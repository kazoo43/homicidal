-- Clean, fresh implementation of trigger replacement
local waitingPlayers = {}

-- Global function to update custom wait zone
function HMCD_WaitZone_Update(pos, mins, maxs)
    local map = game.GetMap()
    local data = {
        pos = pos,
        mins = mins,
        maxs = maxs
    }
    
    -- Save to disk
    if not file.Exists("hmcd_waitzones", "DATA") then
        file.CreateDir("hmcd_waitzones")
    end
    
    file.Write("hmcd_waitzones/" .. map .. ".txt", util.TableToJSON(data))
    
    -- Reload triggers
    SetupHL2MapTriggers()
end

function HMCD_WaitZone_Remove()
    local map = game.GetMap()
    if file.Exists("hmcd_waitzones/" .. map .. ".txt", "DATA") then
        file.Delete("hmcd_waitzones/" .. map .. ".txt")
    end
    
    -- Reload triggers
    SetupHL2MapTriggers()
end

-- Main function to replace triggers
function SetupHL2MapTriggers()
    -- Clear existing replacement triggers first to avoid duplicates
    for _, ent in ipairs(ents.FindByClass("trigger_multiple")) do
        if ent.HMCD_TargetMap then
            ent:Remove()
        end
    end

    -- Check for custom wait zone data
    local map = game.GetMap()
    local customData = nil
    
    if file.Exists("hmcd_waitzones/" .. map .. ".txt", "DATA") then
        local content = file.Read("hmcd_waitzones/" .. map .. ".txt", "DATA")
        if content then
            customData = util.JSONToTable(content)
            print("[HMCD] Loaded custom wait zone data for " .. map)
        end
    end
    
    if customData then
        -- Create custom trigger
        local pos = customData.pos
        local mins = customData.mins or Vector(-100, -100, -50)
        local maxs = customData.maxs or Vector(100, 100, 150)
        
        local nextMap = nil
        if HMCD_HL2_MapList then
            nextMap = HMCD_HL2_MapList[game.GetMap()]
        end
        
        local newTrigger = ents.Create("trigger_multiple")
        if IsValid(newTrigger) then
            newTrigger:SetPos(pos)
            newTrigger:SetSpawnFlags(1) -- Clients Only
            newTrigger:SetSolid(SOLID_BBOX)
            newTrigger:SetCollisionBounds(mins, maxs)
            newTrigger:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
            newTrigger:SetTrigger(true)
            newTrigger:SetNotSolid(false)
            
            newTrigger:Spawn()
            newTrigger:Activate()
            
            -- Store map data
            newTrigger.HMCD_TargetMap = nextMap
            newTrigger.HMCD_TriggerCenter = pos
            -- Update radius to match the max dimension of the box to ensure coverage
            local maxDim = math.max(maxs.x - mins.x, maxs.y - mins.y, maxs.z - mins.z)
            newTrigger.HMCD_TriggerRadiusSqr = (maxDim * 1.5) ^ 2 -- 1.5x max dimension just to be safe
            
            -- Define logic (Shared logic function)
            local function ProcessPlayerSuccess(ply)
                if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
                if waitingPlayers[ply] then return end
                
                waitingPlayers[ply] = true
                ply:StripWeapons()
                ply:Spectate(OBS_MODE_ROAMING)
                ply:SetPos(newTrigger.HMCD_TriggerCenter)
                ply:ChatPrint("Waiting for other players...")
                
                local allReady = true
                local playerCount = 0
                for _, p in ipairs(player.GetAll()) do
                    if p:Alive() then
                        playerCount = playerCount + 1
                        if not waitingPlayers[p] then allReady = false end
                    end
                end
                
                if allReady and playerCount > 0 then
                    local target = newTrigger.HMCD_TargetMap
                    if target then
                        GAMEMODE:EndRound(8, nil)
                        PrintMessage(HUD_PRINTTALK, "Changing level to " .. target .. " in 5 seconds...")
                        timer.Simple(5, function() RunConsoleCommand("changelevel", target) end)
                    else
                        PrintMessage(HUD_PRINTTALK, "Error: No next map defined in HMCD_HL2_MapList")
                    end
                end
            end
            
            newTrigger.StartTouch = function(self, ply) ProcessPlayerSuccess(ply) end
            newTrigger.Touch = function(self, ply) ProcessPlayerSuccess(ply) end
            
            hook.Add("Think", "HMCD_TriggerCheck_" .. newTrigger:EntIndex(), function()
                if not IsValid(newTrigger) then 
                    hook.Remove("Think", "HMCD_TriggerCheck_" .. newTrigger:EntIndex())
                    return 
                end
                
                -- Always visualize custom trigger with Cyan box
                -- We use 1.1 seconds so it stays visible as long as the trigger exists
                if (newTrigger.HMCD_NextDebug or 0) < CurTime() then
                    newTrigger.HMCD_NextDebug = CurTime() + 1
                    debugoverlay.Box(pos, mins, maxs, 1.1, Color(0, 255, 255, 100)) -- Increased alpha for visibility
                    debugoverlay.Text(pos, "CUSTOM WAIT ZONE", 1.1)
                end
                
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply:Alive() and not waitingPlayers[ply] then
                        if ply:GetPos():DistToSqr(pos) < newTrigger.HMCD_TriggerRadiusSqr then
                            if ply:GetPos():WithinAABox(newTrigger:LocalToWorld(mins), newTrigger:LocalToWorld(maxs)) then
                                ProcessPlayerSuccess(ply)
                            end
                        end
                    end
                end
            end)
            
            print("[HMCD] Spawning CUSTOM wait zone trigger at " .. tostring(pos))
        end
        
        -- Also remove default triggers to avoid conflict
        local defaultTriggers = ents.FindByClass("trigger_changelevel")
        for _, ent in ipairs(defaultTriggers) do
            ent:Remove()
        end
        return -- Skip default generation
    end

    -- 1. Find all existing changelevel triggers
    local triggers = ents.FindByClass("trigger_changelevel")
    if #triggers == 0 then return end
    
    print("[HMCD] Found " .. #triggers .. " changelevel triggers. Replacing with custom logic...")
    
    for _, ent in ipairs(triggers) do
        print("[HMCD] Processing trigger_changelevel: " .. tostring(ent) .. " Map: " .. tostring(ent:GetInternalVariable("map")))
        
        -- 2. Extract necessary data
        local targetMap = ent:GetInternalVariable("map")
        local pos = ent:GetPos()
        local model = ent:GetModel()
        local mins = ent:OBBMins()
        local maxs = ent:OBBMaxs()
        local center = ent:LocalToWorld(ent:OBBCenter())
        
        -- Fallback map lookup
        if (not targetMap or targetMap == "") and HMCD_HL2_MapList then
            targetMap = HMCD_HL2_MapList[game.GetMap()]
        end
        
        -- 3. Remove the original entity immediately
        ent:Remove()
        
        -- 4. Create a fresh trigger entity
        local newTrigger = ents.Create("trigger_multiple")
        if IsValid(newTrigger) then
            newTrigger:SetPos(pos)
            newTrigger:SetModel(model)
            newTrigger:SetSpawnFlags(1) -- Clients Only
            
            -- Use SOLID_BBOX and explicit bounds
            newTrigger:SetSolid(SOLID_BBOX)
            newTrigger:SetCollisionBounds(mins, maxs)
            
            -- Set to TRIGGER group
            newTrigger:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
            newTrigger:SetTrigger(true)
            newTrigger:SetNotSolid(false)
            
            newTrigger:Spawn()
            newTrigger:Activate()
            
            -- Store map data on the entity itself
            newTrigger.HMCD_TargetMap = targetMap
            newTrigger.HMCD_TriggerCenter = center
            newTrigger.HMCD_TriggerRadiusSqr = 200 * 200 -- 200 units radius for proximity check
            
            -- Debug
            print("[HMCD] Created replacement trigger for map: " .. tostring(targetMap))
            
            -- Function to process player success
            local function ProcessPlayerSuccess(ply)
                if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
                if waitingPlayers[ply] then return end
                
                print("[HMCD] Player " .. ply:Nick() .. " successfully triggered level change!")
                
                -- Add to waiting list
                waitingPlayers[ply] = true
                
                -- Spectate logic
                ply:StripWeapons()
                ply:Spectate(OBS_MODE_ROAMING)
                ply:SetPos(newTrigger.HMCD_TriggerCenter)
                ply:ChatPrint("Waiting for other players...")
                
                -- Check all players
                local allReady = true
                local playerCount = 0
                
                for _, p in ipairs(player.GetAll()) do
                    if p:Alive() then
                        playerCount = playerCount + 1
                        if not waitingPlayers[p] then
                            allReady = false
                        end
                    end
                end
                
                if allReady and playerCount > 0 then
                    local nextMap = newTrigger.HMCD_TargetMap
                    
                    if (not nextMap or nextMap == "") and HMCD_HL2_MapList then
                        nextMap = HMCD_HL2_MapList[game.GetMap()]
                    end
                    
                    if nextMap then
                        GAMEMODE:EndRound(8, nil) -- Episode Successful
                        PrintMessage(HUD_PRINTTALK, "Changing level to " .. nextMap .. " in 5 seconds...")
                        
                        timer.Simple(5, function()
                            RunConsoleCommand("changelevel", nextMap)
                        end)
                    else
                        PrintMessage(HUD_PRINTTALK, "Error: No next map found!")
                    end
                end
            end
            
            -- 5. Define the touch logic
            newTrigger.StartTouch = function(self, ply)
                ProcessPlayerSuccess(ply)
            end
            
            newTrigger.Touch = function(self, ply)
                ProcessPlayerSuccess(ply)
            end
            
            -- 6. Add a Think hook to check distance as a backup
            hook.Add("Think", "HMCD_TriggerCheck_" .. newTrigger:EntIndex(), function()
                if not IsValid(newTrigger) then 
                    hook.Remove("Think", "HMCD_TriggerCheck_" .. newTrigger:EntIndex())
                    return 
                end
                
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply:Alive() and not waitingPlayers[ply] then
                        local distSqr = ply:GetPos():DistToSqr(newTrigger.HMCD_TriggerCenter)
                        
                        -- Debug print every second if close
                        if distSqr < (500 * 500) and (ply.HMCD_LastTriggerDebug or 0) < CurTime() then
                            ply.HMCD_LastTriggerDebug = CurTime() + 1
                            print("[HMCD] Player " .. ply:Nick() .. " distance to trigger: " .. math.sqrt(distSqr))
                        end
                        
                        if distSqr < newTrigger.HMCD_TriggerRadiusSqr then
                             -- Also check if they are inside the box
                            local inBox = ply:GetPos():WithinAABox(newTrigger:LocalToWorld(mins), newTrigger:LocalToWorld(maxs))
                            
                            if inBox then
                                print("[HMCD] Player " .. ply:Nick() .. " is INSIDE trigger box (AABB check)!")
                                ProcessPlayerSuccess(ply)
                            end
                        end
                    end
                end
            end)
        end
    end
end

-- Hook into map load
hook.Add("InitPostEntity", "HMCD_HL2Coop_SetupTriggers_V2", SetupHL2MapTriggers)

-- Hook into entity creation (for late spawns)
hook.Add("OnEntityCreated", "HMCD_HL2Coop_LateTriggerCatch_V2", function(ent)
    if ent:GetClass() == "trigger_changelevel" then
        -- Delay by one frame to let engine finish initializing it
        timer.Simple(0, function()
            if IsValid(ent) then
                print("[HMCD] Late trigger_changelevel detected. Replacing...")
                
                -- Extract data
                local targetMap = ent:GetInternalVariable("map")
                local pos = ent:GetPos()
                local model = ent:GetModel()
                local mins = ent:OBBMins()
                local maxs = ent:OBBMaxs()
                
                if (not targetMap or targetMap == "") and HMCD_HL2_MapList then
                    targetMap = HMCD_HL2_MapList[game.GetMap()]
                end
                
                -- Remove original
                ent:Remove()
                
                -- Create replacement
                local newTrigger = ents.Create("trigger_multiple")
                if IsValid(newTrigger) then
                    newTrigger:SetPos(pos)
                    newTrigger:SetModel(model)
                    newTrigger:SetSpawnFlags(1)
                    newTrigger:SetSolid(SOLID_BBOX)
                    newTrigger:SetCollisionBounds(mins, maxs)
                    newTrigger:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
                    newTrigger:SetTrigger(true)
                    newTrigger:SetNotSolid(false)
                    
                    newTrigger:Spawn()
                    newTrigger:Activate()
                    
                    newTrigger.HMCD_TargetMap = targetMap
                    
                    -- Same logic as above
                    newTrigger.StartTouch = function(self, ply)
                        if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
                        if waitingPlayers[ply] then return end
                        
                        waitingPlayers[ply] = true
                        ply:StripWeapons()
                        ply:Spectate(OBS_MODE_ROAMING)
                        ply:SetPos(self:LocalToWorld(self:OBBCenter()))
                        ply:ChatPrint("Waiting for other players...")
                        
                        local allReady = true
                        local playerCount = 0
                        for _, p in ipairs(player.GetAll()) do
                            if p:Alive() then
                                playerCount = playerCount + 1
                                if not waitingPlayers[p] then allReady = false end
                            end
                        end
                        
                        if allReady and playerCount > 0 then
                            local nextMap = self.HMCD_TargetMap
                            if (not nextMap or nextMap == "") and HMCD_HL2_MapList then
                                nextMap = HMCD_HL2_MapList[game.GetMap()]
                            end
                            if nextMap then
                                GAMEMODE:EndRound(8, nil)
                                PrintMessage(HUD_PRINTTALK, "Changing level to " .. nextMap .. " in 5 seconds...")
                                timer.Simple(5, function() RunConsoleCommand("changelevel", nextMap) end)
                            end
                        end
                    end
                    newTrigger.Touch = newTrigger.StartTouch
                end
            end
        end)
    end
end)

-- Admin debug commands
hook.Add("PlayerSay", "HMCD_HL2Coop_Commands", function(ply, text)
    if not ply:IsAdmin() then return end
    local cmd = string.lower(text)
    
    if cmd == "!skip" then
        if HMCD_HL2_MapList then
            local nextMap = HMCD_HL2_MapList[game.GetMap()]
            if nextMap then
                GAMEMODE:EndRound(8, nil)
                PrintMessage(HUD_PRINTTALK, "Force skipping level to " .. nextMap .. " in 5 seconds...")
                timer.Simple(5, function() RunConsoleCommand("changelevel", nextMap) end)
                return ""
            end
        end
    elseif cmd == "!trigger" then
        local triggers = ents.FindByClass("trigger_multiple")
        local count = 0
        for _, ent in ipairs(triggers) do
            if ent.HMCD_TargetMap then
                count = count + 1
                debugoverlay.Box(ent:GetPos(), ent:OBBMins(), ent:OBBMaxs(), 30, Color(0, 255, 0, 50))
                debugoverlay.Text(ent:LocalToWorld(ent:OBBCenter()), "MAP: " .. ent.HMCD_TargetMap, 30)
                ply:SetPos(ent:LocalToWorld(ent:OBBCenter()))
                ply:ChatPrint("Teleported to trigger #" .. count .. " for map " .. ent.HMCD_TargetMap)
                break -- Just tp to first one
            end
        end
        if count == 0 then ply:ChatPrint("No replaced triggers found!") end
        return ""
    end
end)

-- Force run on reload
if SERVER then SetupHL2MapTriggers() end
