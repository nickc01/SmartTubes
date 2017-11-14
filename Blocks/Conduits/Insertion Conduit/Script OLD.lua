local Cables;
local InsertID;
local ExtractAndSend;
local InsertConduitsAtContainer;
local InsertController = {{},{},{},{}};
local ContainerMap = {};
local ControllerFilled = false;
local EntityID;
local Predictions = {};
local PredictionsForDumping = {};
local Colors;
local AddToInventory;
local DropItems;
local AddAllItems;
local Ready = false;
local AddAllOfTraversalID;
--local ExpectedTravesals = {};
--local PredictionsByTraversal = {};
--[[if Initalizers == nil then
	Initializers = {};
end--]]

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function AddPredictionGroup(ContainerID)
	Predictions[tostring(ContainerID)] = {};
	--object.setConfigParameter("Predictions",Predictions);
end

local function GetPredictionGroup(ContainerID)
	ContainerID = tostring(ContainerID);
	if Predictions[ContainerID] == nil then
		Predictions[ContainerID] = {};
	end
	return Predictions[ContainerID];
end

--[[local function GetPredictions(ContainerID)
	
end--]]

local function AddPredictionAndSend(prediction)
	local predictionList = GetPredictionGroup(prediction.Container);
	local Contained = false;
	predictionList[#predictionList + 1] = prediction;
	--sb.logInfo("READY TO SPAWN!");
end

--[[local function RemovePrediction()
	
end--]]

local function GetDump(ContainerID)
	ContainerID = tostring(ContainerID);
	if PredictionsForDumping[ContainerID] == nil then
		PredictionsForDumping[ContainerID] = {};
	end
	return PredictionsForDumping[ContainerID];
end
local function AddToDump(ContainerID,value)
	ContainerID = tostring(ContainerID);
	if PredictionsForDumping[ContainerID] == nil then
		PredictionsForDumping[ContainerID] = {};
	end
	PredictionsForDumping[ContainerID][#PredictionsForDumping[ContainerID] + 1] = value;
end

--[[function stringTable(table,name,spacer)
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		elseif type(i) == "function" then

		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. i .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end--]]

local function TableEqual(o1, o2)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or TableEqual(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

local function shuffle(t)
  local n = #t
  while n > 1 do 
    local k = math.random(n)
    t[n], t[k] = t[k], t[n]
    n = n - 1
 end
 return t
end

local function InventoryIter(t)
	local iterator = nil;
	if #t > 0 then
		for k,i in ipairs(t) do
			iterator = ipairs(t);
			return function()
				return iterator();
			end
		end
		iterator = pairs(t);
		return function()
			return iterator();
		end
	end
	return nil;
end

local function GetIndexType(t)
	if #t > 0 then
		for k,i in ipairs(t) do
			return "number";
		end
		return "string";
	end
	return "number";
end

local function FindSlot(prediction,inventory,ContainerSize,converter,ReduceCount)
	ReduceCount = ReduceCount or false;
	if converter == nil then
		if GetIndexType(inventory) == "number" then
			converter = function(v) return v end;
		else
			converter = function(v) return tostring(v) end;
		end
	end
	if prediction.InsertSlots[1] == "any" then
		for i=1,ContainerSize do
			local Slot = converter(i);
			-- and inventory[Slot].count + prediction.Item.count <= prediction.MaxStack
			--if inventory[Slot] == nil or (inventory[Slot].name == prediction.Item.name and TableEqual(inventory[Slot].parameters,prediction.Item.parameters)) then
			if inventory[Slot] == nil or root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
				if ReduceCount == true then
					if inventory[Slot] == nil then
						--sb.logInfo("Slot of" .. Slot .. " is NIL");
						return i,prediction.Item.count;
					end
					if inventory[Slot].count ~= prediction.MaxStack then
						local NewCount = prediction.Item.count;
						--sb.logInfo("InventoryCount = " .. inventory[Slot].count);
						--sb.logInfo("PredictionItem = " .. prediction.Item.count);
						if inventory[Slot].count + prediction.Item.count > prediction.MaxStack then
							NewCount = NewCount - (NewCount + inventory[Slot].count - prediction.MaxStack);
						end
						--sb.logInfo("Final Count = " .. NewCount);
						--sb.logInfo("Count is adjusted to " .. NewCount .. " and slot is " .. Slot);
						return i,NewCount;
					end
				else
					if inventory[Slot] == nil or inventory[Slot].count + prediction.Item.count <= prediction.MaxStack then
						return i;
					end
				end
			end
		end
	else
		for k,i in ipairs(prediction.InsertSlots) do
			local Slot = converter(i);
			--[[if inventory[Slot] == nil or (inventory[Slot].name == predictions[i].Item.name and TableEqual(inventory[Slot].parameters,predictions[i].Item.parameters) and inventory[Slot].count + predictions[i].Item.count <= predictions[i].MaxStack) then
				return i;
			end--]]
			--if inventory[Slot] == nil or (inventory[Slot].name == prediction.Item.name and TableEqual(inventory[Slot].parameters,prediction.Item.parameters)) then
			if inventory[Slot] == nil or root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
				if ReduceCount == true then
					if inventory[Slot] == nil then
						--sb.logInfo("Slot of" .. Slot .. " is NIL");
						return i,prediction.Item.count;
					end
					if inventory[Slot].count ~= prediction.MaxStack then
						local NewCount = prediction.Item.count;
						--sb.logInfo("InventoryCount = " .. inventory[Slot].count);
						--sb.logInfo("PredictionItem = " .. prediction.Item.count);
						if inventory[Slot].count + prediction.Item.count > prediction.MaxStack then
							NewCount = NewCount - (NewCount + inventory[Slot].count - prediction.MaxStack);
						end
						--sb.logInfo("Final Count = " .. NewCount);
						--sb.logInfo("Count is adjusted to " .. NewCount .. " and slot is " .. Slot);
						return i,NewCount;
					end
				else
					if inventory[Slot] == nil or inventory[Slot].count + prediction.Item.count <= prediction.MaxStack then
						return i;
					end
				end
			end
		end
	end
end

local function BuildPrediction(prediction,Predictions,inventory,converter,ContainerSize)
	local Slot = converter(prediction.Slot);
	--if inventory[Slot].name == prediction.Item.name and TableEqual(inventory[Slot].parameters,prediction.Item.parameters) == true then
	if root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
		--sb.logInfo("NAME SAME");
		local OriginalCount = prediction.Item.count;
		--sb.logInfo("1COUNT  INVENTORY = " .. inventory[Slot].count);
		--sb.logInfo("1COUNT  MAXSTACK = " .. prediction.MaxStack);
		if inventory[Slot].count == prediction.MaxStack then
			--sb.logInfo("NEWSLOT1");
			--FIND NEW SLOT FOR PREDICTION
			local NewSlot = FindSlot(prediction,inventory,ContainerSize,converter);
			if NewSlot ~= nil then
				prediction.Slot = NewSlot;
				inventory[converter(NewSlot)] = prediction.Item;
			else
				prediction.Dumping = true;
				AddToDump(prediction.Container,prediction);
			end
		else
			--sb.logInfo("INV COUNT NOT MAXSTACK");
			--sb.logInfo("Prediction Count = " .. prediction.Item.count);
			prediction.Item.count = prediction.Item.count - (prediction.Item.count + inventory[Slot].count - prediction.MaxStack);
			inventory[Slot].count = prediction.MaxStack;
			local Leftover = OriginalCount - prediction.Item.count;
			local NewPrediction = {Item = {name = prediction.Item.name, count = Leftover,parameters = prediction.Item.parameters},Slot = prediction.Slot,MaxStack = prediction.MaxStack,Container = prediction.Container,InsertSlots = prediction.InsertSlots,TraversalID = prediction.TraversalID};
			--GENERATE NEW PREDICTION WITH THE LEFTOVER AMOUNT AND FIND A SLOT FOR IT
			local NewSlot = FindSlot(NewPrediction,inventory,ContainerSize,converter);
			if NewSlot ~= nil then
				NewPrediction.Slot = NewSlot;
				--sb.logInfo("Adding Extension");
				Predictions[#Predictions + 1] = NewPrediction;
				inventory[converter(NewSlot)] = NewPrediction.Item;
			else
				NewPrediction.Dumping = true;
				AddToDump(NewPrediction.Container,NewPrediction);
			end
		end

	else
		--FIND NEW SLOT FOR PREDICTION
		local NewSlot = FindSlot(prediction,inventory,ContainerSize,converter);
		if NewSlot ~= nil then
			prediction.Slot = NewSlot;
			inventory[converter(NewSlot)] = prediction.Item;
		else
			prediction.Dumping = true;
			AddToDump(prediction.Container,prediction);
		end
	end
end

function ContainerCount()
	if Cables.CableTypes.Containers ~= nil then
		return #Cables.CableTypes.Containers;
	end
	return 0;
end

--local function ItemEquals

--WHAT EACH PREDICTION WILL CONTAIN
--local NewPrediction = {Item = nil,Slot = nil,MaxStack = nil,Container = nil,InsertSlots = nil,TraversalID = nil};

--[[local function SlotIterator(InsertSlots,ContainerSize)
	
end--]]

local function CombinePredictions(inventory,predictions,ContainerSize)
	if inventory == nil then return nil end;
	--sb.logInfo(stringTable(inventory,"THE INVENTORY"));
	--TODO
	local converter;
	if GetIndexType(inventory) == "string" then
		converter = function(v) return tostring(v) end;
	else
		converter = function(v) return v end;
	end
	local Size = #predictions;
	for i=1,Size do
		local Slot = converter(predictions[i].Slot);
		--if inventory[Slot] == nil or (inventory[Slot].name == predictions[i].Item.name and TableEqual(inventory[Slot].parameters,predictions[i].Item.parameters) and inventory[Slot].count + predictions[i].Item.count <= predictions[i].MaxStack) then
		if inventory[Slot] == nil or (root.itemDescriptorsMatch(inventory[Slot],predictions[i].Item,true) and inventory[Slot].count + predictions[i].Item.count <= predictions[i].MaxStack) then
			--sb.logInfo("Success");
			if inventory[Slot] == nil then
				--sb.logInfo("Setting Inventory Slot " .. Slot .. " to (Name = " .. predictions[i].Item.name .. ", count = " .. predictions[i].Item.count .. ")");
				--predictions[i].Item;
				inventory[Slot] = {name = predictions[i].Item.name, count = predictions[i].Item.count, parameters = predictions[i].Item.parameters};
			else
				--sb.logInfo("Adding Inventory Slot " .. Slot .. " with count of " .. predictions[i].Item.count .. " to " .. inventory[Slot].count);
				inventory[Slot].count = inventory[Slot].count + predictions[i].Item.count;
			end
		else
			--sb.logInfo("inventorySlot = " .. inventory[Slot].count);
			--sb.logInfo("Predictions = " .. predictions[i].Item.count);
			--sb.logInfo("Size = " .. (inventory[Slot].count + predictions[i].Item.count));
			--sb.logInfo("BUILDING");
			BuildPrediction(predictions[i],predictions,inventory,converter,ContainerSize);
		end
	end
	for i=#predictions,1,-1 do
		if predictions[i].Dumping == true then
			table.remove(predictions,i);
		end
	end
end

local function RandomIter(t)
	local indexTable = {};
	for i=1,#t do
		indexTable[i] = i;
	end
	indexTable = shuffle(indexTable);
	local n = 0;
	return function()
		n = n + 1;
		return indexTable[n],t[indexTable[n]];
	end
end

local function ChangeTransferID(_,_,From,To)
	for m,n in pairs(Predictions) do
		for x=1,#n do
			if n[x].TraversalID == From then
				n[x].TraversalID = To;
			end
		end
	end
	for m,n in pairs(PredictionsForDumping) do
		for x=1,#n do
			if n[x].TraversalID == From then
				n[x].TraversalID = To;
			end
		end
	end
end

local function AddHandlers()
	message.setHandler("SetInsertID",function(_,_,id)
		InsertID = id;
		object.setConfigParameter("insertID",id);
	end);
	message.setHandler("ExtractAndSend",ExtractAndSend);
	message.setHandler("RemoveConduit",function(_,_,ContainerID,ID) RemoveConduit(ContainerID,ID) end);
	message.setHandler("SetMaster",function(_,_,ContainerID,NewMaster,predictions,dump) SetMaster(ContainerID,NewMaster,predictions,dump) end);
	message.setHandler("AddToInventory",AddToInventory);
	message.setHandler("DropItems",DropItems);
	message.setHandler("ChangeTransferID",ChangeTransferID);
end

local function RemapSide(OldID,NewID)
	if OldID == NewID then return nil end;
	for k,i in pairs(Predictions) do
		if tonumber(k) == OldID then
			Predictions[tostring(NewID)] = Predictions[k];
			Predictions[k] = nil;
			--sb.logInfo("Remapped " .. k .. " to : " .. NewID);
			return nil;
		end
	end
end

--local FirstUpdate = false;

local function UpdateContainerConduits()
	--sb.logInfo("Containers = " .. sb.print(Cables.CableTypes.Containers));
	--sb.logInfo("CableTypes = " .. sb.print(Cables.CableTypes));
	--[[if FirstUpdate == false then
		FirstUpdate = true;
		local PreviousSideMap = config.getParameter("PreviousSideMap");
		if PreviousSideMap ~= nil then
			for k,i in ipairs(PreviousSideMap) do
				RemapSide(i,Cables.CableTypes.Containers[k]);
			end
		end
	end--]]
	if Ready == true then
		object.setConfigParameter("PreviousSideMap",Cables.CableTypes.Containers);
	--sb.logInfo("Updating");
	--if Cables.CableTypes.Containers ~= nil then
		for i=1,4 do
			if InsertController[i].IsMaster == nil then
				if Cables.CableTypes.Containers ~= nil and Cables.CableTypes.Containers[i] ~= -10 then
					InsertController[i].Container = Cables.CableTypes.Containers[i];
					InsertController[i].Conduits = InsertConduitsAtContainer(InsertController[i].Container);
					if #InsertController[i].Conduits == 0 then
						InsertController[i].IsMaster = true;
					else
						InsertController[i].IsMaster = false;
						for j=1,#InsertController[i].Conduits do
							if world.entityExists(InsertController[i].Conduits[j]) == true then
								world.callScriptedEntity(InsertController[i].Conduits[j],"AddConduit",InsertController[i].Container,EntityID);
								if world.callScriptedEntity(InsertController[i].Conduits[j],"IsMaster",InsertController[i].Container) == true then
									InsertController[i].Master = InsertController[i].Conduits[j];
								end
							end
						end
						if InsertController[i].Master == nil then
							InsertController[i].IsMaster = true;
						end
					end
				end
			else
				if Cables.CableTypes.Containers == nil or Cables.CableTypes.Containers[i] == -10 then
					InsertController[i] = {};
				end
			end
		end
	end
end

local function GetContainerConduits()
	if Cables.CableTypes["Containers"] ~= nil then
		for i=1,4 do
			if Cables.CableTypes.Containers[i] ~= -10 then
				InsertController[i].Container = Cables.CableTypes.Containers[i];
				InsertController[i].Conduits = InsertConduitsAtContainer(InsertController[i].Container);
				--sb.logInfo("Conduits = " .. #InsertController[i].Conduits);
				if #InsertController[i].Conduits == 0 then
					InsertController[i].IsMaster = true;
				else
					InsertController[i].IsMaster = false;
					for j=1,#InsertController[i].Conduits do
						--world.callScriptedEntity(InsertController[i].Conduits[j],"AddConduit",InsertController[i].Container,EntityID);
						world.callScriptedEntity(InsertController[i].Conduits[j],"AddConduit",InsertController[i].Container,EntityID);
						if world.callScriptedEntity(InsertController[i].Conduits[j],"IsMaster",InsertController[i].Container) == true then
							InsertController[i].Master = InsertController[i].Conduits[j];
							--break;
						end
					end
					if InsertController[i].Master == nil then
						InsertController[i].IsMaster = true;
					end
				end
			end
		end
	end
	ControllerFilled = true;
	--sb.logInfo(stringTable(InsertController,"InsertController for after function : " .. EntityID));
end

function IsMaster(Container)
	for i=1,4 do
		if InsertController[i].Container == Container then
			return InsertController[i].IsMaster;
		end
	end
	return false;
end

function AddConduit(Container,ID)
	--sb.logInfo("Adding Conduit " .. ID .. " To Container " .. Container .. " at : " .. entity.id());
	--sb.logInfo(stringTable(InsertController,"InsertController for in add : " .. EntityID));
	if ID == EntityID then return nil end;
	--[[if Cables.Initalized == false then
		sb.logInfo("NOT INITALIZED");
		return nil;
	else
		sb.logInfo("IS INITALIZED");
	end--]]
	for i=1,#InsertController do
		if InsertController[i].Container == Container then
			local Added = false;
			for j=1,#InsertController[i].Conduits do
				if InsertController[i].Conduits[j] == ID then
					Added = true;
					break;
				end
			end
			if Added == false then
				InsertController[i].Conduits[#InsertController[i].Conduits + 1] = ID;
			end
			--sb.logInfo(stringTable(InsertController,"InsertController after Addition : " .. EntityID));
			return nil;
		end
	end
	--sb.logInfo("Adding Conduit " .. ID .. " To Container " .. Container .. " at : " .. entity.id());
	--[[for i=1,#InsertController do
		if InsertController[i].Container == Container then
			for j=1,InsertController[i].Conduits[j] do
				if InsertController[i].Conduits[j] == ID then
					table.remove(InsertController[i].Conduits,j);
					break;
				end
			end
			break;
		end
	end--]]
end

function RemoveConduit(Container,ID)
	--sb.logInfo("Removing Conduit " .. ID .. " From Container " .. Container .. " at : " .. entity.id());
	--sb.logInfo(stringTable(InsertController,"InsertController for in remove : " .. EntityID));
	if ID == EntityID then return nil end;
	--[[if Cables.Initalized == false then
		sb.logInfo("NOT INITALIZED");
		return nil;
	else
		sb.logInfo("IS INITALIZED");
	end--]]
	for i=1,#InsertController do
		if InsertController[i].Container == Container then
			for j=1,#InsertController[i].Conduits do
				if InsertController[i].Conduits[j] == ID then
					table.remove(InsertController[i].Conduits,j);
					--sb.logInfo(stringTable(InsertController,"InsertController after removal : " .. EntityID));
					return nil;
				end
			end
			return nil;
		end
	end
end

function SetMaster(Container,ID,AllPredictions,AllDump)
	--[[if Cables.Initalized == false then
		sb.logInfo("NOT INITALIZED");
		return nil;
	else
		sb.logInfo("IS INITALIZED");
	end--]]
	for i=1,#InsertController do
		if InsertController[i].Container == Container then
			if ID == entity.id() then
				InsertController[i].IsMaster = true;
				InsertController[i].Master = nil;
			else
				InsertController[i].Master = ID;
			end
			Predictions = AllPredictions;
			PredictionsForDumping = AllDump;
			object.setConfigParameter("Predictions",Predictions);
			object.setConfigParameter("Dump",PredictionsForDumping);
			return nil;
		end
	end
end

local oldinit = init;
function init()
	--sb.logInfo("Insertion Conduit INIT");
	if oldinit ~= nil then
		oldinit();
	end
	ControllerFilled = false;
	--sb.logInfo("Insert Initialized");
	Cables = CableCore;
	Colors = {};
	Predictions = config.getParameter("Predictions",{});
	PredictionsForDumping = config.getParameter("Dump",{});
	--sb.logInfo(stringTable(root.assetJson("/Projectiles/Traversals/Colors.json").Colors,"COLORS"));
	for k,i in ipairs(root.assetJson("/Projectiles/Traversals/Colors.json").Colors) do
		Colors[i[1]] = i[2];
	end
	--Colors = root.assetJson("/Projectiles/Traversals/Colors.json").Colors;
	AddHandlers();
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddCondition("Containers","objectType",function(value) return value == "container" end);
	Cables.AddAfterFunction(UpdateContainerConduits);
	EntityID = entity.id();
	Cables.Initialize();
	InsertID = config.getParameter("insertID");
	if InsertID == nil then
		InsertID = "";
		object.setConfigParameter("insertID",InsertID);
	end
	--InsertID = config.getParameter("insertID"," ");
end

--[[if Updates == nil then
	Updates = {};
end--]]
local Loaded = false;
local First = false;
local oldupdate = update;
local EntityPos = nil;
local RegionRect = nil;
function update(dt)
	if oldupdate ~= nil then
		oldupdate();
	end
	Cables.Update();
	if First == false then
		First = true;
		EntityPos = entity.position();
		RegionRect = {EntityPos[1] - 5,EntityPos[2] - 5,EntityPos[1] + 5,EntityPos[2] + 5};
	end
	if Loaded == false then
		if world.regionActive(RegionRect) == true then
			Loaded = true;
			local PreviousSideMap = config.getParameter("PreviousSideMap");
			if PreviousSideMap ~= nil then
				for k,i in ipairs(PreviousSideMap) do
					RemapSide(i,Cables.CableTypes.Containers[k]);
				end
			end
			AddAllItems();
			--sb.logInfo("READY");
			Ready = true;
		end
	end
end
local Calculating = false;
ExtractAndSend = function(_,_,Item,Slot,Container,Path,InsertIntoSides,InsertIntoSlots,insertContainer,Color,Speed,PossibleInsertConduits)
	if Calculating == true then return nil end;
	Calculating = true;
	if Ready == false then Calculating = false; return nil end;
	--sb.logInfo("Extracting");
	if ControllerFilled == false then
		GetContainerConduits();
		--sb.logInfo();
	end
	local InsertContainer = insertContainer;
	if InsertContainer == nil then
		for k,i in RandomIter(InsertIntoSides) do
			if Cables.CableTypes.Containers ~= nil then
				if i == "right" then
					if Cables.CableTypes.Containers[4] > 0 then
						InsertContainer = Cables.CableTypes.Containers[4];
						break;
					end
				elseif i == "down" then
					if Cables.CableTypes.Containers[2] > 0 then
						InsertContainer = Cables.CableTypes.Containers[2];
						break;
					end
				elseif i == "left" then
					if Cables.CableTypes.Containers[3] > 0 then
						InsertContainer = Cables.CableTypes.Containers[3];
						break;
					end
				elseif i == "up" then
					if Cables.CableTypes.Containers[1] > 0 then
						InsertContainer = Cables.CableTypes.Containers[1];
						break;
					end
				end
			end
		end
	end
	local ControllerIndex;
	--sb.logInfo("InsertContainer = " .. InsertContainer);
	--sb.logInfo("Controller = " .. sb.print(InsertController));
	if InsertContainer ~= nil and world.entityExists(InsertContainer) == true then
		for i=1,4 do
			if InsertController[i].Container == InsertContainer then
				if InsertController[i].IsMaster == true then
					--sb.logInfo("Setting INDEXER to " .. i);
					ControllerIndex = i;
					--sb.logInfo(entity.id() .. " Is Master");
					break;
				else
					--sb.logInfo(entity.id() .. " is Sending To Master");
					Calculating = false;
					world.sendEntityMessage(InsertController[i].Master,"ExtractAndSend",Item,Slot,Container,Path,InsertIntoSides,InsertIntoSlots,InsertContainer,Color,Speed,PossibleInsertConduits);
					return nil;
				end
			end
		end
		--TODO
		if ControllerIndex == nil then Calculating = false; return nil end;
		local ContainerPredictions = GetPredictionGroup(InsertContainer);
		local ContainerSize = world.containerSize(InsertContainer);
		local Inventory = world.containerItems(InsertContainer);
		if Inventory == nil then Calculating = false; return nil end;
		CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
		--object.setConfigParameter("Predictions",Predictions);
		object.setConfigParameter("Dump",PredictionsForDumping);
		--sb.logInfo(stringTable(Inventory,"FINAL INVENTORY"));
		local NewPrediction = {Item = Item,Container = InsertContainer,InsertSlots = InsertIntoSlots,MaxStack = root.itemConfig(Item).config.maxStack or 1000};
		local NewSlot,Count = FindSlot(NewPrediction,Inventory,ContainerSize,nil,true);
		if NewSlot ~= nil then
			NewPrediction.Slot = NewSlot;
			NewPrediction.Item.count = Count;
			--sb.logInfo(stringTable(NewPrediction.Item,"FINAL ITEM"));
			--sb.logInfo(stringTable(Path,"Path"));
			--sb.logInfo(stringTable(InsertController,"CONTROLLER4"));
			NewPrediction.TraversalID = world.spawnProjectile("traversal" .. Colors[Color],vecAdd(world.entityPosition(Path[#Path]),{0.5,0.5}),entity.id());
			local AllConduits = nil;
			if PossibleInsertConduits == "any" then
				--sb.logInfo("IS ANY");
				--sb.logInfo("ControllerIndex = " .. ControllerIndex);
				sb.logInfo(sb.print(InsertController[ControllerIndex]));
				AllConduits = {};
				for k,i in ipairs(InsertController[ControllerIndex].Conduits) do
					AllConduits[#AllConduits + 1] = i;
				end
				AllConduits[#AllConduits + 1] = EntityID;
			else
				AllConduits = {};	
				--sb.logInfo("IS NOT ANY");
				--sb.logInfo(stringTable(PossibleInsertConduits,"PrePossibilities"));
				for k,i in ipairs(InsertController[ControllerIndex].Conduits) do
					--if i ~= EntityID then
						local IID = world.getObjectParameter(i,"insertID");
						for j=1,#PossibleInsertConduits do
							if PossibleInsertConduits[j] == IID then
								AllConduits[#AllConduits + 1] = i;
								break;
							end
						end
					--end
				end
				for j=1,#PossibleInsertConduits do
					if PossibleInsertConduits[j] == InsertID then
						AllConduits[#AllConduits + 1] = EntityID;
					end
				end
			end
			if world.entityExists(NewPrediction.TraversalID) == true and world.containerConsumeAt(Container,Slot - 1,Count) == true then
				--sb.logInfo("Adding Prediction of = " .. sb.printJson(NewPrediction,1));
				AddPredictionAndSend(NewPrediction);
				world.callScriptedEntity(NewPrediction.TraversalID,"StartTraversing",Path,AllConduits,Speed,InsertContainer);
			end
		end
		object.setConfigParameter("Predictions",Predictions);
	end
	Calculating = false;
end

AddToInventory = function(_,_,TraversalID,ContainerID)
	--sb.logInfo("STARTINGDROP");
	--sb.logInfo("ContainerID = " .. ContainerID);
	for i=1,4 do
		if InsertController[i].Container == ContainerID then
			--sb.logInfo(stringTable(InsertController[i],"Controller"));
			if InsertController[i].IsMaster == true then
				break;
			else
				--sb.logInfo("Master = " .. InsertController[i].Master);
				world.sendEntityMessage(InsertController[i].Master,"AddToInventory",TraversalID,ContainerID);
				return nil;
			end
		end
	end
	local ContainerPredictions = GetPredictionGroup(ContainerID);
	local ContainerSize = world.containerSize(ContainerID);
	local Inventory = world.containerItems(ContainerID);
	CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
	local Position = entity.position();
	local Exists = world.entityExists(ContainerID);
	for i=#ContainerPredictions,1,-1 do
		if ContainerPredictions[i].TraversalID == TraversalID then
			if Exists == true then
				world.containerPutItemsAt(ContainerID,ContainerPredictions[i].Item,ContainerPredictions[i].Slot - 1);
			else
				world.spawnItem(ContainerPredictions[i].Item,Position,ContainerPredictions[i].Item.count,ContainerPredictions[i].Item.parameters);
			end
			table.remove(ContainerPredictions,i);
		end
	end
	local dump = GetDump(ContainerID);
	for i=#dump,1,-1 do
		if dump[i].TraversalID == TraversalID then
			world.spawnItem(dump[i].Item,Position,dump[i].Item.count,dump[i].Item.parameters);
			table.remove(dump,i);
		end
	end
	object.setConfigParameter("Predictions",Predictions);
	object.setConfigParameter("Dump",PredictionsForDumping);
end

DropItems = function(_,_,TraversalID,ContainerID,Position)
	for i=1,4 do
		if InsertController[i].Container == ContainerID then
			if InsertController[i].IsMaster == true then
				break;
			else
				world.sendEntityMessage(InsertController[i].Master,"DropItems",TraversalID,ContainerID,Position);
				return nil;
			end
		end
	end
	local ContainerPredictions = GetPredictionGroup(ContainerID);
	local ContainerSize = world.containerSize(ContainerID);
	local Inventory = world.containerItems(ContainerID);
	CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
	for i=#ContainerPredictions,1,-1 do
		if ContainerPredictions[i].TraversalID == TraversalID then
			world.spawnItem(ContainerPredictions[i].Item,Position,ContainerPredictions[i].Item.count,ContainerPredictions[i].Item.parameters);
			table.remove(ContainerPredictions,i);
		end
	end
	local dump = GetDump(ContainerID);
	for i=#dump,1,-1 do
		if dump[i].TraversalID == TraversalID then
			world.spawnItem(dump[i].Item,Position,dump[i].Item.count,dump[i].Item.parameters);
			table.remove(dump,i);
		end
	end
	object.setConfigParameter("Predictions",Predictions);
	object.setConfigParameter("Dump",PredictionsForDumping);
end

AddAllItems = function()
	--sb.logInfo("Adding All Items");
	local Position = entity.position();
	--sb.logInfo("PREDICTIONS = " .. sb.print(Predictions));
	for k,i in pairs(Predictions) do
		local Container = tonumber(k);
		for x=#i,1,-1 do
			if world.entityExists(Container) == true then
				world.containerPutItemsAt(Container,i[x].Item,i[x].Slot - 1);
			else
				sb.logInfo("Doesn't Exist, so dumping" .. sb.print(i[x].Item));
				world.spawnItem(i[x].Item,Position,i[x].Item.count,i[x].Item.parameters);
			end
		end
	end
	Predictions = {};
	object.setConfigParameter("Predictions",Predictions);
	for k,i in pairs(PredictionsForDumping) do
		for x=#i,1,-1 do
			world.spawnItem(i[x].Item,Position,i[x].Item.count,i[x].Item.parameters);
		end
	end
	PredictionsForDumping = {};
	object.setConfigParameter("Dump",PredictionsForDumping);
end

InsertConduitsAtContainer = function(ContainerID)
	local Conduits = {};
	local XTop,YTop,XLow,YLow = nil,nil,nil,nil;
	local entityPos = world.entityPosition(ContainerID);
	for k,i in ipairs(world.objectSpaces(ContainerID)) do
		if XTop == nil then
			XTop = i[1];
		elseif i[1] > XTop then
			XTop = i[1];
		end
		if XLow == nil then
			XLow = i[1];
		elseif i[1] < XLow then
			XLow = i[1];
		end
		if YTop == nil then
			YTop = i[1];
		elseif i[1] > YTop then
			YTop = i[1];
		end
		if YLow == nil then
			YLow = i[1];
		elseif i[1] < YLow then
			YLow = i[1];
		end
	end
	for k,i in ipairs(world.objectQuery({XLow - 1 + entityPos[1],YLow - 1 + entityPos[2]},{XTop + 1 + entityPos[1],YTop + 1 + entityPos[2]})) do
		--sb.logInfo("ID = " .. i);
		if i ~= EntityID and world.getObjectParameter(i,"insertID") ~= nil and world.callScriptedEntity(i,"IsConnectedTo",ContainerID) == true then
			Conduits[#Conduits + 1] = i;
		end
	end
	return Conduits;
end
local Dying = false;
function die()
	Cables.UpdateOthers();
	Dying = true;
end

--[[function uninit()
	sb.logInfo("Old UNINIT");
end--]]

function uninit()
	--sb.logInfo("UNINIT");
	--sb.logInfo("Insertion Conduit UNINIT");
	for i=1,4 do
		if InsertController[i].Conduits ~= nil then
			local NewMaster = nil;
			if InsertController[i].IsMaster == true then
				if #InsertController[i].Conduits > 0 then
					NewMaster = InsertController[i].Conduits[1];
				end
			end
			local MasterSet = false;
			for j=1,#InsertController[i].Conduits do
				if InsertController[i].Conduits[j] ~= nil then
					if NewMaster ~= nil then
						--sb.logInfo("BEFORE 1");
						if world.entityExists(InsertController[i].Conduits[j]) == true then
							MasterSet = true;
							world.sendEntityMessage(InsertController[i].Conduits[j],"SetMaster",InsertController[i].Container,NewMaster,Predictions,PredictionsForDumping);
							object.setConfigParameter("Predictions",nil);
							object.setConfigParameter("PredictionsForDumping",nil);
						end
						--sb.logInfo("AFTER 1");
					end
					--sb.logInfo("BEFORE 2");
					if world.entityExists(InsertController[i].Conduits[j]) == true then
						world.sendEntityMessage(InsertController[i].Conduits[j],"RemoveConduit",InsertController[i].Container,EntityID);
					end
					--sb.logInfo("After 2");
				end
			end
			if NewMaster ~= nil and Dying == true then
				for m,n in pairs(Predictions) do
					for x=1,#n do
						--sb.logInfo("BEFORE 3");
						if world.entityExists(n[x].TraversalID) == true then
							world.sendEntityMessage(n[x].TraversalID,"SetSource",NewMaster);
						end
						--sb.logInfo("After 3");
					end
				end
			end
			if MasterSet == false and Dying == true then
				for m,n in pairs(Predictions) do
					for x=1,#n do
						--sb.logInfo("BEFORE 4");
						if world.entityExists(n[x].TraversalID) == true then
							world.sendEntityMessage(n[x].TraversalID,"AddItemToDrop",n[x].Item);
						end
						--sb.logInfo("After 4");
					end
				end
			end
		end
	end
end
