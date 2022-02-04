local configs = {};

function tableMerge(t1, t2)
  for k,v in pairs(t2) do
      if type(v) == "table" then
          if type(t1[k] or false) == "table" then
              tableMerge(t1[k] or {}, t2[k] or {})
          else
              t1[k] = v
          end
      else
          t1[k] = v
      end
  end
  if next(t2) == nil then -- If the new table removed something, remove it here too
    for k,v in pairs(t1)do
        t1[k] = nil
    end
  end
  return t1
end

function load_settings(player)
  local f = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', {});
  configs['all'] = tableMerge(configs['all'],f);
  if (configs['all'][player] == nil)then
    -- Try again
    print ("Trying again");
    local f = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', {});
    configs['all'] = tableMerge(configs['all'],f);
    if (configs['all'][player] == nil)then
      configs['all'][player]={
        AutoCast = false,
        AutoHeal = false,
        AutoNuke = false,
        AutoPosition = false,
        AutoWS = false,
        HealThreshold = 50,
        IdleBuffs = false,
        SneakyTime = false,
        WeaponSkill = "",
        leader = "",
        tank = "",
        bard = {},
        corsair = {
          roll = false,
          roll1 = "",
          roll2 = "",
          rollvar1 = "",
          rollvar2 = ""
        },
        Summoner = {
          AutoPact = false,
          AutoRelease = false,
          AutoSummon = false,
          BPRage = {},
          BPWard = {},
          Summon = ""
        },
        geomancer = {},
        escape = false,
        follow = false
      }
      configs:save();
      print("New Character '"..player.. "' added to settings")
    end
  end
  return configs['all'];
end

function configs:get()
  local entity = GetPlayerEntity();
  if (not(entity)) then return end
  local player = entity.Name;
  if (configs['all']==nil)then
    configs['all'] = ashita.settings.load_merged(_addon.path .. '/settings/settings.json',{});
  end
  -- if (configs['all'][player] == nil) then -- This will use only local memory, not shared across characters
    load_settings(player);
  -- end
  return configs['all'][player];
end
  
function configs:getall()
  if (configs['all']==nil)then
    configs['all'] = ashita.settings.load(_addon.path .. '/settings/settings.json');
  end
  return configs['all'];
end

function configs:save()
  ashita.settings.save(_addon.path .. '/settings/settings.json', configs['all']);
end
return configs
