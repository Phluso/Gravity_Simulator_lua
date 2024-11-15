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

    --nBola(4096, 0, 0, 0, 0)

    --[[local radius = 50000
    for i = 0, 500, 1 do
        local x = love.math.random() * love.graphics.getWidth()
        local y = love.math.random() * love.graphics.getHeight()
        local dist = distance(x, y, window.centerx, window.centery)
        local xspd = lenx(window.centerx, x, dist)
        local yspd = leny(window.centery, y, dist)
        nBola(80, xspd * love.math.random() * radius, 0 + yspd * love.math.random() * radius, 0, 0)
    end]]
    nBola(80, 0, 0, 0, 0, false)
    nBola(1, 0, 500, 3.61, 0)
    nBola(2, 0, 1500, 4.2, 0)
    nBola(15, 0, 10000, 11.85, 0)
    nBola(20, 0, 20000, 11.85, 0)

    
    cam = newCamera(0, 0, window.lar / 3, window.alt / 3, .025)

    --simulation precision (0-1)
    precision = 1

    --initial simulation speed
    simSpd = 1

    mass = 80

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
    
    --velocidade da simulação
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
    cam.zoom = clamp(cam.zoom, 0, 100)
    cam.width = window.lar / cam.zoom
    cam.height = window.alt / cam.zoom

    --+------------+
    --|INTERACTIONS|
    --+------------+
    local maxInt = #bolas * precision + 1
    for t = 0, simSpd, 1 do                     --repetir os cálculos de acordo com a velocidade da simulação
        for i, v in ipairs(bolas) do            --calcular para cada objeto
            --seguir
            if (love.mouse.isDown(3)) then
                if (circleColision(mousex, mousey, v.x, v.y, (v.massa / v.densidade * 3.14) * cam.zoom)) then
                    seguindo.id = v
                end
            end
            if (simSpd > 0) then                --calcular interações somente caso não esteja pausado
            --adcionar posição nas arrays de rastro
            v.tailTime = v.tailTime - dt
            if (v.tailTime <= 0) then
                if (#v.tailX < 300) then
                    --adicionar posição atual
                    table.insert(v.tailX, v.x)
                    table.insert(v.tailY, v.y)
                else
                    --remover primeiro indice
                    table.remove(v.tailX, 1)
                    table.remove(v.tailY, 1)
                    --adicionar posição atual
                    table.insert(v.tailX, v.x)
                    table.insert(v.tailY, v.y)
                end
                v.tailTime = 10
            end
            --alterar a densidade no caso de estrelas
            if (v.tipo == "estrela madura" or v.tipo == "gigante vermelha" or v.tipo == "gigante azul") then
                v.densidade = v.densidade - .00001 * dt
            end
            bolaSpecs(v)
            --remover se estiver muito longe do ponto inicial
                if not(collision(v.x, v.y, -500000, -500000, 500000, 500000)) then table.remove(bolas, i) end
                for j, u in ipairs(bolas) do        --calcular as interações
                    if (j < maxInt) then            --limitar interações
                        if (v.fixed == nil or v.fixed == false) then
                            if (v.id ~= u.id) then  
                                local atracao = (u.massa * v.massa) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
                                --colisão entre os objetos
                                local vvolume = (v.massa / v.densidade * 3.14)
                                local uvolume = (u.massa / u.densidade * 3.14)
                                if (circleColision(v.x + v.xspd, v.y + v.yspd, u.x + u.xspd + (vvolume * sign(v.x - u.x)), u.y + u.yspd + (vvolume * sign(v.y - u.y)), uvolume)) then
                                    if (u.massa >= v.massa) then
                                        u.massa = u.massa + v.massa
                                        table.remove(bolas, i)
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
        for i = 0, #bolas, 1 do
            bolas[i] = nil
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
    cam.x = clamp(cam.x, -500000, 500000)
    cam.y = clamp(cam.y, -500000, 500000)

    --somar tempo
    time = time + dt * 100 * simSpd
end


--[[ DESENHAR ]] -- /////////////////////////////////////////////////////////////////////////////////////
--[[ DESENHAR ]] -- /////////////////////////////////////////////////////////////////////////////////////
--[[ DESENHAR ]] -- /////////////////////////////////////////////////////////////////////////////////////
--[[ DESENHAR ]] -- /////////////////////////////////////////////////////////////////////////////////////
--[[ DESENHAR ]] -- /////////////////////////////////////////////////////////////////////////////////////


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
        local x = normal(v.x, minx, maxx) * window.lar
        local y = normal(v.y, miny, maxy) * window.alt

        love.graphics.setColor(1, 1, 1, .3)

        for t = 2, #v.tailX, 1 do
            local tx1 = normal(v.tailX[t], minx, maxx) * window.lar
            local ty1 = normal(v.tailY[t], miny, maxy) * window.alt

            local tx2 = normal(v.tailX[t -1], minx, maxx) * window.lar
            local ty2 = normal(v.tailY[t -1], miny, maxy) * window.alt
            --desenhar rastro
            love.graphics.line(tx1, ty1, tx2, ty2)
        end

        --desenhar objeto
        love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)
        love.graphics.circle("fill", x, y, clamp((v.massa / v.densidade * 3.14) * cam.zoom, 1, 999999)) 
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
        love.graphics.print("Following density: " .. seguindo.id.densidade, 10, 210)
        love.graphics.print("Following volume: " .. tostring(seguindo.id.massa / seguindo.id.densidade * 3.14), 10, 230)
    end
