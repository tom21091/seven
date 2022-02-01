local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs');
local healing = require('behaviors.healing');
local nukes = require('behaviors.nukes');
local zones = require('zones');

return {

  tick = function(self)
    --local cnf = config:get();
    --local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
    local cnf = config:get();

    if(cnf.AutoCast~=true)then return end
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    local tp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentTP(0);
    if ( cnf.ATTACK_TID == tid and cnf['AutoNuke']==true) then
      if (nukes:Nuke(tid)) then return end
    end
    if (cnf['AutoHeal']==true)then
      if (healing:Heal()) then return end
      if (buffs:Cleanse()) then return end
    end
    if (buffs:SneakyTime()) then return end
    if (buffs:IdleBuffs()) then return end

    

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
