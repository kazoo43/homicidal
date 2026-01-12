local ply_GetAll = player.GetAll

local function GetDamageReason(dmgType)
	if not dmgType then return "Unknown" end
	if bit.band(dmgType, DMG_BUCKSHOT) != 0 then return "Shotgun" end
	if bit.band(dmgType, DMG_BULLET) != 0 then return "Gunshot" end
	if bit.band(dmgType, DMG_SLASH) != 0 then return "Laceration" end
	if bit.band(dmgType, DMG_CLUB) != 0 then return "Blunt Force" end
	if bit.band(dmgType, DMG_BLAST) != 0 then return "Explosion" end
	if bit.band(dmgType, DMG_BURN) != 0 or bit.band(dmgType, DMG_SLOWBURN) != 0 then return "Fire" end
	if bit.band(dmgType, DMG_VEHICLE) != 0 then return "Vehicle" end
	if bit.band(dmgType, DMG_FALL) != 0 then return "Fall" end
	if bit.band(dmgType, DMG_DROWN) != 0 then return "Drowning" end
	if bit.band(dmgType, DMG_POISON) != 0 or bit.band(dmgType, DMG_NERVEGAS) != 0 or bit.band(dmgType, DMG_ACID) != 0 then return "Poison" end
	if bit.band(dmgType, DMG_SHOCK) != 0 then return "Electricity" end
	if bit.band(dmgType, DMG_CRUSH) != 0 then return "Crushing" end
	if bit.band(dmgType, DMG_PHYSGUN) != 0 then return "Physics" end
	
	return "Unknown"
end

hook.Add("Think", "roundsynch", function()
    SetGlobalString("RoundName", GAMEMODE.RoundName)
    SetGlobalInt("RoundType", GAMEMODE.RoundType)
    SetGlobalInt("DMTime", GAMEMODE.DMTime)
end)

concommand.Add("union_gamemode", function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    if args[1] == "homicide" then
        local hmcd_roundtype = math.random(1,5)
        GAMEMODE.RoundNext = "homicide"
        GAMEMODE.RoundNextType = hmcd_roundtype
        PrintMessage(HUD_PRINTTALK, "Next gamemode: Homicide - " .. HMCD_RoundsTypeNormalise[hmcd_roundtype])
    elseif args[1] == "dm" then
        GAMEMODE.RoundNext = "dm"
        GAMEMODE.RoundNextType = 0
        PrintMessage(HUD_PRINTTALK, "Next gamemode: Deathmatch")
    elseif args[1] == "hl2" then
        GAMEMODE.RoundNext = "hl2"
        GAMEMODE.RoundNextType = 0
        PrintMessage(HUD_PRINTTALK, "Next gamemode: Half Life 2 - Deathmatch")
    elseif args[1] == "sandbox" then
        GAMEMODE.RoundNext = "sandbox"
        GAMEMODE.RoundNextType = 0
        PrintMessage(HUD_PRINTTALK, "Next gamemode: SandBox")
    end
end)

concommand.Add("union_gamemode_end", function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    GAMEMODE:EndRound(3, ply)
end)

concommand.Add("union_homicidetype", function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    print("Homicide Types: " .. "\n" .. "1 = Standart" .. "\n" .. "2 = SOE" .. "\n" .. "3 = JIHAD" .. "\n" .. "4 = Wild west")
    if args[1] == "1" or args[1] == "2" or args[1] == "3" or args[1] == "4" then
        local pizda = tonumber(args[1])
        GAMEMODE.RoundNextType = pizda
        PrintMessage(HUD_PRINTTALK, "Next Homicide roundtype: " .. HMCD_RoundsTypeNormalise[pizda])
    end
end)

concommand.Add("union_pidorsflash", function(ply,cmd,args)
	local attachmentsuka=ents.Create("ent_jack_hmcd_flashlight")
	attachmentsuka.HmcdSpawned=true
	attachmentsuka:SetPos(ply:GetShootPos()+ply:GetAimVector()*20)
    attachmentsuka:TurnOn()
	attachmentsuka:GetPhysicsObject():SetVelocity(ply:GetVelocity()+ply:GetAimVector()*100)
end)

