
local SourceID;
local SlotItem;
local UpdateStats;

function init()
	SourceID = pane.sourceEntity();
end

function update(dt)
	
end

--local function UpdateTags

UpdateStats = function()
	widget.setItemSlotItem("itemBox",SlotItem);
	if SlotItem == nil then
		widget.setText("itemName","");
		widget.setText("category","");
		widget.setText("type","");
		widget.setText("maxStack","");
		widget.setText("tags","");
	else
		local Config = root.itemConfig(SlotItem);
		widget.setText("itemName",SlotItem.name);
		widget.setText("category",Config.config.category or "");
		widget.setText("type",root.itemType(SlotItem.name));
		widget.setText("maxStack",sb.print(Config.config.maxStack or 1000));
		widget.setText("tags",table.concat(root.itemTags(SlotItem.name), ", "));
	end
end

function itemBox()
	SlotItem = player.swapSlotItem();
	UpdateStats();
end

function itemBoxRight()
	SlotItem = nil;
	UpdateStats();
end