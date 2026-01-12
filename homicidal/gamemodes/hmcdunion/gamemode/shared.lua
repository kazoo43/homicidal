DeriveGamemode("sandbox")

GM.Name = "HOMICIDAL"
GM.Author = "By Kazoo and Crow, Successor to Cats Homicide. "
GM.Email = "N/A"
GM.Website = "https://discord.gg/Y8WgzQSM"
GM.TeamBased = true

GM.ZoneTimeToShrink = 120

function GM.GetZoneRadius()
	local dist_start = GetGlobalFloat("ZoneDistance", 0)
	if dist_start == 0 then return 999999 end
	
	local start_time = GetGlobalFloat("ZoneStartTime", 0)
	if start_time == 0 then return dist_start + 1024 end

	local dist = dist_start + 1024
	
	return (dist * math.max(((start_time + GAMEMODE.ZoneTimeToShrink) - CurTime()) / GAMEMODE.ZoneTimeToShrink, 0.025))
end

-- checha gm ints!!!
GM.DMTime = 10
GM.RoundName = "homicide"
GM.RoundNext = "homicide"
GM.RoundType = 2
GM.RoundState = 3
GM.Version = "V1"
GM.Traitor = nil
GM.MVP = nil

RunConsoleCommand("hostname", GM.Name)

-- round types hmcd
-- 1 = Standard
-- 2 = State of Emergency
-- 3 = Jihad
-- 4 = Wild West
-- 5 = Gun Free Zone

include("loader.lua")

GM.papkago("hmcdunion/gamemode/gm/")

function GM:CreateTeams()
	team.SetUp(1, "Players", Color(57,62,213))
end

PrecacheParticleSystem("blood_impact")
PrecacheParticleSystem("swb_muzzle")

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

blood_drop = {
	"blood/drop1.wav",
	"blood/drop2.wav",
	"blood/drop3.wav",
	"blood/drop4.wav"
}

Rounds = {
	"homicide",
	"homicide",
	"homicide",
	"homicide",
	"homicide",
	"homicide",
	"homicide",
	"homicide",
	"hl2",
	"dm"
}

TypeHit = {
	[DMG_BULLET] = "shot",
	[DMG_SNIPER] = "shot",
	[DMG_BUCKSHOT] = "shot",
	[DMG_SLASH] = "slash",
	[DMG_CLUB] = "club",
	[DMG_CRUSH] = "crush",
	[DMG_FALL] = "fall"
}

HitgroupReason = {
	[HITGROUP_HEAD] = "head",
	[HITGROUP_CHEST] = "chest",
	[HITGROUP_STOMACH] = "stomach",
	[HITGROUP_LEFTARM] = "left arm",
	[HITGROUP_RIGHTARM] = "right arm",
	[HITGROUP_LEFTLEG] = "left leg",
	[HITGROUP_RIGHTLEG] = "right leg"
}

DieReason = {
	[DMG_BURN] = "burnout.",
	[DMG_BULLET] = "bullet.",
	[DMG_SNIPER] = "bullet.",
	[DMG_BLAST] = "explosion",
	[DMG_CRUSH] = "crush.",
	[DMG_BUCKSHOT] = "bullet.",
	[DMG_SLASH] = "melee weapon.",
	[DMG_CLUB] = "melee weapon.",
	[DMG_FALL] = "falled.",
	[DMG_DROWN] = "drowned.",
	[DMG_POISON] = "poison."
}

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

HMCD_HelpRole = {
	["Traitor"] = "KILL'EM ALL!",
	["Bystander"] = "You innocent, just find traitor and kill him.",
	["Gunman"] = "You have a gun, kill traitor in your party.",
	["Fighter"] = "You fighter, kill all and stay alive.",
	["Rebel"] = "You're a rebel, kill the entire Alliance.",
	["Combine"] = "You're in the Alliance, kill all the rebels."
}

RoundsNormalise = {
	["homicide"] = "Homicide",
	["sandbox"] = "Sandbox",
	["hl2"] = "Homicide: Resistance Versus Combine",
	["dm"] = "Homicide: Deathmatch",
	["hl2coop"] = "Half-Life 2 Cooperative",
	["svo"] = "Special Military Operation"
}

DM_LoadoutMain = {
	"wep_jack_hmcd_akm",
	"wep_jack_hmcd_assaultrifle",
	"wep_jack_hmcd_rifle",
	"wep_jack_hmcd_sr25",
	"wep_jack_hmcd_mp7",
	"wep_jack_hmcd_mp5",
	"wep_jack_hmcd_dbarrel",
	-- "wep_jack_hmcd_remington", Бараны это дробовик стреляющий бинбегом
	"wep_jack_hmcd_shotgun",
	"wep_jack_hmcd_spas"
}

