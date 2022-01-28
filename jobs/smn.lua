local config = require('config');
local party = require('party');
local actions = require('actions');
local packets = require('packets');
local buffs = require('behaviors.buffs')
local healing = require('behaviors.healing');
local magic = require('magic');
local zones = require('zones');
require('ffxi.vanatime');
require('ffxi.weather');

local abilities = packets.abilities;

--Some enums borrowed from https://github.com/Kinematics/GearSwap-Jobs/blob/master/SMN.lua
local pacts = {}
pacts.cure = {['Carbuncle']='Healing Ruby'}
pacts.curaga = {['Carbuncle']='Healing Ruby II', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'}
pacts.buffoffense = {['Carbuncle']='Glittering Ruby', ['Ifrit']='Crimson Howl', ['Garuda']='Hastega', ['Ramuh']='Rolling Thunder',
    ['Fenrir']='Ecliptic Growl'}
pacts.buffdefense = {['Carbuncle']='Shining Ruby', ['Shiva']='Frost Armor', ['Garuda']='Aerial Armor', ['Titan']='Earthen Ward',
    ['Ramuh']='Lightning Armor', ['Fenrir']='Ecliptic Howl', ['Diabolos']='Noctoshield', ['Cait Sith']='Reraise II'}
pacts.buffspecial = {['Ifrit']='Inferno Howl', ['Garuda']='Fleet Wind', ['Titan']='Earthen Armor', ['Diabolos']='Dream Shroud',
    ['Carbuncle']='Soothing Ruby', ['Fenrir']='Heavenward Howl', ['Cait Sith']='Raise II'}
pacts.debuff1 = {['Ramuh']='Thunderspark', ['Leviathan']='Slowga', ['Fenrir']='Lunar Cry',
    ['Diabolos']='Pavor Nocturnus', ['Cait Sith']='Eerie Eye'}
pacts.debuff2 = {['Ramuh']='Thunderspark', ['Shiva']='Sleepga', ['Leviathan']='Slowga', ['Fenrir']='Lunar Roar', ['Diabolos']='Somnolence'}
pacts.sleep = {['Shiva']='Sleepga', ['Diabolos']='Nightmare', ['Cait Sith']='Mewing Lullaby'}
pacts.atk = {['Ifrit']='Punch', ['Titan']='Rock Throw',['Leviathan']='Barracuda Dive',['Garuda']='Claw',['Shiva']='Axe Kick',['Ramuh']='Shock Strike',['Diabolos']='Camisado',['Carbuncle']='Poison Nails',['Fenrir']='Moonlit Charge'}
pacts.nuke2 = {['Ifrit']='Fire II', ['Shiva']='Blizzard II', ['Garuda']='Aero II', ['Titan']='Stone II',
    ['Ramuh']='Thunder II', ['Leviathan']='Water II', ['Fenrir']='Crescent Fang'}
pacts.nuke4 = {['Ifrit']='Fire IV', ['Shiva']='Blizzard IV', ['Garuda']='Aero IV', ['Titan']='Stone IV',
    ['Ramuh']='Thunder IV', ['Leviathan']='Water IV'}
pacts.bpmid = {['Ifrit']='Double Punch',['Titan']='Megalith Throw',['Shiva']='Double Slap',['Carbuncle']='Meteorite',['Leviathan']='Tail Whip'}
pacts.bp70 = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predator Claws', ['Titan']='Mountain Buster',
    ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Carbuncle']='Meteorite', ['Fenrir']='Eclipse Bite',
    ['Diabolos']='Nether Blast',['Cait Sith']='Regal Scratch'}
pacts.bp75 = {['Ifrit']='Meteor Strike', ['Shiva']='Heavenly Strike', ['Garuda']='Wind Blade', ['Titan']='Geocrush',
    ['Ramuh']='Thunderstorm', ['Leviathan']='Grand Fall', ['Carbuncle']='Holy Mist', ['Fenrir']='Lunar Bay',
    ['Diabolos']='Night Terror', ['Cait Sith']='Level ? Holy'}
