if SERVER then return end

hook.Add("RenderScreenspaceEffects", "HMCD_ConsciousnessBlur", function()
	local ply = LocalPlayer()
	if not ply:Alive() then return end
	
	local cons = ply:GetNWFloat("HMCD_Consciousness", 100)
	
	-- Debug print once per second if cons is low
	if cons < 100 and (ply.NextConsPrint or 0) < CurTime() then
		ply.NextConsPrint = CurTime() + 5
		-- print("[HMCD] Current Consciousness: " .. cons)
	end
	
	if cons < 100 then
		-- Motion Blur Logic
		local add_alpha = 0.0
		local draw_alpha = 0.0
		
		if cons <= 50 then
			-- 50 down to 0: Insane to Extreme
			local severity = (50 - cons) / 50 -- 0 to 1
			add_alpha = 0.05 - (severity * 0.03) -- 0.05 down to 0.02
			draw_alpha = 0.95 + (severity * 0.04) -- 0.95 up to 0.99
		else
			-- 100 down to 50: None to Insane
			local severity = (100 - cons) / 50 -- 0 to 1
			add_alpha = 1.0 - (severity * 0.95) -- 1.0 down to 0.05
			draw_alpha = severity * 0.95 -- 0.0 up to 0.95
		end
		
		if draw_alpha > 0.01 then
			DrawMotionBlur(add_alpha, draw_alpha, 0.01)
		end
		
		-- Add some color modification to make it more obvious
		local tab = {
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = -( (100-cons)/100 * 0.1 ), -- Darken slightly
			["$pp_colour_contrast"] = 1 - ( (100-cons)/100 * 0.2 ), -- Reduce contrast
			["$pp_colour_colour"] = 1 - ( (100-cons)/100 * 0.5 ), -- Desaturate
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		}
		DrawColorModify(tab)
	end
end)


