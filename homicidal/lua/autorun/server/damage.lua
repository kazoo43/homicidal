
local filterEnt
local function filter(ent)
	return ent == filterEnt
end

util.AddNetworkString("HMCD_DebugOrganHitboxes")

local OrganHitboxes = {
    { name = "brain",       bone = "ValveBiped.Bip01_Head1", mins = Vector(2,-4,-3), maxs = Vector(6,1,3) },
    { name = "skull",       bone = "ValveBiped.Bip01_Head1", mins = Vector(1,-5,-4), maxs = Vector(7,2,4) },
    { name = "jaw",         bone = "ValveBiped.Bip01_Head1", mins = Vector(-1,-5,-3), maxs = Vector(2,1,3) },
    { name = "neckartery_1",bone = "ValveBiped.Bip01_Head1", mins = Vector(-3,-2,-2), maxs = Vector(0,-1,-1) },
    { name = "neckartery_2",bone = "ValveBiped.Bip01_Head1", mins = Vector(-3,-2,1), maxs = Vector(0,-1,2) },
    { name = "intestines",  bone = "ValveBiped.Bip01_Spine", mins = Vector(-4,-1,-6), maxs = Vector(1,5,6) },
    { name = "liver",       bone = "ValveBiped.Bip01_Spine1", mins = Vector(-4,-1,-6), maxs = Vector(2,5,-1) },
    { name = "stomach",     bone = "ValveBiped.Bip01_Spine1", mins = Vector(-4,-1,-1), maxs = Vector(2,5,6) },
    { name = "spine",       bone = "ValveBiped.Bip01_Spine1", mins = Vector(-8,-3,-1), maxs = Vector(2,-2,1), use_matrix = true },
    { name = "lung",        bone = "ValveBiped.Bip01_Spine2", mins = Vector(-1,0,-6), maxs = Vector(10,6,6) },
    { name = "heart",       bone = "ValveBiped.Bip01_Spine2", mins = Vector(1,0,-1), maxs = Vector(5,4,3) },
}

local util_TraceLine = util.TraceLine

function GetPhysicsBoneDamageInfo(ent,dmgInfo)
	local pos = dmgInfo:GetDamagePosition()
	local dir = dmgInfo:GetDamageForce():GetNormalized()

	dir:Mul(1024 * 8)

	local tr = {}
	tr.start = pos
	tr.endpos = pos + dir
	tr.filter = filter
	filterEnt = ent
	tr.ignoreworld = true

	local result = util_TraceLine(tr)
	if result.Entity == ent then
		return result.PhysicsBone
	end

	tr.endpos = pos - dir
	result = util_TraceLine(tr)
	if result.Entity == ent then
		return result.PhysicsBone
	end

	-- Fallback: Find closest physics bone
	local minDst = math.huge
	local bestBone = 0
	local count = ent:GetPhysicsObjectCount()
	
	if count > 0 then
		for i = 0, count - 1 do
			local phys = ent:GetPhysicsObjectNum(i)
			if IsValid(phys) then
				local dst = phys:GetPos():DistToSqr(pos)
				if dst < minDst then
					minDst = dst
					bestBone = i
				end
			end
		end
		return bestBone
	end
	
	return 0
end
local NULLENTITY = Entity(-1)

