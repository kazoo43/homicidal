if SERVER then return end

-- Helper Functions
local function Center(panel)
    panel:Center()
end

-- Ammo Drop Menu
local function OpenAmmoDropMenu()
    local Ply = LocalPlayer()
    local AmmoType = "Pistol"
    local AmmoAmt = 1
    local Ammos = {}

    -- Ensure HMCD_AmmoNames exists (from shared.lua)
    if not HMCD_AmmoNames then return end

    for key, name in pairs(HMCD_AmmoNames) do
        local Amownt = Ply:GetAmmoCount(key)
        if (Amownt > 0) then Ammos[key] = Amownt end
    end
    
    if (table.Count(Ammos) <= 0) then
        Ply:ChatPrint("You have no ammo!")
        return
    end
    
    -- Get first key safely
    for k, v in pairs(Ammos) do
        AmmoType = k
        AmmoAmt = v
        break
    end

    local DermaPanel = vgui.Create("DFrame")
    DermaPanel:SetPos(40, 80)
    DermaPanel:SetSize(300, 300)
    DermaPanel:SetTitle("Drop Ammo")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    Center(DermaPanel)

    local MainPanel = vgui.Create("DPanel", DermaPanel)
    MainPanel:SetPos(5, 25)
    MainPanel:SetSize(290, 270)
    MainPanel.Paint = function()
        surface.SetDrawColor(0, 20, 40, 255)
        surface.DrawRect(0, 0, MainPanel:GetWide(), MainPanel:GetTall() + 3)
    end
    
    local SecondPanel = vgui.Create("DPanel", MainPanel)
    SecondPanel:SetPos(100, 177)
    SecondPanel:SetSize(180, 20)
    SecondPanel.Paint = function()
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawRect(0, 0, SecondPanel:GetWide(), SecondPanel:GetTall() + 3)
    end
    
    local amtselect = vgui.Create("DNumSlider", MainPanel)
    amtselect:SetPos(10, 170)
    amtselect:SetWide(290)
    amtselect:SetText("Amount")
    amtselect:SetMin(1)
    amtselect:SetMax(AmmoAmt)
    amtselect:SetDecimals(0)
    amtselect:SetValue(AmmoAmt)
    amtselect.OnValueChanged = function(panel, val)
        AmmoAmt = math.Round(val)
    end
    
    local AmmoList = vgui.Create("DListView", MainPanel)
    AmmoList:SetMultiSelect(false)
    AmmoList:AddColumn("Type")
    for key, amm in pairs(Ammos) do
        AmmoList:AddLine(HMCD_AmmoNames[key]).Type = key
    end
    AmmoList:SetPos(5, 5)
    AmmoList:SetSize(280, 150)
    AmmoList.OnRowSelected = function(panel, ind, row)
        AmmoType = row.Type
        AmmoAmt = Ammos[AmmoType]
        amtselect:SetMax(AmmoAmt)
        amtselect:SetValue(AmmoAmt)
    end
    AmmoList:SelectFirstItem()
    
    local gobutton = vgui.Create("Button", MainPanel)
    gobutton:SetSize(270, 40)
    gobutton:SetPos(10, 220)
    gobutton:SetText("Drop")
    gobutton:SetVisible(true)
    gobutton.DoClick = function()
        DermaPanel:Close()
        RunConsoleCommand("hmcd_droprequest_ammo", AmmoType, tostring(AmmoAmt))
    end
end

concommand.Add("open_ammo_drop_menu", OpenAmmoDropMenu)

