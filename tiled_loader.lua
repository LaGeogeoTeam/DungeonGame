-- tiled_loader.lua (robuste : flips + chunks + atlas/collection + chemins + logs)
local Loader = {}

-- ===== Helpers fichiers/chemins =====
local function fileExists(p) return love.filesystem.getInfo(p, "file") ~= nil end
local function basename(p) return p and p:match("([^/\\]+)$") or nil end

-- "assets.maps.dungeon" -> "assets/maps/"
local function dirname(modulePath)
    local p = modulePath:gsub("%.", "/")
    return (p:match("(.*/)") or "")
end

-- Normalise a/./b, a/b/../c, etc.
local function normalize(p)
    repeat
        local before = p
        p = p:gsub("/%./", "/")
             :gsub("//+", "/")
             :gsub("/[^/]+/%.%./", "/")
    until p == before
    return p
end

local function join(base, rel)
    if not rel or rel == "" then return rel end
    if rel:sub(1,1) == "/" then return rel end
    if base == "" then return normalize(rel) end
    return normalize(base .. rel)
end

-- Essaye de résoudre un chemin d'image Tiled vers un fichier du projet
local function resolveImagePath(baseDir, imgPath)
    -- 1) relatif au dossier de la map
    local p = join(baseDir, imgPath)
    if fileExists(p) then return p end

    -- 2) variantes fréquentes
    local name = basename(imgPath)
    local candidates = {
        "assets/" .. imgPath,                 -- ex: assets/tilesets/...
        baseDir .. name,                      -- même dossier que la map
        "assets/tilesets/" .. name,
        "assets/images/"   .. name,
        "assets/"          .. name,
        name,
    }
    for _, c in ipairs(candidates) do
        c = normalize(c)
        if fileExists(c) then return c end
    end

    -- 3) logs
    print(("[tiled_loader] Introuvable: %s"):format(imgPath))
    print(("[tiled_loader] baseDir: %s"):format(baseDir))
    for _, c in ipairs(candidates) do print("  tried:", normalize(c)) end
    return nil
end

-- ===== Gestion des flips de Tiled =====
-- Tiled encode H/V/D dans les 3 bits de poids fort
local FLIP_H = 0x80000000  -- 2147483648
local FLIP_V = 0x40000000  -- 1073741824
local FLIP_D = 0x20000000  -- 536870912
local MASK_GID = 0x1FFFFFFF  -- conserver 29 bits

local function stripFlips(gid)
    if gid == 0 then return 0, false, false, false end
    -- pas d'opérateurs bitwise natifs, on utilise des divisions entières
    local h = (math.floor(gid / FLIP_H) % 2) == 1
    local v = (math.floor(gid / FLIP_V) % 2) == 1
    local d = (math.floor(gid / FLIP_D) % 2) == 1
    local base = gid % 0x20000000 -- conserve 29 bits (retire H/V/D)
    return base, h, v, d
end

local function composeTransform(fh, fv, fd, tw, th)
    -- r = rotation (rad), sx/sy = scale, ox/oy = origine (pixels)
    local r, sx, sy, ox, oy = 0, 1, 1, 0, 0

    if fd then
        -- Le flip diagonal équivaut à une rotation de 90° avec permutations des flips.
        -- Les cas ci-dessous reproduisent les 4 combinaisons standard de Tiled (orthogonal).
        if fh and fv then
            -- D + H + V : 90° CW + flipX
            r  = math.pi/2
            sx = -1
            oy = th
            fh, fv = false, false
        elseif fh then
            -- D + H : 90° CW
            r  = math.pi/2
            oy = th
            fh = false
        elseif fv then
            -- D + V : 270° CW
            r  = -math.pi/2
            ox = tw
            fv = false
        else
            -- D seul : 90° CW
            r  = math.pi/2
            oy = th
        end
    end

    -- Applique les flips restants dans le repère courant
    if fh then sx = -sx; ox = tw - ox end
    if fv then sy = -sy; oy = th - oy end

    return r, sx, sy, ox, oy
end

local function drawTile(ts, quadIndex, x, y, tw, th, flipH, flipV, flipD)
    local r, sx, sy, ox, oy = composeTransform(flipH, flipV, flipD, tw, th)
    if ts.mode == "atlas" then
        love.graphics.draw(ts.image, ts.quads[quadIndex], x, y, r, sx, sy, ox, oy)
    elseif ts.mode == "collection" then
        local img = ts.images[quadIndex]
        if img then love.graphics.draw(img, x, y, r, sx, sy, ox, oy) end
    end
end

