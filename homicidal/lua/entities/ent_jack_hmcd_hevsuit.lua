AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "HEV Suit"
ENT.Author = "Homicidal"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
else
    function ENT:Initialize()
        self:SetModel("models/items/item_item_crate.mdl") -- Box model as requested
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    function ENT:Use(activator, caller)
        if IsValid(activator) and activator:IsPlayer() then
            -- Equip the suit
            if activator.Role == "Gordon" or activator:GetNWString("RoleShow") == "Gordon Freeman" then
                activator:EmitSound("items/suitchargeok1.wav")
                
                -- Apply Model and Bodygroup
                -- Path: c:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\addons\freeman_pm
                -- Model: models/player/freeman.mdl
                activator:SetModel("models/player/freeman.mdl")
                activator:SetBodygroup(1, 1) -- Outfit 1
                
                -- Enable HEV logic
                activator:SetNWBool("HMCD_HEVSuit", true)
                activator:SetNWString("Bodyvest", "Level III") -- High protection
                activator:SetNWString("Helmet", "ACH") -- Head protection
                activator:ChatPrint("HEV Suit Equipped. Systems Online.")
                
                self:Remove()
            else
                activator:ChatPrint("Only Gordon Freeman can wear this suit.")
            end
        end
    end
end
