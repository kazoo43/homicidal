local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")
BleedingEntities = BleedingEntities or {}

RagdollDamageBoneMul={ -- Умножения урона при попадании по регдоллу
	[HITGROUP_LEFTLEG]=0.3,
	[HITGROUP_RIGHTLEG]=0.3,

	[HITGROUP_GENERIC]=0.7,

	[HITGROUP_LEFTARM]=0.4,
	[HITGROUP_RIGHTARM]=0.4,

	[HITGROUP_CHEST]=0.8,
	[HITGROUP_STOMACH]=0.7,

	[HITGROUP_HEAD]=5,
}

bonetohitgroup={ --Хитгруппы костей
    ["ValveBiped.Bip01_Head1"]=1,
    ["ValveBiped.Bip01_R_UpperArm"]=5,
    ["ValveBiped.Bip01_R_Forearm"]=5,
    ["ValveBiped.Bip01_R_Hand"]=5,
    ["ValveBiped.Bip01_L_UpperArm"]=4,
    ["ValveBiped.Bip01_L_Forearm"]=4,
    ["ValveBiped.Bip01_L_Hand"]=4,
    ["ValveBiped.Bip01_Pelvis"]=3,
    ["ValveBiped.Bip01_Spine2"]=2,
    ["ValveBiped.Bip01_L_Thigh"]=6,
    ["ValveBiped.Bip01_L_Calf"]=6,
    ["ValveBiped.Bip01_L_Foot"]=6,
    ["ValveBiped.Bip01_R_Thigh"]=7,
    ["ValveBiped.Bip01_R_Calf"]=7,
    ["ValveBiped.Bip01_R_Foot"]=7
}

function GetFakeWeapon(ply)
    ply.curweapon = ply.Info.ActiveWeapon
end

function SavePlyInfo(ply) -- Сохранение игрока перед его падением в фейк
    ply.Info = {}
    local info = ply.Info
    info.HasSuit = ply:IsSuitEquipped()
    info.SuitPower = ply:GetSuitPower()
    info.skull = ply.skull or 15
    info.brain = ply.brain or 5
    info.Ammo = ply:GetAmmo()
	info.ArteryHit = ply:GetNWBool("ArteryHit")
	info.NeckArteryHit = ply:GetNWBool("NeckArteryHit")
    info.ActiveWeapon = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or nil
    info.ActiveWeapon2 = ply:GetActiveWeapon()
    
	GetFakeWeapon(ply)
    info.Weapons={}
    for i,wep in pairs(ply:GetWeapons())do
        info.Weapons[wep:GetClass()]={
            Clip1=wep:Clip1(),
            Clip2=wep:Clip2(),
			Base=wep.Base,
            AmmoType=wep:GetPrimaryAmmoType(),
			Sight=wep:GetNWBool("Sight"),
			Sight2=wep:GetNWBool("Sight2"),
			Sight3=wep:GetNWBool("Sight3"),
			Laser=wep:GetNWBool("Laser"),
			Suppressor=wep:GetNWBool("Suppressor"),
			Rail=wep:GetNWBool("Rail"),
			Romeo8T=wep:GetNWBool("Romeo8T"),
			Scope1=wep:GetNWBool("Scope1"),
			Resource=wep.Resource
        }
    end
    info.Weapons2={}
    for i,wep in ipairs(ply:GetWeapons())do
        info.Weapons2[i-1]=wep:GetClass()
    end
    info.AllAmmo={}
    local i
    for ammo, amt in pairs(ply:GetAmmo())do
		i = i or 0
        i = i + 1
        info.AllAmmo[ammo]={i,amt}
    end
    --PrintTable(info.AllAmmo)
    return info
end

function GiveAttachments(ply)
end

function GetFakeWeapon(ply)
	ply.curweapon = ply.Info.ActiveWeapon
end

function ClearFakeWeapon(ply)
	if ply.FakeShooting then DespawnWeapon(ply) end
end
util.AddNetworkString("ragplayercolor")
function EntityMeta:BetterSetPlayerColor(col)
	if not (col or self) then return end
	timer.Simple(.1, function()
		if not IsValid(self) then return end
		net.Start("ragplayercolor")
		net.WriteEntity(self)
		net.WriteVector(col)
		net.Broadcast()
	end)
end

function SavePlyInfoPreSpawn(ply) -- Сохранение игрока перед вставанием
	ply.Info = ply.Info or {}
	local info = ply.Info
	info.Hp = ply:Health()
	info.Armor = ply:Armor()
	info.skull = ply.skull or 15
	info.brain = ply.brain or 5
	return info
end

function ReturnPlyInfo(ply) -- возвращение информации игроку по его вставанию
    if GetConVar("developer"):GetInt() >= 1 then print("DEBUG: ReturnPlyInfo called for " .. tostring(ply) .. " FakeShooting=" .. tostring(ply.FakeShooting)) end
    -- Force despawn weapon to clean up props
    DespawnWeapon(ply)
	ply:SetSuppressPickupNotices(true)
    local info = ply.Info
    if (!info) then return end

	ply.IsUnfaking = true
    for k,v in ipairs(ply:GetWeapons()) do v.IsUnfaking = true end
    ply:StripWeapons()
    ply:StripAmmo()
	
	ply.slots = {}
    for name, wepinfo in pairs(info.Weapons or {}) do
        local weapon = ply:Give(name, true)

		if IsValid(weapon) then
			if wepinfo.Base == "wep_cat_base" then
				weapon:SetNWBool("Sight", wepinfo.Sight)
				weapon:SetNWBool("Sight2", wepinfo.Sight2)
				weapon:SetNWBool("Sight3", wepinfo.Sight3)
				weapon:SetNWBool("Laser", wepinfo.Laser)
				weapon:SetNWBool("Suppressor", wepinfo.Suppressor)
				weapon:SetNWBool("Rail", wepinfo.Rail)
				weapon:SetNWBool("Romeo8T", wepinfo.Romeo8T)
				weapon:SetNWBool("Scope1", wepinfo.Scope1)
			end

			weapon.Resource = wepinfo.Resource

			if wepinfo.Clip1~=nil and wepinfo.Clip2~=nil then
            	weapon:SetClip1(wepinfo.Clip1)
            	weapon:SetClip2(wepinfo.Clip2)
        	end

		end
    end
    for ammo, amt in pairs(info.Ammo or {}) do
        ply:GiveAmmo(amt,ammo)
    end
    if info.ActiveWeapon then
        ply:SelectWeapon(info.ActiveWeapon)
    end
    if info.HasSuit then
        ply:EquipSuit()
        ply:SetSuitPower(info.SuitPower or 0)
    else
        ply:RemoveSuit()
    end
    ply:SetHealth(info.Hp)
    ply:SetArmor(info.Armor)
    ply.skull = info.skull or 15
    ply.brain = info.brain or 5
    
    if info.HMCD_HEVSuit then
        ply:SetNWBool("HMCD_HEVSuit", true)
    end
    
    ply.IsUnfaking = nil
end

local poses = {}

