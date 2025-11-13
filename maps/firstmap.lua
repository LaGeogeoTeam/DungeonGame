local firstmap = {}

firstmap.grid = {
	3,3,3,3,3,3,3,3,1,1,1,3,3,3,3,3,3,3,3,3,
	3,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,2,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,
	3,2,2,2,2,2,2,3,2,2,2,2,3,3,2,2,2,2,2,3
}

local arbre = love.graphics.newImage("assets/images/arbre.png")

function firstmap.update(dt)
	-- Si le player touche la zone pour aller à map2
	if checkCollision(player.posX-(player.size/2), player.posY-(player.size/2), player.size, player.size,
		9*tileSize, 0, tileSize*2, tileSize) then
		-- On change la map
		scene = "Map2"
		-- On positionne le player en y
		player.posY = 720-tileSize
	elseif checkCollision(player.posX-(player.size/2), player.posY-(player.size/2), player.size, player.size,
		9*tileSize, 8*tileSize, tileSize*1.3, tileSize) and keycount == 0 then
		-- On a touché la clé
		keycount = keycount + 1
	end
end

function firstmap.draw()
	local cpt = 1
	for y=1, mapH, 1 do
		for x=1, mapW, 1 do
			tileId = firstmap.grid[cpt]
			love.graphics.draw(get_tile_by_id(tileId), (x-1)*tileSize, (y-1)*tileSize)
			cpt = cpt + 1
		end
	end
	if keycount == 0 then
		love.graphics.draw(key, 9*tileSize, 8*tileSize, 0, 0.15, 0.15)
	end

	love.graphics.draw(arbre, 3*tileSize, 9*tileSize)
	love.graphics.draw(arbre, 16*tileSize, 6*tileSize)
	love.graphics.draw(arbre, 5*tileSize, 7*tileSize)
	love.graphics.draw(arbre, 19*tileSize, 10*tileSize)
end

function firstmap.getWorldSize()
	return (mapW or 40) * (tileSize or 32), (mapH or 30) * (tileSize or 32)
end

return firstmap