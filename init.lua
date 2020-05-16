--[[
Copyright 2020 Luis Liñán <luislivilla@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

-- Auto replace tools when broken
local tool_materials = {"wood", "stone", "bronze", "steel", "mese", "diamond"}
local tool_types = {
    "default:pick_", "default:shovel_", "default:axe_", "default:sword_"
}

--- Find an item by it's name in the chosen list.
-- @param item_name name of the item to search
-- @param list list in which search the item
-- @return the index and the item if is found or 0 and nil otherwise
local function find_item (item_name, list)
    for index, item in pairs(list) do
        if item:get_name() == item_name then return index, item end
    end
    return 0, nil
end

--- Run after_use callback when a tool is used.
-- This modified after_use function will auto replace any tool that breaks when
-- using it by another tool of the same kind from your inventory if you have
-- one.
-- @param itemstack ItemStack object used
-- @param user ObjectRef player object that used the itemstack
-- @param node ObjectRef node object target of the itemstack instance
-- @return the itemstack after performing the necessary operations
local function new_after_use (itemstack, user, node, digparams)
    local inv_stack_index = user:get_wield_index()
    local tool_name = itemstack:get_name()
    itemstack:add_wear(digparams.wear)

    if itemstack:get_wear() == 0 then
        minetest.sound_play("default_tool_breaks")
        local tool_type_prefix = string.match(tool_name, '^.*_')
        local inv = user:get_inventory()
        local inv_main_list = inv:get_list("main")
        inv_main_list[inv_stack_index]:clear()

        for _, tool_material in pairs(tool_materials) do
            local found_index, found_itemstack =
                find_item(tool_type_prefix .. tool_material, inv_main_list)
            if found_index > 0 then
                itemstack:replace(found_itemstack)
                inv:set_stack("main", found_index, ItemStack(nil))
                break
            end
        end
    end

    return itemstack
end

for _, tool_type_prefix in pairs(tool_types) do
    for _, tool_material in pairs(tool_materials) do
        minetest.override_item(tool_type_prefix .. tool_material,
                               {after_use = new_after_use})
    end
end