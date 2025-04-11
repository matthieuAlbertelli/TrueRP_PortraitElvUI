-- TrueRP_PortraitElvUI - Refactored version with AceHook integration

local E, L, V, P, G = unpack(ElvUI)
local addonName = ...
local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0", "AceHook-3.0")

-- Constantes
local ADDON_PREFIX = "TrueRP_PortraitElvUI"
-- Protocole de communication entre joueurs
local MessageType = {
    RequestPortrait = "PORTRAIT_REQUEST",
    ResponsePortrait = "PORTRAIT_RESPONSE",
}

local FRAME_PLAYER = "ElvUF_Player"
local FRAME_TARGET = "ElvUF_Target"
local FRAME_PET = "ElvUF_Pet"
local UNIT_PLAYER = "player"
local UNIT_TARGET = "target"
local UNIT_PET = "pet"

-- Utils

--- S'assure qu'une entrée existe dans la base de données pour un joueur
-- @param owner string
local function EnsureDBEntry(owner)
    CustomPortraitDB[owner] = CustomPortraitDB[owner] or { pets = {} }
end

--- Vérifie si un message commence par un certain préfixe suivi de ":"
-- @param message string
-- @param prefix string
-- @return boolean
local function MessageHasPrefix(message, prefix)
    return message:sub(1, #prefix + 1) == prefix .. ":"
end

--- Extrait le contenu après un préfixe de message suivi de ":"
local function ExtractMessagePayload(message, prefix)
    return message:sub(#prefix + 2)
end

--- Retourne le nom de l'unité spécifiée ou celui du joueur par défaut
-- @param unit string|nil - l'identifiant de l'unité ("player", "target", etc.)
-- @return string
local function GetUnitName(unit)
    return UnitName(unit or UNIT_PLAYER)
end

--- Applique une texture personnalisée à un portrait ElvUI
-- @param portrait Texture - la texture du portrait
-- @param texture string - chemin vers la texture à appliquer
local function SetPortraitTexture(portrait, texture)
    if not portrait or not texture then return end
    portrait:SetTexture(texture)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    portrait:Show()
end

--- Récupère une texture de portrait personnalisée depuis la base de données
-- @param owner string - nom du joueur
-- @param pet string|nil - nom du familier (optionnel)
-- @return string|nil - chemin vers la texture
local function GetPortraitFromDB(owner, pet)
    local data = CustomPortraitDB[owner]
    if not data then return nil end
    if pet then
        return data.pets and data.pets[pet]
    else
        return data.portrait
    end
end

--- Vérifie si un portrait personnalisé existe pour un joueur
-- @param owner string
-- @return boolean
local function HasPortrait(owner)
    return GetPortraitFromDB(owner) ~= nil
end

--- Retourne la table des portraits de familiers pour un joueur donné
-- @param owner string
-- @return table|nil
local function GetPetPortraits(owner)
    local data = CustomPortraitDB[owner]
    return data and data.pets or nil
end

--- Définit le portrait principal d’un joueur
-- @param owner string
-- @param path string
local function SetPortraitInDB(owner, path)
    EnsureDBEntry(owner)
    CustomPortraitDB[owner].portrait = path
end

--- Définit le portrait d’un familier pour un joueur
-- @param owner string
-- @param pet string
-- @param path string
local function SetPetPortraitInDB(owner, pet, path)
    EnsureDBEntry(owner)
    CustomPortraitDB[owner].pets[pet] = path
end

--- Affiche le portrait TrueRP du pet ciblé s’il appartient à un membre du groupe
local function HandleTargetPetPortrait()
    local petName = GetUnitName(UNIT_TARGET)
    if not petName then return end

    for i = 1, GetNumPartyMembers() do
        local unit = "party" .. i
        local petUnit = unit .. "pet"
        if UnitExists(petUnit) and UnitName(petUnit) == petName then
            local ownerName = GetUnitName(unit)
            local texture = GetPortraitFromDB(ownerName, petName)
            if texture then
                SetPortraitTexture(_G[FRAME_TARGET].Portrait, texture)
            else
                SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", ownerName)
            end
            break
        end
    end
end

--- Injecte une logique personnalisée dans le PostUpdate d'un portrait ElvUI (via RawHook)
-- @param frame Frame - frame contenant un portrait
-- @param unitKeyFunc function - retourne une clé d'unité (souvent UnitName)
-- @param textureFunc function - retourne une texture selon la clé
local function HookPortrait(frame, unitKeyFunc, textureFunc)
    if not frame or not frame.Portrait or frame.Portrait.__truerp_hooked then return end

    frame.Portrait.__truerp_hooked = true

    CustomPortrait:RawHook(frame.Portrait, "PostUpdate", function(portrait, unit)
        local key = unitKeyFunc(unit)
        local tex = textureFunc(key)
        if tex then
            SetPortraitTexture(portrait, tex)
        else
            local original = CustomPortrait.hooks[frame.Portrait] and CustomPortrait.hooks[frame.Portrait].PostUpdate
            if original then
                return original(portrait, unit)
            end
        end
    end)
end

--- Applique une texture personnalisée à un frame directement
-- @param frame Frame - frame ElvUI avec un .Portrait
-- @param unitKey string - nom de l'unité cible (joueur ou propriétaire du familier)
-- @param textureFunc function - fonction pour obtenir la texture
local function OverridePortraitFrame(frame, unitKey, textureFunc)
    if not frame or not frame.Portrait then return end
    local texture = textureFunc(unitKey)
    SetPortraitTexture(frame.Portrait, texture)
end

--- Parcourt les frames de groupe et applique les hooks & textures personnalisés
local function HandleGroupFrames()
    for i = 1, 4 do
        local frame = _G["ElvUF_PartyGroup1UnitButton" .. i]
        if frame and frame.unit and UnitIsPlayer(frame.unit) then
            local name = GetUnitName(frame.unit)

            HookPortrait(frame, GetUnitName, GetPortraitFromDB)
            OverridePortraitFrame(frame, name, GetPortraitFromDB)

            if not HasPortrait(name) then
                SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", name)
            end
        end
    end
end

-- Événements

--- À l'entrée dans le monde, on hook et override tous les portraits du joueur
--- Hook les portraits de base (joueur, target, pet)
--- Hook le portrait du joueur
local function HookPlayerPortrait()
    HookPortrait(_G[FRAME_PLAYER], GetUnitName, GetPortraitFromDB)
end

--- Hook le portrait du pet du joueur
local function HookPetPortrait()
    HookPortrait(_G[FRAME_PET], function()
        return GetUnitName(UNIT_PLAYER)
    end, function(owner)
        return GetPortraitFromDB(owner, UnitName(UNIT_PET))
    end)
end

--- Détermine la texture de portrait à afficher pour la target actuelle
-- Peut être un joueur, un pet du groupe, ou son propre pet
-- @param name string - Nom de l’unité ciblée
-- @return string|nil - Chemin de la texture personnalisée, ou nil
local function ResolveTargetPortrait(name)
    if not name then return nil end

    local playerName = GetUnitName(UNIT_PLAYER)
    local petName = UnitName(UNIT_PET)

    -- Cas 1 : Joueur avec un portrait défini
    local portrait = GetPortraitFromDB(name)
    if portrait then return portrait end


    -- Cas 2 : Pet appartenant à un membre du groupe
    for i = 1, GetNumPartyMembers() do
        local unit = "party" .. i
        local petUnit = unit .. "pet"
        if UnitExists(petUnit) and UnitName(petUnit) == name then
            local owner = GetUnitName(unit)
            return GetPortraitFromDB(owner, name)
        end
    end

    -- Cas 3 : Ton propre pet
    if name == petName then
        return GetPortraitFromDB(playerName, petName)
    end

    return nil
end

--- Hook le portrait de la target (joueur, pet du groupe, etc.)
local function HookTargetPortrait()
    HookPortrait(
        _G[FRAME_TARGET],
        function(unit) return UnitName(unit) end,
        ResolveTargetPortrait
    )
end

--- Hook les portraits principaux (joueur, target, pet)
local function HookBasePortraits()
    HookPlayerPortrait()
    HookTargetPortrait()
    HookPetPortrait()
end

local function OverridePlayerPortrait()
    local name = GetUnitName(UNIT_PLAYER)
    OverridePortraitFrame(_G[FRAME_PLAYER], name, GetPortraitFromDB)
end

local function OverrideTargetPortrait()
    local name = GetUnitName(UNIT_TARGET)
    OverridePortraitFrame(_G[FRAME_TARGET], name, ResolveTargetPortrait)
end

local function OverridePetPortrait()
    local playerName = GetUnitName(UNIT_PLAYER)
    local petName = UnitName(UNIT_PET)

    OverridePortraitFrame(_G[FRAME_PET], playerName, function(owner)
        return GetPortraitFromDB(owner, petName)
    end)
end

local function OverrideBasePortraits()
    OverridePlayerPortrait()
    OverrideTargetPortrait()
    OverridePetPortrait()
end

local PortraitFrames = {
    [FRAME_PLAYER] = {
        unit = UNIT_PLAYER,
        textureFunc = GetPortraitFromDB,
    },
    [FRAME_TARGET] = {
        unit = UNIT_TARGET,
        textureFunc = ResolveTargetPortrait,
    },
    [FRAME_PET] = {
        unit = UNIT_PLAYER, -- pour accéder à CustomPortraitDB[player]
        textureFunc = function(owner)
            return GetPortraitFromDB(owner, UnitName(UNIT_PET))
        end,
    },
}

local function InitConfiguredPortraits()
    for frameName, config in pairs(PortraitFrames) do
        local frame = _G[frameName]
        if frame then
            local unitKeyFunc = function() return GetUnitName(config.unit) end
            HookPortrait(frame, unitKeyFunc, config.textureFunc)
            OverridePortraitFrame(frame, unitKeyFunc(), config.textureFunc)
        end
    end
end

--- Fonction refactorisée : à l'entrée en jeu
function CustomPortrait:PLAYER_ENTERING_WORLD()
    C_Timer.After(0.5, function()
        InitConfiguredPortraits()
        self:RequestGroupPortraits()
    end)
end

function CustomPortrait:PLAYER_TARGET_CHANGED()
    local name = GetUnitName(UNIT_TARGET)

    if UnitIsPlayer(UNIT_TARGET) and UnitIsConnected(UNIT_TARGET) then
        OverridePortraitFrame(_G[FRAME_TARGET], name, function(key)
            return GetPortraitFromDB(key)
        end)
        SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", name)
    else
        -- Tente d'appliquer un portrait si la target est un pet connu
        HandleTargetPetPortrait()
    end
end

--- Lors du changement d'état du pet, on force un update de son portrait
function CustomPortrait:UNIT_PET()
    C_Timer.After(0.2, function()
        local petFrame = _G[FRAME_PET]
        if petFrame and petFrame.Portrait then
            petFrame:UpdateElement("Portrait")
        end
    end)
end

--- Lorsque la composition du groupe change, on redemande les portraits plusieurs fois
function CustomPortrait:PARTY_MEMBERS_CHANGED()
    local count, maxTries = 0, 10
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, elapsed)
        self.t = (self.t or 0) + elapsed
        if self.t > 0.5 then
            self.t = 0
            count = count + 1
            CustomPortrait:RequestGroupPortraits()
            if count >= maxTries then
                self:SetScript("OnUpdate", nil)
            end
        end
    end)
