-- events.lua

local CustomPortrait = _G.TrueRP_CustomPortrait
local DB = TrueRP_DBModule
local Comm = CustomPortrait.Comm
local Utils = CustomPortrait.Utils
local Frames = CustomPortrait.Frames

local ADDON_PREFIX = CustomPortrait.ADDON_PREFIX
local MessageType = CustomPortrait.MessageType
local FRAME_TARGET = CustomPortrait.FRAME_TARGET
local FRAME_PET = CustomPortrait.FRAME_PET
local UNIT_TARGET = CustomPortrait.UNIT_TARGET
local UNIT_PLAYER = CustomPortrait.UNIT_PLAYER

-- Gère la réception des messages addon
function CustomPortrait:CHAT_MSG_ADDON(_, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    if message == MessageType.RequestPortrait then
        Comm.SendPortraitData(sender)
        return
    end

    if Comm.MessageHasPrefix(message, MessageType.ResponsePortrait) then
        local payload = Comm.ExtractMessagePayload(message, MessageType.ResponsePortrait)
        local main, pets = strsplit("|", payload)

        if main then
            DB.SetPortraitInDB(sender, main)
        end

        if pets then
            for pair in string.gmatch(pets, "[^,]+") do
                local n, t = strmatch(pair, "([^=]+)=([^=]+)")
                if n and t then
                    DB.SetPetPortraitInDB(sender, n, t)
                end
            end
        end

        if UnitIsPlayer(UNIT_TARGET) and Utils.GetUnitName(UNIT_TARGET) == sender then
            Frames.OverridePortraitFrame(_G[FRAME_TARGET], sender, DB.GetPortraitFromDB)
        end

        CustomPortrait:RequestGroupPortraits()
    end
end

-- Événement principal d'initialisation
function CustomPortrait:PLAYER_ENTERING_WORLD()
    C_Timer.After(0.5, function()
        Frames.InitConfiguredPortraits()
        self:RequestGroupPortraits()
    end)
end

-- Mise à jour du portrait lorsqu'on change de cible
function CustomPortrait:PLAYER_TARGET_CHANGED()
    local name = Utils.GetUnitName(UNIT_TARGET)

    if UnitIsPlayer(UNIT_TARGET) and UnitIsConnected(UNIT_TARGET) then
        Frames.OverridePortraitFrame(_G[FRAME_TARGET], name, function(key)
            return DB.GetPortraitFromDB(key)
        end)
        SendAddonMessage(ADDON_PREFIX, MessageType.RequestPortrait, "WHISPER", name)
    else
        Frames.HandleTargetPetPortrait()
    end
end

-- Mise à jour du portrait du familier
function CustomPortrait:UNIT_PET()
    C_Timer.After(0.2, function()
        local petFrame = _G[FRAME_PET]
        if petFrame and petFrame.Portrait then
            petFrame:UpdateElement("Portrait")
        end
    end)
end

-- Réagit aux changements de groupe
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

-- (Ré)initialise les portraits du groupe
function CustomPortrait:RequestGroupPortraits()
    Frames.InitGroupPortraits()
end

CustomPortrait.Events = CustomPortrait
