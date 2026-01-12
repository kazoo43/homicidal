--[[File Path:   gamemodes/homicide/entities/entities/ent_jack_hmcd_assaultrifle.lua

--]]
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_jack_hmcd_wep_base"
ENT.SWEP = "wep_jack_hmcd_assaultrifle"
ENT.ImpactSound = "physics/metal/weapon_impact_soft3.wav"
ENT.Model = "models/btk/w_nam_akm.mdl" -- Use AKM for physics
ENT.VisualModel = "models/weapons/crow/w_huy.mdl" -- Use AR15 for visuals
ENT.VisualModelScale = 1.25
ENT.VisualModelPos = Vector(-1, -2.5, 5)
ENT.VisualModelAng = Angle(0, 0, 0)

if SERVER then
	function ENT:Initialize()
		self.Entity:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(self.CustomCollisionGroup or COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)
		
		-- Use AKM for physics
		-- self:PhysicsInitMultiConvex(util.GetModelMeshes("models/btk/w_nam_akm.mdl"))
		
		-- Removed PhysicsBox and CollisionBounds to match AKM physics exactly
		-- if self.PhysicsBox then
		-- 	self:PhysicsInitBox(self.PhysicsBox[1], self.PhysicsBox[2])
		-- end

		-- if self.CollisionBounds then
		-- 	self:SetCollisionBounds(self.CollisionBounds[1], self.CollisionBounds[2])
		-- end

		-- Don't apply bodygroups to the physics model (AKM), as they belong to the AR15
		-- if self.Bodygroups then
		-- 	for i, val in pairs(self.Bodygroups) do
		-- 		self:SetBodygroup(i, val)
		-- 	end
		-- end

		self:DrawShadow(true)
		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:SetMass(self.Mass or 20)
			phys:Wake()
			phys:EnableMotion(true)
		end
	end
else -- CLIENT
	function ENT:Draw()
		if not IsValid(self.VisualModelEnt) then
			self.VisualModelEnt = ClientsideModel(self.VisualModel)
			self.VisualModelEnt:SetNoDraw(true)
		end
		
		if IsValid(self.VisualModelEnt) then
			local pos, ang = self:GetPos(), self:GetAngles()
			
			-- Apply custom offset
			if self.VisualModelPos then
				pos = pos + ang:Forward() * self.VisualModelPos.x + ang:Right() * self.VisualModelPos.y + ang:Up() * self.VisualModelPos.z
			end
			
			if self.VisualModelAng then
				ang:RotateAroundAxis(ang:Up(), self.VisualModelAng.y)
				ang:RotateAroundAxis(ang:Right(), self.VisualModelAng.p)
				ang:RotateAroundAxis(ang:Forward(), self.VisualModelAng.r)
			end
			
			self.VisualModelEnt:SetPos(pos)
			self.VisualModelEnt:SetAngles(ang)
			
			-- Apply scale
			if self.VisualModelScale then
				self.VisualModelEnt:SetModelScale(self.VisualModelScale, 0)
			end
			
			if self.Bodygroups then
				for i, val in pairs(self.Bodygroups) do
					self.VisualModelEnt:SetBodygroup(i, val)
				end
			end
			
			self.VisualModelEnt:DrawModel()

			-- Draw Attachments on the Visual Model
			if self.Attachments then
				if not self.DrawnAttachments then self.DrawnAttachments = {} end
				for attachment, info in pairs(self.Attachments) do
					if self:GetNWBool(attachment) then
						if not self.DrawnAttachments[attachment] then
							self.DrawnAttachments[attachment] = ClientsideModel(info.model)
							self.DrawnAttachments[attachment]:SetPos(self.VisualModelEnt:GetPos())
							self.DrawnAttachments[attachment]:SetParent(self.VisualModelEnt)
							self.DrawnAttachments[attachment]:SetNoDraw(true)

							if info.scale then
								self.DrawnAttachments[attachment]:SetModelScale(info.scale, 0)
							end

							if info.material then
								self.DrawnAttachments[attachment]:SetMaterial(info.material)
							end
						else
							local boneID = self.VisualModelEnt:LookupBone(info.bone or "")
							local pos, ang
							
							if boneID then
								pos, ang = self.VisualModelEnt:GetBonePosition(boneID)
							else
								pos, ang = self.VisualModelEnt:GetPos(), self.VisualModelEnt:GetAngles()
							end

							local attPos = pos + ang:Right() * info.pos.right + ang:Forward() * info.pos.forward + ang:Up() * info.pos.up
							
							if info.ang then
								local angList = {
									["forward"] = ang:Forward(),
									["right"] = ang:Right(),
									["up"] = ang:Up()
								}

								for i, rot in pairs(info.ang) do
									ang:RotateAroundAxis(angList[i], rot)

									angList = {
										["forward"] = ang:Forward(),
										["right"] = ang:Right(),
										["up"] = ang:Up()
									}
								end
							end

							self.DrawnAttachments[attachment]:SetRenderOrigin(attPos)
							self.DrawnAttachments[attachment]:SetRenderAngles(ang)
							self.DrawnAttachments[attachment]:DrawModel()
						end
					else
						if self.DrawnAttachments[attachment] then
							self.DrawnAttachments[attachment]:Remove()
							self.DrawnAttachments[attachment] = nil
						end
					end
				end
			end
		end
		
		-- Draw the physics model (AKM) as requested
		-- self:DrawModel()
	end

	function ENT:OnRemove()
		if IsValid(self.VisualModelEnt) then
			self.VisualModelEnt:Remove()
		end
		
		if self.DrawnAttachments then
			for k, v in pairs(self.DrawnAttachments) do
				if IsValid(v) then v:Remove() end
			end
		end
	end
