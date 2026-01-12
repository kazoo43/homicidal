if SERVER then
	AddCSLuaFile()
	SWEP.Spawnable = true
else
	killicon.AddFont("wep_jack_hmcd_assaultrifle", "HL2MPTypeDeath", "1", Color(255, 0, 0))
	SWEP.WepSelectIcon = surface.GetTextureID("vgui/inventory/weapon_nam_akm")
end

SWEP.IconTexture = "vgui/inventory/weapon_nam_akm"
SWEP.IconLength = 3
SWEP.IconHeight = 2
SWEP.Base = "wep_cat_base"
SWEP.PrintName = "HK416"
SWEP.Instructions = "The HK416 is a 5.56×45mm NATO assault rifle by Heckler & Koch, using a short-stroke gas piston system and AR-15–compatible magazines, designed for improved reliability.\n\nLMB to fire.\nRMB to aim.\nRELOAD to reload.\nShot placement counts.\nCrouching helps stability.\nBullets can ricochet and penetrate."
SWEP.Primary.ClipSize = 31
SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize
SWEP.ViewModel = "models/weapons/zcity/v_416c.mdl"
SWEP.WorldModel = "models/weapons/zcity/w_hk416.mdl"
SWEP.ViewModelFlip = false
SWEP.Damage = 25
SWEP.Category="HMCD: Union - Rifles"
SWEP.Primary.Automatic = true
SWEP.ViewModelFOV = 80
SWEP.SprintPos = Vector(10, 0, -3)
SWEP.SprintAng = Angle(-20, 40, -50)
SWEP.AimPos = Vector(-2.53, -3, 1.44)
SWEP.AimAng = Angle(1.3, 0, 0)
SWEP.CloseAimPos = Vector(.45, 0, 0)
SWEP.AltAimPos = Vector(-1.63, -4, 0.4)
SWEP.ReloadTime = 5
SWEP.ReloadRate = .6
SWEP.UseHands = true
SWEP.ReloadSound = ""
SWEP.AmmoType = "SMG1"
SWEP.Primary.Ammo = "SMG1"
SWEP.TriggerDelay = .1
SWEP.CycleTime = 0.02
SWEP.IconOverride = "vgui/inventory/weapon_nam_akm"

SWEP.TPIK = false

SWEP.TPIK_PosAngles = {
    ["ValveBiped.Bip01_R_Upperarm"] = Angle(-5, 0, 0),
	["ValveBiped.Bip01_L_Upperarm"] = Angle(30, 0, 0),
	["ValveBiped.Bip01_L_Finger1"] = Angle(-60, 0, 0),
}

SWEP.TPIK_PosVectors = {
	["ValveBiped.Bip01_Spine2"] = Vector(3,0,0)
}

SWEP.ShootWait_Ragdoll = 0.2

SWEP.Recoil = .42
SWEP.AttBone = "Weapon"
SWEP.Supersonic = true
SWEP.Accuracy = .999
SWEP.ShotPitch = 112
SWEP.ENT = "ent_jack_hmcd_hk416"
SWEP.FuckedWorldModel = true
SWEP.DeathDroppable = false
SWEP.CommandDroppable = true
SWEP.Spawnable = true
SWEP.CycleType = "auto"
SWEP.ReloadType = "magazine"
SWEP.DrawAnim = "base_draw"
SWEP.FireAnim = "base_fire"
SWEP.IronFireAnim = "iron_fire"
SWEP.ReloadAnim = "base_reloadempty"
SWEP.TacticalReloadAnim = "base_reload"
--SWEP.TacticalReloadAnim="base_reload"
SWEP.CloseFireSound = "rifle_win1892/win1892_fire_01.wav"
--SWEP.SuppressedFireSound="snd_jack_hmcd_supppistol.wav"
--SWEP.FarFireSound="snd_jack_hmcd_ar_far.wav"
SWEP.LaserAngle = Angle(270, 0, 0)

-- lasers

