local rune = {}
rune.pick_types = { 
  "default:pick_wood",
  "default:pick_stone",
  "default:pick_steel",
  "default:pick_bronze",
  "default:pick_silver",
  "default:pick_gold",
  "default:pick_diamond",
  "default:pick_nyan",
  "default:pick_mese"
}

rune.types = {
  "coal",
  "iron",
  "tin"
}

rune.search_size = 7

for i, p in ipairs(rune.pick_types) do
  minetest.register_craft({
    output = "oleastre:rune",
    recipe = { {p}, {"group:stone"}}
  })
end

function rune.get_quad(player)
  local pi2 = math.pi*2
  local pi4 = math.pi/4
  
  local dir = player:get_look_yaw()
  while (dir<0) do dir = dir + pi2 end
  while (dir>pi2) do dir = dir - pi2 end
  
  local quad = 0
  if(dir>pi4) then quad=1 end
  if(dir>3*pi4) then quad=2 end
  if(dir>5*pi4) then quad=3 end
  if(dir>7*pi4) then quad=0 end
  return quad
end

function rune.handle_rightclick(pos, node, clicker)
  minetest.debug("look at quad="..rune.get_quad(clicker))
    
  local meta = minetest.get_meta(pos)
  local rune_type_idx = meta:get_int("rune:type") + 1
  if rune_type_idx > #rune.types then
    rune_type_idx = 1
  end
  local rune_type = rune.types[rune_type_idx]
  minetest.swap_node(pos, {name="oleastre:rune_"..rune_type, param1=node.param1, param2=node.param2 })

  local res = minetest.find_node_near(pos, rune.search_size, "default:stone_with_"..rune_type)
  if res then
    local wy, wy, wz
    local dx = math.floor(res.x - pos.x)
    local dy = math.floor(res.y - pos.y)
    local dz = math.floor(res.z - pos.z)
    
    if (dy > 0) then 
      wy = ", "..dy.." above"
    elseif (dy==0) then 
      wy = ""
    else 
      wy = ", "..(-dy).." below"
    end
    
    if quad==2 then 
      dx = -dx
      dz = -dz
    elseif quad==1 then
      local t = dx
      dx = dz
      dz = -t
    elseif quad==3 then
      local t = dx
      dx = -dz
      dz = t
    end
    
    if (dx >= 0) then 
      wx =  dx.." steps forward"
    else 
      wx =  (-dx).." steps backward"
    end
    
    if (dz > 0) then 
      wz = ", "..dz.." left"
    elseif (dz==0) then
      wz= ""
    else
      wz =", "..(-dz).." right"
    end
    
    meta:set_string("infotext", "Found "..rune_type.." "..wx..wz..wy)
  else
    meta:set_string("infotext", "No "..rune_type.." found in the surrounding area.")
  end

  meta:set_int("rune:type", rune_type_idx)
end

minetest.register_node("oleastre:rune", {
  description = "Rune",
  drawtype = "signlike",
  tiles = {"rune.png"},
  inventory_image = "rune.png",
  paramtype = "light",
  paramtype2 = "wallmounted",
  sunlight_propagates = true,
  walkable = false,
  selection_box = {type = "wallmounted"},
  groups = {choppy = 2, dig_immediate = 2},
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", "Activate me (right click) to find ores in the surroundig area.")
    meta:set_int("rune:type", 0)
  end,
  on_rightclick = function(pos, node, clicker)
    rune.handle_rightclick(pos, node, clicker)
  end,
})

for i, t in ipairs(rune.types) do
  minetest.register_node("oleastre:rune_"..t, {
    description = "Rune",
    drawtype = "signlike",
    tiles = {"rune.png^rune_"..t..".png"},
    inventory_image = "rune.png^rune_"..t..".png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    drop = "oleastre:rune",
    sunlight_propagates = true,
    walkable = false,
    selection_box = {type = "wallmounted"},
    groups = {choppy = 2, dig_immediate = 2},
    on_rightclick = function(pos, node, clicker)
      rune.handle_rightclick(pos, node, clicker)
    end,
  })
end

