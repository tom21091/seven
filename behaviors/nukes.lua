local party = require('party');
local config = require('config');
local actions = require('actions');
local packets = require('packets');
local magic = require('magic');
local spells = packets.spells;
local status = packets.status;


return {


  -- cast nuke on target
  Nuke = function(self, tid, spellName)
    local names = {'THUNDER','BLIZZARD','FIRE','AERO','WATER','STONE','BANISH','HOLY'};

    local waits = {1, 1.5, 3, 6};
    local dist = math.sqrt(GetEntity(AshitaCore:GetDataManager():GetTarget():GetTargetIndex()).Distance); -- This selects the current target, which is technically wrong, but I'm not sure how to get the entity index from the tid
    if(dist>20)then return end
    if(spellName==nil)then
      local spell, waitindex = magic:highest(names, true);
      
      if(spell==nil)then return false end
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(function(self) print('Casting '.. spell); end)
        :next(partial(magic.cast, magic, spell , tid))
        :next(partial(wait, waits[waitindex]+1.1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return;
    else
      local spell, waitindex = magic:highest(spellName, false);
      if(spell==nil)then return false end
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(partial(magic.cast, magic, spell, tid))
        :next(function(self) print('Casting '.. spell); end)
        :next(partial(wait, waits[waitindex]+1.1))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end

};
