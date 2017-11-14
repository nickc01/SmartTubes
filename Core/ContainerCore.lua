ContainerCore = {};

local ContainerSize;

local Container = {};
local Position;

local Configs = setmetatable({},{__mode = 'v'});

local function GetConfig(Item)
	local ItemConfig;
	if Configs[Item.name] ~= nil then
		ItemConfig = Configs[Item.name];
	else
		ItemConfig = root.itemConfig(Item);
		if ItemConfig == nil then
			error("The Item : " .. sb.print(Item) .. ", is invalid, can't retrieve config for such item");
		else
			Configs[Item.name] = ItemConfig;
		end
	end
	return ItemConfig.config;
end

function ContainerCore.Init(containerSize)
	ContainerSize = containerSize or config.getParameter("slotCount");
	if ContainerSize == nil then
		error("Must Specify a Container Size");
	end
	Position = entity.position();
	Container = config.getParameter("ContainerCore_ItemContainer",{});
	message.setHandler("ContainerCore.ContainerItems",ContainerCore.ContainerItemsRef);
	message.setHandler("ContainerCore.ContainerSize",ContainerCore.ContainerSize);
	message.setHandler("ContainerCore.LeftClick",ContainerCore.LeftClick);
	message.setHandler("ContainerCore.RightClick",ContainerCore.RightClick);
end

function ContainerCore.Uninit(dropAll,position,dropFunction)
	if dropAll == true then
		for i=1,ContainerSize do
			local Index = tostring(i);
			if Container[Index] ~= nil then
				if dropFunction == nil then
					world.spawnItem(Container[Index],position or Position,Container[Index].count,Container[Index].parameters);
				else
					dropFunction(Container[Index],position or Position);
				end
			end
		end
	else
		object.setConfigParameter("ContainerCore_ItemContainer",Container);
	end
end


function ContainerCore.ContainerSize()
	return ContainerSize;
end

function ContainerCore.ContainerItems()
	local NewContainer = {};
	for i=1,ContainerSize do
		local Index = tostring(i);
		if Container[Index] ~= nil then
			NewContainer[Index] = {name = Container[Index].name,count = Container[Index].count,parameters = Container[Index].parameters};
		--else
		--	NewContainer[Index] = "null";
		end
	end
	return NewContainer;
end

function ContainerCore.ContainerItemsRef()
	return Container;
end

function ContainerCore.ContainerAvailable(Item)
	local Count = 0;
	for i=1,ContainerSize do
		local Index = tostring(i);
		if Container[Index] ~= nil and root.itemDescriptorsMatch(Container[Index],Item,true) then
			Count = Count + Container[Index].count;
		end
	end
	return Count;
end

function ContainerCore.ContainerTakeAll()
	local ReturningValue = ContainerCore.ContainerItems();
	Container = {};
	return ReturningValue;
end

function ContainerCore.ContainerTakeAt()
	local Item = Container[tostring(slot + 1)];
	Container[tostring(slot + 1)] = nil;
	return Item;
end

function ContainerCore.ContainerTakeNumItemsAt(slot,Count)
	local Index = tostring(slot + 1);
	if Container[Index] ~= nil then
		local Item = {name = Container[Index].name,count = 0,parameters = Container[Index].parameters};
		if Container[Index].count >= Count then
			Item.count = Count;
			Container[Index].count = Container[Index].count - Count;
			if Container[Index].count <= 0 then
				Container[Index] = nil;
			end
		else
			Item.count = Container[Index].count;
			Container[Index] = nil;
		end
		if Item.count == 0 then
			return nil;
		else
			return Item;
		end
	else
		return nil;
	end
end

function ContainerCore.ContainerItemsCanFit(Item)
	local Times = 0;
	--[[local ItemConfig = root.itemConfig(Item);
	local MaxStack;
	if ItemConfig == nil then
		error("The Item is invalid");
	else
		MaxStack = ItemConfig.config.maxStack or 1000;
	end--]]
	local ItemConfig = GetConfig(Item);
	local MaxStack = ItemConfig.maxStack or 1000;
	for i=1,ContainerSize do
		local Index = tostring(i);
		if Container[Index] == nil then
			Times = Times + (math.floor(MaxStack / Item.count));
		else
			if root.itemDescriptorsMatch(Item,Container[Index],true) then
				Times = Times + (math.floor((MaxStack - Container[Index].count) / Item.count));
			end
		end
	end
	return Times;