pacts.astralflow = {['Ifrit']='Inferno', ['Shiva']='Diamond Dust', ['Garuda']='Aerial Blast', ['Titan']='Earthen Fury',
    ['Ramuh']='Judgment Bolt', ['Leviathan']='Tidal Wave', ['Carbuncle']='Searing Light', ['Fenrir']='Howling Moon',
    ['Diabolos']='Ruinous Omen', ['Cait Sith']="Altana's Favor"}

-- Wards table for creating custom timers   
local wards = {}
-- Base duration for ward pacts.
wards.durations = {
    ['Crimson Howl'] = 60, ['Earthen Armor'] = 60, ['Inferno Howl'] = 60, ['Heavenward Howl'] = 60,
    ['Rolling Thunder'] = 120, ['Fleet Wind'] = 120,
    ['Shining Ruby'] = 180, ['Frost Armor'] = 180, ['Lightning Armor'] = 180, ['Ecliptic Growl'] = 180,
    ['Glittering Ruby'] = 180, ['Hastega'] = 180, ['Noctoshield'] = 180, ['Ecliptic Howl'] = 180,
    ['Dream Shroud'] = 180,
    ['Reraise II'] = 3600
}


local spell_levels = {};

local weekdaynames = {"Firesday", "Earthsday", "Watersday", "Windsday",
"Iceday", "Lightningday", "Lightsday", "Darksday"};
local weathertype = {"Clear","Sunny","Cloudy","Fog","Fire","Fire2","Water","Water2","Earth","Earth2","Air","Air2","Ice","Ice2","Thunder","Thunder2","Light","Light2","Dark","Dark2"};
local weakto = {"Water", "Air", "Thunder","Ice","Fire","Earth","Dark","Light"}
local jsmn = {
  spell_levels = spell_levels,
};

function jsmn:siphon()
  --THIS ASSUMES YOU HAVE ALL SPIRITS LEARNED
  local playerEntity = GetPlayerEntity();
  if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then
    return;
  end
  local siphonElement;
  local avatar;
  local pet;
  local element;
  local spirit;
  local command = actions:new();
  if (playerEntity.PetTargetIndex ~= 0)then -- Have pet  
    pet = GetEntity(playerEntity.PetTargetIndex);
    element, spirit = string.match(pet.Name, "(.*)(Spirit)")
    if (element ~= nil)then -- Spirit pet
      siphonElement = element;
      print ("You have a ".. element .. " " .. spirit .. " summoned");
    else
      avatar = pet.Name;
      command
      :next(function(self)print("Release "..avatar); end)
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
      end)
      :next(partial(wait, 1));
    end
  end
  if (siphonElement == nil)then -- We don't have an elemental summoned

    local date = ashita.ffxi.vanatime.get_current_date();
    local dayelement;
    dayelement =  string.match(weekdaynames[date.weekday+1], "(.*)(sday)")
    if (dayelement == nil)then
      dayelement = string.match(weekdaynames[date.weekday+1], "(.*)(day)")
    end
    dayelement = string.gsub(string.gsub(dayelement,"Lightning","Thunder"),"Wind", "Air");
    local weather = ashita.ffxi.weather.get_weather()
    if (weather > 3 and (string.match(weathertype[weather+1], "2") or weakto[date.weekday+1]~=weathertype[weather+1]))then -- If Strong weather, or if weather is not weak against the day
      siphonElement = string.gsub(weathertype[weather+1],"2","");
      return
    else
      siphonElement = dayelement
    end
  end

  if (not spirit)then -- No pet
    command
    :next(function(self)print("Summon " .. siphonElement .. " Spirit"); end)
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/ma "'.. siphonElement ..' Spirit" <me>', -1);
    end)
    :next(partial(wait,2));
  end
  
  command
  :next(function(self)print("Suck em up"); end)
  :next(function(self)
    AshitaCore:GetChatManager():QueueCommand('/ja "Elemental Siphon" <me>', -1);
  end)

  if (not spirit) then -- If we summoned the spirit, release it
    command
    :next(partial(wait,1))
    :next(function(self)print("Releasing "..siphonElement.." Spirit"); end)
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
    end)
  end
  if (avatar)then -- If we had an avatar out already
    command
    :next(partial(wait,1))
    :next(function(self)print("Resummoning "..avatar); end)
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/ma "'..avatar..'" <me>', -1);
    end)
  end

  command:next(function(self) actions.busy = false; end);

  actions.busy = true;
  actions:queue(command);

