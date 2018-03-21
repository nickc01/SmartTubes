require("/Core/Groups.lua");
require("/Core/ContainerHelper.lua");

--Definition

--Public Table
Insertion = {};
local Insertion = Insertion;
--Private Table, PLEASE DONT TOUCH
__Insertion__ = {};
local __Insertion__ = __Insertion__;

--Variables
local SourceID;
local SourcePosition;
local Predictions = setmetatable({},{
	__index = function(tbl,k)
		if type(k) == "number" then
			return rawget(tbl,tostring(k));
		else
			return rawget(tbl,k);
		end
	end,
	__newindex = function(tbl,k,value)
		if type(k) == "number" then
			return rawset(tbl,tostring(k),value);
		else
			return rawset(tbl,k,value);
		end
	end});
local PredictionsForTossing = setmetatable({},{
	__index = function(tbl,k)
		if type(k) == "number" then
			return rawget(tbl,tostring(k));
		else
			return rawget(tbl,k);
		end
	end,
	__newindex = function(tbl,k,value)
		if type(k) == "number" then
			return rawset(tbl,tostring(k),value);
		else
			return rawset(tbl,k,value);
		end
	end});
local AnyNumTable = setmetatable({},{
	__index = function(_,k)
		return k;
	end});
local ConfigCache = setmetatable({}, { __mode = 'v' });

--Prediction Layout
--Item
--Slot
--MaxStack
--Traversal
--PossibleSlots
--

--Functions
local SetMessages;
local GroupUpdate;
local GroupAdd;
local GroupRemove;
local GroupMasterChange;
local GetInventoryWithPredictions;
local RecalculatePrediction;
local AddPrediction;
local RemovePrediction;
local AddPredictionForTossing;
local RemovePredictionForTossing;
local PredictionIter;
local PossibleSlotIter;

--TODO TODO TODO ---- Get Prediction System Working

--Initializes the Insertion Conduit
function Insertion.Initialize()
--	object.say("THIS IS A TEST");
	SourcePosition = entity.position();
	SourceID = entity.id();
	Groups.Initialize();
	Groups.AddGroupAdditionFunction(GroupAdd);
	Groups.AddGroupRemovalFunction(GroupRemove);
	Groups.AddGroupMasterChangeFunction(GroupMasterChange);
	ConduitCore.UpdateContinuously(true);
	ConduitCore.AddConnectionType("Containers",function(ID) return ContainerHelper.IsContainer(ID) end);
	Groups.OnUpdateFunction(GroupUpdate);
	ConduitCore.Initialize();
	SetMessages();
end

--Gets the ID of the Insertion Conduit
function Insertion.GetID()
	return SourceID;
end

--Called when the groups update
GroupUpdate = function()
	--[[for Object,Connections,Master,k in Groups.GroupIterator() do
		
	end--]]
end

--Called when a group is added
GroupAdd = function(Object,Connections,Master)
	--Add a prediction setup for the object
	--sb.logInfo("Adding Group");
	if Master == SourceID then
		Predictions[Object] = {};
		PredictionsForTossing[Object] = {};
	end
end

--Called when a group is removed
GroupRemove = function(Object,Connections,OldMaster,NewMaster)
	sb.logInfo("Removing Group");
	sb.logInfo("Object = " .. sb.print(Object));
	sb.logInfo("Connections = " .. sb.print(Connections));
	sb.logInfo("OldMaster = " .. sb.print(OldMaster));
	sb.logInfo("New Master = " .. sb.print(NewMaster));
	sb.logInfo("SourceID = " .. sb.print(SourceID));
	--If this entity is the master
	if OldMaster == SourceID then
		sb.logInfo(sb.print(SourceID) .. " was the original Master");
		--If no new master exists
		sb.logInfo("New Master = " .. sb.print(NewMaster));
		if NewMaster == nil then
			--Delete all the predictions for the object
			sb.logInfo("Deleting all predictions");
			Predictions[Object] = {};
			PredictionsForTossing[Object] = {};
		else
			--Send the predictions to the new master
			sb.logInfo("Sending the predictions to the new master");
			sb.logInfo("Predictions to send = " .. sb.print(Predictions[Object]));
			world.callScriptedEntity(Groups.GetMasterID(Object),"__Insertion__.SetPredictions",Object,Predictions[Object],PredictionsForTossing[Object]);
			Predictions[Object] = {};
			PredictionsForTossing[Object] = {};
		end
	end
