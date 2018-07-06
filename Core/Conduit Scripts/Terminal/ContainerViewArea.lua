if ContainerArea ~= nil then return nil end;
require("/Core/Conduit Scripts/Terminal/ViewWindow.lua");
require("/Core/Conduit Scripts/Terminal/SafeCommunicate.lua");

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
local SetContainerRoutine;
local UpdateContainerRoutine;

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
	SetContainerRoutine = sb.makeUuid();
	UpdateContainerRoutine = sb.makeUuid();
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
		--if not world.entityExists(Container) then
		--	ContainerArea.Disable();
		--else
			ContainerUpdateTimer = ContainerUpdateTimer + dt;
			if ContainerUpdateTimer > ContainerUpdateRate then
				ContainerUpdateTimer = 0;
				UICore.QuickAsync(UpdateContainerRoutine,function()
					local Items = SafeCommunicate.GetContainerItemsAsync(Container);
					--sb.logInfo("Items Update = " .. sb.print(Items));
					ContainerItems = Items;
					if Items == nil then
						ContainerArea.Disable();
						return nil;
					end
					for i=1,ContainerSize do
						UpdateContainerSlot(i,Items[i]);
					end
				end);
			end
		--end
	end
end

--Updates a specific Slot
UpdateContainerSlot = function(slot,item)
	if Container ~= nil then
		local Item = item or world.containerItemAt(Container,slot - 1);
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
			--ContainerArea.SetContainer(nil);
			UICore.CancelCoroutine(SetContainerRoutine);
			Container = nil;
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
	UICore.QuickAsync(SetContainerRoutine,function()
		if Container ~= container then
			if container == nil then
				ContainerArea.Disable();
			else
				SelectedSlot = nil;
				local SizePromise = SafeCommunicate.GetContainerSize(container);
				local ItemsPromise = SafeCommunicate.GetContainerItems(container);
				local DescriptionPromise = SafeCommunicate.GetObjectParameter(container,"shortdescription");
				local NamePromise = SafeCommunicate.GetObjectName(container);
				local Size,Items,Description,Name = SafeCommunicate.AwaitAll(SizePromise,ItemsPromise,DescriptionPromise,NamePromise);
				--sb.logInfo("Size = " .. sb.print(Size));
				--sb.logInfo("Items = " .. sb.print(Items));
				--sb.logInfo("Description = " .. sb.print(Description));
				--sb.logInfo("Name = " .. sb.print(Name));
				--sb.logInfo("EXTRACTION = " .. sb.print(extraction));
				--sb.logInfo("INSERTIOn = " .. sb.print(insertion));
				if Items == nil then return nil end;
				ContainerArea.Enable();
				Description = Description or Name;
				widget.setText(ContainerName,Description);
				widget.clearListItems(ContainerItemList);
				--local Size = world.containerSize(container);
				ContainerSize = Size;
				ContainerItems = Items;
				widget.setItemSlotItem(ContainerBox,{name = Name,count = 1});
				local CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
				local H = 1;
				if extraction == true then
					ContainerExtraction = true;
					--sb.logInfo("Extractable");
					widget.setVisible(ExtractButton,true);
					widget.setVisible(SendHereButton,true);
				else
					ContainerExtraction = false;
					--sb.logInfo("Not Extractable");
					widget.setVisible(ExtractButton,false);
					widget.setVisible(SendHereButton,false);
				end
				if insertion == true then
					ContainerInsertion = true;
					widget.setVisible(InsertButton,true);
				else
					ContainerInsertion = false;
					widget.setVisible(InsertButton,false);
				end
				for i=1,Size do
					SlotTable[i] = {};
					if H > 12 then
						CurrentListItem = ContainerItemList .. "." .. widget.addListItem(ContainerItemList);
						H = 1;
					end
					--local Item = world.containerItemAt(container,i - 1);
					local Item = Items[i];
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
				--sb.logInfo("Extract False");
				widget.setButtonEnabled(ExtractButton,false);
				widget.setButtonEnabled(InsertButton,false);
			end
			Container = container;
		end
	end);
end

function ContainerArea.GetContainer()
	return Container;
end

function ContainerArea.__ContainerBoxClicked__()
	if Container ~= nil then
		UICore.AddAsyncCoroutine(function()
			ViewWindow.SetPosition(SafeCommunicate.GetObjectPositionAsync(Container));
		end);
		--ViewWindow.SetPosition(world.entityPosition(Container));
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
	--local SlotItem = world.containerItemAt(Container,Slot - 1);
	local SlotItem = ContainerItems[Slot];
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
				--sb.logInfo("Extract False 2");				
				widget.setButtonEnabled(ExtractButton,false);
				widget.setButtonEnabled(InsertButton,false);
				widget.setText("amountBox","");
			else
				HighlightSlot(SelectedSlot,true);
				local SlotItem = SlotTable[SelectedSlot].Get();
				--sb.logInfo("IS EXTRACTABLE = " .. sb.print(ContainerExtraction));
				if ContainerExtraction == true then
					--sb.logInfo("Extract True");
					widget.setButtonEnabled(SendHereButton,true);
					widget.setButtonEnabled(ExtractButton,true);
					if SlotItem ~= nil then
						widget.setText("amountBox",SlotItem.count);
					else
						widget.setText("amountBox","");
					end
				else
					widget.setButtonEnabled(SendHereButton,false);
					--sb.logInfo("Extract False 3");					
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
function __Extract()
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