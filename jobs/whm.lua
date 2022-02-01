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
  local cnf = config:get();
  local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
  local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);

  if (actions.busy) then return end
  if (cnf['AutoCast']~=true)then return end
  if (cnf['AutoHeal']==true)then
    if (healing:Heal()) then return end -- first priority...
    if (buffs:Cleanse()) then return end
  end
  if (buffs:SneakyTime()) then return end
  if (buffs:IdleBuffs()) then return end
end

function jwhm:attack(tid)
  actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      config:get().ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end));
end

function jwhm:nuke(tid, spell)
  if (AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0) < 50) then return end
  
  nukes:Nuke(tid, spell);
  -- AshitaCore:GetChatManager():QueueCommand('/magic Banish ' .. tid, 0);
end

return jwhm;
