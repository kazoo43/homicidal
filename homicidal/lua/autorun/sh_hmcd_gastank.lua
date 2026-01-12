HMCD_GasTank = HMCD_GasTank or {}
HMCD_GasTank.ActiveTanks = HMCD_GasTank.ActiveTanks or {}

-- Configuration for valid tank models
local TankConfig = {
	["models/props_c17/canister01a.mdl"] = true,
	["models/props_c17/canister02a.mdl"] = true,
	["models/props_junk/PropaneCanister001a.mdl"] = true,
	["models/props_c17/canister_propane01a.mdl"] = true,
	["models/props_junk/propane_tank001a.mdl"] = true,
}

PrecacheParticleSystem("fire_jet_01")
PrecacheParticleSystem("pcf_jack_incendiary_air_sm2")

if SERVER then
	util.AddNetworkString("hmcd_gastank_leak")
	util.AddNetworkString("hmcd_gastank_stop")

	-- Helper for vFire
	local function UsingVFire()
		return GetConVar("hmcd_replace_fire_with_vfire"):GetBool() and vFireInstalled
	end

	local function RegisterTank(ent)
		if not IsValid(ent) then return end
		if HMCD_GasTank.ActiveTanks[ent:EntIndex()] then return end

		if TankConfig[ent:GetModel()] then
			HMCD_GasTank.ActiveTanks[ent:EntIndex()] = {
				Ent = ent,
				IsActive = false
			}
		end
	end

	-- Spawn Hooks
	hook.Add("OnEntityCreated", "HMCD_GasTank_Spawn", function(ent)
		timer.Simple(0, function() RegisterTank(ent) end)
	end)

	hook.Add("InitPostEntity", "HMCD_GasTank_MapInit", function()
		timer.Simple(1, function()
			for mdl, _ in pairs(TankConfig) do
				for _, ent in ipairs(ents.FindByModel(mdl)) do
					RegisterTank(ent)
				end
			end
		end)
	end)
	
	-- Reload support
	timer.Simple(0, function()
		for mdl, _ in pairs(TankConfig) do
			for _, ent in ipairs(ents.FindByModel(mdl)) do
				RegisterTank(ent)
			end
		end
	end)

	function HMCD_GasTank:Detonate(ent)
		if not IsValid(ent) or ent.IsExploding then return end
		ent.IsExploding = true

		-- Cleanup tracking
		local idx = ent:EntIndex()
		if self.ActiveTanks[idx] then
			self.ActiveTanks[idx] = nil
		end
		
		-- Stop client effects
		net.Start("hmcd_gastank_stop")
		net.WriteUInt(idx, 16)
		net.Broadcast()

		local pos = ent:LocalToWorld(ent:OBBCenter())
		local attacker = ent.LastAttacker or ent
		
		ParticleEffect("pcf_jack_incendiary_air_sm2", pos, VectorRand():Angle())
		
		local flash = EffectData()
		flash:SetOrigin(pos)
		flash:SetScale(2)
		util.Effect("eff_jack_hmcd_dlight", flash, true, true)
		util.ScreenShake(pos, 20, 20, 1, 1200)

		util.BlastDamage(ent, attacker, pos, 600, 100)

		-- Push nearby objects
		for k, v in pairs(ents.FindInSphere(pos, 800)) do
			if IsValid(v) then
				local phys = v:GetPhysicsObject()
				if IsValid(phys) then
					local dir = (v:GetPos() - pos):GetNormalized()
					local dist = v:GetPos():Distance(pos)
					local force = (800 - dist) * 10
					phys:ApplyForceCenter(dir * force)
				end
			end
		end

		-- Decals
		timer.Simple(0.01, function()
			for i = 0, 5 do
				local tr = util.QuickTrace(pos, VectorRand() * math.random(10, 100), {ent})
				if tr.Hit then
					util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
				end
			end
		end)

		-- Sound
		timer.Simple(0.02, function()
			sound.Play("ied/ied_detonate_0" .. math.random(1, 3) .. ".wav", pos, 100, 100)
			sound.Play("ied/ied_detonate_dist_0" .. math.random(1, 3) .. ".wav", pos, 140, 100)
		end)

		-- Remove and Fire
		timer.Simple(0.03, function()
			if IsValid(ent) then ent:Remove() end

			if UsingVFire() then
				for i = 1, 3 do
					CreateVFireBall(20, 10, pos + VectorRand() * 30, VectorRand() * 100, attacker)
				end
			else
				for i = 1, 3 do
					local fire = ents.Create("ent_jack_hmcd_fire")
					fire.HmcdSpawned = true
					fire.Initiator = attacker
					fire.Power = 3
					fire:SetPos(pos + VectorRand() * 30)
					fire:Spawn()
					fire:Activate()
				end
			end
		end)
	end

	hook.Add("EntityTakeDamage", "HMCD_GasTank_Damage", function(ent, dmgInfo)
		local idx = ent:EntIndex()
		local data = HMCD_GasTank.ActiveTanks[idx]
		
		if data then
			-- Immediate explosion conditions
			if dmgInfo:IsDamageType(DMG_BURN) or ent:IsOnFire() or (ent.fires and table.Count(ent.fires) > 0) then
				HMCD_GasTank:Detonate(ent)
				dmgInfo:SetDamage(0)
				return true
			end
			
			-- Activation conditions (Bullet/Buckshot/Blast)
			if (dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT) or dmgInfo:IsDamageType(DMG_BLAST)) and not data.IsActive then
				data.IsActive = true
				ent.LastAttacker = dmgInfo:GetAttacker()
				
				local dmgPos = dmgInfo:GetDamagePosition()
				
				-- For blast damage, the position is the explosion origin. We want the impact point on the tank.
				if dmgInfo:IsDamageType(DMG_BLAST) then
					dmgPos = ent:NearestPoint(dmgPos)
				end
				
				data.LocalHolePos = ent:WorldToLocal(dmgPos)
				data.ActiveTime = CurTime()
				data.NextBurnTime = 0
				
				-- Notify clients to start effects
				net.Start("hmcd_gastank_leak")
				net.WriteEntity(ent)
				net.WriteVector(data.LocalHolePos)
				net.Broadcast()

				-- Wake physics
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:Wake()
					phys:EnableMotion(true)
				end
				
				dmgInfo:SetDamage(0)
				return true
			end
			
			-- Health check
			if (ent:Health() - dmgInfo:GetDamage()) <= 0 then
				HMCD_GasTank:Detonate(ent)
				dmgInfo:SetDamage(0)
				return true
			end
		end
	end)

	-- Main Logic Loop
	local nextTick = CurTime()
	hook.Add("Think", "HMCD_GasTank_MainLoop", function()
		if CurTime() < nextTick then return end
		-- We run this frequently for physics smoothing
		-- But we can throttle logic if needed. 
		-- Since we rely on FrameTime for torque, we should run every tick or close to it.
		-- Original code was every tick.
		
		for i, data in pairs(HMCD_GasTank.ActiveTanks) do
			local ent = data.Ent
			if not IsValid(ent) then
				HMCD_GasTank.ActiveTanks[i] = nil
				continue
			end

			if ent:IsOnFire() or (ent.fires and table.Count(ent.fires) > 0) then
				HMCD_GasTank:Detonate(ent)
				continue
			end

			if data.IsActive then
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					local holePos = ent:LocalToWorld(data.LocalHolePos)
					local center = ent:WorldSpaceCenter()
					
					-- Force direction: From Hole to Center (Reaction force)
					local forceDir = (center - holePos):GetNormalized()
					
					-- Chaos
					forceDir = (forceDir + VectorRand() * 0.2):GetNormalized()
					
					-- Apply Force
					phys:ApplyForceCenter(forceDir * 450)
					
					-- Torque
					phys:AddAngleVelocity(VectorRand() * 10 * FrameTime())

					-- Jet Burn Damage
					if CurTime() > (data.NextBurnTime or 0) then
						data.NextBurnTime = CurTime() + 0.1
						local jetDir = (holePos - center):GetNormalized()
						local burnPos = holePos + jetDir * 50
						
						for k, v in pairs(ents.FindInSphere(burnPos, 100)) do
							if v ~= ent and IsValid(v) then
								if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then
									v:Ignite(1)
								elseif v:GetClass() == "prop_physics" then
									-- Prevent chain reaction: Don't ignite other gas tanks
									if not TankConfig[v:GetModel()] then
										v:Ignite(1)
									end
								end
							end
						end
					end
				end
				
				-- Explode after random time (3-5 seconds)
				if CurTime() - data.ActiveTime > math.Rand(3, 5) then
					HMCD_GasTank:Detonate(ent)
				end
			end
		end
	end)

	hook.Add("PostCleanupMap", "HMCD_GasTank_Reset", function()
		HMCD_GasTank.ActiveTanks = {}
	end)

