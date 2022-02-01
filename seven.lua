_addon.author   = 'siete/Tommywommy';
_addon.name     = 'seven';
_addon.version  = '0.3';

require 'common';
local config = require('config');
local debug_packet = require('debug_packet');
local commands = require('commands');
local actions = require('actions');
local packets = require('packets');
local combat = require('combat');
local party = require('party');
local pgen = require('pgen');
local fov = require('fov');
local gui = require('gui');

local jcor = require('jobs.cor');

function wait(time)
  return 'wait', time;
end

function ability(ability, target)
  AshitaCore:GetChatManager():QueueCommand('/ja "' .. ability .. '" ' .. target, 0);
end

function weaponskill(ability, target)
  AshitaCore:GetChatManager():QueueCommand('/ws "' .. ability .. '" ' .. target, 0);
end

function partial(func, ...)
  local args = {...};
  return function(...)
    local newargs = {...};
    while (#newargs > 0) do
      table.insert(args, table.remove(newargs, 1));
    end
    return func(unpack(args));
  end
end

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: listen to incoming packets
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
  debug_packet:inc(id, size, packet);
  actions:packet(true, id, size, packet);

  if (id == packets.inc.PACKET_INCOMING_CHAT) then
    commands:process(id, size, packet);
  elseif (id == packets.inc.PACKET_PARTY_INVITE or id == packets.inc.PACKET_PARTY_STATUS_EFFECT) then
    party:process(id, size, packet);
  end

  return false;
end);


---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: listen to incoming packets
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
  debug_packet:out(id, size, packet);
  local result = actions:packet(false, id, size, packet);
  if (result == true) then
    return true;
  end
  return false;
end);


local last = 0;
---------------------------------------------------------------------------------------------------
-- func: render
-- desc: event loop
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
  local clock = os.clock;
  local t0 = clock();
  gui:main();
  if (t0 - last > 0.5) then -- Every half second?
    last = t0;
    local cnf = config:get();
    if (cnf ~= nil and cnf['stay'] == true) then
      return commands:stay();
    end
    actions:tick();
    combat:tick();
  end
end);


ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
   --print("Mode "..mode.." message ".. message.. " modmode ".. modifiedmode.. " modmess ".. modifiedmessage);
  if(mode == 101)then -- Ability message
      if (string.find(message, "The total"))then        
        local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
        local sub = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
        if(main == Jobs.Corsair or sub == Jobs.Corsair )then
          local abilityname = string.sub(message, string.find(message, "%a+'?s Roll"))
          jcor:roller(abilityname, tonumber(string.match(message, "%d+")));
        end
      end
    end
  return false;

