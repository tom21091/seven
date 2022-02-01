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
  return t1
end

function load_settings(player)
  local f = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', {});
  configs['all'] = tableMerge(configs['all'],f);
  if (configs['all'][player] == nil)then
    configs['all'][player]={
      WeaponSkill = "",
      leader = "",
      tank = "",
      summon = "",
      bard = {},
      corsair = {},
      summoner = {}
    }
    configs:save();
    print("New Character '"..player.. "' added to settings")
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
