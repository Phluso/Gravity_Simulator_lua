require "Objects"
require "Lua library"

function physics(v, i, speed, dt)
    local mov = {x= 0, y= 0}
    if (speed > 0) then                --calcular interações somente caso não esteja pausado
        for t = 0, speed, 1 do                     --repetir os cálculos de acordo com a velocidade da simulação
            for i, v in ipairs(Objects.list) do            --calcular para cada objeto
                if (not v.fixed) then
                    --adcionar posição nas arrays de rastro
                    if (rastro.value) then
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
                    end

                    --alterar a densidade no caso de estrelas
                    if (v.nuclearFusion and evolucaoEstelar.value) then
                        v.temperature = v.temperature + .01 * dt
                        v:specs()
                    end
                    
                    --remover se estiver muito longe do ponto inicial
                    if not(collision(v.x, v.y, -500000, -500000, 500000, 500000)) then
                        table.remove(Objects.list, i) 
                    end
                    for j, u in ipairs(Objects.list) do         --calcular as interações
                        if (math.random() <= precision) then    --limitar interações
                            if (v.id ~= u.id) then 
                                local atracao = 0 
                                if (not u.fixed) then
                                    atracao = ((u.massa + u.atmosfera) * (v.massa + v.atmosfera)) / math.pow(distance(v.x, v.y, u.x, u.y), 2)
                                    v.xspd = v.xspd + lenx(v.x, u.x, distance(v.x, v.y, u.x, u.y)) * atracao
                                    v.yspd = v.yspd + leny(v.y, u.y, distance(v.x, v.y, u.x, u.y)) * atracao
                                end
    --colisões
                                if (u.tipo ~= "nebulosa") then
                                    local vvolume = (v.massa / v.densidade * 3.14)
                                    local uvolume = (u.massa / u.densidade * 3.14)
                                    if (twoCircleCollision(v.x, v.y, u.x, u.y, vvolume, uvolume)) then
                                        if (u.massa >= v.massa) then
                                            print("\ncolisao\n")
                                            u.massa = u.massa + v.massa
                                            u.atmosfera = u.atmosfera + v.atmosfera
                                            v.atmosfera = 0
                                            --remove objeto menos massivo da lista
                                            table.remove(Objects.list, i)
                                            u:specs()
                                            --calcula a velocidade do objeto que sobrou
                                            u.xspd = ((u.massa + u.atmosfera) * u.xspd + (v.massa + v.atmosfera) * v.xspd) / ((u.massa + u.atmosfera) + (v.massa + v.atmosfera)) 
                                            u.yspd = ((u.massa + u.atmosfera) * u.yspd + (v.massa + v.atmosfera) * v.yspd) / ((u.massa + u.atmosfera) + (v.massa + v.atmosfera)) 
                                        end
                                    end
                                else
    --interações com nebulosas
                                    local vvolume = ((v.massa + v.atmosfera) / v.densidade * 3.14)
                                    local uvolume = (u.atmosfera / u.densidade * 3.14)

                                    if (twoCircleCollision(v.x, v.y, u.x, u.y, vvolume, uvolume)) then
                                        --incrementar a atmosfera ou a massa do objeto dentro da nebulosa
                                        if (v.hasAtmophere == true and v.atmosfera < v.massa * 5) then
                                            v.atmosfera = v.atmosfera + (u.atmosfera * v.massa/100)
                                        else
                                            v.massa = v.massa + (u.atmosfera * v.massa/1000000) * boolToInt(v.tipo ~= "Nave espacial")
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
                    --mover objetos
                    mov.x = v.x + v.xspd / (v.massa + v.atmosfera) * dt
                    mov.y = v.y + v.yspd / (v.massa + v.atmosfera) * dt
                end
            end
        end
    end
    return mov
end

rastro = {
    value = false
}
precision = 1
evolucaoEstelar = {value = true}
Objects:newPlanet(-100, 0, 10, 0)
Objects:newStar(500, 0, -10, 0)
Objects:newBlackHole(0, 1000, 0, 0)

for i = 0, 100, 1 do
    for i, v in ipairs(Objects.list) do
        v.x = v.x + physics(v, i, 1, .01).x * .01
        v.y = v.y + physics(v, i, 1, .01).y * .01
        print("id: " .. tostring(v.id) .. " coord: " .. tostring(v.x) .. " x " .. tostring(v.y) .. " tipo: " .. tostring(v.tipo))
    end 
    if #Objects.list == 0 then print("...") break end
end