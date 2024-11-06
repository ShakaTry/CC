-- Structure pour stocker les mouvements et actions
local path = {}
local actionPoints = {
    pickup = nil,    -- Point de collecte
    dropoff = nil,   -- Point de dépôt
    refuel = nil     -- Point de ravitaillement
}

-- Niveau minimum de carburant avant ravitaillement
local MIN_FUEL_LEVEL = 100

-- Variable pour suivre la position actuelle de la turtle
local currentPosition = 0

-- Fonction pour sauvegarder le chemin et les points d'action
function savePath()
    local file = fs.open("path.txt", "w")
    file.write(textutils.serialize({path = path, actions = actionPoints}))
    file.close()
end

-- Fonction pour vérifier et recharger le carburant
function refuelIfNeeded()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel < MIN_FUEL_LEVEL and actionPoints.refuel then
        print("Niveau de carburant bas (" .. fuelLevel .. "). Ravitaillement...")
        
        -- Sauvegarder la position actuelle dans le chemin
        local currentPos = #path
        
        -- Aller au point de ravitaillement
        followPathTo(actionPoints.refuel)
        
        -- Essayer de prendre du carburant
        turtle.select(1) -- Utiliser le premier slot pour le carburant
        turtle.suck()
        
        -- Essayer de se ravitailler avec tous les slots
        for slot = 1, 16 do
            turtle.select(slot)
            turtle.refuel()
        end
        
        -- Retourner à la position précédente
        if currentPos > 0 then
            followPathTo(currentPos)
        end
        
        print("Niveau de carburant actuel: " .. turtle.getFuelLevel())
    end
end

-- Fonction pour charger le chemin et les points d'action
function loadPath()
    if fs.exists("path.txt") then
        local file = fs.open("path.txt", "r")
        local data = textutils.unserialize(file.readAll())
        file.close()
        path = data.path or {}
        actionPoints = data.actions or {pickup = nil, dropoff = nil, refuel = nil}
        return true
    end
    return false
end

-- Fonction pour vérifier le carburant
function checkFuel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == 0 then
        print("Plus de carburant! Veuillez ajouter du carburant")
        return false
    end
    return true
end

-- Fonction pour enregistrer le trajet
function recordPath()
    print("Mode apprentissage du trajet")
    print("Utilisez les touches suivantes:")
    print("Z - Avancer")
    print("S - Reculer")
    print("Q - Tourner à gauche")
    print("D - Tourner à droite")
    print("A - Monter")
    print("E - Descendre")
    print("R - Marquer point de collecte")
    print("T - Marquer point de dépôt")
    print("C - Marquer point de carburant")
    print("F - Terminer l'enregistrement")
    
    path = {} -- Réinitialiser le chemin
    actionPoints = {pickup = nil, dropoff = nil, refuel = nil}
    
    while true do
        local event, key = os.pullEvent("char")
        local action = nil
        local success = true
        
        -- Actions de marquage de points
        if key == "r" then
            actionPoints.pickup = #path
            print("Point de collecte marqué!")
        elseif key == "t" then
            actionPoints.dropoff = #path
            print("Point de dépôt marqué!")
        elseif key == "c" then
            actionPoints.refuel = #path
            print("Point de ravitaillement marqué!")
        elseif key == "f" then
            if not actionPoints.pickup or not actionPoints.dropoff then
                print("Vous devez marquer un point de collecte (R) et un point de dépôt (T)!")
            else
                break
            end
        -- Actions de mouvement
        elseif key == "z" then
            success, action = pcall(function()
                if turtle.forward() then 
                    return "forward"
                else
                    print("Impossible d'avancer - Obstacle détecté")
                    return nil
                end
            end)
        elseif key == "s" then
            success, action = pcall(function()
                if turtle.back() then 
                    return "back"
                else
                    print("Impossible de reculer - Obstacle détecté")
                    return nil
                end
            end)
        elseif key == "q" then
            success, action = pcall(function()
                if turtle.turnLeft() then 
                    return "turnLeft"
                end
            end)
        elseif key == "d" then
            success, action = pcall(function()
                if turtle.turnRight() then 
                    return "turnRight"
                end
            end)
        elseif key == "a" then
            success, action = pcall(function()
                if turtle.up() then 
                    return "up"
                else
                    print("Impossible de monter - Obstacle détecté")
                    return nil
                end
            end)
        elseif key == "e" then
            success, action = pcall(function()
                if turtle.down() then 
                    return "down"
                else
                    print("Impossible de descendre - Obstacle détecté")
                    return nil
                end
            end)
        end
        
        -- Enregistrer l'action si c'est un mouvement réussi
        if success and action then
            table.insert(path, action)
            print("Action enregistrée: " .. action)
        elseif success == false then
            print("Erreur lors de l'exécution de l'action")
        end
    end
    
    savePath()
    print("Trajet et points d'action enregistrés!")
