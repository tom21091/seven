require 'ffxi.targets';

local actions = require('actions');
local packets = require('packets');
local config = require('config');
local party = require('party');
local pgen = require('pgen');
local magic = require('magic');
local buffs = require('behaviors/buffs');
local subjob = require('subjob');

local jblm = require('jobs.blm');
local jbrd = require('jobs.brd');
local jdnc = require('jobs.dnc');
local jdrg = require('jobs.drg');
local jdrk = require('jobs.drk');
local jrdm = require('jobs.rdm');
local jsam = require('jobs.sam');
local jpld = require('jobs.pld');
local jsch = require('jobs.sch');
local jthf = require('jobs.thf');
local jwar = require('jobs.war');
local jwhm = require('jobs.whm');
local jmnk = require('jobs.mnk');
local jsmn = require('jobs.smn');
local jcor = require('jobs.cor');
local jpup = require('jobs.pup');

local map = {};
map[Jobs.BlackMage] = jblm;
map[Jobs.Bard] = jbrd;
map[Jobs.Dancer] = jdnc;
map[Jobs.DarkKnight] = jdrk;
map[Jobs.Dragoon] = jdrg;
map[Jobs.RedMage] = jrdm;
map[Jobs.Scholar] = jsch;
map[Jobs.Thief] = jthf;
map[Jobs.Warrior] = jwar;
map[Jobs.WhiteMage] = jwhm;
map[Jobs.Monk] = jmnk;
map[Jobs.Summoner] = jsmn;
map[Jobs.Corsair] = jcor;
map[Jobs.Samurai] = jsam;
map[Jobs.Paladin] = jpld;
map[Jobs.Puppetmaster] = jpup;

local healing = false;

