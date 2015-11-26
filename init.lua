local rune = {}
rune.pick_types = {
  "default:pick_wood",
  "default:pick_stone",
  "default:pick_steel",
  "default:pick_bronze",
  "default:pick_mese",
  "default:pick_diamond",
  "default:pick_silver",
  "default:pick_gold",
  "default:pick_nyan"
}

rune.default_types = {
  { name="coal", nodes={ "default:stone_with_coal" } },
  { name="iron", nodes={ "default:stone_with_iron" } },
  { name="tin", nodes={ "default:stone_with_tin", "moreores:mineral_tin" } },
  { name="copper", nodes={ "default:stone_with_copper", "moreores:mineral_copper" } },
  { name="silver", nodes={ "default:stone_with_silver", "moreores:mineral_silver" } },
  { name="gold", nodes={ "default:stone_with_gold", "moreores:mineral_gold" } },
  { name="diamond", nodes={ "default:stone_with_diamond", "moreores:mineral_diamond" } },
  { name="mithril", nodes={ "default:stone_with_mithril", "moreores:mineral_mithril" } },
  { name="mese", nodes={ "default:stone_with_mese" } },
}
rune.types = {}
rune.types_idx = {}
rune.search_size = 7

for i, p in ipairs(rune.pick_types) do
  minetest.register_craft({
    output = "runes:miner_inactive_coal",
    recipe = { {p}, {"group:stone"}}
  })
end

function rune.init_rune_types()
  local idx = 0
  for i, t in ipairs(rune.default_types) do
    for j, n in ipairs(t.nodes) do
      if minetest.registered_nodes[n] then
        idx = idx + 1
        rune.types[idx] = { name=t.name, node=n }
        rune.types_idx[t.name] = idx
        break
      end
    end
  end
end

function rune.get_type(meta)
  local name = meta:get_string("runes:type")
  return rune.types[rune.types_idx[name]]
end

function rune.search_ore(pos, node)
  local meta = minetest.get_meta(pos)
  local rune_type = rune.get_type(meta)
  if meta:get_int("runes:state")==0 then
    return
  end
  local res = minetest.find_node_near(pos, rune.search_size, rune_type.node)
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

    local dir = node.param2

    if (dir==1) or (dir==2) then
      dx = -dx
      dz = -dz
    elseif dir==4 then
      local t = dx
      dx = -dz
      dz = t
    elseif dir==5 then
      local t = dx
      dx = dz
      dz = -t
    end

    if (dx > 0) then
      wx = dx.." steps backward"
    else
      wx = (-dx).." steps forward"
    end

    if (dz > 0) then
      wz = ", "..dz.." right"
    elseif (dz==0) then
      wz= ""
    else
      wz =", "..(-dz).." left"
    end

    meta:set_string("infotext", "Found "..rune_type.name.." "..wx..wz..wy)
  else
    meta:set_string("infotext", "No "..rune_type.name.." found in the surrounding area.")
  end
end


function rune.handle_rightclick(pos, node, clicker)
  local meta = minetest.get_meta(pos)
  local rune_type_name = meta:get_string("runes:type")
  local rune_type_idx = rune.types_idx[rune_type_name]

  if (meta:get_int("runes:state")==1) then
    rune_type_idx = rune_type_idx + 1
    if rune_type_idx > #rune.types then
      rune_type_idx = 1
    end
  end
  local rune_type = rune.types[rune_type_idx]
  minetest.swap_node(pos, {name="runes:miner_"..rune_type.name, param1=node.param1, param2=node.param2 })
  meta:set_string("runes:type", rune_type.name)
  meta:set_int("runes:state", 1)
  rune.search_ore(pos, node)
end


for i, t in ipairs(rune.default_types) do
  groups = {choppy = 2, dig_immediate = 2}
  if (t.name~="coal") then
    groups["not_in_creative_inventory"]=1
  end

  minetest.register_node("runes:miner_inactive_"..t.name, {
    description = "Rune",
    drawtype = "signlike",
    tiles = {"runes_miner.png"},
    inventory_image = "runes_miner.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    selection_box = {type = "wallmounted"},
    groups = groups,
    on_rightclick = function(pos, node, clicker)
      rune.handle_rightclick(pos, node, clicker)
    end,
    on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("infotext", "Activate me (right click) to find ores in the surrounding area.")
      meta:set_string("runes:type", t.name)
      meta:set_int("runes:state", 0)
    end,
  })

  minetest.register_node("runes:miner_"..t.name, {
    description = "Rune",
    drawtype = "signlike",
    tiles = {"runes_miner.png^runes_miner_"..t.name..".png"},
    inventory_image = "runes_miner.png^runes_miner_"..t.name..".png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    drop = "runes:miner_inactive_"..t.name,
    sunlight_propagates = true,
    walkable = false,
    selection_box = {type = "wallmounted"},
    groups = {choppy = 2, dig_immediate = 2, not_in_craft_guide=1},
    on_rightclick = function(pos, node, clicker)
      rune.handle_rightclick(pos, node, clicker)
    end,
    on_punch = function(pos, node, clicker)
      rune.search_ore(pos, node)
    end,
  })
end

minetest.after(0, rune.init_rune_types)

function rune.find(name, node_type, area_size)
    local shortcuts = {
      ["lava"] = "default:lava_source",
      ["gravel"] = "default:gravel"
    }
    local ntype = shortcuts[node_type] or node_type
    local player = minetest.get_player_by_name(name)
    local res = minetest.find_node_near(player:getpos(), area_size, ntype)
    if res then
      minetest.chat_send_player(name, "Found "..ntype.." at: ("..res.x..", "..res.y..", "..res.z..").")
    else
      minetest.chat_send_player(name, "No "..ntype.." found in the surrounding area of size "..area_size..".")
    end
end

minetest.register_chatcommand("rune_find", {
  params="<node_type> [area_size]",
  description="Search for a specific node type in the surrounding area",
  func=function(name, params)
    found, _, node_type, area_size = params:find("^([%S]+)(.*)$")
    if found == nil then
      minetest.chat_send_player(name, "Usage: rune_find <node_type> [area_size]")
    else
      rune.find(name, node_type, tonumber(area_size) or rune.search_size)
    end
  end
})

