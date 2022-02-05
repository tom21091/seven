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
local mpcost = packets.mpcost;

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

function jsmn:getBestElemental()
  local Element
  local date = ashita.ffxi.vanatime.get_current_date();
  local dayelement;
  dayelement =  string.match(weekdaynames[date.weekday+1], "(.*)(sday)")
  if (dayelement == nil)then
    dayelement = string.match(weekdaynames[date.weekday+1], "(.*)(day)")
  end
  dayelement = string.gsub(string.gsub(dayelement,"Lightning","Thunder"),"Wind", "Air");
  local weather = ashita.ffxi.weather.get_weather()
  if (weather > 3 and (string.match(weathertype[weather+1], "2") or weakto[date.weekday+1]~=weathertype[weather+1]))then -- If Strong weather, or if weather is not weak against the day
    Element = string.gsub(weathertype[weather+1],"2","");
  else
    Element = dayelement
  end
  return Element
end

function jsmn:siphon(resummon)
  if (resummon == nil)then
    resummon = false
  end
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
    if (element == nil)then -- Spirit pet
      avatar = pet.Name;
      -- siphonElement = element;
      -- print ("You have a ".. element .. " " .. spirit .. " summoned");

    end
    command
    :next(function(self)
      if (avatar)then print("Release "..avatar);end end)
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
      pettarget = nil;
    end)
    :next(partial(wait, 1));
    -- end
  end
  if (siphonElement == nil)then -- We don't have an elemental summoned
    siphonElement = self:getBestElemental()
  end

  if (not spirit)then -- No pet
    command
    :next(function(self)print("Summon " .. siphonElement .. " Spirit"); end)
    :next(partial(actions.pause, true))
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/ma "'.. siphonElement ..' Spirit" <me>', -1);
    end)
    :next(partial(wait,2));
    command:next(partial(actions.pause, false))
  end
  
  command
  :next(function(self)print("Suck em up"); end)
  :next(function(self)
    if (GetPlayerEntity() ~=0 and GetPlayerEntity().PetTargetIndex ~=0)then
      AshitaCore:GetChatManager():QueueCommand('/ja "Elemental Siphon" <me>', -1);
    else
      print("No pet summoned, skipping Elemental Siphon");
    end
  end)

  if (not spirit) then -- If we summoned the spirit, release it
    command
    :next(partial(wait,1))
    :next(function(self)print("Releasing "..siphonElement.." Spirit"); end)
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
      pettarget = nil;
    end)
  end
  if (avatar and resummon)then -- If we had an avatar out already
    command
    :next(partial(wait,1))
    :next(function(self)print("Resummoning "..avatar); end)
    :next(partial(actions.pause, true))
    :next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/ma "'..avatar..'" <me>', -1);
    end)
    :next(partial(wait,7))
    command:next(partial(actions.pause, false))
  end

  command:next(function(self) actions.busy = false; end);

  actions.busy = true;
  actions:queue(command);

end

function jsmn:tick()
  if (actions.busy) then return end
  if (party:GetBuffs(0)[packets.status.EFFECT_INVISIBLE]) then return end
  if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
  local cnf = config:get();
  if (cnf['AutoCast'] ~= true) then return end
  local player = AshitaCore:GetDataManager():GetPlayer();
  local smn = cnf['Summoner'];
  local manapercent = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0);
  local playerEntity = GetPlayerEntity();

  if (manapercent < 70 and buffs:IsAble(abilities.ELEMENTAL_SIPHON) and not buffs:AbilityOnCD("Elemental Siphon"))then
    return self:siphon();
  end
  if (smn.AutoPact and ATTACK_TID)then
    local mana = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0);
    if(smn.BPRage[1] and not buffs:AbilityOnCD("Blood Pact: Rage"))then
      if(buffs:IsAble(abilities[smn.BPRage[2]:gsub(" ","_"):upper()]) and mpcost["SMN_"..smn.BPRage[2]:gsub(" ","_"):upper()]+20 <= mana)then
        return self:pact(smn.BPRage[1], smn.BPRage[2]);
      end
    end
    if(smn.BPWard[1] and not buffs:AbilityOnCD("Blood Pact: Ward"))then
      if (buffs:IsAble(abilities[smn.BPWard[2]:gsub(" ","_"):upper()]) and mpcost["SMN_"..smn.BPWard[2]:gsub(" ","_"):upper()]+20 <= mana)then
        return self:pact(smn.BPWard[1], smn.BPWard[2]);
      end
    end
  end
  if (playerEntity.PetTargetIndex == 0)then
    PETTID = nil
    if(smn['AutoSummon'] and ATTACK_TID ~= nil and manapercent > 10) then
      local bestelement = self:getBestElemental()
      local command = actions:new()
      local spirit
      _, spirit = string.match(smn["Summon"], "(.*)(Spirit)")
      command:next(partial(actions.pause, true))
      if(spirit)then
        if(smn['Summon']=="Auto Spirit")then
          command:next(partial(magic.cast, magic, bestelement.." Spirit", '<me>'))
        else
          command:next(partial(magic.cast, magic, smn["Summon"], '<me>'))
        end
          command:next(partial(wait, 2))
      else
          command:next(partial(magic.cast, magic, smn["Summon"], '<me>'))
          command:next(partial(wait, 7))
      end
      command:next(partial(actions.pause, false))
      command:next(function(self) actions.busy = false; end)
      actions.busy = true;
      actions:queue(command);
      return true
    end
  else
    local pet = GetEntity(playerEntity.PetTargetIndex);
    
    PETTID = pet.ServerId;
    if (ATTACK_TID == nil)then
      local tid = AshitaCore:GetDataManager():GetTarget():GetTargetServerId();
      if(smn.AutoRelease and (tid == playerEntity.ServerId or tid == 0x4000000))then
        actions.busy = true;
        actions:queue(actions:new()
        :next(function(self)
          AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', 0);
          pettarget = nil;
        end)
        :next(partial(wait, 1))
        :next(function(self)actions.busy = false; end));
      end
    elseif (pettarget ~= ATTACK_TID and not buffs:AbilityOnCD("Assault"))then -- Pet is not attacking the target
      actions.busy = true;
      actions:queue(actions:new()
      :next(function(self)
        if(ATTACK_TID~=nil)then
          AshitaCore:GetChatManager():QueueCommand('/pet "Assault" '.. ATTACK_TID, 0);
        end
      end)
      :next(partial(wait, 1))
      :next(function(self) actions.busy = false; end));
    end

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
          pettarget = nil;
        end)
        :next(partial(wait, 2))
        :next(function(self) actions.busy = false; end));
      return;
    end
  end