SWEP.LaserPos_Right = 0
SWEP.LaserPos_Forward = 0
SWEP.LaserPos_Up = 0
SWEP.LaserPos_RightCorrect = 0

--SWEP.CloseFireSound="ak74/ak74_fp.wav"
SWEP.SuppressedFireSound = "m4a1/m4a1_suppressed_fp.wav"
SWEP.FarFireSound = "m4a1/m4a1_dist.wav"
SWEP.ShellType = ""
SWEP.BarrelLength = 18
SWEP.FireAnimRate = 1
SWEP.AimTime = 6
SWEP.BearTime = 7
SWEP.HipHoldType = "ar2"
SWEP.AimHoldType = "ar2"
SWEP.DownHoldType = "passive"
SWEP.MuzzleEffect = "pcf_jack_mf_mrifle2"
SWEP.MuzzleEffectSuppressed = "pcf_jack_mf_suppressed"
SWEP.HipFireInaccuracy = .05
SWEP.HolsterSlot=1
SWEP.HolsterPos=Vector(3,-7,-4)
SWEP.HolsterAng=Angle(160,10,180)
SWEP.CarryWeight = 3500
SWEP.ScopeDotPosition = Vector(0, 0, 0)
SWEP.ScopeDotAngle = Angle(0, 0, 0)
SWEP.NextFireTime = 0
SWEP.ShellAttachment = 1
SWEP.ShellEffect = "eff_jack_hmcd_556"
SWEP.MagEntity = "ent_jack_hmcd_ar15mag"
SWEP.MagDelay = .7

SWEP.MuzzlePos = {30, -5.1, -3.1}

SWEP.InsHands = false
SWEP.ReloadAdd = 2

SWEP.ReloadSounds = {	
	{"weapons/m4a1/m4a1_magrelease.wav", 1, "FullOnly"},
	{"weapons/m4a1/m4a1_magout.wav", 1.25, "FullOnly"},
	{"weapons/m4a1/m4a1_magain.wav", 3.35, "FullOnly"},
	{"weapons/m4a1/m4a1_hit.wav", 4.06, "FullOnly"},
	{"weapons/m4a1/m4a1_magrelease.wav", 1, "EmptyOnly"},
	{"weapons/m4a1/m4a1_magout.wav", 1.25, "EmptyOnly"},
	{"weapons/m4a1/m4a1_magain.wav", 3.25, "EmptyOnly"},
	{"weapons/m4a1/m4a1_hit.wav", 4, "EmptyOnly"},
	{"weapons/m4a1/m4a1_boltarelease.wav", 5, "EmptyOnly"}
}

SWEP.BulletDir = {400, 1.6, -10}

SWEP.SuicidePos = Vector(4, 7, -32)
SWEP.SuicideAng = Angle(100, 0, 90)
SWEP.SuicideTime = 10
SWEP.SuicideType = "Rifle"
SWEP.ProreloadMul = .5