hook.Add("EntityTakeDamage","ragdamage",function(ent,dmginfo)
	if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_CLUB+DMG_GENERIC+DMG_BLAST) then
		if ent:IsRagdoll() then
			local phys = ent:GetPhysicsObject()
			local physBone = GetPhysicsBoneDamageInfo(ent, dmginfo)
			if physBone then
				phys = ent:GetPhysicsObjectNum(physBone)
			end
			
			if IsValid(phys) then
				local forceDir = dmginfo:GetDamageForce():GetNormalized()
				if forceDir:LengthSqr() < 0.001 then
					local att = dmginfo:GetAttacker()
					if IsValid(att) then
						local srcPos = att:GetPos()
						if att:IsPlayer() or att:IsNPC() then
							srcPos = att:GetShootPos()
						end
						forceDir = (dmginfo:GetDamagePosition() - srcPos):GetNormalized()
					end
				end
				
				local dmg = dmginfo:GetDamage()
				local forceMag = math.Clamp(dmg * 100, 100, 10000)

				if dmginfo:IsDamageType(DMG_BUCKSHOT) then
					forceMag = forceMag * 2
				elseif dmginfo:IsDamageType(DMG_CLUB) then
					forceMag = forceMag * 4
				end
				
				phys:ApplyForceCenter(forceDir * forceMag)
				dmginfo:SetDamageForce(Vector(0, 0, 0))
			end
		end
	end
	local ply = RagdollOwner(ent) or ent
    
    -- Fix for fake ragdolls where RagdollOwner might not find the player
    if (not IsValid(ply) or not ply:IsPlayer()) and ent:IsRagdoll() then
        local controller = ent:GetNWEntity("RagdollController")
        if IsValid(controller) and controller:IsPlayer() then
            ply = controller
        end
    end

    if not ply or not ply:IsPlayer() or not ply:Alive() or ply:HasGodMode() then
		return
	end

	local rag = ply ~= ent and ent

	if rag and dmginfo:IsDamageType(DMG_CRUSH) and att and att:IsRagdoll() then
		return true
	end
    
	local physics_bone = GetPhysicsBoneDamageInfo(ent,dmginfo) or 0
	local hitgroup
	local isfall

	local bonename = ent:GetBoneName(ent:TranslatePhysBoneToBone(physics_bone))
	ply.LastHitBoneName = bonename

	if bonetohitgroup[bonename] then hitgroup = bonetohitgroup[bonename] end

	local mul = RagdollDamageBoneMul[hitgroup]

	if rag and mul then dmginfo:ScaleDamage(mul) end
	local entAtt = dmginfo:GetAttacker()
    local att =
		(entAtt:IsPlayer() and entAtt:Alive() and entAtt) or
		(entAtt:GetClass() == "wep" and entAtt:GetOwner())
	att = dmginfo:GetDamageType() ~= DMG_CRUSH and att
	local Attacker = dmginfo:GetAttacker()
	local rubatPidor = DamageInfo()
	rubatPidor:SetAttacker(Attacker)
	--rubatPidor:SetInflictor(dmginfo:GetInflictor())
	rubatPidor:SetDamage(dmginfo:GetDamage())
	rubatPidor:SetDamageType(dmginfo:GetDamageType())
	rubatPidor:SetDamagePosition(dmginfo:GetDamagePosition())
	rubatPidor:SetDamageForce(dmginfo:GetDamageForce())

    ply.LastHitgroup = hitgroup
    ply.LastDamageType = dmginfo:GetDamageType()
    ply.LastAttacker = att
	ply.LastDMGInfo = rubatPidor
	dmginfo:ScaleDamage(2)
	if rag then
		if dmginfo:GetDamageType() == DMG_CRUSH then
			dmginfo:ScaleDamage(1 / 15)
			if dmginfo:GetDamage() < 5 then dmginfo:SetDamage(0) end
		end

		ply:SetHealth(ply:Health() - dmginfo:GetDamage())

		if ply:Health() <= 0 then ply:Kill() end
	end
	hook.Run("HOOK_UNION_Damage",ply,hitgroup,dmginfo,rag)
end)

--------------------------------------------------------

