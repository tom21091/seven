local actions = require('actions');
local packets = require('packets');
local party = require('party');
local buffs = require('behaviors/buffs');
local magic = require('magic');
local healing = require('behaviors/healing');
local nukes = require('behaviors.nukes');

local jblm = require('jobs.blm');
local jbrd = require('jobs.brd');
local jdnc = require('jobs.dnc');
local jdrg = require('jobs.drg');
local jdrk = require('jobs.drk');
local jrdm = require('jobs.rdm');
local jsam = require('jobs.sam');
local jpld = require('jobs.pld');
local jsch = require('jobs.sch');
local jthf = require('jobs.thf');
local jwar = require('jobs.war');
local jwhm = require('jobs.whm');
local jmnk = require('jobs.mnk');
local jsmn = require('jobs.smn');
local jcor = require('jobs.cor');
local jpup = require('jobs.pup');

local map = {};
map[Jobs.BlackMage] = jblm;
map[Jobs.Bard] = jbrd;
map[Jobs.Dancer] = jdnc;
map[Jobs.DarkKnight] = jdrk;
map[Jobs.Dragoon] = jdrg;
map[Jobs.RedMage] = jrdm;
map[Jobs.Scholar] = jsch;
map[Jobs.Thief] = jthf;
map[Jobs.Warrior] = jwar;
map[Jobs.WhiteMage] = jwhm;
map[Jobs.Monk] = jmnk;
map[Jobs.Summoner] = jsmn;
map[Jobs.Corsair] = jcor;
map[Jobs.Samurai] = jsam;
map[Jobs.Paladin] = jpld;
map[Jobs.Puppetmaster] = jpup;

local subjob = {};


  function subjob:subjob(tid, cnf, tp)
    -- SUBJOBS
    
    if (actions.busy==true)then return end
    local sub = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
    local status=party:GetBuffs(0);
    -- IF SUBJOB IS DANCER, DO DANCER THINGS
    if (sub == Jobs.Dancer and ATTACK_TID ~= nil) then
      if (tp >= 150 and buffs:IsAble(packets.abilities.DRAIN_SAMBA) and status[packets.stoe.DRAIN_SAMBA] ~= true) then
        actions.busy = true;
        actions:queue(actions:new()
          :next(partial(actions.pause, true))
          :next(partial(ability, 'Drain Samba', '<me>'))
          :next(partial(wait, 4))
          :next(partial(actions.pause, false))
          :next(function(self) actions.busy = false; end));
        return;
      end
    -- IF SUBJOB IS BARD, DO BARD THINGS
    elseif (sub == Jobs.Bard and (cnf.bard.songvar1 and not(status[packets.stoe[cnf.bard.songvar1]])) and (cnf.bard.sing)) then
      local status = party:GetBuffs(0);
      local statustbl = AshitaCore:GetDataManager():GetPlayer():GetStatusIcons();
      local need = not(status[packets.stoe[cnf.bard.songvar1]]);
      if (not(need) and packets.stoe[cnf.bard.songvar1] == packets.stoe[cnf.bard.songvar2]) then
        local buffcount = 0;
        for slot = 0, 31, 1 do
          local buff = statustbl[slot];
          if (buff == packets.stoe[cnf.bard.songvar1]) then
            buffcount = buffcount + 1;
          end
        end
        if (buffcount < 2) then
          need = true;
        end
      end
      local spell = magic:highest(cnf.bard.song1);
      if(spell)then
        actions.busy = true;
        actions:queue(actions:new()
          :next(partial(actions.pause, true))
          :next(partial(magic.cast, magic, spell , '<me>'))
          :next(partial(wait, 8))
          :next(partial(actions.pause, false))
          :next(function(self) actions.busy = false; end));
        return;
      end
    local cnf = config:get();
    elseif (sub == Jobs.Corsair and cnf.corsair.rollvar1 and not(status[packets.stoe[cnf.corsair.rollvar1]])) then
      if (buffs:IsAble(packets.abilities[cnf.corsair.rollvar1]) and not buffs:AbilityOnCD('PHANTOM_ROLL')) then
        actions.busy = true;
        actions:queue(actions:new()
          :next(partial(ability,  cnf.corsair.roll1, '<me>'))
          :next(partial(wait, 2))
          :next(function(self) actions.busy = false; end));
        return;
      end
    elseif(sub~=nil and sub~=0) then
      map[sub]:tick()
    end

  end

  return subjob;