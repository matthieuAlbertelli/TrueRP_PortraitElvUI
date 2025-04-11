-- utils.lua

local CustomPortrait = _G.TrueRP_CustomPortrait

local Utils = {}

--- Retourne le nom d'une unité ou du joueur si unit est nil
-- @param unit string|nil - ex : "target", "player", etc.
-- @return string
function Utils.GetUnitName(unit)
    return UnitName(unit or "player")
end

--- Applique une texture personnalisée à un portrait
-- @param portrait Texture - la texture du portrait
-- @param texture string - chemin vers la texture
function Utils.SetPortraitTexture(portrait, texture)
    if not portrait or not texture then return end
    portrait:SetTexture(texture)
    portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    portrait:Show()
end

-- Exporte le module
CustomPortrait.Utils = Utils
