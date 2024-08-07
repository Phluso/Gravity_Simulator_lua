require "Lua Library"

function love.load()
    love.window.setFullscreen(false)

    window = {}
    window.lar = love.graphics.getWidth()
    window.alt = love.graphics.getHeight()
    window.centerx = love.graphics.getWidth() / 2
    window.centery = love.graphics.getHeight() / 2

    bolas = {}

    id = 0

    local radius = 5000
    for i = 0, 1000, 1 do
        local x = love.math.random() * love.graphics.getWidth()
        local y = love.math.random() * love.graphics.getHeight()
        local dist = distance(x, y, window.centerx, window.centery)
        local xspd = lenx(window.centerx, x, dist)
        local yspd = leny(window.centery, y, dist)
        nBola(love.math.random() * 10, xspd * love.math.random() * radius, 0 + yspd * love.math.random() * radius, 0, 0)
    end

    
    cam = {}
    cam.x = 0
    cam.y = 0
    cam.width = window.lar / 3
    cam.height = window.alt / 3
    cam.zoom = 1

    cursor = {}
    cursor.x = 0
    cursor.y = 0

    --simulation precision (0-1)
    precision = 1

    --initial simulation speed
    simSpd = 1

    mass = 10

    placingObject = false
    mira = {}
    mira.x = 0
    mira.y = 0
    mira.iniX = 0
    mira.iniY = 0

    pause = false

    time = 0

    seguindo = {}
    seguindo.id = nil
    seguindo.x = nil
    seguindo.y = nil

end

function love.update(dt)
    --coordenadas do mouse em relação ao mundo, não a tela
    mousex = ((love.mouse.getX()) / (window.lar) - .5) * cam.width + cam.x
    mousey = ((love.mouse.getY()) / (window.alt) - .5) * cam.height + cam.y

    local camSpd = 200
    
    if (pause == false) then
        simSpd = 1
    else
        simSpd = 0
    end

    if (love.keyboard.isDown("space")) then
        simSpd = simSpd * 10
        if (love.keyboard.isDown("lshift")) then
            simSpd = simSpd * 100
        end
    end

    --aumentar precisão
    if (love.keyboard.isDown("right")) then
        precision = precision + .01
    end
    if (love.keyboard.isDown("left")) then
        precision = precision - .01
    end

    --aumentar massa
    if (love.keyboard.isDown("up")) then
        mass = mass + 128 * dt
    end
    if (love.keyboard.isDown("down")) then
        mass = mass - 128 * dt
    end

    mass = clamp(mass, .1, 1024)

    precision = clamp(precision, 0, 1)

    --mover câmera
    if (love.keyboard.isDown("lshift")) then
        camSpd = camSpd * 10
    end
    if (love.keyboard.isDown("lctrl")) then
        camSpd = camSpd / 5
    end
    camSpd = camSpd / cam.zoom

    if (love.keyboard.isDown("a")) then
        cam.x = cam.x - camSpd * dt
        seguindo.id = nil
    end
    if (love.keyboard.isDown("d")) then
        cam.x = cam.x + camSpd * dt
        seguindo.id = nil
    end
    if (love.keyboard.isDown("w")) then
        cam.y = cam.y - camSpd * dt
        seguindo.id = nil
    end
    if (love.keyboard.isDown("s")) then
        cam.y = cam.y + camSpd * dt
        seguindo.id = nil
    end

    if (seguindo.id ~= nil) then
        cam.x = seguindo.id.x
        cam.y = seguindo.id.y
    end

    --zoom
    if (love.keyboard.isDown("q")) then
        cam.zoom = cam.zoom - (cam.zoom / 2.5) * dt
    end
    if (love.keyboard.isDown("e")) then
        cam.zoom = cam.zoom + (cam.zoom / 2.5) * dt
    end
    cam.width = window.lar / cam.zoom
    cam.height = window.alt / cam.zoom

    --+------------+
    --|INTERACTIONS|
    --+------------+
    local maxInt = #bolas * precision + 1
    if (simSpd > 0) then                            --caso não esteja pausado
        for t = 0, simSpd, 1 do                     --repetir os cálculos de acordo com a velocidade da simulação
            for i, v in ipairs(bolas) do            --calcular para cada objeto
                if (love.mouse.isDown(3)) then
                    if (circleColision(mousex, mousey, v.x, v.y, v.volume * cam.zoom)) then
                        seguindo.id = v
                    end
                end
                --remover se estiver muito longe do ponto inicial
                if not(collision(v.x, v.y, -50000, -50000, 50000, 50000)) then table.remove(bolas, i) end
                for j, u in ipairs(bolas) do        --calcular as interações
                    if (j < maxInt) then            --limitar interações
                        if (v.fixed == nil or v.fixed == false) then
                            if (v.id ~= u.id) then  
                                local atracao = (u.massa * v.massa) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
                                --colisão entre os objetos
                                if (circleColision(v.x, v.y, u.x + (v.volume * sign(v.x - u.x)), u.y + (v.volume * sign(v.y - u.y)), u.volume)) then
                                    if (u.massa >= v.massa) then
                                        u.massa = u.massa + v.massa / 10
                                        table.remove(bolas, i)
                                        bolaSpecs(u) 
                                    end
                                end
                            end
                        end
                    end
                end
                --mover objetos
                v.x = v.x + (v.xspd / v.massa * dt)
                v.y = v.y + (v.yspd / v.massa * dt)
            end
        end
    end

    --resetar
    if (love.keyboard.isDown("tab")) then
        for i, v in ipairs(bolas) do
            table.remove(bolas, i)
        end
    end 

    --adcionar meteoros
    if (love.mouse.isDown(1)) then

        local randx = (love.math.random() - .5) * 50 / cam.zoom
        local randy = (love.math.random() - .5) * 50 / cam.zoom

        nBola(.1, mousex + randx, mousey + randy, 0, 0)
    end 
    if (love.mouse.isDown(2)) then
        if (placingObject == false) then
            placingObject = true
            mira.iniX = mousex
            mira.iniY = mousey
        end
    end
    if (placingObject == true) then
        pause = true

        local dist = distance(mira.iniX, mira.iniY, mousex, mousey)

        mira.x = mira.iniX + lenx(mousex, mira.iniX, dist)
        mira.y = mira.iniY + leny(mousey, mira.iniY, dist)

        local fixed = false

        if (dist == 0) then
            fixed = true
        end

        if not(love.mouse.isDown(2)) then
            local xspd = clamp(lenx(mousex, mira.iniX, dist) * dist / 2, -2, 2)
            local yspd = clamp(leny(mousey, mira.iniY, dist) * dist / 2, -2, 2)
            if (fixed == true) then xspd = 0 yspd = 0 end
            nBola(mass, mousex, mousey, xspd, yspd, fixed)
            pause = false
            placingObject = false
        end
    end

    --limitar posição da câmera
    cam.x = clamp(cam.x, -50000, 50000)
    cam.y = clamp(cam.y, -50000, 50000)

    --somar tempo
    time = time + dt * 100 * simSpd
