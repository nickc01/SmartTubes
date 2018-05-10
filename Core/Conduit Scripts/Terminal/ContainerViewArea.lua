if ContainerArea ~= nil then return nil end;
require("/Core/Conduit Scripts/Terminal/ViewWindow.lua");

--Declaration
ContainerArea = {};
local ContainerArea = ContainerArea;

--Variables
local Initialize = false;
local ContainerBox = "containerBeingViewed";
local ContainerName = "containerName";
local ContainerScrollArea = "containerViewArea";
local ContainerItemList = ContainerScrollArea .. ".itemList";
local SendHereButton = "sendHereButton";
local AmountArea = "amountArea";
local AmountBox = "amountBox";
local InsertButton = "insertButton";
local ExtractButton = "extractButton";
local Elements = {ContainerBox,ContainerName,ContainerScrollArea,
ContainerItemList,SendHereButton,AmountArea,AmountBox,InsertButton,
ExtractButton};
local Enabled = true;
local Container;
local ContainerSize;
local ContainerItems;
local ContainerExtraction;
local ContainerInsertion;
local SelectedSlot;
local SlotTable = {};
local ContainerUpdateRate = 0.3;
local ContainerUpdateTimer = 0;
local SourceID;
local ItemConfigCache = {};

--Functions
local Update;
local SlotClicked;
local SlotRightClicked;
local SetSelectedSlot;
local HighlightSlot;
local UpdateContainerSlot;
local GetItemConfig;
local PutItemInContainer;

--Initalizes the Container Area
function ContainerArea.Initialize()
	if Initialize == true then return nil end;
	Initialize = true;
	ContainerArea.Disable();
	SourceID = config.getParameter("MainObject") or pane.sourceEntity();
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

--The Update Loop for the Container Area
Update = function(dt)
	if Container ~= nil then
		if not world.entityExists(Container) then
			ContainerArea.Disable();
		else
			ContainerUpdateTimer = ContainerUpdateTimer + dt;
			if ContainerUpdateTimer > ContainerUpdateRate then
				ContainerUpdateTimer = 0;
				for i=1,ContainerSize do
					UpdateContainerSlot(i);
				end
			end
		end
	end
end

--Updates a specific Slot
UpdateContainerSlot = function(slot)
	if Container ~= nil then
		local Item = world.containerItemAt(Container,slot - 1);
		SlotTable[slot].Set(Item);
	end
end

--Enables the Container Area
function ContainerArea.Enable(bool)
	if bool == nil then bool = true end;
	if bool ~= Enabled then
		Enabled = bool;
		for i=1,#Elements do
			widget.setVisible(Elements[i],bool);
		end
		if Enabled == false then
			--Container = nil;
			ContainerArea.SetContainer(nil);
		end
	end
end

--Disables the Container Area
function ContainerArea.Disable()
	ContainerArea.Enable(false);
end

--Sets the Container for the Container Area,
--Set "extraction" parameter to true if this container has a connected extraction conduit
--Set "insertion" parameter to true if this container has a connected insertion conduit
function ContainerArea.SetContainer(container,extraction,insertion)
	if Container ~= container then
		Container = container;
		if Container == nil then
			ContainerArea.Disable();
		else
			ContainerArea.Enable();
			widget.setText(ContainerName,world.getObjectParameter(Container,"shortdescription") or world.entityName(Container));
			widget.clearListItems(ContainerItemList);
			local Size = world.containerSize(Container);
			ContainerSize = Size;
			widget.setItemSlotItem(ContainerBox,{name = world.entityName(Container),count = 1});
			local CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
			local H = 1;
			if extraction == true then
				ContainerExtraction = true;
				widget.setVisible(ExtractButton,true);
				widget.setVisible(SendHereButton,true);
			else
				ContainerExtraction = false;
				widget.setVisible(ExtractButton,false);
				widget.setVisible(SendHereButton,false);
			end
			if insertion == true then
				ContainerInsertion = true;
				widget.setVisible(InsertButton,true);
			else
				ContainerExtraction = false;
				widget.setVisible(InsertButton,false);
			end
			for i=1,Size do
				SlotTable[i] = {};
				if H > 12 then
					CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
					H = 1;
				end
				local Item = world.containerItemAt(Container,i - 1);
				local SlotName = CurrentListItem .. ".slot" .. H;
				widget.setItemSlotItem(SlotName,Item);
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
				H = H + 1;
			end
			widget.setButtonEnabled(SendHereButton,false);
			widget.setButtonEnabled(ExtractButton,false);
			widget.setButtonEnabled(InsertButton,false);
		end
	end
end

function ContainerArea.__ContainerBoxClicked__()
	if Container ~= nil then
		ViewWindow.SetPosition(world.entityPosition(Container));
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

--Called when a slot is clicked
SlotClicked = function(slot)
	local SwapItem = player.swapSlotItem();
	if SwapItem ~= nil and ContainerInsertion == true then
		UpdateContainerSlot(slot);
		local Sent,SentAmount = PutItemInContainer(SwapItem,slot,Container);
		if Sent then
			if SentAmount == SwapItem.count then
				player.setSwapSlotItem(nil);
			else
				player.setSwapSlotItem({name = SwapItem.name,count = SwapItem.count - SentAmount,parameters = SwapItem.parameters});
			end
		end
	else
		SetSelectedSlot(slot);
	end
end

