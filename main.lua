-- init.lua (renommé suggéré : main.lua ou module.lua)

local E, L, V, P, G = unpack(ElvUI)

-- Chargement centralisé depuis core.lua
local CustomPortrait = _G.TrueRP_CustomPortrait
local Events = CustomPortrait.Events

-- Registre tous les événements via Events
function Events.RegisterAll()
    CustomPortrait:RegisterEvent("PLAYER_ENTERING_WORLD")
    CustomPortrait:RegisterEvent("PLAYER_TARGET_CHANGED")
    CustomPortrait:RegisterEvent("UNIT_PET")
    CustomPortrait:RegisterEvent("PARTY_MEMBERS_CHANGED")
    CustomPortrait:RegisterEvent("CHAT_MSG_ADDON")
end

-- Registre l'addon auprès d'ElvUI
function CustomPortrait:Initialize()
    Events.RegisterAll()
end

E:RegisterModule(CustomPortrait:GetName())
