function input(_key)

    if (love.keyboard.isDown(_key)) then
        return 1
    else
        return 0
    end

end

function sign(n)
    if (n < 0) then
        return -1
    else
        return 1
    end
end

function fract(n)
    return n % 1;
end

function lerp(n1, n2, l)
	return n1 + (n2 - n1) * l
end

function round(n)
    if (fract(n) < .5) then     --arredondar pra baixo
        n = math.floor(n);
    else                        --arredondar pra cima
        n = math.ceil(n);
    end

    return n;
end

function clamp(n, min, max)
    if (n < min) then n = min elseif n > max then n = max end
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
    if (x >= x1) and (x <= x2) and (y >= y1) and (y <= y2) then return true else return false end
end

function circleColision(x, y, circlex, circley, radius)
    if (distance(x, y, circlex, circley) <= radius) then
        return true
    else
        return false
    end
end

function lenx(x1, x2, distance)
    return (x2 - x1) / distance
end

function leny(y1, y2, distance)
    return (y2 - y1) / distance
end

function normal(n, min, max)
    -- return a normalized value between 0 to 1

    return (n - min) / (max - min)
end

function newCamera(x, y, width, height, zoom)
    -- create a camera that is stored in a variable
    local camera = {}
    camera.x        = x         or 0
    camera.y        = y         or 0
    camera.width    = width     or 720
    camera.height   = height    or 360
    camera.zoom     = zoom      or 1

    return camera
end

function mouseToCamera(camera)
    -- return the mouse position relative to the camera
    local mouse = {}
    mouse.x = ((love.mouse.getX()) / (window.lar) - .5) * cam.width + cam.x
    mousey = ((love.mouse.getY()) / (window.alt) - .5) * cam.height + cam.y
end

function drawInCamera(object, camera)
    -- draw a object or a list of objects in the screen with a position relative to the camera
end