local function GetLedgePos(ply, rag)
	if not IsValid(ply) or not IsValid(rag) then return nil end

	-- Get ragdoll head position or pelvis
	local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
	local headPos = (bone and rag:GetBonePosition(bone)) or rag:GetPos() + Vector(0,0,60)
	
	-- Direction: where player is looking
	local aimVec = ply:GetAimVector()
	aimVec.z = 0
	aimVec:Normalize()
	
	-- Trace forward to find a wall/ledge face
	-- Increased distance slightly to catch ledges better
	local trForward = util.TraceHull({
		start = headPos,
		endpos = headPos + aimVec * 8, -- Distance 8
		mins = Vector(-5, -5, -5),
		maxs = Vector(5, 5, 5),
		filter = {ply, rag},
		mask = MASK_PLAYERSOLID
	})
	
	if trForward.Hit then
		-- We hit a wall. Now check if there is a ledge top.
		local wallNormal = trForward.HitNormal
		-- If wall is too steep/sloped, ignore (only climb vertical-ish walls)
		if math.abs(wallNormal.z) > 0.5 then return nil end
		
		-- Start trace from above the hit position, slightly inside the wall
		-- Adjusted: Ensure we scan deep enough to find the ledge top, but not too deep
		local scanStart = trForward.HitPos + (aimVec * 8) + Vector(0,0,110) 
		local scanEnd = trForward.HitPos + (aimVec * 8) - Vector(0,0,20)
		
		-- Use TraceHull for the vertical scan to ensure we find a flat surface big enough for feet
		local trDown = util.TraceHull({
			start = scanStart,
			endpos = scanEnd,
			mins = Vector(-8,-8,0),
			maxs = Vector(8,8,1),
			filter = {ply, rag},
			mask = MASK_PLAYERSOLID
		})
		
		if trDown.Hit and not trDown.StartSolid then
			local ledgePos = trDown.HitPos
			local heightDiff = ledgePos.z - headPos.z
			
			-- Height check: Ledge must be above head (or slightly below) but reachable
			if heightDiff > -30 and heightDiff < 110 then
				-- Final check: Is there room to stand?
				-- Increased hull size to standard player size (approx) for safety
				-- Also added a small Z offset to prevent floor sticking
				local destPos = ledgePos + Vector(0,0,2)
				local hull = 16 
				local mins, maxs = Vector(-hull,-hull,0), Vector(hull,hull,72)
				
				local trHull = util.TraceHull({
					start = destPos,
					endpos = destPos,
					mins = mins,
					maxs = maxs,
					filter = {ply, rag},
					mask = MASK_PLAYERSOLID
				})
				
				if not trHull.Hit then
					return destPos
				end
			end
		end
	end
	
	return nil
end

local function GetUpPos(ply, pos, tries, starttries)
	if not IsValid(ply) then return pos end

	local hull = 10
	local mins,maxs = -Vector(hull,hull,0),Vector(hull,hull,72)

	if tries <= 0 then
		table.sort(poses,function(a,b) return a[2] < b[2] end)
		
		local vec = #poses > 0 and poses[1][1]
		
		poses = {}

		if vec then
			local t = {}
			t.start = vec
			t.endpos = vec - Vector(0,0,128)
			t.mins = mins
			t.maxs = maxs
			t.filter = {ply,ply:GetNWEntity("Ragdoll")}
			t.mask = MASK_PLAYERSOLID
			local tr = util.TraceHull( t )

			return tr.HitPos
		end

		return nil
	end
	tries = tries - 1


	local offset = tries == starttries and Vector(0,0,0) or VectorRand(-32,32)
    offset.z = 0
	local newpos = pos + offset

	local t = {}
	t.start = pos
	t.endpos = newpos
	t.filter = {ply,ply:GetNWEntity("Ragdoll")}
	t.mask = MASK_PLAYERSOLID

	local tr = util.TraceLine( t )

	if not tr.Hit then
		local t = {}
		t.start = newpos
		t.endpos = newpos
		t.mins = mins
		t.maxs = maxs
		t.filter = {ply,ply:GetNWEntity("Ragdoll")}
		t.mask = MASK_PLAYERSOLID
		local tr = util.TraceHull( t )
		
		if not tr.Hit then
			table.insert(poses,{newpos,(newpos - pos):LengthSqr()})
		end
	end

	return GetUpPos(ply,pos,tries,starttries)
end

function Faking(ply, forcePos) -- функция падения
	if not ply:Alive() then return end
	if not ply.fake then
		if hook.Run("Fake",ply) ~= nil then return end
		SavePlyInfo(ply)
		ply.fake = true
		--ply.curweapon = ply:GetActiveWeapon():GetClass() or "" 
		ply:SetNWBool("fake",ply.fake)
		ply:SetSuppressPickupNotices(true)
		ply:DrawViewModel(false)
		if (SERVER) then
		ply:DrawWorldModel(false)
		ply:DrawViewModel(false)
		end
		local veh
		if ply:InVehicle() then
			veh = ply:GetVehicle()
			ply:ExitVehicle()
		end

		local rag = ply:CreateRagdoll()
		rag.eye = true
		if IsValid(veh) then
			rag:GetPhysicsObject():SetVelocity(veh:GetPhysicsObject():GetVelocity() * 5)
		end
		if IsValid(ply:GetNWEntity("Ragdoll")) then
			ply.fakeragdoll=ply:GetNWEntity("Ragdoll")
			ply.fake = true
			local wep = ply:GetActiveWeapon()

			if IsValid(wep) and table.HasValue(Guns,wep:GetClass())then
				SpawnWeapon(ply)
			end
			ply.walktime = CurTime()
			rag.temp = ply.temp
			rag:SetFlexWeight(9,2)
			rag.bull = ents.Create("npc_bullseye")
			rag:SetNWEntity("RagdollController",ply)
			local bull = rag.bull
			local bodyphy = rag:GetPhysicsObjectNum(10)
			bull:SetPos(bodyphy:GetPos()+bodyphy:GetAngles():Right()*7)
			bull:SetMoveType( MOVETYPE_OBSERVER )
			bull:SetParent(rag,rag:LookupAttachment("eyes"))
			bull:SetHealth(1000)
			bull:Spawn()
			bull:Activate()
			bull:SetNotSolid(true)
			FakeBullseyeTrigger(rag,ply)
			ply:HuySpectate(OBS_MODE_CHASE)
			ply:SpectateEntity(ply:GetNWEntity("Ragdoll"))
			ply:SetActiveWeapon(nil)
			ply:DropObject()

			timer.Create("faketimer"..ply:EntIndex(), 0.8, 1, function() end)

			if table.HasValue(Guns,ply.curweapon) then
				ply.FakeShooting=true
				ply:SetNWInt("FakeShooting",true)
			else
				ply.FakeShooting=false
				ply:SetNWInt("FakeShooting",false)
			end
		end
	else
		local rag = ply:GetNWEntity("Ragdoll")
		if not IsValid(rag) then return end

		local bone = rag:LookupBone("ValveBiped.Bip01_Pelvis")
		local posit = (bone and rag:GetBonePosition(bone)) or rag:GetPos()
		
		local spawnPos = forcePos
		if not spawnPos then
			-- Prevent instant get-up if a ledge is detected (force player to use the hold mechanic)
			if not GetLedgePos(ply, rag) then
				spawnPos = GetUpPos(ply, posit, 50, 50)
			end
		end

		if not spawnPos then return end

		if ply.Otrub then
			ply:ChatPrint("You're unconscious")
		return false end
		if ply.Hit["spine"] then
			ply:ChatPrint("Your spine is broken")
		return false end
		if ply.Bones['LeftLeg']<1 and ply.Bones['RightLeg']<1 then
			ply:ChatPrint("Your both legs are broken")
		return false end
		local rag = ply:GetNWEntity("Ragdoll")
		ply.lasthitgroup = nil
		if IsValid(rag) then
			if IsValid(rag.bull) then
				rag.bull:Remove()
			end
			ply.GotUp = CurTime()
			if hook.Run("Fake Up",ply,rag) ~= nil then return end

			ply.fake = false
			ply:SetNWBool("fake",ply.fake)

			ply.fakeragdoll=nil
			SavePlyInfoPreSpawn(ply)
			--local pos=rag:GetPos()
			local vel=rag:GetVelocity()
			PLYSPAWN_OVERRIDE = true
			ply.IsUnfaking = true
			for k,v in ipairs(ply:GetWeapons()) do
				if GetConVar("developer"):GetInt() >= 1 then print("DEBUG: Setting IsUnfaking on " .. tostring(v)) end
				v.IsUnfaking = true
			end
			ply:StripWeapons()
			ply:SetNWBool("unfaked",PLYSPAWN_OVERRIDE)
			local eyepos=ply:EyeAngles()
			local health = ply:Health()
			ply:Spawn()
			-- Ensure IsUnfaking persists through spawn
			ply.IsUnfaking = true 
			ReturnPlyInfo(ply)
			ply.IsUnfaking = nil
			ply:SetHealth(health)
			ply.FakeShooting=false
			ply:SetNWInt("FakeShooting",false)
			ply:SetEyeAngles(eyepos)
			PLYSPAWN_OVERRIDE = nil
			ply:SetNWBool("unfaked",PLYSPAWN_OVERRIDE)
			
			ply:SetPos(spawnPos)
			ply:SetVelocity(vel)

			ply:ConCommand("+duck")
			timer.Simple(0.5,function()
				if IsValid(ply) then
					ply:ConCommand("-duck")
				end
			end)

			ply:DrawViewModel(true)
			ply:DrawWorldModel(true)
			ply:SetModel(ply:GetNWEntity("Ragdoll"):GetModel())
			ply:SetPlayerColor(ply:GetNWEntity("Ragdoll"):GetNWVector("plycolor", Vector(1, 1, 1)))
			ply:GetNWEntity("Ragdoll").huychlen = true
			ply:GetNWEntity("Ragdoll"):Remove()
			ply:SetNWEntity("Ragdoll",nil)
		end
	end
