local rune = {}
local pick_types = { 
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

local rune_types = {
  "coal",
  "iron",
  "tin"
}

for i, p in ipairs(pick_types) do
  minetest.register_craft({
    output = "oleastre:rune",
    recipe = { {p}, {"group:stone"}}
  })
end

function rune.handle_rightclick(pos, node, clicker)
  print("rightclick")
  local meta = minetest.get_meta(pos)
  local rune_type_idx = meta:get_int("rune:type") + 1
  print("idx="..rune_type_idx)
  if rune_type_idx > #rune_types then
    rune_type_idx = 1
  end
  local rune_type = rune_types[rune_type_idx]
  minetest.set_node(pos, {name="oleastre:rune_"..rune_type, param1=node.param1, param2=node.param2 })

  meta:set_string("infotext", "Found x "..rune_type.." ore in the surrounding area.")
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

for i, t in ipairs(rune_types) do
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

