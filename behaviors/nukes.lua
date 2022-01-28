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
    local names = {'THUNDER','BLIZZARD','FIRE','AERO','WATER','STONE','BANISH'};

    local waits = {1, 1.5, 3, 6};

    if(spellName==nil)then
      local spell, waitindex = magic:highest(names, true);
      if(spell==nil)then print('Get highest tier failed'); return false end
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(actions.pause, true))
        :next(function(self) print('Casting '.. spell); end)
        :next(partial(magic.cast, magic, spell , tid))
        :next(partial(wait, waits[waitindex]+1.5))
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
        :next(partial(wait, waits[waitindex]+1.5))
        :next(partial(actions.pause, false))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end

};