end

-- Fonction pour suivre le trajet jusqu'à un point spécifique
function followPathTo(endIndex)
    -- Si on est déjà au bon endroit, ne rien faire
    if currentPosition == endIndex then
        return
    end
    
    -- Si on doit reculer dans le trajet
    if currentPosition > endIndex then
        -- Parcourir le chemin à l'envers
        for i = currentPosition, endIndex + 1, -1 do
            local action = path[i]
            if action == "forward" then
                turtle.back()
            elseif action == "back" then
                turtle.forward()
            elseif action == "turnLeft" then
                turtle.turnRight()
            elseif action == "turnRight" then
                turtle.turnLeft()
            elseif action == "up" then
                turtle.down()
            elseif action == "down" then
                turtle.up()
            end
        end
    else
        -- Parcourir le chemin en avant
        for i = currentPosition + 1, endIndex do
            local action = path[i]
            if action == "forward" then
                turtle.forward()
            elseif action == "back" then
                turtle.back()
            elseif action == "turnLeft" then
                turtle.turnLeft()
            elseif action == "turnRight" then
                turtle.turnRight()
            elseif action == "up" then
                turtle.up()
            elseif action == "down" then
                turtle.down()
            end
        end
    end
    
    -- Mettre à jour la position actuelle
    currentPosition = endIndex
end

-- Fonction principale de transport
function startTransport()
    currentPosition = 0  -- Réinitialiser la position au début de chaque cycle
    
    while true do
        -- Vérifier le carburant avant chaque cycle
        refuelIfNeeded()
        
        -- Aller au point de collecte
        followPathTo(actionPoints.pickup)
        
        -- Collecter les items
        for slot = 1, 16 do
            turtle.select(slot)
            turtle.suck()
        end
        
        -- Vérifier le carburant avant de continuer
        refuelIfNeeded()
        
        -- Aller au point de dépôt
        followPathTo(actionPoints.dropoff)
        
        -- Déposer les items
        for slot = 1, 16 do
            turtle.select(slot)
            turtle.drop()
        end
        
        -- Vérifier le carburant avant de retourner
        refuelIfNeeded()
        
        -- Retourner au début
        returnToStart()
        
        print("Cycle de transport terminé!")
        print("Appuyez sur 'Q' pour quitter ou toute autre touche pour continuer")
        
        local event, key = os.pullEvent("key")
        if key == keys.q then
            break
        end
    end
end

-- Fonction pour retourner au point de départ
function returnToStart()
    print("Retour au point de départ...")
    followPathTo(0)
end

-- Menu principal modifié
function showMenu()
    while true do
        print("\nMenu Principal:")
        print("1. Enregistrer nouveau trajet")
        print("2. Commencer le transport")
        print("3. Quitter")
        
        local choice = read()
        
        if choice == "1" then
            recordPath()
        elseif choice == "2" then
            if #path == 0 then
                print("Veuillez d'abord enregistrer un trajet")
            else
                startTransport()
            end
        elseif choice == "3" then
            break
        end
    end
end

-- Charger le trajet sauvegardé au démarrage
loadPath()

-- Démarrer le programme
print("Programme de transport démarré")
showMenu()
