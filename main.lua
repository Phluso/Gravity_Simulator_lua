require "Lua Library"
require "Menu lib"
require "Objects"
require "physics"

function love.load()
    
    love.window.setFullscreen(false)

    over = -1

    shader = love.graphics.newShader("render.frag", "vert.vert")
    canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

    window = {
        lar = love.graphics.getWidth(),
        alt = love.graphics.getHeight(),
        centerx = love.graphics.getWidth() / 2,
        centery = love.graphics.getHeight() / 2
    }

    menu = Menu:create(window.lar - 230, 0, 228, nil, {0, 0, 0, .5})
    rastro = Menu:checkbox(false)
    evolucaoEstelar = Menu:checkbox(true)
    precisionRange = Menu:range(0, 100, 100)
    menu:addRow({Menu:label("Opções")})
    menu:addRow({Menu:label("Exibir rastro:"), rastro})
    menu:addRow({Menu:label("Fusão nuclear nas estrelas:"), evolucaoEstelar})
    objectRadio = Menu:radio({
    {"Nebulosa", {massa = 0, densidade = 0, atmosfera = .015, fusaoNuclear = true, temperatura = 0, fixed = true}},
    {"Buraco negro", {massa = 1024, densidade = 255, atmosfera = 0, fusaoNuclear = false, temperatura = 0}},
    {"Anã Branca", {massa = 512, densidade = 80, atmosfera = 0, fusaoNuclear = false, temperatura = 10000}},
    {"Gigante azul", {massa = 500, densidade = .3, atmosfera = 0, fusaoNuclear = true, temperatura = 9000}},
    {"Gigante vermelha", {massa = 255, densidade = .7, atmosfera = 0, fusaoNuclear = true, temperatura = 6000}},
    {"Estrela", {massa = 100, densidade = 1, atmosfera = 0, fusaoNuclear = true, temperatura = 4000}},
    {"Planeta", {massa = 2, densidade = 1, atmosfera = 1, fusaoNuclear = false, temperatura = 0}}, 
    {"Asteroide", {massa = .2, densidade = 1, atmosfera = 0, fusaoNuclear = false, temperatura = 0}}, 
    {"Nave espacial", {tipo = "nave", massa = .1, atmosfera = 0, fixed = false}}}, 7)

    menu:addRow({Menu:label("Tipo de objeto")})
    menu:addRow({objectRadio.option[1]})
    menu:addRow({objectRadio.option[2]})
    menu:addRow({objectRadio.option[3]})
    menu:addRow({objectRadio.option[4]})
    menu:addRow({objectRadio.option[5]})
    menu:addRow({objectRadio.option[6]})
    menu:addRow({objectRadio.option[7]})
    menu:addRow({objectRadio.option[8]})
    menu:addRow({objectRadio.option[9]})

    speedRadio = Menu:radio({{"1x", 1}, {"2x", 2}, {"10x", 10}, {"100x", 100}, {"1000x", 1000}, {"10000x", 10000}})
    menuSimulacao = Menu:create(window.lar/2 - 400, 20, 800, nil, {0, 0, 0, .5})
    menuSimulacao:addRow({Menu:label("Precisão:"), precisionRange})
    menuSimulacao:addRow({Menu:label("Velocidade:"), speedRadio.option[1], speedRadio.option[2], speedRadio.option[3], speedRadio.option[4], speedRadio.option[5], speedRadio.option[6]})

    naveMenu = Menu:create(0, window.alt - 400, 250, nil, {0, 0, 0, .5})
    naveMenu:addRow({Menu:label("Direção automática da nave")})
    direcaoNave = Menu:radio({{"Manual", 0}, {"Prograde", 1}, {"Retrograde", 2}})
    naveMenu:addRow({direcaoNave.option[1], direcaoNave.option[2], direcaoNave.option[3]})
    naveMenu:addRow({Menu:label("Velocidade da nave:")}, 40)
    velocidadeNave = Menu:range(0, 500, 250)
    naveMenu:addRow({velocidadeNave}, 40)

    Objects:newStar(0, 0, 0, 0)
    Objects:newNebulosaClouds(0, 0, 20, 1000)

    cam = newCamera(0, 0, window.lar / 3, window.alt / 3, 1)
    cam.speedX = 0
    cam.speedY = 0

    --simulation precision (0-1)
    precision = 1

    --initial simulation speed
    simSpd = 1

    mass = 80

    placingObject = false
    mira = {
        x = 0,
        y = 0,
        iniX = 0,
        iniY = 0,
        iniScreenX = 0,
        iniScreenY = 0,
        projecaoX = {},
        projecaoY = {}
    }

    pause = false

    time = 0

    seguindo = nil

