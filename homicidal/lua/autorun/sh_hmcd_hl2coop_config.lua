HMCD_HL2Coop = HMCD_HL2Coop or {}

HMCD_HL2Coop.CitizenMaps = {
    ["d1_trainstation"] = true,
    ["d1_canals"] = true,
    ["d1_town"] = true, -- Ravenholm
}

HMCD_HL2Coop.RebelMaps = {
    ["d2_coast"] = true,
    ["d2_prison"] = true,
    ["d3_c17"] = true,
    ["d3_citadel"] = true,
    ["d3_breen"] = true,
    ["ep1_"] = true,
    ["ep2_"] = true,
}

HMCD_HL2Coop.Loadouts = {
    ["Citizen"] = {
        "wep_jack_hmcd_hands",
        "wep_jack_hmcd_crowbar",
        "wep_jack_hmcd_usp",
    },
    ["Rebel"] = {
        "wep_jack_hmcd_hands",
        "wep_jack_hmcd_crowbar",
        "wep_jack_hmcd_usp",
        "wep_jack_hmcd_mp7",
        "wep_jack_hmcd_mp5",
    }
}

function HMCD_HL2Coop.GetPlayerType(mapName)
    for prefix, _ in pairs(HMCD_HL2Coop.CitizenMaps) do
        if string.find(mapName, prefix) then return "Citizen" end
    end
    for prefix, _ in pairs(HMCD_HL2Coop.RebelMaps) do
        if string.find(mapName, prefix) then return "Rebel" end
    end
    return "Citizen" -- Default
end
