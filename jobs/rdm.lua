local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs');
local healing = require('behaviors.healing');
local nukes = require('behaviors.nukes');


return {

  tick = function(self)
    --local cnf = config:get();
    --local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
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
    if(cnf.AutoCast==true)then
      if ( cnf.ATTACK_TID == tid) then
        if (nukes:Nuke(tid)) then return end
      end
      if (healing:Heal()) then return end
      if (buffs:Cleanse()) then return end
      if (buffs:SneakyTime()) then return end
      if (buffs:IdleBuffs()) then return end
    end

    

    -- local cnf = config:get();
    -- local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    -- if (cnf.ATTACK_TID and tid ~= cnf.ATTACK_TID) then
    --   cnf.ATTACK_TID = nil;
    --   AshitaCore:GetChatManager():QueueCommand("/follow " .. cnf.leader, 1);
    -- end

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
  end,

  nuke = function(self, tid, spell)
    nukes:Nuke(tid, spell);
  end
};
