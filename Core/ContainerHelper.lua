
if ContainerHelper ~= nil then return nil end;
--Declaration
ContainerHelper = {};
local Container = ContainerHelper;
--Variables

--Functions

--Returns if it is a container
function Container.IsContainer(ID)
	return world.getObjectParameter(ID,"objectType") == "container" or (world.entityExists(ID) and world.callScriptedEntity(ID,"IsContainerCore") == true);
end

--Returns if this entity is using The "ContainerCore" Api for containers
function Container.IsScriptedContainer(ID)
	return world.entityExists(ID) and world.callScriptedEntity(ID,"IsContainerCore") == true;
end

--Returns the total capacity of the specified container, or `nil` if the entity is not a container.
function Container.Size(ID)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerSize");
	else
		return world.containerSize(ID);
	end
end

--Returns a list of pairs of item descriptors and container positions of all items in the specified container, or `nil` if the entity is not a container.
function Container.Items(ID)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerItems");
	else
		local Items = world.containerItems(ID);
		local meta = getmetatable(Items);
		local OldNewIndex = meta.__newindex;
		local Num = false;
		for k,i in ipairs(Items) do
			Num = true;
			break;
		end
		if Num == true then
			meta.__newindex = function(tbl,k,value)
				return OldNewIndex(tbl,k,value);
			end
			meta.__index = function(tbl,k)
				return rawget(tbl,k);
			end
		else
			meta.__newindex = function(tbl,k,value)
				if type(k) == "number" then
					return OldNewIndex(tbl,k,value);
				else
					return OldNewIndex(tbl,tostring(k),value);
				end
			end
			meta.__index = function(tbl,k)
				if type(k) == "number" then
					return rawget(tbl,k);
				else
					return rawget(tbl,tostring(k));
				end
			end
		end
		--sb.logInfo("Metatable = " .. sb.print(getmetatable(Items)));
		return Items;
	end
end

--Will Return Reference to Items if Possible
function Container.ItemsRef(ID)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerItemsRef"),true;
	else
		return world.containerItems(ID),false;
	end
end

--Returns the number of the specified item that are currently available to consume in the specified container, or `nil` if the entity is not a container.
function Container.Available(ID,Item)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerAvailable",Item);
	else
		return world.containerAvailable(ID,Item);
	end
end

--Similar to world.containerItems but consumes all items in the container.
function Container.TakeAll(ID)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerTakeAll");
	else
		return world.containerTakeAll(ID);
	end
end

--Similar to world.containerItemAt, but consumes all items in the specified slot of the container.
function Container.TakeAt(ID,Slot)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerTakeAt",Slot);
	else
		return world.containerTakeAt(ID,Slot);
	end
end

--Similar to world.containerTakeAt, but consumes up to (but not necessarily equal to) the specified count of items from the specified slot of the container and returns only the items consumed.
function Container.TakeNumItemsAt(ID,Slot,Count)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerTakeNumItemsAt",Slot,Count);
	else
		return world.containerTakeAt(ID,Slot,Count);
	end
end

--Returns the number of times the specified item can fit in the specified container, or `nil` if the entity is not a container.
function Container.ItemsCanFit(ID,Item)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerItemsCanFit",Item);
	else
		return world.containerItemsCanFit(ID,Item);
	end
end

--Adds the specified items to the specified container. Returns the leftover items after filling the container, or all items if the entity is not a container.
function Container.AddItems(ID,Item)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerAddItems",Item);
	else
		return world.containerAddItems(ID,Item);
	end
end

--Similar to world.containerAddItems but will only combine items with existing stacks and will not fill empty slots.
function Container.StackItems(ID,Item)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerStackItems",Item);
	else
		return world.containerStackItems(ID,Item);
	end
end

--Similar to world.containerAddItems but only considers the specified slot in the container.
function Container.PutItemsAt(ID,Item,Slot)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerPutItemsAt",Item,Slot);
	else
		return world.containerPutItemsAt(ID,Item,Slot);
	end
end

--Places the specified items into the specified container slot and returns the previous contents of the slot if successful, or the original items if unsuccessful.
function Container.SwapItemsNoCombine(ID,Item,Slot)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerSwapItemsNoCombine",Item,Slot);
	else
		return world.containerSwapItemsNoCombine(ID,Item,Slot);
	end
end

--A combination of world.containerItemApply and world.containerSwapItemsNoCombine that attempts to combine items before swapping and returns the leftovers if stacking was successful or the previous contents of the container slot if the items did not stack.
function Container.SwapItems(ID,Item,Slot)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerSwapItems",Item,Slot);
	else
		return world.containerSwapItems(ID,Item,Slot);
	end
end

--Attempts to consume items from the specified container that match the specified item descriptor and returns `true` if successful, `false` if unsuccessful, or `nil` if the entity is not a container. Only succeeds if the full count of the specified item can be consumed.
function Container.Consume(ID,Item)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerConsume",Item);
	else
		return world.containerConsume(ID,Item);
	end
end

--Similar to world.containerConsume but only considers the specified slot within the container.
function Container.ConsumeAt(ID,Slot,Count)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerConsumeAt",Slot,Count);
	else
		return world.containerConsumeAt(ID,Slot,Count);
	end
end

--Returns an item descriptor of the item at the specified position in the specified container, or `nil` if the entity is not a container or the offset is out of range.
function Container.ItemAt(ID,Slot)
	if world.callScriptedEntity(ID,"IsContainerCore") == true then
		return world.callScriptedEntity(ID,"ContainerCore.ContainerItemAt",Slot);
	else
		return world.containerItemAt(ID,Slot);
	end
end

