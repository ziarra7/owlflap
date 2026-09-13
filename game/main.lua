-- Owl state: position, size, and vertical velocity
local owl = {
    x = 100,
    y = 100,
    width = 30,
    height = 30,
    velocityY = 0
}

local gravity = 800     -- pixels per second squared
local jumpForce = -300  -- upward velocity applied on jump (negative = upward)

-- Branches (obstacles): each branch is a table with an x position,
-- a gap center (gapY), and a gap size. The owl must pass through the gap.
local branches = {}
local branchWidth = 60
local branchGapSize = 150
local branchSpeed = 200        -- pixels per second, how fast branches scroll left
local branchSpawnInterval = 1.6 -- seconds between new branches
local timeSinceLastSpawn = 0

-- Spawns a new branch at the right edge of the screen with a random gap position
local function spawnBranch()
    local minGapY = 100
    local maxGapY = 600 - 100 - branchGapSize
    local gapY = math.random(minGapY, maxGapY)

    table.insert(branches, {
        x = 400,
        gapY = gapY
    })
end

function love.load()
    math.randomseed(os.time())
end

function love.update(dt)
    owl.velocityY = owl.velocityY + gravity * dt
    owl.y = owl.y + owl.velocityY * dt

    local groundY = 600 - owl.height
    if owl.y > groundY then
        owl.y = groundY
        owl.velocityY = 0
    end

    if owl.y < 0 then
        owl.y = 0
        owl.velocityY = 0
    end

    -- Spawn new branches at a regular interval
    timeSinceLastSpawn = timeSinceLastSpawn + dt
    if timeSinceLastSpawn > branchSpawnInterval then
        spawnBranch()
        timeSinceLastSpawn = 0
    end

    -- Move all branches to the left, and remove ones that went off-screen
    for i = #branches, 1, -1 do
        branches[i].x = branches[i].x - branchSpeed * dt

        if branches[i].x + branchWidth < 0 then
            table.remove(branches, i)
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.2)

    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", owl.x, owl.y, owl.width, owl.height)

    -- Draw each branch as two rectangles: top part and bottom part,
    -- leaving a gap of branchGapSize between them
    love.graphics.setColor(0.4, 0.25, 0.15)
    for _, branch in ipairs(branches) do
        local topHeight = branch.gapY
        love.graphics.rectangle("fill", branch.x, 0, branchWidth, topHeight)

        local bottomY = branch.gapY + branchGapSize
        local bottomHeight = 600 - bottomY
        love.graphics.rectangle("fill", branch.x, bottomY, branchWidth, bottomHeight)
    end
end

function love.keypressed(key)
    if key == "space" then
        owl.velocityY = jumpForce
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        owl.velocityY = jumpForce
    end
end