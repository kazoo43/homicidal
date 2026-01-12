if SERVER then
    util.AddNetworkString("HMCD_HL2Coop_Vitals")

    hook.Add("PlayerThink", "HMCD_HL2Coop_HEVLogic", function(ply)
        if not ply:GetNWBool("HMCD_HEVSuit") then return end
        
        ply.HEVNextThink = ply.HEVNextThink or 0
        if CurTime() < ply.HEVNextThink then return end
        ply.HEVNextThink = CurTime() + 1
        
        -- 1. Heal Health (Critical State)
        if ply:Health() < 50 then
            if ply:Health() < 100 then
                ply:SetHealth(ply:Health() + 1)
                if math.random(1, 15) == 1 then
                    ply:EmitSound("items/medshot4.wav")
                    ply:ChatPrint("Vital signs stabilizing...")
                end
            end
        end
        
        -- 2. Stop Bleeding (Cauterize Wounds)
        local fixedBleeding = false
        if ply.BleedOuts then
            for k, v in pairs(ply.BleedOuts) do
                if v > 0 then
                    ply.BleedOuts[k] = 0
                    fixedBleeding = true
                end
            end
        end
        
        if ply.Hit then
            local arteries = {"rl_artery", "ll_artery", "rh_artery", "lh_artery", "neck_artery"}
            for _, artery in ipairs(arteries) do
                if ply.Hit[artery] then
                    ply.Hit[artery] = false
                    fixedBleeding = true
                end
            end
        end
        
        if fixedBleeding then
            ply:EmitSound("items/medshot4.wav")
            ply:ChatPrint("Hemorrhage detected. Cauterizing wounds...")
        end

        -- 3. Administer Morphine (Pain Management)
        ply.HEV_NextMorphine = ply.HEV_NextMorphine or 0
        ply.HEV_MorphineEnd = ply.HEV_MorphineEnd or 0
        
        -- Active Morphine Effect
        if CurTime() < ply.HEV_MorphineEnd then
            if ply.pain > 0 then
                ply.pain = math.max(0, ply.pain - 10) -- Rapid reduction per tick (1s)
            end
        elseif ply.pain and ply.pain > 50 and CurTime() > ply.HEV_NextMorphine then
            -- Trigger Morphine
            ply.HEV_MorphineEnd = CurTime() + 30
            ply.HEV_NextMorphine = CurTime() + 60
            
            ply:EmitSound("items/medshot4.wav")
            ply:ChatPrint("Severe nociceptive response detected. Administering morphine...")
        end
        
        -- 4. Administer Blood (Plasma)
        ply.HEV_NextBlood = ply.HEV_NextBlood or 0
        
        if ply.Blood and ply.Blood < 4700 and CurTime() > ply.HEV_NextBlood then
             ply.Blood = math.min(5200, ply.Blood + 500)
             ply.HEV_NextBlood = CurTime() + 60
             
             ply:EmitSound("items/medshot4.wav")
             ply:ChatPrint("Blood loss critical. Administering plasma...")
        end

        -- 5. Bone Repair System
        ply.HEV_NextBoneRepair = ply.HEV_NextBoneRepair or 0
        if CurTime() > ply.HEV_NextBoneRepair and ply.Bones then
             local repaired = false
             for bone, health in pairs(ply.Bones) do
                 if health < 1 then
                     ply.Bones[bone] = 1
                     repaired = true
                     
                     -- Reset flags
                     if bone == "LeftArm" then ply.ane_la = nil end
                     if bone == "RightArm" then ply.ane_ra = nil end
                     if bone == "LeftLeg" then ply.ane_ll = nil end
                     if bone == "RightLeg" then ply.ane_rl = nil end
                     break -- Repair one at a time
                 end
             end
             
             if repaired then
                 ply.HEV_NextBoneRepair = CurTime() + 60
                 ply:EmitSound("items/medshot4.wav")
                 ply:ChatPrint("Fracture detected. Medical systems engaged. Bone repaired.")
             end
        end
        
        -- Prevent/Fix Spine
        if ply.Hit['spine'] then
            ply.Hit['spine'] = false
            ply:ChatPrint("Spinal trauma stabilized.")
        end
        
        -- Network Vitals
        net.Start("HMCD_HL2Coop_Vitals")
        net.WriteFloat(ply.Blood or 5200)
        net.WriteFloat(ply.o2 or 1)
        net.Send(ply)
    end)
    
    hook.Add("PlayerCanPickupItem", "HMCD_HL2Coop_Pickup", function(ply, item)
        if not ply:GetNWBool("HMCD_HEVSuit") then return end
        
        local class = item:GetClass()
        if class == "item_healthkit" or class == "item_healthvial" then
            if ply:Health() < 100 then
                ply:SetHealth(math.min(100, ply:Health() + (class == "item_healthkit" and 25 or 10)))
                ply:EmitSound("items/smallmedkit1.wav")
                item:Remove()
                return true
            end
        elseif class == "item_battery" then
             if ply:Armor() < 100 then
                ply:SetArmor(math.min(100, ply:Armor() + 15))
                ply:EmitSound("items/battery_pickup.wav")
                item:Remove()
                return true
             end
        end
    end)

    -- Reset HEV Suit on Death/Spawn
    local function ResetHEV(ply)
        if ply.IsUnfaking then return end -- Don't reset if getting up from ragdoll
        
        ply:SetNWBool("HMCD_HEVSuit", false)
        ply.HEV_NextMorphine = 0
        ply.HEV_MorphineEnd = 0
        ply.HEV_NextBlood = 0
        ply.HEV_NextBoneRepair = 0
    end
    hook.Add("PlayerSpawn", "HMCD_HEV_ResetSpawn", ResetHEV)
    hook.Add("DoPlayerDeath", "HMCD_HEV_ResetDeath", ResetHEV)

    -- Custom Hands for Gordon
    hook.Add("PlayerSetHands", "HMCD_Gordon_Hands", function(ply, ent)
        if ply:GetNWBool("HMCD_HEVSuit") or ply:GetModel() == "models/player/freeman.mdl" then
            local simplemodel = player_manager.TranslateToPlayerModelName(ply:GetModel())
            local info = player_manager.TranslatePlayerHands(simplemodel)
            if info then
                ent:SetModel("models/gfreakman/gordonf_hands.mdl")
                ent:SetSkin(info.skin)
                ent:SetBodyGroups(info.body)
                
                -- Force update again next tick to override other hooks
                timer.Simple(0, function()
                    if IsValid(ent) and IsValid(ply) then
                        ent:SetModel("models/gfreakman/gordonf_hands.mdl")
                    end
                end)
            end
        end
    end)