DM_LoadoutSecondary = {
	"wep_jack_hmcd_smallpistol",
	"wep_jack_hmcd_cz75a",
	"wep_jack_hmcd_glock17",
	"wep_jack_hmcd_usp",
	"wep_jack_hmcd_revolver",
	"wep_jack_hmcd_suppressed"
}


HL2_Loadout = {
	["Rebel"] = {
		["Medic"] = {"wep_jack_hmcd_oldgrenade_dm","wep_jack_hmcd_fooddrinkbig","wep_jack_hmcd_adrenaline","wep_jack_hmcd_medkit","wep_jack_hmcd_bandagebig","wep_jack_hmcd_painpills","wep_jack_hmcd_walkietalkie"},
		["Fighter"] = {"wep_jack_hmcd_oldgrenade_dm","wep_jack_hmcd_m67","wep_jack_hmcd_bandage","wep_jack_hmcd_painpills","wep_jack_hmcd_pocketknife","wep_jack_hmcd_riotshield","wep_jack_hmcd_walkietalkie","wep_jack_hmcd_riotshield"}
	},
	["Combine"] = {
		["Simple"] = {"wep_jack_hmcd_grenade","wep_jack_hmcd_adrenaline","wep_jack_hmcd_medkit","wep_jack_hmcd_bandagebig","wep_jack_hmcd_painpills"},
		["Elite"] = {"wep_jack_hmcd_grenade","wep_jack_hmcd_m67"},
		["Shotguner"] = {"wep_jack_hmcd_grenade","wep_jack_hmcd_m67"},
	}
}
HL2_LoadoutFire_Main = {
	["Rebel"] = {
		["Medic"] = {
			"wep_jack_hmcd_mp7",
			"wep_jack_hmcd_dbarrel",
			"wep_jack_hmcd_shotgun",
			"wep_jack_hmcd_spas"
		},
		["Fighter"] = {
			"wep_jack_hmcd_combinesniper",
			"wep_jack_hmcd_akm",
			"wep_jack_hmcd_rifle",
			"wep_jack_hmcd_mp7",
			"wep_jack_hmcd_mp5",
			"wep_jack_hmcd_dbarrel",
			"wep_jack_hmcd_shotgun",
			"wep_jack_hmcd_spas"
		},
	},
	["Combine"] = {
		["Simple"] = {
			"wep_jack_hmcd_ar2"
		},
		["Shotguner"] = {
			"wep_jack_hmcd_spas"
		},
		["Elite"] = {
			"wep_jack_hmcd_combinesniper",
			"wep_jack_hmcd_ar2"
		},
	}
}
HL2_LoadoutFire_Secondary = {
	["Rebel"] = {"wep_jack_hmcd_smallpistol","wep_jack_hmcd_usp"},
	["Combine"] = {"wep_jack_hmcd_usp"}
}

HMCD_Loadout_Firearms = {
	["Traitor"] = {
		[1] = {""},
		[2] = {"wep_jack_hmcd_suppressed"},
		[3] = {""},
		[4] = {"wep_jack_hmcd_revolver"},
		[5] = {""}
	},
	["Gunman"] = {
		[1] = {"wep_jack_hmcd_smallpistol"},
		[2] = {"wep_jack_hmcd_rifle"},
		[3] = {"wep_jack_hmcd_smallpistol"},
		[4] = {"wep_jack_hmcd_revolver"},
		[5] = {""}
	},
	["Bystander"] = {
		[1] = {""},
		[2] = {""},
		[3] = {""},
		[4] = {"wep_jack_hmcd_revolver"},
		[5] = {""}
	}
}

