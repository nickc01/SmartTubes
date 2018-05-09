if ContainerArea ~= nil then return nil end;
require("/Core/Conduit Scripts/Terminal/ViewWindow.lua");

--Declaration
ContainerArea = {};
local ContainerArea = ContainerArea;

--Item Names
local ContainerBox = "containerBeingViewed";
local ContainerName = "containerName";
local ContainerScrollArea = "containerViewArea";
local ContainerItemList = ContainerScrollArea .. ".itemList";
local SendHereButton = "sendHereButton";
local AmountArea = "amountArea";
local AmountBox = "amountBox";
local InsertButton = "insertButton";
local ExtractButton = "extractButton";

--Variables
local Initialized = false;
local Enabled = false;
local Container;
local SlotTable = {};
local SelectedSlot;

--Functions
local OnContainerClick;
local SlotClicked;
local SlotRightClicked;
local SelectedSlotUpdate;
local UpdateFunctions = {};
local Update;
local AddUpdateFunction;
local RemoveUpdateFunction;

--Initializes the Container Area
function ContainerArea.Initialize()
	if Initialized == false then
		Initialized = true;
		widget.registerMemberCallback(ContainerItemList,"__SlotClick__",__SlotClick__);
		widget.registerMemberCallback(ContainerItemList,"__SlotRightClick__",__SlotRightClick__);
		local OldUpdate = update;
		update = function(dt)
			if OldUpdate ~= nil then
				OldUpdate(dt);
			end
			Update(dt);
		end
	end
end

-- The Update Loop for the Container Area
Update = function(dt)
	for _,func in pairs(UpdateFunctions) do
		func(dt);
	end
end

--Adds an update function
AddUpdateFunction = function(func)
	local ID = sb.makeUuid();
	UpdateFunctions[ID] = func;
	return ID;
end

--Removes an Update function
RemoveUpdateFunction = function(ID)
	UpdateFunctions[ID] = nil;
end

--Enables the Container Area
function ContainerArea.Enable()
	Enabled = true;
	widget.setVisible(ContainerBox,true);
	widget.setVisible(ContainerName,true);
	widget.setVisible(ContainerScrollArea,true);
	widget.setVisible(SendHereButton,true);
	widget.setVisible(ExtractButton,true);
	widget.setVisible(InsertButton,true);
	widget.setVisible(AmountArea,true);
	widget.setVisible(AmountBox,true);
end

--Disables the Container Area
function ContainerArea.Disable()
	Container = nil;
	Enabled = false;
	widget.setVisible(ContainerBox,false);
	widget.setVisible(ContainerName,false);
	widget.setVisible(ContainerScrollArea,false);
	widget.setVisible(SendHereButton,false);
	widget.setActive(SendHereButton,false);
	widget.setButtonEnabled(SendHereButton,false);
	widget.clearListItems(ContainerItemList);
	widget.setVisible(ExtractButton,false);
	widget.setVisible(InsertButton,false);
	widget.setVisible(AmountArea,false);
	widget.setVisible(AmountBox,false);
	widget.setItemSlotItem(ContainerBox,nil);
	widget.setText(ContainerName,"");
	widget.setButtonEnabled(SendHereButton,false);
	widget.setButtonEnabled(ExtractButton,false);
	widget.setButtonEnabled(InsertButton,false);
end

