require 'ffxi.recast';

local party = require('party');
local config = require('config');
local actions = require('actions');
local magic = require('magic');
local util = require('util');
local packets = require('packets');
local levels = require('levels');

local spells = packets.spells;
local status = packets.status;

local buffs = {
};

-- Can the player use this ability?
-- @param the ability id
-- @param the ability level table
-- @param true/false on checking for SUBJOB
function buffs:IsAble(ability)
  local job = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
  local lvl = util:JobLvlCheck(false);
  local maincan = levels.ability_levels[job][ability] ~= nil and lvl >= levels.ability_levels[job][ability];
  job = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
  if(job==0)then return maincan end
  lvl = util:JobLvlCheck(true);
  local subcan = levels.ability_levels[job][ability] ~= nil and lvl >= levels.ability_levels[job][ability];
  return maincan or subcan;
end

-- Scans the party (including the current player) for those needing heals
-- @param status effect buff to check
-- @returns list of party indicies needing buff
function buffs:NeedBuff(buff, ...)
  local need = {};
  local iparty = AshitaCore:GetDataManager():GetParty();
  local zone = iparty:GetMemberZone(0);
  local exclude_classes = {...};
  local exclude = {}; -- turn into a map
  for i = 1, #exclude_classes do
    exclude[exclude_classes[i]] = true;
  end

  party:PartyBuffs(function(i, buffs, pid)
    if (i == 0) then return end
    local idx = party:ById(pid);
    local samez = zone == iparty:GetMemberZone(idx);
    local alive = iparty:GetMemberCurrentHPP(idx) > 0;
    if (alive and samez and buffs[buff] == nil) then
      if (exclude[iparty:GetMemberMainJob(idx)] ~= true) then
        table.insert(need, pid);
      end
    end
  end);

  if (#need == 0) then
    local alive = iparty:GetMemberCurrentHPP(0) > 0;
    if (alive and party:GetBuffs(0)[buff] == nil) then
      table.insert(need, GetPlayerEntity().ServerId);
    end
  end
  return need;
end

-- Scans the party (including the current player) for those needing heals
-- @param status effect buff to check
-- @returns list of party indicies needing buff
function buffs:NeedCleanse(status)
  local need = {};
  local iparty = AshitaCore:GetDataManager():GetParty();
  local zone = iparty:GetMemberZone(0);
  party:PartyBuffs(function(i, buffs, pid)
    local idx = party:ById(pid);
    local samez = zone == iparty:GetMemberZone(idx);
    local alive = iparty:GetMemberCurrentHPP(idx) > 0;
    if (alive and samez and buffs[status] ~= nil) then
      table.insert(need, pid);
    end
  end);
  return need;
end

-- cast idle buffs
function buffs:IdleBuffs()
  if (not(config:get())) then return end
  if (config:get()['IdleBuffs'] ~= true) then return end

  local need = buffs:NeedBuff(status.EFFECT_PROTECT);
  if (#need > 0) then
    local waits = {1,1.25,1.5,1.75};
    local spell, waitindex, spellkey = magic:highest("Protectra", false);
    if (spell~=nil) then
      if (ashita.ffxi.recast.get_spell_recast_by_index(spells[spellkey])~=0 or AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) < packets.mpcost[spellkey])then return end;
      actions.busy = true;
      actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic,  spell , '<me>'))
      :next(partial(wait, waits[waitindex]+1))
      :next(partial(actions.pause, false))
      :next(function(self) actions.busy = false; end));
      return true;
    end
  end

  need = buffs:NeedBuff(status.EFFECT_SHELL);
  if (#need > 0) then
    local waits = {1,1.25,1.5,1.75};
    local spell, waitindex, spellkey = magic:highest("Shellra", false);
    if (spell~=nil) then
      if (ashita.ffxi.recast.get_spell_recast_by_index(spells[spellkey])~=0 or AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) < packets.mpcost[spellkey])then return end;
      actions.busy = true;
      actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, spell , '<me>'))
      :next(partial(wait, waits[waitindex]))
      :next(partial(actions.pause, false))
      :next(function(self) actions.busy = false; end));
      return true;
    end
  end

  if (ATTACK_TID ~= nil) then
    need = buffs:NeedBuff(status.EFFECT_AUSPICE);
    if (#need > 0 and magic:CanCast('AUSPICE') and (ashita.ffxi.recast.get_spell_recast_by_index(spells['AUSPICE'])==0)) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Auspice', '<me>'))
        :next(partial(wait, 4))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end

  if (AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0) < 70) then return end
  -- local mybuffs = party:GetBuffs(0);
  -- if (magic:CanCast('STONESKIN') and mybuffs[status.EFFECT_STONESKIN] == nil) then
  --   actions.busy = true;
  --   actions:queue(actions:new()
  --     :next(partial(magic.cast, magic, 'Stoneskin', '<me>'))
  --     :next(partial(wait, 16))
  --     :next(function(self) actions.busy = false; end));
  --   return true;
  -- end