end

if CLIENT then
    local Blood = 5200
    local Oxygen = 1
    
    net.Receive("HMCD_HL2Coop_Vitals", function()
        Blood = net.ReadFloat()
        Oxygen = net.ReadFloat()
    end)
    
    surface.CreateFont("HMCD_HEV_Large", {
        font = "Trebuchet MS",
        size = 52,
        weight = 900,
        antialias = true,
        additive = false,
    })
    
    surface.CreateFont("HMCD_HEV_Small", {
        font = "Trebuchet MS",
        size = 20,
        weight = 600,
        antialias = true,
        additive = false,
    })

    -- Store displayed values for smooth animation
    local DisplayValues = {
        Health = 100,
        Armor = 0,
        Blood = 100,
        Oxygen = 100
    }

    local function DrawScanlinedText(text, font, x, y, color, alignX, alignY)
        -- Setup Stencils to only draw scanlines ON TOP of the text pixels
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(1)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
        render.SetStencilEnable(true)
        
        -- Draw the text to stencil buffer (and screen)
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
        
        -- Now set stencil to only draw where the text was drawn
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_KEEP)
        
        -- Get size for scanlines coverage
        surface.SetFont(font)
        local w, h = surface.GetTextSize(text)
        
        -- Calculate top-left starting position based on alignment
        local startX = x
        local startY = y
        
        if alignX == TEXT_ALIGN_CENTER then startX = x - w/2
        elseif alignX == TEXT_ALIGN_RIGHT then startX = x - w end
        
        if alignY == TEXT_ALIGN_BOTTOM then startY = y - h
        elseif alignY == TEXT_ALIGN_CENTER then startY = y - h/2 end
        
        -- Draw scanlines (will be masked by text)
        surface.SetDrawColor(0, 0, 0, 150)
        for i = 3, h, 4 do
            surface.DrawLine(startX, startY + i, startX + w, startY + i)
        end
        
        -- Disable stencils
        render.SetStencilEnable(false)
    end

    hook.Add("HUDPaint", "HMCD_HL2Coop_HUD", function()
        local ply = LocalPlayer()
        if not ply:GetNWBool("HMCD_HEVSuit") then return end
        if not ply:Alive() then return end
        
        local w, h = ScrW(), ScrH()
        local Orange = Color(255, 140, 0, 255)
        local BgColor = Color(20, 10, 0, 220)
        local LabelColor = Color(255, 200, 100)
        
        -- Update Animations
        local dt = FrameTime() * 5
        DisplayValues.Health = Lerp(dt, DisplayValues.Health, ply:Health())
        DisplayValues.Armor = Lerp(dt, DisplayValues.Armor, ply:Armor())
        DisplayValues.Blood = Lerp(dt, DisplayValues.Blood, math.Clamp(math.Round((Blood / 5200) * 100), 0, 100))
        DisplayValues.Oxygen = Lerp(dt, DisplayValues.Oxygen, math.Clamp(math.Round(Oxygen * 100), 0, 100))
        
        -- Background Box for Kiosk Look
        local BoxW, BoxH = 360, 120
        local BoxX, BoxY = 40, h - 160
        
        draw.RoundedBox(0, BoxX, BoxY, BoxW, BoxH, BgColor)
        
        -- Orange Border
        surface.SetDrawColor(Orange)
        surface.DrawOutlinedRect(BoxX, BoxY, BoxW, BoxH, 2)
        
        -- Decorative Header Line
        surface.DrawLine(BoxX, BoxY + 30, BoxX + BoxW, BoxY + 30)
        
        -- Header Text
        draw.SimpleText("H.E.V. MK V MONITORING", "HMCD_HEV_Small", BoxX + 10, BoxY + 5, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Layout
        local ContentY = BoxY + 40
        
        -- HEALTH
        draw.SimpleText("HEALTH", "HMCD_HEV_Small", BoxX + 20, ContentY, LabelColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(math.Round(DisplayValues.Health), "HMCD_HEV_Large", BoxX + 20, ContentY + 20, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- ARMOR
        draw.SimpleText("ARMOR", "HMCD_HEV_Small", BoxX + 140, ContentY, LabelColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(math.Round(DisplayValues.Armor), "HMCD_HEV_Large", BoxX + 140, ContentY + 20, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Vertical Separator
        surface.SetDrawColor(Orange)
        surface.DrawLine(BoxX + 240, BoxY + 30, BoxX + 240, BoxY + BoxH)
        
        -- BLOOD & O2 (Smaller section)
        local RightX = BoxX + 250
        
        draw.SimpleText("BLOOD", "HMCD_HEV_Small", RightX, ContentY, LabelColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(math.Round(DisplayValues.Blood) .. "%", "HMCD_HEV_Small", RightX, ContentY + 20, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        draw.SimpleText("OXY", "HMCD_HEV_Small", RightX + 60, ContentY, LabelColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(math.Round(DisplayValues.Oxygen) .. "%", "HMCD_HEV_Small", RightX + 60, ContentY + 20, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end)
end
