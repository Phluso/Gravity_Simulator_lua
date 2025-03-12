Menu = {
    focus = false
}
Menu.__index = Menu

function Menu:create(x, y, width, height, color)
    local menu = {
        x = x or 0,
        y = y or 0,
        width = width or 200,
        height = height or 0,
        rows = {},
        focus = false,
        color = color or {0, 0, 0, 1}
    }
    setmetatable(menu, Menu)
    clickOnButton = -1
    currentMenuTime = 0
    return menu
end

function Menu:update()
    self.focus = (collision(love.mouse.getX(), love.mouse.getY(), self.x, self.y, self.x + self.width, self.y + self.height))
    currentMenuTime = currentMenuTime + 1
end

function Menu:draw()
    --draw background
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --initial position of the cells
    local pos = {
        x = self.x,
        y = self.y
    }
    for i, row in ipairs(self.rows) do
        --update pos.y to be equal to row.y
        pos.y = row.y
        for j, element in ipairs(row) do
            local cell = {
                width = self.width / #row,
                height = row.height
            }

            pos.x = self.x + (j -1) * cell.width

            --draw grid
            love.graphics.rectangle("line", pos.x, pos.y, cell.width, cell.height)
-- LABEL
            if (element.type == "label") then
                love.graphics.printf(element.text, pos.x, pos.y + cell.height/2, cell.width, "center")
-- CHECKBOX
            elseif (element.type == "checkbox") then
                local checkbox = {
                    x = pos.x + cell.width/2,
                    y = pos.y + cell.height/2,
                }
                --checks if the mouse is over the checkbox
                if (collision(love.mouse.getX(), love.mouse.getY(), checkbox.x, checkbox.y, checkbox.x + 12, checkbox.y + 12)) then
                    
                    --checks click
                    if (leftClick()) then
                        element.value = not element.value
                    end
                end
                local opt = {"line", "fill"}
                love.graphics.rectangle(opt[boolToInt(element.value) +1], checkbox.x, checkbox.y, 12, 12)
-- RADIO
            elseif (element.type == "radio") then
                local radio = {
                    x = pos.x + cell.width/2,
                    y = pos.y + cell.height/2,
                }

                --checks if the mouse is over the radio
                if (circleCollision(love.mouse.getX(), love.mouse.getY(), radio.x, radio.y, 7)) then
    
                    --checks click
                    if (leftClick()) then
                        element.pointer.selected = element.index
                        element.pointer.value = element.value
                    end
                end
                love.graphics.printf(element.label, radio.x - cell.width/2, radio.y - 30, cell.width, "center")
                local opt = {"line", "fill"}
                love.graphics.circle(opt[boolToInt(element.index == element.pointer.selected)+1], radio.x, radio.y, 7)
-- RANGE
            elseif (element.type == "range") then
                local linePos = {}
                local bar = {
                    x = 0,
                    y = 0,
                    width = 0,
                    height = 0
                }   
                --horizontal
                if (not element.vertical) then
                    linePos = {
                        x1 = pos.x + 10, 
                        x2 = pos.x + cell.width - 50, 
                        y1 = pos.y + cell.height/2,
                        y2 = pos.y + cell.height/2
                    }
                    bar.x = lerp(linePos.x1, linePos.x2, element.step)
                    bar.y = pos.y + cell.height/2
                    bar.width = 10
                    bar.height = 20
                else
                --vertical
                    linePos = {
                        x1 = pos.x + cell.width/2, 
                        x2 = pos.x + cell.width/2, 
                        y1 = pos.y + 10,
                        y2 = pos.y + cell.height - 10
                    }
                    bar.x = pos.x + cell.width/2
                    bar.y = lerp(linePos.y1, linePos.y2, element.step)
                    bar.width = 20
                    bar.height = 10
                end 
                if collision(love.mouse.getX(), love.mouse.getY(), bar.x - bar.width/2, bar.y - bar.height/2, bar.x + bar.width/2, bar.y + bar.height/2) then
                    element.selected = true
                end
                if (not love.mouse.isDown(1)) then
                    element.selected = false
                end

                --horizontal
                if (not element.vertical) then
                    if (element.selected) then
                        if (love.mouse.isDown(1)) then
                            bar.x = love.mouse.getX()
                            bar.x = clamp(bar.x, linePos.x1, linePos.x2)
                            element.step = lerp(0, 1, normal(bar.x, linePos.x1, linePos.x2))
                            element.value = lerp(element.min, element.max, element.step)
                        end
                    end
                else
                --vertical
                    if (element.selected) then
                        if (love.mouse.isDown(1)) then
                            bar.y = love.mouse.getY()
                            bar.y = clamp(bar.y, linePos.y1, linePos.y2)
                            element.step = lerp(0, 1, normal(bar.y, linePos.y1, linePos.y2))
                            element.value = lerp(element.max, element.min, element.step)
                        end
                    end
                end

                --draw line
                love.graphics.line(linePos.x1, linePos.y1, linePos.x2, linePos.y2)
                --draw bar
                local opt = {"line", "fill"}
                love.graphics.rectangle(opt[boolToInt(element.selected)+1], bar.x - bar.width/2, bar.y - bar.height/2, bar.width, bar.height)
                --draw value
                love.graphics.print(string.format("%.1f", element.value), linePos.x2 + 10, linePos.y1 - 7)
            end
        end
    end
end

function Menu:addRow(row, height)
    row.height = height or 60
    local rowY = self.y
    for i, _row in ipairs(self.rows) do
        rowY = rowY + _row.height
    end
    row.y = rowY
    table.insert(self.rows, row)
    self.height = self.height + row.height
end

function Menu:range(min, max, _initial, vertical)
    local initial = min
    if (_initial ~= 0) then
        initial = clamp(_initial, min, max) or 0
    end
    local range = {
        type = "range",
        step = normal(initial, min, max) or 0,
        value = 0,
        min = min or 0,
        max = max or 1,
        selected = false,
        vertical = vertical or false
    }

    range.value = lerp(min, max, range.step)

    return range
end

function Menu:radio(arr, initial)
    local optionsList = {}
    for i, option in ipairs(arr) do
        local radio = {
            type = "radio",
            index = i,
            label = arr[i][1] or "no label",
            value = arr[i][2] or 0,
            selected = false
        }
        table.insert(optionsList, radio)
    end
    
    local returnedObject = {
        selected = initial or 1,
        value = optionsList[initial or 1].value,
        option = optionsList
    }

    --add a pointer to arr table
    for i, radio in ipairs(returnedObject.option) do
        radio.pointer = returnedObject
    end

    return returnedObject
end

function Menu:checkbox(var)
    local checkbox = {
        value = var,
        type = "checkbox"
    }
    return checkbox
end

function Menu:label(txt)
    local label = {
        type = "label",
        text = txt
    }
    return label
end

function leftClick()
    if (love.mouse.isDown(1))then
        if (clickOnButton == -1) then
            clickOnButton = currentMenuTime
        end
        return (currentMenuTime == clickOnButton)
    end
    clickOnButton = -1
    return false
end

function collision(x, y, x1, y1, x2, y2)
    return ((x >= x1) and (x <= x2) and (y >= y1) and (y <= y2))
end

function circleCollision(x, y, circlex, circley, radius)
    return (distance(x, y, circlex, circley) <= radius)
end

function boolToInt(bool)
    return bool and 1 or 0
end

function lerp(n1, n2, l)
	return n1 + (n2 - n1) * l
end

function normal(n, min, max)
    return (n - min) / (max - min)
end

function clamp(n, min, max)
    if (n < min) then 
        return min
    elseif (n > max) then 
        return max
    end
    return n
end