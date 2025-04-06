local E, L, V, P, G = unpack(ElvUI)
local addonName = ...

local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0")

local TEXTURE_PATH = "Interface\\AddOns\\TrueRP_PortraitSelector\\portraits\\elfe_de_sang\\paladin\\portrait_1"

-- Fonction de debug (facultative)
local function PrintFrame(frame)
    print("Nom:", frame:GetName() or "anonyme", "unit:", frame.unit or "nil")
end

-- Fonction récursive pour trouver un frame avec un Portrait Texture
local function SearchForPlayerPortraitFrame(frame)
    if not frame then return nil end

    if frame.Portrait and frame.Portrait:IsObjectType("Texture") then
        -- On a trouvé un bon candidat
        return frame
    end

    -- Explorer ses enfants récursivement
    local i = 1
    while true do
        local child = select(i, frame:GetChildren())
        if not child then break end

        local result = SearchForPlayerPortraitFrame(child)
        if result then return result end

        i = i + 1
    end

    return nil
end

-- Appliquer la texture custom
local function OverridePortrait(frame)
    local portrait = frame.Portrait
    if not portrait then return end

    portrait:SetTexture(TEXTURE_PATH)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    portrait:Show()

    print("CustomPortrait: portrait appliqué sur", frame:GetName() or "cadre anonyme")
end

function CustomPortrait:PLAYER_ENTERING_WORLD()
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        if t > 0.5 then
            f:SetScript("OnUpdate", nil)

            local foundFrame = SearchForPlayerPortraitFrame(UIParent)
            if foundFrame then
                OverridePortrait(foundFrame)
            else
                print("CustomPortrait: toujours aucun frame avec Portrait trouvé.")
            end
        end
    end)
end

function CustomPortrait:Initialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    print("CustomPortrait: démarrage en attente de frame.")
end

E:RegisterModule(CustomPortrait:GetName())
