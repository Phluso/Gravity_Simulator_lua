Objects = {
    list = {}, 
    id = 0
}
Objects.__index = Objects

function Objects:newObject(mass, density, atmosphere, x, y, xspd, yspd, fixed, fusion, luminous, temperature)
    local object = {
        id              = Objects.id,
        massa           = mass or 1,
        atmosfera       = atmosphere or 0,
        hasAtmosphere   = (atmosphere ~= nil and atmosphere > 0) or false,
        densidade       = density or 0,
        tipo            = nil,
        cor             = {
            r = .7,
            g = .1,
            b = .2,
        },
        atmosphereColor = {
            r = math.random(),
            g = math.random(),
            b = math.random()
        },
        x               = x or 0,
        y               = y or 0,
        xspd            = xspd or 0,
        yspd            = yspd or 0,
        fixed           = fixed or false,
        nuclearFusion   = fusion or false,
        luminous        = luminous or 0,
        temperature     = temperature or 0,
        tailX           = {x},
        tailY           = {y},
        tailTime        = 1
    }
    
    Objects.id = Objects.id + 1

    setmetatable(object, Objects)
    object:specs()
    table.insert(Objects.list, object)
end

function Objects:newWhiteDwarf(x, y, xspd, yspd)
    Objects:newObject(1000, 128, -1, x, y, xspd, yspd, false, false, 1, 100000)
end

function Objects:newBlackHole(x, y, xspd, yspd)
    Objects:newObject(2048, 255, -1, x, y, xspd, yspd, false, false, 0, 0)
end

function Objects:newNebulosa(x, y)
    Objects:newObject(0, 0, .015, x, y, 0, 0, true, false, 0, 0)
end

function Objects:newNebulosaClouds(x, y, quantity, _radius)
    for i = 0, quantity, 1 do
        radius = math.random() * _radius + _radius
        Objects:newNebulosa(x + math.cos(i) * radius, y + math.sin(i) * radius) 
    end
end

function Objects:newBlueGiant(x, y, xspd, yspd)
    Objects:newObject(700, .2, -1, x, y, xspd, yspd, false, true, 5, 9000)
end

function Objects:newRedGiant(x, y, xspd, yspd)
    Objects:newObject(700, .75, -1, x, y, xspd, yspd, false, true, 2, 6000)
end

function Objects:newStar(x, y, xspd, yspd)
    Objects:newObject(100, 1, 0, x, y, xspd, yspd, false, true, 1, 4000)
end

function Objects:newAsteroid(x, y, xspd, yspd)
    Objects:newObject(.1, 1, .0001, x, y, xspd, yspd, false, false)
end

function Objects:newPlanet(x, y, xspd, yspd)
    Objects:newObject(10, 1, 2, x, y, xspd, yspd, false, false, false)
end

function Objects:newSpaceship(x, y, xspd, yspd)
    local spaceShip = {
        id = Objects.id,
        tipo = "Nave espacial",
        massa = .1,
        densidade = 1,
        x = x,
        y = y,
        acceleration = .0005,
        rotationSpeed = .3,
        xspd = xspd or 0,
        yspd = yspd or 0,
        fixed = false,
        direction = direction(0, 0, xspd, yspd) or 0,
        tailX = {x},
        tailY = {y},
        tailTime = 1,
        atmosfera = 0,
        temperature = 0,
        luminous = 0,
        hasAtmosphere = false,
        cor = {
            r = .7,
            g = .1,
            b = .2,
        },
        atmosphereColor = {
            r = 0,
            g = 0,
            b = 0
        }
    }
    Objects.id = Objects.id + 1
    setmetatable(spaceShip, Objects)
    table.insert(Objects.list, spaceShip)
end

function Objects:specs()
    local solMassa = 80

    --calcular massa e tipo do corpo celeste
--nebulosa
    if (self.densidade <= .001) then 
        self.tipo = "nebulosa" 
--buraco negro
    elseif (self.massa >= 1024) then 
        self.tipo = "buraco negro"