HMCD_Loadout = {
	["Traitor"] = {
		[1] = {
			"wep_jack_hmcd_knife",
			"wep_jack_hmcd_shuriken",
			"wep_jack_hmcd_poisonneedle",
			"wep_jack_hmcd_poisonpowder",
			"wep_jack_hmcd_ied",
			"wep_jack_hmcd_oldgrenade",
			"wep_jack_hmcd_smokebomb",
			"wep_jack_hmcd_fakepistol",
			"wep_jack_hmcd_adrenaline",
			"wep_jack_hmcd_jam",
			"wep_jack_hmcd_poisonliquid",
			"wep_jack_hmcd_poisongoo",
			"wep_jack_hmcd_poisoncanister",
			"wep_jack_hmcd_mask",
			"wep_jack_hmcd_beartrap"
		},
		[2] = {
			"wep_jack_hmcd_knife",
			"wep_jack_hmcd_poisonpowder",
			"wep_jack_hmcd_ied",
			"wep_jack_hmcd_oldgrenade",
			"wep_jack_hmcd_smokebomb",
			--"wep_jack_hmcd_suppressed",
			"wep_jack_hmcd_adrenaline",
			"wep_jack_hmcd_poisoncanister",
			"wep_jack_hmcd_poisonliquid"
		},
		[3] = {
			"wep_jack_hmcd_knife",
			"wep_jack_hmcd_ied",
			"wep_jack_hmcd_pipebombtest",
			"wep_jack_hmcd_jihad",
			"wep_jack_hmcd_molotovtest",
			"wep_jack_hmcd_oldgrenade",
			"wep_jack_hmcd_claymore"
		},
		[4] = {
			"wep_jack_hmcd_knife",
			--"wep_jack_hmcd_revolver",
			"wep_jack_hmcd_ied",
			"wep_jack_hmcd_smokebomb"
		},
		[5] = {
			"wep_jack_hmcd_knife",
			"wep_jack_hmcd_shuriken",
			"wep_jack_hmcd_poisonneedle",
			"wep_jack_hmcd_poisonpowder",
			"wep_jack_hmcd_ied",
			"wep_jack_hmcd_oldgrenade",
			"wep_jack_hmcd_smokebomb",
			"wep_jack_hmcd_fakepistol",
			"wep_jack_hmcd_adrenaline",
			"wep_jack_hmcd_jam",
			"wep_jack_hmcd_poisonliquid",
			"wep_jack_hmcd_poisongoo",
			"wep_jack_hmcd_poisoncanister",
			"wep_jack_hmcd_mask",
			"wep_jack_hmcd_beartrap"
		}
	},
	["Gunman"] = {
		[1] = {""},
		[2] = {""},
		[3] = {""},
		[4] = {""},
		[5] = {""}	
	},
	["Bystander"] = {
		[1] = {""},
		[2] = {""},
		[3] = {""},
		[4] = {"wep_jack_hmcd_revolver"},
		[5] = {""}
	}
}

Classes = {
	"Medic",
	"Fighter"
}

ClassesCombine = {
	"Shotguner",
	"Elite",
	"Simple"
}

CombineModels = {
	["Simple"] = "models/player/combine_soldier.mdl",
	["Shotguner"] = "models/player/combine_soldier.mdl",
	["Elite"] = "models/player/combine_super_soldier.mdl"
}

Fighter_RebelModels = {
	["female"] = {
		"models/player/Group03/female_01.mdl",
		"models/player/Group03/female_02.mdl",
		"models/player/Group03/female_03.mdl",
		"models/player/Group03/female_04.mdl",
		"models/player/Group03/female_05.mdl",
		"models/player/Group03/female_06.mdl",
	},
	["male"] = {
		"models/player/Group03/male_01.mdl",
		"models/player/Group03/male_02.mdl",
		"models/player/Group03/male_03.mdl",
		"models/player/Group03/Male_04.mdl",
		"models/player/Group03/Male_05.mdl",
		"models/player/Group03/male_06.mdl",
		"models/player/Group03/male_07.mdl",
		"models/player/Group03/male_08.mdl",
		"models/player/Group03/male_09.mdl"
	}
}

Medic_RebelModels = {
	["female"] = {
		"models/player/Group03m/female_01.mdl",
		"models/player/Group03m/female_02.mdl",
		"models/player/Group03m/female_03.mdl",
		"models/player/Group03m/female_04.mdl",
		"models/player/Group03m/female_04.mdl",
		"models/player/Group03m/female_05.mdl",
		"models/player/Group03m/female_06.mdl"
	},
	["male"] = {
		"models/player/Group03m/Male_01.mdl",
		"models/player/Group03m/male_02.mdl",
		"models/player/Group03m/male_03.mdl",
		"models/player/Group03m/Male_04.mdl",
		"models/player/Group03m/Male_05.mdl",
		"models/player/Group03m/male_06.mdl",
		"models/player/Group03m/male_07.mdl",
		"models/player/Group03m/male_08.mdl",
		"models/player/Group03m/male_09.mdl"
	}
}

HMCD_RoundsTypeNormalise = {
	[0] = "",
	[1] = "Standart",
	[2] = "State of Emergency",
	[3] = "Jihad",
	[4] = "Wild West",
	[5] = "Gun-Free-Zone Mode"
}

