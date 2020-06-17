local S = minetest.get_translator("runes")
local teleport_rune = {}


teleport_rune.create_gravel = function(itemstack, user, pointed_thing)
    if pointed_thing.under == nil then
        return itemstack
    end

    local dest_pos = pointed_thing.under
    local dest_node = minetest.get_node(dest_pos)

    if dest_node.name ~= "default:gravel" then
        return itemstack
    end
    if itemstack:take_item(1) ~= nil then
        minetest.sound_play("default_break_glass", {pos = user:get_pos(), max_hear_distance = 16}, true)
        minetest.set_node(dest_pos, {name = "runes:teleport_gravel"})
    end
    return itemstack
end

teleport_rune.set_block_text = function(pos, text)
    if not text then
        text = S("At position: @1, @2, @3", pos.x, pos.y, pos.z)
    end
    local meta = minetest.get_meta(pos)
    meta:set_string("text", text)
    meta:set_string("infotext", text)
end

teleport_rune.concat_description = function(description, text)
    local suffix = ""
    if text~=nil then
        suffix = " - " .. text
    end
    return S(description) .. suffix
end

teleport_rune.save_block_meta = function(pos, description, block_meta, item_meta)
    item_meta:set_string("text", block_meta["text"])
    item_meta:set_string("description", teleport_rune.concat_description(description, block_meta["text"]))
    item_meta:set_string("rune_pos", block_meta["rune_pos"] or minetest.serialize(pos))
    return item_meta
end

teleport_rune.restore_block_meta = function(item_meta, block_meta)
    block_meta:set_string("text", item_meta:get_string("text"))
    block_meta:set_string("infotext", item_meta:get_string("text"))
    block_meta:set_string("rune_pos", item_meta:get_string("rune_pos"))
    return block_meta
end

minetest.register_craft({
    output = "runes:teleport_bottle",
    recipe = {{"dye:yellow"}, {"dye:blue"}, {"vessels:glass_bottle"}}
})

minetest.register_craft({
    output = "runes:teleport_block_engraved",
    recipe = { {"group:pickaxe"}, {"runes:teleport_block_item"}}
})

minetest.register_craftitem("runes:teleport_bottle", {
    description = S("Bottle of teleport potion"),
    inventory_image = "runes_teleport_bottle.png",
    wield_image = "runes_teleport_bottle.png",
    on_use = teleport_rune.create_gravel
})

minetest.register_node("runes:teleport_gravel", {
    description = S("Gravel with memory"),
    tiles = {"runes_teleport_gravel.png"},
    groups = {crumbly = 2, not_in_creative_inventory = 1},
    sounds = default.node_sound_gravel_defaults(),
    stack_max=1,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", "field[text;;${text}]")
        teleport_rune.set_block_text(pos, nil)
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        local text = fields.text
        if text and string.len(text) > 512 then
            minetest.chat_send_player(player_name, S("Text too long"))
            return
        end
        teleport_rune.set_block_text(pos, text)
    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local block_pos = pos
        local below_pos = {x = pos.x, y = block_pos.y - 1, z = pos.z}

        local gravel_meta = itemstack:get_meta()
        local below_node = minetest.get_node(below_pos)
        if below_node.name=="default:stone" then
            block_pos = below_pos
            minetest.remove_node(pos)
            minetest.set_node(below_pos, { name = "runes:teleport_block" } )
        end
        local block_meta = minetest.get_meta(block_pos)
        teleport_rune.restore_block_meta(gravel_meta, block_meta)
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        teleport_rune.save_block_meta(pos, "Gravel with memory", oldmeta, drops[1]:get_meta())
    end,
})

minetest.register_node("runes:teleport_block", {
    description = S("Stone with memory"),
    tiles = {"runes_teleport_block.png"},
    groups = {cracky = 3, not_in_creative_inventory = 1},
    stack_max=1,
    sounds = default.node_sound_stone_defaults(),
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        teleport_rune.restore_block_meta(itemstack:get_meta(), minetest.get_meta(pos))
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        teleport_rune.save_block_meta(pos, "Stone with memory", oldmeta, drops[1]:get_meta())
    end,
})

minetest.register_node("runes:teleport_block_engraved", {
    description = S("Teleport stone"),
    tiles = {"runes_teleport_engraved.png"},
    groups = {cracky = 3, not_in_creative_inventory = 1},
    stack_max=1,
    sounds = default.node_sound_stone_defaults(),
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        teleport_rune.restore_block_meta(itemstack:get_meta(), minetest.get_meta(pos))
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        teleport_rune.save_block_meta(pos, "Teleport stone", oldmeta, drops[1]:get_meta())
    end,
})
