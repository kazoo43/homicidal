
FuelLeakSystem = FuelLeakSystem or {}
FuelLeakSystem.ActiveTanks = FuelLeakSystem.ActiveTanks or {}
FuelLeakSystem.FuelPaths = FuelLeakSystem.FuelPaths or {}

-- Configuration for valid tank models and their leak offsets
local TankConfig = {
	["models/props_c17/oildrum001_explosive.mdl"] = { offset = Vector(10, 0, 0) },
	["models/props_junk/gascan001a.mdl"] = { offset = nil },
	["models/props_junk/metalgascan.mdl"] = { offset = nil }
}

PrecacheParticleSystem("env_fire_medium")

if SERVER then
	util.AddNetworkString("fls_leak_fx")
	util.AddNetworkString("fls_path_sync")

	-- Helper to determine if we should use vFire
	local function UsingVFire()
		return GetConVar("hmcd_replace_fire_with_vfire"):GetBool() and vFireInstalled
	end

	local function RegisterTank(ent)
		if not IsValid(ent) then return end
		if FuelLeakSystem.ActiveTanks[ent:EntIndex()] then return end -- Already registered

		local mdl = ent:GetModel()
		local cfg = TankConfig[mdl]
		
		if cfg then
			local maxs, mins = ent:OBBMaxs(), ent:OBBMins()
			local startPos
			
			if cfg.offset then
				startPos = maxs + mins + cfg.offset
			end

			FuelLeakSystem.ActiveTanks[ent:EntIndex()] = {
				Ent = ent,
				-- Randomize fuel level if we have a hole, otherwise use 80% height
				Level = startPos and math.random(1, startPos.z) or (maxs.z * 0.8),
				LeakPoints = {
					[1] = startPos and {startPos, CurTime()} or nil
				}
			}
		end
	end

	hook.Add("OnEntityCreated", "FLS_EntityInit", function(ent)
		-- Delay slightly to ensure entity is valid
		timer.Simple(0, function() RegisterTank(ent) end)
	end)

	-- Handle map-spawned entities on startup
	hook.Add("InitPostEntity", "FLS_MapInit", function()
		timer.Simple(1, function()
			for mdl, _ in pairs(TankConfig) do
				for _, ent in ipairs(ents.FindByModel(mdl)) do
					RegisterTank(ent)
				end
			end
		end)
	end)

	-- Handle reloads
	timer.Simple(0, function()
		for mdl, _ in pairs(TankConfig) do
			for _, ent in ipairs(ents.FindByModel(mdl)) do
				RegisterTank(ent)
			end
		end
	end)

	function FuelLeakSystem:Detonate(ent)
		if not IsValid(ent) or ent.IsExploding then return end
		ent.IsExploding = true

		-- Stop tracking this tank
		local idx = ent:EntIndex()
		if self.ActiveTanks[idx] then
			self.ActiveTanks[idx] = nil
		end

		local centerPos = ent:LocalToWorld(ent:OBBCenter()) + Vector(0, 0, 5)
		local attacker = ent.LastAttacker or ent

		-- Visuals
		ParticleEffect("pcf_jack_incendiary_air_sm2", centerPos, VectorRand():Angle())
		
		local flashData = EffectData()
		flashData:SetOrigin(centerPos)
		flashData:SetScale(2)
		util.Effect("eff_jack_hmcd_dlight", flashData, true, true)
		
		util.ScreenShake(centerPos, 20, 20, 1, 1200)

		-- Damage and physics push
		util.BlastDamage(ent, attacker, centerPos, 800, 120)

		local targets = ents.FindInSphere(centerPos, 1200)
		for _, target in ipairs(targets) do
			if IsValid(target) then
				local phys = target:GetPhysicsObject()
				if IsValid(phys) then
					local vecDir = (target:GetPos() - centerPos):GetNormalized()
					local dist = target:GetPos():Distance(centerPos)
					local pushForce = (1200 - dist) * 15
					phys:ApplyForceCenter(vecDir * pushForce)
				end
			end
		end

		-- Scorch marks
		timer.Simple(0.01, function()
			for i = 1, 10 do
				local trace = util.QuickTrace(centerPos, VectorRand() * math.random(10, 150), {ent})
				if trace.Hit then
					util.Decal("Scorch", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal)
				end
			end
		end)

		-- Sound effects
		timer.Simple(0.02, function()
			sound.Play("ied/ied_detonate_0" .. math.random(1, 3) .. ".wav", centerPos, 100, 100)
			sound.Play("ied/ied_detonate_dist_0" .. math.random(1, 3) .. ".wav", centerPos, 140, 100)
		end)

		-- Fire spawning and cleanup
		timer.Simple(0.03, function()
			if IsValid(ent) then ent:Remove() end

			if UsingVFire() then
				for i = 1, 5 do
					CreateVFireBall(30, 15, centerPos + VectorRand() * 50, VectorRand() * 150, attacker)
				end
				
				local floorTrace = util.QuickTrace(centerPos, Vector(0,0,-500), {ent})
				if floorTrace.Hit then
					CreateVFire(game.GetWorld(), floorTrace.HitPos, floorTrace.HitNormal, 200, attacker)
				end
			else
				for i = 1, 5 do
					local fire = ents.Create("ent_jack_hmcd_fire")
					fire.HmcdSpawned = true
					fire.Initiator = attacker
					fire.Power = 3
					fire:SetPos(centerPos + VectorRand() * 50)
					fire:Spawn()
					fire:Activate()
				end
			end
		end)
	end

	function FuelLeakSystem:IgniteNode(idx)
		local node = self.FuelPaths[idx]
		if node and not node[2] then
			node[2] = CurTime()
		end
	end

	function FuelLeakSystem:CheckIgnition(pos, range)
		range = range or 50
		local rangeSq = range * range
		
		for i, node in ipairs(self.FuelPaths) do
			if not node[2] and node[1]:DistToSqr(pos) < rangeSq then
				self:IgniteNode(i)
				return true
			end
		end
		return false
	end

	-- Main logic loop
	local nextTick = CurTime()
	hook.Add("Think", "FLS_MainLoop", function()
		if CurTime() < nextTick then return end
		nextTick = CurTime() + 0.1

		for idx, data in pairs(FuelLeakSystem.ActiveTanks) do
			local ent = data.Ent
			
			if not IsValid(ent) then
				FuelLeakSystem.ActiveTanks[idx] = nil
				continue
			end

			-- Explode if burning
			if ent:IsOnFire() or (ent.fires and table.Count(ent.fires) > 0) then
				FuelLeakSystem:Detonate(ent)
				continue
			end

			local pos = ent:GetPos()
			local center = ent:OBBCenter()
			center:Rotate(ent:GetAngles())

			-- Calculate liquid height based on orientation
			local upDot = math.max(math.abs(vector_up:Dot(ent:GetUp())), 0.99)
			local liquidHeight = (data.Level / upDot) - ent:OBBCenter().z
			local liquidPos = center + Vector(0, 0, liquidHeight)
			liquidPos:Add(ent:GetVelocity() / 8)

			for _, pointData in pairs(data.LeakPoints) do
				local leakPosLocal = Vector(0,0,0)
				leakPosLocal:Set(pointData[1])
				leakPosLocal:Rotate(ent:GetAngles())

				local leakZ = math.Round(leakPosLocal.z, 1)
				local liquidZ = math.Round(liquidPos.z, 1)
				
				-- World position of the leak point
				local worldLeakPos = pos + leakPosLocal

				-- Check for matches near the leak point
				-- Only checks the first leak point (or any) as per user request "the one thats on top" usually refers to the main nozzle/hole
				-- But checking all is safer and covers the "top" one naturally.
				local nearbyMatches = ents.FindInSphere(worldLeakPos, 15) -- Small radius check
				for _, match in ipairs(nearbyMatches) do
					if match:GetClass() == "ent_jack_hmcd_match" and match:GetNWBool("Lit") then
						FuelLeakSystem:Detonate(ent)
						break
					end
				end
				if ent.IsExploding then break end -- Exit loop if detonated

				if leakZ < liquidZ then
					-- It's leaking
					data.Level = math.max(data.Level - 0.1, 0)
					data.IsLeaking = true
					
					if not data.LoopSnd then
						data.LoopSnd = CreateSound(ent, "ambient/water/leak_1.wav")
					end
					
					-- Pitch shift based on emptiness (100 to 120)
					-- Level starts at ~50 (max) goes to 0
					-- We want pitch 100 at max level, 120 at empty
					-- Assuming max level is around 40-50 based on logic (startPos.z or maxs.z * 0.8)
					local maxLvl = 50 -- Approximation
					local pitch = 120 - ((data.Level / maxLvl) * 20)
					pitch = math.Clamp(pitch, 100, 120)
					
					if data.LoopSnd:IsPlaying() then
						data.LoopSnd:ChangePitch(pitch, 0.1)
					else
						data.LoopSnd:PlayEx(1, pitch)
					end

					-- Raycast for liquid hitting the ground
					local tr = util.TraceLine({
						start = worldLeakPos,
						endpos = worldLeakPos - (vector_up * 256),
						filter = ent
					})

					if tr.Hit and tr.Entity == Entity(0) then
						if (data.NextPuddleTime or 0) < CurTime() then
							data.NextPuddleTime = CurTime() + 0.2
							table.insert(FuelLeakSystem.FuelPaths, {tr.HitPos, false, CurTime()})
						end
					elseif IsValid(tr.Entity) then
						tr.Entity.shouldburn = (tr.Entity.shouldburn or 0) + 1
					end

					-- Send visual effects
					net.Start("fls_leak_fx")
					net.WriteVector(worldLeakPos)
					
					local sprayDir = (worldLeakPos - (center + ent:GetPos())):GetNormalized()
					local sprayVel = ent:GetVelocity() + VectorRand(-15, 15) + (sprayDir * 60)
					
					net.WriteVector(sprayVel)
					net.WriteEntity(ent)
					net.Broadcast()
				else
					-- Not leaking
					if data.LoopSnd then data.LoopSnd:Stop() end
					data.IsLeaking = false
				end
				
				-- Increment leak point timer
				if pointData[2] < CurTime() then 
					pointData[2] = pointData[2] + 0.1 
				end
			end

			-- Empty tank cleanup
			if data.Level <= 0.5 then
				if data.LoopSnd then
					data.LoopSnd:Stop()
					data.LoopSnd = nil
				end
				FuelLeakSystem.ActiveTanks[idx] = nil
			end
		end
	end)

	-- Path update loop
	local pathTick = CurTime()
	hook.Add("Think", "FLS_PathLogic", function()
		if CurTime() < pathTick then return end
		pathTick = CurTime() + 0.2

		local hasUpdates = false
		local cleanPath = {}
		local counter = 0
		
		-- Gather all fire entities
		local fireEnts = ents.FindByClass("ent_jack_hmcd_fire")
		table.Add(fireEnts, ents.FindByClass("env_fire"))
		
		local vFireMode = UsingVFire()
		if vFireMode then
			table.Add(fireEnts, ents.FindByClass("vfire"))
		end
		
		local firesThisTick = 0
		local lastFireLoc = nil
		
		for i, node in ipairs(FuelLeakSystem.FuelPaths) do
			local loc = node[1]
			local igniteTime = node[2]
			local createTime = node[3] or 0
			
			-- Clean up old burnt nodes or old unlit nodes
			if isnumber(igniteTime) and (igniteTime + 8) < CurTime() then
				hasUpdates = true
				continue
			end
			-- INCREASED DURATION TO 100 SECONDS
			if not igniteTime and (createTime + 100) < CurTime() then
				hasUpdates = true
				continue
			end
			
			counter = counter + 1
			cleanPath[counter] = node
			
			if isnumber(igniteTime) then
				-- Spread fire to neighbors
				local prevNode = FuelLeakSystem.FuelPaths[i-1]
				local nextNode = FuelLeakSystem.FuelPaths[i+1]
				
				if prevNode and not prevNode[2] and (prevNode[1]:DistToSqr(loc) < 2500) then
					prevNode[2] = CurTime()
					hasUpdates = true
				end
				if nextNode and not nextNode[2] and (nextNode[1]:DistToSqr(loc) < 2500) then
					nextNode[2] = CurTime()
					hasUpdates = true
				end

				-- Spawn actual fire entities
				if not node.hasSpawnedFire then
					local canSpawn = true
					
					-- Don't spawn too close to last one
					if lastFireLoc and loc:DistToSqr(lastFireLoc) < 3600 then
						canSpawn = false
						node.hasSpawnedFire = true
					end
					
					if canSpawn then
						if firesThisTick >= 5 then
							canSpawn = false
						else
							-- Check for existing fires nearby
							local nearby = ents.FindInSphere(loc, 60)
							for _, f in ipairs(nearby) do
								local cls = f:GetClass()
								if cls == "ent_jack_hmcd_fire" or (vFireMode and cls == "vfire") then
									canSpawn = false
									node.hasSpawnedFire = true
									lastFireLoc = loc
									break
								end
							end
						end
					end
					
					if canSpawn then
						if vFireMode then
							CreateVFire(game.GetWorld(), loc, Vector(0,0,1), 15)
						else
							local fire = ents.Create("ent_jack_hmcd_fire")
							fire.HmcdSpawned = true
							fire.Initiator = game.GetWorld()
							fire.Power = 3
							fire:SetPos(loc)
							fire:Spawn()
							fire:Activate()
						end
						
						firesThisTick = firesThisTick + 1
						node.hasSpawnedFire = true
						lastFireLoc = loc
					end
				else
					lastFireLoc = loc
				end
			else
				-- Check if this node should ignite from nearby fires
				for _, fire in ipairs(fireEnts) do
					if IsValid(fire) and fire:GetPos():DistToSqr(loc) < 2500 then
						node[2] = CurTime()
						hasUpdates = true
						break
					end
				end
			end
		end
		
		if hasUpdates then
			FuelLeakSystem.FuelPaths = cleanPath
			net.Start("fls_path_sync")
			net.WriteTable(FuelLeakSystem.FuelPaths)
			net.Broadcast()
		end
	end)

	hook.Add("EntityTakeDamage", "FLS_DamageHandler", function(ent, dmg)
		local idx = ent:EntIndex()
		local data = FuelLeakSystem.ActiveTanks[idx]
		
		if data then
			local dmgType = dmg:GetDamageType()
			local isBullet = dmg:IsDamageType(DMG_BULLET) or dmg:IsDamageType(DMG_BUCKSHOT)
			local isSlash = dmg:IsDamageType(DMG_SLASH) and dmg:GetDamage() >= 25

			if isBullet or isSlash then
				local hitPos = dmg:GetDamagePosition()
				
				-- Push the tank
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ApplyForceOffset(dmg:GetDamageForce(), hitPos)
				end

				-- Add a new leak point
				local localHitPos = ent:WorldToLocal(hitPos)
				table.insert(data.LeakPoints, {localHitPos, CurTime()})
				
				dmg:SetDamage(0)
				return true
			elseif dmg:IsDamageType(DMG_BURN) or dmg:IsDamageType(DMG_BLAST) or dmg:IsDamageType(DMG_SLOWBURN) or ent:IsOnFire() then
				FuelLeakSystem:Detonate(ent)
				dmg:SetDamage(0)
				return true
			end

			-- Explode if health drops to zero
			if (ent:Health() - dmg:GetDamage()) <= 0 then
				FuelLeakSystem:Detonate(ent)
				dmg:SetDamage(0)
				return true
			end
		end
	end)

	hook.Add("PostCleanupMap", "FLS_Reset", function()
		FuelLeakSystem.ActiveTanks = {}
		FuelLeakSystem.FuelPaths = {}
	end)