end

--[[hook.Add("CanExitVehicle", "fakefastcar", function(veh,ply)
    if veh:GetPhysicsObject():GetVelocity():Length() > 100 then Faking(ply) return false end
end)]]

function FakeBullseyeTrigger(rag,owner)
	if not IsValid(rag.bull) then return end
	for i,ent in pairs(ents.FindByClass("npc_*"))do
		if(ent:IsNPC() and ent:Disposition(owner)==D_HT)then
			ent:AddEntityRelationship(rag.bull,D_HT,0)
		end
	end
end

hook.Add("OnEntityCreated","hg-bullseye",function(ent)
	ent:SetShouldPlayPickupSound(false)
	if ent:IsNPC() then
		for i,rag in pairs(ents.FindByClass("prop_ragdoll"))do
			if IsValid(rag.bull) then
				ent:AddEntityRelationship(rag.bull,D_HT,0)
			end
		end
	end
end)

hook.Add("Player Think","FakedShoot",function(ply,time) --функция стрельбы лежа
	if IsValid(ply:GetNWEntity("Ragdoll")) and ply.FakeShooting and ply:Alive() then
		SpawnWeapon(ply)
	else
		if IsValid(ply.wep) then
			DespawnWeapon(ply)
		end
	end
end)


function RagdollOwner(rag) --функция, определяет хозяина регдолла
	if not IsValid(rag) then return end

	local ent = rag:GetNWEntity("RagdollController")
	return IsValid(ent) and ent
end

function PlayerMeta:DropWeapon1(wep)
    local ply = self
	wep = wep or ply:GetActiveWeapon()
    if !IsValid(wep) then return end

	if wep:GetClass() == "wep_jack_hmcd_hands" then return end
	ply:DropWeapon(wep)
	wep.Spawned = true
	ply:SelectWeapon("wep_jack_hmcd_hands")
end

util.AddNetworkString("pophead")
util.AddNetworkString("HMCD_LedgeClimb")

net.Receive("HMCD_LedgeClimb", function(len, ply)
	if not IsValid(ply) or not ply:Alive() or not ply.fake then return end
	
	-- Double check inputs on server for security
	if not (ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED)) then return end
	
	local rag = ply:GetNWEntity("Ragdoll")
	if not IsValid(rag) then return end
	
	local ledgePos = GetLedgePos(ply, rag)
	if ledgePos then
		Faking(ply, ledgePos)
	end
end)

function PlayerMeta:PickupEnt()
	local ply = self
	local rag = ply:GetNWEntity("Ragdoll")
	local phys = rag:GetPhysicsObjectNum(7)
	local offset = phys:GetAngles():Right()* 5
	local traceinfo={
		start=phys:GetPos(),
		endpos=phys:GetPos()+offset,
		filter=rag,
		output=trace,
	}
	local trace = util.TraceLine(traceinfo)
	if trace.Entity == Entity(0) or trace.Entity == NULL or !trace.Entity.canpickup then return end
	if trace.Entity:GetClass()=="wep" then
		ply:Give(trace.Entity.curweapon,true):SetClip1(trace.Entity.Clip)
		--SavePlyInfo(ply)
		ply.wep.RoundsInMag=trace.Entity.Clip
		trace.Entity:Remove()
	end
end

hook.Add("DoPlayerDeath","blad",function(ply,att,dmginfo)
	if IsValid(ply.wep) then
		ply.wep.OwnerAlive = false
		ply.wep = nil
	end
	SavePlyInfo(ply)
	local rag = ply:GetNWEntity("Ragdoll")
	
	if not IsValid(rag) then
		rag = ply:CreateRagdoll(att,dmginfo)
		ply:SetNWEntity("Ragdoll",rag)
	end
	rag=ply:GetNWEntity("Ragdoll")
	rag:GetPhysicsObject():SetMass(1)
	rag:SetNWEntity("RagdollController",nil)

	net.Start("pophead")
	net.WriteEntity(rag)
	net.Send(ply)
	if IsValid(rag.bull) then rag.bull:Remove() end
	rag:SetNWBool("Dead", true)
	if checkAllBleedOuts_bolshe(ply, 0) then
		rag.IsBleeding=true
		rag.bloodNext = CurTime()
		rag.Blood = ply.Blood
		table.insert(BleedingEntities,rag)
	end

	rag.Info = ply.Info
	rag:SetNWBool("Dead", true)
	rag.curweapon=ply.curweapon
	if(IsValid(rag.ZacConsLH))then
		rag.ZacConsLH:Remove()
		rag.ZacConsLH=nil
	end

	if(IsValid(rag.ZacConsRH))then
		rag.ZacConsRH:Remove()
		rag.ZacConsRH=nil
	end

	local ent = ply:GetNWEntity("Ragdoll")
	if IsValid(ent) then ent:SetNWEntity("RagdollOwner",Entity(-1)) end

	ply:SetDSP(0)
	ply.fakeragdoll = nil
	ply.fake = nil
	ply.FakeShooting = false
	PLYSPAWN_OVERRIDE = nil
	ply.FakeShooting=false
	ent.canaccept_dead = true
	ply:SetNWInt("FakeShooting",false)
	ent:SetFlexWeight(9, 10)
	if fs then
		ent.temp = ply.temp
		if ply.Otrub then
			ent.eye = false
		else
			ent.eye = true
		end
		timer.Create("temperature_1"..ent:EntIndex(),30,1,function()
			if IsValid(ent) then
				ent.temp = "Little Cold"
				timer.Create("temperature_2"..ent:EntIndex(),10,1,function()
					if IsValid(ent) then
						ent.temp = "Cold"
					end
				end)
			end
		end)
	end
	timer.Create("collision"..ent:EntIndex(),15,1,function()
		if IsValid(ent) and GetGlobalString("RoundName", "homicide") != "homicide" then rag:SetCollisionGroup(COLLISION_GROUP_WEAPON) end
	end)
	timer.Create("stopbleed"..ent:EntIndex(),30,1,function()
		if IsValid(ent) then ent.IsBleeding = false end
	end)
	timer.Create("delete"..ent:EntIndex(),120,1,function()
		if IsValid(ent) and GetGlobalString("RoundName", "homicide") != "homicide" then ent:Remove() end
	end)
end)

hook.Add("PhysgunDrop", "DropPlayer", function(ply,ent)
	ent.isheld=false
end)

--[[hook.Add("PlayerDisconnected","saveplyinfo",function(ply)
	if ply:Alive() then
		SavePlyInfo(ply)
		ply:Kill()
	end
end)]]

hook.Add("PhysgunPickup", "DropPlayer2", function(ply,ent)

	if ply:IsAdmin()  then

		if ent:IsPlayer() and !ent.fake then
			if hook.Run("Should Fake Physgun",ply,ent) ~= nil then return false end

			Faking(ent)
			return false
		end
	end
end)

util.AddNetworkString("fuckfake")
util.AddNetworkString("hmcd_fakefire")
hook.Add("PlayerSpawn","resetfakebody",function(ply) --обнуление регдолла после вставания
	ply.fake = false
	ply:AddEFlags(EFL_NO_DAMAGE_FORCES)

	net.Start("fuckfake")
	net.Send(ply)

	ply:SetNWBool("fake",false)

	if PLYSPAWN_OVERRIDE then return end
	ply.FakeShooting = false

	ply:SetDuckSpeed(0.3)
	ply:SetUnDuckSpeed(0.3)
	
	ply.slots = {}
	if ply.UsersInventory ~= nil then
		for plys,bool in pairs(ply.UsersInventory) do
			ply.UsersInventory[plys] = nil
			send(plys,lootEnt,true)
		end
	end
	ply:SetNWEntity("Ragdoll",nil)
end)

