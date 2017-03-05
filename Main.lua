-- Mars Explorer

--[[
sprite("Dropbox:starmap_small")
--]]

--[[
Bugs

Need a reset for when planet fills screen
Shouldn't be able to zoom in so far that you go through the surface -- fixed with min/maxzoom
Not all menus react properly to orientation change -- fixed: textarea added to ui
Show nearby features?
--]]


--[[
    cmodule "Mars Explorer"
    cmodule.path("Base", "UI", "Graphics", "Maths", "Utilities")
  ]]
-- supportedOrientations(LANDSCAPE_ANY)
function setup()
    displayMode(FULLSCREEN)
    -- displayMode(OVERLAY)
    --[[
    cimport "VecExt"
    cimport "MeshExt"
    cimport "ColourNames"
    cimport "MathsUtilities"
    cimport "Coordinates"
    local Menu = cimport "Menu"
    local Slider = cimport "Slider"
    local Font,_,Textarea = unpack(cimport "Font", nil)
    touches = cimport "Touch"()
    ui = cimport "UI"(touches)
      ]]
    touches = Touches()
    ui = UI(touches)
    local types = {
        "Catena",
        "Cavus",
        "Chaos",
        "Chasma",
        "Collis",
        "Dorsum",
        "Fluctus",
        "Fossa",
        "Labyrinthus",
        "Lingula",
        "Mensa",
        "Mons",
        "Palus",
        "Planitia",
        "Planum",
        "Rupes",
        "Scopulus",
        "Serpens",
        "Sulcus",
        "Terra",
        "Tholus",
        "Unda",
        "Vallis",
        "Vastitas"
    }
    atypes = {}
    for k,v in ipairs(types) do
        atypes[v] = false
    end
    local m = Menu({
        pos = function() return RectAnchorOf(Screen,"north west") end,
        anchor = "north west",
        autoactive = false,
        title = "Features",
        colour = color(127, 127, 127, 118),
        textColour = color(255, 255, 255, 255)
    })
    ui:addElement(m)
    ui:activateElement(m)
    m:activate()
    for k,v in ipairs(types) do
        m:addItem({
            title = v,
            action = function()
                atypes[v] = not atypes[v]
                return true
            end,
            highlight = function()
                return atypes[v]
            end
        })
    end
    m:addItem({
        title = "All",
        action = function()
            local set = true
            for k,v in pairs(atypes) do
                set = set and v
            end
            if set then
                for k,v in pairs(atypes) do
                    atypes[k] = false
                end
            else
                for k,v in pairs(atypes) do
                    atypes[k] = true
                end
            end
            return true
        end,
        highlight = function()
            for k,v in pairs(atypes) do
                if not v then
                    return false
                end
            end
            return true
        end
    })
    local s = Slider({
        b = function() local x,y = RectAnchorOf(Screen,"south west") x = x + 150 y = y + 50 return x,y end,
        a = function() local x,y = RectAnchorOf(Screen,"south west") x = x + 450 y = y + 50 return x,y end,
        autoactive = false,
        colour = color(127, 127, 127, 255)
    })
    ui:addElement(s)
    ui:activateElement(s)
    diameter = 500
    s:activate({
        min = 500,
        max = 2000,
        action = function(d) diameter = d end,
        value = diameter
    })

    info = Textarea({
        title = "Minerals",
        font = Font({name = "Copperplate-Light", size = 20}),
        colour = color(127, 127, 127, 118),
        pos = function() local x,y = RectAnchorOf(Screen,"north east") x = x y = y return x,y end,
        anchor = "north east",
        width = "30ex",
        height = "13lh"
    })
    info:activate()
    ui:addElement(info)
    stars = Globe(100,"Project:stars")
    mars = Globe(2,"Project:mars")
    touches:pushHandler(mars)
    -- view = cimport "View"(nil,touches)
    view = View(nil,touches)
    view.doTranslation = false
    view.maxZoom = 3
    view.minZoom = 1/2
    setImages()
    --[[
    for k,v in pairs(cmodule.loaded()) do
        saveProjectTab(v:sub(v:find(":")+1,-5),readProjectTab(v:sub(1,-5)))
    end
    --]]
    -- saveImage("Dropbox:Mars",readImage("Project:Icon"))