else
	-- CLIENT SIDE
	HMCD_GasTank.ActiveEffects = HMCD_GasTank.ActiveEffects or {}

	net.Receive("hmcd_gastank_leak", function()
		local ent = net.ReadEntity()
		local localHolePos = net.ReadVector()
		
		if not IsValid(ent) then return end
		
		-- Cleanup old if exists
		local idx = ent:EntIndex()
		if HMCD_GasTank.ActiveEffects[idx] then
			local old = HMCD_GasTank.ActiveEffects[idx]
			if old.Sound then old.Sound:Stop() end
			if IsValid(old.Dummy) then old.Dummy:Remove() end
		end
		
		local sound = CreateSound(ent, "tankfire.mp3")
		sound:SetSoundLevel(70)
		sound:Play()
		
		local dummy = ClientsideModel("models/props_junk/PopCan01a.mdl", RENDERGROUP_NONE)
		dummy:SetPos(ent:LocalToWorld(localHolePos))
		dummy:SetParent(ent)
		dummy:SetRenderMode(RENDERMODE_TRANSCOLOR)
		dummy:SetColor(Color(0,0,0,0))
		
		ParticleEffectAttach("fire_jet_01", PATTACH_ABSORIGIN_FOLLOW, dummy, 0)
		
		HMCD_GasTank.ActiveEffects[idx] = {
			Sound = sound,
			Dummy = dummy,
			Entity = ent
		}
	end)

	net.Receive("hmcd_gastank_stop", function()
		local entIndex = net.ReadUInt(16)
		local data = HMCD_GasTank.ActiveEffects[entIndex]
		if data then
			if data.Sound then data.Sound:Stop() end
			if IsValid(data.Dummy) then data.Dummy:Remove() end
			HMCD_GasTank.ActiveEffects[entIndex] = nil
		end
	end)
	
	hook.Add("Think", "HMCD_GasTank_ClientThink", function()
		for i, data in pairs(HMCD_GasTank.ActiveEffects) do
			if not IsValid(data.Entity) then
				if data.Sound then data.Sound:Stop() end
				if IsValid(data.Dummy) then data.Dummy:Remove() end
				HMCD_GasTank.ActiveEffects[i] = nil
			end
		end
	end)
end