local function hasWeapon(ply, weaponName) -- И че это за чатгпт кодинг але
    if not IsValid(ply) or not ply:IsPlayer() then return false end -- Проверяем, является ли объект игроком и существует ли он
    
    for _, weapon in pairs(ply:GetWeapons()) do -- Перебираем все оружия игрока
        if IsValid(weapon) and weapon:GetClass() == weaponName then -- Проверяем, является ли оружие действительным и совпадает ли его класс с заданным названием
            return true -- Если нашли оружие, возвращаем true
        end
    end
    
    return false 
end

zeroAng = Angle(0,0,0)
concommand.Add("fake",function(ply)
	if ply:GetNWString("Round","") == "dm" and ply:GetNWInt("DMTime", 10) >= 1 then return nil end
	if ply.Otrub then return nil end
	if ply.in_handcuff then return nil end
	if ply.Stunned then return nil end
	if not ply.fake and (ply.NextManualRagdoll or 0) > CurTime() then return nil end
	if timer.Exists("faketimer"..ply:EntIndex()) then return nil end
	if IsValid(ply:GetNWEntity("Ragdoll")) and ply:GetNWEntity("Ragdoll"):GetVelocity():Length()>300 then return nil end
	if IsValid(ply:GetNWEntity("Ragdoll")) and table.Count(constraint.FindConstraints( ply:GetNWEntity("Ragdoll"), 'Rope' ))>0 then return nil end
	--if IsValid(ply:GetNWEntity("Ragdoll")) and table.Count(constraint.FindConstraints( ply:GetNWEntity("Ragdoll"), 'Weld' ))>0 then return nil end

	timer.Create("faketimer"..ply:EntIndex(), 0.2, 1, function() end)
	if ply:Alive() then
		Faking(ply)
		ply.fakeragdoll=ply:GetNWEntity("Ragdoll")
	end
end)

hook.Add("PreCleanupMap", "cleannoobs", function() --все игроки встают после очистки карты
	for _, ply in player.Iterator() do
		if ply.fake then Faking(ply) end
	end

	BleedingEntities = {}
end)

--[[local function Remove(self,ply)
end]]

local CustomWeight = {
	["models/player/police_fem.mdl"] = 50,
	["models/player/police.mdl"] = 60,
	["models/player/combine_soldier.mdl"] = 70,
	["models/player/combine_super_soldier.mdl"] = 80,
	["models/player/combine_soldier_prisonguard.mdl"] = 70,
	["models/player/azov.mdl"] = 10,
	["models/player/Rusty/NatGuard/male_01.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_02.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_03.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_04.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_05.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_06.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_07.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_08.mdl"] = 90,
	["models/player/Rusty/NatGuard/male_09.mdl"] = 90,
	["models/LeymiRBA/Gyokami/Gyokami.mdl"] = 50,
	["models/player/smoky/Smoky.mdl"] = 65,
	["models/player/smoky/Smokycl.mdl"] = 65,
	["models/knyaje pack/dibil/sso_politepeople.mdl"] = 40
}

for i = 1,6 do
	CustomWeight["models/monolithservers/mpd/female_0"..i..".mdl"] = 20
end

for i = 1,6 do
	CustomWeight["models/monolithservers/mpd/female_0"..i.."_2.mdl"] = 20
end

for i = 1,6 do
	CustomWeight["models/monolithservers/mpd/male_0"..i..".mdl"] = 20
end

for i = 1,6 do
	CustomWeight["models/monolithservers/mpd/male_0"..i.."_2.mdl"] = 20
end

local hitgroup_angle = {
	[HITGROUP_LEFTLEG] = 2000,
	[HITGROUP_RIGHTLEG] = 2000,
	[HITGROUP_STOMACH] = 3500,
	[HITGROUP_CHEST] = 3500,
	[HITGROUP_LEFTARM] = 6000,
	[HITGROUP_RIGHTARM] = 6000,
	[HITGROUP_HEAD] = 8000,
}

