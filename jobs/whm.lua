local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local nukes = require('behaviors.nukes');
local zones = require('zones');


local jwhm = {};

function jwhm:tick()
  if not (zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
  local buff = party:GetBuffs(0);
  if (buff[packets.status.EFFECT_INVISIBLE]) then return end
  if (actions.busy) then return end
  local cnf = config:get();
  local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
  local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
 
  
  if (cnf['AutoCast']~=true or buff[packets.status.EFFECT_SILENCE])then print("no") return end
  if (cnf['AutoHeal']==true)then
    if (healing:Heal()) then return end -- first priority...
    if (buffs:Cleanse()) then return end
  end
  if (buffs:SneakyTime()) then return end
  if (buffs:IdleBuffs()) then return end
  if (ATTACK_TID == tid and cnf['AutoNuke'])then
    self:nuke(tid);
  end
end

function jwhm:attack(tid)
  actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end));
end

function jwhm:nuke(tid, spell)
  local cnf = config:get();
  if (AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0) < cnf["NukeManaCutoff"]) then return end
  
  nukes:Nuke(tid, spell);
  -- AshitaCore:GetChatManager():QueueCommand('/magic Banish ' .. tid, 0);
end

return jwhm;