end

function love.update(dt)
    menu:update()
    menuSimulacao:update()
    naveMenu:update()

    --coordenadas do mouse em relação ao mundo, não a tela
    mousex = ((love.mouse.getX()) / (window.lar) - .5) * cam.width + cam.x
    mousey = ((love.mouse.getY()) / (window.alt) - .5) * cam.height + cam.y

    local camSpd = 20000

    --velocidade da simulação
    simSpd = speedRadio.value * boolToInt(not pause)
    
    if (love.keyboard.isDown("space")) then
        speedRadio.selected = 2
        speedRadio.value = speedRadio.option[2].value
        if (love.keyboard.isDown("lshift")) then
            speedRadio.selected = 3
            speedRadio.value = speedRadio.option[3].value
        end
    end

    --alterar precisão
    precision = precisionRange.value/100

    --alterar massa
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

    local camMov = {
        x = (boolToInt(love.keyboard.isDown("d")) - boolToInt(love.keyboard.isDown("a"))) * camSpd * dt * boolToInt(not placingObject),
        y = (boolToInt(love.keyboard.isDown("s")) - boolToInt(love.keyboard.isDown("w"))) * camSpd * dt * boolToInt(not placingObject)
    }

    cam.speedX = lerp(cam.speedX, camMov.x, .1)
    cam.speedY = lerp(cam.speedY, camMov.y, .1)

    cam.x = cam.x + cam.speedX * dt
    cam.y = cam.y + cam.speedY * dt

    if (camMov.x + camMov.y ~= 0) then 
        seguindo = nil
    end

    --zoom
    function love.wheelmoved(x, y)
        if (y > 0) then
            cam.zoom = cam.zoom + (cam.zoom * 3) * dt
        elseif (y < 0) then
            cam.zoom = cam.zoom - (cam.zoom * 3) * dt
        end
    end

    cam.zoom = clamp(cam.zoom, .001, 100)
    cam.width = window.lar / cam.zoom
    cam.height = window.alt / cam.zoom

    --+------------+
    --|INTERACTIONS|
    --+------------+
    physics(simSpd, dt)

    --mover a câmera para seguir o alvo
    if (seguindo) then
        cam.x = lerp(cam.x, seguindo.x, .1)
        cam.y = lerp(cam.y, seguindo.y, .1)

        if (seguindo.tipo == "Nave espacial") then
            seguindo.acceleration = velocidadeNave.value / 200000
            seguindo.rotationAcc = lerp(seguindo.rotationAcc, 0, dt * simSpd)
            seguindo.rotationAcc = seguindo.rotationAcc + (boolToInt(love.keyboard.isDown("right")) - boolToInt(love.keyboard.isDown("left"))) * seguindo.rotationSpeed * dt * simSpd
            seguindo.direction = seguindo.direction + seguindo.rotationAcc
            seguindo.xspd = seguindo.xspd + math.cos(seguindo.direction) * boolToInt(love.keyboard.isDown("up")) * seguindo.acceleration * simSpd * dt
            seguindo.yspd = seguindo.yspd + math.sin(seguindo.direction) * boolToInt(love.keyboard.isDown("up")) * seguindo.acceleration * simSpd * dt

            if direcaoNave.value == 1 then
                seguindo.direction = lerp(seguindo.direction, direction(0, 0, seguindo.xspd, seguindo.yspd), dt)
            elseif direcaoNave.value == 2 then
                seguindo.direction = lerp(seguindo.direction, direction(seguindo.xspd, seguindo.yspd, 0, 0), dt)
            end
        end
    end

    --resetar
    if (love.keyboard.isDown("tab")) then
        for i = 0, #Objects.list, 1 do
            Objects.list[i] = nil
        end
    end 

    --adcionar asteroides
    if (not menu.focus and not menuSimulacao.focus and not naveMenu.focus) then
        if (love.mouse.isDown(1)) then

            local randx = (love.math.random() - .5) * 50 / cam.zoom
            local randy = (love.math.random() - .5) * 50 / cam.zoom

            Objects:newAsteroid(mousex + randx, mousey + randy, 0, 0, Objects.list)
        end 
        if (love.mouse.isDown(2)) then
            if (placingObject == false) then
                placingObject = true
                mira.iniX = mousex
                mira.iniY = mousey
                mira.iniScreenX = ((mouseToCamera(cam).x-cam.x)/cam.width+.5)*window.lar
                mira.iniScreenY = ((mouseToCamera(cam).y-cam.y)/cam.height+.5)*window.alt
            end
        end
        if (placingObject) then
            pause = true

            local dist = distance(mira.iniX, mira.iniY, mousex, mousey)
            mira.x = mira.iniX + (mousex - mira.iniX)
            mira.y = mira.iniY + (mousey - mira.iniY)

            local o = objectRadio.value

            local oMass = o.massa + o.atmosfera

            local xspd = (mira.iniX - mousex) * dist / 10
            local yspd = (mira.iniY - mousey) * dist / 10
            
            local spd = {x = xspd, y = yspd}
            local pos = {x = mousex, y = mousey}
            
            for i = 1, 1000, 1 do
                for a = 0, 100, i do
                    for j, obj in ipairs(Objects.list) do
                        local objMass = obj.massa + obj.atmosfera
                        local atracao = calcAtracao(objMass, oMass, obj.x, obj.y, pos.x, pos.y)
                        local acc = calcAceleracao(pos.x, pos.y, obj.x, obj.y, atracao)

                        spd.x = spd.x + acc.x
                        spd.y = spd.y + acc.y
                    end
                end

                pos.x = pos.x + spd.x / oMass * dt
                pos.y = pos.y + spd.y / oMass * dt
                
                local pro = positionToCamera(pos.x, pos.y, cam)
                mira.projecaoX[i] = pos.x
                mira.projecaoY[i] = pos.y
            end

            if not(love.mouse.isDown(2)) then
                pause = false
                placingObject = false

                if (o.tipo) then
                    Objects:newSpaceship(mousex, mousey, xspd, yspd)   
                else
                    Objects:newObject(o.massa, o.densidade, o.atmosfera, mousex, mousey, xspd, yspd, (o.fixed or dist == 0), o.fusaoNuclear, 0, o.temperatura)
                end
            end
        end
    end

    --limitar posição da câmera
    cam.x = clamp(cam.x, -5000000, 5000000)
    cam.y = clamp(cam.y, -5000000, 5000000)

    --somar tempo
    time = time + dt * simSpd
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

    local lightPositions = {
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0},
        {-1, -1, 0}
    }

    local lightColors = {
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0}
    }

    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.setShader(shader)
    
    local positions = {}

    --desenhar objetos
    for i, v in ipairs(Objects.list) do

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
        local volumeMassaTela = clamp((v.massa / v.densidade * 3.14) * cam.zoom, 1, 999999)
        local volumeAtmosferaTela = clamp(((v.massa + v.atmosfera) / v.densidade * 3.14) * cam.zoom, 1, 999999)

            table.insert(positions, {v.x, v.y, v.massa / v.densidade, v.atmosfera or v.luminous or 0})

            --[[
            --desenhar atmosfera
            love.graphics.setColor(v.atmosphereColor.r, v.atmosphereColor.g, v.atmosphereColor.b, .5)
            love.graphics.circle("line", x, y, volumeAtmosferaTela)
            love.graphics.setColor(v.atmosphereColor.r, v.atmosphereColor.g, v.atmosphereColor.b, .4)
            love.graphics.circle("fill", x, y, volumeAtmosferaTela)

            --desenhar objeto
            love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)
            love.graphics.circle("fill", x, y, volumeMassaTela) 
            ]]
            --checa se o mouse está sobre o objeto
            if (over == v.id) then
                love.graphics.circle("line", x, y, volumeMassaTela + 5)
            end
            if (v.luminous > 0) then
                for i = 1, #lightPositions, 1 do
                    if (lightPositions[i][1] == -1) then
                        lightPositions[i][1] = x
                        lightPositions[i][2] = y
                        lightPositions[i][3] = volumeMassaTela*3.14*v.luminous

                        lightColors[i][1] = v.cor.r
                        lightColors[i][2] = v.cor.g
                        lightColors[i][3] = v.cor.b
                        break
                    end
                end
            end
        --[[
        else
            love.graphics.setColor(1, 1, 1, 1)
            local size = clamp(volumeMassaTela * 10, 5, 999999)
            volumeMassaTela = 10
            love.graphics.polygon("fill",
                x + math.cos(v.direction) * size, y + math.sin(v.direction) * size,
                x + math.sin(v.direction)/3 * size, y - math.cos(v.direction)/3 * size,
                x - math.sin(v.direction)/3 * size, y + math.cos(v.direction)/3 * size
            )
        end
        ]]
    end

    --desenhar mira
    if (placingObject == true) then
        love.graphics.setColor(1, 1, 1, .5)
        love.graphics.line(love.mouse.getX(), love.mouse.getY(), mira.iniScreenX, mira.iniScreenY)
        love.graphics.setColor(1, 1, 1, 1)

        --desenhar projeção
        for i = 2, #mira.projecaoX, 1 do
            local pos = {
                x = mira.projecaoX[i-1], 
                y = mira.projecaoY[i-1]
            }
            local nextPos = {
                x = mira.projecaoX[i],
                y = mira.projecaoY[i]
            }
            --calcular posição na tela
            local x1 = normal(pos.x, minx, maxx) * window.lar
            local y1 = normal(pos.y, miny, maxy) * window.alt

            local x2 = normal(nextPos.x, minx, maxx) * window.lar
            local y2 = normal(nextPos.y, miny, maxy) * window.alt

            --desenhar linhas
            love.graphics.line(x1, y1, x2, y2)
        end
    end
    if (shader:hasUniform("resolution")) then 
        --shader:send("lightPos", unpack(lightPositions))
        shader:send("objPos", unpack(positions))
        shader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        print(love.graphics.getWidth())
    end

    love.graphics.setCanvas(nil)

    love.graphics.draw(canvas, 0, 0, 0, 1, 1)

    love.graphics.setShader(nil)

    --dados do jogo
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Time: " .. tostring(round(time)), 10, 30)
    love.graphics.print("Objects: " .. tostring(#Objects.list), 10, 50)
    love.graphics.print("Simulation Speed: " .. tostring(simSpd), 10, 70)
    love.graphics.print("Simulation Precision: " .. tostring(precision * 100) .. "%", 10, 90)
    love.graphics.print("Coordinates: " .. tostring(round(cam.x)) .. " x " .. tostring(round(cam.y)), 10, 110)
    love.graphics.print("Camera Zoom: " .. tostring(cam.zoom), 10, 130)
    love.graphics.print("Current mass: " .. tostring(mass), 10, 150)
    if (seguindo ~= nil) then
        love.graphics.print("Following type: " .. seguindo.tipo, 10, 170)
        love.graphics.print("Following mass: " .. seguindo.massa, 10, 190)
        love.graphics.print("Following atmosphere: " .. seguindo.atmosfera, 10, 210)
        love.graphics.print("Following density: " .. seguindo.densidade, 10, 230)
        love.graphics.print("Following volume: " .. tostring(seguindo.massa / seguindo.densidade * 3.14), 10, 250)
        love.graphics.print("Following Speed: " .. tostring(distance(0, 0, seguindo.xspd, seguindo.yspd)/(seguindo.massa + seguindo.atmosfera)), 10, 270)
        love.graphics.print("Following Luminous: " .. tostring(seguindo.luminous), 10, 290)
        love.graphics.print("Following Temperature: " .. tostring(seguindo.temperature), 10, 310)
        love.graphics.print("Following color:\nr: " .. tostring(seguindo.cor.r) .. "\ng: " .. tostring(seguindo.cor.g) .. "\nb: " .. tostring(seguindo.cor.b), 10, 330)
    end

    menu:draw()
    menuSimulacao:draw()
    naveMenu:draw()

end

function love.keypressed(key)
    if (key == "escape") then
        pause = not pause
    end
end

