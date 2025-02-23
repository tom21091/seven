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
    ['NukeManaCutoff']         = { {}, ImGuiVar_INT32, 20 },
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
    ['AutoPact']              = { {}, ImGuiVar_BOOLCPP },
    ['AutoRelease']              = { {}, ImGuiVar_BOOLCPP },

    ['BPRageSelectable1']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable2']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable3']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable4']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable5']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable6']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPRageSelectable7']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPWardSelectable1']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPWardSelectable2']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPWardSelectable3']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPWardSelectable4']                 = { {}, ImGuiVar_BOOLCPP},
    ['BPWardSelectable5']                 = { {}, ImGuiVar_BOOLCPP},
}

local rolls = {
    "Corsair's Roll","Ninja Roll","Hunter's Roll","Chaos Roll","Magus's Roll","Healer's Roll","Drachen Roll","Choral Roll","Monk's Roll","Beast Roll","Samurai Roll","Evoker's Roll","Rogue's Roll","Warlock's Roll","Fighter's Roll","Puppet Roll","Gallant's Roll","Wizard's Roll","Dancer's Roll","Scholar's Roll","Naturalist's Roll", "Runeist's Roll"
}
local summons = {
    "Carbuncle", "Fenrir", "Diabolos", "Ifrit", "Titan", "Leviathan", "Garuda", "Shiva", "Ramuh", "Odin", "Alexander", "Cait Sith",
    "Light Spirit", "Dark Spirit", "Fire Spirit", "Earth Spirit", "Water Spirit", "Air Spirit", "Ice Spirit", "Thunder Spirit", "Auto Spirit"
}
local BPRage = {
    Carbuncle = {"Poison Nails", "Meteorite"},
    Diabolos = {"Camisado", "Nether Blast"},
    Fenrir = {"Moonlit Charge", "Crescent Fang", "Eclipse Bite"},
    Garuda = {"Claw", "Aero II", "Aero IV", "Predator Claws", "Wind Blade"},
    Ifrit = {"Punch","Fire II", "Burning Strike", "Double Punch", "Fire IV", "Flaming Crush", "Meteor Strike"},
    Leviathan = {"Barracuda Dive", "Water II", "Tail Whip", "Water IV","Spinning Dive", "Grand Fall"},
    Ramuh = { "Shock Strike", "Thunder II", "Thunderspark", "Thunder IV", "Chaotic Strike", "Thunderstorm"},
    Shiva = {"Axe Kick", "Blizzard II", "Double Slap", "Blizzard IV", "Rush", "Heavenly Strike"},
    Titan = {"Rock Throw", "Stone II", "Rock Buster", "Megalith Throw", "Stone IV","Mountain Buster", "Geocrush"}
}
local BPWard = {
    Carbuncle = {"Healing Ruby","Shining Ruby", "Glittering Ruby", "Healing Ruby II"},
    Diabolos = {"Somnolence", "Nightmare", "Ultimate Terror", "NoctoShield", "Dream Shroud"},
    Fenrir = {"Lunar Cry", "Lunar Roar", "Ecliptic Growl", "Ecliptic Howl"},
    Garuda = {"Aerial Armor", "Whispering Wind", "Hastega"},
    Ifrit = {"Crimson Howl"},
    Leviathan = {"Slowga", "Spring Water"},
    Ramuh = {"Rolling Thunder", "Lightning Armor"},
    Shiva = {"Frost Armor", "Sleepga"},
    Titan = {"Earthen Ward"}
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
        imgui.SetVarValue(variables['NukeManaCutoff'][1][player],cnf['NukeManaCutoff']);
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
        imgui.SetVarValue(variables['AutoSummon'][1][player],cnf['Summoner']['AutoSummon']);
        imgui.SetVarValue(variables['AutoPact'][1][player],cnf['Summoner']['AutoPact']);
        imgui.SetVarValue(variables['AutoRelease'][1][player],cnf['Summoner']['AutoRelease']);
        for k ,v in pairs(summons) do
            if (cnf['Summoner']['Summon'] == v)then
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
    if(imgui.SmallButton("Set Leader"))then
        for p, cnf in pairs(self.all)do
            cnf['leader'] = player;
        end
        config:save();
    end
    imgui.Separator();
    if(imgui.Checkbox("Disable All", variables['Disable All'][1][player]))then
        self.all[player]['escape'] = imgui.GetVarValue(variables['Disable All'][1][player]);
        config:save();
    end
    
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
    if (imgui.TreeNode('Autocast Settings')) then
        if(imgui.Checkbox("Nukes", variables['AutoNuke'][1][player]))then
            self.all[player]['AutoNuke'] = imgui.GetVarValue(variables['AutoNuke'][1][player]);
            config:save();
        end 
        if(self.all[player]['AutoNuke'])then
            if(imgui.SliderInt('Mana Cutoff', variables['NukeManaCutoff'][1][player], 0, 100, "%.0f%% MP"))then
                self.all[player]['NukeManaCutoff'] = imgui.GetVarValue(variables['NukeManaCutoff'][1][player]);
                config:save();
            end
        end         
        if(imgui.Checkbox("Heals", variables['AutoHeal'][1][player]))then
            self.all[player]['AutoHeal'] = imgui.GetVarValue(variables['AutoHeal'][1][player]);
            config:save();
        end
        if(self.all[player]['AutoHeal'])then
            if(imgui.SliderInt('Threshold', variables['HealThreshold'][1][player], 1, 100, "%.0f%% HP"))then
                self.all[player]['HealThreshold'] = imgui.GetVarValue(variables['HealThreshold'][1][player]);
                config:save();
            end
        end
        if (imgui.CollapsingHeader('Summoner Settings')) then
            imgui.Columns(2, nil, false);
            if(imgui.Checkbox("AutoSummon", variables['AutoSummon'][1][player]))then
                self.all[player]['Summoner']['AutoSummon'] = imgui.GetVarValue(variables['AutoSummon'][1][player]);
                config:save();
            end
            imgui.NextColumn();
            if (imgui.Combo("Summon",variables['SummonCombo'][1][player],"Carbuncle\0Fenrir\0Diabolos\0Ifrit\0Titan\0Leviathan\0Garuda\0Shiva\0Ramuh\0Odin\0Alexander\0Cait Sith\0Light Spirit\0Dark Spirit\0Fire Spirit\0Earth Spirit\0Water Spirit\0Air Spirit\0Ice Spirit\0Thunder Spirit\0Auto Spirit\0\0"))then
                self.all[player]['Summoner']['Summon'] = summons[imgui.GetVarValue(variables['SummonCombo'][1][player])+1]
                config:save();
            end
            imgui.NextColumn();
            if(imgui.Checkbox("AutoPact", variables['AutoPact'][1][player]))then
                self.all[player]['Summoner']['AutoPact'] = imgui.GetVarValue(variables['AutoPact'][1][player]);
                config:save();
            end
            imgui.NextColumn();
            if(imgui.Checkbox("AutoRelease", variables['AutoRelease'][1][player]))then
                self.all[player]['Summoner']['AutoRelease'] = imgui.GetVarValue(variables['AutoRelease'][1][player]);
                config:save();
            end
            imgui.Columns(1);
            imgui.Text("Current: ")
            imgui.Columns(2, nil, false);

            if(self.all[player]['Summoner']['BPRage'] and self.all[player]['Summoner']['BPRage'][1])then
                imgui.Text(self.all[player]['Summoner']['BPRage'][1]..":"..self.all[player]['Summoner']['BPRage'][2])
            else
                imgui.Text("");
            end
            imgui.NextColumn();
            if(self.all[player]['Summoner']['BPWard'] and self.all[player]['Summoner']['BPWard'][1]) then
                imgui.Text(self.all[player]['Summoner']['BPWard'][1]..":"..self.all[player]['Summoner']['BPWard'][2])
            else
                imgui.Text("");
            end
            imgui.NextColumn();
            if(imgui.SmallButton("Clear Rage"))then
                self.all[player]['Summoner']['BPRage']={}           
                config:save();
            end
            imgui.NextColumn();
            if(imgui.SmallButton("Clear Ward"))then
                self.all[player]['Summoner']['BPWard']={}           
                config:save();
            end
            imgui.Columns(1);
            imgui.Separator();
            for Avatar, _ in pairs(BPRage) do
                if (imgui.TreeNode(Avatar)) then
                    imgui.Columns(2, nil, false);
                    for i, ability in ipairs(BPRage[Avatar])do
                        if (imgui.Selectable(ability, imgui.GetVarValue(variables['BPRageSelectable'..i][1][player]), ImGuiSelectableFlags_AllowDoubleClick)) then
                            if (imgui.IsMouseDoubleClicked(0)) then
                                AshitaCore:GetChatManager():QueueCommand('/seven pact ' .. player .. ' ' .. Avatar .. ' "'.. ability ..'"', 1);
                                self.all[player]['Summoner']['BPRage']={}
                                config:save();
                            else
                                self.all[player]['Summoner']['BPRage']={Avatar, ability}
                                config:save();
                            end
                            
                        end
                    end
                    imgui.NextColumn();
                    for i, ability in ipairs(BPWard[Avatar])do
                        if (imgui.Selectable(ability, imgui.GetVarValue(variables['BPWardSelectable'..i][1][player]), ImGuiSelectableFlags_AllowDoubleClick)) then
                            if (imgui.IsMouseDoubleClicked(0)) then
                                AshitaCore:GetChatManager():QueueCommand('/seven pact ' .. player .. ' ' .. Avatar .. ' "'.. ability ..'"', 1);
                                self.all[player]['Summoner']['BPWard']={}
                                config:save();
                            else
                                self.all[player]['Summoner']['BPWard']={Avatar, ability}
                                config:save();
                            end
                        end
                    end
                    imgui.Columns(1);
                    imgui.TreePop()
                end
            end
        end
        imgui.TreePop()
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
end

function gui:main()
    -- imgui.SetNextWindowSize(300, 400, ImGuiSetCond_FirstUseEver);
    -- if (imgui.Begin('Seven') == false) then
    --     imgui.End();
    --     return;
    -- end
    
    for player, cnf in pairs(self.all)do
        imgui.SetNextWindowSize(300, 400, ImGuiSetCond_FirstUseEver);
        if (imgui.Begin(player) == false) then
            imgui.End();
            return;
        end
        self:showMenu(player)
        -- if (imgui.TreeNode(player))then
            -- self:showMenu(player)
        --     imgui.TreePop();
        -- end
        imgui.End();
    end
    
    -- if(imgui.SmallButton("Save"))then
    --     config:save();
    -- end
    -- imgui.End();
end


return gui;