-- Includes
Object = require "classic"
require "collision"
require "settings"
require "tiles"
require "inventory"
require "screens/allscreens"
require "player"
require "arrow"
local Camera = require "camera"

-- Variables
key = love.graphics.newImage("assets/images/key.png")
heart = love.graphics.newImage("assets/images/heart.png")
mob = love.graphics.newImage("assets/images/snake.png")


font = love.graphics.newFont("assets/fonts/Bebas.ttf", 35)
fontBig = love.graphics.newFont("assets/fonts/Bebas.ttf", 55)
fontSmall = love.graphics.newFont("assets/fonts/Bebas.ttf", 20)
sfx = love.audio.newSource("assets/sfx/plop.wav", "static")
music = love.audio.newSource("assets/sfx/music.ogg", "stream")

arrowList = {}
mobX = 900
mobY = 400

local W, H = love.graphics.getWidth(), love.graphics.getHeight()
local camera = Camera.new()

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

-- Convertit coords écran -> monde (pour le tir / clic)
local function screenToWorld(sx, sy)
	return camera.x + sx / camera.scale, camera.y + sy / camera.scale
end

-- Retourne la map de la scène courante
local function getCurrentMapByScene()
	if scene == "Map1" then return firstmap
	elseif scene == "Map2" then return secondmap
	elseif scene == "Map3" then return thirdmap
	elseif scene == "Dungeon" then
		return dungeon
		-- elseif scene == "Map3" then return thirdmap
	end
	return nil
end

-- Informe la caméra de la taille du monde (map)
local function updateWorldBoundsFromMap(map)
	local worldW, worldH
	if map and map.getWorldSize then
		worldW, worldH = map.getWorldSize()
	else
		worldW = (mapW or 40) * (tileSize or 32)
		worldH = (mapH or 30) * (tileSize or 32)
	end
	camera:setWorld(worldW, worldH)
end


function love.load()

	love.graphics.setDefaultFilter("nearest", "nearest", 1)

	math.randomseed(os.time())
	menu.load()

	music:setLooping(true)
	-- music:play()


	camera:setScale(1.5) -- ajuste (1.0 = pas de zoom ; 1.5/2.0 = zoom avant)
end

local lastScene = scene

function love.update(dt) -- Tourne en boucle

	if scene == "Menu" then
		menu.update(dt)
	elseif scene == "Map1" then
		if firstmap.update then firstmap.update(dt) end
	elseif scene == "Map2" then
		if secondmap.update then secondmap.update(dt) end
	end


	if scene ~= lastScene then
		lastScene = scene
		local currentMap = getCurrentMapByScene()
		if currentMap then
			updateWorldBoundsFromMap(currentMap)

			camera:follow(player.posX, player.posY, dt)
		end
	end

	if scene ~= "Menu" then

		input_utilisateur(dt)

		for i, v in ipairs(arrowList) do
			v:update(dt)
			if checkCollision(mobX, mobY, 64, 64, v.x, v.y, 5, 5) then
				mobY = 10000 -- TODO: gérer mort/score/sfx
			end
		end

		for i = #arrowList, 1, -1 do
			local a = arrowList[i]
			if a.x < -50 or a.x > camera.worldW + 50 or a.y < -50 or a.y > camera.worldH + 50 then
				table.remove(arrowList, i)
			end
		end


		player.anim_timer = player.anim_timer - dt
		if player.anim_timer <= 0 then
			player.anim_timer = 0.1
			player.frame = player.frame + 1
			if player.frame > player.max_frame then player.frame = 1 end
			local offset = 32 * (player.frame - 1)
			player.sprite:setViewport(offset, player.yline, 32, 36)
		end

		camera:follow(player.posX, player.posY, dt)
	end
end


