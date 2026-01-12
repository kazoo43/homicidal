local PlayerMeta = FindMetaTable("Player")

if PlayerMeta and not PlayerMeta.HuySpectate then
	PlayerMeta.HuySpectate = PlayerMeta.Spectate
end

-- Ensure drop object exists (usually in Sandbox, but just in case)
if PlayerMeta and not PlayerMeta.DropObject then
	PlayerMeta.DropObject = function(self)
		-- Fallback if DropObject is missing, though it's standard Sandbox
	end
end

concommand.Add("hmcd_droprequest_ammo",function(ply,cmd,args)
	local Type,Amount=args[1],tonumber(args[2])
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

hook.Add("PlayerSpawn", "HMCD_Sandbox_Movement", function(ply)
	if engine.ActiveGamemode() == "hmcdunion" then return end

	-- Apply Homicidal movement settings
	ply:SetSlowWalkSpeed(75)
	ply:SetLadderClimbSpeed(75)

	local phys = ply:GetPhysicsObject()
	if IsValid(phys) then 
		phys:SetMass(15) 
	end

    -- Fix for grey screen / uninitialized variables in Sandbox
    -- Initialize vital stats to ensure screen effects (consciousness) work correctly
    ply.Blood = 5200
    ply.pain = 0
    ply.consciousness = 100
    ply:SetNWFloat("HMCD_Consciousness", 100)
    ply.o2 = 1
    
    ply.stamina = ply.stamina or {}
    ply.stamina['leg'] = 100
    ply:SetNWFloat("Stamina_Arm", 50)
    
    ply.BleedOuts = {
		["right_hand"] = 0,
		["left_hand"] = 0,
		["left_leg"] = 0,
		["right_leg"] = 0,
		["stomach"] = 0,
		["chest"] = 0
	}
    
    ply.Hit = {
		['lungs']=false,
		['liver']=false,
		['stomach']=false,
		['intestines']=false,
		['heart']=false,
		['neck_artery']=false,
		['rl_artery']=false,
		['ll_artery']=false,
		['rh_artery']=false,
		['spine']=false,
		['trahea']=false
	}
    
    ply.Bones = {
		['LeftArm']=1,
		['RightArm']=1,
		['LeftLeg']=1,
		['RightLeg']=1,
		['Jaw']=1
	}
    
    -- Reset bone manipulations
    local bones = ply:GetBoneCount()
    if bones and bones > 0 then
        for i = 0, bones - 1 do
            ply:ManipulateBonePosition(i, Vector(0, 0, 0))
            ply:ManipulateBoneAngles(i, Angle(0, 0, 0))
            ply:ManipulateBoneScale(i, Vector(1,1,1))
        end
    end
end)

-- Apply to existing players immediately (for Lua Refresh support)
for _, ply in ipairs(player.GetAll()) do
	if ply:Alive() and engine.ActiveGamemode() ~= "hmcdunion" then
		ply.Blood = ply.Blood or 5200
		ply.pain = ply.pain or 0
		ply.consciousness = 100
		ply:SetNWFloat("HMCD_Consciousness", 100)
		ply.o2 = ply.o2 or 1
		
		ply.stamina = ply.stamina or {}
		ply.stamina['leg'] = ply.stamina['leg'] or 100
		ply:SetNWFloat("Stamina_Arm", 50)
		
		ply.BleedOuts = ply.BleedOuts or {
			["right_hand"] = 0,
			["left_hand"] = 0,
			["left_leg"] = 0,
			["right_leg"] = 0,
			["stomach"] = 0,
			["chest"] = 0
		}
		
		ply.Hit = ply.Hit or {
			['lungs']=false,
			['liver']=false,
			['stomach']=false,
			['intestines']=false,
			['heart']=false,
			['neck_artery']=false,
			['rl_artery']=false,
			['ll_artery']=false,
			['rh_artery']=false,
			['spine']=false,
			['trahea']=false
		}
		
		ply.Bones = ply.Bones or {
			['LeftArm']=1,
			['RightArm']=1,
			['LeftLeg']=1,
			['RightLeg']=1,
			['Jaw']=1
		}
	end
end