end

--Called when a group's master is changed
GroupMasterChange = function(Object,OldMaster,NewMaster)
	--if this entity was the original master
	if OldMaster == SourceID then
		sb.logInfo("Sending Predictions to new Master");
		--Move The Predictions to the new master
		world.callScriptedEntity(NewMaster,"__Insertion__.SetPredictions",Object,Predictions[Object],PredictionsForTossing[Object]);
		Predictions[Object] = {};
		PredictionsForTossing[Object] = {};
	end
end

--
function __Insertion__.SetPredictions(Object,predictions,predictionsForTossing)
	sb.logInfo("Setting the predictions at " .. sb.print(SourceID) .. " to " .. sb.print(Predictions));
	Predictions[Object] = predictions;
	for k,i in ipairs(predictions) do
		if world.entityExists(i.Traversal) then
			world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",Insertion);
		end
	end
	PredictionsForTossing[Object] = predictionsForTossing;
	for k,i in ipairs(predictionsForTossing) do
		if world.entityExists(i.Traversal) then
			world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",Insertion);
		end
	end
end

--Sends a traversal and sends it to the destination
function Insertion.SendItem(Item,DestinationContainer,Slot,ExtractionID,PossibleSlots,TraversalColor)
	if not Insertion.IsConnectedTo(DestinationContainer) then
		error("This insertion Conduit is not connected to the Object : " .. sb.print(DestinationContainer));
	end
	TraversalColor = TraversalColor or "red";
	PossibleSlots = PossibleSlots or "any";
	local StartPosition = world.entityPosition(ExtractionID);
	local Traversal = world.spawnProjectile("traversal" .. TraversalColor,{StartPosition[1] + 0.5,StartPosition[2] + 0.5});
	world.callScriptedEntity(Traversal,"Traversal.Initialize",Insertion,DestinationContainer,"Conduits");
	if PossibleSlots == "any" then
		--Set Possible Slots to be all the slots in the container
		local ContainerSize = ContainerHelper.Size(DestinationContainer);
		PossibleSlots = setmetatable({},{
			__index = function(tbl,k)
				if k > 0 and k <= ContainerSize then
					return k;
				end
			end
		});
	end
	--Create the prediction for the item
	local Prediction = {Item = Item,Slot = Slot,MaxStack = Insertion.GetItemConfig(Item).config.maxstack or 1000,Traversal = Traversal,PossibleSlots = PossibleSlots};
	AddPrediction(DestinationContainer,Prediction);
	return true;
end

--Returns true if this insertion conduit is connected to the container
function Insertion.IsConnectedTo(Container)
	return Groups.IsConnectedTo(Container);
end

--Inserts the Traversals Items into the Container
function __Insertion__.InsertTraversalItems(Traversal)
	local Object = world.callScriptedEntity(Traversal,"Traversal.GetDestination");
	--Rescans all the predictions so they all fit
	GetInventoryWithPredictions(Object);
	local Predictions = world.callScriptedEntity(Traversal,"__Traversal__.GetPredictions");
	local PredictionsForTossing = world.callScriptedEntity(Traversal,"__Traversal__.GetPredictions",true);
	local Position = world.entityPosition(Traversal);
	--If Destination even exists
	if world.entityExists(Object) then
		for k,i in ipairs(Predictions) do
			--Add Item into the Container
			ContainerHelper.PutItemsAt(Object,i.Item,i.Slot - 1);
		end
	else
		for k,i in ipairs(Predictions) do
			--Drop Items on the group
			world.spawnItem(i.Item,Position);
		end
	end
	for k,i in ipairs(Predictions) do
		RemovePrediction(Object,i);
	end
	for k,i in ipairs(PredictionsForTossing) do
		world.spawnItem(i.Item,Position);
	end
	for k,i in ipairs(PredictionsForTossing) do
		RemovePredictionForTossing(Object,i);
	end
end

