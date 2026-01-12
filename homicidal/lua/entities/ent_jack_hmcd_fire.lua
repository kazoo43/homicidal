AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Fire"
ENT.AddRadius = 1500
-- ENT.Fires definition removed to prevent memory leak
ENT.SpawnTime = 0

if SERVER then
	local vector_up = Vector(0, 0, 1)
	local spreadDirs = {Vector(150, 0, 0), Vector(-150, 0, 0), Vector(0, 150, 0), Vector(0, -150, 0), Vector(0, 0, 1), Vector(0, 0, -1)}

	function ENT:Initialize()
		self.Entity:SetMoveType(MOVETYPE_NONE)
		self.Entity:DrawShadow(false)
		self.Entity:SetNoDraw(true)
		self.Entity:SetCollisionBounds(Vector(-20, -20, -10), Vector(20, 20, 10))
		self.Entity:PhysicsInitBox(Vector(-20, -20, -10), Vector(20, 20, 10))
		local phys = self.Entity:GetPhysicsObject()

		if phys:IsValid() then
			phys:EnableCollisions(false)
		end

		self.Entity:SetNotSolid(true)

		if not self.Radius then
			self.Radius = 50
		end

		self.NextSound = 0
		self.IgniteTimes = {}
		self.NextSpreadCheck = CurTime() + 40

		if not self.Power then
			self.Power = 3
		end

		local trdown = util.QuickTrace(self:GetPos(), self:GetAngles():Up() * -30, {self})

		self.FloorMat = trdown.MatType
		self.AddRadius = 1

		if not self.SpawnTime then
			self.SpawnTime = CurTime()
		end
	end

	function ENT:ModifiedIgnite(ent, ignitetime, isRDM)
		local curIgniteTime = 0

		if IsValid(ent.CurrentFire) then
			curIgniteTime = ent.CurrentFire:GetInternalVariable("lifetime") - CurTime()
		end

		ent:Ignite(curIgniteTime + ignitetime)

		if isRDM then
			local owner = ent

			if owner:IsPlayer() and IsValid(self.Initiator) then
				owner.LastIgniter = self.Initiator
			end
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		return false
	end

	local BurnMuls = {
		[MAT_ANTLION] = 1.3,
		[MAT_BLOODYFLESH] = 0.8,
		[MAT_DIRT] = 0.5,
		[MAT_EGGSHELL] = 0.4,
		[MAT_FLESH] = 1,
		[MAT_ALIENFLESH] = 1.5,
		[MAT_PLASTIC] = 1.2,
		[MAT_FOLIAGE] = 2.5,
		[MAT_COMPUTER] = 1,
		[MAT_GRASS] = 1.2,
		[MAT_WOOD] = 2
	}

	local dirs = {Vector(10, 0, -1), Vector(-10, 0, -1), Vector(0, 10, -1), Vector(0, -10, -1), Vector(10, 10, -1), Vector(10, -10, -1), Vector(-10, 10, -1), Vector(-10, -10, -1)}

	function ENT:Think()
		local heightmul = BurnMuls[self.FloorMat] or 0
		local SelfPos = self:GetPos() + Vector(0, 0, math.random(0, 100)) + VectorRand() * math.random(0, 100)
		local Foof = EffectData()
		Foof:SetOrigin(SelfPos)
		Foof:SetRadius(self.Radius)
		Foof:SetScale(heightmul)
		util.Effect("eff_jack_hmcd_fire", Foof, true, true)

		for key, obj in pairs(ents.FindInSphere(SelfPos, self.Radius)) do
			if (obj ~= self) and obj.GetPhysicsObject and IsValid(obj:GetPhysicsObject()) then
				local Dist = (obj:GetPos() - self:GetPos()):Length()
				local Frac = math.Clamp(1 - (Dist / self.Radius), 0.1, 1)

				local visible = not util.QuickTrace(self:GetPos(), obj:WorldSpaceCenter() - self:GetPos(), {obj, self}).Hit

				if visible then
					if HMCD_IsDoor(obj) then
						local col = obj:GetColor()

						if col.r <= 25 then
							HMCD_BlastThatDoor(obj, (obj:GetPos() - self:GetPos()):GetNormalized() * 100)
						else
							col.r = col.r - 1
							col.g = col.g - 1
							col.b = col.b - 1
						end

						obj:SetColor(col)
					end

					local Dmg = DamageInfo()
					local attacker = self.Initiator

					if not IsValid(attacker) then
						attacker = game.GetWorld()
					end

					if CurTime() - self.SpawnTime >= 10 then
						Dmg:SetAttacker(game.GetWorld())

						if IsValid(attacker) then
							local owner = obj

							if owner:IsPlayer() then
								owner.LastAttacker = attacker
								owner.LastAttackerName = attacker.BystanderName
							end
						end
					else
						Dmg:SetAttacker(attacker)
					end

					Dmg:SetInflictor(self)
					Dmg:SetDamageType(DMG_BURN)
					Dmg:SetDamagePosition(SelfPos)
					Dmg:SetDamageForce(vector_origin)
					Dmg:SetDamage(Frac * 3)
					obj:TakeDamageInfo(Dmg)

					if not (obj:WaterLevel() > 0 or (obj:IsPlayer() and (not obj:Alive() or obj.fake)) or obj:GetClass() == "ent_jack_hmcd_fire") then
						self:ModifiedIgnite(obj, Frac * 15, CurTime() - self.SpawnTime < 10)
					end
				end
			end
		end

		if self.NextSpreadCheck < CurTime() then
			self.NextSpreadCheck = CurTime() + 40

			for i, dir in pairs(dirs) do
				local tr = util.TraceLine({
					start = self:GetPos() + Vector(0, 0, 40),
					endpos = self:GetPos() + Vector(0, 0, 40) + dir * 40,
					mask = MASK_SOLID_BRUSHONLY
				})

				tr = util.QuickTrace(tr.HitPos, -vector_up * 40)
				local farAway = tr.Hit

				if farAway then
					-- Optimized spatial check instead of global list scan
					local nearbyFires = ents.FindInSphere(tr.HitPos, 200)
					for _, ent in ipairs(nearbyFires) do
						if ent:GetClass() == "ent_jack_hmcd_fire" then
							farAway = false
							break
						end
					end
				end

				if BurnMuls[tr.MatType] and farAway then
					local Fire = ents.Create("ent_jack_hmcd_fire")
					Fire.HmcdSpawned = self.HmcdSpawned
					Fire.Initiator = self.Initiator
					Fire.Power = self.Power
					Fire:SetPos(tr.HitPos)
					Fire.SpawnTime = CurTime() - 10
					Fire:Spawn()
					Fire:Activate()
				end
			end
		end

		self.Radius = self.Radius + self.AddRadius

		if self.Radius <= 70 and self.AddRadius < 0 then
			self:Remove()
		end

		if self.Radius >= 500 then
			self.AddRadius = -1
		end

		self:NextThink(CurTime() + .2)

		return true
	end
end