end


ENT.Bodygroups = {
	[2] = 1,
	[8] = 2
}

ENT.Spawnable = true

-- ENT.PhysicsBox = {Vector(), Vector()}

-- ENT.CollisionBounds = {Vector(-1,10,5), Vector(1,-5,0)}

ENT.DefaultAmmoAmt = 30
ENT.AmmoType = "SMG1"
ENT.MuzzlePos = Vector(15, 5, 10)
ENT.BulletDir = Vector(5, -1, 0)
ENT.BulletEjectPos = Vector(0, -5.1, 3.8)
ENT.BulletEjectDir = Vector(1, 0, 0)
ENT.Damage = 90
ENT.ShellEffect = "eff_jack_hmcd_556"
ENT.TriggerDelay = .1
ENT.MuzzleEffect = "pcf_jack_mf_mrifle1"

ENT.Attachments = {
	["Suppressor"] = {
		bone = "Dummy001",
		pos = {
			forward = 12,
			up = 0.6,
			right = -3.25
		},
		ang = {
			forward = -90,
			up = 90
		},
		scale = .9,
		model = "models/cw2/attachments/556suppressor.mdl"
	},
	["Laser"] = {
		bone = "Dummy001",
		pos = {
			forward = 20.5,
			up = 1.5,
			right = -6
		},
		ang = {
			up = 180,
			forward = 0,
			right = 0
		},
		scale = .9,
		model = "models/cw2/attachments/anpeq15.mdl"
	},
	["Sight"] = {
		bone = "Dummy001",
		pos = {
			forward = 13.5,
			up = 1.5,
			right = -6
		},
		ang = {
			up = 0,
			forward = 0,
			right = 0
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_kobra.mdl"
	},
	["Sight2"] = {
		bone = "Dummy001",
		pos = {
			forward = 13.5,
			up = 1.5,
			right = -6
		},
		ang = {
			forward = 0,
			up = 0,
			right = 0
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_aimpoint.mdl"
	},
	["Sight3"] = {
		bone = "Dummy001",
		pos = {
			forward = 13.5,
			up = 1.5,
			right = -6
		},
		ang = {
			forward = 0,
			up = 0,
			right = 0
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_eotech.mdl"
	}
}