function love.draw() -- Dessine le contenu
	love.graphics.setFont(font)

	if scene == "Menu" then
		-- Le menu n'est pas “dans le monde”
		menu.draw()
		return
	end

	-- Monde (maps, entités) dans la caméra
	camera:attach()
	-- Dessin de la map courante
	if scene == "Map1" then
		firstmap.draw()
	elseif scene == "Map2" then
		secondmap.draw()
	elseif scene == "Dungeon" then
		dungeon.draw(camera)
		-- elseif scene == "Map3" then
		-- 	thirdmap.draw()
	end

	-- Entités monde
	love.graphics.draw(
			player.sprite_sheet, player.sprite, player.posX, player.posY,
			player.r, player.xscale, player.yscale, 16, 18
	)

	for i, v in ipairs(arrowList) do
		v:draw()
	end

	love.graphics.draw(mob, mobX, mobY, 0, 0.75, 0.75)
	camera:detach()

	-- HUD (fixe à l'écran)
	love.graphics.draw(heart, 1180, 15, 0, 1.5, 1.5)
	love.graphics.draw(key, 10, 10, 0, 0.1, 0.1)
	love.graphics.print(keycount, 80, 20)
end


function love.keypressed(key)
	check_key_current_screen(key)
end

-- Fonctions perso

local function getPlayerAABBAt(x, y)
	-- sprite = 32x36 avec origine (16,18) ; on prend une hitbox un peu plus petite
	local w, h = 20, 26
	local ax = x - 10      -- 10 px à gauche du centre approx.
	local ay = y - 13      -- 13 px au-dessus du centre approx.
	return ax, ay, w, h
end

function input_utilisateur(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	if key == "+" or key == "kp+" then camera:zoomIn() end
	if key == "-" or key == "kp-" then camera:zoomOut() end
	if key == "0" or key == "kp0" then camera:resetZoom() end

	-- Si on appuie sur clic droit
	if love.mouse.isDown(1) and not mousePressed then
		mousePressed = true
		local sx, sy = love.mouse.getX(), love.mouse.getY()
		local mx, my = screenToWorld(sx, sy)
		local arrowR = atan2(my - player.posY, mx - player.posX)
		table.insert(arrowList, Arrow(player.posX, player.posY, arrowR))
    end

    if not love.mouse.isDown(1) then
        mousePressed = false
    end

	local minX, minY = 32, 32
	local maxX = (camera.worldW or love.graphics.getWidth())  - 30
	local maxY = (camera.worldH or love.graphics.getHeight()) - 36

	local dx, dy = 0, 0
	if love.keyboard.isDown("z") and player.posY > minY then
		dy = dy - player.speed * dt
		player.yline = 0
		player.max_frame = 2
	elseif love.keyboard.isDown("s") and player.posY < maxY then
		dy = dy + player.speed * dt
		player.yline = 36 * 2
		player.max_frame = 2
	elseif love.keyboard.isDown("q") and player.posX > minX then
		dx = dx - player.speed * dt
		player.yline = 36 * 3
		player.max_frame = 2
	elseif love.keyboard.isDown("d") and player.posX < maxX then
		dx = dx + player.speed * dt
		player.yline = 36
		player.max_frame = 2
	else
		player.max_frame = 1
	end

	local map = currentMap or getCurrentMapByScene()

	-- Passe X
	if dx ~= 0 then
		local nx = player.posX + dx
		local ax, ay, aw, ah = getPlayerAABBAt(nx, player.posY)
		if not (map and map.rectCollides and map:rectCollides(ax, ay, aw, ah)) then
			player.posX = nx
		else
			-- Snap au bord du bloc (facultatif, simple : on annule)
			-- Pour un snap précis, on peut calculer la tuile et ajuster, mais ça suffit pour commencer
		end
	end

	-- Passe Y
	if dy ~= 0 then
		local ny = player.posY + dy
		local ax, ay, aw, ah = getPlayerAABBAt(player.posX, ny)
		if not (map and map.rectCollides and map:rectCollides(ax, ay, aw, ah)) then
			player.posY = ny
		else
			-- idem : on annule le mouvement sur Y si collision
		end
	end
end

function love.resize(w, h)
	if camera and camera.resize then camera:resize() end
end

function check_player_collisions()
	-- if checkCollision(player.posX-(player.size/2), player.posY-(player.size/2), player.size, player.size, enemy.x-32, enemy.y-32, 64, 64) then
	-- end
end

function update_current_screen(dt)
	if scene == "Menu" then
		menu.update(dt)
	elseif scene == "Map1" then
		firstmap.update(dt)
	elseif scene == "Map2" then
		secondmap.update(dt)
	end
end

function draw_current_screen()
	if scene == "Menu" then
		menu.draw()
	elseif scene == "Map1" then
		firstmap.draw()
	elseif scene == "Map2" then
		secondmap.draw()
	end
end

function check_key_current_screen(key)
	if scene == "Menu" then
		menu.keypressed(key)
	end
end