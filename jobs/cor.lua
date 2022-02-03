local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local jdnc = require('jobs.dnc');
local jbrd = require('jobs.brd');
local zones = require('zones');

local spells = packets.spells;
local stoe = packets.stoe;
local abilities = packets.abilities;

-- local ability_levels = {};
-- ability_levels[abilities.CORSAIRS_ROLL] = 5;
-- ability_levels[abilities.NINJA_ROLL] = 8;
-- ability_levels[abilities.HUNTERS_ROLL] = 11;
-- ability_levels[abilities.CHAOS_ROLL] = 14;
-- ability_levels[abilities.MAGUSS_ROLL] = 17;
-- ability_levels[abilities.HEALERS_ROLL] = 20;
-- ability_levels[abilities.DRACHEN_ROLL] = 23;
-- ability_levels[abilities.CHORAL_ROLL] = 26;
-- ability_levels[abilities.MONKS_ROLL] = 31;
-- ability_levels[abilities.BEAST_ROLL] = 34;
-- ability_levels[abilities.SAMURAI_ROLL] = 37;
-- ability_levels[abilities.EVOKERS_ROLL] = 40;
-- ability_levels[abilities.ROGUES_ROLL] = 43;
-- ability_levels[abilities.WARLOCKS_ROLL] = 46;
-- ability_levels[abilities.FIGHTERS_ROLL] = 49;
-- ability_levels[abilities.PUPPET_ROLL] = 52;
-- ability_levels[abilities.GALLANTS_ROLL] = 55;
-- ability_levels[abilities.WIZARDS_ROLL] = 58;
-- ability_levels[abilities.DANCERS_ROLL] = 61;
-- ability_levels[abilities.SCHOLARS_ROLL] = 64;

local jcor = {
  -- ability_levels = ability_levels
};
--TODO: Make Corsair distance aware
function jcor:tick()
  if (actions.busy) then return end
  if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
  local cnf = config:get();
  local cor = cnf['corsair'];
  if (not(cor['roll'])) then return end

  local status = party:GetBuffs(0);
  if (status[packets.status.EFFECT_INVISIBLE]) then return end
 
  local cnf = config:get();
  if (cnf.corsair.rollvar1 and not(status[stoe[cnf.corsair.rollvar1]])) then
    if (buffs:IsAble(abilities[cnf.corsair.rollvar1]) and not buffs:AbilityOnCD('PHANTOM_ROLL')) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(ability,  cnf.corsair.roll1, '<me>'))
        :next(partial(wait, 2))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end
  if (cnf.corsair.rollvar2 and not(status[stoe[cnf.corsair.rollvar2]] and not(status[packets.status.EFFECT_BUST]))) then
    if (buffs:IsAble(abilities[cnf.corsair.rollvar2]) and not buffs:AbilityOnCD('PHANTOM_ROLL')) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(ability, cnf.corsair.roll2 , '<me>'))
        :next(partial(wait, 2))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end

  if (ATTACK_TID) then
    actions.busy = true;
      actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(function(self) AshitaCore:GetChatManager():QueueCommand("/ra <t>", 1);end)
      :next(partial(wait, 5))
      :next(partial(actions.pause, false))
      :next(function(self) actions.busy = false; end));
    
  end

  
end

function jcor:attack(tid)
  actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end)
    );
end

function jcor:roller(name, number)
  local key = string.upper(string.gsub(string.gsub(name,' ','_'), "'",""));
  
  --Lucky roll, stop here
  if(number==packets.luckyRolls[key])then print("Lucky Roll!"); return end
  local status = party:GetBuffs(0);
  --No more double up chance
  if(not status[packets.status.EFFECT_DOUBLE_UP_CHANCE])then print("Double up over..."); return end
  --Less than 6 or unlucky number, roll again

  if(number<=6 or number==packets.unluckyRolls[key])then
    print("Rerolling");
    actions.busy = true;
      actions:queue(actions:new()
      :next(partial(wait, 2))
      :next(partial(ability, 'Double-Up' , '<me>'))
      :next(partial(wait, 1))
      :next(function(self) actions.busy = false; end));
  end

end

function jcor:corsair(corsair, command, roll)
  local cnf = config:get();
  local cor = cnf['corsair'];
  local onoff = cor['roll'] and 'on' or 'off';
  local roll1 = cor['roll1'] or 'none';
  local roll2 = cor['roll2'] or 'none';

  local rollvar;
  if(roll ~= nil) then
    rollvar = roll:upper():gsub("'", ""):gsub(" ", "_");
  end

  if (command ~= nil) then
    if (command == 'on' or command == 'true') then
      cor['roll'] = true;
      onoff = 'on';
    elseif (command == 'off' or command == 'false') then
      cor['roll'] = false;
      onoff = 'off';
    elseif (command == '1' and roll and abilities[rollvar]) then
      cor['roll1'] = roll;
      cor['rollvar1'] = rollvar;
      roll1 = roll;
    elseif (command == '2' and roll and abilities[rollvar]) then
      cor['roll2'] = roll;
      cor['rollvar2'] = rollvar;
      roll2 = roll;
    elseif (command =='1' and roll == 'none') then
      cor['roll1'] = nil;
      cor['rollvar1'] = nil;
      roll1 = 'none';
    elseif (command =='2' and roll == 'none') then
      cor['roll2'] = nil;
      cor['rollvar2'] = nil;
      roll2 = 'none';
    end
    config:save();
  end

  AshitaCore:GetChatManager():QueueCommand('/l2 I\'m a Corsair!\nrolling: ' .. onoff .. '\n1: ' .. roll1 .. '\n2: ' .. roll2, 1);
end

return jcor;
