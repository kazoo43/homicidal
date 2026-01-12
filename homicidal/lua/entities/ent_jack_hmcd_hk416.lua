--[[File Path:   gamemodes/homicide/entities/entities/ent_jack_hmcd_akm.lua

--]]
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_jack_hmcd_wep_base"
ENT.SWEP = "wep_jack_hmcd_hk416"
ENT.ImpactSound = "physics/metal/weapon_impact_soft3.wav"
ENT.Model = "models/weapons/zcity/w_hk416.mdl"
ENT.DefaultAmmoAmt = 30
ENT.AmmoType = "SniperRound"
ENT.MuzzlePos = Vector(27, 0, 2.8)
ENT.BulletDir = Vector(1, 0, 0)
ENT.BulletEjectPos = Vector(6, 1, 3.3)
ENT.BulletEjectDir = Vector(0, 1, 0)
ENT.Damage = 30
ENT.ShellEffect = "eff_jack_hmcd_556"
ENT.TriggerDelay = .1
ENT.Automatic = true
ENT.MuzzleEffect = "pcf_jack_mf_mrifle1"

ENT.Attachments = {
	["Suppressor"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = -4.6,
			up = 0.2,
			right = -2.65
		},
			ang = {
			right = 90,
			up = 0,
			forward = 90
		},
		
		scale = .9,
		model = "models/cw2/attachments/556suppressor.mdl"
	},
	["Rail"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = 1,
			up = 3.8,
			right = 0
		},
		ang = {
			right = 180,
			up = 90,
			forward = 180
		},
		material = "models/wystan/attachments/akrail/newscope",
		model = "models/wystan/attachments/akrailmount.mdl"
	},
	["Sight"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = -7,
			up = 1.35,
			right = 0
		},
		ang = {
			right = 180,
			up = 180,
			forward = 180
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_kobra.mdl"
	},
	["Sight2"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = 1,
			up = 5.75,
			right = -0.25
		},
		ang = {
			right = 180,
			up = 180,
			forward = 180
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_aimpoint.mdl"
	},
	["Sight3"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = 1,
			up = 5.5,
			right = -0.25
		},
		ang = {
			right = 180,
			up = 180,
			forward = 180
		},
		scale = .9,
		model = "models/weapons/tfa_ins2/upgrades/a_optic_eotech.mdl"
	},
	["Laser"] = {
		bone = "M4A1_ThirdPerson",
		pos = {
			forward = 0,
			up = 1.1,
			right = 0.5
		},
		ang = {
			right = 180,
			forward = 180
		},
		scale = .7,
		model = "models/cw2/attachments/anpeq15.mdl"
	}
}