end

--- Parcourt le groupe et hook les portraits manquants
function CustomPortrait:RequestGroupPortraits()
    HandleGroupFrames()
    HookPortrait(_G[FRAME_PLAYER], GetUnitName, function(key) return GetPortraitFromDB(key) end)
    HookPortrait(_G[FRAME_TARGET], GetUnitName, function(key) return GetPortraitFromDB(key) end)
end

--- Envoie les données de portrait du joueur courant à un destinataire donné
-- @param to string - nom du joueur cible
local function SendPortraitData(to)
    local playerName = GetUnitName(UNIT_PLAYER)
    local portrait = GetPortraitFromDB(playerName)
    if not portrait then return end

    local msg = MessageType.ResponsePortrait .. ":" .. portrait
    local pets = GetPetPortraits(playerName)
    if pets then
        local parts = {}
        for pet, tex in pairs(pets) do
            table.insert(parts, pet .. "=" .. tex)
        end
        msg = msg .. "|" .. table.concat(parts, ",")
    end

    SendAddonMessage(ADDON_PREFIX, msg, "WHISPER", to)
end

--- Réception des messages Addon pour envoyer ou recevoir les données de portrait
function CustomPortrait:CHAT_MSG_ADDON(_, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    if message == MessageType.RequestPortrait then
        SendPortraitData(sender)
        return
    end

    if MessageHasPrefix(message, MessageType.ResponsePortrait) then
        local payload = ExtractMessagePayload(message, MessageType.ResponsePortrait)
        local main, pets = strsplit("|", payload)

        if main then
            SetPortraitInDB(sender, main)
        end

        if pets then
            for pair in string.gmatch(pets, "[^,]+") do
                local n, t = strmatch(pair, "([^=]+)=([^=]+)")
                if n and t then
                    SetPetPortraitInDB(sender, n, t)
                end
            end
        end

        if UnitIsPlayer(UNIT_TARGET) and GetUnitName(UNIT_TARGET) == sender then
            OverridePortraitFrame(_G[FRAME_TARGET], sender, GetPortraitFromDB)
        end

        HandleGroupFrames()
    end
end

--- Enregistre tous les événements nécessaires
function CustomPortrait:Initialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self:RegisterEvent("CHAT_MSG_ADDON")
end

E:RegisterModule(CustomPortrait:GetName())
