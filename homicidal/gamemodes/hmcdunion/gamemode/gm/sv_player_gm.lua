local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:GuiltAdd(count) 
    local guilt = self:GetNWInt("Guilt", 0)
    self:SetNWInt("Guilt", guilt + count)
    self:SetPData("U_Guilt", guilt + count)
end

function PlayerMeta:GuiltRemove(count) 
    local guilt = self:GetNWInt("Guilt", 0)
    self:SetNWInt("Guilt", guilt - count)
    self:SetPData("U_Guilt", guilt - count)
end

function PlayerMeta:GuiltSet(count) 
    local guilt = self:GetNWInt("Guilt", 0)
    self:SetNWInt("Guilt", count)
    self:SetPData("U_Guilt", count)
end

concommand.Add("hmcd_droprequest_ammo",function(ply,cmd,args)
	Type,Amount=args[1],tonumber(args[2])
	local Amm=ply:GetAmmoCount(Type)
	if(Amm<Amount)then Amount=Amm end
	if(Amount>0)then
		ply:DropAmmo(Type,Amount)
	end
end)

function PlayerMeta:DropAmmo(type,amt)
	if not(amt)then amt=self:GetAmmoCount(type) end
	if not(amt>0)then return end
	self:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_DROP)
	self:RemoveAmmo(amt,type)
	local Ammo=ents.Create("ent_jack_hmcd_ammo")
	Ammo.HmcdSpawned=true
	Ammo.AmmoType=type
	Ammo.Rounds=amt
	Ammo:SetPos(self:GetShootPos()+self:GetAimVector()*20)
	Ammo:Spawn();Ammo:Activate()
	Ammo:GetPhysicsObject():SetVelocity(self:GetVelocity()+self:GetAimVector()*100)
end

function GM:PlayerCanHearChatVoice(listener, talker, typ)
	if not talker:Alive() then 
		return not listener:Alive()
	end
	
	local isOtrub = talker.Otrub
	if talker.organism and talker.organism.otrub then isOtrub = true end

	if isOtrub or talker.mutejaw or (talker.consciousness and talker.consciousness < 40) or (talker.Blood and talker.Blood <= 3100) or (talker.pain and talker.pain >= 250) or (talker.o2 and talker.o2 <= 0.4) then
		return false
	end

	local ply = listener

	local Wep = talker:GetActiveWeapon()
	if IsValid(Wep) and (Wep:GetClass() == "wep_jack_hmcd_walkietalkie") then
		if ply and ply:Alive() and ply:HasWeapon("wep_jack_hmcd_walkietalkie") then
			if typ == "voice" then
				local talkerFreq = Wep.GetFrequency and Wep:GetFrequency()
				local listenerWep = ply:GetWeapon("wep_jack_hmcd_walkietalkie")
				local listenerFreq = listenerWep and listenerWep.GetFrequency and listenerWep:GetFrequency()
				if talkerFreq == listenerFreq then return true, false end
			else
				return true
			end
		end
	end

	local dis, MaxDist = ply:GetPos():Distance(talker:GetPos()), 3000
	
	local tr = util.TraceLine({
		start = talker:EyePos(),
		endpos = ply:EyePos(),
		filter = {talker, ply},
		mask = MASK_SHOT
	})

	if tr.Hit then
		MaxDist = 300
	end

	if dis < MaxDist then return true, true end

	return false
end

function GM:PlayerCanSeePlayersChat(text, teamOnly, listener, speaker)
	if not IsValid(speaker) then return false end
	local canhear = self:PlayerCanHearChatVoice(listener, speaker, "chat")

	return canhear
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	local canHear, is3D = self:PlayerCanHearChatVoice(listener, talker, "voice")
	return canHear, is3D
end

local function ObfuscateString(str, amount)
	if amount <= 0 then return str end
	local len = #str
	local newStr = ""
	for i = 1, len do
		local char = string.sub(str, i, i)
		if char == " " then
			newStr = newStr .. " "
		elseif math.random() < amount then
			newStr = newStr .. "-"
		else
			newStr = newStr .. char
		end
	end
	return newStr
end

function GM:PlayerSay(ply,text,teem)
	if not ply:Alive() then
		local ct = ChatText()
		ct:Add("(DEAD) " .. ply:Nick(), Color(255, 0, 0))
		ct:Add(": " .. text, color_white)
		
		for k, v in player.Iterator() do
			if not v:Alive() then
				ct:Send(v)
			end
		end
		return false
	end

	if ply:Alive() then

		local Wep, WalkieTalkie = ply:GetActiveWeapon(), false
		local talkerFreq = nil
		if IsValid(Wep) and (Wep:GetClass() == "wep_jack_hmcd_walkietalkie") then
			WalkieTalkie = true
			talkerFreq = Wep.GetFrequency and Wep:GetFrequency()
		end

		local col = ply:GetPlayerColor()
		for k, ply2 in player.Iterator() do
			local can = hook.Call("PlayerCanSeePlayersChat", GAMEMODE, text, teem, ply2, ply)
			if can then
				local ct = ChatText()
				
				local listenerHasWalkie = false
				local listenerFreq = nil
				local Wep2 = ply2:GetActiveWeapon()
				if ply2:Alive() and IsValid(Wep2) and (Wep2:GetClass() == "wep_jack_hmcd_walkietalkie") then
					listenerHasWalkie = true
					listenerFreq = Wep2.GetFrequency and Wep2:GetFrequency()
				end

				local isRadioMessage = WalkieTalkie and listenerHasWalkie and (talkerFreq == listenerFreq)

				if isRadioMessage then
					ct:Add("Walkie Talkie", color_white)
				else
					ct:Add(ply:GetNWString("Character_Name"), Color(col.x * 255, col.y * 255, col.z * 255))
				end

				local displayText = text
				local dis = ply:GetPos():Distance(ply2:GetPos())
				local MaxDist = 3000
				
				local tr = util.TraceLine({
					start = ply:EyePos(),
					endpos = ply2:EyePos(),
					filter = {ply, ply2},
					mask = MASK_SHOT
				})

				if tr.Hit then
					MaxDist = 300
				end

				if not isRadioMessage then
					local factor = math.Clamp(dis / MaxDist, 0, 1)
					if factor < 0.2 then factor = 0 end
					displayText = ObfuscateString(text, factor)
				end

				ct:Add(": " .. displayText, color_white)
				ct:Send(ply2)
				if isRadioMessage then
					sound.Play("snd_jack_hmcd_walkietalkie.wav", ply2:GetShootPos(), 50, 100)
				end
			end
		end

		return false
	end
	return true
end

function GM:PlayerLeavePlay(ply)
	if ply:HasWeapon("wep_jack_hmcd_smallpistol") then
		ply:DropWeapon(ply:GetWeapon("wep_jack_hmcd_smallpistol"))
	end

	if GetGlobalInt("RoundState", 0) == 1 then
		if ply.Role == "Traitor" then
			GAMEMODE:EndRound(2, ply)
		end
	end
end

function GM:PlayerOnChangeTeam(ply, newTeam, oldTeam)
	if oldTeam == 2 then
		GAMEMODE:PlayerLeavePlay(ply)
	end

	if newteam == 1 then end
	ply:KillSilent()
end