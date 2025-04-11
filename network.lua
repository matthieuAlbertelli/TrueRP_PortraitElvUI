-- comm.lua

local CustomPortrait = _G.TrueRP_CustomPortrait
local DB = CustomPortraitDBModule

local Comm = {}

--- Envoie les données de portrait du joueur courant à un destinataire donné
-- @param to string - nom du joueur cible
function Comm.SendPortraitData(to)
    local playerName = UnitName("player")
    local portrait = DB.GetPortraitFromDB(playerName)
    if not portrait then return end

    local msg = CustomPortrait.MessageType.ResponsePortrait .. ":" .. portrait
    local pets = DB.GetPetPortraits(playerName)
    if pets then
        local parts = {}
        for pet, tex in pairs(pets) do
            table.insert(parts, pet .. "=" .. tex)
        end
        msg = msg .. "|" .. table.concat(parts, ",")
    end

    SendAddonMessage(CustomPortrait.ADDON_PREFIX, msg, "WHISPER", to)
end

--- Vérifie si un message commence par un certain préfixe suivi de ":"
-- @param message string
-- @param prefix string
-- @return boolean
function Comm.MessageHasPrefix(message, prefix)
    return message:sub(1, #prefix + 1) == prefix .. ":"
end

--- Extrait le contenu après un préfixe de message suivi de ":"
-- @param message string
-- @param prefix string
-- @return string
function Comm.ExtractMessagePayload(message, prefix)
    return message:sub(#prefix + 2)
end

CustomPortrait.Comm = Comm