--Drops the Traversals Items
function __Insertion__.DropTraversalItems(Traversal)
	local Object = world.callScriptedEntity(Traversal,"Traversal.GetDestination");
	GetInventoryWithPredictions(Object);
	local Predictions = world.callScriptedEntity(Traversal,"__Traversal__.GetPredictions");
	local PredictionsForTossing = world.callScriptedEntity(Traversal,"__Traversal__.GetPredictions",true);
	local Position = world.entityPosition(Traversal);
	for k,i in ipairs(Predictions) do
		world.spawnItem(i.Item,Position);
	end
	for k,i in ipairs(PredictionsForTossing) do
		world.spawnItem(i.Item,Position);
	end
	for k,i in ipairs(Predictions) do
		RemovePrediction(Object,i);
	end
	for k,i in ipairs(PredictionsForTossing) do
		RemovePredictionForTossing(Object,i);
	end
end

--Checks if the item can fit in the Object
function Insertion.ItemCanFit(Object,Item,Slots,Exact)
	local Inventory = GetInventoryWithPredictions(Object);
	local MaxStack = Insertion.GetItemConfig(Item).config.maxStack or 1000;
	Exact = Exact or false;
	Slots = Slots or "any";
	for slot in SlotIter(Slots,ContainerHelper.Size(Object)) do
		if Inventory[slot] == nil then
			return Item,slot;
		elseif root.itemDescriptorsMatch(Inventory[slot],Item,true) then
			local RemainingCount = MaxStack - Inventory[slot].count;
			if Item.count <= RemainingCount then
				return Item,slot;
			else
				if RemainingCount > 0 and Exact == true then
					return {name = Item.name,count = RemainingCount,parameters = Item.parameters},slot;
				else
					goto Continue;
				end
			end
		end
		::Continue::
	end
	return nil;
end

--Gets the Master Prediction of the Object
function __Insertion__.GetMasterPredictions(Object,Tossing)
	Tossing = Tossing or false;
	local Master = Groups.GetMasterID(Object);
	if Master == SourceID then
		sb.logInfo(sb.print(SourceID) .. " is the master");
		if Tossing then
			return PredictionsForTossing;
		else
			return Predictions;
		end
	else
		return world.callScriptedEntity(Master,"__Insertion__.GetMasterPredictions",Object,Tossing);
	end
end

--Adds any messages for the object to call
SetMessages = function()
	
end

--Adds the prediction to the list and to the traversal's
AddPrediction = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object)[Object];
	Predictions[#Predictions + 1] = prediction;
	if world.entityExists(prediction.Traversal) then
		world.callScriptedEntity(prediction.Traversal,"__Traversal__.AddPrediction",prediction);
	end
end

--Removes the prediction from the list and from the traversal's
RemovePrediction = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object);
	for k,i in ipairs(Predictions[Object]) do
		if i == prediction then
			table.remove(Predictions[Object],k);
			if world.entityExists(prediction.Traversal) then
				world.callScriptedEntity(prediction.Traversal,"__Traversal__.RemovePrediction",prediction);
			end
			return nil;
		end
	end
end

--Adds the prediction to the list for tossing and to the traversal's
AddPredictionForTossing = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object,true)[Object];
	Predictions[#Predictions + 1] = prediction;
	if world.entityExists(prediction.Traversal) then
		world.callScriptedEntity(prediction.Traversal,"__Traversal__.AddPredictionForTossing",prediction);
	end
end

--Removes the prediction from the list for tossing and from the traversal's
RemovePredictionForTossing = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object,true);
	for k,i in ipairs(Predictions[Object]) do
		if i == prediction then
			table.remove(Predictions[Object],k);
			if world.entityExists(prediction.Traversal) then
				world.callScriptedEntity(prediction.Traversal,"__Traversal__.RemovePredictionForTossing",prediction);
			end
			return nil;
		end
	end
end

--Returns an iterator that iterates over the master predictions
PredictionIter = function(Object)
	local Predictions = __Insertion__.GetMasterPredictions(Object);
	if Predictions[Object] == nil then
		return function()
			return nil,nil;
		end
	else
		local k = #Predictions[Object];
		return function()
			if k == 0 then return nil,nil end;
			local Value = Predictions[Object][k];
			k = k - 1;
			return k + 1,Value;
		end
	end
end

--Returns an iterator of slots using the possible slots of the prediction
SlotIter = function(Slots,ContainerSize)
	local i = 0;
	if Slots == "any" then
		return function()
			i = i + 1;
			if i > ContainerSize then
				return nil;
			else
				return i;
			end
		end
	else
		return function()
			i = i + 1;
			if i > #Slots then
				return nil;
			else
				return Slots[i];
			end
		end
	end