--Called when a slot is right clicked
SlotRightClicked = function(slot)
	--SetSelectedSlot(nil);
	local SwapItem = player.swapSlotItem();
	if SwapItem ~= nil and ContainerInsertion == true then
		UpdateContainerSlot(slot);
		local Sent,SentAmount = PutItemInContainer({name = SwapItem.name,count = 1,parameters = SwapItem.parameters},slot,Container);
		if Sent then
			if SwapItem.count - 1 == 0 then
				player.setSwapSlotItem(nil);
			else
				player.setSwapSlotItem({name = SwapItem.name,count = SwapItem.count - 1,parameters = SwapItem.parameters});
			end
		end
	else
		SetSelectedSlot(nil);
	end
end

--Puts an item in a Container, returns true if successful and returns the amount sent over
PutItemInContainer = function(Item,Slot,Container)
	local SlotItem = world.containerItemAt(Container,Slot - 1);
	if SlotItem == nil then
		world.sendEntityMessage(SourceID,"PutItemInContainer",Item,Container,Slot);
		return true,Item.count;
	elseif root.itemDescriptorsMatch(Item,SlotItem,true) then
		local ItemConfig = GetItemConfig(Item.name);
		local MaxStack = ItemConfig.config.maxStack or 1000;
		if SlotItem.count < MaxStack then
			local FinalCount = Item.count;
			if FinalCount > MaxStack - SlotItem.count then
				FinalCount = MaxStack - SlotItem.count;
			end
			local FinalItem = {name = Item.name,count = FinalCount,parameters = Item.parameters};
			world.sendEntityMessage(SourceID,"PutItemInContainer",FinalItem,Container,Slot);
			return true,FinalCount;
		end
	end
	return false;
end

function ContainerPutItemsAt(ID,Item,Offset)
    local ContainerSize = world.containerSize(ID);
    if ContainerSize == nil or Offset + 1 > ContainerSize then
        return Item;
    end
    local ItemConfig = root.itemConfig(Item);
    if ItemConfig == nil then
        return Item;
    end
    local MaxStack = ItemConfig.config.maxStack or 1000;
    local ItemInSlot = world.containerItemAt(ID,Offset);
    local RemainingCount = Item.count;
    if ItemInSlot == nil then
        local OriginalCount = Item.count;
        if Item.count > MaxStack then
            Item.count = Item.count - (Item.count - MaxStack);
        end
        RemainingCount = RemainingCount - world.containerItemApply(ID,Item,Offset).count;
        Item.count = OriginalCount;
    else
        if root.itemDescriptorsMatch(ItemInSlot,Item,true) then
            if ItemInSlot.count >= MaxStack then
                return Item;
            else
                local OriginalCount = Item.count;
                if ItemInSlot.count + Item.count > MaxStack then
                    Item.count = Item.count - (ItemInSlot.count + Item.count - MaxStack);
                end
                RemainingCount = OriginalCount - Item.count;
                world.containerSwapItems(ID,Item,Offset);
                Item.count = OriginalCount;
            end
        else
            return Item;
        end
    end
    if RemainingCount == 0 then
        return nil;
    end
    return {name = Item.name,count = RemainingCount,parameters = Item.parameters};
end

--Sets the Selected slot
SetSelectedSlot = function(slot)
	if Container ~= nil then
		if SelectedSlot ~= slot then
			if SelectedSlot ~= nil then
				HighlightSlot(SelectedSlot,false);
			end
			SelectedSlot = slot;
			if SelectedSlot == nil then
				widget.setButtonEnabled(SendHereButton,false);
				widget.setButtonEnabled(ExtractButton,false);
				widget.setButtonEnabled(InsertButton,false);
				widget.setText("amountBox","");
			else
				HighlightSlot(SelectedSlot,true);
				local SlotItem = SlotTable[SelectedSlot].Get();
				if ContainerExtraction == true then
					widget.setButtonEnabled(SendHereButton,true);
					widget.setButtonEnabled(ExtractButton,true);
					if SlotItem ~= nil then
						widget.setText("amountBox",SlotItem.count);
					else
						widget.setText("amountBox","");
					end
				else
					widget.setButtonEnabled(SendHereButton,false);
					widget.setButtonEnabled(ExtractButton,false);
				end
				if ContainerInsertion == true then
					widget.setButtonEnabled(InsertButton,true);
				else
					widget.setButtonEnabled(InsertButton,false);
				end
			end
		end
	end
end

--Sets a slot in it's highlighted state
HighlightSlot = function(slot,bool)
	if Container ~= nil then
		if bool == nil then bool = true end;
		if bool == true then
			widget.setImage(SlotTable[slot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot Selected.png");
		else
			widget.setImage(SlotTable[slot].GetWidget() .. "background","/Blocks/Conduit Terminal/UI/Window/Slot.png");
		end
	end
end

--Returns the config of the Item
GetItemConfig = function(itemName)
	if ItemConfigCache[itemName] == nil then
		ItemConfigCache[itemName] = root.itemConfig({name = itemName,count = 1});
	end
	return ItemConfigCache[itemName];
end

--Called when the Extract Button is Clicked
function Extract()
	if Container ~= nil and ContainerExtraction == true and SelectedSlot ~= nil then
		--TODO, set up the amount area
		local AmountText = widget.getText("amountBox");
		if AmountText == nil or AmountText == "" then
			AmountText = 1000;
		else
			AmountText = tonumber(AmountText);
		end
		--sb.logInfo("Amount Text = " .. sb.print(AmountText));
		UICore.CallMessageOnce(SourceID,"ExtractFromContainer",function(success)
			if success == true then
				UpdateContainerSlot(SelectedSlot);
			end
		end,Container,SelectedSlot,AmountText);
		--world.sendEntityMessage(SourceID,"ExtractFromContainer",Container,SelectedSlot,AmountText);
	end
end