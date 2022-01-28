local util = require('util');
local packets = require('packets');
local levels = require('levels');
local spells = packets.spells;
local status = packets.status;
local mpcost = packets.mpcost;

return {

  cast = function(self, spell, target)
    AshitaCore:GetChatManager():QueueCommand('/magic "' .. spell .. '" ' .. target, 0);
  end,
  -- Can the player cast this spell?
  CanCast = function(self, spellkey, checkCooldown)
    local player = AshitaCore:GetDataManager():GetPlayer();
    local job = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
    local lvl = util:JobLvlCheck(false);
    local mana = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0);
    local maincan;
    if(checkCooldown==true)then
      if(ashita.ffxi.recast.get_spell_recast_by_index(spells[spellkey])~=0) then return end
    end
    if(levels.spell_levels[job]~=nil)then
      maincan = spells[spellkey] and mpcost[spellkey]<=mana and player:HasSpell(spells[spellkey]) and levels.spell_levels[job][spells[spellkey]] ~= nil and lvl >= levels.spell_levels[job][spells[spellkey]];
    else
      maincan = false;
    end
    job = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
    lvl = util:JobLvlCheck(true);
    if(job==0)then return maincan end
    local subcan;
    if(levels.spell_levels[job]~=nil)then
      subcan = spells[spellkey] and mpcost[spellkey]<=mana and player:HasSpell(spells[spellkey]) and levels.spell_levels[job][spells[spellkey]] ~= nil and lvl >= levels.spell_levels[job][spells[spellkey]];
    else
      subcan = false;
    end
    return maincan or subcan;
  end,

  highest = function(self, names, checkCooldown)
    local ranks = {'', 'II', 'III', 'IV', 'V', 'VI', 'VII'};
    if (type(names) == 'string') then
      names = {names};
    end
    --Count down ranks to find the strongest
    for i = #ranks, 1, -1 do
      for j, name in ipairs(names) do
        local key = name.upper(string.gsub(string.gsub(name,"'","")," ","_"));
        local spell = name;
        if (ranks[i] ~= '') then
          key = key .. '_' .. ranks[i];
          spell = spell .. ' ' .. ranks[i];
        end
        --print(''..key);
        if (spells[key] and self:CanCast(key, checkCooldown)) then
          return spell, i, key;
        end
      end
    end
  end

};