require 'ffxi.targets';

local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');

local abilities = packets.abilities;

return {

  tick = function(self)
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    -- Attempt to weaponskill when you have TP
    -- if (cnf.ATTACK_TID and tid == cnf.ATTACK_TID and tp >= 1000) then
    --   if (cnf.WeaponSkillID ~= nil ) then
    --     if AshitaCore:GetDataManager():GetPlayer():HasWeaponSkill(tonumber(cnf.WeaponSkillID)) then
    --       for k, v in pairs(packets.weaponskills) do
    --         if (tonumber(cnf.WeaponSkillID) == tonumber(v)) then
    --           weaponskill(string.gsub(string.gsub(k,"_"," "),"TACHI","TACHI:"), tid);
    --         end
    --       end
    --     end
    --   end
    -- end
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end

    local queueJobAbility = nil;
    local queueTarget = nil;
    -- if (not(buffs:AbilityOnCD("Provoke")) and cnf.ATTACK_TID ~= nil) then
    --   print('provoke');
    --   queueJobAbility = 'Provoke';
    --   queueTarget = '<t>';
    if (not(buffs:AbilityOnCD("Steal")) and buffs:IsAble(abilities.STEAL) and cnf.ATTACK_TID ~= nil) then
      print('Steal');
      queueJobAbility = 'Steal';
      queueTarget = '<t>';
    elseif (not(buffs:AbilityOnCD("Sneak Attack"))and buffs:IsAble(abilities.SNEAK_ATTACK) and cnf.ATTACK_TID ~= nil and self:checkSA()) then
      print('Sneak Attack');
      queueJobAbility = 'Sneak Attack';
      queueTarget = '<me>';
    elseif (not(buffs:AbilityOnCD("Trick Attack"))and buffs:IsAble(abilities.TRICK_ATTACK) and cnf.ATTACK_TID ~= nil and self:checkSA()) then
      print('Trick Attack');
      queueJobAbility = 'Trick Attack';
      queueTarget = '<me>';
    end
    if (queueJobAbility ~= nil) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(ability, queueJobAbility, queueTarget))
        :next(partial(wait, 0.01))
        :next(function(self) actions.busy = false; end));
      return true;
    end
    
  end,

  checkSA = function(self)
    local targetname = ashita.ffxi.targets.get_target('t')	
    if (targetname == nil) then
      return false
    end
    local dist = math.sqrt(targetname.Distance)
    if (dist >=3.0)then 
      return false
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
    if(math.abs(degrees - idegrees) <= 45)then
      return true;
    else
      return false;
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
