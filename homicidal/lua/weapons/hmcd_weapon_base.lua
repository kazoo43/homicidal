function SWEP:OnDrop()
	if GetConVar("developer"):GetInt() >= 1 then print("DEBUG: OnDrop " .. tostring(self) .. " IsUnfaking=" .. tostring(self.IsUnfaking)) end
	local owner = self:GetOwner()
	if IsValid(owner) then
		if GetConVar("developer"):GetInt() >= 1 then print("DEBUG: Owner " .. tostring(owner) .. " IsUnfaking=" .. tostring(owner.IsUnfaking)) end
	else
		if GetConVar("developer"):GetInt() >= 1 then print("DEBUG: Owner is NULL") end
	end

	if self.IsUnfaking then return end
	if IsValid(owner) and owner.IsUnfaking then return end

	if self:GetSuiciding() then
		self.FirstOwner:SetDSP(0)
	end

	timer.Stop(tostring(self:GetOwner()) .. "ReloadTimer")
	local Ent = ents.Create(self.ENT)
	Ent.HmcdSpawned = self.HmcdSpawned
	Ent:SetPos(self:GetPos())
	Ent:SetAngles(self:GetAngles())

	if self.Attachments and self.Attachments["Owner"] then
		for attachment, info in pairs(self.Attachments["Owner"]) do
			Ent:SetNWBool(attachment, self:GetNWBool(attachment))
		end
	end

	Ent:Spawn()
	Ent:Activate()
	Ent.RoundsInMag = self:Clip1()
	Ent:GetPhysicsObject():SetVelocity(self:GetVelocity() / 2)
	self:Remove()
end