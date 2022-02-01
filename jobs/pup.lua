local config = require('config');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs');
local nukes = require('behaviors.nukes');
local magic = require('magic');
local levels = require('levels');
local zones = require('zones');


return {

  tick = function(self)
    if not(zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    


  end,

  attack = function(self, tid)
    actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/pet Deploy ' .. tid, 0);
    end)
    :next(partial(wait, 0.5))
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      config:get().ATTACK_TID = tid;
      AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
    end)
    
  );
  end

};
