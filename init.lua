-- TrueRP_PortraitElvUI - Refactored version with AceHook integration

local E, L, V, P, G = unpack(ElvUI)
local addonName = ...
local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0", "AceHook-3.0")

-- Constantes
local ADDON_PREFIX = "TrueRP_PortraitElvUI"
local FRAME_PLAYER = "ElvUF_Player"
local FRAME_TARGET = "ElvUF_Target"
local FRAME_PET = "ElvUF_Pet"
local UNIT_PLAYER = "player"
local UNIT_TARGET = "target"
local UNIT_PET = "pet"

-- Utils

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
            HookPortrait(frame, GetUnitName, function(unitKey)
                return GetPortraitFromDB(unitKey)
            end)
            OverridePortraitFrame(frame, name, function(key)
                return GetPortraitFromDB(key)
            end)
            if not CustomPortraitDB[name] then
                SendAddonMessage(ADDON_PREFIX, "REQ", "WHISPER", name)
            end
        end
    end
end

-- Événements

--- À l'entrée dans le monde, on hook et override tous les portraits du joueur
function CustomPortrait:PLAYER_ENTERING_WORLD()
    C_Timer.After(0.5, function()
        local playerName = GetUnitName(UNIT_PLAYER)
        local targetName = GetUnitName(UNIT_TARGET)
        local petName = UnitName(UNIT_PET)

        HookPortrait(_G[FRAME_PLAYER], GetUnitName, function(key) return GetPortraitFromDB(key) end)
        HookPortrait(_G[FRAME_TARGET], GetUnitName, function(key) return GetPortraitFromDB(key) end)
        HookPortrait(_G[FRAME_PET], function() return playerName end,
            function(owner) return GetPortraitFromDB(owner, petName) end)

        OverridePortraitFrame(_G[FRAME_PLAYER], playerName, function(key) return GetPortraitFromDB(key) end)
        OverridePortraitFrame(_G[FRAME_TARGET], targetName, function(key) return GetPortraitFromDB(key) end)
        OverridePortraitFrame(_G[FRAME_PET], playerName, function(owner) return GetPortraitFromDB(owner, petName) end)

        self:RequestGroupPortraits()
    end)
end

--- Lors du changement de cible, on override si c'est un joueur connu
function CustomPortrait:PLAYER_TARGET_CHANGED()
    local name = GetUnitName(UNIT_TARGET)
    if UnitIsPlayer(UNIT_TARGET) and UnitIsConnected(UNIT_TARGET) then
        OverridePortraitFrame(_G[FRAME_TARGET], name, function(key) return GetPortraitFromDB(key) end)
        SendAddonMessage(ADDON_PREFIX, "REQ", "WHISPER", name)
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
    local data = CustomPortraitDB[GetUnitName(UNIT_PLAYER)]
    if not data or not data.portrait then return end

    local msg = "RESP:" .. data.portrait
    if data.pets then
        local parts = {}
        for pet, tex in pairs(data.pets) do
            table.insert(parts, pet .. "=" .. tex)
        end
        msg = msg .. "|" .. table.concat(parts, ",")
    end
    SendAddonMessage(ADDON_PREFIX, msg, "WHISPER", to)
end

--- Réception des messages Addon pour envoyer ou recevoir les données de portrait
function CustomPortrait:CHAT_MSG_ADDON(_, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    if message == "REQ" then
        SendPortraitData(sender)
        return
    end

    if message:sub(1, 5) == "RESP:" then
        local payload = message:sub(6)
        local main, pets = strsplit("|", payload)
        CustomPortraitDB[sender] = CustomPortraitDB[sender] or { pets = {} }
        CustomPortraitDB[sender].portrait = main

        if pets then
            for pair in string.gmatch(pets, "[^,]+") do
                local n, t = strmatch(pair, "([^=]+)=([^=]+)")
                if n and t then
                    CustomPortraitDB[sender].pets[n] = t
                end
            end
        end

        if UnitIsPlayer(UNIT_TARGET) and GetUnitName(UNIT_TARGET) == sender then
            OverridePortraitFrame(_G[FRAME_TARGET], sender, function(key) return GetPortraitFromDB(key) end)
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