---------- round logics???)())))))))
local pitch = math.random(80, 120)
local bodyvest = {
	"Level IIIA",
	"Level III"
}
function GM:StartRound()
	if #ply_GetAll()<2 then return end
    local hmcd_roundtype = math.random(1,5)
    local roundt = table.Random(Rounds)
    local rezhim = GAMEMODE.RoundNextType or math.random(1, 5)
    GAMEMODE.RoundName = GAMEMODE.RoundNext
    GAMEMODE.RoundNext = roundt
    
    -- Force HL2 Coop Mode on HL2 maps
    if HMCD_HL2Coop and HMCD_HL2Coop.IsHL2Map and HMCD_HL2Coop.IsHL2Map() then
        GAMEMODE.RoundName = "hl2coop"
        GAMEMODE.RoundNext = "hl2coop"
    end
    
    if GAMEMODE.RoundName == "homicide" then
        GAMEMODE.RoundType = rezhim
        GAMEMODE.RoundNextType = math.random(1, 5)
    else
        GAMEMODE.RoundType = 0
        GAMEMODE.RoundNextType = math.random(1, 5)
    end
	for _,ply in player.Iterator() do
        if ply.fake then
            ply.fake = false
            ply:SetNWBool("fake", false)
            ply.fakeragdoll = nil
            ply.FakeShooting = false
            ply:SetNWInt("FakeShooting", false)
        end
		ply:StripAmmo()
		ply:StripWeapons()
	end
    game.CleanUpMap(false, {"env_fire", "entityflame", "_firesmoke"})
	for _,ply in player.Iterator() do
        ply:UnSpectate()
		ply:Spawn()
	end
    if GAMEMODE.RoundName == "homicide" then
        timer.Simple(.3,function()
            if #ply_GetAll() < 2 then return end

            local traitor = table.Random(ply_GetAll())
            local gunman

            repeat
                gunman = table.Random(ply_GetAll())
            until gunman != traitor
            traitor.Role = "Traitor"
            traitor:SetNWString("RoleShow", "Traitor")
            traitor:SetRoleColor(164,26,26)
            if GAMEMODE.RoundType != 5 then
                gunman.SecretRole = "Gunman"
                gunman:SetNWString("RoleShow", "Gunman")
            end

            GAMEMODE.Traitor = traitor
            GAMEMODE.RoundState = 1
	        for _,ply in player.Iterator()do
	            if HMCD_Loadout[ply:GetNWString("RoleShow", "")][GAMEMODE.RoundType] then
		            for i,wep in pairs(HMCD_Loadout[ply:GetNWString("RoleShow", "")][GAMEMODE.RoundType]) do
				        ply:Give(wep)
	            	end
	            end
	            if HMCD_Loadout_Firearms[ply:GetNWString("RoleShow", "")][GAMEMODE.RoundType] then
		            for i,wep in pairs(HMCD_Loadout_Firearms[ply:GetNWString("RoleShow", "")][GAMEMODE.RoundType]) do
                        if wep != "" then
				            ply:Give(wep)
                            if ply:GetNWString("RoleShow", "") == "Traitor" then ply:GiveAmmo(weapons.Get(wep).Primary.ClipSize, weapons.Get(wep).Primary.Ammo, true) end
                            if GAMEMODE.RoundType == 2 and ply.Role == "Traitor" then
                                ply.Equipment[6]=true
		                        net.Start("hmcd_equipment")
		                        net.WriteInt(6,6)
		                        net.WriteBit(true)
		                        net.Send(ply)
                            end
                            if ply.Role == "Traitor" then
			                    ply:AllowFlashlight(true)
			                    ply.Equipment[HMCD_EquipmentNames[5]] = true
			                    net.Start("hmcd_equipment")
			                    net.WriteInt(5, 6)
			                    net.WriteBit(true)
			                    net.Send(ply)
                            end
                        end
	            	end
	            end
	        end
        end)
    elseif GAMEMODE.RoundName == "sandbox" then
        timer.Simple(.3,function()
	        for _, ply in player.Iterator() do
                ply.Role = "Sandboxer"
                GAMEMODE.RoundState = 1
	        end
        end)
    elseif GAMEMODE.RoundName == "dm" then
        GAMEMODE.DMTime = 10
        GAMEMODE.NoGun = true
        timer.Simple(12,function()
            timer.Create("DM_Timer", 1, 10, function()
                GAMEMODE.DMTime = GAMEMODE.DMTime - 1
                if timer.RepsLeft("DM_Timer") <= 0 then
                    timer.Remove("DM_Timer")
                    GAMEMODE.NoGun = false
                    SetGlobalFloat("ZoneStartTime", CurTime())
                end
            end)
        end)
        timer.Simple(.3, function()
            local poses = {}
            for k, ply in ipairs(player.GetAll()) do
                if ply:Alive() then
                    table.insert(poses, ply:GetPos())
                end
            end
            
            if #poses > 0 then
                local centerpoint = Vector(0, 0, 0)
                for i, pos in ipairs(poses) do
                    centerpoint:Add(pos)
                end
                centerpoint:Div(#poses)

                local dist = 0
                for i, pos in ipairs(poses) do
                    local dist2 = pos:Distance(centerpoint)
                    if dist < dist2 then
                        dist = dist2
                    end
                end

                GAMEMODE.ZonePos = centerpoint
                GAMEMODE.ZoneDistance = dist
                
                SetGlobalFloat("ZoneStartTime", 0)
                SetGlobalVector("ZonePos", centerpoint)
                SetGlobalFloat("ZoneDistance", dist)
            end

	        for _,ply in pairs(ply_GetAll())do
                ply.Role = "Fighter"
                ply:SetNWString("RoleShow", "Fighter")

                timer.Simple(1,function()
                    ply:SetNWString("Bodyvest", table.Random(bodyvest))
                    if math.random(1, 3) == 2 then
                        ply:SetNWString("Helmet", "ACH")
                    end
                end)

                local mainwep = table.Random(DM_LoadoutMain)
                local secwep = table.Random(DM_LoadoutSecondary)
				ply:Give(mainwep)
                ply:GiveAmmo(weapons.Get(mainwep).Primary.ClipSize * 1.5, weapons.Get(mainwep).Primary.Ammo, true)
				ply:Give(secwep)
                ply:GiveAmmo(weapons.Get(secwep).Primary.ClipSize * 0.5, weapons.Get(mainwep).Primary.Ammo, true)
                
                ply:Give("wep_jack_hmcd_oldgrenade_dm")
                ply:Give("wep_jack_hmcd_medkit")
                ply:Give("wep_jack_hmcd_bandage")

                for i=1, math.random(1, 4) do
                    local atth = math.random(6,15)
                    ply.Equipment[atth]=true
		            net.Start("hmcd_equipment")
		            net.WriteInt(atth,6)
		            net.WriteBit(true)
		            net.Send(ply)
                end
                GAMEMODE.RoundState = 1
	        end
        end)
    elseif GAMEMODE.RoundName == "hl2coop" then
        timer.Simple(.3, function()
            local players = ply_GetAll()
            local gordon = table.Random(players)
            
            for _, ply in ipairs(players) do
                ply:StripWeapons()
                ply:StripAmmo()
                ply:Give("wep_jack_hmcd_hands")

                local sex = ply.ModelSex or "male"
                if not Fighter_RebelModels[sex] then sex = "male" end

                local hl2_class = table.Random(Classes) -- "Medic" or "Fighter"
                ply:SetNWString("HL2_Class", hl2_class)
                
                if ply == gordon then
                    ply.Role = "Gordon"
                    ply:SetNWString("RoleShow", "Gordon Freeman")
                    ply:SetRoleColor(255, 155, 0)
                    
                    -- Gordon Model and HEV Suit
                    ply:SetModel("models/gfreakman/gordonf.mdl")
                    ply:SetBodygroup(1, 1)
                    
                    -- Direct HEV Suit Equip
                    ply:SetNWBool("HMCD_HEVSuit", true)
                    -- Removed explicit Bodyvest/Helmet NWStrings to avoid inventory item conflicts
                    ply:ChatPrint("HEV Suit Equipped. Systems Online.")
                    
                    -- Gordon specific weapon
                    ply:Give("weapon_physcannon")
                else
                    ply.Role = "Rebel"
                    ply:SetNWString("RoleShow", "Rebel")
                    ply:SetRoleColor(29, 125, 19)
                    
                    if hl2_class == "Medic" then
                        ply:SetModel(table.Random(Medic_RebelModels[sex]))
                    else
                        ply:SetModel(table.Random(Fighter_RebelModels[sex]))
                    end
                end
                
                -- Give HL2 Loadout (Rebel table for everyone, including Gordon)
                if HL2_Loadout["Rebel"] and HL2_Loadout["Rebel"][hl2_class] then
                    for _, wep in pairs(HL2_Loadout["Rebel"][hl2_class]) do
                        -- Filter out grenades and riot shields as requested
                        if wep ~= "wep_jack_hmcd_oldgrenade_dm" and 
                           wep ~= "wep_jack_hmcd_m67" and 
                           wep ~= "wep_jack_hmcd_grenade" and
                           wep ~= "wep_jack_hmcd_riotshield" then
                            ply:Give(wep)
                        end
                    end
                end
                
                if HL2_LoadoutFire_Main["Rebel"] and HL2_LoadoutFire_Main["Rebel"][hl2_class] then
                    local wep = table.Random(HL2_LoadoutFire_Main["Rebel"][hl2_class])
                    ply:Give(wep)
                    local wepData = weapons.Get(wep)
                    if wepData then
                        ply:GiveAmmo(wepData.Primary.ClipSize * 2, wepData.Primary.Ammo, true)
                    end
                end
                
                if HL2_LoadoutFire_Secondary["Rebel"] then
                    local wep = table.Random(HL2_LoadoutFire_Secondary["Rebel"])
                    ply:Give(wep)
                    local wepData = weapons.Get(wep)
                    if wepData then
                        ply:GiveAmmo(wepData.Primary.ClipSize * 1, wepData.Primary.Ammo, true)
                    end
                end

                ply:SetupHands()
            end
            
            GAMEMODE.RoundState = 1
        end)
    elseif GAMEMODE.RoundName == "hl2" then
        timer.Simple(.3, function()
	        for _, ply in player.Iterator() do
                local class = table.Random(Classes)
                if _ % 2 == 0 then
                    ply.Role = "Rebel"

                    ply:SetNWString("HL2_Class", class)
                    ply:SetRoleColor(29,125,19)

                    timer.Simple(1,function()
                        ply:SetNWString("Bodyvest", table.Random(bodyvest))
                        if math.random(1, 3) == 2 then
                            ply:SetNWString("Helmet", "ACH")
                        end
                    end)
                    if ply:GetNWString("HL2_Class", "") == "Medic" then
                        ply:SetModel(table.Random(Medic_RebelModels[ply.ModelSex]))
                    else
                        ply:SetModel(table.Random(Fighter_RebelModels[ply.ModelSex]))
                    end
                    if #ents.FindByClass("info_player_terrorist") > 0 then
                        ply:SetPos(ents.FindByClass("info_player_terrorist")[table.Random(1,10)]:GetPos())
                    end
                else
                    ply.Role = "Combine"
                    ply.ModelSex = "combine"
                    ply:SetRoleColor(32,98,185)
                    ply:SetNWString("Character_Name", "OTA Unit #" .. math.random(126, 978))
                    ply:SetNWString("HL2_Class", table.Random(ClassesCombine))
                    ply:SetModel(CombineModels[ply:GetNWString("HL2_Class","")])
                    if ply:GetNWString("HL2_Class","") == "Shotguner" then
                        ply:SetBodygroup(0, 1)
                    end
                    ply:SetupHands()
                    if #ents.FindByClass("info_player_terrorist") > 0 then
                        ply:SetPos(ents.FindByClass("info_player_counterterrorist")[table.Random(1,10)]:GetPos())
                    end
                end

		        for i,wep in pairs(HL2_Loadout[ply.Role][ply:GetNWString("HL2_Class")]) do
				    ply:Give(wep)
	            end
                local totalwep_main = table.Random(HL2_LoadoutFire_Main[ply.Role][ply:GetNWString("HL2_Class")])
                local totalwep_sec = table.Random(HL2_LoadoutFire_Secondary[ply.Role])
				ply:Give(totalwep_main)
                ply:GiveAmmo(weapons.Get(totalwep_main).Primary.ClipSize * 2, weapons.Get(totalwep_main).Primary.Ammo, true)
				
                ply:Give(totalwep_sec)
                ply:GiveAmmo(weapons.Get(totalwep_sec).Primary.ClipSize * 1, weapons.Get(totalwep_sec).Primary.Ammo, true)

                ply:SetNWString("RoleShow", ply.Role)
                GAMEMODE.RoundState = 1
	        end
            
            local rebels = {}
            for _, ply in player.Iterator() do
                if ply.Role == "Rebel" and ply:Alive() then
                    table.insert(rebels, ply)
                end
            end
            
            if #rebels >= 2 then
                local rpg = rebels[math.random(#rebels)]
                local crossbow
                repeat
                    crossbow = rebels[math.random(#rebels)]
                until crossbow != rpg
                
                rpg:Give("wep_jack_hmcd_rpg", false)
                rpg:GiveAmmo(1, "RPG_Round", true)
                crossbow:Give("wep_jack_hmcd_crossbow", false)
                crossbow:GiveAmmo(5, "XBowBolt", true)
            elseif #rebels == 1 then
                local rpg = rebels[1]
                rpg:Give("wep_jack_hmcd_rpg", false)
                rpg:GiveAmmo(1, "RPG_Round", true)
            end
        end)
    end
    timer.Simple(.5, function()
	    for _,ply in player.Iterator()do
	        net.Start("StartRound")
	        net.Send(ply)
	    end
    end)
end

hook.Add("PlayerPostThink", "IncreaseFOVOnSprint", function(ply)
    if !IsValid(ply) or !ply:Alive() then return end
    if ply:KeyDown(IN_FORWARD) and ply:KeyDown(IN_SPEED) then -- Говно резкое.. Надо с ванильного хомисайда портануть смену фова
        ply:SetFOV(105, 0.1) -- Попробовал закинуть в cl_hud, как обычно рубат момент нихрена на клиенте не работает хотя на вики написано обратное
    else
        ply:SetFOV(95, 0.1)
    end
end)

-- win traitor 1
-- lost traitor 2 
function GM:EndRound(reason, mvp, survived)
    PrintMessage(HUD_PRINTTALK, "Round end")
    net.Start("EndRound")

	    net.WriteUInt(reason, 8)
	    net.WriteEntity(mvp or Entity(-1))
        if mvp then
	        net.WriteVector(mvp:GetPlayerColor())
	        net.WriteString(mvp:GetNWString("Character_Name"))
        else
	        net.WriteVector(Vector(0,0,0))
	        net.WriteString("?")
        end
        if survived then
            net.WriteString(survived:GetNWString("Character_Name", ""))
        else
            net.WriteString("?")
        end

    net.Broadcast()

    timer.Simple(5, function()
        GAMEMODE:StartRound()
    end)
    GAMEMODE.RoundState = 0
end

function GM:Think()
    if GAMEMODE.RoundName == "sandbox" then return end
    if #ply_GetAll() < 2 then GAMEMODE.RoundState = 2 end
    if GAMEMODE.RoundState == 0 or GAMEMODE.RoundState == 2 then 
        if GAMEMODE.RoundState == 2 and #ply_GetAll() > 1 then 
            GAMEMODE:EndRound(1, table.Random(ply_GetAll()), nil) 
        end
    return end
    local alive_ply = GetAlivePlayerCount()
    if alive_ply <= 0 and GAMEMODE.RoundName != "hl2coop" then
        GAMEMODE:EndRound(1, table.Random(ply_GetAll()), nil)
    end

    if GAMEMODE.RoundName != "homicide" then
        GAMEMODE.RoundType = 0
    end

    if GAMEMODE.RoundName == "dm" then
        if alive_ply < 2 then
            GAMEMODE:EndRound(6, nil, GetLastPlayerAlive())
        end
    return end

    if GAMEMODE.RoundName == "hl2" then
        local alive_rebel, alive_combine = GetAliveRoleCount("Rebel"), GetAliveRoleCount("Combine")
        if alive_rebel < 1 then
            GAMEMODE:EndRound(4, nil)
        elseif alive_combine < 1 and alive_rebel > 0 then
            GAMEMODE:EndRound(5, nil)
        end
    return end
    
    if GAMEMODE.RoundName == "hl2coop" then
        if GAMEMODE.RoundState == 1 then
            local alive_players = 0
            for _, p in ipairs(player.GetAll()) do
                if p:Alive() then alive_players = alive_players + 1 end
            end
            
            if alive_players == 0 then
                GAMEMODE:EndRound(7, nil) -- Episode Failed
            end
        end
        return 
    end

    if GAMEMODE.RoundName == "homicide" then
        if GAMEMODE.RoundState == 1 then
            local alive_traitor, alive_innocent = GetAliveRoleCount("Traitor"), GetAliveRoleCount("Bystander")
            if alive_innocent < 1 then
                GAMEMODE:EndRound(1, GAMEMODE.Traitor)

            elseif alive_traitor < 1 and alive_innocent > 0 then
                GAMEMODE:EndRound(2, GAMEMODE.Traitor.LastAttacker)
                if GAMEMODE.Traitor.LastDamageType then
                    PrintMessage(HUD_PRINTTALK, "The murderer died because of " .. GetDamageReason(GAMEMODE.Traitor.LastDamageType))
                end
            end

        end

    return end
end

hook.Add("PlayerPostThink", "Spectating", function(ply)
    if !ply:GetNWBool("Spectating", false) then return end
    
    local alive = {}
    for _, p in ipairs(ply_GetAll()) do
        if p:Alive() and not p:GetNWBool("Spectating", false) then
            table.insert(alive, p)
        end
    end

	local plyselect = ply:GetNWEntity("SelectPlayer", Entity(-1))
    if !IsValid(plyselect) or !plyselect:Alive() or plyselect:GetNWBool("Spectating", false) then 
        if #alive > 0 then
            ply:SetNWEntity("SelectPlayer", table.Random(alive))
        end
    end

    ButtonInput = 0
    ply.ButtonInput = ply.ButtonInput or ButtonInput

        if ply:KeyDown(IN_ATTACK) and ply.ButtonInput < CurTime() then
            ply.ButtonInput = CurTime() + math.random(0.1, 0.5)
            if #alive > 0 then
                local target = table.Random(alive)
                if #alive > 1 then
                    -- Try to pick a different player
                    for i=1, 10 do
                        if target != ply:GetNWEntity("SelectPlayer") then break end
                        target = table.Random(alive)
                    end
                end
                ply:SetNWEntity("SelectPlayer", target)
            end
        end
        if ply:KeyDown(IN_ATTACK2) and ply.ButtonInput < CurTime() then
            ply.ButtonInput = CurTime() + math.random(0.1, 0.5)
            if ply:GetNWInt("SpectateMode") == 3 then ply:SetNWInt("SpectateMode", 1) else
                ply:SetNWInt("SpectateMode", 3)
                ply:UnSpectate()
            end
        end
        if ply:KeyDown(IN_RELOAD) and ply:GetNWInt("SpectateMode") != 3 and ply.ButtonInput < CurTime() then
            ply.ButtonInput = CurTime() + math.random(0.1, 0.5)
            ply:SetNWInt("SpectateMode", ( ply:GetNWInt("SpectateMode") + 1 ) % 3)
        end

    if ply:GetNWInt("SpectateMode") == 1 then
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(plyselect)
    end

    if ply:GetNWInt("SpectateMode") == 2 then
        ply:Spectate(OBS_MODE_IN_EYE)
        ply:SpectateEntity(plyselect)
    end

    if ply:GetNWInt("SpectateMode") == 3 then
        ply:Spectate(OBS_MODE_ROAMING)
        ply:SpectateEntity(nil)
    end

end)

hook.Add("PlayerDeathThink", "DeathThink", function(ply)
    return false
end)

hook.Add("PlayerPostThink", "ZoneDamage", function(ply)
	if GAMEMODE.RoundName != "dm" or GAMEMODE.RoundState != 1 then return end
    if (GetGlobalFloat("ZoneStartTime", 0) == 0) then return end
    if !ply:Alive() then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
	
	local pos = GetGlobalVector("ZonePos", Vector(0,0,0))
	local radius = GAMEMODE.GetZoneRadius()
	local radiussqr = radius * radius
	
	local ply_pos = ply:GetPos()
	if ply.fake and IsValid(ply:GetNWEntity("Ragdoll")) then
		ply_pos = ply:GetNWEntity("Ragdoll"):GetPos()
	end
	
	if (pos:DistToSqr(ply_pos) > radiussqr) then
        local dmg = DamageInfo()
        dmg:SetDamage(5 * FrameTime())
        dmg:SetDamageType(DMG_RADIATION)
        dmg:SetAttacker(ply)
        dmg:SetInflictor(ply)
        ply:TakeDamageInfo(dmg)
	end
end)