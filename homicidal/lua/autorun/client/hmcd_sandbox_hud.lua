
if SERVER then return end

-- Create Fonts
surface.CreateFont("DefaultFont",{
    font = "Coolvetica",
    size = math.ceil(ScrW() / 38),
    weight = 500,
    antialias = true,
    italic = false
})

surface.CreateFont("FontTargetP",{
    font = "Coolvetica",
    size = 48,
    weight = 1100,
    antialias = true,
    italic = false
})

surface.CreateFont("FontSmall",{
    font = "Coolvetica",
    size = ScreenScale(10),
    weight = 1100,
    antialias = true,
    italic = false
})

-- Helpers
local function drawTextShadow(t,f,x,y,c,px,py)
    draw.SimpleText(t,f,x + 1,y + 1,Color(0,0,0,c.a),px,py)
    draw.SimpleText(t,f,x - 1,y - 1,Color(255,255,255,math.Clamp(c.a*.25,0,255)),px,py)
    draw.SimpleText(t,f,x,y,c,px,py)
end

local function RagdollOwner(rag)
    if not IsValid(rag) then return end
    local ent = rag:GetNWEntity("RagdollController")
    return IsValid(ent) and ent
end

local HMCD_LastLooked = nil
local HMCD_LastLookedType = "Other"
local HMCD_LookedFade = 0