end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Leader Commands
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
  local args = cmd:args();
  if (args[1] ~= '/seven' and args[1] ~= '/sv') then return false end

  local target = AshitaCore:GetDataManager():GetTarget();
  local tid = target:GetTargetServerId();
  local tidx = target:GetTargetIndex();

  if(args[2] == 'dump')then
    party:DumpBuffs();
  elseif(args[2] == 'db')then
    local jsmn = require('jobs.smn');
    jsmn:pact(args[3]);
    -- actions:queue(actions:new()
    -- :next(function(self)print("Start wait"); end)
    -- :next(partial(wait, 0.01))
    -- :next(function(self)print("Done waiting"); end))



    -- local zone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
    -- local zones = require('zones');
    -- print(zones[zone].name, zones[zone].hostile);
  elseif(args[2] == 'siphon')then
    local jsmn = require('jobs.smn');
    jsmn:siphon();
  elseif (args[2] == 'leader') then
    actions:leader(GetPlayerEntity().Name);
    AshitaCore:GetChatManager():QueueCommand('/l2 leader', 1);
  elseif (args[2] == 'tank') then
    if(args[3]~=nil)then
      actions:tank(args[3]);
      AshitaCore:GetChatManager():QueueCommand('/l2 tank ' .. args[3], 1);
    else
      actions:tank(GetPlayerEntity().Name);
      AshitaCore:GetChatManager():QueueCommand('/l2 tank ' .. GetPlayerEntity().Name, 1);
    end
  elseif (args[2] == 'follow') then
    AshitaCore:GetChatManager():QueueCommand('/l2 follow', 1);
  elseif (args[2] == 'followme') then
    local cnf= config:get();
    cnf['follow']=false;
    config:save();
    AshitaCore:GetChatManager():QueueCommand('/l2 followme', 1);
  elseif (args[2] == 'heal')then
    AshitaCore:GetChatManager():QueueCommand('/l2 heal', 1);
  elseif (args[2] == 'stay') then
    AshitaCore:GetChatManager():QueueCommand('/l2 stay', 1);
  elseif (args[2] == 'reload') then
    AshitaCore:GetChatManager():QueueCommand('/l2 reload', 1);
    AshitaCore:GetChatManager():QueueCommand('/addon reload seven', -1);
  elseif (args[2] == 'echo') then
    AshitaCore:GetChatManager():QueueCommand('/l2 echo ' .. cmd:sub(13):gsub('<t>',tid), 1);
  elseif (args[2] == 'fov' or args[2] == 'gov') then
    if (args[3] == nil) then
      print('Which page?');
      return true;
    end

    if (args[3] == 'cancel') then
      AshitaCore:GetChatManager():QueueCommand('/l2 ' .. args[2] .. ' ' .. tid .. ' ' .. tidx .. ' cancel', 1);
      fov:cancel(args[2], tid, tidx); 
    elseif (args[3] == 'buff' or args[3] == 'buffs') then
      AshitaCore:GetChatManager():QueueCommand('/l2 ' .. args[2] .. ' ' .. tid .. ' ' .. tidx .. ' buffs', 1);
      fov:buffs(args[2], tid, tidx);
    elseif (args[3] == 'home') then
      AshitaCore:GetChatManager():QueueCommand('/l2 ' .. args[2] .. ' ' .. tid .. ' ' .. tidx .. ' home', 1);
      fov:home(args[2], tid, tidx);
    elseif (args[3] == 'sneak') then
      AshitaCore:GetChatManager():QueueCommand('/l2 ' .. args[2] .. ' ' .. tid .. ' ' .. tidx .. ' sneak', 1);
      fov:sneak(args[2], tid, tidx);
    elseif (tonumber(args[3])) then
      AshitaCore:GetChatManager():QueueCommand('/l2 ' .. args[2] .. ' ' .. tid .. ' ' .. tidx .. ' ' .. args[3], 1);
      fov:page(args[2], tid, tidx, args[3]);
    end
  elseif (args[2] == 'debuff') then
    AshitaCore:GetChatManager():QueueCommand('/l2 debuff ' .. tid, 1);
  elseif (args[2] == 'nuke') then
    if(args[3] ~= nil)then
      AshitaCore:GetChatManager():QueueCommand('/l2 nuke ' .. tid .. ' ' .. args[3], 1);
    else
      AshitaCore:GetChatManager():QueueCommand('/l2 nuke ' .. tid, 1);
    end
  elseif (args[2] == 'sleep') then
    AshitaCore:GetChatManager():QueueCommand('/l2 sleep ' .. tid, 1);
  elseif (args[2] == 'sleepga') then
    AshitaCore:GetChatManager():QueueCommand('/l2 sleepga ' .. tid, 1);
  elseif (args[2] == 'attack') then
    AshitaCore:GetChatManager():QueueCommand('/l2 attack ' .. tid, 1);
    combat:attack(tonumber(tid));
  elseif (args[2] == 'signet') then
    AshitaCore:GetChatManager():QueueCommand('/l2 signet ' .. tid .. " " .. tidx, 1);
    actions:signet(tid, tidx);
  elseif (args[2] == 'warp')then
    AshitaCore:GetChatManager():QueueCommand('/l2 warp', 1);
    AshitaCore:GetChatManager():QueueCommand('/item "Warp Ring" <me>', -1);
  elseif (args[2] == 'warpscroll') then
    AshitaCore:GetChatManager():QueueCommand('/l2 warpscroll ' .. tid .. " " .. tidx, 1);
    AshitaCore:GetChatManager():QueueCommand('/item "Warp Ring" <me>', -1);
    if (tidx ~= 0) then
      actions:warp_scroll(tid, tidx);
    else
      actions:queue(actions:new()
        :next(partial(wait, 1))
        :next(function(self)
          AshitaCore:GetChatManager():QueueCommand('/item "Instant Warp" <me>', -1);
          actions.busy = false;
        end));
    end
  elseif (args[2] == 'autocast') then
    if(args[3] ~= nil) then
      if(args[4] == nil) then
        AshitaCore:GetChatManager():QueueCommand('/l2 autocast ' .. args[3], 1);
      else
        AshitaCore:GetChatManager():QueueCommand('/l2 autocast '  .. args[3] .." ".. args[4], 1);
      end
    else
      print('ERROR: Invalid entry for the "/seven autocast" command');
      print('SYNTAX: /seven autocast <on/off> <player>*optional*');
      print('This will turn on or off autocast for the player or all players');
    end
  elseif(args[2] == 'autonuke')then
    if(args[3] ~= nil) then
      if(args[4] == nil) then
        AshitaCore:GetChatManager():QueueCommand('/l2 autonuke ' .. args[3], 1);
      else
        AshitaCore:GetChatManager():QueueCommand('/l2 autonuke '  .. args[3] .." ".. args[4], 1);
      end
    else
      print('ERROR: Invalid entry for the "/seven autonuke" command');
      print('SYNTAX: /seven autonuke <on/off> <player>*optional*');
      print('This will turn on or off autonuke for the player or all players');
    end
  elseif(args[2] == 'autoheal')then
    if(args[3] ~= nil) then
      if(args[4] == nil) then
        AshitaCore:GetChatManager():QueueCommand('/l2 autoheal ' .. args[3], 1);
      else
        AshitaCore:GetChatManager():QueueCommand('/l2 autoheal '  .. args[3] .." ".. args[4], 1);
      end
    else
      print('ERROR: Invalid entry for the "/seven autoheal" command');
      print('SYNTAX: /seven autoheal <on/off> <player>*optional*');
      print('This will turn on or off autoheal for the player or all players');
    end
  elseif (args[2] == 'autows') then
    if(args[3] ~= nil) then
      if(args[4] == nil) then
        AshitaCore:GetChatManager():QueueCommand('/l2 autows ' .. args[3], 1);
        commands:SetAutoWS(nil, args[3]);
      else
        AshitaCore:GetChatManager():QueueCommand('/l2 autows '  .. args[3] .." ".. args[4], 1);
        commands:SetAutoWS(args[3], args[4]);
      end
    else
      print('ERROR: Invalid entry for the "/seven autows" command');
      print('SYNTAX: /seven autows <on/off> <player>*optional*');
      print('This will turn on or off autows for the player or all players');
    end
  elseif (args[2] == 'autopos') then
    if(args[3] ~= nil) then
      if(args[4] == nil) then
        AshitaCore:GetChatManager():QueueCommand('/l2 autopos ' .. args[3], 1);
        commands:SetAutoPosition(nil, args[3]);
      else
        AshitaCore:GetChatManager():QueueCommand('/l2 autopos '  .. args[3] .." ".. args[4], 1);
        commands:SetAutoPosition(args[3], args[4]);
      end
    else
      print('ERROR: Invalid entry for the "/seven autopos" command');
      print('SYNTAX: /seven autopos <on/off> <player>*optional*');
      print('This will turn on or off autopos for the player or all players');
    end
  elseif (args[2] == 'ws')then
    combat:ws(tonumber(tid));
    AshitaCore:GetChatManager():QueueCommand('/l2 ws ' .. tid, 1);
  elseif (args[2] == 'idlebuffs') then
    AshitaCore:GetChatManager():QueueCommand('/l2 idlebuffs ' .. args[3], 1);
    commands:SetIdleBuffs(args[3]);
  elseif (args[2] == 'sneakytime') then
    AshitaCore:GetChatManager():QueueCommand('/l2 sneakytime ' .. args[3], 1);
    commands:SetSneakyTime(args[3]);
  elseif (args[2] == 'setws') then
    if (args[4] ~= nil) then
      AshitaCore:GetChatManager():QueueCommand('/l2 setws ' .. args[3] .. ' "' .. args[4]..'"', 1);
      commands:SetWeaponSkill(args[3], args[4]);
    else
      print(' ');
      print('ERROR: Invalid entry for the "/seven setws" command');
      print('SYNTAX: /seven setws (player) (weapon skill)');
      print(' ');
      print('TIP: Use "/seven searchws" to find available weapon skill ID');
      print(' ');
    end
  elseif (args[2] == 'setsmn') then
    if (args[4] ~= nil) then
      AshitaCore:GetChatManager():QueueCommand('/l2 setsmn ' .. args[3] .. ' "' .. args[4]..'"', 1);
    else
      print(' ');
      print('ERROR: Invalid entry for the "/seven setsmn" command');
      print('SYNTAX: /seven setsmn (player) (summonname in quotes)');
    end
  elseif (args[2] == 'searchws') then
    commands:SearchWeaponSkill(args[3]);
  elseif (args[2] == 'talk') then
    AshitaCore:GetChatManager():QueueCommand('/l2 talk ' .. tid .. " " .. tidx, 1);
    actions:queue(actions:new():next(partial(wait, 1))
    :next(function(self, stalled)
      actions:queue(actions:InteractNpc(tid, tidx));
    end))
  elseif (args[2] == 'bard') then
    if (args[4]) then
      args[4] = '"'..args[4]..'"';
    end
    AshitaCore:GetChatManager():QueueCommand('/l2 bard ' .. (args[3] or '') .. ' ' .. (args[4] or ''), 1);
  elseif (args[2] == 'corsair') then
    if (args[4]) then
      args[4] = '"'..args[4]..'"';
    end
    AshitaCore:GetChatManager():QueueCommand('/l2 corsair ' .. (args[3] or '') .. ' ' .. (args[4] or ''), 1);
  elseif (args[2] == 'summoner') then
    AshitaCore:GetChatManager():QueueCommand('/l2 summoner ' .. (args[3] or '') .. ' ' .. (args[4] or ''), 1);
  elseif (args[2] == 'corn') then
    AshitaCore:GetChatManager():QueueCommand('/l2 corn' .. ' ' .. tid .. ' ' .. tidx, 1);
    actions:corn(tid, tidx);
  elseif (args[2] == 'escape') then
    AshitaCore:GetChatManager():QueueCommand('/l2 escape', 1);
    commands:escape();
  elseif (args[2] == 'relax') then
    AshitaCore:GetChatManager():QueueCommand('/l2 relax', 1);
    commands:relax();
  elseif (args[2] == 'invite') then
    local act = actions:new();
    if(args[3])then
      act:next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pcmd add ' .. args[3], 0);
      end)
    end
    if(args[4])then
      act:next(partial(wait, .5))
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pcmd add ' .. args[4], 0);
      end)
      
    end
    if(args[5])then
      act:next(partial(wait, .5))
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pcmd add ' .. args[5], 0);
      end)
      
    end
    if(args[6])then
      act:next(partial(wait, .5))
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pcmd add ' .. args[6], 0);
      end)
      
    end
    if(args[7])then
      act:next(partial(wait, .5))
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pcmd add ' .. args[7], 0);
      end)
    end
    actions:queue(act);
  elseif (args[2] == 'yaw') then
    local ientity = AshitaCore:GetDataManager():GetEntity();
    local rot = ientity:GetLocalYaw(GetPlayerEntity().TargetIndex);
    local trot = ientity:GetLocalYaw(tidx);
    print(math.abs(rot - trot));
    print(os.date("%j"))
  else
    print("Invalid command");
  end

  return true;
end);


----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
  gui:load();
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
  config:save();
  gui:unload();
end);