end

function love.draw()

    --desenhar grade
    --[[local nx = window.lar / 10
    love.graphics.setColor(1, 1, 1, .2)
    for i = -5000, 5000, 1000 do
        love.graphics.line(i * cam.zoom - cam.x, 0, i * cam.zoom - cam.x, window.alt)
    end]]

    local cw = cam.width / 2
    local ch = cam.height / 2

    local minx = cam.x - cw
    local maxx = cam.x + cw
    local miny = cam.y - ch
    local maxy = cam.y + ch

    --desenhar objetos
    for i, v in ipairs(bolas) do

        --calcular posição na tela
        local x = (v.x - minx) / (maxx - minx) * window.lar
        local y = (v.y - miny) / (maxy - miny) * window.alt

        love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)
        love.graphics.circle("fill", x, y, v.volume * cam.zoom) 
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(x, y, x + v.xspd, y + v.yspd)
        --love.graphics.print(distance(x, y, x + v.xspd, y + v.yspd), x, y - 10)
    end
    
    --desenhar mira
    if (placingObject == true) then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(love.mouse.getX(), love.mouse.getY(), mira.x, mira.y)
    end

    --dados do jogo
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Time: " .. tostring(round(time)), 10, 30)
    love.graphics.print("Objects: " .. tostring(#bolas), 10, 50)
    love.graphics.print("Simulation Speed: " .. tostring(simSpd), 10, 70)
    love.graphics.print("Simulation Precision: " .. tostring(precision * 100) .. "%", 10, 90)
    love.graphics.print("Coordinates: " .. tostring(round(cam.x)) .. " x " .. tostring(round(cam.y)), 10, 110)
    love.graphics.print("Camera Zoom: " .. tostring(cam.zoom), 10, 130)
    love.graphics.print("Current mass: " .. tostring(mass), 10, 150)
    if (seguindo.id ~= nil) then
        love.graphics.print("Following type: " .. seguindo.id.tipo, 10, 170)
        love.graphics.print("Following mass: " .. seguindo.id.massa, 10, 190)
    end
end

function nBola(massa, x, y, xspd, yspd, fixed)
    local bola = {}
    bola.id = id
    bola.massa = massa
    bola.densidade = nil
    bola.volume = nil
    bola.tipo   = nil
    bola.cor = {}
    bola.cor.r = .7
    bola.cor.g = .1
    bola.cor.b = .2
    bola.x = x
    bola.y = y
    bola.xspd = xspd
    bola.yspd = yspd
    bola.fixed = fixed

    id = id + 1

    bolaSpecs(bola)

    table.insert(bolas, bola)
end

function bolaSpecs(index)
    --calcular massa e tipo do corpo celeste
    if (index.massa >= 1024) then
        index.tipo = "buraco negro"
        index.cor.r = .1
        index.cor.g = .1
        index.cor.b = .1
        index.densidade = 255
    elseif (index.massa >= 700) then
        index.tipo = "anã branca"
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 1
        index.densidade = 10
    elseif (index.massa >= 600) then
        index.tipo = "gigante azul"
        index.cor.r = .15
        index.cor.g = .15
        index.cor.b = 1
        index.densidade = .35
    elseif (index.massa >= 500) then
        index.tipo = "gigante vermelha"
        index.cor.r = 1
        index.cor.g = .25
        index.cor.b = 0
        index.densidade = .4
    elseif (index.massa >= 300) then
        index.tipo = "estrela"
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 0
        index.densidade = .6
    elseif (index.massa >= 110) then
        index.tipo = "anã marrom"
        index.cor.r = .5
        index.cor.g = .25
        index.cor.b = .25
        index.densidade = .75
    elseif (index.massa >= 30) then
        index.tipo = "planeta gasoso"
        index.cor.r = .75
        index.cor.g = .5
        index.cor.b = .25
        index.densidade = .5
    elseif (index.massa >= 1) then
        index.tipo = "planeta rochoso"
        index.cor.r = .2
        index.cor.g = .5
        index.cor.b = .7
        index.densidade = 1
    elseif (index.massa < 1) then
        index.tipo = "asteroide"
        index.cor.r = .5
        index.cor.g = .1
        index.cor.b = .2
        index.densidade = .75
    end

    --calcular o volume do planeta com base na massa e densidade
    index.volume = index.massa / index.densidade * 3.14
end

function love.keypressed(key)
    if (key == "escape") then
        pause = not pause
    end
end

