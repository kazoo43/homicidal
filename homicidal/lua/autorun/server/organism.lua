
if SERVER then
	print("[HMCD] Server organism script loaded")
	AddCSLuaFile("autorun/client/cl_consciousness.lua")
end

hook.Add("PlayerSpawn", "HMCD_ConsciousnessInit", function(ply)
	if PLYSPAWN_OVERRIDE then return end
	ply.consciousness = 100
	ply:SetNWFloat("HMCD_Consciousness", 100)
end)

if not blood_drop then
	blood_drop = {
		"blood/drop1.wav",
		"blood/drop2.wav",
		"blood/drop3.wav",
		"blood/drop4.wav"
	}
end

-- Stamina Work

hook.Add("Player Think", "StaminaWork", function(ply,time)
	ply.stamina = ply.stamina or {}
	ply.stamina['leg'] = ply.stamina['leg'] or 100
	ply.adrenalineinjector = ply.adrenalineinjector or 0
	
	local leg = math.max(0, ply.stamina['leg'])
	local duo_leg = ply.Bones['RightLeg']+ply.Bones['LeftLeg']

	local run = math.max(10, leg*6.5+ply.adrenalineinjector)
	local walk = math.max(10, leg*2+ply.adrenalineinjector)
	local jump = math.max(0, leg*4.2)
	local hui = (ply.ModelSex == "male" and "m") or "f"
	if walk != ply:GetWalkSpeed() then ply:SetWalkSpeed(walk)  end
	if jump != ply:GetJumpPower() then ply:SetJumpPower(jump) end
	if run != ply:GetRunSpeed() then ply:SetRunSpeed(run) end
	if ply:HasGodMode() or not ply:Alive() or (ply.staminaNext or time) > time then return end
	ply.staminaNext = time + 1

	if ply:GetMoveType() == MOVETYPE_WALK and ply:IsSprinting() and ply:IsOnGround() and ply.stamina['leg'] >= 3 and ply:GetVelocity():Length() > 1 then
		ply.stamina['leg'] = math.max(0, ply.stamina['leg'] - 2.5)
	end
	if leg < 20 then
		ply:EmitSound("snds_jack_hmcd_breathing/" .. hui .. math.random(1,6) .. ".wav",60,100,0.6,CHAN_AUTO)
	end
end)

hook.Add("EntityTakeDamage", "ConsciousnessDamage", function(target, dmginfo)
	if target:IsPlayer() then
		target.consciousness = target.consciousness or 100
		local dmg = dmginfo:GetDamage()
		local mult = 1.0

		-- Headshot multiplier (3x)
		if target.lasthitgroup == HITGROUP_HEAD then
			mult = mult * 3
		end

		-- Increased damage for crush and fall
		if dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_FALL) then
			mult = mult * 0.5
		end
		
		-- Base multiplier increased (was 0.8)
		target.consciousness = math.Clamp(target.consciousness - (dmg * 0.5 * mult), 0, 100)
		
		target:SetNWFloat("HMCD_Consciousness", target.consciousness)
	end
end)

-- Hook into the custom damage system to handle ragdoll/fake damage
hook.Add("HOOK_UNION_Damage", "ConsciousnessRagdollDamage", function(ply, hitgroup, dmginfo, rag)
	if IsValid(ply) and ply:IsPlayer() then
		ply.consciousness = ply.consciousness or 100
		local dmg = dmginfo:GetDamage()
		local mult = 1.0

		-- Headshot multiplier
		if hitgroup == HITGROUP_HEAD then
			mult = mult * 3
		end

		-- Increased damage for crush and fall
		if dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_FALL) then
			mult = mult * 0.5
		end
		
		-- Same high multiplier as normal damage
		ply.consciousness = math.Clamp(ply.consciousness - (dmg * 0.5 * mult), 0, 100)
		
		ply:SetNWFloat("HMCD_Consciousness", ply.consciousness)
	end
end)

hook.Add("Player Think", "ConsciousnessThink", function(ply)
	if not ply:Alive() then return end
	
	ply.ConsciousnessNextThink = ply.ConsciousnessNextThink or 0
	if ply.ConsciousnessNextThink > CurTime() then return end
	ply.ConsciousnessNextThink = CurTime() + 1

	local change = 1 -- Reduced base recovery (was 0.5)

	-- Pain reduction
	if ply.pain > 250 then
		change = change - 2.0
	elseif ply.pain > 100 then
		change = change - 1.0
	end

	-- Blood reduction
	if ply.Blood < 3000 then
		change = change - 2.0
	elseif ply.Blood < 4000 then
		change = change - 1.0
	end

	ply.consciousness = ply.consciousness or 100
	ply.consciousness = math.Clamp(ply.consciousness + change, 0, 100)
	
	if ply.consciousness < 100 then
		ply:SetNWFloat("HMCD_Consciousness", ply.consciousness)
	end
end)

