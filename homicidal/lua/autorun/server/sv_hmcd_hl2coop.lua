if CLIENT then return end

HMCD_HL2Coop = HMCD_HL2Coop or {}

function HMCD_HL2Coop.IsHL2Map()
    local map = game.GetMap()
    -- Check if it starts with d1_, d2_, d3_, ep1_, ep2_ or is a known hl2 map
    if string.sub(map, 1, 3) == "d1_" or string.sub(map, 1, 3) == "d2_" or string.sub(map, 1, 3) == "d3_" then
        return true
    end
    if string.sub(map, 1, 4) == "ep1_" or string.sub(map, 1, 4) == "ep2_" or string.sub(map, 1, 4) == "ep3_" then
        return true
    end
    -- Additional check for common HL2 map names just in case
    if string.find(map, "^d1_") or string.find(map, "^d2_") or string.find(map, "^d3_") then
        return true
    end
    if string.find(map, "^ep1_") or string.find(map, "^ep2_") or string.find(map, "^ep3_") then
        return true
    end
    return false
end

hook.Add("InitPostEntity", "HMCD_HL2Coop_ForceMode", function()
    if HMCD_HL2Coop.IsHL2Map() then
        GAMEMODE.RoundNext = "hl2coop"
        GAMEMODE.RoundNextType = 0
        print("[HMCD] Forced HL2 Coop mode for map: " .. game.GetMap())
    end
end)



-- Offset players around spawn and prevent spawn kills
hook.Add("PlayerSpawn", "HMCD_HL2Coop_SpawnSafety", function(ply)
    if GAMEMODE.RoundName == "hl2coop" then
        -- 1. Prevent spawn kill (Godmode temporarily)
        ply:GodEnable()
        
        -- 2. Disable collision with other players to prevent stuck/crush
        ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
        
        -- 3. Move player around the spawn point immediately
        local center = ply:GetPos()
        local idx = ply:EntIndex()
        
        -- Attempt to find a clear spot in a spiral pattern
        local found = false
        for i = 0, 8 do
            local dist = 45 + (i * 25) -- Increase distance
            local ang = (idx * 60) + (i * 45) -- Rotate based on index and ring
            local offset = Vector(math.cos(math.rad(ang)) * dist, math.sin(math.rad(ang)) * dist, 5)
            local targetPos = center + offset
            
            -- Check if this spot is clear of world geometry (ignoring players)
            local tr = util.TraceHull({
                start = targetPos,
                endpos = targetPos,
                mins = ply:OBBMins(),
                maxs = ply:OBBMaxs(),
                mask = MASK_PLAYERSOLID_BRUSHONLY -- Only check walls/world
            })
            
            if not tr.Hit then
                ply:SetPos(targetPos)
                found = true
                break
            end
        end
        
        -- Disable godmode after a safe period
        timer.Simple(6, function()
            if IsValid(ply) then
                ply:GodDisable()
                -- Note: We keep COLLISION_GROUP_PASSABLE_DOOR to prevent players sticking together if they walk into each other
            end
        end)
    end
end)

-- Force spawn points to be suitable to prevent engine from rejecting spawns
hook.Add("IsSpawnpointSuitable", "HMCD_HL2Coop_ForceSuitable", function(ply, spawn, makeSuitable)
    if GAMEMODE.RoundName == "hl2coop" then
        return true
    end
end)

hook.Add("PlayerInitialSpawn", "HMCD_HL2Coop_LateJoin", function(ply)
    if GAMEMODE.RoundName == "hl2coop" and GAMEMODE.RoundState == 1 then
        -- Late joiner
        ply:KillSilent()
        ply:Spectate(OBS_MODE_ROAMING)
        ply:SetNWInt("SpectateMode", 1) -- Custom spectate mode tracker if needed
        ply:ChatPrint("Please wait for other players to reach the level transition.")
    end
end)

-- Handle Level Transition (Spectators waiting)
-- MOVED TO sv_hmcd_hl2coop_trigger.lua TO PREVENT MESSY LOGIC AND ENSURE CLEAN REWRITE

local weaponReplacements = {
    ["weapon_stunstick"] = "ent_jack_hmcd_stunstick",
    ["weapon_crowbar"] = "ent_jack_hmcd_crowbar",
    ["weapon_pistol"] = "ent_jack_hmcd_usp",
    ["weapon_357"] = "ent_jack_hmcd_revolver",
    ["weapon_smg1"] = "ent_jack_hmcd_mp7",
    ["weapon_ar2"] = "ent_jack_hmcd_ar2",
    ["weapon_shotgun"] = "ent_jack_hmcd_spas",
    ["weapon_crossbow"] = "ent_jack_hmcd_crossbow",
    ["weapon_rpg"] = "ent_jack_hmcd_rpg",
    ["weapon_frag"] = "ent_jack_hmcd_grenade",
    ["weapon_annabelle"] = "ent_jack_hmcd_shotgun",
    ["weapon_alyxgun"] = "ent_jack_hmcd_pistol"
}

-- Only replace MAP spawned items (not held by NPCs)
hook.Add("OnEntityCreated", "HMCD_HL2Coop_WeaponReplaceSpawn", function(ent)
    if HMCD_HL2Coop.IsHL2Map() then
        -- Also check for trigger_changelevel creation here to catch it if InitPostEntity misses it
        -- HANDLED BY sv_hmcd_hl2coop_trigger.lua NOW
        
        timer.Simple(0, function()
            if IsValid(ent) and weaponReplacements[ent:GetClass()] then
                -- If it has an owner (NPC/Player), do not replace it immediately
                if IsValid(ent:GetOwner()) or IsValid(ent:GetParent()) then return end
                
                local replacement = weaponReplacements[ent:GetClass()]
                local pos = ent:GetPos()
                local ang = ent:GetAngles()
                ent:Remove()
                
                local newEnt = ents.Create(replacement)
                if IsValid(newEnt) then
                    newEnt:SetPos(pos)
                    newEnt:SetAngles(ang)
                    newEnt:Spawn()
                end
            end
        end)
    end
end)

-- Replace weapon when NPC drops it on death
hook.Add("OnNPCKilled", "HMCD_HL2Coop_NPCDeathWeapon", function(npc, attacker, inflictor)
    if not HMCD_HL2Coop.IsHL2Map() then return end
    
    local wep = npc:GetActiveWeapon()
    if IsValid(wep) and weaponReplacements[wep:GetClass()] then
        local replacement = weaponReplacements[wep:GetClass()]
        
        -- We need to wait for the engine to drop the weapon, or we handle it ourselves
        -- Often, the weapon entity is the same one.
        
        timer.Simple(0, function()
            -- If the weapon is still valid, it might be the dropped one
            if IsValid(wep) then
                local pos = wep:GetPos()
                local ang = wep:GetAngles()
                wep:Remove()
                
                local newEnt = ents.Create(replacement)
                if IsValid(newEnt) then
                    newEnt:SetPos(pos)
                    newEnt:SetAngles(ang)
                    newEnt:Spawn()
                    
                    -- Simulate drop physics
                    local phys = newEnt:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:Wake()
                        phys:SetVelocity(VectorRand() * 50)
                    end
                end
            end
        end)
    end
end)
