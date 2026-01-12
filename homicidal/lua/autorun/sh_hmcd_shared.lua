
AddCSLuaFile()

HMCD_REMOVEEQUIPMENT=-1
HMCD_ARMOR3A=1
HMCD_ARMOR3=2
HMCD_ACH=3
HMCD_GASMASK=4
HMCD_FLASHLIGHT=5
HMCD_PISTOLSUPP=6
HMCD_RIFLESUPP=7
HMCD_SHOTGUNSUPP=8
HMCD_LASERSMALL=9
HMCD_LASERBIG=10
HMCD_AIMPOINT=11
HMCD_EOTECH=12
HMCD_KOBRA=13
HMCD_PBS=14
HMCD_OSPREY=15
HMCD_BALLISTICMASK=16
HMCD_NVG=17
HMCD_MOTHELMET=18

HMCD_EquipmentNames = {
	[1] = "Level IIIA Armor",
	[2] = "Level III Armor",
	[3] = "Advanced Combat Helmet",
	[4] = "M40 Gas Mask",
	[5] = "Maglite ML300LX-S3CC6L Flashlight",
	[6] = "Cobra M2 Suppressor",
	[7] = "Hybrid 46 Suppressor",
	[8] = "Salvo 12 Suppressor",
	[9] = "Marcool JG5 Laser Sight",
	[10] = "AN/PEQ-15 Laser Sight",
	[11] = "Aimpoint CompM2 Sight",
	[12] = "EOTech 552.A65 Sight",
	[13] = "Kobra Sight",
	[14] = "PBS-1 Suppressor",
	[15] = "Osprey 45 Suppressor",
	[16] = "Ballistic Mask",
	[17] = "Ground Panoramic Night Vision Goggles",
	[18] = "Bell Bullitt Motorcycle Helmet"
}

HMCD_AmmoWeights={
	["AlyxGun"]=4,
	["Pistol"]=12,
	["HelicopterGun"]=30,
	["357"]=15,
	["AirboatGun"]=3,
	["Buckshot"]=60,
	["AR2"]=50,
	["MP5_Grenade"]=60,
	["SMG1"]=18,
	["Gravity"]=18,
	["SniperRound"]=20,
	["XBowBolt"]=22,
	["Thumper"]=26,
	["StriderMinigun"]=20,
	["RPG_Round"]=150,
	["9mmRound"]=8,
	["Hornet"]=30,
	["SniperPenetratedRound"]=20
}

HMCD_AmmoNames={
	["AlyxGun"]="5.7x16mm (.22 long rifle)",
	["Pistol"]="9x19mm (9mm luger/parabellum)",
	["357"]="9x29mmR (.38 special)",
	["SMG1"]="5.56x45mm (.223 remington)",
	["Buckshot"]="18.5x70mmR (12 gauge shotshell)",
	["AR2"]="7x57mm (7mm mauser)",
	["XBowBolt"]="6x735mm broadhead hunting arrow",
	["AirboatGun"]="2x89mm Carpentry Nail",
	["RPG_Round"]="40mm Rocket",
	["StriderMinigun"]="7.62x51 NATO",
	["HelicopterGun"]="4.6x30mm",
	["SniperRound"]="7.62x39mm",
	["Gravity"]="Pulse Slug",
	["Thumper"]="300mm Rebar",
	["MP5_Grenade"]="Energy Ball",
	["SniperPenetratedRound"]="X26 Taser Cartridge",
	["9mmRound"]="9×22mm P.A.",
	["Hornet"]="Flexible Baton Round"
}

local atts_ents = {
	[HMCD_ARMOR3A]="ent_jack_hmcd_softarmor",
	[HMCD_ARMOR3]="ent_jack_hmcd_hardarmor",
	[HMCD_ACH]="ent_jack_hmcd_helmet",
	[HMCD_GASMASK]="ent_jack_hmcd_gasmask",
	[HMCD_PISTOLSUPP]="ent_jack_hmcd_pistolsuppressor",
	[HMCD_RIFLESUPP]="ent_jack_hmcd_riflesuppressor",
	[HMCD_SHOTGUNSUPP]="ent_jack_hmcd_shotgunsuppressor",
	[HMCD_LASERSMALL]="ent_jack_hmcd_laser",
	[HMCD_LASERBIG]="ent_jack_hmcd_laserbig",
	[HMCD_KOBRA]="ent_jack_hmcd_kobra",
	[HMCD_AIMPOINT]="ent_jack_hmcd_aimpoint",
	[HMCD_EOTECH]="ent_jack_hmcd_eotech",
	[HMCD_PBS]="ent_jack_hmcd_aksuppressor",
	[HMCD_OSPREY]="ent_jack_hmcd_uspsuppressor",
	[HMCD_FLASHLIGHT]="ent_jack_hmcd_flashlight",
	[HMCD_BALLISTICMASK]="ent_jack_hmcd_ballisticmask",
	[HMCD_NVG]="ent_jack_hmcd_nvg",
	[HMCD_MOTHELMET]="ent_jack_hmcd_mothelmet"
}