end

function nBola(massa, x, y, xspd, yspd, fixed)
    local bola = {}
    bola.id = id
    bola.massa = massa
    bola.densidade = 1
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

    bola.tailX = {x}
    bola.tailY = {y}
    bola.tailTime = 1

    id = id + 1

    bolaSpecs(bola)

    table.insert(bolas, bola)
end

function bolaSpecs(index)
    local terraMassa = 1
    local solMassa = 80

    --calcular massa e tipo do corpo celeste
    if (index.densidade >= 255) or (index.tipo == "buraco negro") then index.tipo = "buraco negro"
    elseif (index.densidade <= .15) or (index.tipo == "anã branca") then index.tipo = "anã branca"
    elseif (index.massa >= solMassa * 10) or (index.densidade <= .25) then index.tipo = "gigante azul"
    elseif (index.massa >= solMassa * 7) or (index.densidade <= .5) then index.tipo = "gigante vermelha"
    elseif (index.massa >= solMassa) then index.tipo = "estrela madura"
    elseif (index.massa >= terraMassa * 40) then index.tipo = "anã marrom"
    elseif (index.massa >= terraMassa * 15) then index.tipo = "gigante" 
    elseif (index.massa >= terraMassa) then index.tipo = "planeta"
    else index.tipo = "asteroide" end

    if (index.densidade <= .01) then index.tipo = "nebulosa" end

    if (index.tipo == "anã branca") then  --estágio final
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 1
        index.densidade = 80
        if (index.massa >= solMassa * 12) then
            index.tipo = "buraco negro"
            index.cor.r = .3
            index.cor.g = .3
            index.cor.b = .3
            index.densidade = 512
        end
    elseif (index.tipo == "gigante azul") then
        index.cor.r = .6
        index.cor.g = .6
        index.cor.b = 1
        --index.densidade = .45
    elseif (index.tipo == "gigante vermelha") then     --início do estágio de gigante vermelha
        index.cor.r = 1
        index.cor.g = .25
        index.cor.b = 0
        --index.densidade = .6
    elseif (index.tipo == "estrela madura") then         --fase madura da estrela
        index.cor.r = 1
        index.cor.g = 1
        index.cor.b = 0
        --index.densidade = .8
    elseif (index.tipo == "anã marrom") then         --anã marrom ou protoestrela
        index.cor.r = .5
        index.cor.g = .25
        index.cor.b = .25
        index.densidade = .95
    elseif (index.tipo == "gigante") then
        index.cor.r = .75
        index.cor.g = .5
        index.cor.b = .25
        index.densidade = .95
    elseif (index.tipo == "planeta") then
        index.cor.r = .2
        index.cor.g = .5
        index.cor.b = .7
        index.densidade = 1
    elseif (index.tipo == "asteroide") then
        index.cor.r = .5
        index.cor.g = .1
        index.cor.b = .2
        index.densidade = 1.5
    elseif (index.tipo == "nebulosa") then
        index.cor.r = .5
        index.cor.g = .5
        index.cor.b = .5
        index.densidade = .0001
    end
end

function love.keypressed(key)
    if (key == "escape") then
        pause = not pause
    end
end

