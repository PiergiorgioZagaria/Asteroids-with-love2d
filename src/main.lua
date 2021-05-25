---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global
---@diagnostic disable: unused-local

--[[
    I commenti cominciano con doppio -, sopra stanno dei commenti
    per dire all'editor di non farmi vedere alcuni avvisi perchè
    danno fastidio e sono inutili. Btw questo è un commento multilinea

    TODO
    Trasformare gli asteroidi in poligoni e farli ruotare,
    Forme strane e non poligoni?
    Cambiare palette,
    Implementare game over, punteggio, leaderboard, menu, multiplayer, ecc.
    Implementare settings, tra cui toggle fullscreen
    Power Ups?
    Navicelle, Shop?
    Web o android?
    Cambiare il movimento, accelerazione?
]]

-- Classes creation
-- Creo una classe di vettori, così posso controllare meglio cose come
-- posizione e velocità, che sono a coppie
Vec2 = {}
function Vec2:new(x,y)
    newobj = {x = x,y = y} -- X e Y del vettore
    self.__index = self                -- Non so bene cosa facciano questi righi
    return setmetatable(newobj,self)   -- Ma ho visto che di solito la gente fa così
end

-- Funzione per trovare la distanza tra due punti, teorema di pitagora
function Vec_dist(v1,v2)
    return math.sqrt(math.pow(v1.x - v2.x,2) + math.pow(v1.y - v2.y,2))
end

-- La base per ostacoli, proiettili e giocatore/i, multiplayer?
-- Hanno una posizione e velocità, entrambi vettori
Entity = {}
function Entity:new(pos,vel)
    newobj = {pos = pos, vel = vel}
    self.__index = self
    return setmetatable(newobj,self)
end

-- La base per gli asteroidi, hanno posizione velocità e dimensione
-- Usare inheritance?
Enemy = {}
function Enemy:new(pos,vel,size)
    newobj = {pos = pos, vel = vel,size = size}
    self.__index = self
    return setmetatable(newobj,self)
end

-- Main love functions
-- La Funzione che il motore di gioco esegue una volta appena parte il gioco
function love.load()
    -- Tutte queste variabili sono globali e possono venire accesse
    -- da qualunque parte del codice
    local winw,winh = love.graphics.getDimensions()
    player = Entity:new(Vec2:new(winw / 2,winh / 2),Vec2:new(0,0))
    player.size = Vec2:new(10,10)
    SPEED = 400 -- Il modulo del vettore velocità
    angle = 0   -- L'angolo di partenza del giocatore, servirà per farlo girare con il mouse
    projectiles = {} -- Array di proiettili nel gioco
    enemies = {}     -- Array di nemici creati
end

-- La funziona che il gioco chiama ogni frame (60)
-- Qui è dove si scrive la logica del gioco
function love.update(dt)
-- dt sta per delta time, serve perchè nel caso i frame calano le velocità rimangono le stesse
    player.pos.x = player.pos.x + player.vel.x * dt
    player.pos.y = player.pos.y + player.vel.y * dt
    -- Sposta il giocatore in base alla sua velocità

    mx , my = love.mouse.getPosition()
    angle = math.atan2(my - player.pos.y,mx - player.pos.x) + math.pi / 2
    -- L'angolo a cui deve girarsi il giocatore per puntare il mouse
    -- Sottraggo i vettori per trovare il vettore che unisce le punte
    -- Se hai domande puoi chiedere, posso condividerti un altro link per
    -- farti vedere i vettori in pratica

    local width,height = love.graphics.getDimensions()
    for i, p in ipairs(projectiles) do
        if p.pos.x > width +10 or p.pos.x < -10 or p.pos.y > height + 10 or p.pos.y < -10 then
            table.remove(projectiles,i)
            -- Not the most efficient, but better than p=nil,
            -- Maybe create new remove function
        else
            p.pos.x = p.pos.x + p.vel.x * dt
            p.pos.y = p.pos.y + p.vel.y * dt
        end
    end
    -- Se il proiettile è fuori dallo schermo eliminalo,
    -- altrimenti spostalo in base alla sua velocità

    if #enemies < 4 then
        local posx,posy = math.random() * (width + 100) , math.random()
        if posy > 0.5 then
            posy = height + 100
        else
            posy = -100
        end
        -- La posx serve per farlo spawnare lungo tutta la lunghezza dello schermo e un po'
        -- oltre, mentre posy puo' essere solo sopra o sotto lo schermo, forse lo cambierò
        -- Servono perchè non vuoi far spawnare i nemici a caso sullo schermo ma fuori dalla
        -- vista del giocatore
        local pos = Vec2:new(posx,posy)
        local a = math.random() * math.pi * 2
        local v = Vec2:new(100 * math.cos(a),100 * math.sin(a))
        -- I nemici hanno una direzione a caso e velocità 100
        local s = math.random(30,50)
        -- le dimensioni dei nemici, lo cambierò dopo
        table.insert(enemies,Enemy:new(pos,v,s))
    end
    -- Spawna nemici se ce ne sono meno di quattro,
    -- Dovrei cambiarlo e mettere qualcosa di più bello

    for _, e in ipairs(enemies) do