local atts_simplified={
	[HMCD_PISTOLSUPP]="Suppressor",
	[HMCD_RIFLESUPP]="Suppressor",
	[HMCD_SHOTGUNSUPP]="Suppressor",
	[HMCD_LASERSMALL]="Laser",
	[HMCD_LASERBIG]="Laser",
	[HMCD_KOBRA]="Sight",
	[HMCD_AIMPOINT]="Sight2",
	[HMCD_EOTECH]="Sight3",
	[HMCD_PBS]="Suppressor",
	[HMCD_OSPREY]="Suppressor"
}

if SERVER then
	util.AddNetworkString("hmcd_equipment")
	util.AddNetworkString("ragplayercolor")
	util.AddNetworkString("ebal_chellele")

	concommand.Add("hmcd_attachrequest",function(ply,cmd,args)
		if not ply.Equipment then ply.Equipment={} end
		local attachment=math.Round(args[1])
		local wep=ply:GetActiveWeapon()
		
		if not IsValid(wep) then return end

		if wep:GetNWBool(atts_simplified[attachment]) then
			if ply.Equipment[HMCD_EquipmentNames[attachment]] then ply:PrintMessage(HUD_PRINTTALK, "You already have this attachment!") return end
			wep:SetNWBool(atts_simplified[attachment],false)
			ply.Equipment[HMCD_EquipmentNames[attachment]]=true
			if (wep:GetNWBool("Rail", false) == true) and (attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT or attachment==HMCD_EOTECH) then
				wep:SetNWBool("Rail", false)
			end
			net.Start("hmcd_equipment")
			net.WriteInt(attachment,6)
			net.WriteBit(true)
			net.Send(ply)
		else
			if attachment==HMCD_LASERBIG and (wep:GetNWBool("Sight") or wep:GetNWBool("Sight2") or wep:GetNWBool("Sight3")) and not(wep.MultipleRIS) then
				ply:PrintMessage(HUD_PRINTTALK, "You can't apply this attachment! There isn't enough space!")
				return
			end
			if (attachment==HMCD_EOTECH or attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT) and wep:GetNWBool("Laser") and not(wep.MultipleRIS) then
				ply:PrintMessage(HUD_PRINTTALK, "You can't apply this attachment! There isn't enough space!")
				return
			end
			if (attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT or attachment==HMCD_EOTECH) and (wep:GetNWBool("Sight") or wep:GetNWBool("Sight2") or wep:GetNWBool("Sight3")) then
				ply:PrintMessage(HUD_PRINTTALK, "You already have a sight attached!")
				return
			end
			if wep:GetClass() == "wep_jack_hmcd_akm" and (attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT or attachment==HMCD_EOTECH) then
				wep:SetNWBool("Rail", true)
			end
			wep:SetNWBool(atts_simplified[attachment],true)
			ply.Equipment[HMCD_EquipmentNames[attachment]]=false
			net.Start("hmcd_equipment")
			net.WriteInt(attachment, 6)
			net.WriteBit(false)
			net.Send(ply)
		end
	end)

	concommand.Add("hmcd_droprequest",function(ply,cmd,args)
		if not ply.Equipment then ply.Equipment={} end
		local attachment=math.Round(args[1])
		local wep=ply:GetActiveWeapon()

		local attachmentsuka=ents.Create(atts_ents[attachment])
		attachmentsuka.HmcdSpawned=true
		attachmentsuka:SetPos(ply:GetShootPos()+ply:GetAimVector()*20)
		attachmentsuka:Spawn()
		attachmentsuka:Activate()
		attachmentsuka:GetPhysicsObject():SetVelocity(ply:GetVelocity()+ply:GetAimVector()*100)

		-- вот эта нижняя строка самая длинная ее не надо разбирать, это убирание рэйла при убирании прицела
		if IsValid(wep) then
			if wep:GetClass() == "wep_jack_hmcd_akm" and (attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT or attachment==HMCD_EOTECH) then wep:SetNWBool("Rail", false) end
			if attachment != 5 then wep:SetNWBool(atts_simplified[attachment],false) end
		end
		if attachment == 5 then ply:AllowFlashlight(false) end

		ply.Equipment[HMCD_EquipmentNames[attachment]]=false
		net.Start("hmcd_equipment")
		net.WriteInt(attachment, 6)
		net.WriteBit(false)
		net.Send(ply)
	end)
end