SWEP.MuzzleInfo = {
	["Bone"] = "A_Muzzle",
	["Offset"] = Vector(30, 2, -2)
}
SWEP.Attachments = {
	["Owner"] = {
		["Suppressor"] = {
			bone = "Weapon",
			pos = {
				right = -5,
				forward = 0,
				up = 0.8
			},
			ang = {
				up = 0,
				right = 0
			},
			model = "models/cw2/attachments/556suppressor.mdl",
			scale = .7,
			num = HMCD_RIFLESUPP
		},
		["Sight"] = {
			bone = "Weapon",
			pos = {
				right = -2,
				forward = 0,
				up = 4
			},
			ang = {
				up = -90
			},
			scale = .8,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_kobra.mdl",
			sightpos = {
				up = 3.6,
				forward = 0;
				right = 15.6
			},
			sightang = {
				up = -90,
				right = 180
			},
			aimpos = Vector(-2.53, -2.98, 0.55),
			num = HMCD_KOBRA
		},
		["Sight2"] = {
			bone = "Weapon",
			pos = {
				right = -2,
				forward = 0,
				up = 4.15
			},
			ang = {
				up = -90
			},
			scale = .8,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_aimpoint.mdl",
			sightpos = {
				up = 3.6,
				forward = 0;
				right = 15.6
			},
			sightang = {
				up = 90,
				right = 180
			},
			aimpos = Vector(-2.53, -2.98, -0.5),
			num = HMCD_AIMPOINT
		},
		["Sight3"] = {
			bone = "Weapon",
			pos = {
				right = -2,
				forward = 0,
				up = 4 	
			},
			ang = {
				up = -90
			},
			scale = .8,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_eotech.mdl",
			sightpos = {
				up = 3.6,
				forward = 0;
				right = 15.6
			},
			sightang = {
				up = 90,
				right = 180
			},
			aimpos = Vector(-2.53, -2.98, 0.55),
			num = HMCD_EOTECH
		},
		["Rail"] = {
			bone = "Weapon",
			pos = {
				right = -2.5,
				forward = -0.25,
				up = 1
			},
			model = "models/wystan/attachments/akrailmount.mdl",
			material = "models/wystan/attachments/akrail/newscope"
		},
		["Laser"] = {
			bone = "Weapon",
			pos = {
				right = 1,
				forward = 1.22,
				up = 2.7
			},
			ang = {
				up = 0,
				forward = 90,
				right = 90

			},
			model = "models/cw2/attachments/anpeq15.mdl",
			scale = .4,
			num = HMCD_LASERBIG
		},
		["TSRS02"] = {
			bone = "Weapon",
			pos = {
				right = -2,
				forward = 0,
				up = 2.75
			},
			ang = {
				up = -90
			},
			scale = .8,
			model = "models/weapons/arc9/darsu_eft/mods/scope_all_trijicon_srs_02.mdl",
			sightpos = {
				right = 0.4,
				forward = 0,
				up = 20
			},
			sightang = {
				up = -90,
				forward = 180,
				right = 90
			},
			aimpos = Vector(-1.63, -5, -1),
			thermal = true,
			num = 9
		}
	},
	["Viewer"] = {
		["Weapon"] = {
			pos = {
				right = 1,
				forward = 4,
				up = 0
			},
			ang = {
				forward = 180,
				right = 10
			}
		},
		["Suppressor"] = {
			pos = {
				right = 1,
				forward = 8.5,
				up = -7.55
			},
			ang = {
				right = -8,
				up = 90,
				forward = 0
			},
			scale = .9,
			model = "models/cw2/attachments/556suppressor.mdl"
		},
		["Rail"] = {
			pos = {
				forward = 7,
				up = -4.55,
				right = 0.8
			},
			ang = {
				right = -10,
				up = -90,
				forward = 180
			},
			model = "models/wystan/attachments/akrailmount.mdl",
			material = "models/wystan/attachments/akrail/newscope"
		},
		["Sight"] = {
			pos = {
				forward = 7.5,
				up = -5,
				right = 1
			},
			ang = {
				right = -10,
				forward = 180
			},
			scale = .9,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_kobra.mdl"
		},
		["Sight2"] = {
			pos = {
				forward = 7.5,
				up = -5,
				right = 1
			},
			ang = {
				right = -10,
				forward = 180
			},
			scale = .9,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_aimpoint.mdl"
		},
		["Sight3"] = {
			pos = {
				forward = 7.5,
				up = -5,
				right = 1
			},
			ang = {
				right = -10,
				forward = 180
			},
			scale = .9,
			model = "models/weapons/tfa_ins2/upgrades/a_optic_eotech.mdl"
		},
		["Laser"] = {
			pos = {
				forward = 7.75,
				up = -6.3,
				right = 1
			},
			ang = {
				right = -10,
				forward = 180,
				up = 180
			},
			scale = .7,
			model = "models/cw2/attachments/anpeq15.mdl"
		}
	}
}