HMCD_RoundStartSound = {
	[1]="snd_jack_hmcd_halloween.mp3",
	[2]="snd_jack_hmcd_disaster.mp3",
	[3]="snd_mann_islam.mp3",
	[4]="snd_jack_hmcd_wildwest.mp3",
	[5]="snd_jack_hmcd_halloween.mp3",
}

RoundStartSound = {
	["dm"]="snd_jack_hmcd_deathmatch.mp3",
	["hl2"]="hl2mode1.wav"
}



NormaliseKonech = {
	["left_hand"] = "Left arm",
	["left_leg"] = "Left leg",
	["right_hand"] = "Right arm",
	["right_leg"] = "Right leg",
	["stomach"] = "Stomach",
	["chest"] = "Chest"
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

Box_Models = {
	"models/props_c17/FurnitureDrawer001a.mdl",
	"models/props_c17/FurnitureDresser001a.mdl",
	"models/props_c17/FurnitureDrawer003a.mdl",
	"models/props_c17/FurnitureCupboard001a.mdl",
	"models/props_c17/shelfunit01a.mdl",
	"models/props_junk/cardboard_box002a_gib01.mdl",
	"models/props_junk/cardboard_box002a.mdl",
	"models/props_junk/cardboard_box001b.mdl",
	"models/props_junk/cardboard_box001a_gib01.mdl",
	"models/props_junk/cardboard_box002b.mdl",
	"models/props_junk/cardboard_box003a.mdl",
	"models/props_junk/cardboard_box003a_gib01.mdl",
	"models/props_junk/cardboard_box003b_gib01.mdl",
	"models/props_junk/cardboard_box004a.mdl",
	"models/props_junk/cardboard_box004a_gib01.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_junk/wood_crate001a_damaged.mdl",
	"models/props_junk/wood_crate002a.mdl"
}

HeavyBox_Models = {
	"models/props_junk/wood_crate002a.mdl",
	"models/props_c17/FurnitureDresser001a.mdl",
	"models/props_c17/FurnitureDrawer003a.mdl"
}

Box_DropGunFreeZone = {
	"ent_jack_hmcd_ammo",
	"ent_jack_hmcd_fooddrinkbig",
	"ent_jack_hmcd_fooddrink",
	"ent_jack_hmcd_adrenaline",
	"ent_jack_hmcd_medkit",
	"ent_jack_hmcd_bandagebig",
	"ent_jack_hmcd_morphine",
	"ent_jack_hmcd_painpills",
	"ent_jack_hmcd_bandage",
	"ent_jack_hmcd_baseballbat",
	"ent_jack_hmcd_brick",
	"ent_jack_hmcd_cleaver",
	"ent_jack_hmcd_hammer",
	"ent_jack_hmcd_pocketknife",
	"ent_jack_hmcd_crowbar",
	"ent_jack_hmcd_hatchet",
	"ent_jack_hmcd_leadpipe",
	"ent_jack_hmcd_axe",
	"ent_jack_hmcd_ducttape",
	"ent_jack_hmcd_oldgrenade_dm",
	"ent_jack_hmcd_bugbait",
	"ent_jack_hmcd_softarmor"
}

HeavyBox_DropGunFreeZone = {
	"ent_jack_hmcd_adrenaline",
	"ent_jack_hmcd_medkit"
}

Box_Drop = {
	"ent_jack_hmcd_ammo",
	"ent_jack_hmcd_fooddrinkbig",
	"ent_jack_hmcd_fooddrink",
	"ent_jack_hmcd_adrenaline",
	"ent_jack_hmcd_medkit",
	"ent_jack_hmcd_bandagebig",
	"ent_jack_hmcd_morphine",
	"ent_jack_hmcd_painpills",
	"ent_jack_hmcd_bandage",
	"ent_jack_hmcd_baseballbat",
	"ent_jack_hmcd_brick",
	"ent_jack_hmcd_cleaver",
	"ent_jack_hmcd_hammer",
	"ent_jack_hmcd_pocketknife",
	"ent_jack_hmcd_crowbar",
	"ent_jack_hmcd_hatchet",
	"ent_jack_hmcd_leadpipe",
	"ent_jack_hmcd_axe",
	"ent_jack_hmcd_smallpistol",
	"ent_jack_hmcd_ducttape",
	"ent_jack_hmcd_oldgrenade_dm",
	"ent_jack_hmcd_glock17",
	"ent_jack_hmcd_revolver",
	"ent_jack_hmcd_rifle",
	"ent_jack_hmcd_mp7",
	"ent_jack_hmcd_shotgun",
	"ent_jack_hmcd_dbarrel",
	"ent_jack_hmcd_remington",
	"ent_jack_hmcd_bugbait",
	"ent_jack_hmcd_nvg",
	"ent_jack_hmcd_softarmor",
	"ent_jack_hmcd_hardarmor",
	"ent_jack_hmcd_helmet",
	"ent_jack_hmcd_laserbig",
	"ent_jack_hmcd_eotech",
	"ent_jack_hmcd_kobra",
	"ent_jack_hmcd_uspsuppressor",
	"ent_jack_hmcd_aksuppressor",
	"ent_jack_hmcd_pistolsuppressor",
	"ent_jack_hmcd_riflesuppressor",
	"ent_jack_hmcd_shotgunsuppressor",
	"ent_jack_hmcd_laser"
}

HeavyBox_Drop = {
	"ent_jack_hmcd_ptrd",
	"ent_jack_hmcd_adrenaline",
	"ent_jack_hmcd_medkit",
	"ent_jack_hmcd_oldgrenade_dm",
	"ent_jack_hmcd_glock17",
	"ent_jack_hmcd_revolver",
	"ent_jack_hmcd_rifle",
	"ent_jack_hmcd_mp7",
	"ent_jack_hmcd_shotgun",
	"ent_jack_hmcd_dbarrel",
	"ent_jack_hmcd_remington",
	"ent_jack_hmcd_nvg",
	"ent_jack_hmcd_softarmor",
	"ent_jack_hmcd_hardarmor",
	"ent_jack_hmcd_helmet",
	"ent_jack_hmcd_laserbig",
	"ent_jack_hmcd_eotech",
	"ent_jack_hmcd_kobra",
	"ent_jack_hmcd_uspsuppressor",
	"ent_jack_hmcd_aksuppressor",
	"ent_jack_hmcd_pistolsuppressor",
	"ent_jack_hmcd_riflesuppressor",
	"ent_jack_hmcd_shotgunsuppressor",
	"ent_jack_hmcd_laser"
}

AmmoType_Drop = {
	"AirboatGun",
	"AlyxGun",
	"357",
	"Pistol",
	"Buckshot",
	"AR2",
	"SMG1",
	"XBowBolt",
	"AirboatGun"
}

local atts_ents = {
	[HMCD_PISTOLSUPP]="ent_jack_hmcd_pistolsuppressor",
	[HMCD_RIFLESUPP]="ent_jack_hmcd_riflesuppressor",
	[HMCD_SHOTGUNSUPP]="ent_jack_hmcd_shotgunsuppressor",
	[HMCD_LASERSMALL]="ent_jack_hmcd_laser",
	[HMCD_LASERBIG]="ent_jack_hmcd_laserbig",
	[HMCD_KOBRA]="ent_jack_hmcd_kobra",
	[HMCD_AIMPOINT]="ent_jack_hmcd_eq_base",
	[HMCD_EOTECH]="ent_jack_hmcd_eotech",
	[HMCD_PBS]="ent_jack_hmcd_aksuppressor",
	[HMCD_OSPREY]="ent_jack_hmcd_uspsuppressor",
	[HMCD_FLASHLIGHT]="ent_jack_hmcd_flashlight"
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

concommand.Add("hmcd_attachrequest",function(ply,cmd,args)
	local attachment=math.Round(args[1])
	local wep=ply:GetActiveWeapon()
	
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
	local attachment=math.Round(args[1])
	local wep=ply:GetActiveWeapon()

	local attachmentsuka=ents.Create(atts_ents[attachment])
	attachmentsuka.HmcdSpawned=true
	attachmentsuka:SetPos(ply:GetShootPos()+ply:GetAimVector()*20)
	attachmentsuka:Spawn()
	attachmentsuka:Activate()
	attachmentsuka:GetPhysicsObject():SetVelocity(ply:GetVelocity()+ply:GetAimVector()*100)

	-- вот эта нижняя строка самая длинная ее не надо разбирать, это убирание рэйла при убирании прицела
	if wep:GetClass() == "wep_jack_hmcd_akm" and (attachment==HMCD_KOBRA or attachment==HMCD_AIMPOINT or attachment==HMCD_EOTECH) then wep:SetNWBool("Rail", false) end
	if attachment != 5 then wep:SetNWBool(atts_simplified[attachment],false) end
	if attachment == 5 then ply:AllowFlashlight(false) end

	ply.Equipment[HMCD_EquipmentNames[attachment]]=false
	net.Start("hmcd_equipment")
	net.WriteInt(attachment, 6)
	net.WriteBit(false)
	net.Send(ply)
end)