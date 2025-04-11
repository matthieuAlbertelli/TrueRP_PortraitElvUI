-- frames.lua

local CustomPortrait = _G.TrueRP_CustomPortrait
local DB = CustomPortraitDBModule
local Utils = CustomPortrait.Utils

local ADDON_PREFIX = CustomPortrait.ADDON_PREFIX
local MessageType = CustomPortrait.MessageType
local GroupPortraitFrameNames = CustomPortrait.GroupPortraitFrameNames
local UNIT_TARGET = CustomPortrait.UNIT_TARGET


local Frames = {}

--- Injecte une logique personnalisée dans le PostUpdate d'un portrait ElvUI (via RawHook)
-- @param frame Frame - frame contenant un portrait
-- @param unitKeyFunc function - retourne une clé d'unité (souvent UnitName)
-- @param textureFunc function - retourne une texture selon la clé
function Frames.HookPortrait(frame, unitKeyFunc, textureFunc)
    if not frame or not frame.Portrait or frame.Portrait.__truerp_hooked then return end
    frame.Portrait.__truerp_hooked = true

    CustomPortrait:RawHook(frame.Portrait, "PostUpdate", function(portrait, unit)
        local key = unitKeyFunc(unit)
        local tex = textureFunc(key)
        if tex then
            Utils.SetPortraitTexture(portrait, tex)
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
function Frames.OverridePortraitFrame(frame, unitKey, textureFunc)
    if not frame or not frame.Portrait then return end
    local texture = textureFunc(unitKey)
    Utils.SetPortraitTexture(frame.Portrait, texture)
end

-- Initialisation des portraits configurés (joueur, target, pet)
function Frames.InitConfiguredPortraits()
    for frameName, config in pairs(Frames.PortraitFrames) do
        local frame = _G[frameName]
        if frame then
            local unitKeyFunc = function() return Utils.GetUnitName(config.unit) end
            Frames.HookPortrait(frame, unitKeyFunc, config.textureFunc)
            Frames.OverridePortraitFrame(frame, unitKeyFunc(), config.textureFunc)
        end
    end
end

-- Initialisation des portraits de groupe
function Frames.InitGroupPortraits()
    for _, frameName in ipairs(GroupPortraitFrameNames) do
        local frame = _G[frameName]
        if frame and frame.unit and UnitIsPlayer(frame.unit) then
            local name = Utils.GetUnitName(frame.unit)
            Frames.HookPortrait(frame, Utils.GetUnitName, DB.GetPortraitFromDB)
            Frames.OverridePortraitFrame(frame, name, DB.GetPortraitFromDB)

            if not DB.HasPortrait(name) then
                SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", name)
            end
        end
    end
end

-- Gère les cas où la cible est un pet de joueur en groupe
function Frames.HandleTargetPetPortrait()
    local petName = Utils.GetUnitName(UNIT_TARGET)
    if not petName then return end

    for i = 1, GetNumPartyMembers() do
        local unit = "party" .. i
        local petUnit = unit .. "pet"
        if UnitExists(petUnit) and UnitName(petUnit) == petName then
            local ownerName = Utils.GetUnitName(unit)
            local texture = DB.GetPortraitFromDB(ownerName, petName)
            if texture then
                Utils.SetPortraitTexture(_G[CustomPortrait.FRAME_TARGET].Portrait, texture)
            else
                SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", ownerName)
            end
            break
        end
    end
end

--- Table des frames à surveiller et leurs configurations
Frames.PortraitFrames = {
    [CustomPortrait.FRAME_PLAYER] = {
        unit = CustomPortrait.UNIT_PLAYER,
        textureFunc = DB.GetPortraitFromDB,
    },
    [CustomPortrait.FRAME_TARGET] = {
        unit = CustomPortrait.UNIT_TARGET,
        textureFunc = function(name)
            local playerName = Utils.GetUnitName("player")
            local petName = UnitName("pet")

            local portrait = DB.GetPortraitFromDB(name)
            if portrait then return portrait end

            for i = 1, GetNumPartyMembers() do
                local unit = "party" .. i
                local petUnit = unit .. "pet"
                if UnitExists(petUnit) and UnitName(petUnit) == name then
                    local owner = Utils.GetUnitName(unit)
                    return DB.GetPortraitFromDB(owner, name)
                end
            end

            if name == petName then
                return DB.GetPortraitFromDB(playerName, petName)
            end

            return nil
        end,
    },
    [CustomPortrait.FRAME_PET] = {
        unit = CustomPortrait.UNIT_PLAYER,
        textureFunc = function(owner)
            return DB.GetPortraitFromDB(owner, UnitName("pet"))
        end,
    },
}



CustomPortrait.Frames = Frames
