function physics(speed, dt)
    over = -1
    if (speed > 0) then                                     --calcular interações somente caso não esteja pausado
        for t = 0, speed, 1 do                              --repetir os cálculos de acordo com a velocidade da simulação
            for i, v in ipairs(Objects.list) do             --calcular para cada objeto
                --remover se estiver muito longe do ponto inicial
                if not(collision(v.x, v.y, -5000000, -5000000, 5000000, 5000000)) then
                    if (seguindo == i) then seguindo = nil end
                    table.remove(Objects.list, i) 
                end
                --clique para seguir o objeto
                local volumeMassaTela = clamp((v.massa / v.densidade * 3.14) * cam.zoom, 1, 999999)
                if (circleCollision(v.x, v.y, mouseToCamera(cam).x, mouseToCamera(cam).y, volumeMassaTela / cam.zoom))then
                    over = v.id
                    if (middleClick())then
                        seguindo = v
                    end
                end
                if (not v.fixed and math.random() <= precision) then
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
                            v.tailTime = 1
                        end
                    end

                    --alterar a densidade no caso de estrelas
                    if (v.nuclearFusion and evolucaoEstelar.value) then
                        v.temperature = v.temperature + .01 * dt
                        v:specs()
                    end
                    

                    for j, u in ipairs(Objects.list) do         --calcular as interações
                        if (math.random() < precision) then    --limitar interações
                            if (v.id ~= u.id) then 
                                local atracao = calcAtracao(u.massa + u.atmosfera, v.massa + v.atmosfera, v.x, v.y, u.x, u.y)
                                if (u.fixed) then atracao = 0 end
                                local aceleracao = calcAceleracao(v.x, v.y, u.x, u.y, atracao)
                                v.xspd = v.xspd + aceleracao.x
                                v.yspd = v.yspd + aceleracao.y

                                local vvolume = (v.massa / v.densidade * 3.14)
                                local uvolume = (u.massa / u.densidade * 3.14)
                                if (u.tipo ~= "nebulosa") then  --colisões
                                    if (twoCircleCollision(v.x, v.y, u.x, u.y, vvolume, uvolume)) then
                                        if (u.massa >= v.massa) then
                                            u.massa = u.massa + v.massa
                                            u.atmosfera = u.atmosfera + v.atmosfera
                                            v.atmosfera = 0
                                            if (seguindo == v) then seguindo = u end
                                            --remove objeto menos massivo da lista
                                            table.remove(Objects.list, i)
                                            u:specs()
                                            --calcula a velocidade do objeto que sobrou
                                            u.xspd = ((u.massa + u.atmosfera) * u.xspd + (v.massa + v.atmosfera) * v.xspd) / ((u.massa + u.atmosfera) + (v.massa + v.atmosfera)) 
                                            u.yspd = ((u.massa + u.atmosfera) * u.yspd + (v.massa + v.atmosfera) * v.yspd) / ((u.massa + u.atmosfera) + (v.massa + v.atmosfera)) 
                                        end
                                    end
                                else                    --interações com nebulosas
                                    vvolume = ((v.massa + v.atmosfera) / v.densidade * 3.14)
                                    uvolume = (u.atmosfera / u.densidade * 3.14)

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
                    v.x = v.x + v.xspd / (v.massa + v.atmosfera) * dt
                    v.y = v.y + v.yspd / (v.massa + v.atmosfera) * dt
                end
            end
        end
    end
end

function calcAtracao(massa1, massa2, x1, y1, x2, y2)
    return (massa1 * massa2) / math.pow(distance(x1, y1, x2, y2), 2)
end

function calcAceleracao(x1, y1, x2, y2, forca)
    local acc = {
        x = lenx(x1, x2, distance(x1, y1, x2, y2)) * forca,
        y = lenx(y1, y2, distance(x1, y1, x2, y2)) * forca
    }
    return acc
end