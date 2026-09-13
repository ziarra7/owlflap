-- Owl state: position, size, and vertical velocity
local owl = {
    x = 100,
    y = 100,
    width = 30,
    height = 30,
    velocityY = 0
}

local gravity = 800    -- pixels per second squared
local jumpForce = -300  -- upward velocity applied on jump (negative = upward)

-- Called once when the game starts
function love.load()
end

-- Called every frame; handles game logic (physics, input, collisions)
function love.update(dt)
    -- Gravity increases the owl's falling speed over time
    owl.velocityY = owl.velocityY + gravity * dt
    owl.y = owl.y + owl.velocityY * dt

    -- Prevent the owl from falling past the ground
    local groundY = 600 - owl.height
    if owl.y > groundY then
        owl.y = groundY
        owl.velocityY = 0
    end

    -- Prevent the owl from flying above the top of the screen
    if owl.y < 0 then
        owl.y = 0
        owl.velocityY = 0
    end
end

-- Called every frame, right after love.update(); handles all rendering
function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.2)

    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", owl.x, owl.y, owl.width, owl.height)
end

-- Called once whenever a key is pressed
function love.keypressed(key)
    if key == "space" then
        owl.velocityY = jumpForce
    end
end

-- Called once whenever a mouse button is pressed
function love.mousepressed(x, y, button)
    if button == 1 then
        owl.velocityY = jumpForce
    end
end