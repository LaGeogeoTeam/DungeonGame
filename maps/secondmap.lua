local secondmap = {}

secondmap.grid = {
	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
	3,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,3,
	3,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,
	3,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,2,2,2,2,2,2,3,1,1,1,2,3,3,2,2,2,2,2,3
}

local house = love.graphics.newImage("assets/images/house.png")

function secondmap.update(dt)
	-- Si le player touche la zone pour aller à map2
	if checkCollision(player.posX-(player.size/2), player.posY-(player.size/2), player.size, player.size,
		9*tileSize, 11*tileSize, tileSize*2, tileSize) then
		-- On change la map
		scene = "Map1"
		-- On positionne le player en y
		player.posY = 96
	elseif checkCollision(player.posX-(player.size/2), player.posY-(player.size/2), player.size, player.size,
		9*tileSize, 1*tileSize, tileSize*3, tileSize*3) and keycount > 0 then
		-- On change la map
		scene = "Menu"
		-- TODO: Charger intérieur maison
	end
end

function secondmap.draw()
	local cpt = 1
	for y=1, mapH, 1 do
		for x=1, mapW, 1 do
			tileId = secondmap.grid[cpt]
			love.graphics.draw(get_tile_by_id(tileId), (x-1)*tileSize, (y-1)*tileSize)
			cpt = cpt + 1
		end
	end

	love.graphics.draw(house, 9*tileSize, 3*tileSize, 0, 1.3, 1.3)
end

function secondmap.getWorldSize()
	return (mapW or 40) * (tileSize or 32), (mapH or 30) * (tileSize or 32)
end

return secondmap