local config = require('config');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs');
local nukes = require('behaviors.nukes');
local magic = require('magic');
local party = require('party');


return {

  tick = function(self)
    local cnf = config:get();
    local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
    if (actions.busy) then return end
    if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end

    if(cnf.AutoCast==true and cnf.ATTACK_TID == tid)then
      nukes:Nuke(tid);
    end

  end,

  attack = function(self, tid)
    actions:queue(actions:new()
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
    end)
    :next(function(self)
      config:get().ATTACK_TID = tid;
    end));
  end,

  sleep = function(self, tid, aoe)
    if(buffs:IsAble(packets.abilities.ELEMENTAL_SEAL))then
      actions.busy = true;
      actions:queue(actions:new():next(partial(ability, 'Elemental Seal', '<me>'))
      :next(partial(wait, 1))
      :next(function(self) actions.busy = false; end));
    end
    if(aoe)then
      if(magic:CanCast('SLEEPGA')and ashita.ffxi.recast.get_spell_recast_by_index(packets.spells['SLEEPGA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['SLEEPGA'])then
        actions.busy = true;
        actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Sleepga', tid))
        :next(partial(wait, 3.5))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end)
      );
      end
    else
      if(magic:CanCast('SLEEP')and ashita.ffxi.recast.get_spell_recast_by_index(packets.spells['SLEEP'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['SLEEP'])then
        actions.busy = true;
        actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Sleep', tid))
        :next(partial(wait, 3))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end)
      );
      end
    end

  end,

  nuke = function(self, tid, spell)
    nukes:Nuke(tid, spell);
  end

};
