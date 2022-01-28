local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local levels = require('levels');
local zones = require('zones');

local status = packets.status;
local abilities = packets.abilities;
local stoe = packets.stoe;

-- local ability_levels = {};
-- ability_levels[packets.abilities.THIRD_EYE] = 15;
-- ability_levels[packets.abilities.HASSO] = 25;
-- ability_levels[packets.abilities.MEDITATE] = 30;
-- ability_levels[packets.abilities.SEIGAN] = 35;
-- ability_levels[packets.abilities.SEKKANOKI] = 40;
-- ability_levels[packets.abilities.KONZEN_ITTAI] = 65;

local jpld = {
};

function jpld:tick()
  if (actions.busy) then return end
  if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
  local cnf = config:get();
  local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
  local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);

  local queueJobAbility = nil;
--   if(zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then
--     if (buffs:IsAble(abilities.HASSO) and not(buffs:AbilityOnCD("Hasso")) and cnf.ATTACK_TID ~= nil) then
--       queueJobAbility = "Hasso";
--     elseif (not(buffs:AbilityOnCD("Meditate")) and buffs:IsAble(abilities.MEDITATE) and cnf.ATTACK_TID ~= nil) then
--         queueJobAbility = 'Meditate';
--     elseif (not(buffs:AbilityOnCD("Third Eye")) and buffs:IsAble(abilities.THIRD_EYE) and cnf.ATTACK_TID ~= nil) then
--         queueJobAbility = 'Third Eye';
--     else
--         queueJobAbility = nil;
--     end
--   end
  if (queueJobAbility ~= nil) then
    print (queueJobAbility)
    actions.busy = true;
    actions:queue(actions:new()
      :next(partial(ability, queueJobAbility, '<me>'))
      :next(partial(wait, .01))
      :next(function(self) actions.busy = false; end));
    return true;
  end
end

function jpld:attack(tid)
  actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      config:get().ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end));
end

return jpld;
