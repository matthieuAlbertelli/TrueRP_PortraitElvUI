-- core.lua

local E, L, V, P, G = unpack(ElvUI)
local addonName = ...
local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0", "AceHook-3.0")

-- Expose le module dans l’environnement global
_G.TrueRP_CustomPortrait = CustomPortrait