end

function jsmn:pact(avatar, ability)
  avatar=avatar:lower()
  local command = actions:new();
  local pet
  local skipsummon = false
  local playerEntity = GetPlayerEntity()
  if (playerEntity.PetTargetIndex ~= 0)then -- Have pet  
    pet = GetEntity(playerEntity.PetTargetIndex);
    if (pet.Name:lower() ~= avatar)then
      command
      :next(function(self)print("Release "..pet.Name); end)
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
        pettarget = nil;
      end)
      :next(partial(wait, 1));
    else
      skipsummon = true
    end
  end
  if (not skipsummon) then
    command:next(partial(actions.pause, true))
    :next(partial(magic.cast, magic, avatar, "<me>"))
    :next(partial(wait, 7))
    :next(partial(actions.pause, false));
  end
  command:next(function(self)
    if (GetPlayerEntity().PetTargetIndex ~=0)then
      AshitaCore:GetChatManager():QueueCommand('/pet "'..ability..'"', -1);
    end
  end)
  :next(partial(wait, 3))
  local smn = config:get()["Summoner"]
  if(smn.AutoRelease)then
    command:next(function(self)
      AshitaCore:GetChatManager():QueueCommand('/pet "Release" <me>', -1);
      pettarget = nil;
    end)
    :next(partial(wait, 1))
  end
  command
  :next(function(self) actions.busy = false; end);

  actions.busy = true;
  actions:queue(command);
end

-- function jsmn:pact(type)
--   if (not zones[AshitaCore:GetDataManager():GetParty():GetMemberZone(0)].hostile)then return end
--   local playerEntity = GetPlayerEntity();
--   if (playerEntity.PetTargetIndex == 0)then 
--     print("No avatar summoned");
--     return
--   end
--   local pet = GetEntity(playerEntity.PetTargetIndex);
--   if(string.match(pet.Name, "(.*)(Spirit)"))then
--     print("Can't use pact with spirits.");
--     return
--   end
--   print (type)
--   if(not type)then
--     print("No pact type given")
--     return
--   end
--   if(not pacts[type])then
--     print ("Unknown pact type ".. type);
--     return
--   end
--   if(pacts[type][pet.Name])then
--     if(type == 'astralflow')then
--       local buffs = party:GetBuffs(0);
--       if (not buffs[packets.status.EFFECT_ASTRAL_FLOW])then
--         print("Astral flow not active!");
--         return;
--       end
--     end
--     actions.busy = true;
--     actions:queue(actions:new()
--       :next(function(self)
--         AshitaCore:GetChatManager():QueueCommand('/pet "'..pacts[type][pet.Name]..'"', -1);
--       end)
--       :next(partial(wait, 1))
--       :next(function(self) actions.busy = false; end));
--     return;
--   else
--     print(pet.Name.." does not have a ".. type .. " type pact.");
--   end
-- end

function jsmn:attack(tid)

  actions:queue(actions:new()
  :next(function(self)
    AshitaCore:GetChatManager():QueueCommand('/attack ' .. tid, 0);
  end)
  :next(function(self)
    ATTACK_TID = tid;
    AshitaCore:GetChatManager():QueueCommand('/follow ' .. tid, 0);
  end)
  );
end

function jsmn:summoner(summoner, command, arg)
  local cnf = config:get();
  local smn = cnf['Summoner'];
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
