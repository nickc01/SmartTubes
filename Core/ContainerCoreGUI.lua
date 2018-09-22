ContainerCore = {};

local ItemSlots;
local SourceID;
local ContainerSize;

local ContainerUpdatePromise;

local function SlotToIndex(slotLink)
	for i=1,#ItemSlots do
		if ItemSlots[i] == slotLink then
			return i;
		end
	end
	error(slotLink .. " is not a valid slot");
end

function ContainerCore.ChangeSourceID(sourceID)
	if sourceID ~= nil then
		SourceID = sourceID;
	end
end

function ContainerCore.Init(sourceID)
	if sourceID == nil then
		error("SourceID is required");
	end
	SourceID = sourceID;
	ItemSlots = config.getParameter("ItemSlots");
	if ItemSlots == nil then
		error("Could not find an Item Slots Parameter in the UI Config Json");
	end
end

function ContainerCore.AddSlot(slotLink)
	for i=#ItemSlots,1,-1 do
		if ItemSlots[i] == slotLink then
			return nil;
		end
	end
	ItemSlots[#ItemSlots + 1] = slotLink;
end

function ContainerCore.Update()
	if ContainerUpdatePromise == nil then
		ContainerUpdatePromise = world.sendEntityMessage(SourceID,"ContainerCore.ContainerItems");
	else
		if ContainerUpdatePromise:finished() == true then
			
			
			--[[for k,i in pairs(ContainerUpdatePromise:result()) do
				
				widget.setItemSlotItem(ItemSlots[tonumber(k)],i);
			end--]]
			local UpdatedContainer = ContainerUpdatePromise:result();
		--	
			if UpdatedContainer ~= nil then
				for i=1,#ItemSlots do
					widget.setItemSlotItem(ItemSlots[i],UpdatedContainer[tostring(i)]);
				end
			end
			ContainerUpdatePromise = nil;
			ContainerUpdatePromise = world.sendEntityMessage(SourceID,"ContainerCore.ContainerItems");
		end
	end
	--[[for k,i in ipairs(ContainerCore.ContainerItems()) do
		widget.setItemSlotItem(ItemSlots[k],i);
	end--]]
end

function ContainerCore.RemoveSlot(slotLink)
	for i=#ItemSlots,1,-1 do
		if ItemSlots[i] == slotLink then
			table.remove(ItemSlots,i);
			return nil;
		end
	end
end

--[[function ContainerCore.ContainerItems()
	return SendAndWait(SourceID,"ContainerCore.ContainerItems");
end--]]

--[[function ContainerCore.ContainerSize()
	return #ItemSlots;
end--]]

function ContainerCore.SlotCallback(slotLink)
	
	world.sendEntityMessage(SourceID,"ContainerCore.LeftClick",SlotToIndex(slotLink) - 1,player.id(),player.swapSlotItem());
end

function ContainerCore.SlotRightClickCallback(slotLink)
	
	world.sendEntityMessage(SourceID,"ContainerCore.RightClick",SlotToIndex(slotLink) - 1,player.id(),player.swapSlotItem());
end