hook.Add("KeyPress", "JumpStamina", function(ply, key)
	if (key == IN_JUMP) and ply:IsOnGround() and ply:Alive() and ply:GetMoveType() == MOVETYPE_WALK then
		if ply.stamina and ply.stamina['leg'] then
			ply.stamina['leg'] = math.max(0, ply.stamina['leg'] - 3.5)
		end
	end
end)

------------------------------------------------------------------

-- Organs Work
OrgansNextThink = 0
LungNextThink = 0
hook.Add("Player Think","Organs_Hit_Reactions",function(ply,time)
	ply.OrgansNextThink = ply.OrgansNextThink or OrgansNextThink
	ply.LungNextThink = ply.LungNextThink or LungNextThink
	if ply.o2 < 0 then
		ply:ChatPrint("You died because of a small amount of oxygen.")
		ply:Kill()
		ply.o2 = 1
	end

	if ply.Blood <= 1000 and ply:Alive() then
		ply:ChatPrint("You died due to a lot of blood loss.")
		ply:Kill()
	end
	
	if ply.pain >= 900 and ply:Alive() then
		ply:ChatPrint("You died due to pain shock.")
		ply:Kill()
	end

	if ply.overdose >= 10 and ply:Alive() then
		ply:ChatPrint("You died due to an overdose.")
		ply:Kill()
	end
	
	if not ( ply.OrgansNextThink > CurTime() ) and ply:Alive() then
		ply.OrgansNextThink = CurTime() + 0.2

		if ply.Hit["intestines"] == true then
			ply.cant_eat = true
		end

		if ply.Hit["heart"] == true then
			ply.heartstop = true
		end

    end

	if not ( ply.LungNextThink > CurTime() ) and ply:Alive() then
		ply.LungNextThink = CurTime() + 1

		if ply.Hit["lungs"] == true then
			ply.o2 = ply.o2 - math.Rand(0.1, 0.4)
		end

		if !ply:GetNWBool("Breath", true) then
			ply.o2 = ply.o2 - math.Rand(0.1, 0.3)
		end

		if ply:GetNWBool("Breath", true) then
			ply.o2 = ply.o2 + math.Rand(0.08, 0.3)
		end
		
    end
end)

------------------------------------------------------------------

-- Heart Work

function Pulse(ply)
    local basePulse = 70
    local bloodFactor = ply.Blood / 4000
    local adrenalineFactor = ply.adrenaline
    local painFactor = 1 + (ply.pain / 1000)

    pulse = basePulse * bloodFactor * painFactor + adrenalineFactor
	return pulse
end

hook.Add("Player Think","HeartWork",function(ply,time)
	if not ply:Alive() or ply:HasGodMode() then return end
	ply.pulse = Pulse(ply)
	local ent = IsValid(ply.fakeragdoll) and ply.fakeragdoll or ply
	if ply.ArteryThink < CurTime() then
	
		ply.ArteryThink = ply.ArteryThink + 0.6
		if ply.Hit["rl_artery"] or ply.Hit["ll_artery"] then
			ply.Blood = ply.Blood - 15
			sound.Play(table.Random(blood_drop), ent:GetPos(), 55, 100,1)
			BloodParticle(ply)
		end

		if ply.Hit["rh_artery"] or ply.Hit["lh_artery"] then
			ply.Blood = ply.Blood - 10
			sound.Play(table.Random(blood_drop), ent:GetPos(), 55, 100,1)
			BloodParticle(ply)
		end

		if ply.Hit["neck_artery"] then
			ply.Blood = ply.Blood - 30
			sound.Play(table.Random(blood_drop), ent:GetPos(), 55, 100,1)
			BloodParticle(ply)
		end

	end
end)

local hook_run = hook.Run

timer.Create("Headcrab",2,0,function()
    for _, ply in player.Iterator() do
        hook_run("Headcrab", ply)
    end

end)

timer.Create("PulseWork",0.9,0,function()
    for _, ply in player.Iterator() do
        hook_run("Bleeding", ply)
    end

end)