end

function IsContainerCore()
	return true;
end

function ContainerCore.ContainerAddItems(Item)
	--sb.logInfo("Adding = " .. sb.print(Item));
	local Count = Item.count;
	if Count == 0 then
		return nil;
	end
	--[[local ItemConfig = root.itemConfig(Item);
	local MaxStack;
	if ItemConfig == nil then
		error("The Item is invalid");
	else
		MaxStack = ItemConfig.config.maxStack or 1000;
	end--]]
	local ItemConfig = GetConfig(Item);
	local MaxStack = ItemConfig.maxStack or 1000;
	for i=1,ContainerSize do
		local Index = tostring(i);
		if Container[Index] == nil then
			if Count > MaxStack then
				Container[Index] = {name = Item.name,count = MaxStack,parameters = Item.parameters};
				Count = Count - MaxStack;
			else
				Container[Index] = {name = Item.name,count = Count,parameters = Item.parameters};
				Count = 0;
			end
		else
			if root.itemDescriptorsMatch(Item,Container[Index],true) and Container[Index].count < MaxStack then
				if Container[Index].count + Count > MaxStack then
					Count = Container[Index].count + Count - MaxStack;
					Container[Index].count = MaxStack;
				else
					Container[Index].count = Container[Index].count + Count;
					Count = 0;
				end
			end
		end
		if Count == 0 then
			break;
		end
	end
	if Count == 0 then
		return nil;
	else
		return {name = Item.name,count = Count,parameters = Item.parameters};
	end
end

function ContainerCore.ContainerStackItems(Item)
	local Count = Item.count;
	--[[local ItemConfig = root.itemConfig(Item);
	local MaxStack;
	if ItemConfig == nil then
		error("The Item is invalid");
	else
		MaxStack = ItemConfig.config.maxStack or 1000;
	end--]]
	local ItemConfig = GetConfig(Item);
	local MaxStack = ItemConfig.maxStack or 1000;
	for i=1,ContainerSize do
		local Index = tostring(i);
		if Container[Index] ~= nil and root.itemDescriptorsMatch(Item,Container[Index],true) and Container[Index].count < MaxStack then
			if Container[Index].count + Count > MaxStack then
				Count = Container[Index].count + Count - MaxStack;
				Container[Index].count = MaxStack;
			else
				Container[Index].count = Container[Index].count + Count;
				Count = 0;
			end
		end
	end
	if Count == 0 then
		return nil;
	else
		return {name = Item.name,count = Count,parameters = Item.parameters};
	end
end

function ContainerCore.ContainerPutItemsAt(Item,slot)
	--sb.logInfo("Attempting To Put In Slot " .. sb.print(slot + 1));
	--local ItemConfig = root.itemConfig(Item);
	--local MaxStack;
	local Count = Item.count;
	--[[if ItemConfig == nil then
		error("The Item is invalid");
	else
		MaxStack = ItemConfig.config.maxStack or 1000;
	end--]]
	local ItemConfig = GetConfig(Item);
	local MaxStack = ItemConfig.maxStack or 1000;
	local Index = tostring(slot + 1);
	if Container[Index] == nil then
		Container[Index] = {name = Item.name,count = Item.count,parameters = Item.parameters};
		return nil;
	else
	--[[	if root.itemDescriptorsMatch(Item,Container[Index],true) and Container[Index].count < MaxStack then
			Count = Container[Index].count + Count - MaxStack;
			return {name = Item.name,count = Count,parameters = Item.parameters};
		end--]]
		--sb.logInfo("Container Slot of " .. Index .. " = " .. sb.print(Container[Index]));
		if root.itemDescriptorsMatch(Item,Container[Index],true) then
			if Container[Index].count + Count <= MaxStack then
				Container[Index].count = Container[Index].count + Count;
				return nil;
			else
				Count = Container[Index].count + Count - MaxStack;
				Container[Index].count = MaxStack;
				return {name = Item.name,count = Count,parameters = Item.parameters};
			end
		end
	end
	return Item;
end

function ContainerCore.ContainerSwapItemsNoCombine(Item,slot)
	local SlotItem;
	local Index = tostring(slot + 1);
	SlotItem,Container[Index] = Container[Index],Item;
	return SlotItem;
end