end

function buffs:Cleanse()
  local iparty = AshitaCore:GetDataManager():GetParty();
  local need = buffs:NeedCleanse(status.EFFECT_POISON);
  if (#need > 0) then
    if(magic:CanCast('POISONA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['POISONA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['POISONA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Poisona', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_BLINDNESS);
  if (#need > 0) then
    if (magic:CanCast('BLINDNA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['BLINDNA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['BLINDNA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Blindna', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_PARALYSIS);
  if (#need > 0) then
    if(magic:CanCast('PARALYNA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['PARALYNA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['PARALYNA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Paralyna', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_CURSE_I);
  if (#need > 0) then
    print('cursna1');
    if(magic:CanCast('CURSNA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['CURSNA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['CURSNA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Cursna', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_CURSE_II);
  if (#need > 0) then
    print('cursna2');
    if (magic:CanCast('CURSNA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['CURSNA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['CURSNA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Cursna', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_DOOM);
  if (#need > 0) then
    if (magic:CanCast('CURSNA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['CURSNA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['CURSNA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Cursna', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_PETRIFICATION);
  if (#need > 0) then
    if(magic:CanCast('STONA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['STONA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['STONA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Stona', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
  need = buffs:NeedCleanse(status.EFFECT_SILENCE);
  if (#need > 0) then
    if(magic:CanCast('SILENA')and ashita.ffxi.recast.get_spell_recast_by_index(spells['SILENA'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['SILENA'])then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, 'Silena', need[math.random(#need)]))
        :next(partial(wait, 1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return true;
    end
  end
end

function buffs:SneakyTime()
  if (config:get()['SneakyTime'] ~= true) then return end
  local iparty = AshitaCore:GetDataManager():GetParty();
  if (iparty:GetMemberCurrentMPP(0) < 15) then return end

  local need = buffs:NeedBuff(status.EFFECT_SNEAK, Jobs.WhiteMage);
  if (magic:CanCast('SNEAK') and #need > 0 and ashita.ffxi.recast.get_spell_recast_by_index(spells['SNEAK'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['SNEAK']) then
    actions.busy = true;
    print('Sneak');
    actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, 'Sneak', need[math.random(#need)]))
      :next(partial(wait, 2))
      :next(partial(actions.pause, false))
      :next(function(self) actions.busy = false; end));
    return true;
  end

  need = buffs:NeedBuff(status.EFFECT_INVISIBLE, Jobs.WhiteMage);
  if (magic:CanCast('INVISIBLE') and #need > 0 and ashita.ffxi.recast.get_spell_recast_by_index(spells['INVISIBLE'])==0 and AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0) > packets.mpcost['INVISIBLE']) then
    -- print('need invis ' .. ashita.settings.JSON:encode_pretty(need, nil, { pretty = true, align_keys = false, indent = '    ' }));
    actions.busy = true;
    actions:queue(actions:new()
      :next(partial(actions.pause, true))
      :next(partial(magic.cast, magic, 'Invisible', need[math.random(#need)]))
      :next(partial(wait, 2))
      :next(partial(actions.pause, false))
      :next(function(self) actions.busy = false; end));
    return true;
  end
end

function buffs:AbilityOnCD(abilityName)
  local r = AshitaCore:GetResourceManager();
  local onCD = false;
  for x = 0, 31 do
    if (ashita.ffxi.recast.get_ability_recast_by_index(x) > 0) then
      local ability = r:GetAbilityByTimerId(ashita.ffxi.recast.get_ability_id_from_index(x));
      if (ability.Name[0] == abilityName) then
        onCD = true;
      end
    end
  end
  return onCD;
end

return buffs;
