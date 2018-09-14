
--Variables
local BlueprintList = "blueprintSlotsArea.itemList";
local SlotItems;
local SlotsPerRow = 12;
local Rows = {};
local ListUpdated = true;
local SourceID;

--Functions
local SlotClick;
local SlotRClick;


--The init function for the Crafting Terminal UI Script
function init()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	widget.registerMemberCallback(BlueprintList,"__SlotClick__",SlotClick);
	widget.registerMemberCallback(BlueprintList,"__SlotRightClick__",SlotRClick);
	SlotItems = world.getObjectParameter(SourceID,"SlotItems") or {};
	sb.logInfo("SlotItems 2 = " .. sb.print(SlotItems));
	UpdateSlotArea();
end

--The update function for the Crafting Terminal UI Script
function update()
	if ListUpdated == false then
		UpdateSlotArea();
		ListUpdated = true;
		world.sendEntityMessage(SourceID,"Controller.UpdateCraftingList",SlotItems);
	end
end

SlotClick = function(_,data)
	sb.logInfo("SlotClick = " .. sb.print(data));
	sb.logInfo("SlotItems1 = " .. sb.printJson(SlotItems,1));
	local SlotNumber = tonumber(data);
	if player.swapSlotItem() == nil then
		player.setSwapSlotItem(SlotItems[SlotNumber]);
		RemoveItem(SlotNumber);
	end
end

SlotRClick = function(_,data)
	sb.logInfo("SlotRightClick = " .. sb.print(data));
	sb.logInfo("SlotItems2 = " .. sb.printJson(SlotItems,1));
	local SlotNumber = tonumber(data);
	local Item = SlotItems[SlotNumber];
	if Item ~= nil then
		world.spawnItem(Item,world.entityPosition(player.id()));
		RemoveItem(SlotNumber);
	end
end

function AddItem(item)
	if item ~= nil then
		SlotItems[#SlotItems + 1] = item;
		ListUpdated = false;
	end
	--UpdateSlotArea();
end

function RemoveItem(Slot)
	table.remove(SlotItems,Slot);
	ListUpdated = false;
	--UpdateSlotArea();
end

function UpdateSlotArea()
	local RowsNeeded = math.ceil(#SlotItems / SlotsPerRow);
	sb.logInfo("SlotItemSize = " .. sb.print(#SlotItems));
	sb.logInfo("Rows Needed = " .. sb.print(RowsNeeded));
	if RowsNeeded == 0 then
		--[[for row in ipairs(RowsNeeded) do
			widget.removeListItem()
		end--]]
		widget.clearListItems(BlueprintList);
		Rows = {};
		return nil;
	end
	if #Rows > RowsNeeded then
		for i=#Rows,RowsNeeded + 1 do
			widget.removeListItem(BlueprintList,i);
			table.remove(Rows,i);
		end
	elseif #Rows < RowsNeeded then
		for i=#Rows + 1,RowsNeeded do
			Rows[i] = widget.addListItem(BlueprintList);
		end
	end
	for row=1,#Rows do
		local RowLink = BlueprintList .. "." .. Rows[row];
		for slot=1,SlotsPerRow do
			local GlobalSlot = ((row - 1) * SlotsPerRow) + slot;
			local SlotLink = RowLink .. ".slot" .. slot;
			if GlobalSlot > #SlotItems then
				widget.setItemSlotItem(SlotLink,nil);
				widget.setVisible(SlotLink,false);
			else
				widget.setItemSlotItem(SlotLink,SlotItems[GlobalSlot]);
				widget.setData(SlotLink,GlobalSlot);
				widget.setVisible(SlotLink,true);
			end
		end
	end
end

function AddSlotClick()
	local SwapItem = player.swapSlotItem();
	if SwapItem ~= nil and SwapItem.name == "craftingblueprint" and SwapItem.parameters ~= nil and SwapItem.parameters.Recipe ~= nil then
		AddItem(player.swapSlotItem());
		player.setSwapSlotItem(nil);
	end
end

function AddSlotRClick()

end


