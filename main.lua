require "Lua Library"
require "Menu lib"
require "Objects"

function love.load()
    love.window.setFullscreen(true)

    shader = love.graphics.newShader("frag.frag", "vert.vert")
    canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

    window = {
        lar = love.graphics.getWidth(),
        alt = love.graphics.getHeight(),
        centerx = love.graphics.getWidth() / 2,
        centery = love.graphics.getHeight() / 2
    }

    menu = Menu:create(window.lar - 230, 0, 230, 600)
    rastro = Menu:checkbox(true)
    evolucaoEstelar = Menu:checkbox(false)
    precisionRange = Menu:range(0, 100, 10)
    menu:addRow({Menu:label("Opções")})
    menu:addRow({Menu:label("Exibir rastro:"), rastro})
    menu:addRow({Menu:label("Fusão nuclear nas estrelas:"), evolucaoEstelar})
    --[[massRadio = Menu:radio({{"Buraco negro", Objects:newBlackHole},
    {"Anã Branca", Objects:newWhiteDwarf},
    {"Gigante azul", Objects:newBlueGiant},
    {"Gigante vermelha", Objects:newRedGiant},
    {"Estrela", Objects:newStar},
    {"Planeta", Objects:newWhiteDwarf}})

    menu:addRow({massRadio.option[1].label, massRadio.option[1]})
    menu:addRow({massRadio.option[2].label, massRadio.option[2]})
    menu:addRow({massRadio.option[3].label, massRadio.option[3]})
    menu:addRow({massRadio.option[4].label, massRadio.option[4]})
    menu:addRow({massRadio.option[5].label, massRadio.option[5]})
    menu:addRow({massRadio.option[6].label, massRadio.option[6]})]]

    speedRadio = Menu:radio({{"1x", 1}, {"2x", 2}, {"10x", 10}, {"100x", 100}, {"1000x", 1000}, {"10000x", 10000}})
    menuSimulacao = Menu:create(window.lar/2 - 400, 20, 800, 120)
    menuSimulacao:addRow({Menu:label("Precisão:"), precisionRange})
    menuSimulacao:addRow({Menu:label("Velocidade:"), speedRadio.option[1], speedRadio.option[2], speedRadio.option[3], speedRadio.option[4], speedRadio.option[5], speedRadio.option[6]})

    naveMenu = Menu:create(0, window.alt - 400, 250)
    naveMenu:addRow({Menu:label("Direção automática da nave")})
    direcaoNave = Menu:radio({{"Manual", 0}, {"Prograde", 1}, {"Retrograde", 2}})
    naveMenu:addRow({direcaoNave.option[1], direcaoNave.option[2], direcaoNave.option[3]})

    Objects.list = {}

    id = 0

    Objects:newPlanet(0, 0, 0, 0)
    Objects:newSpaceship(500, 500)

    cam = newCamera(0, 0, window.lar / 3, window.alt / 3, 1)

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
        iniY = 0
    }

    pause = false

    time = 0

    seguindo = {}
    seguindo.id = nil
    seguindo.x = nil
    seguindo.y = nil

end