return {
  ATTACK_TID = nil,

  debuff = function(self, tid)
    local player = AshitaCore:GetDataManager():GetPlayer();
    local main = player:GetMainJob();
    local sub  = player:GetSubJob();

    if (main == Jobs.WhiteMage) then
      actions:queue(actions:new()
        :next(partial(magic.cast, magic, 'Slow', tid)));
      actions:queue(actions:new():next(partial(wait, 3))
        :next(partial(magic.cast, magic, 'Paralyze', tid)));
      actions:queue(actions:new():next(partial(wait, 3))
        :next(partial(magic.cast, magic, 'Dia', tid)));

    elseif (main == Jobs.BlackMage) then
      actions:queue(actions:new()
        :next(partial(magic.cast, magic, 'Blind', tid)));
      actions:queue(actions:new():next(partial(wait, 3))
        :next(partial(magic.cast, magic, 'Poison', tid)));
      actions:queue(actions:new():next(partial(wait, 3))
        :next(partial(magic.cast, magic, 'Bio', tid)));
    end
  end,


  nuke = function(self, tid, spell)
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local sub = AshitaCore:GetDataManager():GetPlayer():GetSubJob();

    for jobid, job in pairs(map) do
      if ((main == jobid or sub == jobid) and job.nuke) then
        return job:nuke(tid, spell);
      end
    end
  end,


  sleep = function(self, tid, aoe)
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local sub = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
    for jobid, job in pairs(map) do
      if ((main == jobid or sub == jobid) and job.sleep) then
        return job:sleep(tid, aoe);
      end
    end
  end,

  attack = function(self, tid)
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();

    for jobid, job in pairs(map) do
      if (main == jobid and job.attack) then
        return job:attack(tid);
      end
    end
  end,

  ws = function(self, tid)
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    if (cnf.ATTACK_TID) then -- Attacking something
      if (tp >= 1000 and cnf.ATTACK_TID ~= nil and cnf.WeaponSkill ~= nil) then -- Weaponskill
        local key = packets.weaponskills[string.upper(string.gsub(string.gsub(cnf.WeaponSkill," ","_"),":",""))];
        print (string.upper(string.gsub(string.gsub(cnf.WeaponSkill,":","")," ","_")))
        if (AshitaCore:GetDataManager():GetPlayer():HasWeaponSkill(key))then
          if(cnf.WeaponSkill == "Starlight")then
            if(AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0)<75)then
              actions:queue(actions:new()
              :next(function(self)print("starlight");weaponskill("Starlight", "<me>"); end)
              :next(partial(wait, 1))
            );
            end
          else
            actions:queue(actions:new()
            :next(function(self)print(cnf.WeaponSkill);weaponskill(string.gsub(cnf.WeaponSkill,"_"," "), tid); end)
            :next(partial(wait, 1))
          );
          end
        end
      end
    end
  end,

  reposition = function(self)
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local targetname = ashita.ffxi.targets.get_target('t');	
    if (targetname == nil) then
      return false
    end
    local dist = math.sqrt(targetname.Distance)
    if (dist >=3.0)then 
      print ("Too far");
      for jobid, job in pairs(map) do
        if (main == jobid and job.attack) then
          local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
          return job:attack(tid);
        end
      end
    end
    if (dist < 1) then
      print ("Too close");
      AshitaCore:GetChatManager():QueueCommand("/sendkey numpad2 down", -1);
      ashita.timer.once(0.001, function()
        AshitaCore:GetChatManager():QueueCommand("/sendkey numpad2 up", -1)
      end);
    end
    local tardir = targetname.Heading
	  local degrees = tardir * (180 / math.pi) + 90;
    local pH = string.format('%2.3f',AshitaCore:GetDataManager():GetEntity():GetLocalYaw(AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0)));	
    local idegrees = pH * (180 / math.pi) + 90;
    if (degrees > 360) then
			degrees = degrees - 360;
		elseif (degrees < 0) then
			degrees = degrees + 360;
		end	
    if (idegrees > 360) then
			idegrees = idegrees - 360;
		elseif (idegrees < 0) then
			idegrees = idegrees + 360;
		end
    local a = math.abs(degrees - idegrees)
    local b = 360 - a
    local minangle = math.min(a,b)
    
    if(minangle <= 45)then
      return true;
    else
      a = (idegrees - minangle) % 360;
      if (a<0)then
        a = a+360;
      end
      if (a == degrees)then
        --Right
        if (minangle>50 or dist > 2)then
        AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 down", -1);
        ashita.timer.once(0.001, function()
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 up", -1)
        end);
        else
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 down", -1);
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 up", -1);
        end

      else
        if (minangle>50 or dist > 2)then
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 down", -1);
          ashita.timer.once(0.001, function()
            AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 up", -1)
          end);
        else
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 down", -1);
          AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 up", -1);
        end
      end
    end
      
    -- print ("Me ".. idegrees .. " Target ".. degrees .. "ang" .. degrees - idegrees);

      -- actions.busy = true;
      -- actions:queue(actions:new()
      -- :next(function(self) AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 down", -1);end)
      -- :next(partial(wait,0))
      -- :next(function(self) AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 up", -1);end)
      -- :next(function(self) actions.busy = false; end));
      -- if(degrees - idegrees >15) then
      --   AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 down", -1);
      --   ashita.timer.once(0.001, function()
      --     AshitaCore:GetChatManager():QueueCommand("/sendkey numpad4 up", -1)
      --   end);
      -- else
      --   AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 down", -1);
      --   ashita.timer.once(0.001, function()
      --     AshitaCore:GetChatManager():QueueCommand("/sendkey numpad6 up", -1)
      --   end);
      -- end
    -- end
  end,

  tick = function(self)
    if (config:get() == nil) then return end
    local status = party:GetBuffs(0);
    if (status[packets.status.EFFECT_INVISIBLE]) then return end
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local main = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    local mytid = GetPlayerEntity().ServerId;
    if(cnf['escape']==true)then-- running away, don't stop
      print('.');
      return
    end
    if(actions.busy==true)then return end
    if (cnf.ATTACK_TID) then -- Attacking something
      if (tid ~= cnf.ATTACK_TID and not(tid == mytid and cnf.leader == GetPlayerEntity().Name)) then -- Target likely dead
        cnf.ATTACK_TID = nil;
        if(cnf['follow']==true)then --follow leader
          AshitaCore:GetChatManager():QueueCommand("/follow " .. config:get().leader, 1);
        else --wait here
          self:stay();
        end
      elseif (tp >= 1000 and actions.busy==false and cnf.ATTACK_TID == tid and cnf.AutoWS==true) then -- Weaponskill
        if (cnf.WeaponSkill ~= nil ) then
          local key = packets.weaponskills[string.upper(string.gsub(string.gsub(cnf.WeaponSkill," ","_"),"TACHI:","TACHI"))];
          if (AshitaCore:GetDataManager():GetPlayer():HasWeaponSkill(key))then
            local target;
            if(cnf.WeaponSkill == "Starlight")then
              if(AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0)<75)then
                actions:queue(actions:new()
                :next(partial(wait, 0.5))
                :next(function(self)print("starlight");weaponskill("Starlight", "<me>"); end)
                :next(partial(wait, 1))
              );
              end
            else
              actions:queue(actions:new()
              :next(partial(wait, 0.5))
              :next(function(self)print(cnf.WeaponSkill);weaponskill(string.gsub(cnf.WeaponSkill,"_"," "), tid); end)
              :next(partial(wait, 1))
            );
            end
          end
        end
      end
      if(GetPlayerEntity().Name == cnf['tank'])then
        if (not(buffs:AbilityOnCD("Provoke")) and cnf.ATTACK_TID ~= nil and tid == cnf.ATTACK_TID) then
          print('Provoke');
          actions.busy = true;
          actions:queue(actions:new()
            :next(partial(ability, 'Provoke', tid))
            :next(partial(wait, 1))
            :next(function(self) actions.busy = false; end));
        end
      elseif (cnf.AutoPosition == true)then
        self:reposition();
      end
    end
    
    for jobid, job in pairs(map) do
      if (main == jobid and job.tick) then
        job:tick();
      end
    end
    subjob:subjob(tid, cnf, tp);
  end,

  stay = function(self)
    local cnf = config:get();
    if (cnf['stay'] == nil) then
      cnf['stay'] = true;
      AshitaCore:GetChatManager():QueueCommand("/sendkey numpad7 down", -1);
    elseif (cnf['stay'] == true) then
      cnf['stay'] = nil;
      AshitaCore:GetChatManager():QueueCommand("/sendkey numpad7 up", -1);
    end
    config:save();
  end
};
