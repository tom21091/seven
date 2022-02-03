local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local zones = require('zones');

local spell_levels = {};

return {

  tick = function(self)
    if not(zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    -- if (ATTACK_TID and tid == ATTACK_TID and tp >= 1000) then
    --   if (cnf.WeaponSkillID ~= nil ) then
    --     if AshitaCore:GetDataManager():GetPlayer():HasWeaponSkill(tonumber(cnf.WeaponSkillID)) then
    --       for k, v in pairs(packets.weaponskills) do
    --         if ( tonumber(cnf.WeaponSkillID) == tonumber(v)) then
    --           weaponskill(string.gsub(string.gsub(k,"_"," "),"TACHI","TACHI:"), tid);
    --         end
    --       end
    --     end
    --   end
    -- end
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
