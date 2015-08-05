local enchanting = {}

function enchanting.construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "size[8,7;]"..xdecor.fancy_gui..
		"label[0.85,-0.15;Enchant]"..
		"image[0.6,0.2;2,2;xdecor_enchbook.png]"..
		"image[1.5,2;1,1;ench_mese_layout.png]"..
		"list[current_name;tool;0.5,2;1,1;]"..
		"list[current_name;mese;1.5,2;1,1;]"..
		"image_button[2.75,0;5,1.5;ench_bg.png;durable;Durable]"..
		"image_button[2.75,1.5;5,1.5;ench_bg.png;fast;Fast]"..
		"list[current_player;main;0,3.3;8,4;]")
	meta:set_string("infotext", "Enchantment Table")

	local inv = meta:get_inventory()
	inv:set_size("tool", 1)
	inv:set_size("mese", 1)
end

function enchanting.is_allowed_tool(toolname)
	local tdef = minetest.registered_tools[toolname]
	if tdef and string.find(toolname, "default:") and not
			string.find(toolname, "sword") and not
			string.find(toolname, "stone") and not
			string.find(toolname, "wood") then
		return 1
	else return 0 end
end

function enchanting.fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local toolstack = inv:get_stack("tool", 1)
	local mesestack = inv:get_stack("mese", 1)
	local toolname = toolstack:get_name()
	local mese = mesestack:get_count()
	local enchs = {"durable", "fast"}

	for _, e in pairs(enchs) do
		if enchanting.is_allowed_tool(toolname) ~= 0 and mese > 0 and fields[e] then
			toolstack:replace("xdecor:enchanted_"..string.sub(toolname, 9).."_"..e)
			mesestack:take_item()
			inv:set_stack("mese", 1, mesestack)
			inv:set_stack("tool", 1, toolstack)
		end
	end
end

function enchanting.dig(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	if not inv:is_empty("tool") or not inv:is_empty("mese") then
		return false
	end
	return true
end

function enchanting.put(pos, listname, index, stack, player)
	local toolname = stack:get_name()
	local count = stack:get_count()

	if listname == "mese" then
		if toolname == "default:mese_crystal" then return count
		else return 0 end
	end
	if listname == "tool" then
		return enchanting.is_allowed_tool(toolname)
	end
	return count
end

xdecor.register("enchantment_table", {
	description = "Enchantment Table",
	tiles = {
		"xdecor_enchantment_top.png", "xdecor_enchantment_bottom.png",
		"xdecor_enchantment_side.png", "xdecor_enchantment_side.png",
		"xdecor_enchantment_side.png", "xdecor_enchantment_side.png"
	},
	groups = {cracky=1},
	sounds = xdecor.stone,
	on_construct = enchanting.construct,
	can_dig = enchanting.dig,
	allow_metadata_inventory_put = enchanting.put,
	on_receive_fields = enchanting.fields
})

function enchanting.register_enchtools(init, m, def)
	local faster, longer = {}, {}
	longer = init["uses"] * 1.2 -- Wearing factor for enchanted tools (higher number = longer use).
	for i = 1, 3 do
		faster[i] = init["times"][i] - 0.1 -- Digging factor for enchanted tools (higher number = faster dig).
	end

	local enchtools = {
		{"axe", "durable", {choppy = {times=def.times, uses=longer, maxlevel=def.maxlvl}}},
		{"axe", "fast", {choppy = {times=faster, uses=def.uses, maxlevel=def.maxlvl}}},
		{"pick", "durable", {cracky = {times=def.times, uses=longer, maxlevel=def.maxlvl}}},
		{"pick", "fast", {cracky = {times=faster, uses=def.uses, maxlevel=def.maxlvl}}},
		{"shovel", "durable", {crumbly = {times=def.times, uses=longer, maxlevel=def.maxlvl}}},
		{"shovel", "fast", {crumbly = {times=faster, uses=def.uses, maxlevel=def.maxlvl}}}
	}
	for _, x in pairs(enchtools) do
		local tool, ench, grp = x[1], x[2], x[3]
		minetest.register_tool("xdecor:enchanted_"..tool.."_"..m.."_"..ench, {
			description = "Enchanted "..string.gsub(m, "%l", string.upper, 1)..
					" "..string.gsub(tool, "%l", string.upper, 1).." ("..string.gsub(ench, "%l", string.upper, 1)..")",
			inventory_image = minetest.registered_tools["default:"..tool.."_"..m]["inventory_image"],
			groups = {not_in_creative_inventory=1},
			tool_capabilities = {groupcaps = grp, damage_groups = def.dmg}
		})
	end
end

local tools = {
	{"axe", "choppy"}, {"pick", "cracky"}, {"shovel", "crumbly"}
}
local materials = {"steel", "bronze", "mese", "diamond"}

for _, t in pairs(tools) do
for _, m in pairs(materials) do
	local tool, group = t[1], t[2]
	local toolname = tool.."_"..m
	local init_def = minetest.registered_tools["default:"..toolname]["tool_capabilities"]["groupcaps"][group]

	local tooldef = {
		times = init_def["times"],
		uses = init_def["uses"],
		dmg = init_def["damage_groups"],
		maxlvl = init_def["maxlevel"]
	}
	enchanting.register_enchtools(init_def, m, tooldef)
end
end
