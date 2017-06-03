local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');

local spell_levels = {};


local jsam = {
  spell_levels = spell_levels,
};

function jsam:tick()
  if (actions.busy) then return end

  local cnf = config:get();
  local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
  local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);

  if (cnf.ATTACK_TID and tid ~= cnf.ATTACK_TID) then
    cnf.ATTACK_TID = nil;
    AshitaCore:GetChatManager():QueueCommand("/follow " .. cnf.leader, 1);
  -- Attempt to weaponskill when you have TP
  elseif (cnf.ATTACK_TID and tid == cnf.ATTACK_TID and tp >= 1000) then
    if (cnf.WeaponSkillID ~= nil ) then
      if AshitaCore:GetDataManager():GetPlayer():HasWeaponSkill(tonumber(cnf.WeaponSkillID)) then
        for k, v in pairs(packets.weaponskills) do
          if (tonumber(cnf.WeaponSkillID) == tonumber(v)) then
            AshitaCore:GetChatManager():QueueCommand('/ws "' .. string.gsub(string.gsub(k,"_"," "),"TACHI","TACHI:") .. '" <t>', 1);
          end
        end
      end
    end
  end
end

function jsam:attack(tid)
  actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      config:get().ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end));
end

return jsam;
