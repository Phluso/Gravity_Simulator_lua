require "Lua Library"

function love.load()
    love.window.setFullscreen(true)

    window = {}
    window.lar = love.graphics.getWidth()
    window.alt = love.graphics.getHeight()
    window.centerx = love.graphics.getWidth() / 2
    window.centery = love.graphics.getHeight() / 2

    bolas = {}

    id = 0

    local radius = 3000
    for i = 0, 1000, 1 do
        local x = love.math.random() * love.graphics.getWidth()
        local y = love.math.random() * love.graphics.getHeight()
        local dist = distance(x, y, window.centerx, window.centery)
        local xspd = lenx(window.centerx, x, dist)
        local yspd = leny(window.centery, y, dist)
        nBola(love.math.random() * 2, 0 + xspd * love.math.random() * radius, 0 + yspd * love.math.random() * radius, 0, 0)
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

end

function love.update(dt)
    mousex = love.mouse.getX()
    mousey = love.mouse.getY()

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

    camSpd = camSpd * cam.zoom
    if (love.keyboard.isDown("a")) then
        cam.x = cam.x - camSpd * dt
    end
    if (love.keyboard.isDown("d")) then
        cam.x = cam.x + camSpd * dt
    end
    if (love.keyboard.isDown("w")) then
        cam.y = cam.y - camSpd * dt
    end
    if (love.keyboard.isDown("s")) then
        cam.y = cam.y + camSpd * dt
    end

    --zoom
    if (love.keyboard.isDown("q")) then
        cam.zoom = cam.zoom + (cam.zoom / 2.5) * dt
    end
    if (love.keyboard.isDown("e")) then
        cam.zoom = cam.zoom - (cam.zoom / 2.5) * dt
    end
    cam.width = window.lar * cam.zoom
    cam.height = window.alt * cam.zoom

    --calcular interações dos planetas
    local maxInt = #bolas * precision + 1
    if (simSpd > 0) then                            --caso não esteja pausado
        for t = 0, simSpd, 1 do                     --repetir os cálculos de acordo com a velocidade da simulação
            for i, v in ipairs(bolas) do            --calcular para cada objeto
                --remover se estiver muito longe do ponto inicial
                if not(collision(v.x, v.y, -50000, -50000, 50000, 50000)) then table.remove(bolas, i) end
                for j, u in ipairs(bolas) do        --calcular as interações
                    if (j < maxInt) then            --limitar interações
                        if (v.fixed == nil or v.fixed == false) then
                            if (v.id ~= u.id) then  
                                local atracao = (u.massa * v.massa) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
                                --colisão entre os planetas
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

                    --mover objetos
                    v.x = v.x + (v.xspd / v.massa * dt)
                    v.y = v.y + (v.yspd / v.massa * dt)
                end
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
        cam.zoom = 1

        local randx = (love.math.random() - .5) * 50
        local randy = (love.math.random() - .5) * 50

        nBola(.3, mousex - (cam.width / 2) + cam.x + randx, mousey - (cam.height / 2) + cam.y + randy, 0, 0)
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

        cam.zoom = 1

        local dist = distance(mira.iniX, mira.iniY, mousex, mousey)

        mira.x = mira.iniX + lenx(mousex, mira.iniX, dist)
        mira.y = mira.iniY + leny(mousey, mira.iniY, dist)

        local fixed = false

        if (dist <= 1) then
            fixed = true
        end

        if not(love.mouse.isDown(2)) then
            local xspd = clamp(lenx(mousex, mira.iniX, dist) * dist / 2, -100, 100)
            local yspd = clamp(leny(mousey, mira.iniY, dist) * dist / 2, -100, 100)
            nBola(mass, mousex - (cam.width / 2) + cam.x, mousey - (cam.height / 2) + cam.y, xspd, yspd, fixed)
            pause = false
            placingObject = false
        end
    end

    --limitar posição da câmera
    cam.x = clamp(cam.x, -50000, 50000)
    cam.y = clamp(cam.y, -50000, 50000)
end

function love.draw()

    local cw = cam.width / 2
    local ch = cam.height / 2

    local minx = cam.x - cw
    local maxx = cam.x + cw
    local miny = cam.y - ch
    local maxy = cam.y + ch

    --desenhar objetos
    for i, v in ipairs(bolas) do

        --calcular posição na tela
        local x = (v.x - minx) / (maxx - minx)
        local y = (v.y - miny) / (maxy - miny)

        love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)
        love.graphics.circle("fill", x * window.lar, y * window.alt, v.volume / cam.zoom) 
    end
    
    --desenhar mira
    if (placingObject == true) then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(mousex, mousey, mira.x, mira.y)
    end

    --dados do jogo
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(love.timer.getFPS(), 10, 10)
    love.graphics.print("Objects: " .. tostring(#bolas), 10, 30)
    love.graphics.print("Simulation Speed: " .. tostring(simSpd), 10, 50)
    love.graphics.print("Simulation Precision: " .. tostring(precision * 100) .. "%", 10, 70)
    love.graphics.print("Coordinates: " .. tostring(round(cam.x)) .. " x " .. tostring(round(cam.y)), 10, 90)
    love.graphics.print("Camera Zoom: " .. tostring(cam.zoom), 10, 110)
    love.graphics.print("Current mass: " .. tostring(mass), 10, 130)
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
    if (index.massa >= 512) then
        index.tipo = "buraco negro"
        index.cor.r = .3
        index.cor.g = .3
        index.cor.b = .3
        index.densidade = 512
    elseif (index.massa >= 400) then
        index.tipo = "anã branca"
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 1
        index.densidade = 512
    elseif (index.massa >= 250) then
        index.tipo = "gigante azul"
        index.cor.r = .15
        index.cor.g = .15
        index.cor.b = 1
        index.densidade = .7
    elseif (index.massa >= 200) then
        index.tipo = "gigante vermelha"
        index.cor.r = 1
        index.cor.g = .25
        index.cor.b = 0
        index.densidade = .8
    elseif (index.massa >= 100) then
        index.tipo = "estrela"
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 0
        index.densidade = .6
    elseif (index.massa >= 50) then
        index.tipo = "anã marrom"
        index.cor.r = .5
        index.cor.g = .25
        index.cor.b = .25
        index.densidade = 1.5
    elseif (index.massa >= 25) then
        index.tipo = "planeta gasoso"
        index.cor.r = .75
        index.cor.g = .5
        index.cor.b = .25
        index.densidade = .8
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

