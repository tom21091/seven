local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local zones = require('zones');

local spells = packets.spells;
local status = packets.status;
local abilities = packets.abilities;
local stoe = packets.stoe;

local ability_levels = {};
ability_levels[packets.abilities.DRAIN_SAMBA] = 5;

return {
  ability_levels = ability_levels,

  tick = function(self)
    if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
    if (healing:DNCHeal(spell_levels)) then return end

    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    if (ATTACK_TID and tid ~= ATTACK_TID) then
      ATTACK_TID = nil;
      AshitaCore:GetChatManager():QueueCommand("/follow " .. cnf.leader, 1);
    end

    if (ATTACK_TID ~= nil) then
      local status = party:GetBuffs(0);
      local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
      if (tp >= 150 and buffs:IsAble(abilities.DRAIN_SAMBA, ability_levels) and status[stoe.DRAIN_SAMBA] ~= true) then
        actions.busy = true;
        actions:queue(actions:new()
          :next(partial(ability, 'Drain Samba', '<me>'))
          :next(partial(wait, 4))
          :next(function(self) actions.busy = false; end));
        return true;
      end
    end
  end,

  attack = function(self, tid)
    actions:queue(actions:new()
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
      end)
      :next(function(self)
        ATTACK_TID = tid;
        AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
      end));
  end

};
