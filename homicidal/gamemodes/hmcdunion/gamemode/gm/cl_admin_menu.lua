local function OpenAdminMenu()
    if IsValid(HMCD_AdminFrame) then HMCD_AdminFrame:Remove() end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 400)
    frame:Center()
    frame:SetTitle("Homicidal Admin Menu")
    frame:MakePopup()
    HMCD_AdminFrame = frame
    
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    
    -- Gamemode Tab
    local pnlGM = vgui.Create("DPanel", sheet)
    pnlGM.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50)) end
    sheet:AddSheet("Gamemode", pnlGM, "icon16/controller.png")
    
    local lblGM = vgui.Create("DLabel", pnlGM)
    lblGM:SetText("Select Gamemode:")
    lblGM:SetPos(10, 10)
    lblGM:SizeToContents()
    
    local comboGM = vgui.Create("DComboBox", pnlGM)
    comboGM:SetPos(10, 30)
    comboGM:SetSize(200, 25)
    comboGM:AddChoice("Homicide", "homicide")
    comboGM:AddChoice("Deathmatch", "dm")
    comboGM:AddChoice("Half-Life 2", "hl2")
    comboGM:AddChoice("HL2 Coop", "hl2coop")
    comboGM:AddChoice("Sandbox", "sandbox")
    comboGM:ChooseOptionID(1)
    
    local lblSub = vgui.Create("DLabel", pnlGM)
    lblSub:SetText("Homicide Submode (if Homicide):")
    lblSub:SetPos(10, 70)
    lblSub:SizeToContents()
    
    local comboSub = vgui.Create("DComboBox", pnlGM)
    comboSub:SetPos(10, 90)
    comboSub:SetSize(200, 25)
    comboSub:AddChoice("Standard", 1)
    comboSub:AddChoice("State of Emergency", 2)
    comboSub:AddChoice("Jihad", 3)
    comboSub:AddChoice("Wild West", 4)
    comboSub:AddChoice("Gun Free Zone", 5)
    comboSub:ChooseOptionID(1)
    
    local btnSetGM = vgui.Create("DButton", pnlGM)
    btnSetGM:SetText("Set Next Gamemode")
    btnSetGM:SetPos(10, 130)
    btnSetGM:SetSize(200, 30)
    btnSetGM.DoClick = function()
        local _, gm = comboGM:GetSelected()
        local _, sub = comboSub:GetSelected()
        if not gm then gm = "homicide" end
        if not sub then sub = 1 end
        
        net.Start("HMCD_AdminMenu_Action")
        net.WriteString("set_gamemode")
        net.WriteString(gm)
        net.WriteInt(sub, 8)
        net.SendToServer()
        
        chat.AddText(Color(0, 255, 0), "[Admin] Request sent.")
    end
    
    -- Players Tab
    local pnlPly = vgui.Create("DPanel", sheet)
    pnlPly.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50)) end
    sheet:AddSheet("Players", pnlPly, "icon16/user.png")
    
    local listPly = vgui.Create("DListView", pnlPly)
    listPly:SetPos(10, 10)
    listPly:SetSize(300, 300)
    listPly:AddColumn("Name")
    listPly:AddColumn("Role")
    listPly:SetMultiSelect(false)
    
    local function RefreshPlayers()
        listPly:Clear()
        for _, ply in ipairs(player.GetAll()) do
            local role = ply:GetNWString("RoleShow", "Unknown")
            listPly:AddLine(ply:Nick(), role).ply = ply
        end
    end
    RefreshPlayers()
    
    local lblRole = vgui.Create("DLabel", pnlPly)
    lblRole:SetText("Assign Role:")
    lblRole:SetPos(320, 10)
    lblRole:SizeToContents()
    
    local comboRole = vgui.Create("DComboBox", pnlPly)
    comboRole:SetPos(320, 30)
    comboRole:SetSize(150, 25)
    local roles = {"Traitor", "Gunman", "Bystander", "Rebel", "Combine", "Fighter", "Sandboxer"}
    for _, r in ipairs(roles) do comboRole:AddChoice(r) end
    comboRole:ChooseOptionID(1)
    
    local btnSetRole = vgui.Create("DButton", pnlPly)
    btnSetRole:SetText("Set Role")
    btnSetRole:SetPos(320, 60)
    btnSetRole:SetSize(150, 30)
    btnSetRole.DoClick = function()
        local line = listPly:GetSelectedLine()
        if not line then return end
        local ply = listPly:GetLine(line).ply
        local _, role = comboRole:GetSelected()
        
        if IsValid(ply) and role then
            net.Start("HMCD_AdminMenu_Action")
            net.WriteString("set_role")
            net.WriteEntity(ply)
            net.WriteString(role)
            net.SendToServer()
            chat.AddText(Color(0, 255, 0), "[Admin] Role change requested.")
            
            timer.Simple(0.5, RefreshPlayers)
        end
    end
    
    local btnRefresh = vgui.Create("DButton", pnlPly)
    btnRefresh:SetText("Refresh List")
    btnRefresh:SetPos(320, 100)
    btnRefresh:SetSize(150, 30)
    btnRefresh.DoClick = RefreshPlayers
    
    -- Management Tab
    local pnlMan = vgui.Create("DPanel", sheet)
    pnlMan.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50)) end
    sheet:AddSheet("Management", pnlMan, "icon16/wrench.png")
    
    local btnEnd = vgui.Create("DButton", pnlMan)
    btnEnd:SetText("End Current Round")
    btnEnd:SetPos(10, 10)
    btnEnd:SetSize(200, 40)
    btnEnd.DoClick = function()
        net.Start("HMCD_AdminMenu_Action")
        net.WriteString("end_round")
        net.SendToServer()
    end
end

hook.Add("PlayerButtonDown", "HMCD_AdminMenu_Open", function(ply, button)
    if button == KEY_F6 and IsFirstTimePredicted() then
        if ply:IsAdmin() then
            OpenAdminMenu()
        else
            -- Optional: chat.AddText(Color(255, 0, 0), "You must be an admin to open this menu.")
        end
    end
end)