function love.update(dt)
    menu:update()
    menuSimulacao:update()
    naveMenu:update()

    --coordenadas do mouse em relação ao mundo, não a tela
    mousex = ((love.mouse.getX()) / (window.lar) - .5) * cam.width + cam.x
    mousey = ((love.mouse.getY()) / (window.alt) - .5) * cam.height + cam.y

    local camSpd = 200

    --velocidade da simulação
    if (pause == false) then
        simSpd = speedRadio.value
    else
        simSpd = 0
    end
    
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
    --mass = massRadio.value

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
        x = (boolToInt(love.keyboard.isDown("d")) - boolToInt(love.keyboard.isDown("a"))) * camSpd * dt,
        y = (boolToInt(love.keyboard.isDown("s")) - boolToInt(love.keyboard.isDown("w"))) * camSpd * dt
    }

    if (camMov.x ~= 0 or camMov.y ~= 0) then 
        seguindo.id = nil
    end

    cam.x = cam.x + camMov.x
    cam.y = cam.y + camMov.y

    --zoom
    if (love.keyboard.isDown("q")) then
        cam.zoom = cam.zoom - (cam.zoom / 2.5) * dt
    end
    if (love.keyboard.isDown("e")) then
        cam.zoom = cam.zoom + (cam.zoom / 2.5) * dt
    end
    cam.zoom = clamp(cam.zoom, 0, 10000)
    cam.width = window.lar / cam.zoom
    cam.height = window.alt / cam.zoom

    --+------------+
    --|INTERACTIONS|
    --+------------+

    if (simSpd > 0) then                --calcular interações somente caso não esteja pausado
        for t = 0, simSpd, 1 do                     --repetir os cálculos de acordo com a velocidade da simulação
            for i, v in ipairs(Objects.list) do            --calcular para cada objeto
                --adcionar posição nas arrays de rastro
                if (rastro.value == true) then
                    v.tailTime = v.tailTime - dt
                else
                    v.tailX = {}
                    v.tailY = {}
                end
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
                if (v.nuclearFusion == true) and (evolucaoEstelar.value == true) then
                    v.temperature = v.temperature + .01 * dt
                    v:specs()
                end
                
                --remover se estiver muito longe do ponto inicial
                if not(collision(v.x, v.y, -500000, -500000, 500000, 500000)) then
                    table.remove(Objects.list, i) 
                end
                for j, u in ipairs(Objects.list) do        --calcular as interações
                    if (v.fixed == false) then
                        if (math.random() <= precision) then  --limitar interações
                            if (v.id ~= u.id) then  
                                local atracao = (u.massa * v.massa) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
--colisões
                                if (u.tipo ~= "nebulosa") then
                                    local vvolume = (v.massa / v.densidade * 3.14)
                                    local uvolume = (u.massa / u.densidade * 3.14)
                                    if (twoCircleCollision(v.x, v.y, u.x, u.y, vvolume, uvolume)) then
                                        if (u.massa >= v.massa) then
                                            u.massa = u.massa + v.massa
                                            u.atmosfera = u.atmosfera + v.atmosfera
                                            --remove objeto menos massivo da lista
                                            table.remove(Objects.list, i)
                                            u:specs()
                                            --calcula a velocidade do objeto que sobrou
                                            u.xspd = (u.massa * u.xspd + v.massa * v.xspd) / (u.massa + v.massa) 
                                            u.yspd = (u.massa * u.xspd + v.massa * v.xspd) / (u.massa + v.massa) 
                                        end
                                    end
                                else