-- damage you base
hook.Add("HOOK_UNION_Damage","Hit",function(ply,hitgroup,dmginfo,rag)
    local ent = rag or ply
    local inf = dmginfo:GetInflictor()
    print("12123")
    if IsValid(inf) and inf:GetClass() == "npc_headcrab" then
        inf:Remove()
        ply:SetNWBool("Headcrab", true)
        ply.adrenaline = ply.adrenaline + 5
        ply.Wounds['stomach'] = ply.Wounds['stomach'] + 1    
    end
    if dmginfo:GetDamage() > 5 and ply:GetNWString("Helmet", "") == "ACH" and math.random(1,3) == 2 and (hitgroup == HITGROUP_HEAD or hitgroup == HITGROUP_CHEST or hitgroup == HITGROUP_STOMACH) then
        if ply.fake then
            ply:SetNWString("Helmet", "")
            if ply.fakeragdoll.helmetweld then
                ply.fakeragdoll.helmetweld:Remove()
            end
        else
            ply:SetNWString("Helmet", "")
            local helmet = ents.Create("ent_jack_hmcd_helmet")
            helmet:SetPos(ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1")))
            helmet:SetAngles(Angle(0,0,0))
            helmet:Activate()
            helmet:Spawn()
            timer.Simple(.3,function()
            helmet:GetPhysicsObject():SetVelocity(ply:GetAngles():Up()*6)
            end)
        end
    end
    if hitgroup == HITGROUP_HEAD and ply:GetNWString("Helmet", "") == "ACH" then
        if ply.fake then
            if ply.fakeragdoll.helmetweld and IsValid(ply.fakeragdoll:GetNWEntity("ENT_Helmet", "")) then
                local armorent = ply.fakeragdoll:GetNWEntity("ENT_Helmet", "")
                ply.fakeragdoll.helmetweld:Remove()
                armorent:GetPhysicsObject():SetVelocity(ply:GetAngles():Up()*1.5)
                ply:SetNWString("Helmet", "")
            end
        else
            ply:SetNWString("Helmet", "")
            local helmet = ents.Create("ent_jack_hmcd_helmet")
            helmet:SetPos(ply:GetPos())
            helmet:SetAngles(Angle(0,0,0))
            helmet:Activate()
            helmet:Spawn()
            helmet:GetPhysicsObject():SetVelocity(ply:GetAngles():Up()*1.5)
        end
    end
    if ply:GetNWString("Bodyvest", "") == "Level IIIA" then
        if hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_CHEST then
            dmginfo:ScaleDamage(1 / 3.4)
        end
    end
    if ply:GetNWString("Bodyvest", "") == "Level III" or ply:GetNWBool("HMCD_HEVSuit", false) then
        if hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_CHEST then
            dmginfo:ScaleDamage(1 / 5)
        end
    end
    if ply:GetNWString("Helmet", "") == "ACH" or ply:GetNWBool("HMCD_HEVSuit", false) then
        if hitgroup == HITGROUP_HEAD then
            dmginfo:ScaleDamage(1 / 3)
        end
    end
    if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER+DMG_SLASH+DMG_CRUSH+DMG_BLAST) then
        ply.adrenaline = ply.adrenaline + dmginfo:GetDamage() / 2.5
    end
    if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER+DMG_SLASH) then
        if hitgroup == HITGROUP_STOMACH then

            ply.Wounds["stomach"] = ply.Wounds["stomach"] + 1
            ply.BleedOuts["stomach"] = ply.BleedOuts["stomach"] + math.random(10, 15)

        elseif hitgroup == HITGROUP_CHEST then

            ply.Wounds["chest"] = ply.Wounds["chest"] + 1
            ply.BleedOuts["chest"] = ply.BleedOuts["chest"] + math.random(4, 9)

        elseif hitgroup == HITGROUP_LEFTARM then
            ply.Wounds["left_hand"] = ply.Wounds["left_hand"] + 1
            ply.BleedOuts["left_hand"] = ply.BleedOuts["left_hand"] + math.random(4, 5)

        elseif hitgroup == HITGROUP_RIGHTARM then

            ply.Wounds["right_hand"] = ply.Wounds["right_hand"] + 1
            ply.BleedOuts["right_hand"] = ply.BleedOuts["right_hand"] + math.random(4, 5)

        elseif hitgroup == HITGROUP_LEFTLEG then

            ply.Wounds["left_leg"] = ply.Wounds["left_leg"] + 1
            ply.BleedOuts["left_leg"] = ply.BleedOuts["left_leg"] + math.random(4, 6)

        elseif hitgroup == HITGROUP_RIGHTLEG then
            ply.Wounds["right_leg"] = ply.Wounds["right_leg"] + 1
            ply.BleedOuts["right_leg"] = ply.BleedOuts["right_leg"] + math.random(4, 6)
        else
            ply.BleedOuts["stomach"] = ply.BleedOuts["stomach"] + math.random(4, 6)
            ply.BleedOuts["chest"] = ply.BleedOuts["chest"] + math.random(4, 6)

        end
    end
    dmg_d = dmginfo:GetDamage()
    if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
        dmg_d = dmg_d * 3.5
    elseif dmginfo:IsDamageType(DMG_SLASH+DMG_CLUB+DMG_BLAST+DMG_CRUSH) then
        dmg_d = dmg_d * 1.2
    end
    local force_hit = dmg_d / math.random(2.1, 3.2)
    ply.bullet_force = ply.bullet_force + force_hit
    ply.pain_add = ply.pain_add + force_hit

    if hitgroup == HITGROUP_HEAD and dmginfo:GetDamageType() == DMG_CRUSH and dmginfo:GetDamage() >= 15 and ent:GetVelocity():Length() > 400 then
        if ply.adrenaline < 20 then
            ply:ChatPrint("Your neck is broken")
            ply:Kill()
        else
            ply.ane_neck = true
        end
        ent:EmitSound("neck_snap_01.wav",511,100,1,CHAN_ITEM)
        return
    end

    if hitgroup == HITGROUP_STOMACH and ply.fake and !ply.Hit['spine'] and dmginfo:GetDamageType() == DMG_CRUSH and ent:GetVelocity():Length() > 730 and not ply:GetNWBool("HMCD_HEVSuit") then
        ply.Hit['spine']=true
        ply:ChatPrint("Your spine is broken")
        ply.pain_add = ply.pain_add + 300
        ent:EmitSound("neck_snap_01.wav",70,125,0.7,CHAN_ITEM)
     end

    if dmginfo:GetDamage() >= 70 or (dmginfo:GetDamageType() == DMG_CRUSH and dmginfo:GetDamage() >= 5 and ent:GetVelocity():Length() > 100) then
        local brokenLeftLeg = hitgroup == HITGROUP_LEFTLEG
        local brokenRightLeg = hitgroup == HITGROUP_RIGHTLEG
        local brokenLeftArm = hitgroup == HITGROUP_LEFTARM
        local brokenRightArm = hitgroup == HITGROUP_RIGHTARM
        local sub = dmginfo:GetDamage() / 120
        if brokenLeftArm and ply.Bones['LeftArm']>=1 then
            if ply.adrenaline < 5 then
                ply:ChatPrint("Your left arm is broken")
            else
                ply.ane_la = true
            end
            ply.Bones['LeftArm'] = ply.Bones['LeftArm'] - sub
            ply.pain_add = ply.pain_add + 120
            ent:EmitSound("npc/barnacle/neck_snap2.wav",70,65,0.4,CHAN_ITEM)
        end

        if brokenRightArm and ply.Bones['RightArm']>=1 then
            if ply.adrenaline < 5 then
                ply:ChatPrint("Your right arm is broken")
            else
                ply.ane_ra = true
            end
            ply.Bones['RightArm'] = ply.Bones['RightArm'] - sub
            ply.pain_add = ply.pain_add + 120
            ent:EmitSound("npc/barnacle/neck_snap1.wav",70,65,0.4,CHAN_ITEM)
        end

        if brokenLeftLeg and ply.Bones['LeftLeg']>=1 then
            if ply.adrenaline < 5 then
                ply:ChatPrint("Your left leg is broken")
            else
                ply.ane_ll = true
            end
            ply.Bones['LeftLeg'] = ply.Bones['LeftLeg'] - sub
            ply.pain_add = ply.pain_add + 120
            ent:EmitSound("npc/barnacle/neck_snap1.wav",70,65,0.4,CHAN_ITEM)
            
            if ply.Bones['LeftLeg'] < 1 and !ply.fake then
                Faking(ply)
            end
        end

        if brokenRightLeg and ply.Bones['RightLeg']>=1 then
            if ply.adrenaline < 5 then
                ply:ChatPrint("Your right leg is broken")
            else
                ply.ane_rl = true
            end
            ply.Bones['RightLeg'] = ply.Bones['RightLeg'] - sub
            ply.pain_add = ply.pain_add + 120
            ent:EmitSound("npc/barnacle/neck_snap1.wav",70,65,0.4,CHAN_ITEM)
            
            if ply.Bones['RightLeg'] < 1 and !ply.fake then
                Faking(ply)
            end
        end
    end

    local penetration = dmginfo:GetDamageForce()
    if dmginfo:IsDamageType(DMG_BULLET + DMG_SLASH) then
        penetration:Mul(5)
    else
        penetration:Mul(0.03)
    end
    if !rag or (rag and !dmginfo:IsDamageType(DMG_CRUSH)) then
        local dmg = dmginfo:GetDamage()

        local dmgpos = dmginfo:GetDamagePosition()

        local hits = {}
        local debugBoxes = {}
        local devMode = GetConVar("developer"):GetInt() >= 1

        for _, organ in ipairs(OrganHitboxes) do
            local boneId = ent:LookupBone(organ.bone)
            if boneId then
                local pos, ang = ent:GetBonePosition(boneId)
                if organ.use_matrix then
                    local matrix = ent:GetBoneMatrix(boneId)
                    if matrix then
                        ang = matrix:GetAngles()
                    end
                end
                
                local hit = util.IntersectRayWithOBB(dmgpos, penetration, pos, ang, organ.mins, organ.maxs)
                if hit then
                    hits[organ.name] = hit
                end

                if devMode then
                     table.insert(debugBoxes, { pos = pos, ang = ang, mins = organ.mins, maxs = organ.maxs })
                end
            end
        end

        if devMode and #debugBoxes > 0 then
            local recipients = {}
            for _, p in ipairs(player.GetAll()) do
                if p:IsAdmin() then
                    table.insert(recipients, p)
                end
            end
            if #recipients > 0 then
                net.Start("HMCD_DebugOrganHitboxes")
                net.WriteTable(debugBoxes)
                net.Send(recipients)
            end
        end

        local brain = hits["brain"]
        local skull = hits["skull"]
        local jaw = hits["jaw"]
        local neckartery_1 = hits["neckartery_1"]
        local neckartery_2 = hits["neckartery_2"]
        local intestines = hits["intestines"]
        local liver = hits["liver"]
        local stomach = hits["stomach"]
        local spine = hits["spine"]
        local lung = hits["lung"]
        local heart = hits["heart"]

        --[[local pos,ang = ent:GetBonePosition(ent:LookupBone('ValveBiped.Bip01_L_Forearm'))
        local left_hand_artery = util.IntersectRayWithOBB(dmgpos,penetration, pos, ang, Vector(-5,-1,-2), Vector(10,0,-1))

        local pos,ang = ent:GetBonePosition(ent:LookupBone('ValveBiped.Bip01_R_Forearm'))
        local right_hand_artery = util.IntersectRayWithOBB(dmgpos,penetration, pos, ang, Vector(-5,-2,1), Vector(10,0,2))

        local pos,ang = ent:GetBonePosition(ent:LookupBone('ValveBiped.Bip01_L_Calf'))
        local left_leg_artery = util.IntersectRayWithOBB(dmgpos,penetration, pos, ang, Vector(-5,-1,-2), Vector(10,0,-1))

        local pos,ang = ent:GetBonePosition(ent:LookupBone('ValveBiped.Bip01_R_Calf'))
        local right_leg_artery = util.IntersectRayWithOBB(dmgpos,penetration, pos, ang, Vector(-5,-2,1), Vector(10,0,2))]]--

        if lung then
            if !ply.Hit['lungs'] and dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.Hit['lungs'] = true
				ply.BleedOuts["chest"] = ply.BleedOuts["chest"] + 20
            end
        end

        if brain then
            if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                -- Play sound at the location so it's audible even if the player is spectating/ragdolled
                sound.Play("headshot.mp3", dmgpos, 75, 100, 1)
                
                local effectdata = EffectData()
                effectdata:SetOrigin( dmgpos )
                util.Effect( "BloodImpact", effectdata )

                if ply.skull > 0 then
                    ply.skull = ply.skull - dmg
                    ply.brain = ply.brain - (dmg * 0.2)
                else
                    ply.brain = ply.brain - dmg
                end
               
                if ply.brain <= 0 then
                    ply:Kill()
                end
            end
        elseif skull then
            if dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.skull = ply.skull - dmg
            end
        end

        if jaw then
            if ply.Bones['Jaw']>0 and dmginfo:IsDamageType(DMG_BULLET+DMG_CLUB)  then
                ply.Bones['Jaw']=ply.Bones['Jaw']-(dmginfo:GetDamage()/100)
                if ply.Bones['Jaw'] <= 0.6 then
                    if ply.adrenaline < 15 then
                        ply:ChatPrint("Your jaw has been dislocated")
                        if !ply.fake then
                            Faking(ply)
                        end
                    else
                        ply.ane_jdis = true
                    end
                    ply.pain_add = ply.pain_add + 150
                end
                if ply.Bones['Jaw'] <= 0.1 then
                    if ply.adrenaline < 15 then
                        ply:ChatPrint("Your jaw is broken")
                        ply.mutejaw = true
                    else
                        ply.ane_jaw = true
                    end
                end
            end
        end

        if liver then
            if !ply.Hit['liver'] and dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.Hit['liver'] = true
				ply.BleedOuts["stomach"] = ply.BleedOuts["stomach"] + 20
            end
        end
        
        if stomach then
            if !ply.Hit['stomach'] and dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.Hit['stomach'] = true
                ply.BleedOuts["stomach"] = ply.BleedOuts["stomach"] + 10
            end
        end
        
        if intestines then
            if !ply.Hit['intestines'] and dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.Hit['intestines'] = true
                ply.BleedOuts["stomach"] = ply.BleedOuts["stomach"] + 10
            end
        end
        
        if heart then
            if !ply.Hit['heart'] and dmginfo:IsDamageType(DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER) then
                ply.Hit['heart'] = true
				ply.BleedOuts["chest"] = ply.BleedOuts["chest"] + 100
            end
        end

        if IsValid(dmginfo:GetAttacker()) and dmginfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BLAST+DMG_ENERGYBEAM+DMG_NEVERGIB+DMG_ALWAYSGIB+DMG_PLASMA+DMG_AIRBOAT+DMG_SNIPER+DMG_BUCKSHOT) then 
            if neckartery_1 or neckartery_2 then
                if !ply.Hit['neck_artery'] and !dmginfo:IsDamageType(DMG_CLUB) then
                    ply.Hit['neck_artery']=true
                    sound.Play("bleeding/arteryhit.wav",ent:GetPos(),75,100)
                end
            end

            if left_hand_artery and !dmginfo:IsDamageType(DMG_CLUB) then
                if !ply.Hit["lh_artery"] then
                    ply.Hit["lh_artery"] = true
                    sound.Play("bleeding/arteryhit.wav",ent:GetPos(),75,100)
                end
            end

            if right_hand_artery and !dmginfo:IsDamageType(DMG_CLUB) then
                if !ply.Hit["rh_artery"] then
                    ply.Hit["rh_artery"] = true
                    sound.Play("bleeding/arteryhit.wav",ent:GetPos(),75,100)
                end
            end

            if left_leg_artery then
                if !ply.Hit["ll_artery"] then
                    ply.Hit["ll_artery"] = true
                    sound.Play("bleeding/arteryhit.wav",ent:GetPos(),75,100)
                end
            end

            if right_leg_artery then
                if !ply.Hit["rl_artery"] then
                    ply.Hit["rl_artery"] = true
                    sound.Play("bleeding/arteryhit.wav",ent:GetPos(),75,100)
                end
            end
        end

        if spine and !ply.Hit['spine'] and dmginfo:IsDamageType(DMG_BULLET+DMG_CRUSH) then
            ply.Hit['spine']=true
            timer.Simple(0.01,function()
                if !ply.fake then
                    Faking(ply)
                end
            end)
            ply:ChatPrint("Your spine is broken")
            ply.pain_add = ply.pain_add + 300
            ent:EmitSound("neck_snap_01.wav",70,125,0.7,CHAN_ITEM)
        end
    end
