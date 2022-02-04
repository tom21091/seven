local party = require('party');
local actions = require('actions');
local magic = require('magic');
local actions = require('actions');
local packets = require('packets');
local config = require('config');

return {

  -- Scans the party (including the current player) for those needing heals
  -- @returns list of party indicies needing heals
  NeedHeals = function(self, hppCheck)
    local need = {};
    local player = GetPlayerEntity();
    local iparty = AshitaCore:GetDataManager():GetParty();
    local zone = iparty:GetMemberZone(0);
    local i;
    for i = 0, 5 do
      local hpp = party:GetHPP(i);
      local samez = zone == iparty:GetMemberZone(i);
      local alive = iparty:GetMemberCurrentHPP(i) > 0;
      if (alive and samez and hpp > 0 and hpp < hppCheck) then
        table.insert(need, i);
      end
      table.sort(need, function(a, b)
        return party:GetHPP(a) < party:GetHPP(b);
      end);
    end
    return need;
  end,

  -- Heals a target in the party in need of heals
  -- @param table of spell levels
  Heal = function(self)
    local waits = {2, 2.25, 2.5, 2.5, 2.5};
    local waitsga = {4.5, 4.75, 5};
    local iparty = AshitaCore:GetDataManager():GetParty();
    local cnf = config:get();
    local idxs;
    if (cnf['HealThreshold'])then
      idxs = self:NeedHeals(cnf['HealThreshold']);
    else
      idxs = self:NeedHeals(60);
    end
    local dist = 1000;
    if (#idxs > 0 and #idxs <=2) then
      local target = idxs[1];
      if (target == 0) then
        target = '<me>'
        dist = 0
      else
        if (GetEntity(iparty:GetMemberTargetIndex(target)) ~= nil)then
          dist = math.sqrt(GetEntity(iparty:GetMemberTargetIndex(target)).Distance);
        end
        target = iparty:GetMemberServerId(target);
      end
      local spell, waitindex, spellkey = magic:highest("Cure", false);
      if (spell==nil)then return false end;
      if(ashita.ffxi.recast.get_spell_recast_by_index(packets.spells[spellkey])~=0 or AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) < packets.mpcost[spellkey] or dist > 20)then return false end;
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, spell, target))
        :next(partial(wait, waits[waitindex]+1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    elseif(#idxs >2)then
      local spell, waitindex, spellkey = magic:highest("Curaga", false);
      if (spell==nil)then return false end;
      if(ashita.ffxi.recast.get_spell_recast_by_index(packets.spells[spellkey])~=0 or AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) < packets.mpcost[spellkey])then return false end;
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, spell, '<me>'))
        :next(partial(wait, waitsga[waitindex]+1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end,

  -- Heals a target in the party in need of heals
  SupportHeal = function(self)
    local waits = {2, 2.25, 2.5, 2.5, 2.5};
    local iparty = AshitaCore:GetDataManager():GetParty();
    local idxs = self:NeedHeals(30);
    if (#idxs > 0) then
      local target = idxs[1];
      if (target == 0) then
        target = '<me>'
      else
        target = iparty:GetMemberServerId(target);
      end
      local spell, waitindex, spellkey = magic:highest("Cure", true);
      if (spell==nil)then return false end;
      if(ashita.ffxi.recast.get_spell_recast_by_index(packets.spells[spellkey])~=0 or AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) < packets.mpcost[spellkey])then return false end;
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, spell, target))
        :next(partial(wait, waits[waitindex]))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end,

  -- Heals a target in the party in need of heals
  -- @param table of spell levels
  DNCHeal = function(self, ability_levels)
    local iparty = AshitaCore:GetDataManager():GetParty();
    local idxs = self:NeedHeals(90);
    --if (#idxs > 3) then
    --      actions.busy = true;
    --      actions:queue(actions:new()
    --        :next(partial(ability, '"Curing Waltz"', target))
    --        :next(partial(wait, 8))
    --        :next(function(self) actions.busy = false; end));
    --      return true;
    --elseif (#idxs > 1)
    if (#idxs > 1) then
      local target = idxs[2];
      if (target == 0) then
        target = '<me>'
      else
        target = iparty:GetMemberServerId(target);
      end
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(ability, 'Curing Waltz', target))
        :next(partial(wait, 4))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
};
