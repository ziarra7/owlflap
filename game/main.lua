-- Owl state: position, size, and vertical velocity
local owl = {
    x = 100,
    y = 100,
    width = 50,
    height = 50,
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

local gameOver = false
local score = 0

-- A larger font specifically for displaying the score
local scoreFont

-- Standard AABB (Axis-Aligned Bounding Box) collision check between two rectangles
local function rectsOverlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

-- Draws a single branch segment (top or bottom part of an obstacle) with
-- a bark texture and a lighter "cut" end facing the gap.
-- isTop = true draws the cut at the bottom (facing down into the gap);
-- isTop = false draws the cut at the top (facing up into the gap).
local function drawBranchSegment(x, y, width, height, isTop)
    -- Base bark color
    love.graphics.setColor(0.353, 0.275, 0.196)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Vertical bark stripes (alternating tones), skipping the cut zone
    local cutSize = math.min(20, height * 0.3)
    local barkHeight = height - cutSize
    local barkY = isTop and y or (y + cutSize)

    local stripeOffsets = {0.1, 0.3, 0.5, 0.7, 0.9}
    for i, offset in ipairs(stripeOffsets) do
        local stripeX = x + width * offset
        local stripeColor = (i % 2 == 0) and {0.420, 0.322, 0.251} or {0.290, 0.220, 0.149}
        love.graphics.setColor(stripeColor[1], stripeColor[2], stripeColor[3])
        love.graphics.rectangle("fill", stripeX, barkY, width * 0.06, barkHeight)
    end

    -- Wood knots
    love.graphics.setColor(0.227, 0.173, 0.110)
    love.graphics.rectangle("fill", x + width * 0.2, barkY + barkHeight * 0.25, width * 0.15, height * 0.03)
    love.graphics.rectangle("fill", x + width * 0.55, barkY + barkHeight * 0.6, width * 0.15, height * 0.04)

    -- Lighter "cut" end, facing the gap
    local cutY = isTop and (y + height - cutSize) or y
    love.graphics.setColor(0.788, 0.659, 0.463)
    love.graphics.rectangle("fill", x, cutY, width, cutSize)
    love.graphics.setColor(0.910, 0.863, 0.769)
    love.graphics.rectangle("fill", x + width * 0.1, cutY + cutSize * 0.25, width * 0.8, cutSize * 0.5)
end

-- Spawns a new branch at the right edge of the screen with a random gap position
local function spawnBranch()
    local minGapY = 100
    local maxGapY = 600 - 100 - branchGapSize
    local gapY = math.random(minGapY, maxGapY)

    table.insert(branches, {
        x = 400,
        gapY = gapY,
        scored = false
    })
end

-- Draws the owl as pixel art using colored rectangles (no image file needed)
local function drawOwl(x, y)
    local s = owl.width / 20 -- scale factor: our design is a 20x20 grid

    -- Ear tufts
    love.graphics.setColor(0.353, 0.275, 0.196) -- dark brown
    love.graphics.rectangle("fill", x + 6*s, y, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 13*s, y, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 7*s, y + 1*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 12*s, y + 1*s, 1*s, 1*s)

    -- Head outline
    love.graphics.setColor(0.420, 0.345, 0.259) -- brown
    love.graphics.rectangle("fill", x + 6*s, y + 2*s, 8*s, 2*s)
    love.graphics.rectangle("fill", x + 6*s, y + 4*s, 2*s, 1*s)
    love.graphics.rectangle("fill", x + 12*s, y + 4*s, 2*s, 1*s)
    love.graphics.rectangle("fill", x + 6*s, y + 9*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 13*s, y + 9*s, 1*s, 1*s)

    -- Facial disc (beige), symmetric around both eyes
    love.graphics.setColor(0.910, 0.863, 0.769) -- beige
    love.graphics.rectangle("fill", x + 7*s, y + 4*s, 1*s, 5*s)
    love.graphics.rectangle("fill", x + 14*s, y + 4*s, 1*s, 5*s)
    love.graphics.rectangle("fill", x + 8*s, y + 4*s, 6*s, 5*s)

    -- Eyes: yellow circles with black pupils
    love.graphics.setColor(0.949, 0.757, 0.306) -- yellow
    love.graphics.rectangle("fill", x + 8*s, y + 5*s, 2*s, 2*s)
    love.graphics.rectangle("fill", x + 11*s, y + 5*s, 2*s, 2*s)
    love.graphics.setColor(0.102, 0.102, 0.102) -- near black
    love.graphics.rectangle("fill", x + 8.7*s, y + 5.7*s, 0.8*s, 0.8*s)
    love.graphics.rectangle("fill", x + 11.7*s, y + 5.7*s, 0.8*s, 0.8*s)

    -- Beak
    love.graphics.setColor(0.910, 0.588, 0.235) -- orange
    love.graphics.rectangle("fill", x + 9.5*s, y + 7*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 9*s, y + 8*s, 2*s, 1*s)

    -- Body
    love.graphics.setColor(0.541, 0.435, 0.306) -- tan brown
    love.graphics.rectangle("fill", x + 5*s, y + 10*s, 10*s, 2*s)
    love.graphics.rectangle("fill", x + 5*s, y + 12*s, 2*s, 6*s)
    love.graphics.rectangle("fill", x + 13*s, y + 12*s, 2*s, 6*s)
    love.graphics.rectangle("fill", x + 6*s, y + 16*s, 8*s, 1*s)

    -- Belly (lighter feathers with subtle spots)
    love.graphics.setColor(0.961, 0.925, 0.851) -- cream
    love.graphics.rectangle("fill", x + 7*s, y + 12*s, 6*s, 2*s)
    love.graphics.setColor(0.910, 0.863, 0.769) -- beige
    love.graphics.rectangle("fill", x + 7*s, y + 14*s, 6*s, 2*s)
    love.graphics.setColor(0.788, 0.659, 0.463) -- darker beige spots
    love.graphics.rectangle("fill", x + 8*s, y + 14*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 10*s, y + 14*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 12*s, y + 14*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 9*s, y + 15*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 11*s, y + 15*s, 1*s, 1*s)

    -- Feet
    love.graphics.setColor(0.910, 0.588, 0.235) -- orange
    love.graphics.rectangle("fill", x + 7*s, y + 17*s, 1*s, 1*s)
    love.graphics.rectangle("fill", x + 12*s, y + 17*s, 1*s, 1*s)
end

-- Draws the moon as pixel art using colored rectangles
local function drawMoon(x, y)
    love.graphics.setColor(0.949, 0.929, 0.878) -- off-white

    love.graphics.rectangle("fill", x + 30, y, 40, 10)
    love.graphics.rectangle("fill", x + 10, y + 10, 80, 10)
    love.graphics.rectangle("fill", x, y + 20, 100, 10)
    love.graphics.rectangle("fill", x, y + 30, 100, 10)
    love.graphics.rectangle("fill", x, y + 40, 100, 10)
    love.graphics.rectangle("fill", x, y + 50, 100, 10)
    love.graphics.rectangle("fill", x, y + 60, 100, 10)
    love.graphics.rectangle("fill", x + 10, y + 70, 80, 10)
    love.graphics.rectangle("fill", x + 30, y + 80, 40, 10)

    -- Craters
    love.graphics.setColor(0.847, 0.816, 0.737)
    love.graphics.rectangle("fill", x + 20, y + 25, 10, 10)
    love.graphics.rectangle("fill", x + 55, y + 15, 10, 10)
    love.graphics.rectangle("fill", x + 60, y + 50, 15, 10)
    love.graphics.rectangle("fill", x + 30, y + 55, 10, 10)
end

-- Stars scattered across the sky, generated once at startup
local stars = {}
local function generateStars()
    stars = {}
    for i = 1, 25 do
        table.insert(stars, {
            x = math.random(0, 400),
            y = math.random(0, 400)
        })
    end
end

-- Draws each star as a small white square, dimmed at random for a twinkling feel
local function drawStars()
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(stars) do
        love.graphics.rectangle("fill", star.x, star.y, 3, 3)
    end
end

function love.load()
    math.randomseed(os.time())
    generateStars()
    scoreFont = love.graphics.newFont(48)
end

function love.update(dt)
    -- Freeze all game logic once the game is over
    if gameOver then
        return
    end

    owl.velocityY = owl.velocityY + gravity * dt
    owl.y = owl.y + owl.velocityY * dt

    local groundY = 600 - owl.height
    if owl.y > groundY then
        owl.y = groundY
        owl.velocityY = 0
        gameOver = true
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

    -- Check collision between the owl and each branch (top and bottom parts)
    for _, branch in ipairs(branches) do
        local topHeight = branch.gapY
        local bottomY = branch.gapY + branchGapSize
        local bottomHeight = 600 - bottomY

        local hitsTop = rectsOverlap(owl.x, owl.y, owl.width, owl.height,
                                       branch.x, 0, branchWidth, topHeight)
        local hitsBottom = rectsOverlap(owl.x, owl.y, owl.width, owl.height,
                                          branch.x, bottomY, branchWidth, bottomHeight)

        if hitsTop or hitsBottom then
            gameOver = true
        end

        -- The owl has passed this branch once its left edge clears the branch's right edge
        if not branch.scored and owl.x > branch.x + branchWidth then
            branch.scored = true
            score = score + 1
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.2)

    drawStars()
    drawMoon(320, 40)

    love.graphics.setColor(0.4, 0.7, 1)
    drawOwl(owl.x, owl.y)

    -- Draw each branch as two textured segments: top part and bottom part,
    -- leaving a gap of branchGapSize between them
    for _, branch in ipairs(branches) do
        local topHeight = branch.gapY
        drawBranchSegment(branch.x, 0, branchWidth, topHeight, true)

        local bottomY = branch.gapY + branchGapSize
        local bottomHeight = 600 - bottomY
        drawBranchSegment(branch.x, bottomY, branchWidth, bottomHeight, false)
    end

    -- Display the current score at the top of the screen, in a large font
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(score), 0, 20, 400, "center")

    if gameOver then
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, 250, 400, "center")
        love.graphics.printf("Press space to restart", 0, 280, 400, "center")
    end
end

-- Resets all game state to start a fresh game
local function resetGame()
    owl.y = 100
    owl.velocityY = 0
    branches = {}
    timeSinceLastSpawn = 0
    gameOver = false
    score = 0
end

function love.keypressed(key)
    if key == "space" then
        if gameOver then
            resetGame()
        else
            owl.velocityY = jumpForce
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and not gameOver then
        owl.velocityY = jumpForce
    end
end