-- _ significa che non mi importa l'indice dell'elemento nell'array
        e.pos.x = e.pos.x + e.vel.x * dt
        e.pos.y = e.pos.y + e.vel.y * dt
        if e.pos.x < -100 then
            e.pos.x = width + 100
        elseif e.pos.x > width + 100 then
            e.pos.x = - 100
        elseif e.pos.y < -100 then
            e.pos.y = height + 100
        elseif e.pos.y > height + 100 then
            e.pos.y = - 100
        end
    end
    -- Sposta tutti i nemici e se sono troppo fuori schermo falli apparire
    -- Dall'altra parte dello schermo

    -- Questo serve per controllare se i proiettili hanno colpito qualcosa
    for i, p in ipairs(projectiles) do
        -- La flag serve perchè altrimenti prova a eliminare nemici
        -- anche se il proiettile è scomparso
        local flag = false
        for j, e in ipairs(enemies) do
            if not flag then
                -- Se la distanza tra il proiettile (punto) e il nemico (approx. cerchio)
                -- è minore del suo raggio, allora l'ha colpito
                if Vec_dist(p.pos,e.pos) < e.size then
                    flag = true
                    table.remove(projectiles,i) -- Elimina il proiettile
                    if e.size > 25 then         -- Se è grande allora dividilo in due
                        for k = 1, 2 do
                            -- Dovrei fare una funzione a parte probabilmente
                            local a = math.random(0,2 * 3.14159) * k
                            local pos = Vec2:new(25 * math.cos(a),25 * math.sin(a))
                            local v = Vec2:new(pos.x * 4, pos.y * 4)
                            pos.x, pos.y = pos.x + e.pos.x, pos.y + e.pos.y
                            table.insert(enemies,Enemy:new(pos,v,e.size/2))
                        end
                    end
                    table.remove(enemies,j) -- Rimuovi il nemico originale
                end
            end
        end
    end
end
-- Questa serie di end è davvero brutta

-- Questa è la funzione che il motore di gioco vede per disegnare sullo schermo
function love.draw()
    love.graphics.push()
    love.graphics.translate(player.pos.x,player.pos.y)
    -- Sposta il centro del sistema di riferimento al punto dove sta il giocatore
    love.graphics.rotate(angle)
    -- Ruota il sistema di riferimento
    love.graphics.translate(- player.pos.x, - player.pos.y)
    -- Sposta il centro dove stava
    love.graphics.polygon("fill",
        player.pos.x,player.pos.y-player.size.y,
        player.pos.x+player.size.x,player.pos.y+player.size.y,
        player.pos.x,player.pos.y,
        player.pos.x - player.size.x,player.pos.y + player.size.y)
    -- Il giocatore è un poligono fatto con questi 4 punti
    love.graphics.pop()
    -- Disegna il giocatore, push e pop servono per resettare il sistema di coordinate

    for _, p in ipairs(projectiles) do
        love.graphics.circle("fill",p.pos.x,p.pos.y,5)
        -- Disegna i proiettili come piccoli cerchi
    end
    for _, e in ipairs(enemies) do
        love.graphics.circle("line",e.pos.x,e.pos.y,e.size)
        -- Disegna i nemici come cerchi vuoti
    end
end

-- Event handlers

-- Cosa succede quando il giocatore preme un pulsante
function love.keypressed(key,scancode,isrepeat)
    -- key e scancode sono simili, ma scancode funziona su tutte
    -- le tastiere, key no, isrepeat non ci serve
    if scancode == 'w' then
        player.vel.y = - SPEED
    elseif scancode == 'a' then
        player.vel.x = - SPEED
    elseif scancode == 's' then
        player.vel.y = SPEED
    elseif scancode == 'd' then
        player.vel.x = SPEED
    end
    -- Cambia la direzione della velocità in base al tasto che premi

    if scancode == 'q' then
        love.event.push("quit")
    end
    -- Chiudi il gioco con q
end

-- Quando viene lasciato un tasto
function love.keyreleased(key,scancode)
    if scancode == 'w' or scancode == 's' then
        if love.keyboard.isScancodeDown('w') then
            player.vel.y = - SPEED
        elseif love.keyboard.isScancodeDown('s') then
            player.vel.y = SPEED
        else
            player.vel.y = 0
        end
    elseif scancode == 'a' or scancode == 'd' then
        if love.keyboard.isScancodeDown('a') then
            player.vel.x = - SPEED
        elseif love.keyboard.isScancodeDown('d') then
            player.vel.x = SPEED
        else
            player.vel.x = 0
        end
    end
    -- Praticamente se tieni premuto entrambe le direzioni
    -- e poi lasci una, mette come direzione l'altra,
    -- più facile da capire provando senza
    -- Forse c'è un metodo più facile
end

-- Cosa succede se premi il mouse
function love.mousepressed( x, y, button, istouch, presses )
    a = math.atan2(y - player.pos.y,x - player.pos.x)            -- Angolo tra mouse e personaggio
    v = Vec2:new(1000 * math.cos(a),1000 * math.sin(a))  -- Velocità con modulo fisso
    p = Entity:new(Vec2:new(player.pos.x,player.pos.y),v)
    table.insert(projectiles,p)
    -- Aggiungi un nuovo proiettile
end