--anã branca
    elseif (self.temperature >= 10000 or self.densidade <= .015) then 
        self.tipo = "anã branca"
--estrela
    elseif (self.massa + self.atmosfera >= 60 and self.densidade <= 5) then 
        self.massa = self.massa + self.atmosfera
        self.tipo = "estrela"
--anã marrom
    elseif (self.massa + self.atmosfera >= 30) then 
        self.tipo = "anã marrom"
--gigante gasoso
    elseif (self.atmosfera >= self.massa) then 
        self.tipo = "gigante gasoso" 
--planeta
    elseif (self.massa >= 1) then 
            self.tipo = "planeta"
--asteroide
    else 
        self.tipo = "asteroide" 
    end

    if (self.tipo == "anã branca") then  --estágio final
        self.densidade = 80
        self.nuclearFusion = false
        self.luminous = 3
        self.cor.r = 1
        self.cor.g = 1
        self.cor.b = 1
        self.temperature = 100000
        self.nuclearFusion = false
        self.atmosfera = 0
        self.hasAtmophere = false
    elseif (self.tipo == "buraco negro") then
        self.cor.r = .3
        self.cor.g = .3
        self.cor.b = .3
        self.densidade = 512
        self.nuclearFusion = false
        self.luminous = 0
        self.atmosfera = 0
        self.hasAtmophere = false
    elseif (self.tipo == "estrela") then         --fase de estrela

        local colors = {
--anã marrom                --faixa de temperaturas
            {.7, .2, .2},   --3500 - 4000
--sequencia principal  
            {1, 1, 0},      --4001 - 6500
--gigante vermelha
            {1, 0, 0},      --6501 - 9000
--gigante azul
            {.6, .7, 1},     --9001 - 10000
--anã branca
            {1, 1, 1}       --10000 - .
        }

        local stage = 1
        local minTemp = 1
        local maxTemp = 4000
        if (self.temperature < 4000)     then stage = 1 minTemp = 3500 maxTemp = 4000
        elseif (self.temperature < 6500) then stage = 2 minTemp = 4000 maxTemp = 6500
        elseif (self.temperature < 9000) then stage = 3 minTemp = 6500 maxTemp = 9000
        elseif (self.temperature < 10000) then stage = 4 minTemp = 9000 maxTemp = 1000
        else stage = 5 minTemp = 10000 maxTemp = 99999 end
        
        self.nuclearFusion = true
        self.temperature = clamp(self.temperature, 3500, 999999)
        self.atmosfera = 0
        self.hasAtmophere = false
        self.densidade = 1.15 - normal(self.temperature, 3500, 10000)
        self.luminous = 1 + self.massa / 10000
        self.cor.r = lerp(colors[stage][1], colors[stage+1][1], normal(self.temperature, minTemp, maxTemp))
        self.cor.g = lerp(colors[stage][2], colors[stage+1][2], normal(self.temperature, minTemp, maxTemp))
        self.cor.b = lerp(colors[stage][3], colors[stage+1][3], normal(self.temperature, minTemp, maxTemp))
    elseif (self.tipo == "anã marrom") then         --anã marrom ou protoestrela
        self.cor.r = .5
        self.cor.g = .25
        self.cor.b = .25
        self.densidade = .95
        self.luminous = .8
        self.hasAtmophere = true
    elseif (self.tipo == "gigante gasoso") then
        self.cor.r = .75
        self.cor.g = .5
        self.cor.b = .25
        self.densidade = .95
        self.hasAtmophere = true
    elseif (self.tipo == "planeta") then
        self.cor.r = .2
        self.cor.g = .5
        self.cor.b = .7
        self.densidade = 1
        self.hasAtmophere = true
    elseif (self.tipo == "asteroide") then
        self.cor.r = .5
        self.cor.g = .1
        self.cor.b = .2
        self.densidade = 1.5
        self.hasAtmophere = true
    elseif (self.tipo == "nebulosa") then
        self.cor.r = .5
        self.cor.g = .5
        self.cor.b = .5
        self.densidade = .0001
        self.hasAtmophere = true
    end
end
