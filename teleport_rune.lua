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

teleport_rune.set_gravel_text = function(pos, text)
    if not text then
        text = S("At position: @1, @2, @3", pos.x, pos.y, pos.z)
    end
    local meta = minetest.get_meta(pos)
    meta:set_string("text", text)
    meta:set_string("infotext", text)
end

minetest.register_craft({
    output = "runes:teleport_bottle",
    recipe = {{"dye:yellow"}, {"dye:blue"}, {"vessels:glass_bottle"}}
})

minetest.register_craft({
    output = "runes:teleport_block_engraved",
    recipe = { {"group:pickaxe"}, {"runes:teleport_block_item"}}
})

minetest.register_craft({
	type = "cooking",
	output = "runes:teleport_block_item",
	recipe = "runes:teleport_gravel_item",
})

minetest.register_craftitem("runes:teleport_bottle", {
    description = S("Bottle of teleport potion"),
    inventory_image = "runes_teleport_bottle.png",
    wield_image = "runes_teleport_bottle.png",
    on_use = teleport_rune.create_gravel
})

minetest.register_craftitem("runes:teleport_gravel_item", {
    description = S("Gravel with memory"),
    inventory_image = "runes_teleport_gravel.png",
    wield_image = "runes_teleport_gravel.png",
    stack_max=1
})

minetest.register_node("runes:teleport_gravel", {
    description = S("Gravel with memory"),
    tiles = {"runes_teleport_gravel.png"},
    groups = {crumbly = 2},
    sounds = default.node_sound_gravel_defaults(),
    stack_max=1,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", "field[text;;${text}]")
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        local text = fields.text
        if text and string.len(text) > 512 then
            minetest.chat_send_player(player_name, S("Text too long"))
            return
        end
        teleport_rune.set_gravel_text(pos, text)
    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        teleport_rune.set_gravel_text(pos, itemstack:get_meta():get_string("text"))
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        item_meta = drops[1]:get_meta()
        item_meta:set_string("text", oldmeta["text"])
        item_meta:set_string("rune_pos", minetest.serialize(pos))
    end,
})

minetest.register_craftitem("runes:teleport_block_item", {
    description = S("Stone with memory"),
    inventory_image = "runes_teleport_block.png",
    wield_image = "runes_teleport_block.png"
})

minetest.register_node("runes:teleport_block_engraved", {
    description = S("Teleport stone"),
    tiles = {"runes_teleport_engraved.png"},
    groups = {cracky = 3},
    sounds = default.node_sound_stone_defaults(),
})