-- Main HUD Function
local function HMCD_DrawGameHUD()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    
    -- Nametags and Interaction Prompts
    local tr = ply:GetEyeTraceNoCursor()
    if IsValid(tr.Entity) and tr.HitPos:Distance(tr.StartPos) < 60 then
        if tr.Entity:IsPlayer() then
            HMCD_LastLooked = tr.Entity
            HMCD_LastLookedType = "Other"
            HMCD_LookedFade = CurTime()
        elseif tr.Entity:IsRagdoll() then
             -- Use RagdollOwner if available, otherwise fallback to the ragdoll itself
            local owner = RagdollOwner(tr.Entity)
            if IsValid(owner) then
                HMCD_LastLooked = owner
            else
                HMCD_LastLooked = tr.Entity
            end
            HMCD_LastLookedType = "Ragdoll"
            HMCD_LookedFade = CurTime()
        end
    end

    if IsValid(HMCD_LastLooked) and HMCD_LookedFade + 1 > CurTime() and HMCD_LastLooked ~= LocalPlayer() and LocalPlayer():Alive() then
        local type_look = HMCD_LastLookedType
        -- Safe name retrieval
        local name = HMCD_LastLooked:GetNWString("Character_Name")
        
        -- Fallback if no character name
        if name == "" or name == nil then
            if HMCD_LastLooked:IsPlayer() then
                name = HMCD_LastLooked:Nick()
            else
                name = "Unknown"
            end
        end

        local col = Vector(1,1,1)
        if HMCD_LastLooked:IsPlayer() then
             -- Safe retrieval of player color
             if HMCD_LastLooked.GetPlayerColor then
                col = HMCD_LastLooked:GetPlayerColor() or Vector(1,1,1)
             end
        elseif type_look == "Ragdoll" then
            -- If looking at a ragdoll entity directly (no owner), try getting color from it
             col = HMCD_LastLooked:GetNWVector("plycolor", Vector(1,1,1))
        end

        col = Color(col.x * 255, col.y * 255, col.z * 255)
        col.a = (1 - (CurTime() - HMCD_LookedFade) / 1) * 255
        
        drawTextShadow(name, "FontTargetP", ScrW() / 2, ScrH() / 2 + 80, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if type_look == "Ragdoll" then
            drawTextShadow("[RMB]+[E] Loot", "FontSmall", ScrW() / 2, ScrH() / 2 + 110, Color(255,255,255,col.a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Ammo Display
    local RoundTextures={
        ["Pistol"]=surface.GetTextureID("vgui/hud/hmcd_round_9"),
        ["357"]=surface.GetTextureID("vgui/hud/hmcd_round_38"),
        ["AlyxGun"]=surface.GetTextureID("vgui/hud/hmcd_round_22"),
        ["Buckshot"]=surface.GetTextureID("vgui/hud/hmcd_round_12"),
        ["AR2"]=surface.GetTextureID("vgui/hud/hmcd_round_76239"),
        ["SMG1"]=surface.GetTextureID("vgui/hud/hmcd_round_4630"),
        ["XBowBolt"]=surface.GetTextureID("vgui/hud/hmcd_round_arrow"),
        ["AirboatGun"]=surface.GetTextureID("vgui/hud/hmcd_nail"),
        ["RPG_Round"]=surface.GetTextureID("vgui/hud/rpg_round")
    }

    if ply.AmmoShow and (ply.AmmoShow > CurTime()) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().AmmoType != nil then
        local Wep, TimeLeft, Opacity = ply:GetActiveWeapon(), ply.AmmoShow - CurTime(), 255
        if Opacity <= 0 then return end
        Opacity = TimeLeft * 255
        
        -- Check if weapon has CanAmmoShow or just show for all in sandbox
        if Wep.CanAmmoShow or true then -- Forced true for sandbox compatibility
            local tex = RoundTextures[Wep.AmmoType]
            if tex then
                surface.SetTexture(tex)
                surface.SetDrawColor(Color(255, 255, 255, Opacity))
                surface.DrawTexturedRect(ScrW() * .7 + 20, ScrH() * .830, (Wep.AmmoType == "RPG_Round" and 175) or 128, 100)
            end
            
            local Mag, Message, Cnt = Wep:Clip1(), "", ply:GetAmmoCount(Wep.AmmoType)
            if Mag >= 0 then
                Message = tostring(Mag)
                if Cnt > 0 then Message = Message .. " + " .. tostring(Cnt) end
            else
                Message = tostring(Cnt)
            end

            drawTextShadow(Message, "FontSmall", ScrW() * .7 + 30, ScrH() * .8 + 45, Color(255, 255, 255, Opacity), 0, TEXT_ALIGN_TOP)
        end
    end
end

-- Ledge Detection for HUD
local HMCD_ClimbHoldStart = 0
local HMCD_ClimbSent = false

local function HMCD_CheckLedge()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Only check if we are ragdolled/fake
    local rag = ply:GetNWEntity("Ragdoll")
    if not IsValid(rag) or not ply:GetNWBool("fake") then 
        HMCD_ClimbHoldStart = 0
        HMCD_ClimbSent = false
        return 
    end

    -- Replicate GetLedgePos logic (simplified for client visualization)
    local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
    local headPos = (bone and rag:GetBonePosition(bone)) or rag:GetPos() + Vector(0,0,60)
    
    local aimVec = ply:GetAimVector()
    aimVec.z = 0
    aimVec:Normalize()
    
    local trForward = util.TraceHull({
        start = headPos,
        endpos = headPos + aimVec * 8, -- Distance 8
        mins = Vector(-5, -5, -5),
        maxs = Vector(5, 5, 5),
        filter = {ply, rag},
        mask = MASK_PLAYERSOLID
    })
    
    if trForward.Hit and math.abs(trForward.HitNormal.z) < 0.5 then
        local scanStart = trForward.HitPos + (aimVec * 8) + Vector(0,0,110)
        local scanEnd = trForward.HitPos + (aimVec * 8) - Vector(0,0,20)
        
        local trDown = util.TraceHull({
            start = scanStart,
            endpos = scanEnd,
            mins = Vector(-8,-8,0),
            maxs = Vector(8,8,1),
            filter = {ply, rag},
            mask = MASK_PLAYERSOLID
        })
        
        if trDown.Hit and not trDown.StartSolid then
            local heightDiff = trDown.HitPos.z - headPos.z
            if heightDiff > -30 and heightDiff < 110 then
                 -- Final validation
                local destPos = trDown.HitPos + Vector(0,0,2)
                local trHull = util.TraceHull({
                    start = destPos,
                    endpos = destPos,
                    mins = Vector(-16,-16,0),
                    maxs = Vector(16,16,72),
                    filter = {ply, rag},
                    mask = MASK_PLAYERSOLID
                })
                
                if not trHull.Hit then
                    -- Ledge is valid. Check inputs.
                    local fakeKey = input.LookupBinding("fake")
                    local isFakeKeyDown = false
                    if fakeKey then
                        local key = input.GetKeyCode(fakeKey)
                        if key and key > 0 then
                            isFakeKeyDown = input.IsButtonDown(key)
                        end
                    end
                    
                    local isGrabDown = ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED)
                    
                    if not isGrabDown then
                        HMCD_ClimbHoldStart = 0
                        HMCD_ClimbSent = false
                    else
                         if isFakeKeyDown then
                            if HMCD_ClimbHoldStart == 0 then
                                HMCD_ClimbHoldStart = CurTime()
                            end
                            
                            local progress = math.Clamp((CurTime() - HMCD_ClimbHoldStart) / 2, 0, 1)
                            
                            drawTextShadow("Climb Over", "FontTargetP", ScrW() / 2, ScrH() - 150, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            
                            -- Progress Bar
                            local barW, barH = 200, 10
                            local barX, barY = ScrW() / 2 - barW / 2, ScrH() - 120
                            
                            surface.SetDrawColor(0, 0, 0, 150)
                            surface.DrawRect(barX, barY, barW, barH)
                            
                            surface.SetDrawColor(255, 255, 255, 200)
                            surface.DrawRect(barX, barY, barW * progress, barH)
                            
                            if progress >= 1 and not HMCD_ClimbSent then
                                net.Start("HMCD_LedgeClimb")
                                net.SendToServer()
                                HMCD_ClimbSent = true
                            end
                        else
                            drawTextShadow("Hold ["..(string.upper(fakeKey or "UNBOUND")).."] to Climb", "FontTargetP", ScrW() / 2, ScrH() - 150, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            HMCD_ClimbHoldStart = 0
                            HMCD_ClimbSent = false
                        end
                    end
                end
            end
        end
    else
        HMCD_ClimbHoldStart = 0
        HMCD_ClimbSent = false
    end
end

hook.Add("HUDPaint", "HMCD_DrawGameHUD", function()
    HMCD_DrawGameHUD()
    HMCD_CheckLedge()
end)

-- Ammo Show Message
net.Receive("HMCD_AmmoShow", function()
    LocalPlayer().AmmoShow = CurTime() + 2
end)

-- Menus

function HMCD_OpenAmmoDropMenu()
    local Ply,AmmoType,AmmoAmt,Ammos=LocalPlayer(),"Pistol",1,{}
    for key,name in pairs(HMCD_AmmoNames or {})do
        local Amownt=Ply:GetAmmoCount(key)
        if(Amownt>0)then Ammos[key]=Amownt end
    end
    
    if(#table.GetKeys(Ammos)<=0)then
        Ply:ChatPrint("You have no ammo!")
        return
    end
    
    AmmoType=table.GetKeys(Ammos)[1]
    AmmoAmt=Ammos[AmmoType]

    local DermaPanel=vgui.Create("DFrame")
    DermaPanel:SetPos(40,80)
    DermaPanel:SetSize(300,300)
    DermaPanel:SetTitle("Drop Ammo")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    DermaPanel:Center()

    local MainPanel=vgui.Create("DPanel",DermaPanel)
    MainPanel:SetPos(5,25)
    MainPanel:SetSize(290,270)
    MainPanel.Paint=function()
        surface.SetDrawColor(0,20,40,255)
        surface.DrawRect(0,0,MainPanel:GetWide(),MainPanel:GetTall()+3)
    end
    
    local SecondPanel=vgui.Create("DPanel",MainPanel)
    SecondPanel:SetPos(100,177)
    SecondPanel:SetSize(180,20)
    SecondPanel.Paint=function()
        surface.SetDrawColor(100,100,100,255)
        surface.DrawRect(0,0,SecondPanel:GetWide(),SecondPanel:GetTall()+3)
    end
    
    local amtselect=vgui.Create("DNumSlider",MainPanel)
    amtselect:SetPos(10,170)
    amtselect:SetWide(290)
    amtselect:SetText("Amount")
    amtselect:SetMin(1)
    amtselect:SetMax(AmmoAmt)
    amtselect:SetDecimals(0)
    amtselect:SetValue(AmmoAmt)
    amtselect.OnValueChanged=function(panel,val)
        AmmoAmt=math.Round(val)
    end
    
    local AmmoList=vgui.Create("DListView",MainPanel)
    AmmoList:SetMultiSelect(false)
    AmmoList:AddColumn("Type")
    for key,amm in pairs(Ammos)do
        AmmoList:AddLine(HMCD_AmmoNames[key]).Type=key
    end
    AmmoList:SetPos(5,5)
    AmmoList:SetSize(280,150)
    AmmoList.OnRowSelected=function(panel,ind,row)
        AmmoType=row.Type
        AmmoAmt=Ammos[AmmoType]
        amtselect:SetMax(AmmoAmt)
        amtselect:SetValue(AmmoAmt)
    end
    AmmoList:SelectFirstItem()
    
    local gobutton=vgui.Create("Button",MainPanel)
    gobutton:SetSize(270,40)
    gobutton:SetPos(10,220)
    gobutton:SetText("Drop")
    gobutton:SetVisible(true)
    gobutton.DoClick=function()
        DermaPanel:Close()
        RunConsoleCommand("hmcd_droprequest_ammo",AmmoType,tostring(AmmoAmt))
    end
end

concommand.Add("open_ammo_drop_menu", HMCD_OpenAmmoDropMenu)

function HMCD_OpenEquipmentDropMenu()
    local ply,eqType=LocalPlayer(),""
    if(table.Count(ply.Equipment or {})<=0)then
        ply:ChatPrint("You have no equipment!")
        return
    end
    local size=ScrW()/8.5
    local DermaPanel=vgui.Create("DFrame")
    DermaPanel:SetSize(size,size)
    DermaPanel:SetTitle("Drop Equipment")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    DermaPanel:Center()

    local MainPanel=vgui.Create("DPanel",DermaPanel)
    MainPanel:SetPos(5,25)
    MainPanel:SetSize(size*0.96,size*0.9)
    MainPanel.Paint=function()
        surface.SetDrawColor(0,20,40,255)
        surface.DrawRect(0,0,MainPanel:GetWide(),MainPanel:GetTall())
    end

    local EquipmentList=vgui.Create("DListView",MainPanel)
    EquipmentList:SetMultiSelect(false)
    EquipmentList:AddColumn("Type")
    for key,amm in pairs(ply.Equipment)do
        EquipmentList:AddLine(key).Type=table.KeyFromValue(HMCD_EquipmentNames,key)
    end
    EquipmentList:SetPos(5,5)
    EquipmentList:SetSize(size*0.93,size*0.5)
    EquipmentList.OnRowSelected=function(panel,ind,row)
        eqType=row.Type
    end
    EquipmentList:SelectFirstItem()

    local gobutton=vgui.Create("Button",MainPanel)
    gobutton:SetSize(size*0.9,size*0.15)
    gobutton:SetPos(size/30,size*0.73)
    gobutton:SetText("Drop")
    gobutton:SetVisible(true)
    gobutton.DoClick=function()
        DermaPanel:Close()
        ply.Equipment[HMCD_EquipmentNames[eqType]]=nil
		RunConsoleCommand("hmcd_droprequest",eqType)
	end
end
concommand.Add("open_equipment_drop_menu", HMCD_OpenEquipmentDropMenu)

function HMCD_OpenAttachmentMenu()
    local ply,Wep,attType=LocalPlayer(),LocalPlayer():GetActiveWeapon(),0
    local List={}
    if IsValid(Wep) then
        local atts={}
        if Wep.Attachments and Wep.Attachments["Owner"] then
            for attachment,info in pairs(Wep.Attachments["Owner"]) do
                if info.num then
                    if Wep:GetNWBool(attachment) then
                        table.insert(List,info.num)
                    end
                    table.insert(atts,info.num)
                end
            end
        end
        if ply.Equipment then
            for i,attachment in pairs(atts) do
                if ply.Equipment[HMCD_EquipmentNames[attachment]] then
                    table.insert(List,attachment)
                end
            end
        end
    end

    local size=ScrW()/8.5

    local DermaPanel=vgui.Create("DFrame")
    DermaPanel:SetPos(40,80)
    DermaPanel:SetSize(size,size)
    DermaPanel:SetTitle("Customize your weapon")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    DermaPanel:Center()

    local MainPanel=vgui.Create("DPanel",DermaPanel)
    MainPanel:SetPos(5,25)
    MainPanel:SetSize(size*0.96,size*0.9)
    MainPanel.Paint=function()
        surface.SetDrawColor(0,20,40,255)
        surface.DrawRect(0,0,MainPanel:GetWide(),MainPanel:GetTall()+3)
    end

    local AttachmentList=vgui.Create("DListView",MainPanel)
    AttachmentList:SetMultiSelect(false)
    AttachmentList:AddColumn("Type")
    for i,att in pairs(List)do
        AttachmentList:AddLine(HMCD_EquipmentNames[List[i]]).Type=att
    end
    AttachmentList:SetPos(5,5)
    AttachmentList:SetSize(size*0.93,size*0.5)
    local gobutton=vgui.Create("Button",MainPanel)
    gobutton:SetSize(size*0.9,size*0.15)
    gobutton:SetPos(size/30,size*0.73)
    gobutton:SetText("Attach")
    gobutton:SetVisible(true)
    gobutton:SetEnabled(false)
    gobutton.DoClick=function()
        DermaPanel:Close()
        RunConsoleCommand("hmcd_attachrequest",attType)
    end
    AttachmentList.OnRowSelected=function(panel,ind,row)
        attType=row.Type
        gobutton:SetEnabled(true)
    end
end

concommand.Add("attachmentsmenu", HMCD_OpenAttachmentMenu)
