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

return {

  tick = function(self)
    if not (zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
    if (actions.busy) then return end
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    local topen = AshitaCore:GetDataManager():GetTarget():GetIsMenuOpen();
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end

    -- local sub = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
    -- if (sub == Jobs.Dancer and ATTACK_TID ~= nil) then
    --   local status = party:GetBuffs(0);
    --   local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    --   if (tp >= 150 and buffs:IsAble(abilities.DRAIN_SAMBA, jdnc.ability_levels) and status[packets.status.EFFECT_DRAIN_SAMBA] ~= true) then
    --     actions.busy = true;
    --     actions:queue(actions:new()
    --       :next(partial(ability, 'Drain Samba', '<me>'))
    --       :next(partial(wait, 8))
    --       :next(function(self) actions.busy = false; end));
    --     return true;
    --   end
    --   if (healing:DNCHeal()) then return end
    -- end

    if(ATTACK_TID == nil)then return end
    local queueJobAbility = nil;
    local queueTarget = nil;
    -- if (not(buffs:AbilityOnCD("Provoke")) and ATTACK_TID ~= nil) then
    --   print('provoke');
    --   queueJobAbility = 'Provoke';
    --   queueTarget = '<t>';
    if (not(buffs:AbilityOnCD("Warcry")) and buffs:IsAble(abilities.WARCRY)) then
      print('Warcry');
      queueJobAbility = 'Warcry';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Defender"))and buffs:IsAble(abilities.DEFENDER) and cnf['tank']==GetPlayerEntity().Name) then
      print('Defender');
      queueJobAbility = 'Defender';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Berserk"))and buffs:IsAble(abilities.BERSERK) and cnf['tank']~=GetPlayerEntity().Name) then
      print('Berserk');
      queueJobAbility = 'Berserk';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Dodge")) and buffs:IsAble(abilities.DODGE)) then
      print('Dodge');
      queueJobAbility = 'Dodge';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Aggressor")) and buffs:IsAble(abilities.AGGRESSOR)) then
      print('Aggressor');
      queueJobAbility = 'Aggressor';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Focus")) and buffs:IsAble(abilities.FOCUS)) then
      print('Focus');
      queueJobAbility = 'Focus';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Boost"))  and buffs:IsAble(abilities.BOOST)) then
      queueJobAbility = 'Boost';
      queueTarget = '<me>';
    end
    if (queueJobAbility ~= nil) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(ability, queueJobAbility, queueTarget))
        :next(partial(wait, .5))
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
        ATTACK_TID = tid;
        AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
      end));
  end

};