end

--Attempts to find a new spot or spots for the Prediction
RecalculatePrediction = function(Inventory,Prediction,Object)
	--Remove the existing prediction
	RemovePrediction(Object,Prediction);
	local Count = Prediction.Item.count;
	local PostFunctions = setmetatable({},{
		__call = function(tbl)
			for _,func in ipairs(tbl) do
				func();
			end
		end});
	for _,slot in ipairs(Prediction.PossibleSlots) do
		if Inventory[slot] == nil then
			--If the Slot is empty
			--Add the item into the slot
			Inventory[slot] = {name = Prediction.Item.name,count = Count,parameters = Prediction.Item.parameters};
			Count = 0;
			PostFunctions[#PostFunctions + 1] = function() AddPrediction(Object,{Item = Inventory[slot],Slot = slot,MaxStack = Prediction.MaxStack,Traversal = Prediction.Traversal,PossibleSlots = Prediction.PossibleSlots}); end;
		elseif root.itemDescriptorsMatch(Inventory[slot],Prediction.Item,true) then
			--If the Slot is the same as the Item
			--Add the item into the slot
			local MaxCount = Prediction.MaxStack - Inventory[slot].count;
			if MaxCount > 0 then
				local ItemCount = Count;
				if ItemCount > MaxCount then
					Count = Count - (ItemCount - MaxCount);
					ItemCount = MaxCount;
				else
					Count = 0;
				end
				Inventory[slot].count = ItemCount;
				PostFunctions[#PostFunctions + 1] = function() AddPrediction(Object,{Item = Inventory[slot],Slot = slot,MaxStack = Prediction.MaxStack,Traversal = Prediction.Traversal,PossibleSlots = Prediction.PossibleSlots}); end;
			end
		end
		if Count == 0 then
			break;
		end
	end
	if Count > 0 then
		AddPredictionForTossing(Object,{Item = {name = Prediction.Item.name,count = Count,parameters = Prediction.Item.parameters},MaxStack = Prediction.MaxStack,Traversal = Prediction.Traversal,PossibleSlots = Prediction.PossibleSlots});
	end
	PostFunctions();
end

--Gets the Inventory of the object with it's predictions added to it
GetInventoryWithPredictions = function(Object)
	local Inventory = ContainerHelper.Items(Object);
	for k,prediction in PredictionIter(Object) do
		if Inventory[prediction.Slot] == nil then
			--If Slot doesn't have anything
			--Add the  item into the slot
			Inventory[prediction.Slot] = {name = prediction.Item.name,count = prediction.Item.count,parameters = prediction.Item.parameters};
		elseif root.itemDescriptorsMatch(Inventory[prediction.Slot],prediction.Item,true) then
			--If Inventory Item matches the prediction item
			if Inventory[prediction.Slot].count + prediction.Item.count > prediction.MaxStack then
				--If the Item can't fit inside the slot
				--Find a new slot for the prediction item to fit in
				--If it can't find one then remove the prediction and distribute it across all possible slots,
				--any leftovers will be added to the tossed predictions
				RecalculatePrediction(Inventory,prediction,Object);
			else
				--Add the predictions to the Inventory Slot
				Inventory[prediction.Slot].count = Inventory[prediction.Slot].count + prediction.Item.count;
			end
		else
			--If Slot is occupied with a different item
			--Find a new slot for the prediction item to fit in
			--If it can't find one then remove the prediction and distribute it across all possible slots,
			--any leftovers will be added to the tossed predictions
			RecalculatePrediction(Inventory,prediction,Object);
		end
	end
	return Inventory;
end

--Gets the Config of the Item
function Insertion.GetItemConfig(Item)
	if ConfigCache[Item.name] ~= nil then
		return ConfigCache[Item.name];
	else
		local Config = root.itemConfig(Item);
		ConfigCache[Item.name] = Config;
		return Config;
	end
end

--Called to uninitialize the Insertion Conduit
function Insertion.Uninitialize()
	if Predictions ~= nil then
		for k,i in pairs(Predictions) do
			for m,prediction in ipairs(i) do
				if world.entityExists(prediction.Traversal) then
					world.callScriptedEntity(prediction.Traversal,"__Traversal__.SetInsertionTable",nil);
				end
			end
		end
	end
	Groups.Uninitialize();
end