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

    local radius = 300
    for i = 0, 100, 1 do
        local x = love.math.random() * love.graphics.getWidth()
        local y = love.math.random() * love.graphics.getHeight()
        local dist = distance(x, y, window.centerx, window.centery)
        local xspd = lenx(window.centerx, x, dist)
        local yspd = leny(window.centery, y, dist)
        nBola(love.math.random() / 2, 
        0 + xspd * love.math.random() * radius, 
        0 + yspd * love.math.random() * radius, 
        0, 
        0
    )
    end
    --nBola(400, window.centerx, window.centery, 0, 0)

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

    if (love.keyboard.isDown("lshift")) then
        camSpd = camSpd * 10
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
                --remover objetos muito distantes da câmera
                --if (v.x < -5000) or (v.x > 5000) or (v.y < -5000) or (v.y > 5000) then table.remove(bolas, i) end
                if (i < maxInt) then                --limitar interações
                    for j, u in ipairs(bolas) do    --calcular as interações
                        if (v.fixed == nil or v.fixed == false) then
                            if (v.id ~= u.id) then  
                                --local dist = distance(v.x, v.y, u.x, u.y)
                                --v.xspd = v.xspd + (lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * u.massa / dist)
                                --v.yspd = v.yspd + (leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * u.massa / dist)
                                local atracao = (u.massa * v.massa) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
                                --colisão entre os planetas
                                if (circleColision(v.x, v.y, u.x, u.y, u.volume)) then
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
        local randx = (love.math.random() - .5) * 5
        local randy = (love.math.random() - .5) * 5

        local x = (mousex - cam.x) / ((cam.x + cam.width) - cam.x)
        local y = (mousey - cam.y) / ((cam.y + cam.height) - cam.y)

        nBola(.3, x * window.lar + randx, y * window.alt + randy, 0, 0)
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

        if not(love.mouse.isDown(2)) then
            local x = mousex + cam.x
            local y = mousey + cam.y
            nBola(mass, x, y, lenx(mousex, mira.iniX, dist) * dist / 2, leny(mousey, mira.iniY, dist) * dist / 2)
            pause = false
            placingObject = false
        end
    end


end

function love.draw()

    --desenhar planetas
    for i, v in ipairs(bolas) do

        local cw = cam.width / 2
        local ch = cam.height / 2

        local minx = cam.x - cw
        local maxx = cam.x + cw
        local miny = cam.y - ch
        local maxy = cam.y + ch

        local x = (v.x - minx) / (maxx - minx)
        local y = (v.y - miny) / (maxy - miny)
        if (collision(v.x, v.y, cam.x - cw, cam.y - ch, cam.x + cw, cam.y + ch)) then
            love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)

            love.graphics.circle("fill", x * window.lar, y * window.alt, v.volume / cam.zoom) 
            --love.graphics.circle("fill", v.x, v.y, v.volume / cam.zoom) 
        end
        --love.graphics.print(x, v.x, v.y)
        --love.graphics.print(x, v.x, v.y)
        --love.graphics.print(cam.x + cam.width, cam.x + cam.width, cam.y + cam.height)

        --verificar se está dentro da área da câmera (opcional)
        --calcular a posição normalizada em relação a área da câmera (0-1)
        --desenhar na posição normalizada multiplicada pelas dimensões da tela
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

    --love.graphics.rectangle("line", cam.x - cam.width / 2, cam.y - cam.height / 2, cam.width, cam.height)
    --love.graphics.circle("line", cam.x, cam.y, 10)

    --love.graphics.print(cursor.x, 100, 10)
    --love.graphics.print(mousex, 100, 30)




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

