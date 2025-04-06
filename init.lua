local E, L, V, P, G = unpack(ElvUI)
local addonName = ...

local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0")

-- Fonction pour récupérer le chemin de texture du portrait
local function GetPortraitTexture(unitKey)
    local unitPortraitData = CustomPortraitDB[unitKey]
    if not unitPortraitData then return end
    return unitPortraitData.portrait
end

-- Appliquer la texture custom
local function OverridePortrait(frame, unitKey)
    if not frame or not frame.Portrait then return end

    local texture = GetPortraitTexture(unitKey)
    if not texture then return end

    frame.Portrait:SetTexture(texture)
    frame.Portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    frame.Portrait:Show()
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

            CustomPortrait:RequestGroupPortraits()
        end
    end)
end

-- Quand la cible change
function CustomPortrait:PLAYER_TARGET_CHANGED()
    if UnitIsPlayer("target") and UnitIsConnected("target") then
        local targetName = UnitName("target")
        local targetFrame = _G["ElvUF_Target"]

        -- Affiche directement si on a le portrait en cache
        if targetFrame and CustomPortraitDB[targetName] then
            OverridePortrait(targetFrame, targetName)
        end

        -- Envoie la requête de toute façon pour s'assurer qu'on a la version à jour
        SendAddonMessage("TrueRP_PortraitElvUI", "REQ", "WHISPER", targetName)
    end
end

-- Quand un membre du groupe change
function CustomPortrait:GROUP_ROSTER_UPDATE()
    CustomPortrait:RequestGroupPortraits()
end

-- Requête les portraits des membres de groupe si manquants
function CustomPortrait:RequestGroupPortraits()
    local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name = UnitName(unit)
            if name and not CustomPortraitDB[name] then
                SendAddonMessage("TrueRP_PortraitElvUI", "REQ", "WHISPER", name)
            else
                local frame = _G["ElvUF_PartyGroup1UnitButton" .. i]
                if frame then
                    OverridePortrait(frame, name)
                end
            end
        end
    end
end

-- Gestion des messages
function CustomPortrait:CHAT_MSG_ADDON(_, prefix, message, channel, sender)
    if prefix ~= "TrueRP_PortraitElvUI" then return end

    if message == "REQ" then
        local data = CustomPortraitDB and CustomPortraitDB[UnitName("player")]
        if data and data.portrait then
            SendAddonMessage("TrueRP_PortraitElvUI", "RESP:" .. data.portrait, "WHISPER", sender)
        end
    elseif message:sub(1, 5) == "RESP:" then
        local texturePath = message:sub(6)
        if not texturePath or texturePath == "" then return end

        CustomPortraitDB[sender] = { portrait = texturePath }

        local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
        for i = 1, count do
            local unit = prefix .. i
            if UnitExists(unit) and UnitIsPlayer(unit) then
                local name = UnitName(unit)
                if name == sender then
                    local frame = _G["ElvUF_PartyGroup1UnitButton" .. i]
                    if frame then
                        OverridePortrait(frame, name)
                    end
                    break
                end
            end
        end

        -- Mise à jour de la target si c'est le joueur concerné
        if UnitIsPlayer("target") and UnitName("target") == sender then
            local targetFrame = _G["ElvUF_Target"]
            if targetFrame then
                OverridePortrait(targetFrame, sender)
            end
        end
    end
end

function CustomPortrait:Initialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_ADDON")
end

E:RegisterModule(CustomPortrait:GetName())
