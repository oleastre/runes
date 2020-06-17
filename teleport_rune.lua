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
    block_meta:set_string("text", item_meta["text"])
    block_meta:set_string("infotext", item_meta["text"])
    block_meta:set_string("rune_pos", item_meta["rune_pos"])
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
            minetest.sound_play("runes_teleport_build", {pos = pos, max_hear_distance = 8}, true)
            minetest.add_particlespawner({
                amount = 50,
                time = 3,
                minpos = {x = pos.x-0.5, y=pos.y+1, z=pos.z-0.5},
                maxpos = {x = pos.x+0.5, y=pos.y-0.5, z=pos.z+0.5},
                minvel = {x = -0.1, y=-0, z=-0.1},
                maxvel = {x = 0.1, y=-0.5, z=0.1},
                minacc = vector.new(),
                maxacc = vector.new(),
                minexptime = 1,
                maxexptime = 3,
                minsize = 1,
                maxsize = 3,
                texture="runes_teleport_particle.png",
                glow=7,
            })
        end
        local block_meta = minetest.get_meta(block_pos)
        teleport_rune.restore_block_meta(gravel_meta:to_table().fields, block_meta)
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
    drop = {},
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, { name = "runes:teleport_block_engraved" } )
        minetest.sound_play("runes_teleport_engrave", {pos = pos, max_hear_distance = 8}, true)
        minetest.add_particlespawner({
            amount = 50,
            time = 3,
            minpos = {x = pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
            maxpos = {x = pos.x+0.5, y=pos.y+1, z=pos.z+0.5},
            minvel = {x = -0.2, y=0.2, z=-0.2},
            maxvel = {x = 0.2, y=0.5, z=0.2},
            minacc = vector.new(),
            maxacc = vector.new(),
            minexptime = 1,
            maxexptime = 3,
            minsize = 1,
            maxsize = 3,
            texture="runes_teleport_particle.png",
            glow=7,
        })
        teleport_rune.restore_block_meta(oldmetadata.fields, minetest.get_meta(pos))
    end
})

minetest.register_node("runes:teleport_block_engraved", {
    description = S("Teleport stone"),
    tiles = {"runes_teleport_engraved.png"},
    groups = {cracky = 3, not_in_creative_inventory = 1},
    stack_max=1,
    sounds = default.node_sound_stone_defaults(),
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        teleport_rune.restore_block_meta(itemstack:get_meta():to_table().fields, minetest.get_meta(pos))
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        teleport_rune.save_block_meta(pos, "Teleport stone", oldmeta, drops[1]:get_meta())
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local origin = pos
        local dest = minetest.deserialize(minetest.get_meta(pos):get_string("rune_pos"))
        minetest.sound_play("runes_teleport_activate", {pos = origin, max_hear_distance = 8}, true)
        minetest.sound_play("runes_teleport_activate", {pos = dest, max_hear_distance = 8}, true)
        minetest.add_particlespawner({
            amount = 25,
            time = 2,
            minpos = {x = origin.x-0.5, y=origin.y-0.5, z=origin.z-0.5},
            maxpos = {x = origin.x+0.5, y=origin.y+2, z=origin.z+0.5},
            minvel = {x = -0.5, y=0.2, z=-0.5},
            maxvel = {x = 0.5, y=0.5, z=0.5},
            minacc = vector.new(),
            maxacc = vector.new(),
            minexptime = 1,
            maxexptime = 2,
            minsize = 1,
            maxsize = 2,
            texture="runes_teleport_particle.png",
            glow=7,
        })
        minetest.add_particlespawner({
            amount = 25,
            time = 2,
            minpos = {x = dest.x-0.5, y=dest.y-0.5, z=dest.z-0.5},
            maxpos = {x = dest.x+0.5, y=dest.y+2, z=dest.z+0.5},
            minvel = {x = -0.5, y=0.2, z=-0.5},
            maxvel = {x = 0.5, y=0.5, z=0.5},
            minacc = vector.new(),
            maxacc = vector.new(),
            minexptime = 1,
            maxexptime = 2,
            minsize = 1,
            maxsize = 2,
            texture="runes_teleport_particle.png",
            glow=7,
        })
        clicker:set_pos(dest)
    end
})
