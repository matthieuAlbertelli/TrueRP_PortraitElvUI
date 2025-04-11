-- db.lua

--- Module d'accès aux portraits personnalisés
local DB = {}

--- S'assure qu'une entrée existe dans la base de données pour un joueur
-- @param owner string
local function EnsureDBEntry(owner)
    CustomPortraitDB[owner] = CustomPortraitDB[owner] or { pets = {} }
end

--- Récupère une texture de portrait personnalisée depuis la base de données
-- @param owner string - nom du joueur
-- @param pet string|nil - nom du familier (optionnel)
-- @return string|nil - chemin vers la texture
function DB.GetPortraitFromDB(owner, pet)
    local data = CustomPortraitDB[owner]
    if not data then return nil end
    return pet and data.pets and data.pets[pet] or data.portrait
end

--- Vérifie si un portrait personnalisé existe pour un joueur
-- @param owner string
-- @return boolean
function DB.HasPortrait(owner)
    return DB.GetPortraitFromDB(owner) ~= nil
end

--- Retourne la table des portraits de familiers pour un joueur donné
-- @param owner string
-- @return table|nil
function DB.GetPetPortraits(owner)
    local data = CustomPortraitDB[owner]
    return data and data.pets or nil
end

--- Définit le portrait principal d’un joueur
-- @param owner string
-- @param path string
function DB.SetPortraitInDB(owner, path)
    EnsureDBEntry(owner)
    CustomPortraitDB[owner].portrait = path
end

--- Définit le portrait d’un familier pour un joueur
-- @param owner string
-- @param pet string
-- @param path string
function DB.SetPetPortraitInDB(owner, pet, path)
    EnsureDBEntry(owner)
    CustomPortraitDB[owner].pets[pet] = path
end

-- Exporte le module dans l'environnement global
CustomPortraitDBModule = DB
