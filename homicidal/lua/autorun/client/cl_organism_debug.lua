local OrganismData = {}
local lastReceiveTime = 0

-- Create a scalable font
surface.CreateFont("HMCD_DebugFont", {
    font = "Verdana",
    size = ScreenScale(6), -- Scales with screen resolution (approx 14px on 1080p)
    weight = 600,
    antialias = true,
    shadow = true
})

net.Receive("HMCD_DebugOrganism", function()
    OrganismData = net.ReadTable()
    lastReceiveTime = CurTime()
end)

net.Receive("HMCD_DebugOrganHitboxes", function()
    local hitboxes = net.ReadTable()
    for _, box in ipairs(hitboxes) do
        debugoverlay.BoxAngles(box.pos, box.mins, box.maxs, box.ang, 5, Color(255, 0, 0, 50))
    end
end)

-- Helper to collect lines for multi-column rendering
local function CollectLines(tbl, indentLevel, lines)
    local keys = table.GetKeys(tbl)
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    
    for _, k in ipairs(keys) do
        local v = tbl[k]
        local keyStr = tostring(k)
        
        if type(v) == "table" then
            table.insert(lines, {
                text = keyStr .. ":",
                indent = indentLevel,
                isHeader = true,
                color = Color(255, 220, 100)
            })
            CollectLines(v, indentLevel + 1, lines)
        else
            local valStr = tostring(v)
            local valColor = Color(255, 255, 255)
            if type(v) == "number" then valColor = Color(100, 255, 100) end
            if type(v) == "boolean" then valColor = v and Color(100, 255, 100) or Color(255, 100, 100) end
            
            table.insert(lines, {
                key = keyStr,
                value = valStr,
                indent = indentLevel,
                isHeader = false,
                color = valColor
            })
        end
    end
end

hook.Add("HUDPaint", "HMCD_OrganismDebugHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    -- Check developer convar
    local dev = GetConVar("developer")
    if not dev or dev:GetInt() < 1 then return end

    if not OrganismData or table.Count(OrganismData) == 0 then return end

    surface.SetFont("HMCD_DebugFont")
    local _, fontHeight = surface.GetTextSize("A")
    local lineHeight = fontHeight + (fontHeight * 0.2)
    local indentWidth = fontHeight * 1.5
    
    local lines = {}
    CollectLines(OrganismData, 0, lines)
    
    -- Calculate column width based on max content width
    local maxW = 0
    for _, line in ipairs(lines) do
        local w = 0
        if line.isHeader then
            w = (line.indent * indentWidth) + surface.GetTextSize(line.text)
        else
            w = (line.indent * indentWidth) + surface.GetTextSize(line.key .. ": " .. line.value)
        end
        if w > maxW then maxW = w end
    end
    
    local padding = ScreenScale(5)
    local colWidth = maxW + (padding * 2)
    local startX, startY = padding, padding
    
    -- Background for the whole area? Or per column?
    -- User asked for "rest of the stuff that doesnt fit... will be cut into parts... right next to it"
    -- So we draw separate columns.
    
    local screenHeight = ScrH()
    local currentY = startY + ScreenScale(10) -- Title offset
    local currentX = startX
    
    -- Calculate columns needed
    local columns = {}
    local currentCol = {}
    
    -- Title takes up space in first column
    local availableHeightFirst = screenHeight - (startY + ScreenScale(10)) - padding
    local availableHeight = screenHeight - padding * 2
    
    local remainingH = availableHeightFirst
    
    for _, line in ipairs(lines) do
        if remainingH < lineHeight then
            -- Push current col
            table.insert(columns, currentCol)
            currentCol = {}
            remainingH = availableHeight
        end
        
        table.insert(currentCol, line)
        remainingH = remainingH - lineHeight
    end
    if #currentCol > 0 then table.insert(columns, currentCol) end
    
    -- Draw Columns
    for i, col in ipairs(columns) do
        local drawX = startX + ((i-1) * (colWidth + padding))
        local drawY = startY
        
        -- Draw Box Background for this column
        local colH = (#col * lineHeight) + (padding * 2)
        if i == 1 then colH = colH + ScreenScale(10) end -- Add title space for first col
        
        draw.RoundedBox(4, drawX, drawY, colWidth, colH, Color(0, 0, 0, 200))
        
        local textY = drawY + padding
        if i == 1 then
            draw.SimpleText("Organism Debug", "HMCD_DebugFont", drawX + padding, textY, Color(255, 150, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            textY = textY + ScreenScale(10)
        end
        
        for _, line in ipairs(col) do
            local lineX = drawX + padding + (line.indent * indentWidth)
            
            if line.isHeader then
                draw.SimpleText(line.text, "HMCD_DebugFont", lineX, textY, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            else
                draw.SimpleText(line.key .. ": ", "HMCD_DebugFont", lineX, textY, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                local w, _ = surface.GetTextSize(line.key .. ": ")
                draw.SimpleText(line.value, "HMCD_DebugFont", lineX + w, textY, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            textY = textY + lineHeight
        end
    end
end)
