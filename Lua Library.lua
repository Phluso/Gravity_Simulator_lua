function input(_key)
    return (love.keyboard.isDown(_key))

end

function sign(n)
    if (n < 0) then
        return -1
    end
    return 1
end

function fract(n)
    return n % 1;
end

function lerp(n1, n2, l)
	return n1 + (n2 - n1) * l
end

function round(n)
    if (fract(n) < .5) then     --arredondar pra baixo
        return math.floor(n);
    end                         --arredondar pra cima
    return math.ceil(n);
end

function clamp(n, min, max)
    if (n < min) then 
        return min
    elseif (n > max) then 
        return max
    end
    return n
end

function direction(x1, y1, x2, y2) 
    return math.atan2(y2 - y1, x2 - x1);
end

function distance(x1, y1, x2, y2)
    local ct1 = math.abs(x1 - x2)    --cateto 1
    local ct2 = math.abs(y1 - y2)    --cateto 2
    return math.sqrt((ct1 * ct1) + (ct2 * ct2)) --hipotenusa
end

function collision(x, y, x1, y1, x2, y2)
    return ((x >= x1) and (x <= x2) and (y >= y1) and (y <= y2))
end

function circleCollision(x, y, circlex, circley, radius)
    return (distance(x, y, circlex, circley) <= radius)
end

function twoCircleCollision(x1, y1, x2, y2, radius1, radius2)
    return (distance(x1, y1, x2, y2) <= radius1 + radius2)
end

function normal(n, min, max)
    -- return a normalized value between 0 to 1

    return (n - min) / (max - min)
end

function newCamera(x, y, width, height, zoom)
    -- create a camera that is stored in a variable
    local camera = {
        x        = x         or 0,
        y        = y         or 0,
        width    = width     or 720,
        height   = height    or 360,
        zoom     = zoom      or 1
    }

    return camera
end

function mouseToCamera(camera)
    -- return the mouse position relative to the camera
    local mouse = {
        x = ((love.mouse.getX()) / (window.lar) - .5) * camera.width + camera.x,
        y = ((love.mouse.getY()) / (window.alt) - .5) * camera.height + camera.y
    }

    return mouse
end

function positionToCamera(x, y, camera)
    local position = {
        x = (x / (window.lar) - .5) * camera.width + camera.x,
        y = (y / (window.alt) - .5) * camera.height + camera.y
    }
    return position
end

function drawInCamera(object, camera)
    -- draw a object or a list of objects in the screen with a position relative to the camera
end

libClick = {
    leftClick = -1,
    rightClick = -1,
    middleClick = -1
}

function leftClick()
    if (love.mouse.isDown(1))then
        if (libClick.leftClick == -1) then
            libClick.leftClick = time
        end
        libClick.leftClick = -1
        return (time == libClick.leftClick)
    end
    return false
end

function rightClick()
    if (love.mouse.isDown(2))then
        if (libClick.rightClick == -1) then
            libClick.rightClick = time
        end
        libClick.rightClick = -1
        return (time == libClick.rightClick)
    end
    return false
end

function middleClick()
    if (love.mouse.isDown(3))then
        if (libClick.middleClick == -1) then
            libClick.middleClick = time
        end
        return (time == libClick.middleClick)
    end
    libClick.middleClick = -1
    return false
end

function boolToInt(bool)
    return bool and 1 or 0
end