local E, L, V, P, G = unpack(ElvUI)
local addonName = ...

local CustomPortrait = E:NewModule("CustomPortrait", "AceEvent-3.0")

local TEXTURE_PATH_BASE = "Interface\\AddOns\\TrueRP_PortraitSelector\\portraits"

-- Fonction de debug (facultative)
local function PrintFrame(frame)
    print("Nom:", frame:GetName() or "anonyme", "unit:", frame.unit or "nil")
end


-- Fonction récursive pour trouver un frame avec un Portrait Texture
-- local function SearchForPlayerPortraitFrame(frame)
--     if not frame then return nil end

--     if frame.Portrait and frame.Portrait:IsObjectType("Texture") then
--         -- On a trouvé un bon candidat
--         -- print("Frame Player:", frame:GetName() or "Unnamed frame")
--         -- print("Found portrait in frame:", frame:GetName() or tostring(frame), "of type", frame:GetObjectType(), "parent:",
--         --     frame:GetParent() and frame:GetParent():GetName() or "no parent")

--         return frame
--     end

--     -- Explorer ses enfants récursivement
--     local i = 1
--     while true do
--         local child = select(i, frame:GetChildren())
--         if not child then break end

--         local result = SearchForPlayerPortraitFrame(child)
--         if result then return result end

--         i = i + 1
--     end

--     return nil
-- end

local function GetPortraitTexture(unitKey)
    -- print("GetPortraitTexture: unitKey:" .. unitKey)
    local unitPortraitData = CustomPortraitDB[unitKey]
    if not unitPortraitData then
        -- print("Ce personnage n'a pas de portrait enregistré.")
        return
    end
    if unitPortraitData then
        print("Portrait ID :", unitPortraitData.portrait)
    end
    -- print("GetPortraitTexture: TEXTURE_PATH_BASE:" .. TEXTURE_PATH_BASE)
    -- local texturePath = TEXTURE_PATH_BASE ..
    --     "\\" .. unitPortraitData.race .. "\\" .. unitPortraitData.classe .. "\\" .. unitPortraitData.portrait
    -- print("GetPortraitTexture:" .. texturePath)
    -- print("unitPortraitData.portrait:" .. unitPortraitData.portrait)
    return (unitPortraitData.portrait)
end

-- Appliquer la texture custom
local function OverridePortrait(frame, unitKey)
    local portrait = frame.Portrait
    if not portrait then return end

    local texture = GetPortraitTexture(unitKey)
    portrait:SetTexture(texture)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    portrait:Show()

    -- print("CustomPortrait: portrait appliqué sur", frame:GetName() or "cadre anonyme")
end

function CustomPortrait:PLAYER_ENTERING_WORLD()
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(_, elapsed)
        t = t + elapsed
        if t > 0.5 then
            f:SetScript("OnUpdate", nil)

            -- local foundFrame = SearchForPlayerPortraitFrame(UIParent)
            local playerFrame = _G["ElvUF_Player"]
            if playerFrame then
                OverridePortrait(playerFrame, UnitName("player"))
            else
                -- print("CustomPortrait: toujours aucun frame avec Portrait trouvé.")
            end
        end
    end)
end

function CustomPortrait:Initialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- print("CustomPortrait: démarrage en attente de frame.")
end

E:RegisterModule(CustomPortrait:GetName())
