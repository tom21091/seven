local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local cfg = require('config');
local zones = require('zones');

local spell_levels = {};
spell_levels[packets.spells.POISONA] = 10;
spell_levels[packets.spells.PROTECT] = 10;
spell_levels[packets.spells.PARALYNA] = 12;
spell_levels[packets.spells.DEODORIZE] = 15;
spell_levels[packets.spells.BLINDNA] = 17;
spell_levels[packets.spells.SHELL] = 20;
spell_levels[packets.spells.SNEAK] = 20;
spell_levels[packets.spells.INVISIBLE] = 25;
spell_levels[packets.spells.PROTECT_II] = 30;
spell_levels[packets.spells.SHELL_II] = 40;
spell_levels[packets.spells.STONESKIN] = 44;

return {

  tick = function(self)
    if not (zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
    if (actions.busy) then return end
    local cnf = config:get();
    if (cfg['AutoCast']~=true) then return end
    if (cnf['AutoHeal']==true)then
      if (healing:Heal(spell_levels)) then return end -- first priority...
      if (buffs:Cleanse(spell_levels)) then return end
    end
    if (buffs:SneakyTime(spell_levels)) then return end
    if (buffs:IdleBuffs(spell_levels)) then return end
  end,

  attack = function(self, tid)
  end

};