end)

hook.Add("HOOK_UNION_Damage","BurnDamage",function(ply,hitgroup,dmginfo) 
    if dmginfo:IsDamageType( DMG_BURN ) then
        dmginfo:ScaleDamage( 5 )
        if fs then
            ply.temp = "Hot"
            if not timer.Exists("nohot"..ply:EntIndex()) then
                timer.Create("nohot"..ply:EntIndex(), 15, 1, function() 
                    if not ply:IsOnFire() then
                        ply.temp = "Warm"
                    end
                end)
            end
        end
    end
end)

-------------------------------------------------------------------------------

hook.Add("ScalePlayerDamage","FallPain", function(ply,hit,dmg)
    ply.lasthitgroup = hit
    if hit == HITGROUP_HEAD then
        if ply:GetNWString("Helmet", "") == "ACH" then
            dmg:ScaleDamage(2)
        else
            dmg:ScaleDamage(5)
        end
        if !ply.fake then
            Faking(ply)
        end
    end
    if hit == HITGROUP_LEFTLEG or hit == HITGROUP_RIGHTLEG then
        if ply.bullet_force > 20 or ply.pain > 100 then
            if !ply.fake then
                Faking(ply)
            end
        end
    end
    if hit == HITGROUP_STOMACH or hit == HITGROUP_CHEST then
        if ply.bullet_force > 14 or ply.pain > 120 then
            if !ply.fake then
                Faking(ply)
            end
        end
    end
end)

