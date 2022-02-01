local config = require('config');
local gui = { };
local variables = {
    ['Disable All']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoPosition']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoWS']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoCast']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoHeal']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoNuke']         = { {}, ImGuiVar_BOOLCPP },
    ['HealThreshold']         = { {}, ImGuiVar_INT32, 60 },
    ['IdleBuffs']         = { {}, ImGuiVar_BOOLCPP },
    ['SneakyTime']         = { {}, ImGuiVar_BOOLCPP },
    ['AutoFollow']         = { {}, ImGuiVar_BOOLCPP },

    ['AutoRoll']         = { {}, ImGuiVar_BOOLCPP },
    ['RollCombo1']                  = { {}, ImGuiVar_INT32, -1 },
    ['RollCombo2']                  = { {}, ImGuiVar_INT32, -1 },
    ['WeaponSkill']              = { {}, ImGuiVar_CDSTRING, 64 },
    ['Leader']              = { {}, ImGuiVar_CDSTRING, 64 },
    ['Tank']              = { {}, ImGuiVar_CDSTRING, 64 },
    ['AutoSummon']              = { {}, ImGuiVar_BOOLCPP },
    ['SummonCombo']                  = { {}, ImGuiVar_INT32, -1 },
}

local rolls = {
    "Corsair's Roll","Ninja Roll","Hunter's Roll","Chaos Roll","Magus's Roll","Healer's Roll","Drachen Roll","Choral Roll","Monk's Roll","Beast Roll","Samurai Roll","Evoker's Roll","Rogue's Roll","Warlock's Roll","Fighter's Roll","Puppet Roll","Gallant's Roll","Wizard's Roll","Dancer's Roll","Scholar's Roll","Naturalist's Roll", "Runeist's Roll"
}
local summons = {
    "Carbuncle", "Fenrir", "Diabolos", "Ifrit", "Titan", "Leviathan", "Garuda", "Shiva", "Ramuh", "Odin", "Alexander", "Cait Sith",
    "Light Spirit", "Dark Spirit", "Fire Spirit", "Earth Spirit", "Water Spirit", "Air Spirit", "Ice Spirit", "Thunder Spirit"
}

function gui:update()
    ashita.timer.once(1, function()self:loadConfig();self:update()end);
end