end

function jsmn:tick()
  if (actions.busy) then return end
  if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
  if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
  local player = AshitaCore:GetDataManager():GetPlayer();
  local cnf = config:get();
  local smn = cnf['summoner'];
  local manapercent = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0);
  local playerEntity = GetPlayerEntity();

  if (manapercent < 70 and buffs:IsAble(abilities.ELEMENTAL_SIPHON) and not buffs:AbilityOnCD("Elemental Siphon") and cnf['AutoCast']==true)then
    return self:siphon();
  end
  if (playerEntity.PetTargetIndex == 0 and cnf['AutoCast']==true) then
    actions.busy = true;
    actions:queue(actions:new()
      :next(partial(magic.cast, magic, cnf['summon'], '<me>'))
      :next(partial(wait, 7))
      :next(function(self) actions.busy = false; end));
  else
    -- local pet = GetEntity(playerEntity.PetTargetIndex);
    -- if (pet ~= nil)then
    --   if (pet.HealthPercent <= 50)then
    --     if(not(buffs:AbilityOnCD("Spirit Link"))and buffs:IsAble(abilities.SPIRIT_LINK))then
    --       queueJobAbility = 'Spirit Link';
    --       queueTarget = '<me>';
    --     end
    --   end
    -- end

  end

  
  if (smn['practice'])then
    local mana = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0);
    if (player and mana > 50) then
      actions.busy = true;
      actions:queue(actions:new()
        :next(partial(magic.cast, magic, 'carbuncle', '<me>'))
        :next(partial(wait, 7))
        :next(function(self)
          AshitaCore:GetChatManager():QueueCommand('/ja release <me>', 0);
        end)
        :next(partial(wait, 2))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end

end

function jsmn:pact(type)
  if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
  local playerEntity = GetPlayerEntity();
  if (playerEntity.PetTargetIndex == 0)then 
    print("No avatar summoned");
    return
  end
  local pet = GetEntity(playerEntity.PetTargetIndex);
  if(string.match(pet.Name, "(.*)(Spirit)"))then
    print("Can't use pact with spirits.");
    return
  end
  print (type)
  if(not type)then
    print("No pact type given")
    return
  end
  if(not pacts[type])then
    print ("Unknown pact type ".. type);
    return
  end
  if(pacts[type][pet.Name])then
    if(type == 'astralflow')then
      local buffs = party:GetBuffs(0);
      if (not buffs[packets.status.EFFECT_ASTRAL_FLOW])then
        print("Astral flow not active!");
        return;
      end
    end
    actions.busy = true;
    actions:queue(actions:new()
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pet "'..pacts[type][pet.Name]..'"', -1);
      end)
      :next(partial(wait, 1))
      :next(function(self) actions.busy = false; end));
    return;
  else
    print(pet.Name.." does not have a ".. type .. " type pact.");
  end
end

function jsmn:attack(tid)

  actions:queue(actions:new()
  :next(function(self)
    AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
  end)
  :next(function(self)
    config:get().ATTACK_TID = tid;
    AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
  end)
  :next(function(self)
    AshitaCore:GetChatManager():QueueCommand('/pet "Assault" '.. tid, 0);
  end)
  );
end

function jsmn:summoner(summoner, command, arg)
  local cnf = config:get();
  local smn = cnf['summoner'];
  local onoff = smn['practice'] and 'on' or 'off';

  if (command ~= nil) then
    if (command == 'practice' and (arg == 'on' or arg == 'true')) then
      smn['practice'] = true;
      onoff = 'on';
    elseif (command == 'practice' and (arg == 'off' or arg == 'false')) then
      smn['practice'] = false;
      onoff = 'off';
    end
    config:save();
  end
end

return jsmn;