--Sets the container to be showed in the container Area
function ContainerArea.SetContainer(object,clickFunction,rightClickFunction)
	widget.clearListItems(ContainerItemList);
	widget.setButtonEnabled(SendHereButton,false);
	widget.setButtonEnabled(ExtractButton,false);
	widget.setButtonEnabled(InsertButton,false);
	UpdateFunctions = {};
	SlotTable = {};
	if object ~= nil then
		if Enabled == false then
			ContainerArea.Enable();
		end
		local Size = world.containerSize(object);
		local H = 1;
		--sb.logInfo("ListItem = " .. sb.print(widget.addListItem(ContainerItemList)));
		widget.setItemSlotItem(ContainerBox,{name = world.entityName(object),count = 1});
		--widget.registerMemberCallback(ContainerBox,"callback",function()
			--sb.logInfo("CLICKING");
			--ViewWindow.SetPosition(world.entityPosition(object));
		--end);
		OnContainerClick = function()
			sb.logInfo("CLICKING");
			ViewWindow.SetPosition(world.entityPosition(object));
		end
		widget.setText(ContainerName,world.getObjectParameter(object,"shortdescription") or world.entityName(object));
		local CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
		for i=1,Size do
			SlotTable[i] = {};
			if H > 12 then
				CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
				H = 1;
			end
			sb.logInfo("i = " .. sb.print(i));
			local Item = world.containerItemAt(object,i - 1);
			local SlotName = CurrentListItem .. ".slot" .. H;
			widget.setItemSlotItem(SlotName,Item);
			widget.registerMemberCallback(SlotName,"rightClickCallback",function()
				SlotRightClicked(i);
			end);
			SlotTable[i].Set = function(newItem)
				widget.setItemSlotItem(SlotName,newItem);
			end
			SlotTable[i].Get = function()
				return widget.itemSlotItem(SlotName);
			end
			SlotTable[i].GetWidget = function()
				return SlotName;
			end
			widget.setData(SlotName,tostring(i));
			widget.setVisible(SlotName,true);
			widget.setVisible(SlotName .. "background",true);
			--widget.setVisible(SlotName,true);
		--	widget.setVisible(SlotName .. "background",true);
			--widget.setButtonEnabled(SendHereButton,false);
			H = H + 1;
		end
		AddUpdateFunction(function(dt)
			sb.logInfo("Update");
			for i=1,Size do
				--if SlotTable[i] ~= nil then
					ContainerArea.ItemInSlot(i);
				--end
			end
		end);
	else
		OnContainerClick = nil;
		if Enabled == true then 
			ContainerArea.Disable();
		end
	end
	Container = object;
end

--Sets the Selected slot
function ContainerArea.SetSelectedSlot(slot)
	if Container ~= nil then
		if SelectedSlot ~= slot then
			if SelectedSlot ~= nil then
				widget.setImage(SlotTable[SelectedSlot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot.png");
			end
		end
		SelectedSlot = slot;
		if slot ~= nil then
			widget.setImage(SlotTable[slot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot Selected.png");
		end
		SelectedSlotUpdate();
	end
end

--Returns the Item in the slot number
function ContainerArea.ItemInSlot(slot)
	if Container ~= nil then
		local StoredItem = world.containerItemAt(Container,slot - 1);
		SlotTable[slot].Set(StoredItem,slot);
		return SlotTable[slot].Get();
	end
end

--Called when the Selected Slot is updated
SelectedSlotUpdate = function()
	if SelectedSlot ~= nil then
		
	end
end

--Sets the Item in the slot number
function ContainerArea.SetItemInSlot(slot,item)
	if Container ~= nil then
		return SlotTable[slot].Set(item);
	end
end

--Returns true if there's a container being viewed
function ContainerArea.HasContainer()
	return Container ~= nil;
end

--Called when the containerbox is clicked
function ContainerArea.__ContainerBoxClicked__()
	if OnContainerClick ~= nil then
		OnContainerClick();
	end
end

--Called when the "Send Here" Button is clicked
function SendHere()
	
end

--Called when a slot is clicked
SlotClicked = function(slot)
	ContainerArea.SetSelectedSlot(slot);
	--[[sb.logInfo("Click on Slot = " .. sb.print(slot));
	if SelectedSlot ~= nil then
		widget.setImage(SlotTable[SelectedSlot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot.png");
	end
	SelectedSlot = slot;
	widget.setImage(SlotTable[slot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot Selected.png");--]]
end

--Called when a slot is right clicked
SlotRightClicked = function(slot)
	if slot == SelectedSlot then
		ContainerArea.SetSelectedSlot(nil);
	end
end

--Internal Handler for slot clicks
function __SlotClick__(widgetName,data)
	SlotClicked(tonumber(data));
end

--Internal Handler for slot right clicks
function __SlotRightClick__(widgetName,data)
	SlotRightClicked(tonumber(data));
end