-- ===== Construction tileset (atlas ou collection d'images) =====
local function buildTileset(ts, baseDir)
    -- Atlas (image unique)
    if ts.image then
        local path = resolveImagePath(baseDir, ts.image)
        assert(path, ("Tileset introuvable : %s (place l'image dans 'assets/' ou corrige le chemin dans Tiled)")
                :format(ts.image))
        print("[tiled_loader] tileset image ->", path)
        local img = love.graphics.newImage(path)
        img:setFilter("nearest", "nearest")

        local tw, th = ts.tilewidth, ts.tileheight
        local iw, ih = ts.imagewidth or img:getWidth(), ts.imageheight or img:getHeight()
        local margin  = ts.margin  or 0
        local spacing = ts.spacing or 0
        local columns = ts.columns or math.floor((iw - margin + spacing) / (tw + spacing))
        local rows    = math.floor((ih - margin + spacing) / (th + spacing))
        local tilecount = ts.tilecount or (columns * rows)

        local quads = {}
        for i = 0, tilecount - 1 do
            local cx = i % columns
            local cy = math.floor(i / columns)
            local x = margin + cx * (tw + spacing)
            local y = margin + cy * (th + spacing)
            quads[i + 1] = love.graphics.newQuad(x, y, tw, th, iw, ih)
        end

        return {
            mode     = "atlas",
            firstgid = ts.firstgid or 1,
            lastgid  = (ts.firstgid or 1) + tilecount - 1,
            image    = img,
            quads    = quads,
            tw = tw, th = th
        }
    end

    -- Collection d'images
    if ts.tiles and #ts.tiles > 0 then
        local images = {}
        local maxId = 0
        for _, tile in ipairs(ts.tiles) do
            if tile.image then
                local path = resolveImagePath(baseDir, tile.image)
                assert(path, ("Tile image introuvable : %s"):format(tile.image))
                print("[tiled_loader] tile image ->", path)
                images[(tile.id or 0) + 1] = love.graphics.newImage(path)
                if tile.id and tile.id > maxId then maxId = tile.id end
            end
        end
        return {
            mode     = "collection",
            firstgid = ts.firstgid or 1,
            lastgid  = (ts.firstgid or 1) + maxId,
            images   = images,
            tw = ts.tilewidth, th = ts.tileheight
        }
    end

    -- --- marquage des tuiles solides via propriétés Tiled : solid=true
    local solid = {}
    if ts.tiles then
        for _, tile in ipairs(ts.tiles) do
            local props = tile.properties
            local isSolid = false
            if props then
                -- Tiled (Lua export) peut donner un dictionnaire { solid = true } OU un tableau { {name=..., value=...}, ... }
                if props.solid == true then
                    isSolid = true
                elseif props[1] and props[1].name then
                    for _, p in ipairs(props) do
                        if p.name == "solid" and (p.value == true or p.value == "true") then
                            isSolid = true
                            break
                        end
                    end
                end
            end
            if isSolid then
                -- tile.id est 0-based ; nos quads/images sont 1-based : +1
                solid[(tile.id or 0) + 1] = true
            end
        end
    end
    ts.solid = solid
    -- Tileset externe (.tsx) non embeddé
    return { mode = "external", source = ts.source }
end

-- ===== Loader principal =====
function Loader.load(luaModulePath)
    local data = require(luaModulePath)  -- ex: "assets.maps.dungeon"
    assert(data.width and data.height and data.tilewidth and data.tileheight, "Invalid Tiled map")

    local baseDir = dirname(luaModulePath)  -- "assets/maps/"
    local tilesets, externals = {}, {}

    for _, ts in ipairs(data.tilesets or {}) do
        local built = buildTileset(ts, baseDir)
        if built.mode == "external" then
            table.insert(externals, built.source or "(unknown .tsx)")
        else
            table.insert(tilesets, built)
        end
    end
    assert(#tilesets > 0, ("No usable tileset. Dans Tiled: Map → Embed Tilesets, puis export Lua. Externes: %s")
            :format(table.concat(externals, ", ")))

    local map = {
        width  = data.width,  height = data.height,
        tw     = data.tilewidth, th  = data.tileheight,
        layers = {}
    }

    for _, layer in ipairs(data.layers or {}) do
        if layer.type == "tilelayer" then
            table.insert(map.layers, {
                name    = layer.name or "layer",
                width   = layer.width  or data.width,
                height  = layer.height or data.height,
                data    = layer.data,          -- si finite map
                chunks  = layer.chunks,        -- si infinite map
                visible = (layer.visible ~= false),
                opacity = layer.opacity or 1
            })
            local L = map.layers[#map.layers]

            L._namelower = (L.name or ""):lower()

            if L.data then
                function L:getGidAt(tx, ty)
                    if tx < 0 or ty < 0 or tx >= map.width or ty >= map.height then return 0 end
                    return L.data[ty * map.width + tx + 1] or 0
                end
            elseif L.chunks then
                function L:getGidAt(tx, ty)
                    for _, ch in ipairs(L.chunks) do
                        local cx1, cy1 = ch.x, ch.y
                        local cx2, cy2 = ch.x + ch.width - 1, ch.y + ch.height - 1
                        if tx >= cx1 and tx <= cx2 and ty >= cy1 and ty <= cy2 then
                            local lx = tx - cx1
                            local ly = ty - cy1
                            return ch.data[ly * ch.width + lx + 1] or 0
                        end
                    end
                    return 0
                end
            end
        end
    end

    local function findTilesetForGid(gid)
        if gid == 0 then return nil end
        for i = #tilesets, 1, -1 do
            local ts = tilesets[i]
            if gid >= ts.firstgid and gid <= ts.lastgid then
                return ts, gid - ts.firstgid + 1
            end
        end
        return nil
    end

    function map:getWorldSize()
        return self.width * self.tw, self.height * self.th
    end

    function map:isSolidTile(tx, ty)
        -- Option : hors de la map = solide (empêche de sortir)
        if tx < 0 or ty < 0 or tx >= self.width or ty >= self.height then
            return true
        end

        for _, L in ipairs(self.layers) do
            if L.getGidAt and (L._namelower == "bordure" or L._namelower == "border" or L._namelower == "collision") then
                local gid = L:getGidAt(tx, ty)
                if gid ~= 0 then return true end
            end
        end

        for _, L in ipairs(self.layers) do
            if L.getGidAt then
                local gid = L:getGidAt(tx, ty)
                if gid ~= 0 then
                    local base = gid % 0x20000000 -- enlève les bits de flip
                    local ts, idxInTs = (function()
                        for i = #tilesets, 1, -1 do
                            local t = tilesets[i]
                            if base >= t.firstgid and base <= t.lastgid then
                                return t, base - t.firstgid + 1
                            end
                        end
                    end)()
                    if ts and idxInTs and ts.solid and ts.solid[idxInTs] then
                        return true
                    end
                end
            end
        end

        return false
    end

    -- test de collision AABB rectangle (x,y,w,h) en pixels
    function map:rectCollides(x, y, w, h)
        local tw, th = self.tw, self.th
        local x1 = math.floor(x / tw)
        local y1 = math.floor(y / th)
        local x2 = math.floor((x + w - 1) / tw)
        local y2 = math.floor((y + h - 1) / th)
        for ty = y1, y2 do
            for tx = x1, x2 do
                if self:isSolidTile(tx, ty) then return true end
            end
        end
        return false
    end

    local function drawRange(getGidAt, x1, y1, x2, y2, tw, th)
        for ty = y1, y2 do
            for tx = x1, x2 do
                local gid = getGidAt(tx, ty)
                if gid and gid ~= 0 then
                    local base, fh, fv, fd = stripFlips(gid)  -- ignore flip diag
                    local ts, idxInTs = findTilesetForGid(base)
                    if ts and idxInTs then
                        drawTile(ts, idxInTs, tx * tw, ty * th, tw, th, fh, fv, fd)
                    end
                end
            end
        end
    end

    function map:drawVisible(camX, camY, viewW, viewH)
        local tw, th = self.tw, self.th
        local x1 = math.max(0, math.floor(camX / tw))
        local y1 = math.max(0, math.floor(camY / th))
        local x2 = math.min(self.width  - 1, math.floor((camX + viewW) / tw))
        local y2 = math.min(self.height - 1, math.floor((camY + viewH) / th))

        for _, layer in ipairs(self.layers) do
            if layer.visible then
                if layer.opacity and layer.opacity ~= 1 then love.graphics.setColor(1,1,1,layer.opacity) end

                if layer.data then
                    -- finite map
                    local function getGidAt(tx, ty)
                        if tx < 0 or ty < 0 or tx >= self.width or ty >= self.height then return 0 end
                        return layer.data[ty * self.width + tx + 1] or 0
                    end
                    drawRange(getGidAt, x1, y1, x2, y2, tw, th)

                elseif layer.chunks then
                    -- infinite map (chunks)
                    for _, ch in ipairs(layer.chunks) do
                        -- chunk rect
                        local cx1, cy1 = ch.x, ch.y
                        local cx2, cy2 = ch.x + ch.width - 1, ch.y + ch.height - 1
                        -- intersection avec la vue
                        local rx1 = math.max(x1, cx1)
                        local ry1 = math.max(y1, cy1)
                        local rx2 = math.min(x2, cx2)
                        local ry2 = math.min(y2, cy2)
                        if rx1 <= rx2 and ry1 <= ry2 then
                            local function getGidAt(tx, ty)
                                if tx < cx1 or ty < cy1 or tx > cx2 or ty > cy2 then return 0 end
                                local lx = tx - cx1
                                local ly = ty - cy1
                                return ch.data[ly * ch.width + lx + 1] or 0
                            end
                            drawRange(getGidAt, rx1, ry1, rx2, ry2, tw, th)
                        end
                    end
                end

                if layer.opacity and layer.opacity ~= 1 then love.graphics.setColor(1,1,1,1) end
            end
        end
    end

    -- Petit log de contrôle
    print(string.format("[tiled_loader] map %dx%d tiles (%dx%d px)",
            map.width, map.height, map.width*map.tw, map.height*map.th))

    return map
end

return Loader
