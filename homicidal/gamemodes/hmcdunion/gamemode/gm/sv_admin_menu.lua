util.AddNetworkString("HMCD_AdminMenu_Action")

net.Receive("HMCD_AdminMenu_Action", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local action = net.ReadString()
    
    if action == "set_gamemode" then
        local gm = net.ReadString()
        local type = net.ReadInt(8)
        
        GAMEMODE.RoundNext = gm
        GAMEMODE.RoundNextType = type
        
        local typeName = ""
        if gm == "homicide" and HMCD_RoundsTypeNormalise and HMCD_RoundsTypeNormalise[type] then
            typeName = " (" .. HMCD_RoundsTypeNormalise[type] .. ")"
        elseif gm == "hl2coop" then
            typeName = " (Cooperative)"
        end
        
        PrintMessage(HUD_PRINTTALK, "Admin " .. ply:Nick() .. " set next gamemode to " .. gm .. typeName)
        
    elseif action == "set_role" then
        local target = net.ReadEntity()
        local role = net.ReadString()
        
        if IsValid(target) then
            target.Role = role
            target:SetNWString("RoleShow", role)
            
            -- Set basic colors if known (copied from sv_round.lua snippets)
            if role == "Traitor" then
                target:SetRoleColor(164,26,26)
            elseif role == "Rebel" then
                target:SetRoleColor(29,125,19)
            end
            
            PrintMessage(HUD_PRINTTALK, "Admin " .. ply:Nick() .. " set " .. target:Nick() .. "'s role to " .. role)
            
            -- Attempt to refresh loadout if round is active
            if GAMEMODE.RoundState == 1 then
                target:StripWeapons()
                target:StripAmmo()
                
                -- Homicide Logic
                if GAMEMODE.RoundName == "homicide" then
                    if HMCD_Loadout and HMCD_Loadout[role] and HMCD_Loadout[role][GAMEMODE.RoundType] then
                        for i,wep in pairs(HMCD_Loadout[role][GAMEMODE.RoundType]) do
                            target:Give(wep)
                        end
                    end
                    if HMCD_Loadout_Firearms and HMCD_Loadout_Firearms[role] and HMCD_Loadout_Firearms[role][GAMEMODE.RoundType] then
                         for i,wep in pairs(HMCD_Loadout_Firearms[role][GAMEMODE.RoundType]) do
                            if wep ~= "" then
                                target:Give(wep)
                                if role == "Traitor" then 
                                    local wepDat = weapons.Get(wep)
                                    if wepDat then
                                        target:GiveAmmo(wepDat.Primary.ClipSize, wepDat.Primary.Ammo, true) 
                                    end
                                end
                            end
                        end
                    end
                
                -- DM Logic
                elseif GAMEMODE.RoundName == "dm" and role == "Fighter" and DM_LoadoutMain and DM_LoadoutSecondary then
                     local mainwep = table.Random(DM_LoadoutMain)
                     local secwep = table.Random(DM_LoadoutSecondary)
                     target:Give(mainwep)
                     local mainDat = weapons.Get(mainwep)
                     if mainDat then
                        target:GiveAmmo(mainDat.Primary.ClipSize * 1.5, mainDat.Primary.Ammo, true)
                     end
                     target:Give(secwep)
                     local secDat = weapons.Get(secwep)
                     if secDat then
                        target:GiveAmmo(secDat.Primary.ClipSize * 0.5, secDat.Primary.Ammo, true)
                     end
                
                -- HL2 Logic
                elseif GAMEMODE.RoundName == "hl2" and HL2_Loadout and HL2_Loadout[role] then
                     local subclass = table.Random(table.GetKeys(HL2_Loadout[role]))
                     local weps = HL2_Loadout[role][subclass]
                     if weps then
                        for _, wep in pairs(weps) do target:Give(wep) end
                     end
                end
            end
        end
        
    elseif action == "end_round" then
        if GAMEMODE.EndRound then
            GAMEMODE:EndRound(3, ply)
        end
    end
end)