function gui:load()
    config:get();
    self.all = config:getall();
    for player, cnf in pairs(self.all) do        
        for k, v in pairs(variables) do
            -- Create the variable..
            if (v[2] >= ImGuiVar_CDSTRING) then 
                variables[k][1][player] = imgui.CreateVar(variables[k][2], variables[k][3]);
            else
                variables[k][1][player] = imgui.CreateVar(variables[k][2]);
            end
            
            -- Set a default value if present..
            if (#v > 2 and v[2] < ImGuiVar_CDSTRING) then
                imgui.SetVarValue(variables[k][1][player], variables[k][3]);
            end        
        end
    end
    self:update()--Start the update loop

    local style = imgui.style
    style.WindowRounding = 5
    style.FrameRounding = 6
end

function gui:unload()
    -- Cleanup the custom variables..
    for player, cnf in pairs(self.all) do
        for k, v in pairs(variables) do
            if (variables[k][1][player] ~= nil) then
                imgui.DeleteVar(variables[k][1][player]);
            end
            variables[k][1][player] = nil;
        end
    end
end

function gui:loadConfig()
    for player, cnf in pairs(self.all) do 
        imgui.SetVarValue(variables['Disable All'][1][player],cnf['escape']);
        imgui.SetVarValue(variables['AutoPosition'][1][player],cnf['AutoPosition']);
        imgui.SetVarValue(variables['AutoCast'][1][player],cnf['AutoCast']);
        imgui.SetVarValue(variables['AutoHeal'][1][player],cnf['AutoHeal']);
        imgui.SetVarValue(variables['AutoNuke'][1][player],cnf['AutoNuke']);
        imgui.SetVarValue(variables['HealThreshold'][1][player],cnf['HealThreshold']);
        imgui.SetVarValue(variables['AutoWS'][1][player],cnf['AutoWS']);
        imgui.SetVarValue(variables['IdleBuffs'][1][player],cnf['IdleBuffs']);
        imgui.SetVarValue(variables['SneakyTime'][1][player],cnf['SneakyTime']);
        imgui.SetVarValue(variables['AutoFollow'][1][player],cnf['follow']);
        imgui.SetVarValue(variables['WeaponSkill'][1][player],"");
        imgui.SetVarValue(variables['WeaponSkill'][1][player],cnf['WeaponSkill']);
        imgui.SetVarValue(variables['Leader'][1][player],"");
        imgui.SetVarValue(variables['Leader'][1][player],cnf['leader'].."\0\0");
        imgui.SetVarValue(variables['Tank'][1][player],"");
        imgui.SetVarValue(variables['Tank'][1][player],cnf['tank']);
        imgui.SetVarValue(variables['AutoRoll'][1][player],cnf['corsair']['roll']);
        for k ,v in pairs(summons) do
            if (cnf['summoner']['summon'] == v)then
                imgui.SetVarValue(variables['SummonCombo'][1][player],k-1);
            end
        end
        for k ,v in pairs(rolls) do
            if (cnf['corsair']['roll1'] == v)then
                imgui.SetVarValue(variables['RollCombo1'][1][player],k-1);
            end
            if (cnf['corsair']['roll2'] == v)then
                imgui.SetVarValue(variables['RollCombo2'][1][player],k-1);
            end
        end
    end
end

function gui:showMenu(player)
    if(imgui.Checkbox("Disable All", variables['Disable All'][1][player]))then
        self.all[player]['escape'] = imgui.GetVarValue(variables['Disable All'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Auto SA Position", variables['AutoPosition'][1][player]))then
        self.all[player]['AutoPosition'] = imgui.GetVarValue(variables['AutoPosition'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Auto WS", variables['AutoWS'][1][player]))then
        self.all[player]['AutoWS'] = imgui.GetVarValue(variables['AutoWS'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Idle Buffs", variables['IdleBuffs'][1][player]))then
        self.all[player]['IdleBuffs'] = imgui.GetVarValue(variables['IdleBuffs'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Sneaky Time", variables['SneakyTime'][1][player]))then
        self.all[player]['SneakyTime'] = imgui.GetVarValue(variables['SneakyTime'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Auto Follow", variables['AutoFollow'][1][player]))then
        self.all[player]['follow'] = imgui.GetVarValue(variables['AutoFollow'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.InputText("WeaponSkill", variables['WeaponSkill'][1][player], 64))then
        self.all[player]['WeaponSkill'] = imgui.GetVarValue(variables['WeaponSkill'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.InputText("Leader", variables['Leader'][1][player], 64))then
        self.all[player]['leader'] = imgui.GetVarValue(variables['Leader'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.InputText("Tank", variables['Tank'][1][player], 64))then
        self.all[player]['tank'] = imgui.GetVarValue(variables['Tank'][1][player]);
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Auto Cast", variables['AutoCast'][1][player]))then
        self.all[player]['AutoCast'] = imgui.GetVarValue(variables['AutoCast'][1][player]);
        config:save();
    end
    imgui.Separator();
    if (imgui.CollapsingHeader('AutoCast Settings', variables['AutoCast'][1][player])) then
        if(imgui.Checkbox("Nukes", variables['AutoNuke'][1][player]))then
            self.all[player]['AutoNuke'] = imgui.GetVarValue(variables['AutoNuke'][1][player]);
            config:save();
        end          
        if(imgui.Checkbox("Heals", variables['AutoHeal'][1][player]))then
            self.all[player]['AutoHeal'] = imgui.GetVarValue(variables['AutoHeal'][1][player]);
            config:save();
        end
        if(self.all[player]['AutoHeal'])then
            if(imgui.SliderInt('Threshold', variables['HealThreshold'][1][player], 1, 100, "%.0f%%"))then
                self.all[player]['HealThreshold'] = imgui.GetVarValue(variables['HealThreshold'][1][player]);
                config:save();
            end
        end
        if(imgui.Checkbox("AutoSummon", variables['AutoSummon'][1][player]))then
            self.all[player]['AutoSummon'] = imgui.GetVarValue(variables['AutoSummon'][1][player]);
            config:save();
        end
        if(self.all[player]['AutoSummon'])then
            if (imgui.Combo("Summon",variables['SummonCombo'][1][player],"Carbuncle\0Fenrir\0Diabolos\0Ifrit\0Titan\0Leviathan\0Garuda\0Shiva\0Ramuh\0Odin\0Alexander\0Cait Sith\0Light Spirit\0Dark Spirit\0Fire Spirit\0Earth Spirit\0Water Spirit\0Air Spirit\0Ice Spirit\0Thunder Spirit\0\0"))then
                self.all[player]['summoner']['summon'] = summons[imgui.GetVarValue(variables['SummonCombo'][1][player])+1]
                config:save();
            end
        end
    end
    imgui.Separator();
    if (imgui.CollapsingHeader('Corsair Settings')) then
        if(imgui.Checkbox("Enable", variables['AutoRoll'][1][player]))then
            self.all[player]['corsair']['roll'] = imgui.GetVarValue(variables['AutoRoll'][1][player]);
            config:save();
        end  
        if(imgui.Combo('Roll1', variables['RollCombo1'][1][player], "Corsair's Roll\0Ninja Roll\0Hunter's Roll\0Chaos Roll\0Magus's Roll\0Healer's Roll\0Drachen Roll\0Choral Roll\0Monk's Roll\0Beast Roll\0Samurai Roll\0Evoker's Roll\0Rogue's Roll\0Warlock's Roll\0Fighter's Roll\0Puppet Roll\0Gallant's Roll\0Wizard's Roll\0Dancer's Roll\0Scholar's Roll\0Naturalist's Roll\0Runeist's Roll\0\0"))then
            self.all[player]['corsair']['roll1'] = rolls[imgui.GetVarValue(variables['RollCombo1'][1][player])+1]
            self.all[player]['corsair']['rollvar1'] = self.all[player]['corsair']['roll1']:upper():gsub("'", ""):gsub(" ", "_");
            config:save();
        end
        if(imgui.Combo('Roll2', variables['RollCombo2'][1][player], "Corsair's Roll\0Ninja Roll\0Hunter's Roll\0Chaos Roll\0Magus's Roll\0Healer's Roll\0Drachen Roll\0Choral Roll\0Monk's Roll\0Beast Roll\0Samurai Roll\0Evoker's Roll\0Rogue's Roll\0Warlock's Roll\0Fighter's Roll\0Puppet Roll\0Gallant's Roll\0Wizard's Roll\0Dancer's Roll\0Scholar's Roll\0Naturalist's Roll\0Runeist's Roll\0\0"))then
            self.all[player]['corsair']['roll2'] = rolls[imgui.GetVarValue(variables['RollCombo2'][1][player])+1]
            self.all[player]['corsair']['rollvar2'] = self.all[player]['corsair']['roll2']:upper():gsub("'", ""):gsub(" ", "_");
            config:save();
        end
        
    end
    imgui.Separator();
end

function gui:main()
    imgui.SetNextWindowSize(300, 400, ImGuiSetCond_FirstUseEver);
    if (imgui.Begin('Seven') == false) then
        imgui.End();
        return;
    end
    if(imgui.SmallButton("Set Leader"))then
        local entity = GetPlayerEntity();
        if (not(entity)) then return end
        for player, cnf in pairs(self.all)do
            cnf['leader'] = entity.Name;
        end
        config:save();
    end
    for player, cnf in pairs(self.all)do
        if (imgui.TreeNode(player))then
            self:showMenu(player)
            imgui.TreePop();
        end
    end
    
    -- if(imgui.SmallButton("Save"))then
    --     config:save();
    -- end
    imgui.End();
end


return gui;