local hRun = hook.Run
hook.Add("RoundPlayerVar", "FUNC_VAR", function(ply)
    if GAMEMODE.RoundName == "dm" then
        ply.Role = "Fighter"
        ply:SetNWString("RoleShow", "Fighter")
    elseif GAMEMODE.RoundName == "sandbox" then
        ply.Role = "Sandboxer"
        ply:SetNWString("RoleShow", "Sandboxer")
    else
        ply.Role = "Bystander"
        ply:SetNWString("RoleShow", "Bystander")
    end

    ply.SecretRole = ""
    ply:SetNWString("SecretRole", "")
    ply:SetRoleColor(57,62,213)
end)

hook.Add("PlayerSpawn", "RoundPlayerVar_Spawn", function(ply)
    if PLYSPAWN_OVERRIDE then return end
    hRun("RoundPlayerVar", ply)
end)