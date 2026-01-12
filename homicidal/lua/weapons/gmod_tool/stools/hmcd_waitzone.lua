TOOL.Category = "Homicide"
TOOL.Name = "Wait Zone Editor"
TOOL.Command = nil
TOOL.ConfigName = "" 

if CLIENT then
    language.Add("tool.hmcd_waitzone.name", "Wait Zone Editor")
    language.Add("tool.hmcd_waitzone.desc", "Create and edit custom level transition wait zones for HL2 Coop")
    language.Add("tool.hmcd_waitzone.0", "Left Click: Create/Update | Right Click: Remove | Reload: Cycle Size (Small/Medium/Large)")
    
    TOOL.Information = {
        { name = "left", stage = 0 },
        { name = "right", stage = 0 },
        { name = "reload", stage = 0 }
    }
end

TOOL.ClientConVar = {
    ["size"] = "1" -- 1=Small, 2=Medium, 3=Large
}

local ZONE_SIZES = {
    [1] = { Vector(-100, -100, -50), Vector(100, 100, 150) }, -- Small (Original)
    [2] = { Vector(-250, -250, -100), Vector(250, 250, 250) }, -- Medium
    [3] = { Vector(-500, -500, -200), Vector(500, 500, 500) }  -- Large
}

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ply:IsAdmin() then
        ply:ChatPrint("You must be an admin to use this tool.")
        return false
    end
    
    local pos = trace.HitPos
    
    -- Get current size
    local sizeIdx = self:GetClientNumber("size", 1)
    local bounds = ZONE_SIZES[sizeIdx] or ZONE_SIZES[1]
    
    HMCD_WaitZone_Update(pos, bounds[1], bounds[2])
    
    -- Visual feedback
    local eff = EffectData()
    eff:SetOrigin(pos)
    util.Effect("cball_explode", eff)
    
    ply:ChatPrint("Wait Zone set at: " .. tostring(pos) .. " (Size: " .. sizeIdx .. ")")
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ply:IsAdmin() then return false end
    
    HMCD_WaitZone_Remove()
    ply:ChatPrint("Custom Wait Zone removed. Reverting to map defaults.")
    
    return true
end

function TOOL:Reload(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ply:IsAdmin() then return false end
    
    -- Cycle size
    local current = self:GetClientNumber("size", 1)
    local nextSize = current + 1
    if nextSize > 3 then nextSize = 1 end
    
    ply:ConCommand("hmcd_waitzone_size " .. nextSize)
    
    local sizeNames = { "Small", "Medium", "Large" }
    ply:ChatPrint("Wait Zone Size: " .. sizeNames[nextSize])
    
    return true
end

function TOOL:DrawHUD()
    if not CLIENT then return end
    
    local ply = LocalPlayer()
    
    -- Draw text instructions
    local x, y = ScrW() / 2, ScrH() / 2 + 100
    draw.SimpleText("Left Click: Set Custom Wait Zone", "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Right Click: Remove Custom Zone", "DermaDefault", x, y + 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local sizeIdx = self:GetClientNumber("size", 1)
    local sizeNames = { "Small", "Medium", "Large" }
    draw.SimpleText("Reload: Change Size (Current: " .. (sizeNames[sizeIdx] or "Unknown") .. ")", "DermaDefault", x, y + 40, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function TOOL:Think()
    if CLIENT then return end
    local ply = self:GetOwner()
    
    -- If holding tool, ensure debug visualization is active
    if IsValid(ply) and ply:IsAdmin() then
        local tr = ply:GetEyeTrace()
        -- Show preview of where it WOULD go
        local pos = tr.HitPos
        
        local sizeIdx = self:GetClientNumber("size", 1)
        local bounds = ZONE_SIZES[sizeIdx] or ZONE_SIZES[1]
        
        debugoverlay.Box(pos, bounds[1], bounds[2], 0.1, Color(255, 255, 0, 10))
    end
end