end

function draw()
    background(40, 40, 50)
    touches:draw()
    view:draw()
    stars:draw()
    mars:draw()
    resetMatrix()
    viewMatrix(matrix())
    ortho()
    fill(255, 255, 255, 255)
    font("Copperplate-Light")
    textMode(CORNER)
    fontSize(30)
    local s
    for k,v in pairs(features) do
        if atypes[v.type] 
            and v.diameter > diameter then
            s = math.floor(math.log(v.diameter)/math.log(5000)*20)
            fontSize(s)
            ltext(v.sname,v.latitude,v.longitude,mars)
        end
    end
    -- ltext("Olympus Mons",18.65,226.2,mars)
    fontSize(20)
    if mars.tcoords then
        fill(0, 255, 211, 255)
        local lat,long = mars.tcoords.y*180-90,mars.tcoords.x*360-180
        local coords = string.format("(%d°N,%d°E)",math.floor(lat+.5),math.floor(long+.5))
        local x,y = ltext(coords,lat,long,mars)
        setMinerals(mars.tcoords,coords)
    end
    --[[
    spriteMode(CORNER)
    sprite("Dropbox:geology",0,0,WIDTH)
    if mars.tcoords then
        fill(255, 242, 0, 255)
        noStroke()
        ellipse(mars.tcoords.x * WIDTH,mars.tcoords.y * WIDTH/imw*imh,10)
        fill(255, 1, 0, 255)
        ellipse(mars.tcoords.x * WIDTH,mars.tcoords.y * WIDTH/imw*imh,5)
    end
    if mars.tcolour then
        fill(mars.tcolour)
        rect(WIDTH-100,HEIGHT-100,100,100)
    end
    --]]
    info:draw()
    ui:draw()
end

function touched(t)
    touches:addTouch(t)
end

function orientationChanged(o)
    if ui then
        ui:orientationChanged(o)
    end
end

function ltext(s,lat,long,g)
    phi = (long/180-1)*math.pi
    theta = (lat/180+.5)*math.pi
    local p = g.radius*vec4(math.cos(phi) * math.sin(theta), math.sin(phi) * math.sin(theta), math.cos(theta),0)
    p.w = 1
    local q = applymatrix4(p,g.matrix)
    local o = applymatrix4(vec4(0,0,0,1),g.matrix)
    tpt = q
    if q[3] > o[3] then
        return
    end
    local x,y = (q[1]/q[4]/2 +.5)*WIDTH, (q[2]/q[4]/2 +.5)*HEIGHT
    ellipse(x,y,3)
    text(s,x,y)
    return x,y
end

local minerals = {
    {
        "Amphibole",
        "Project:Amphibole.png"
    },
    {
        "Feldspar",
        "Project:Feldspar.png"
    },
    {
        "Hematite",
        "Project:Hematite.png"
    },
    {
        "High Ca Pyroxene",
        "Project:HighCaPyroxene.png"
    },
    {
        "Low Ca Pyroxene",
        "Project:LowCaPyroxene.png"
    },
    {
        "Olivine",
        "Project:Olivine.png"
    },
    {
        "Plagioclase",
        "Project:Plagioclase.png"
    },
    {
        "Quartz",
        "Project:Quartz.png"
    },
    {
        "Silicate",
        "Project:Silicate.png"
    },
    {
        "Dust",
        "Project:Dust.png"
    }
}

function setImages()
    for k,v in ipairs(minerals) do
        v[3] = readImage(v[2])
        v[4],v[5] = spriteSize(v[3])
    end
end

local pcoords

function setMinerals(p,c)
    if p == pcoords then
        return
    end
    pcoords = p
    local l = {}
    local s = "%s: %.2f"
    local r
    table.insert(l,string.format("At %s",c))
    for k,v in ipairs(minerals) do
        r = v[3]:get(math.floor(p.x*v[4]+.5),math.floor(p.y*v[5]+.5))/255*.2
        table.insert(l,string.format(s,v[1],r))
    end
    info:setLines(unpack(l))
end