local hook_run = hook.Run

timer.Create("MinusOrganismInt",1.4,0,function()
    for _, ply in player.Iterator() do
        hook_run("OrganismVars", ply)
    end
end)

timer.Create("PlusStamina",0.9,0,function()
    for _, ply in player.Iterator() do
        hook_run("StaminaVars", ply)
    end
end)

timer.Create("WorkKislorod",2,0,function()
    for _, ply in player.Iterator() do
        hook_run("O2Vars", ply)
    end
end)

hook.Add("OrganismVars", "MinusOrganismInt", function(ply)
    if ply.pain < 0 then ply.pain = 0 end
	if ply.adrenalineinjector < 0 then ply.adrenalineinjector = 0 end

	if ply.adrenalineinjector > 0 then
		ply.adrenaline_unone = ply.adrenaline_unone + 2
		ply.adrenalineinjector = ply.adrenalineinjector - 1.5
	end

    if ply.pain > 0 then
        if ply.bullet_force / 2 > 0 then
            ply.pain = ply.pain - ply.bullet_force / 2
        else
            ply.pain = ply.pain - math.random(1, 15)
        end
    end
    if ply.bullet_force > 0 then
        ply.bullet_force = ply.bullet_force - 3
    end
end)

hook.Add("StaminaVars", "PlusStamina", function(ply)
    if ply.stamina['leg'] > 50 then ply.stamina['leg'] = 50 end
    if ply:GetNWFloat("Stamina_Arm", 50) > 50 then ply:SetNWFloat("Stamina_Arm", 50) end

    if ply.stamina['leg'] < 50 then
        ply.stamina['leg'] = ply.stamina['leg'] + 1.3
    end
    if ply:GetNWFloat("Stamina_Arm", 50) < 50 then
        ply:SetNWFloat("Stamina_Arm", ply:GetNWInt("Stamina_Arm") + 1.1)
    end
end)

hook.Add("O2Vars", "O2_Work", function(ply)
    if ply.o2 < 0 then ply.o2 = 0 end
    if ply:GetNWBool("Breath", true) and ply:WaterLevel() >= 3 then
        ply.o2 = ply.o2 - math.Rand(0.2, 0.5)
        ply:EmitSound("player/pl_drown" .. math.random(1, 3) .. ".wav", 50,100,1,CHAN_AUTO)
        ply:ViewPunch(Angle(-math.random(1, 3),math.random(0.4, 2),math.random(0.6, 2)))
    end
end)