--interações com nebulosas
                                    local vvolume = ((v.massa + v.atmosfera) / v.densidade * 3.14)
                                    local uvolume = (u.atmosfera / u.densidade * 3.14)

                                    if (twoCircleCollision(v.x, v.y, u.x, u.y, vvolume, uvolume)) then
                                        --incrementar a atmosfera ou a massa do objeto dentro da nebulosa
                                        if (v.atmosfera >= 0) then
                                            v.atmosfera = v.atmosfera + (u.atmosfera * v.massa/100)
                                        else
                                            v.massa = v.massa + (u.atmosfera * v.massa/100000)
                                        end
                                        --alterar a cor
                                        v.atmosphereColor.r = lerp(v.atmosphereColor.r, u.atmosphereColor.r, .01)
                                        v.atmosphereColor.g = lerp(v.atmosphereColor.g, u.atmosphereColor.g, .01)
                                        v.atmosphereColor.b = lerp(v.atmosphereColor.b, u.atmosphereColor.b, .01)
                                        if (v.tipo ~= "Nave espacial") then
                                            v:specs()
                                        end
                                        --decrementar a atmosfera da nebulosa
                                        u.atmosfera = u.atmosfera - (u.atmosfera * v.massa/100000)
                                        if (u.atmosfera <= .001) then
                                            table.remove(Objects.list, j)
                                        end
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

    --mover a câmera para seguir o alvo
    if (seguindo.id ~= nil) then
        cam.x = seguindo.id.x
        cam.y = seguindo.id.y

        if (seguindo.id.tipo == "Nave espacial") then
            seguindo.id.direction = seguindo.id.direction + (boolToInt(love.keyboard.isDown("right")) - boolToInt(love.keyboard.isDown("left"))) * seguindo.id.rotationSpeed * dt
            seguindo.id.xspd = seguindo.id.xspd + math.cos(seguindo.id.direction) * boolToInt(love.keyboard.isDown("up")) * seguindo.id.acceleration * simSpd * dt
            seguindo.id.yspd = seguindo.id.yspd + math.sin(seguindo.id.direction) * boolToInt(love.keyboard.isDown("up")) * seguindo.id.acceleration * simSpd * dt

            if direcaoNave.value == 1 then
                seguindo.id.direction = direction(0, 0, seguindo.id.xspd, seguindo.id.yspd)
            elseif direcaoNave.value == 2 then
                seguindo.id.direction = direction(seguindo.id.xspd, seguindo.id.yspd, 0, 0)
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
            if (not placingObject) then
                placingObject = true
                mira.iniX = love.mouse.getX()
                mira.iniY = love.mouse.getY()
            end
        end
        if (placingObject) then
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
                --Objects:newObject(mass, mousex, mousey, xspd, yspd, Objects.list, fixed)
                pause = false
                placingObject = false
            end
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
        if (v.tipo ~= "Nave espacial") then
            --desenhar atmosfera
            love.graphics.setColor(v.atmosphereColor.r, v.atmosphereColor.g, v.atmosphereColor.b, .5)
            love.graphics.circle("line", x, y, volumeAtmosferaTela)
            love.graphics.setColor(v.atmosphereColor.r, v.atmosphereColor.g, v.atmosphereColor.b, .4)
            love.graphics.circle("fill", x, y, volumeAtmosferaTela)

            --desenhar objeto
            love.graphics.setColor(v.cor.r, v.cor.g, v.cor.b, 1)
            love.graphics.circle("fill", x, y, volumeMassaTela) 

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

        --clique para seguir o objeto
        if (circleCollision(x, y, love.mouse.getX(), love.mouse.getY(), volumeMassaTela))then
            love.graphics.circle("line", x, y, volumeMassaTela + 5)
            if (love.mouse.isDown(3))then
                seguindo.id = v
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    --desenhar mira
    if (placingObject == true) then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(love.mouse.getX(), love.mouse.getY(), mira.x, mira.y)
    end

    love.graphics.setShader(shader)

    if (shader:hasUniform("lightPos")) then 
        shader:send("lightPos", unpack(lightPositions))
        shader:send("lightColor", unpack(lightColors))
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
    if (seguindo.id ~= nil) then
        love.graphics.print("Following type: " .. seguindo.id.tipo, 10, 170)
        love.graphics.print("Following mass: " .. seguindo.id.massa, 10, 190)
        love.graphics.print("Following atmosphere: " .. seguindo.id.atmosfera, 10, 210)
        love.graphics.print("Following density: " .. seguindo.id.densidade, 10, 230)
        love.graphics.print("Following volume: " .. tostring(seguindo.id.massa / seguindo.id.densidade * 3.14), 10, 250)
        love.graphics.print("Following Speed: " .. tostring(distance(0, 0, seguindo.id.xspd, seguindo.id.yspd)), 10, 270)
        love.graphics.print("Following Luminous: " .. tostring(seguindo.id.luminous), 10, 290)
        love.graphics.print("Following Temperature: " .. tostring(seguindo.id.temperature), 10, 310)
        love.graphics.print("Following color:\nr: " .. tostring(seguindo.id.cor.r) .. "\ng: " .. tostring(seguindo.id.cor.g) .. "\nb: " .. tostring(seguindo.id.cor.b), 10, 330)
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

