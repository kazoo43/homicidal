util.AddNetworkString("HMCD_DebugOrganism")

local blacklistedKeys = {
    ["Info"] = true,
    ["Mics"] = true,
    ["Equipment"] = true,
    ["UsersInventory"] = true,
    ["slots"] = true,
    ["wep"] = true,
    ["WepCons"] = true,
    ["WepCons2"] = true,
    ["fakeragdoll"] = true,
    ["ragdoll"] = true,
    ["CheckPoint"] = true,
    ["LastAttacker"] = true,
    ["LastHitgroup"] = true,
    ["LastDamageType"] = true,
    ["dt"] = true, -- DataTable
}

local function IsSimpleValue(val)
    local t = type(val)
    return t == "number" or t == "boolean" or (t == "string" and #val < 50)
end

local function IsSimpleTable(tbl, depth)
    if depth > 2 then return false end
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
        if count > 20 then return false end -- Too big
        if not IsSimpleValue(v) then
            if type(v) == "table" then
                if not IsSimpleTable(v, depth + 1) then return false end
            else
                return false
            end
        end
    end
    return true
end

local function GetOrganismData(ply)
    local data = {}
    -- Helper to safely get the table
    local tab = ply:GetTable()
    if not tab then return data end

    for k, v in pairs(tab) do
        if type(k) ~= "string" then continue end
        if blacklistedKeys[k] then continue end
        
        -- Filter out standard GMod/Engine functions/userdata
        if type(v) == "function" or type(v) == "userdata" or type(v) == "panel" then continue end

        if IsSimpleValue(v) then
            data[k] = v
        elseif type(v) == "table" then
            if IsSimpleTable(v, 1) then
                data[k] = v
            end
        end
    end
    return data
end

local nextPrint = 0

timer.Create("HMCD_OrganismDebugUpdate", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() then
            local data = GetOrganismData(ply)
            
            -- Debug print every 5 seconds
            if CurTime() > nextPrint then
               -- print("[HMCD Debug] Sending data to " .. ply:Nick() .. " | Keys: " .. table.Count(data))
            end

            net.Start("HMCD_DebugOrganism")
            net.WriteTable(data)
            net.Send(ply)
        end
    end
    if CurTime() > nextPrint then
        nextPrint = CurTime() + 5
    end
end)
