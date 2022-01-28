local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local zones = require('zones');

local abilities = packets.abilities;
local spell_levels = {};

return {

  tick = function(self)
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
    
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    queueJobAbility = nil;
    local playerEntity = GetPlayerEntity();
    if (zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then
      if (playerEntity.PetTargetIndex == 0) then
        if (not(buffs:AbilityOnCD("Call Wyvern")) and buffs:IsAble(abilities.CALL_WYVERN) and cnf.ATTACK_TID ~= nil) then
          queueJobAbility = 'Call Wyvern';
          queueTarget = '<me>';
        end
      else
        local pet = GetEntity(playerEntity.PetTargetIndex);
        if (pet ~= nil)then
          if (pet.HealthPercent <= 50)then
            if(not(buffs:AbilityOnCD("Spirit Link"))and buffs:IsAble(abilities.SPIRIT_LINK))then
              queueJobAbility = 'Spirit Link';
              queueTarget = '<me>';
            end
          end
        end

      end
    end

    if (not(buffs:AbilityOnCD("Jump"))and buffs:IsAble(abilities.JUMP) and cnf.ATTACK_TID ~= nil) then
      queueJobAbility = 'Jump';
      queueTarget = '<t>';
    elseif (not(buffs:AbilityOnCD("High Jump"))and buffs:IsAble(abilities.HIGH_JUMP) and cnf.ATTACK_TID ~= nil) then
      queueJobAbility = 'High Jump';
      queueTarget = '<t>';
    -- elseif (not(buffs:AbilityOnCD("Super Jump"))and buffs:IsAble(abilities.SUPER_JUMP) and cnf.ATTACK_TID ~= nil) then
    --   queueJobAbility = 'Super Jump';
    --   queueTarget = '<t>';
    end
    if (queueJobAbility ~= nil) then
      print (queueJobAbility);
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(wait, 1))
        :next(partial(ability, queueJobAbility, queueTarget))
        :next(partial(wait, 0.5))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end,

  attack = function(self, tid)
    actions:queue(actions:new()
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
      end)
      :next(function(self)
        config:get().ATTACK_TID = tid;
        AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
      end));
  end

};
