if SERVER then return end

-- Create Fonts
surface.CreateFont("Radial_QM", {
    font = "coolvetica",
    size = math.ceil(ScrW() / 38),
    weight = 500,
    antialias = true,
    italic = false
})

surface.CreateFont("RadialSmall_QM", {
    font = "coolvetica",
    size = math.ceil(ScrW() / 80),
    weight = 100,
    antialias = true,
    italic = false
})

-- Globals/Locals
local UseMents
local RadialMents
local Menuuse = false
local RadialOpen = false
local UsePrevSelected, UsePrevSelectedVertex
local RadialPrevSelected, RadialPrevSelectedVertex

-- Define HMCD_IsDoor locally if not available (it's in hmcd_weps.lua but good to be safe)
local function HMCD_IsDoor(ent)
    if not IsValid(ent) then return false end
    local Class = ent:GetClass()
    return (Class == "prop_door") or (Class == "prop_door_rotating") or (Class == "func_door") or (Class == "func_door_rotating") or (Class == "func_breakable")
end

-- --- USE MENU FUNCTIONS ---
local function Openmenu_useMenu(elements)
    if not LocalPlayer():Alive() then return end
    Menuuse = true
    LocalPlayer():SetNWBool("Menuuse", true)
    gui.EnableScreenClicker(true)
    UseMents = elements or {}
    UsePrevSelected = nil
end

local function Closemenu_useMenu()
    Menuuse = false
    LocalPlayer():SetNWBool("Menuuse", false)
    if not RadialOpen and not LocalPlayer():GetNWBool("Phraseopen") then gui.EnableScreenClicker(false) end
end

local function getUseSelected()
    local mx, my = gui.MousePos()
    local sw, sh = ScrW(), ScrH()
    local total = #UseMents
    if total == 0 then return 0 end
    
    local w = math.min(sw * 0.45, sh * 0.45)
    local h = w
    local sx, sy = sw / 2, sh / 2
    local x2, y2 = mx - sx, my - sy
    local ang = 0
    local dis = math.sqrt(x2 ^ 2 + y2 ^ 2)
    if dis / w <= 1 then
        if y2 <= 0 and x2 <= 0 then
            ang = math.acos(x2 / dis)
        elseif x2 > 0 and y2 <= 0 then
            ang = -math.asin(y2 / dis)
        elseif x2 <= 0 and y2 > 0 then
            ang = math.asin(y2 / dis) + math.pi
        else
            ang = math.pi * 2 - math.acos(x2 / dis)
        end
        return math.floor((1 - (ang - math.pi / 2 - math.pi / total) / (math.pi * 2) % 1) * total) + 1
    end
end

local function menu_useMousePressed(code)
    local lply = LocalPlayer()
    local eyetrace = lply:GetEyeTrace()
    if Menuuse then
        local selected = getUseSelected()
        if selected and selected > 0 and code == MOUSE_LEFT then
            if selected and UseMents[selected] then
                if UseMents[selected].Code == "door_stuck" then
                    net.Start("Use_DoorStuck")
                    net.WriteEntity(eyetrace.Entity)
                    net.SendToServer()
                elseif UseMents[selected].Code == "door_unstuck" then
                    net.Start("Use_DoorUnStuck")
                    net.WriteEntity(eyetrace.Entity)
                    net.SendToServer()
                elseif UseMents[selected].Code == "ply_push" then
                    net.Start("Player_Push")
                    net.WriteEntity(eyetrace.Entity)
                    net.SendToServer()              
                end
            end
        end

        Closemenu_useMenu()
    end
end

-- --- MAIN RADIAL MENU FUNCTIONS ---
local function OpenRadialMenu(elements)
    if not LocalPlayer():Alive() then return end
    -- if PhraseOpen then return end -- PhraseOpen logic not fully ported, skipping check
    RadialOpen = true
    LocalPlayer():SetNWBool("radialopen", true)
    gui.EnableScreenClicker(true)
    RadialMents = elements or {}
    RadialPrevSelected = nil
end

local function CloseRadialMenu(keepClicker)
    RadialOpen = false
    LocalPlayer():SetNWBool("radialopen", false)
    if not keepClicker and not Menuuse and not LocalPlayer():GetNWBool("Phraseopen") then gui.EnableScreenClicker(false) end
end

local function getRadialSelected()
    local mx, my = gui.MousePos()
    local sw, sh = ScrW(), ScrH()
    local total = #RadialMents
    if total == 0 then return 0 end
    local w = math.min(sw * 0.45, sh * 0.45)
    local h = w
    local sx, sy = sw / 2, sh / 2
    local x2, y2 = mx - sx, my - sy
    local ang = 0
    local dis = math.sqrt(x2 ^ 2 + y2 ^ 2)
    if dis / w <= 1 then
        if y2 <= 0 and x2 <= 0 then
            ang = math.acos(x2 / dis)
        elseif x2 > 0 and y2 <= 0 then
            ang = -math.asin(y2 / dis)
        elseif x2 <= 0 and y2 > 0 then
            ang = math.asin(y2 / dis) + math.pi
        else
            ang = math.pi * 2 - math.acos(x2 / dis)
        end
        return math.floor((1 - (ang - math.pi / 2 - math.pi / total) / (math.pi * 2) % 1) * total) + 1
    end
end

local function RadialMousePressed(code)
    if RadialOpen then
        local selected = getRadialSelected()
        if selected and selected > 0 and code == MOUSE_LEFT then
            if selected and RadialMents[selected] then
                local code = RadialMents[selected].Code
                if code == "hmcd_ammo" then
                    RunConsoleCommand("open_ammo_drop_menu")
                elseif code == "unloadwep" then
                    local lply = LocalPlayer()
                    local wep = lply:GetActiveWeapon()
                    net.Start("Unload")
                    net.WriteEntity(wep)
                    net.SendToServer()
                elseif code == "drop" then
                    local lply = LocalPlayer()
                    lply:ConCommand("say *drop")
                elseif code == "phrase" then
                    local lply = LocalPlayer()
                    lply:ConCommand("+phrase")
                    CloseRadialMenu(true)
                    return
                elseif code == "laser" then
                    local lply = LocalPlayer()
                    if not lply:GetActiveWeapon():GetNWBool("LaserStatus", false) then
                        lply:GetActiveWeapon():SetNWBool("LaserStatus", true)
                        lply:EmitSound("att/laser_on.ogg", 75,100,1,CHAN_AUTO)
                    else
                        lply:GetActiveWeapon():SetNWBool("LaserStatus", false)
                        lply:EmitSound("att/laser_off.ogg", 75,100,1,CHAN_AUTO)
                    end
                elseif code == "usemenu" then
                    local lply = LocalPlayer()
                    lply:ConCommand("+menu_use")
                elseif code == "attach" then
                    local lply = LocalPlayer()
                    lply:ConCommand("attachmentsmenu")
                elseif code == "nvg" then
                    local lply = LocalPlayer()
                    local nvgstat = lply:GetNWBool("NVG_Up", false)
                    if nvgstat then
                        lply:SetNWBool("NVG_Up", false)
                        lply:SetNWBool("NVG_WereOn", false)
                    else
                        lply:SetNWBool("NVG_Up", true)
                        lply:SetNWBool("NVG_WereOn", true)
                    end
                end
            end
        end

        CloseRadialMenu()
    end
end

-- Helper functions for drawing
local tex = surface.GetTextureID("VGUI/white.vmt")
local fontHeight = draw.GetFontHeight("Radial_QM")

local function drawShadow(n, f, x, y, color, pos)
    draw.DrawText(n, f, x + 1, y + 1, color_black, pos)
    draw.DrawText(n, f, x, y, color, pos)
end

local circleVertex
local function Drawmenu_useMenu()
    if Menuuse then
        local sw, sh = ScrW(), ScrH()
        local total = #UseMents
        local w = math.min(sw * 0.45, sh * 0.45)
        local h = w
        local sx, sy = sw / 2, sh / 2

        local selected = getUseSelected() or -1
        
        if not circleVertex then
            circleVertex = {}
            local max = 50
            for i = 0, max do
                local vx, vy = math.cos((math.pi * 2) * i / max), math.sin((math.pi * 2) * i / max)
                table.insert(circleVertex, {x = sx + w * 1 * vx, y = sy + h * 1 * vy})
            end
        end

        surface.SetTexture(tex)
        local defaultTextCol = color_white
        if selected <= 0 or selected ~= selected then
            surface.SetDrawColor(20, 20, 20, 180)
        else
            surface.SetDrawColor(20, 20, 20, 120)
            defaultTextCol = Color(150, 150, 150)
        end
        surface.DrawPoly(circleVertex)

        if total > 0 then
            local add = math.pi * 1.5 + math.pi / total
            local add2 = math.pi * 1.5 - math.pi / total

            for k, ment in pairs(UseMents) do
                local x, y = math.cos((k - 1) / total * math.pi * 2 + math.pi * 1.5), math.sin((k - 1) / total * math.pi * 2 + math.pi * 1.5)
                local lx, ly = math.cos((k - 1) / total * math.pi * 2 + add), math.sin((k - 1) / total * math.pi * 2 + add)

                local textCol = defaultTextCol
                
                if selected == k then
                    local vertexes = {} -- New vertex list for selection
                    
                    local lx2, ly2 = math.cos((k - 1) / total * math.pi * 2 + add2), math.sin((k - 1) / total * math.pi * 2 + add2)

                    table.insert(vertexes, {x = sx, y = sy})
                    table.insert(vertexes, {x = sx + w * 1 * lx2, y = sy + h * 1 * ly2})

                    local max = math.floor(50 / total)
                    for i = 0, max do
                        local addv = (add - add2) * i / max + add2
                        local vx, vy = math.cos((k - 1) / total * math.pi * 2 + addv), math.sin((k - 1) / total * math.pi * 2 + addv)
                        table.insert(vertexes, {x = sx + w * 1 * vx, y = sy + h * 1 * vy})
                    end

                    table.insert(vertexes, {x = sx + w * 1 * lx, y = sy + h * 1 * ly})

                    surface.SetTexture(tex)
                    surface.SetDrawColor(20, 120, 255, 120)
                    surface.DrawPoly(vertexes)
                    textCol = color_white
                end
                
                local Main, Sub
                if ment.TransCode == "Door_Stuck" then
                    Main = "Stuck Door"
                    Sub = "try to stuck this door"
                elseif ment.TransCode == "Door_UnStuck" then
                    Main = "Unstuck Door"
                    Sub = "try to unstuck this door"
                elseif ment.TransCode == "Player_Push" then
                    Main = "Push player"
                    Sub = "push that jackass"
                else
                    Main = "No actions"
                    Sub = "however"
                end
                drawShadow(Main, "Radial_QM", sx + w * 0.6 * x, sy + h * 0.6 * y - fontHeight / 3, textCol, 1)
                drawShadow(Sub, "RadialSmall_QM", sx + w * 0.6 * x, sy + h * 0.6 * y + fontHeight / 2, textCol, 1)
            end
        end
    end
end

local function DrawRadialMenu()
    if RadialOpen then
        local sw,sh = ScrW(), ScrH()
        local total = #RadialMents
        local w = math.min(sw * 0.45, sh * 0.45)
        local h = w
        local sx, sy = sw / 2, sh / 2

        local selected = getRadialSelected() or -1

        if not circleVertex then
            circleVertex = {}
            local max = 50
            for i = 0, max do
                local vx, vy = math.cos((math.pi * 2) * i / max), math.sin((math.pi * 2) * i / max)
                table.insert(circleVertex, {x = sx + w* 1 * vx, y= sy + h* 1 * vy})
            end
        end

        surface.SetTexture(tex)
        local defaultTextCol = color_white
        if selected <= 0 or selected ~= selected then
            surface.SetDrawColor(20,20,20,180)
        else
            surface.SetDrawColor(20,20,20,120)
            defaultTextCol = Color(150,150,150)
        end
        surface.DrawPoly(circleVertex)

        local add = math.pi * 1.5 + math.pi / total
        local add2 = math.pi * 1.5 - math.pi / total

        for k,ment in pairs(RadialMents) do
            local x,y = math.cos((k - 1) / total * math.pi * 2 + math.pi * 1.5), math.sin((k - 1) / total * math.pi * 2 + math.pi * 1.5)
            local lx, ly = math.cos((k - 1) / total * math.pi * 2 + add), math.sin((k - 1) / total * math.pi * 2 + add)

            local textCol = defaultTextCol
            if(ment.Code=="villain")then
                textCol=Color(200,10,10,150)
            elseif(ment.Code=="hero") or (ment.Code=="police")then
                textCol=Color(20,200,255,150)
            end
            if selected == k then
                local vertexes = {} 

                local lx2, ly2 = math.cos((k - 1) / total * math.pi * 2 + add2), math.sin((k - 1) / total * math.pi * 2 + add2)

                table.insert(vertexes, {x = sx, y = sy})
                table.insert(vertexes, {x = sx + w* 1 * lx2, y= sy + h* 1 * ly2})

                local max = math.floor(50 / total)
                for i = 0, max do
                    local addv = (add - add2) * i / max + add2
                    local vx, vy = math.cos((k - 1) / total * math.pi * 2 + addv), math.sin((k - 1) / total * math.pi * 2 + addv)
                    table.insert(vertexes, {x = sx + w* 1 * vx, y= sy + h* 1 * vy})
                end

                table.insert(vertexes, {x = sx + w* 1 * lx, y= sy + h* 1 * ly})

                surface.SetTexture(tex)
                surface.SetDrawColor(20,120,255,120)
                if ment.Code == "happy" then
                    surface.SetDrawColor(255, 20, 20, 120)
                elseif ment.Code == "burp" then
                    surface.SetDrawColor(195, 167, 30, 120)
                elseif ment.Code == "fart" then
                    surface.SetDrawColor(111, 94, 8, 120)
                elseif ment.Code == "kurare" then
                    surface.SetDrawColor(192, 23, 23, 120)
                end

                surface.DrawPoly(vertexes)
                textCol = color_white
            end
            local ply = LocalPlayer()
            local Main, Sub

            if ment.TransCode == "Ammo Menu" then
                Main = "Ammo Menu"
                Sub = "drop ammo"
            elseif ment.TransCode == "UnloadWep" then
                Main = "Unload Ammo"
                Sub = "unload weapon in your hands"
            elseif ment.TransCode == "Drop" then
                Main = "Drop Weapon"
                Sub = "drop weapon in your hands"
            elseif ment.TransCode == "Phrase_Category" then
                Main = "Phrase"
                Sub = "say something"
            elseif ment.TransCode == "LaserOn" then
                Main = "Laser"
                Sub = (ply:GetActiveWeapon():GetNWBool("LaserStatus") and "Disable") or "Enable"
            elseif ment.TransCode == "MenuUse_Category" then
                Main = "Actions Menu"
                Sub = "interact with the environment"
            elseif ment.TransCode == "attach" then
                Main = "Modify weapon"
                Sub = "equip weapon attachments"
            elseif ment.TransCode == "nvg" then
                Main = "NVG"
                Sub = "up or down nvg"
            else
                Main = "?"
                Sub = "?"
            end
            drawShadow(ply:GetNWString("Character_Name") or "Bystander", "GM", w/2.7, h/8.5, Color(255,255,255,255), 1)
            drawShadow(ply:GetNWString("Role") or "Bystander", "GM", w/3, h/5, Color(ply:GetNWInt("RoleColor_R"),ply:GetNWInt("RoleColor_G"),ply:GetNWInt("RoleColor_B"),255), 1)
            drawShadow(Main, "Radial_QM", sx + w * 0.6 * x, sy + h * 0.6 * y - fontHeight / 3,textCol, 1)
            drawShadow(Sub, "RadialSmall_QM", sx + w * 0.6 * x, sy + h * 0.6 * y + fontHeight / 2, textCol, 1)
        end
    end
end

-- Hook drawing
hook.Add("HUDPaint", "HMCD_DrawRadialMenu", function()
    if Menuuse then Drawmenu_useMenu() end
    if RadialOpen then DrawRadialMenu() end
end)

-- Command handling
local function addElement(elements, transCode, code)
    local t = {}
    t.TransCode = transCode
    t.Code = code
    table.insert(elements, t)
end

concommand.Add("+menu_use", function(client, com, args, full)
    if client:Alive() then
        local elements = {}
        local tr = client:GetEyeTrace()
        local ent = tr.Entity
        local distance = client:GetPos():Distance(tr.HitPos) -- Use HitPos for accuracy
        
        if distance <= 100 and IsValid(ent) then
            if HMCD_IsDoor(ent) then
                addElement(elements, "Door_Stuck", "door_stuck")
                addElement(elements, "Door_UnStuck", "door_unstuck")
            end

            if ent:IsPlayer() then
                addElement(elements, "Player_Push", "ply_push")
            end
        end
        
        Openmenu_useMenu(elements)
    end
end)

concommand.Add("-menu_use", function(client, com, args, full)
    menu_useMousePressed(MOUSE_LEFT)
end)

concommand.Add("+hmcd_radial", function(client, com, args, full)
    if client:GetNWBool("Phraseopen") then return end
    if client:GetNWBool("Otrub", false) == true then return end
    if client:Alive() then
        local Wep = client:GetActiveWeapon()
        local Ammos = {}
        if HMCD_AmmoNames then
            for key,name in pairs(HMCD_AmmoNames) do
                local Amownt = client:GetAmmoCount(key)
                if (Amownt > 0) then Ammos[key] = Amownt end
            end
        end

        local elements = {}
        if table.Count(Ammos) > 0 then addElement(elements, "Ammo Menu","hmcd_ammo") end
        addElement(elements, "Phrase_Category","phrase")
        if client:GetNWBool("Mask", "") == "NVG" then addElement(elements, "nvg", "nvg") end
        addElement(elements, "MenuUse_Category","usemenu") -- Always add use menu option
        if IsValid(Wep) then
            if Wep:GetClass() ~= "wep_jack_hmcd_hands" then
                addElement(elements, "Drop", "drop")
                addElement(elements, "attach", "attach")
            end
            if Wep:GetNWBool("Laser", false) then addElement(elements, "LaserOn","laser") end
            if Wep:Clip1() > 0 then
                addElement(elements, "UnloadWep", "unloadwep")
            end
        end
        OpenRadialMenu(elements)
    end
end)

concommand.Add("-hmcd_radial", function(client, com, args, full)
    RadialMousePressed(MOUSE_LEFT)
end)

-- Key release detection for Radial Menu (since OnSpawnMenuClose might not fire)
hook.Add("Think", "HMCD_RadialKeyRelease", function()
    if RadialOpen then
        local key = input.LookupBinding("+menu")
        if key then
            local keyCode = input.GetKeyCode(key)
            if keyCode and not input.IsKeyDown(keyCode) then
                -- Key released, trigger -hmcd_radial
                LocalPlayer():ConCommand("-hmcd_radial")
            end
        end
    end
end)

-- Click support for Radial Menu
hook.Add("GUIMousePressed", "HMCD_RadialClick", function(code, vec)
    if RadialOpen and code == MOUSE_LEFT then
        RadialMousePressed(code)
        -- return true -- Don't consume, let engine handle it if needed, but we acted.
    end
    if Menuuse and code == MOUSE_LEFT then
        menu_useMousePressed(code)
    end
end)

local HMCD_HelpSpawnMenu = false
local function HMCD_ToggleSpawnMenu()
    if not (LocalPlayer():IsAdmin() or LocalPlayer():IsSuperAdmin()) then return end
    if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
        if isfunction(g_SpawnMenu.Close) then
            g_SpawnMenu:Close()
        else
            g_SpawnMenu:SetVisible(false)
        end
        return
    end

    if IsValid(g_SpawnMenu) then
        if isfunction(g_SpawnMenu.Open) then
            g_SpawnMenu:Open()
        else
            g_SpawnMenu:SetVisible(true)
            if isfunction(g_SpawnMenu.MakePopup) then
                g_SpawnMenu:MakePopup()
            end
            gui.EnableScreenClicker(true)
        end
        return
    end

    HMCD_HelpSpawnMenu = true
    RunConsoleCommand("+menu")
end

hook.Add("PlayerBindPress", "HMCD_HelpSpawnMenu", function(ply, bind, pressed)
    if not pressed then return end
    if not isstring(bind) then return end
    if bind:find("gm_showhelp", 1, true) then
        HMCD_ToggleSpawnMenu()
        return true
    end
end)

-- Bind to key (User requested Q menu functionality)
hook.Add("OnSpawnMenuOpen", "HMCD_OverrideSpawnMenu", function()
    if HMCD_HelpSpawnMenu then
        HMCD_HelpSpawnMenu = false
        return -- Allow spawn menu
    end

    -- Run our command
    RunConsoleCommand("+hmcd_radial")
    -- Prevent default spawn menu
    return false 
end)

hook.Add("OnSpawnMenuClose", "HMCD_OverrideSpawnMenuClose", function()
    RunConsoleCommand("-hmcd_radial")
end)