else
	-- Client Side
	FuelLeakSystem.Emitters = FuelLeakSystem.Emitters or {}
	local mainEmitter = ParticleEmitter(Vector(0, 0, 0))

	net.Receive("fls_leak_fx", function()
		local pos = net.ReadVector()
		local vel = net.ReadVector()
		local ent = net.ReadEntity() -- unused in original particle logic but sent
		
		if not IsValid(mainEmitter) then mainEmitter = ParticleEmitter(pos) end
		
		for i = 1, 2 do
			local p = mainEmitter:Add("effects/blood_core", pos)
			if p then
				p:SetDieTime(2)
				p:SetStartAlpha(150)
				p:SetEndAlpha(0)
				p:SetStartSize(3)
				p:SetEndSize(0)
				p:SetColor(200, 180, 50) -- Fuel color
				p:SetGravity(Vector(0, 0, -600))
				p:SetVelocity(vel + VectorRand() * 5)
				p:SetCollide(true)
				p:SetBounce(0)
				p:SetLighting(true)
				p:SetCollideCallback(function(part, hitPos, hitNorm)
					util.Decal("BeerSplash", hitPos + hitNorm, hitPos - hitNorm)
					part:SetDieTime(0)
				end)
			end
		end
	end)

	net.Receive("fls_path_sync", function()
		FuelLeakSystem.FuelPaths = net.ReadTable()
	end)
end
