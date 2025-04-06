local E, L, V, P, G = unpack(ElvUI)
local addonName = ...

local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0")

-- local TEXTURE_PATH_BASE = "Interface\\AddOns\\TrueRP_PortraitSelector\\portraits"

-- Fonction pour récupérer le chemin de texture du portrait
local function GetPortraitTexture(unitKey)
    local unitPortraitData = CustomPortraitDB[unitKey]
    if not unitPortraitData then return end
    return unitPortraitData.portrait
end

-- Appliquer la texture custom
local function OverridePortrait(frame, unitKey)
    local portrait = frame.Portrait
    if not portrait then return end

    local texture = GetPortraitTexture(unitKey)
    if not texture then return end

    portrait:SetTexture(texture)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    portrait:Show()
end

-- Quand le joueur entre dans le monde
function CustomPortrait:PLAYER_ENTERING_WORLD()
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        if t > 0.5 then
            f:SetScript("OnUpdate", nil)

            local playerFrame = _G["ElvUF_Player"]
            if playerFrame then
                OverridePortrait(playerFrame, UnitName("player"))
            end
        end
    end)
end

-- Quand la cible change, envoyer une requête si c'est un joueur
function CustomPortrait:PLAYER_TARGET_CHANGED()
    if UnitIsPlayer("target") and UnitIsConnected("target") then
        local targetName = UnitName("target")
        SendAddonMessage("TrueRP_PortraitElvUI", "REQ", "WHISPER", targetName)
    end
end

-- Initialisation
function CustomPortrait:Initialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")

    local listenerFrame = CreateFrame("Frame")
    listenerFrame:RegisterEvent("CHAT_MSG_ADDON")
    listenerFrame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        if prefix ~= "TrueRP_PortraitElvUI" then return end

        DEFAULT_CHAT_FRAME:AddMessage("ADDON MSG: prefix=" ..
            tostring(prefix) .. " msg=" .. tostring(message) .. " sender=" .. tostring(sender))

        if message == "REQ" then
            local data = CustomPortraitDB and CustomPortraitDB[UnitName("player")]
            if data and data.portrait then
                SendAddonMessage("TrueRP_PortraitElvUI", "RESP:" .. data.portrait, "WHISPER", sender)
            end
        elseif message:sub(1, 5) == "RESP:" then
            local portraitId = message:sub(6)
            local targetName = UnitName("target")
            if portraitId and targetName then
                local targetFrame = _G["ElvUF_Target"]
                if targetFrame and targetFrame.Portrait then
                    targetFrame.Portrait:SetTexture(portraitId)
                    targetFrame.Portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    targetFrame.Portrait:Show()
                end
            end
        end
    end)
end

E:RegisterModule(CustomPortrait:GetName())
