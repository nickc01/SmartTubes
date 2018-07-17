
--Variables
local SourceID;
local SlotItem;
local CopyText = "";
local CopyAble = false;
local SlotsPerRow = 2;
local SlotList = "inventoryItemsArea.itemList";
local First = false;

--Functions
local UpdateStats;
local SetCopyText;
local CopyableUpdated;
local InventoryItems = {};
local SlotClick;
local SlotRightClick;
local SetupInventoryArea;
local Rows = {};

function init()
	SourceID = pane.sourceEntity();
	widget.registerMemberCallback(SlotList,"__SlotClick__",function(wid,data)
		SlotClick(tonumber(data));
	end);
	widget.registerMemberCallback(SlotList,"__SlotRightClick__",function(wid,data)
		SlotRightClick(tonumber(data));
	end);
end

function update(dt)
	if First == false then
		First = true;
		local Items = config.getParameter("InventoryItems");
		if Items ~= nil then
			SetupInventoryArea(Items);
		end
	end
	--[[local Items = config.getParameter("InventoryItems");
	if Items ~= nil then
		SetupInventoryArea(Items);
	end--]]
	local HasFocus = widget.hasFocus("copybox");
	if HasFocus ~= CopyAble then
		CopyAble = HasFocus;
		CopyableUpdated(CopyAble);
	end
end

--local function UpdateTags

UpdateStats = function()
	--widget.setItemSlotItem("itemBox",SlotItem);
	if SlotItem == nil then
		--widget.setText("textArea.dataArea","");
		SetCopyText("");
	else
		local Config = root.itemConfig(SlotItem);
		local Data = Config.config;
		if SlotItem.parameters ~= nil then
			for name,data in pairs(SlotItem.parameters) do
				Data[name] = data;
			end
		end
		--widget.setText("textArea.dataArea",sb.printJson(Data,1));
		SetCopyText(Data);
	end
end

function SetScanningItem(item)
	SlotItem = item;
	UpdateStats();
end

CopyableUpdated = function(copyable)
	--sb.logInfo("Copyable Updated = " .. sb.print(copyable));
	widget.setVisible("copyDisplayText",copyable);
end

function itemBoxRight()
	SlotItem = nil;
	UpdateStats();
end

SetCopyText = function(text)
	if type(text) == "table" then
		CopyText = sb.printJson(text);
		--sb.logInfo("CopyText = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",sb.printJson(text,1));
	else
		CopyText = text;
		--sb.logInfo("CopyText = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",text);
	end
	__copybox__();
end

function __copybox__()
	if widget.getText("copybox") ~= CopyText then
		widget.blur("copybox");
	end
	widget.setText("copybox",CopyText);
	--sb.logInfo("CopyBox = " .. sb.print(widget.getText("copybox")));
end

--Called when the copy button is clicked on
function copyButton()
	--sb.logInfo("Copy Button");
	widget.focus("copybox");
end

--Sets up the inventory slots
SetupInventoryArea = function(items)
	InventoryItems = {};
	widget.clearListItems(SlotList);
	SetScanningItem(nil);
	for _,item in pairs(items) do
		--Check if unique
		for x=1,#InventoryItems do
			if root.itemDescriptorsMatch(InventoryItems[x],item,true) then
				goto Continue;
			end
		end
		InventoryItems[#InventoryItems + 1] = item;
		local GlobalSlot = #InventoryItems;
		local SlotAtRow = ((GlobalSlot - 1) % SlotsPerRow) + 1;
		local RowNumber = math.ceil(GlobalSlot / SlotsPerRow);
		if Rows[RowNumber] == nil then
			Rows[RowNumber] = widget.addListItem(SlotList);
		end
		local SelectedRow = SlotList .. "." .. Rows[RowNumber];
		local SlotPath = SelectedRow .. ".slot" .. SlotAtRow;
		widget.setVisible(SlotPath,true);
		widget.setItemSlotItem(SlotPath,{name = item.name,count = 1,parameters = item.parameters});
		widget.setData(SlotPath,GlobalSlot);
		::Continue::
	end
end

--Called when a slot is clicked
SlotClick = function(slot)
	SetScanningItem(InventoryItems[slot]);
end

SlotRightClick = function(slot)
	SetScanningItem(nil);
end