-- Equipment Drop Menu
local function OpenEquipmentDropMenu()
    local ply = LocalPlayer()
    local eqType = ""
    
    -- Sandbox check: ply.Equipment might be nil or empty if not initialized
    if not ply.Equipment or table.Count(ply.Equipment) <= 0 then
        ply:ChatPrint("You have no equipment!")
        return
    end

    local size = math.max(ScrW() * 0.2, 400)
    local DermaPanel = vgui.Create("DFrame")
    DermaPanel:SetSize(size, size)
    DermaPanel:SetTitle("Drop Equipment")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    Center(DermaPanel)

    local MainPanel = vgui.Create("DPanel", DermaPanel)
    MainPanel:SetPos(5, 25)
    MainPanel:SetSize(size * 0.96, size * 0.9)
    MainPanel.Paint = function()
        surface.SetDrawColor(0, 20, 40, 255)
        surface.DrawRect(0, 0, MainPanel:GetWide(), MainPanel:GetTall())
    end

    local EquipmentList = vgui.Create("DListView", MainPanel)
    EquipmentList:SetMultiSelect(false)
    EquipmentList:AddColumn("Type")
    
    if HMCD_EquipmentNames then
        for key, amm in pairs(ply.Equipment) do
            -- HMCD_EquipmentNames is [ID] = Name
            -- ply.Equipment is likely [Name] = true or [ID] = true?
            -- Looking at code: ply.Equipment[HMCD_EquipmentNames[eqType]] = nil
            -- This implies ply.Equipment uses Names as keys.
            -- But EquipmentList:AddLine(key).Type = table.KeyFromValue(HMCD_EquipmentNames, key)
            -- This implies key is the Name.
            EquipmentList:AddLine(key).Type = table.KeyFromValue(HMCD_EquipmentNames, key)
        end
    end
    
    EquipmentList:SetPos(5, 5)
    EquipmentList:SetSize(size * 0.93, size * 0.5)
    EquipmentList.OnRowSelected = function(panel, ind, row)
        eqType = row.Type
    end
    EquipmentList:SelectFirstItem()

    local gobutton = vgui.Create("Button", MainPanel)
    gobutton:SetSize(size * 0.9, size * 0.15)
    gobutton:SetPos(size / 30, size * 0.73)
    gobutton:SetText("Drop")
    gobutton:SetVisible(true)
    gobutton.DoClick = function()
        DermaPanel:Close()
        if ply.Equipment and HMCD_EquipmentNames and eqType then
             ply.Equipment[HMCD_EquipmentNames[eqType]] = nil
             RunConsoleCommand("hmcd_dropequipment", eqType)
        end
    end
end

-- Attachment Menu
local function OpenAttachmentMenu()
    local ply = LocalPlayer()
    local Wep = ply:GetActiveWeapon()
    local attType = 0
    local List = {}
    
    if IsValid(Wep) then
        local atts = {}
        -- Sandbox compatibility: Wep.Attachments might be nil
        if Wep.Attachments and Wep.Attachments["Owner"] then
            for attachment, info in pairs(Wep.Attachments["Owner"]) do
                if info.num then
                    if Wep:GetNWBool(attachment) then
                        table.insert(List, info.num)
                    end
                    table.insert(atts, info.num)
                end
            end
        end
        
        if ply.Equipment and HMCD_EquipmentNames then
            for i, attachment in pairs(atts) do
                if ply.Equipment[HMCD_EquipmentNames[attachment]] then
                    table.insert(List, attachment)
                end
            end
        end
    end

    local size = math.max(ScrW() * 0.2, 400)
    local DermaPanel = vgui.Create("DFrame")
    DermaPanel:SetPos(40, 80)
    DermaPanel:SetSize(size, size)
    DermaPanel:SetTitle("Customize your weapon")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:MakePopup()
    Center(DermaPanel)

    local MainPanel = vgui.Create("DPanel", DermaPanel)
    MainPanel:SetPos(5, 25)
    MainPanel:SetSize(size * 0.96, size * 0.9)
    MainPanel.Paint = function()
        surface.SetDrawColor(0, 20, 40, 255)
        surface.DrawRect(0, 0, MainPanel:GetWide(), MainPanel:GetTall() + 3)
    end

    local AttachmentList = vgui.Create("DListView", MainPanel)
    AttachmentList:SetMultiSelect(false)
    AttachmentList:AddColumn("Type")
    
    if HMCD_EquipmentNames then
        for i, att in pairs(List) do
            AttachmentList:AddLine(HMCD_EquipmentNames[List[i]]).Type = att
        end
    end
    
    AttachmentList:SetPos(5, 5)
    AttachmentList:SetSize(size * 0.93, size * 0.5)
    
    local gobutton = vgui.Create("Button", MainPanel)
    gobutton:SetSize(size * 0.9, size * 0.15)
    gobutton:SetPos(size / 30, size * 0.73)
    gobutton:SetText("Attach")
    gobutton:SetVisible(true)
    gobutton:SetEnabled(false)
    gobutton.DoClick = function()
        DermaPanel:Close()
        RunConsoleCommand("hmcd_attachrequest", attType)
    end
    
    AttachmentList.OnRowSelected = function(panel, ind, row)
        attType = row.Type
        gobutton:SetEnabled(true)
    end
end

concommand.Add("attachmentsmenu", OpenAttachmentMenu)