function ContainerCore.ContainerSwapItems(Item,slot)
	--local ItemConfig = root.itemConfig(Item);
	--local MaxStack;
	local Count = Item.count;
	--[[if ItemConfig == nil then
		error("The Item is invalid");
	else
		MaxStack = ItemConfig.config.maxStack or 1000;
	end--]]
	local ItemConfig = GetConfig(Item);
	local MaxStack = ItemConfig.maxStack or 1000;
	local Index = tostring(slot + 1);
	if Container[Index] ~= nil and root.itemDescriptorsMatch(Item,Container[Index],true) and Container[Index].count < MaxStack then
		if Container[Index].count + Count > MaxStack then
			Count = Container[Index].count + Count - MaxStack;
			Container[Index] = MaxStack;
			return {name = Item.name,count = Count,parameters = Item.parameters};
		else
			Container[Index].count = Container[Index].count + Count;
			Count = 0;
			return nil;
		end
	end
	return ContainerCore.ContainerSwapItemsNoCombine(Item,slot);
end


function ContainerCore.ContainerConsume(Item,Amount)
	local FullCount = Amount or Item.count;
	if ContainerCore.ContainerAvailable(Item) <= 0 then
		return false;
	end
	if Item.count <= 0 then
		return true;
	end
	if ContainerCore.ContainerAvailable(Item) >= FullCount then
		local CountRemaining = FullCount;
		for i=1,ContainerSize do
			local Index = tostring(i);
			if Container[Index] ~= nil and root.itemDescriptorsMatch(Container[Index],Item,true) then
				if CountRemaining > Container[Index].count then
					CountRemaining = CountRemaining - Container[Index].count;
					Container[Index] = nil;
					if CountRemaining == 0 then
						break;
					end
				else
					Container[Index].count = Container[Index].count - CountRemaining;
					if Container[Index].count <= 0 then
						Container[Index] = nil;
					end
					CountRemaining = 0;
					break;
				end
			end
		end
		return true;
	else
		return false;
	end
end

local function SetSlotNull(Slot)
	Container[tostring(Slot + 1)] = nil;
end

function ContainerCore.ContainerConsumeAt(Slot,Count)
	if Count <= 0 then
		return true;
	end
	local Item = ContainerCore.ContainerItemAtRef(Slot);
	if Item ~= nil and Item.count >= Count then
		--sb.logInfo("Subtracting " .. sb.print(Count));
		Item.count = Item.count - Count;
		if Item.count == 0 then
			SetSlotNull(Slot);
		end
		return true;
	else
		return false;
	end
end

function ContainerCore.LeftClick(_,_,slot,player,currentSwapItem)
	local Index = tostring(slot + 1);
	if currentSwapItem == nil then
		local Item;
		Item,Container[Index] = Container[Index],nil;
		world.sendEntityMessage(player,"SetSwapItem",Item);
	else
		local Item = ContainerCore.ContainerSwapItems(currentSwapItem,slot);
		world.sendEntityMessage(player,"SetSwapItem",Item);
	end
end

function ContainerCore.RightClick(_,_,slot,player,currentSwapItem)
	local Index = tostring(slot + 1);
	if currentSwapItem == nil then
		local TakenItem = ContainerCore.ContainerTakeNumItemsAt(slot,1);
		if TakenItem ~= nil then
			world.sendEntityMessage(player,"SetSwapItem",TakenItem);
		end
	else
		--[[local ItemConfig = root.itemConfig(currentSwapItem);
		local MaxStack;
		if ItemConfig == nil then
			error("The Item is invalid");
		else
			MaxStack = ItemConfig.config.maxStack or 1000;
		end--]]
		local ItemConfig = GetConfig(Item);
		local MaxStack = ItemConfig.maxStack or 1000;
		if root.itemDescriptorsMatch(currentSwapItem,Container[Index],true) and currentSwapItem.count < MaxStack then
			local TakenItem = ContainerCore.ContainerTakeNumItemsAt(slot,1);
			if TakenItem ~= nil then
				currentSwapItem.count = currentSwapItem.count + TakenItem.count;
				world.sendEntityMessage(player,"SetSwapItem",currentSwapItem);
			end
		end
	end
end

function ContainerCore.ContainerItemAt(slot)
	--return Container[tostring(slot + 1)];
	local Item;
	local Index = tostring(slot + 1);
	if Container[Index] ~= nil then
		Item = {name = Container[Index].name,count = Container[Index].count,parameters = Container[Index].parameters}
	end
	return Item;
end
function ContainerCore.ContainerItemAtRef(slot)
	return Container[tostring(slot + 1)];
end