hook.Add("Headcrab", "Headcrabwork", function(ply)
    if IsValid(ply) and ply:Alive() and ply:GetNWBool("Headcrab", false) == true then
        ply.BleedOuts['stomach'] = ply.BleedOuts['stomach'] + 1
        ply.pain_add = ply.pain_add + 5
        if math.random(1,5) == 2 then
            if !ply.fake then
                 Faking(ply)
            end
        end
    end
end)

hook.Add("Bleeding", "BleedWorkPulse", function(ply)
	if not ply:Alive() then return end
	local ent = IsValid(ply.fakeragdoll) and ply.fakeragdoll or ply

	if ply.BleedOuts["right_hand"] > 0 then
		Bleed(ply, 0.1, "right_hand", ent)
	end

	if ply.BleedOuts["left_hand"] > 0 then
		Bleed(ply, 0.1, "left_hand", ent)
	end

	if ply.BleedOuts["left_leg"] > 0 then
		Bleed(ply, 0.1, "left_leg", ent)
	end

	if ply.BleedOuts["right_leg"] > 0 then
		Bleed(ply, 0.1, "right_leg", ent)
	end

	if ply.BleedOuts["right_leg"] > 0 then
		Bleed(ply, 0.1, "right_leg", ent)
	end

	if ply.BleedOuts["stomach"] > 0 then
		Bleed(ply, 0.1, "stomach", ent)
	end

	if ply.BleedOuts["chest"] > 0 then
		Bleed(ply, 0.1, "chest", ent)
	end
end)

local BLEEDING_NextThink1 = 0
hook.Add("Think","BleedingBodies",function()
	for i, ent in pairs(BleedingEntities) do
		if not ent.IsBleeding then return end
		ent.BLEEDING_NextThink1 = ent.BLEEDING_NextThink1 or BLEEDING_NextThink1
		if ent.BLEEDING_NextThink1 < CurTime() then
			ent.BLEEDING_NextThink1 = CurTime() + math.random(0.6, 0.8)
			local rn = math.Rand(-0.35, 0.35)
			local rnn = math.Rand(-0.35, 0.35)
			local tr = {}
			tr.start = Vector(ent:GetPos(0, 0, 50)) + Vector(0, 0, 50)
			tr.endpos = tr.start + Vector(rn, rnn, -1) * 8000
			tr.filter = ent
			local trw = util.TraceHull(tr)
			local Pos1 = trw.HitPos + trw.HitNormal
			local Pos2 = trw.HitPos - trw.HitNormal
			if IsValid(ent) and blood_drop then
				ent:EmitSound(table.Random(blood_drop), 60, math.random(230, 240), 0.2, CHAN_AUTO)
			end
			util.Decal("Blood", Pos1, Pos2, ent)
		end
	end
end)

local CTime = CurTime
hook.Add("Player Think", "AdrenalineWork", function(ply)
	ply.adrenaline_unone = ply.adrenaline_unone or CTime()
	ply.pain_addtime = ply.pain_addtime or CTime()

	if ply.adrenaline < 0 then ply.adrenaline = 0 end
	if ply.pain_add < 0 then ply.pain_add = 0 end

	if ply.pain_add > 0 and ply.adrenaline < 10 then
		if ply.pain_addtime < CTime() then
			ply.pain_addtime = ply.pain_addtime + 0.15
			ply.pain_add = ply.pain_add - 1
			ply.pain = ply.pain + 1
		end
	end

	if ply.adrenaline > 0 then
		if ply.adrenaline_unone < CTime() then
			ply.adrenaline_unone = ply.adrenaline_unone + 1
			ply.adrenaline = ply.adrenaline - 0.3
		end
	end

	if ply.adrenaline < 5 then
		if ply.ane_ra then
			ply:ChatPrint("Your right arm is broken")
			ply.ane_ra = false
		elseif ply.ane_la then
			ply:ChatPrint("Your left arm is broken")
			ply.ane_la = false
		elseif ply.ane_ll then
			ply:ChatPrint("Your left leg is broken")
			ply.ane_ll = false
		elseif ply.ane_rl then
			ply:ChatPrint("Your right leg is broken")
			ply.ane_rl = false
		end
	end

	if ply.adrenaline < 20 then
		if ply.ane_neck then
			ply:ChatPrint("Your neck is broken")
            ply:Kill()
			ply.ane_neck = false
		end
	end

	if ply.adrenaline < 15 then
		if ply.ane_jdis then
            ply:ChatPrint("Your jaw has been dislocated")
            if !ply.fake then
                Faking(ply)
            end
			ply.ane_jdis = false
		elseif ply.ane_jaw then
            ply:ChatPrint("Your jaw is broken")
            ply.mutejaw = true
			ply.ane_jaw = false
		end
	end
end)