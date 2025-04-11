-- config.lua

local CustomPortrait = _G.TrueRP_CustomPortrait

-- Protocole de communication
CustomPortrait.ADDON_PREFIX = "TrueRP_PortraitElvUI"
CustomPortrait.MessageType = {
    RequestPortrait = "PORTRAIT_REQUEST",
    ResponsePortrait = "PORTRAIT_RESPONSE",
}

-- Frames et unités de base
CustomPortrait.FRAME_PLAYER = "ElvUF_Player"
CustomPortrait.FRAME_TARGET = "ElvUF_Target"
CustomPortrait.FRAME_PET = "ElvUF_Pet"
CustomPortrait.UNIT_PLAYER = "player"
CustomPortrait.UNIT_TARGET = "target"
CustomPortrait.UNIT_PET = "pet"

-- Noms des frames de groupe (pour TBC/3.3.5)
CustomPortrait.GroupPortraitFrameNames = {
    "ElvUF_PartyGroup1UnitButton1",
    "ElvUF_PartyGroup1UnitButton2",
    "ElvUF_PartyGroup1UnitButton3",
    "ElvUF_PartyGroup1UnitButton4",
}