function PlayerMeta:CreateRagdoll(attacker,dmginfo) --изменение функции регдолла
	--if not self:Alive() then return end
	local ragd=self:GetNWEntity("Ragdoll")
	ragd.ExplProof = true
	--debug.Trace()
	if IsValid(ragd) then
		if(IsValid(ragd.ZacConsLH))then
			ragd.ZacConsLH:Remove()
			ragd.ZacConsLH=nil
		end
		if(IsValid(ragd.ZacConsRH))then
			ragd.ZacConsRH:Remove()
			ragd.ZacConsRH=nil
		end
		return
	end

	local Data = duplicator.CopyEntTable( self )
	local rag = ents.Create( "prop_ragdoll" )
	duplicator.DoGeneric( rag, Data )
	rag:SetModel(self:GetModel())
	rag:SetNWVector("plycolor",self:GetPlayerColor())
	rag:SetNWString("Character_Name", self:GetNWString("Character_Name"))
	rag:SetSkin(self:GetSkin())
	rag:BetterSetPlayerColor(self:GetPlayerColor())
	rag:Spawn()
	rag:SetCollisionGroup(COLLISION_GROUP_NONE)
	rag:CallOnRemove("huyhjuy",function() self.firstrag = false end)
	rag:CallOnRemove("huy2ss",function()
		if not rag.huychlen and RagdollOwner(rag) then
			rag.huychlen = false
			RagdollOwner(rag):KillSilent()
		end
	end)
	if self:GetNWString("Bodyvest", "") == "Level IIIA" or self:GetNWString("Bodyvest", "") == "Level III" then

		--local ent = ents.Create((self:GetNWString("Bodyvest", "") == "Level IIIA" and "ent_jack_hmcd_softarmor") or "ent_jack_hmcd_hardarmor")
		local ent = ents.Create("prop_physics")
		local Pos,Ang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Spine4"))
		local Right,Forward,Up = Ang:Right(),Ang:Forward(),Ang:Up()
		if self.ModelSex == "male" then
			Pos = Pos + Right * -15 + Forward * -55 + Up * 0
		else
			Pos = Pos + Right * -8 + Forward * -58 + Up * 0
		end

		ent.IsArmor = true
		rag.Bodyvest = ent
		rag:SetNWEntity("ENT_Bodyvest", ent)
		ent:SetPos(Pos)
		ent:SetAngles(Angle(0,0,0))
		ent:SetModel("models/sal/acc/armor01.mdl")

		if self:GetNWString("Bodyvest","") == "Level III" then
			ent:SetColor(Color(5,0,5))
		else
			ent:SetColor(Color(255,255,255))
		end

		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if IsValid(ent:GetPhysicsObject()) then
			ent:GetPhysicsObject():SetMaterial("plastic")
			ent:GetPhysicsObject():SetMass(4)
		end

		constraint.Weld(ent,rag,0,rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_Spine4")),0,true,false)

		rag:DeleteOnRemove(ent)
		ent:CallOnRemove("BodyvestNo",function()
			if IsValid(rag) then
				rag.Bodyvest = nil
			end
		end)
	end
	if self:GetNWBool("Headcrab", false) == true then

		--local ent = ents.Create((self:GetNWString("Bodyvest", "") == "Level IIIA" and "ent_jack_hmcd_softarmor") or "ent_jack_hmcd_hardarmor")
		local ent = ents.Create("prop_physics")
		local Pos,Ang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Head1"))
		local Right,Forward,Up = Ang:Right(),Ang:Forward(),Ang:Up()
		if self.ModelSex == "male" then
			Pos = Pos + Right * 4 + Forward * -5 + Up * 0
		else
			Pos = Pos + Right * 4 + Forward * -5 + Up * 0
		end

		ent.IsArmor = false
		rag.HeadcrabEnt = ent
		rag:SetNWEntity("ENT_Helmet", ent)
		ent:SetPos(Pos)
		ent:SetAngles(Angle(0,0,0))
		ent:SetModel("models/headcrabclassic.mdl")
		timer.Create("HeadcrabVelocity"..rag:EntIndex(), 2, 0, function()
			if IsValid(rag) and IsValid(rag.HeadcrabEnt) then
				rag.HeadcrabEnt:GetPhysicsObject():SetVelocity(rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Head1"))*math.random(1, 6))
				if rag:GetNWBool("Dead", false) == true then
					rag.HeadcrabEnt:GetPhysicsObject():SetVelocity(rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Head1"))*25)
					local headcrab = ents.Create("npc_headcrab")
					headcrab:SetPos(rag.HeadcrabEnt:GetPos()+Vector(0,0,15))
					headcrab:SetAngles(rag.HeadcrabEnt:GetAngles())
					headcrab:Activate()
					headcrab:Spawn()
					rag.HeadcrabEnt:Remove()
				end
			end
		end)
		ent:SetColor(Color(255,255,255))

		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if IsValid(ent:GetPhysicsObject()) then
			ent:GetPhysicsObject():SetMaterial("plastic")
			ent:GetPhysicsObject():SetMass(0)
		end

		local pizdahelmet = constraint.Weld(ent,rag,0,rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_Head1")),0,true,false)
		rag:DeleteOnRemove(ent)
		ent:CallOnRemove("HelmetNo",function()
			if IsValid(rag) then
				rag.Helmet = nil
			end
		end)
	end
	if self:GetNWString("Helmet", "") == "ACH" then

		--local ent = ents.Create((self:GetNWString("Bodyvest", "") == "Level IIIA" and "ent_jack_hmcd_softarmor") or "ent_jack_hmcd_hardarmor")
		local ent = ents.Create("prop_physics")
		local Pos,Ang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Head1"))
		local Right,Forward,Up = Ang:Right(),Ang:Forward(),Ang:Up()
		if self.ModelSex == "male" then
			Pos = Pos + Right * 2 + Forward * 0 + Up * 0
		else
			Pos = Pos + Right * 2 + Forward * 0 + Up * 0
		end

		ent.IsArmor = true
		rag.Helmet = ent
		rag:SetNWEntity("ENT_Helmet", ent)
		ent:SetPos(Pos)
		ent:SetAngles(Angle(0,0,0))
		ent:SetModel("models/barney_helmet.mdl")
		ent:SetMaterial("models/mat_jack_hmcd_armor")

		ent:SetColor(Color(255,255,255))

		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if IsValid(ent:GetPhysicsObject()) then
			ent:GetPhysicsObject():SetMaterial("plastic")
			ent:GetPhysicsObject():SetMass(0)
		end

		local pizdahelmet = constraint.Weld(ent,rag,0,rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_Head1")),0,true,false)
		rag.helmetweld = pizdahelmet
		rag:DeleteOnRemove(ent)
		ent:CallOnRemove("HelmetNo",function()
			if IsValid(rag) then
				rag.Helmet = nil
			end
		end)
	end
	if self:GetNWString("Mask", "") == "NVG" then

		--local ent = ents.Create((self:GetNWString("Bodyvest", "") == "Level IIIA" and "ent_jack_hmcd_softarmor") or "ent_jack_hmcd_hardarmor")
		local ent = ents.Create("prop_physics")
		local Pos,Ang = rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Head1"))
		local Right,Forward,Up = Ang:Right(),Ang:Forward(),Ang:Up()
		Pos = Pos + Right * 2 + Forward * 0 + Up * 0

		ent.IsArmor = true
		rag.Mask = ent
		rag:SetNWEntity("ENT_Mask", ent)
		ent:SetPos(Pos)
		ent:SetAngles(Angle(0,0,0))
		ent:SetModel("models/arctic_nvgs/nvg_gpnvg.mdl")

		ent:SetColor(Color(255,255,255))

		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if IsValid(ent:GetPhysicsObject()) then
			ent:GetPhysicsObject():SetMaterial("plastic")
			ent:GetPhysicsObject():SetMass(0)
		end

		constraint.Weld(ent,rag,0,rag:TranslateBoneToPhysBone(rag:LookupBone("ValveBiped.Bip01_Head1")),0,true,false)

		rag:DeleteOnRemove(ent)
		ent:CallOnRemove("MaskNo",function()
			if IsValid(rag) then
				rag.Mask = nil
			end
		end)
	end
	rag:AddEFlags(EFL_NO_DAMAGE_FORCES)
	if IsValid(rag:GetPhysicsObject()) then
		rag:GetPhysicsObject():SetMass(CustomWeight[rag:GetModel()] or 15)
	end
	rag:SetNWString("Mask",self:GetNWString("Mask"))
	rag:SetNWString("Bodyvest",self:GetNWString("Bodyvest"))
	rag:SetNWString("Helmet",self:GetNWString("Bodyvest"))
	rag:Activate()
	rag:SetNWEntity("RagdollOwner", self)
	local vel = self:GetVelocity()/1
	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local physobj = rag:GetPhysicsObjectNum( i )
		local ragbonename = rag:GetBoneName(rag:TranslatePhysBoneToBone(i))
		local bone = self:LookupBone(ragbonename)
		if(bone)then
			local bonemat = self:GetBoneMatrix(bone)
			if(bonemat)then
				local bonepos = bonemat:GetTranslation()
				local boneang = bonemat:GetAngles()
				physobj:SetPos( bonepos,true )
				physobj:SetAngles( boneang )
				if !self:Alive() then vel=vel end
				physobj:AddVelocity( vel )
			end
		end
	end

	if IsValid(self.wep) then
		self.wep.rag = rag
	end

	self.fakeragdoll = rag
	self:SetNWEntity("Ragdoll", rag )
	if self.lasthitgroup and IsValid(rag:GetPhysicsObject()) then
		if self.LastDMGInfo then
			local dmgInfo = self.LastDMGInfo
			local force = dmgInfo:GetDamageForce()
			-- Cap the force to prevent flying, keep it subtle
			local maxForce = 3000
			if force:Length() > maxForce then
				force = force:GetNormalized() * maxForce
			end
			
			local boneName = self.LastHitBoneName
			local physBone = 0
			if boneName then
				local boneId = rag:LookupBone(boneName)
				if boneId then
					physBone = rag:TranslateBoneToPhysBone(boneId)
				end
			end
			
			local phys = rag:GetPhysicsObjectNum(physBone)
			if IsValid(phys) then
				-- Apply force to the specific limb to create natural spin/knockback
				phys:ApplyForceCenter(force * 0.5) 
			end
		end
	end
	if not self:Alive() then
		net.Start("pophead")
		net.WriteEntity(rag)
		net.Send(self)
        rag.Info=self.Info
        if IsValid(self:GetActiveWeapon()) then
            self.curweapon = nil
            if table.HasValue(Guns,self:GetActiveWeapon():GetClass()) then
				self.curweapon = self:GetActiveWeapon():GetClass()
				SpawnWeapon(self,self:GetActiveWeapon():Clip1())
				rag.curweapon = self:GetActiveWeapon():GetClass()
			end
        end
        rag.Info=self.Info
        rag.curweapon=self.curweapon
        rag:SetFlexWeight(9,0)
		if checkAllBleedOuts_bolshe(self, 0) then
			rag.IsBleeding=true
			rag.bloodNext = CurTime()
			rag.Blood = self.Blood
			table.insert(BleedingEntities,rag)
		end
		if IsValid(rag.bull) then
			rag.bull:Remove()
		end
        rag:SetNWBool("Dead", true)
		self.fakeragdoll = nil
		--if not self:GetActiveWeapon():IsValid() then return rag end
		net.Start("ebal_chellele")
		net.WriteEntity(rag)
		net.WriteEntity(rag.curweapon)
		net.Broadcast()
    else
		if not self:GetActiveWeapon():IsValid() then return rag end
		net.Start("ebal_chellele")
		net.WriteEntity(self)
		net.WriteString(self:GetActiveWeapon():GetClass())
		net.Broadcast()
	end
	return rag
end

hook.Add("OnPlayerHitGround","GovnoJopa",function(ply,a,b,speed)
	if speed > 200 then
		if hook.Run("Should Fake Ground",ply) ~= nil then return end

		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ply:GetPos() - Vector(0,0,10)
		tr.mins = ply:OBBMins()
		tr.maxs = ply:OBBMaxs()
		tr.filter = ply
		local traceResult = util.TraceHull(tr)
		if traceResult.Entity:IsPlayer() and not traceResult.Entity.fake then
			Faking(traceResult.Entity)
		end
	end
end)

local CurTime = CurTime
hook.Add("StartCommand","asdfgghh",function(ply,cmd)
	local rag = ply:GetNWEntity("Ragdoll")
	if (ply.GotUp or 0) - CurTime() > -0.1 and not IsValid(rag) then cmd:AddKey(IN_DUCK) end
	-- if IsValid(rag) then cmd:RemoveKey(IN_DUCK) end
end)

hook.Add( "KeyPress", "Shooting", function( ply, key )
	if !ply:Alive() or ply.Otrub or !ply.fake then return end
	if ply.FakeShooting and !weapons.Get(ply.curweapon).Primary.Automatic then
		if( key == IN_ATTACK )then
		end
	end

	if(key == IN_RELOAD)then
		Reload(ply.wep)
	end
end )

local LeftFingers = {
	"ValveBiped.Bip01_L_Finger1", "ValveBiped.Bip01_L_Finger11", "ValveBiped.Bip01_L_Finger12",
	"ValveBiped.Bip01_L_Finger2", "ValveBiped.Bip01_L_Finger21", "ValveBiped.Bip01_L_Finger22",
	"ValveBiped.Bip01_L_Finger3", "ValveBiped.Bip01_L_Finger31", "ValveBiped.Bip01_L_Finger32",
	"ValveBiped.Bip01_L_Finger4", "ValveBiped.Bip01_L_Finger41", "ValveBiped.Bip01_L_Finger42"
}
local LeftThumb = {
	"ValveBiped.Bip01_L_Finger0", "ValveBiped.Bip01_L_Finger01", "ValveBiped.Bip01_L_Finger02"
}
local RightFingers = {
	"ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11", "ValveBiped.Bip01_R_Finger12",
	"ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21", "ValveBiped.Bip01_R_Finger22",
	"ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31", "ValveBiped.Bip01_R_Finger32",
	"ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41", "ValveBiped.Bip01_R_Finger42"
}
local RightThumb = {
	"ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02"
}

local function SetFingers(rag, hand, type)
	if not IsValid(rag) then return end
	local val = (type == "grab")
	if hand == "left" then
		rag.ZacLeftGrip = val
	elseif hand == "right" then
		rag.ZacRightGrip = val
	end
end

local function ProcessFingerLerp(rag)
	local dt = FrameTime() * 10
	
	local lTarget = rag.ZacLeftGrip and Angle(0, -50, 0) or Angle(0,0,0)
	local lThumb = rag.ZacLeftGrip and Angle(0, 50, 0) or Angle(0,0,0)
	
	local rTarget = rag.ZacRightGrip and Angle(0, -50, 0) or Angle(0,0,0)
	local rThumb = rag.ZacRightGrip and Angle(0, 50, 0) or Angle(0,0,0)
	
	for _, b in ipairs(LeftFingers) do
		local bone = rag:LookupBone(b)
		if bone then rag:ManipulateBoneAngles(bone, LerpAngle(dt, rag:GetManipulateBoneAngles(bone), lTarget)) end
	end
	for _, b in ipairs(LeftThumb) do
		local bone = rag:LookupBone(b)
		if bone then rag:ManipulateBoneAngles(bone, LerpAngle(dt, rag:GetManipulateBoneAngles(bone), lThumb)) end
	end
	
	for _, b in ipairs(RightFingers) do
		local bone = rag:LookupBone(b)
		if bone then rag:ManipulateBoneAngles(bone, LerpAngle(dt, rag:GetManipulateBoneAngles(bone), rTarget)) end
	end
	for _, b in ipairs(RightThumb) do
		local bone = rag:LookupBone(b)
		if bone then rag:ManipulateBoneAngles(bone, LerpAngle(dt, rag:GetManipulateBoneAngles(bone), rThumb)) end
	end
end

local dvec = Vector(0,0,-64)
hook.Add("Player Think","FakeControl",function(ply,time) --управление в фейке
	if not ply:Alive() then return end
	local rag = ply:GetNWEntity("Ragdoll")

	if not IsValid(rag) or not ply:Alive() then return end
	ProcessFingerLerp(rag)
	local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
	if not bone then return end
	if IsValid(ply.bull) then
		ply.bull:SetPos(rag:GetPos())
	end
	local head1 = rag:GetBonePosition(bone) + dvec
	ply:SetPos(head1)
	ply:SetNWBool("fake",ply.fake)
	local deltatime = CurTime()-(rag.ZacLastCallTime or CurTime())
	rag.ZacLastCallTime=CurTime()
	local eyeangs = ply:EyeAngles()
	local head = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_Head1" )) )
	local pelvis = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_Pelvis" )) )
	local dist = (rag:GetAttachment(rag:LookupAttachment( "eyes" )).Ang:Forward()):Distance(ply:GetAimVector()*10000)
	local distmod = math.Clamp(1-(dist/20000),0.1,1)
	local lookat = LerpVector(distmod,rag:GetAttachment(rag:LookupAttachment( "eyes" )).Ang:Forward()*100000,ply:GetAimVector()*100000)
	local attachment = rag:GetAttachment( rag:LookupAttachment( "eyes" ) )
	local LocalPos, LocalAng = WorldToLocal( lookat, Angle( 0, 60, 0 ), attachment.Pos, attachment.Ang )
	if !ply.Otrub then rag:SetEyeTarget( LocalPos ) else rag:SetEyeTarget( Vector(0,0,0) ) end
	if ply:Alive() then
		--RagdollOwner(rag):SetMoveParent( rag )
		--RagdollOwner(rag):SetParent( rag )
	if !ply.Otrub and !ply.Hit["highspine"] then
		if ply:KeyDown( IN_JUMP ) and (table.Count(constraint.FindConstraints( ply:GetNWEntity("Ragdoll"), 'Rope' ))>0 or ((rag.IsWeld or 0) > 0)) and ply.stamina['leg']>20 and (ply.lastuntietry or 0) < CurTime() then
			ply.lastuntietry = CurTime() + 2
			
			rag.IsWeld = math.max((rag.IsWeld or 0) - 0.1,0)

			local RopeCount = table.Count(constraint.FindConstraints( ply:GetNWEntity("Ragdoll"), 'Rope' ))
			Ropes = constraint.FindConstraints( ply:GetNWEntity("Ragdoll"), 'Rope' )
			Try = math.random(1,10*RopeCount)
			ply.stamina['leg']=ply.stamina['leg'] - 5
			local phys = rag:GetPhysicsObjectNum( 1 )
			local speed = 200
			local shadowparams = {
				secondstoarrive=0.5,
				pos=phys:GetPos()+phys:GetAngles():Forward()*20,
				angle=phys:GetAngles(),
				maxangulardamp=30,
				maxspeeddamp=30,
				maxangular=90,
				maxspeed=speed,
				teleportdistance=0,
				deltatime=0.01,
			}
			phys:Wake()
			phys:ComputeShadowControl(shadowparams)
			if Try > (7*RopeCount) or ((rag.IsWeld or 0) > 0) then
				if RopeCount>1 or (rag.IsWeld or 0 > 0) then
					if RopeCount > 1 then
						ply:ChatPrint("Rope remaining: "..RopeCount - 1)
					end
					if (rag.IsWeld or 0) > 0 then
						ply:ChatPrint("Nails remaining: "..tostring(math.ceil(rag.IsWeld)))
						ply.BleedOuts["right_leg"] = ply.BleedOuts["right_leg"] + 10
						ply.pain_add = ply.pain_add + 10
					end
				else
					ply:ChatPrint("Ты развязался") --!! Я без интернета сижу без переводчика забыл как на английском..бля
				end
				
				if Ropes and Ropes[1] and Ropes[1].Constraint then
    				Ropes[1].Constraint:Remove()
				end
				rag:EmitSound("snd_jack_hmcd_ducttape.wav",90,50,0.5,CHAN_AUTO)
			end
		end
		if(ply:KeyDown(IN_ATTACK))then
            if !ply.FakeShooting then
				local phys = rag:GetPhysicsObjectNum( 5 )	
				local ang=ply:EyeAngles()
				ang:RotateAroundAxis(eyeangs:Forward(),90)
				local shadowparams = {
					secondstoarrive=0.5,
					pos=head:GetPos()+eyeangs:Up()*-10+eyeangs:Forward()*(120/math.Clamp(rag:GetVelocity():Length()/300,1,6)),
					angle=ang,
					maxangular=370,
					maxangulardamp=100,
					maxspeeddamp=10,
					maxspeed=110,
					teleportdistance=0,
					deltatime=deltatime,
					}
				phys:Wake()
				phys:ComputeShadowControl(shadowparams)
			end
		end

		if ply.FakeShooting and weapons.Get(ply.curweapon).Primary.Automatic then
			if(ply:KeyDown(IN_ATTACK))then--KeyDown if an automatic gun
			end
		end
		if(ply:KeyDown(IN_ATTACK2))then
			local physa = rag:GetPhysicsObjectNum( 7 )
			local phys = rag:GetPhysicsObjectNum( 5 ) --rhand
			local ang=ply:EyeAngles() --LerpAngle(0.5,ply:EyeAngles(),ply:GetNWEntity("DeathRagdoll"):GetAttachment(1).Ang)

			if ply.FakeShooting then
				ang:RotateAroundAxis(eyeangs:Forward(),180)
			else
				ang:RotateAroundAxis(eyeangs:Forward(),90)
			end


			local shadowparams = {
					secondstoarrive=0.5,
					pos=head:GetPos()+eyeangs:Forward()*(100/math.Clamp(rag:GetVelocity():Length()/300,1,6)),
					angle=ang,
					maxangular=370,
					maxangulardamp=100,
					maxspeeddamp=10,
					maxspeed=110,
					teleportdistance=0,
					deltatime=deltatime,
			}
			physa:Wake()
			if (!ply.suiciding or TwoHandedOrNo[ply.curweapon]) then
				if TwoHandedOrNo[ply.curweapon] and IsValid(ply.wep) then
					shadowparams.angle:RotateAroundAxis(eyeangs:Up(),45)
					shadowparams.pos=shadowparams.pos+eyeangs:Right()*50
					shadowparams.pos=shadowparams.pos+eyeangs:Up()*40
					shadowparams.angle:RotateAroundAxis(eyeangs:Forward(),-910)
					ply.wep:GetPhysicsObject():ComputeShadowControl(shadowparams)
					--shadowparams.maxspeed=20
					phys:ComputeShadowControl(shadowparams) --if 2handed
					shadowparams.pos=head:GetPos()
					shadowparams.angle=ang
					ply.wep:GetPhysicsObject():ComputeShadowControl(shadowparams)
				else
					physa:ComputeShadowControl(shadowparams)
				end
			else
				if ply.FakeShooting and IsValid(ply.wep) then
					shadowparams.maxspeed=500
					shadowparams.maxangular=500
					shadowparams.pos=head:GetPos()-ply.wep:GetAngles():Forward()*12
					shadowparams.angle=ply.wep:GetPhysicsObject():GetAngles()
					ply.wep:GetPhysicsObject():ComputeShadowControl(shadowparams)
					physa:ComputeShadowControl(shadowparams)
				end
			end
			--[[physa:ComputeShadowControl(shadowparams)
			if TwoHandedOrNo[ply.curweapon] then
				shadowparams.maxspeed=90
				ply.wep:GetPhysicsObject():ComputeShadowControl(shadowparams)
				shadowparams.maxspeed=20
				shadowparams.angle:RotateAroundAxis(eyeangs:Forward(),90)
				phys:ComputeShadowControl(shadowparams) --if 2handed
			end--]]
		end
		if ply:KeyDown(IN_DUCK) then
			local lthigh = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_L_Thigh" )) )
			local rthigh = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_R_Thigh" )) )
			local lcalf = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_L_Calf" )) )
			local rcalf = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_R_Calf" )) )
			
			if IsValid(lthigh) and IsValid(rthigh) then
				local angs = ply:EyeAngles()
				
				local legAng1 = Angle(0, 0, 0)
				local legAng2 = Angle(0, 0, 0)
				
				legAng1:Set(angs)
				legAng1:RotateAroundAxis(angs:Right(), 80)
				legAng1:RotateAroundAxis(angs:Forward(), -40)
				legAng1:RotateAroundAxis(angs:Up(), -70)
				
				legAng2:Set(angs)
				legAng2:RotateAroundAxis(angs:Right(), 60)
				legAng2:RotateAroundAxis(angs:Forward(), -40)
				legAng2:RotateAroundAxis(angs:Up(), -70)
				
				local shadowparams = {
					secondstoarrive=0.001,
					pos=nil,
					angle=legAng1,
					maxangular=200,
					maxangulardamp=10,
					deltatime=deltatime,
				}
				lthigh:Wake()
				lthigh:ComputeShadowControl(shadowparams)
				
				shadowparams.angle = legAng2
				rthigh:Wake()
				rthigh:ComputeShadowControl(shadowparams)
				
				if IsValid(lcalf) and IsValid(rcalf) then
					local calfAng1 = Angle(0, 0, 0)
					local calfAng2 = Angle(0, 0, 0)
					
					calfAng1:Set(legAng1)
					calfAng1:RotateAroundAxis(angs:Right(), -90)
					
					calfAng2:Set(legAng2)
					calfAng2:RotateAroundAxis(angs:Right(), -90)
					
					shadowparams.angle = calfAng1
					shadowparams.maxangular = 150
					lcalf:Wake()
					lcalf:ComputeShadowControl(shadowparams)
					
					shadowparams.angle = calfAng2
					rcalf:Wake()
					rcalf:ComputeShadowControl(shadowparams)
				end
			end
		end

		if ply:KeyDown( IN_JUMP ) and !rag.jumpdelay then
			rag.jumpdelay = true
			timer.Simple(1.3, function()
				rag.jumpdelay = false
			end)
			local phys = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_Pelvis" )) )
			local angs = ply:EyeAngles()
			local shadowparams = {
				secondstoarrive=0.01,
				pos=head:GetPos(),
				angle=head:GetAngles():Forward(),
				maxangulardamp=100,
				maxspeeddamp=100,
				maxangular=370,
				maxspeed=400,
				teleportdistance=0,
				deltatime=deltatime,
			}
			phys:Wake()
			phys:ComputeShadowControl(shadowparams)
		end

		if(ply:KeyDown(IN_USE))then
			local phys = head
			local angs = ply:EyeAngles()
			angs:RotateAroundAxis(angs:Forward(),90)
			angs:RotateAroundAxis(angs:Up(),90)
			local shadowparams = {
				secondstoarrive=0.2,
				pos=head:GetPos()+vector_up*(20/math.Clamp(rag:GetVelocity():Length()/300,1,12)),
				angle=angs,
				maxangulardamp=10,
				maxspeeddamp=10,
				maxangular=370,
				maxspeed=40,
				teleportdistance=0,
				deltatime=deltatime,
			}
			head:Wake()
			head:ComputeShadowControl(shadowparams)
		end

		end
		if (ply:KeyDown(IN_SPEED)) and !RagdollOwner(rag).Otrub then
			local bone = rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_L_Hand" ))
			local phys = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_L_Hand" )) )
			if(!IsValid(rag.ZacConsLH) and (!rag.ZacNextGrLH || rag.ZacNextGrLH<=CurTime()))then
				rag.ZacNextGrLH=CurTime()+0.1
				for i=1,3 do
					local offset = phys:GetAngles():Up()*5
					if(i==2)then
						offset = phys:GetAngles():Right()*5
					end
					if(i==3)then
						offset = phys:GetAngles():Right()*-5
					end
					local traceinfo={
						start=phys:GetPos(),
						endpos=phys:GetPos()+offset,
						filter=rag,
						output=trace,
					}
					local trace = util.TraceLine(traceinfo)
					if(trace.Hit and !trace.HitSky)then
						local cons = constraint.Weld(rag,trace.Entity,bone,trace.PhysicsBone,0,false,false)
						if(IsValid(cons))then
							rag.ZacConsLH=cons
							rag:EmitSound("physics/body/body_medium_impact_soft"..math.random(1,7)..".wav")
							SetFingers(rag, "left", "grab")
						end
						break
					end
				end
			end
		else
			if(IsValid(rag.ZacConsLH))then
				rag.ZacConsLH:Remove()
				rag.ZacConsLH=nil
				SetFingers(rag, "left", "release")
			end
		end
		if(ply:KeyDown(IN_WALK) and !ply.RightArmbroke) and !RagdollOwner(rag).Otrub then
			local bone = rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_R_Hand" ))
			local phys = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_R_Hand" )) )
			if(!IsValid(rag.ZacConsRH) and (!rag.ZacNextGrRH || rag.ZacNextGrRH<=CurTime()))then
				rag.ZacNextGrRH=CurTime()+0.1
				for i=1,3 do
					local offset = phys:GetAngles():Up()*5
					if(i==2)then
						offset = phys:GetAngles():Right()*5
					end
					if(i==3)then
						offset = phys:GetAngles():Right()*-5
					end
					local traceinfo={
						start=phys:GetPos(),
						endpos=phys:GetPos()+offset,
						filter=rag,
						output=trace,
					}
					local trace = util.TraceLine(traceinfo)
					if(trace.Hit and !trace.HitSky)then
						local cons = constraint.Weld(rag,trace.Entity,bone,trace.PhysicsBone,0,false,false)
						if(IsValid(cons))then
							rag.ZacConsRH=cons
							rag:EmitSound("physics/body/body_medium_impact_soft"..math.random(1,7)..".wav")
							SetFingers(rag, "right", "grab")
						end
						break
					end
				end
			end
		else
			if(IsValid(rag.ZacConsRH))then
				rag.ZacConsRH:Remove()
				rag.ZacConsRH=nil
				SetFingers(rag, "right", "release")
			end
		end
		if(ply:KeyDown(IN_FORWARD) and IsValid(rag.ZacConsLH))then
			local phys = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_Spine" )) )
			local lh = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_L_Hand" )) )
			local angs = ply:EyeAngles()
			angs:RotateAroundAxis(angs:Forward(),90)
			angs:RotateAroundAxis(angs:Up(),90)
			local speed = 500
			
			if(rag.ZacConsLH.Ent2:GetVelocity():LengthSqr()<1000) then
				local shadowparams = {
					secondstoarrive=1.1,
					pos=lh:GetPos(),
					angle=phys:GetAngles(),
					maxangulardamp=10,
					maxspeeddamp=10,
					maxangular=50,
					maxspeed=speed,
					teleportdistance=0,
					deltatime=deltatime,
				}
				phys:Wake()
				phys:ComputeShadowControl(shadowparams)
			end
		end
		if(ply:KeyDown(IN_FORWARD) and IsValid(rag.ZacConsRH))then
			local phys = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_Spine" )) )
			local rh = rag:GetPhysicsObjectNum( rag:TranslateBoneToPhysBone(rag:LookupBone( "ValveBiped.Bip01_R_Hand" )) )
			local angs = ply:EyeAngles()
			angs:RotateAroundAxis(angs:Forward(),90)
			angs:RotateAroundAxis(angs:Up(),90)
			local speed = 500
			
			if(rag.ZacConsRH.Ent2:GetVelocity():LengthSqr()<1000)then
				local shadowparams = {
					secondstoarrive=1.1,
					pos=rh:GetPos(),
					angle=phys:GetAngles(),
					maxangulardamp=10,
					maxspeeddamp=10,
					maxangular=50,
					maxspeed=speed,
					teleportdistance=0,
					deltatime=deltatime,
				}
				phys:Wake()
				phys:ComputeShadowControl(shadowparams)
			end
		end
		if(ply:KeyDown(IN_BACK) and IsValid(rag.ZacConsLH))then
			local phys = rag:GetPhysicsObjectNum( 1 )
			local chst = rag:GetPhysicsObjectNum( 0 )
			local angs = ply:EyeAngles()
			angs:RotateAroundAxis(angs:Forward(),90)
			angs:RotateAroundAxis(angs:Up(),90)
			local speed = 450
			
			if(rag.ZacConsLH.Ent2:GetVelocity():LengthSqr()<1000)then
				local shadowparams = {
					secondstoarrive=0.3,
					pos=chst:GetPos(),
					angle=phys:GetAngles(),
					maxangulardamp=10,
					maxspeeddamp=10,
					maxangular=50,
					maxspeed=speed,
					teleportdistance=0,
					deltatime=deltatime,
				}
				phys:Wake()
				phys:ComputeShadowControl(shadowparams)
			end
		end
		if(ply:KeyDown(IN_BACK) and IsValid(rag.ZacConsRH))then
			local phys = rag:GetPhysicsObjectNum( 1 )
			local chst = rag:GetPhysicsObjectNum( 0 )
			local angs = ply:EyeAngles()
			angs:RotateAroundAxis(angs:Forward(),90)
			angs:RotateAroundAxis(angs:Up(),90)
			local speed = 450
			
			if(rag.ZacConsRH.Ent2:GetVelocity():LengthSqr()<1000)then
				local shadowparams = {
					secondstoarrive=0.3,
					pos=chst:GetPos(),
					angle=phys:GetAngles(),
					maxangulardamp=10,
					maxspeeddamp=10,
					maxangular=50,
					maxspeed=speed,
					teleportdistance=0,
					deltatime=deltatime,
				}
				phys:Wake()
				phys:ComputeShadowControl(shadowparams)
			end
		end
	end
end)

hook.Add("Player Think","VelocityPlayerFallOnPlayerCheck",function(ply,time)
	local speed = ply:GetVelocity():Length()
	if ply:GetMoveType() != MOVETYPE_NOCLIP and not ply.fake and not ply:HasGodMode() and ply:Alive() then
		if speed < 550 or (IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "wep_jack_hmcd_fastzombhands") then return end
		if hook.Run("Should Fake Velocity",ply,speed) ~= nil then return end

		Faking(ply)
	end
end)

util.AddNetworkString("ebal_chellele")
hook.Add("PlayerSwitchWeapon","wep",function(ply,oldwep,newwep)
	if GAMEMODE.NoGun then return true end
	if ply.in_handcuff then return true end
	if ply.Otrub then return true end

	if ply.fake then
		if IsValid(ply.Info.ActiveWeapon2) and IsValid(ply.wep) and ply.wep.RoundsInMag~=nil and ply.wep.Amt~=nil and ply.wep.AmmoType~=nil then
			ply.Info.ActiveWeapon2:SetClip1((ply.wep.RoundsInMag or 0))
			ply:SetAmmo((ply.wep.Amt or 0), (ply.wep.AmmoType or 0))
		end

		if table.HasValue(Guns,newwep:GetClass()) then
			if IsValid(ply.wep) then DespawnWeapon(ply) end
			ply:SetActiveWeapon(newwep)
			ply.Info.ActiveWeapon=newwep
			ply.curweapon=newwep:GetClass()
			SavePlyInfo(ply)
			ply:SetActiveWeapon(nil)
			SpawnWeapon(ply)
			ply.FakeShooting=true
		else
			if IsValid(ply.wep) then DespawnWeapon(ply) end
			ply:SetActiveWeapon(nil)
			ply.curweapon=nil
			ply.FakeShooting=false
		end
		net.Start("ebal_chellele")
		net.WriteEntity(ply)
		net.WriteString(ply.curweapon or "")
		net.Broadcast()
		return true
	end
end)

function PlayerMeta:HuySpectate()
	local ply = self
	ply:Spectate(OBS_MODE_CHASE)
	ply:UnSpectate()

	ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	ply:SetMoveType(MOVETYPE_OBSERVER)
end

concommand.Add("checha_getotrub",function(ply,cmd,args)
	local huyply = args[1] and player.GetListByName(args[1])[1] or ply
	print(huyply.Otrub)
end)

concommand.Add("checha_setarmor",function(ply,cmd,args)
	local huyply = args[1] and player.GetListByName(args[1])[1] or ply
	huyply:SetNWString(args[2], args[3])
end)

hook.Add("UpdateAnimation","huy",function(ply,event,data)
	ply:RemoveGesture(ACT_GMOD_NOCLIP_LAYER)
end)

--[[hook.Add("Player Think","holdentity",function(ply,time)
	if IsValid(ply.holdEntity) then

	end
end)]]