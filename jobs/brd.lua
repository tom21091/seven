require 'ffxi.recast';

local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local jwhm = require('jobs.whm');
local magic = require('magic');
local levels = require('levels');

local spells = packets.spells;
local status = packets.status;
local stoe = packets.stoe;



-- spells to effect

local jbrd = {
  stack_toggle = 0;
};

function jbrd:tick()
  local cnf = config:get();
  local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
  local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
  local status = party:GetBuffs(0);
  if (actions.busy) then return end
  if (status[packets.status.EFFECT_INVISIBLE]) then return end
  if (not(cnf.bard.sing)) then return end

  local statustbl = AshitaCore:GetDataManager():GetPlayer():GetStatusIcons();
  if (status[packets.status.EFFECT_INVISIBLE]) then return end

  if (not(not(cnf.bard.songvar1)) and ashita.ffxi.recast.get_spell_recast_by_index(spells[cnf.bard.songvar1]) == 0) then
    local need = not(status[stoe[cnf.bard.songvar1]]);
    if (not(need) and stoe[cnf.bard.songvar1] == stoe[cnf.bard.songvar2]) then
      local buffcount = 0;
      for slot = 0, 31, 1 do
        local buff = statustbl[slot];
        if (buff == stoe[cnf.bard.songvar1]) then
          buffcount = buffcount + 1;
        end
      end
      if (buffcount < 2) then
        need = true;
      end
    end
    if (cnf.bard.songvar1 and need) then
      local spell = magic:highest(cnf.bard.song1, false);
      if (spell) then
        actions.busy = true;
        actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, spell , '<me>'))
        :next(partial(wait, 8))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
        return;
      end
    end
  end

  if (not(not(cnf.bard.songvar2)) and ashita.ffxi.recast.get_spell_recast_by_index(spells[cnf.bard.songvar2]) == 0) then
    local need = not(status[stoe[cnf.bard.songvar2]]);
    if (not(need) and stoe[cnf.bard.songvar1] == stoe[cnf.bard.songvar2]) then
      local buffcount = 0;
      for slot = 0, 31, 1 do
        local buff = statustbl[slot];
        if (buff == stoe[cnf.bard.songvar2]) then
          buffcount = buffcount + 1;
        end
      end
      if (buffcount < 2) then
        need = true;
      end
    end
    if (cnf.bard.songvar2 and need) then
        local spell = magic:highest(cnf.bard.song2, false);
      if (spell) then
        actions.busy = true;
        actions:queue(actions:new()
          :next(partial(actions.pause, true))
          :next(partial(magic.cast, magic, spell , '<me>'))
          :next(partial(wait, 8))
          :next(partial(actions.pause, false))
          :next(function(self) actions.busy = false; end));
        return;
      end
    end
  end

  if (healing:SupportHeal()) then return end
  
end

function jbrd:attack(tid)
  local cnf = config:get();

  if (cnf['bard']['melee']) then
    actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      cnf.ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end)
    :next(partial(wait, 4)));
  end
  local spell = magic:highest('Foe Requiem', false);
  if (spell) then
    actions.busy = true;
      actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, spell , tid))
      :next(partial(wait, 2))
      :next(partial(actions.pause, false)));
  end
  

  if (magic:CanCast('BATTLEFIELD_ELEGY')) then
    actions.busy = true;
    actions:queue(actions:new()
    :next(partial(actions.pause, true))
    :next(partial(magic.cast, magic, 'Battlefield Elegy', tid))
    :next(partial(wait, 2))
    :next(partial(actions.pause, false))
    :next(function(self) actions.busy = false; end));
  end

 

  spell = magic:highest('Dia', false);
  if (spell) then
    actions.busy = true;
    
    actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, spell, tid))
      :next(partial(wait, 1))
      :next(partial(actions.pause, false)));
  end

  if (magic:CanCast('LIGHTNING_THRENODY')) then
    actions.busy = true;
    action:next(partial(magic.cast, magic, 'Lightning Threnody', tid))
      :next(partial(wait, 2));
  end
  actions:queue(actions:new()
  :next(function(self) actions.busy = false; end));
end

function jbrd:sleep(tid, aoe)
  if (not(aoe) and magic:CanCast(spells.FOE_LULLABY)) then
    actions:queue(actions:new()
    :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, 'Foe Lullaby', tid))
      :next(partial(wait, 2)))
      :next(partial(actions.pause, false));
  elseif (aoe and magic:CanCast(spells.HORDE_LULLABY)) then
    actions:queue(actions:new()
      :next(partial(magic.cast, magic, 'Horde Lullaby', tid))
      :next(partial(wait, 2)));
  end
end

function jbrd:bard(bard, command, song, silent)
  local cnf = config:get();
  local brd = cnf['bard'];
  local onoff = brd['sing'] and 'on' or 'off';
  local song1 = brd['song1'] or 'none';
  local song2 = brd['song2'] or 'none';

  local songvar;

  if(song ~= nil) then
    songvar = song:upper():gsub("'", ""):gsub(" ", "_");
  end
  if (command ~= nil) then
    if (command == 'on' or command == 'true') then
      brd['sing'] = true;
      onoff = 'on';
    elseif (command == 'off' or command == 'false') then
      brd['sing'] = false;
      onoff = 'off';
    elseif (command == '1' and song and spells[songvar]) then
      brd['song1'] = song;
      brd['songvar1'] = songvar;
      song1 = song;
    elseif (command == '2' and song and spells[songvar]) then
      brd['song2'] = song;
      brd['songvar2'] = songvar;
      song2 = song;
    elseif (command =='1' and song == 'none') then
      brd['song1'] = nil;
      brd['songvar1'] = nil;
      song1 = 'none';
    elseif (command =='2' and song == 'none') then
      brd['song2'] = nil;
      brd['songvar2'] = nil;
      song2 = 'none';
    elseif (command == 'run') then
      jbrd:bard(bard, '1', 'raptor mazurka', true);
      jbrd:bard(bard, '2', 'chocobo mazurka');
      return;
    elseif (command == 'sustain') then
      jbrd:bard(bard, '1', "mage's ballad ii", true);
      jbrd:bard(bard, '2', "army's paeon v");
      return;
    elseif (command == 'mana') then
      jbrd:bard(bard, '1', "mage's ballad ii", true);
      jbrd:bard(bard, '2', "mage's ballad");
      return;
    elseif (command == 'melee') then
      brd['melee'] = not(brd['melee']);
    end
    config:save();
  end

  if (not(silent)) then
    local msg = "I'm a ";
    if (brd['melee']) then
      msg = msg .. 'MELEE ';
    end
    msg = msg .. 'Bard!\nsinging: ' .. onoff .. '\n1: ' .. song1 .. '\n2: ' .. song2;
    AshitaCore:GetChatManager():QueueCommand('/l2 ' .. msg, 1);
  end
end

return jbrd;
