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
local StringTableMetatable = {
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
	end}
local Predictions = setmetatable({},StringTableMetatable);
local PredictionsForTossing = setmetatable({},StringTableMetatable);
local AnyNumTable = setmetatable({},{
	__index = function(_,k)
		return k;
	end});
local ConfigCache = setmetatable({}, { __mode = 'v' });
local InsertID;
local InsertUUID;
local Uninitializing = false;
local Dying = false;
local ContainerQueryUUID;
local AllContainerItems;

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
local InsertIDChange;
local SavePredictions;
local LoadPredictions;
local PostInit;

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
	InsertID = config.getParameter("insertID");
	if InsertID == nil then
		object.setConfigParameter("insertID","");
		InsertID = "";
	end
	InsertUUID = config.getParameter("InsertUUID");
	if InsertUUID == nil then
		InsertUUID = sb.makeUuid();
		object.setConfigParameter("InsertUUID",InsertUUID);
	end
	ConduitCore.AddConnectionType("Containers",function(ID) return ContainerHelper.IsContainer(ID) end);
	--Groups.OnUpdateFunction(GroupUpdate);
	ConduitCore.AddPostInitFunction(PostInit);
	ConduitCore.Initialize();
	SetMessages();
	local OldDie = die;
	die = function()
		if OldDie ~= nil then
			OldDie();
		end
		Dying = true;
	end
end

--Adds the insertion conduit's save parameters
function __Insertion__.SaveParameters()
	ConduitCore.AddSaveParameter("insertID",InsertID);
end

--Gets the ID of the Insertion Conduit
function Insertion.GetID()
	return SourceID;
end

--Returns if the conduit is ready to start transporting items
function Insertion.Ready()
	return ConduitCore.FirstUpdateCompleted();
end

--Gets the Insert ID of this conduit
function Insertion.GetInsertID()
	return InsertID;
end

--Is an insertion conduit
function Insertion.IsInsertion()
	return true;
end

--Called when the ConduitCore is fully initialized
PostInit = function()
	--TODO -- TODO -- TODO -- TODO -- TODO
	local LoadedPredictions = LoadPredictions("StoredPredictions");
	local LoadedPredictionsForTossing = LoadPredictions("StoredPredictionsForTossing");
	--[[if LoadedPredictions ~= nil then
		
	end--]]
	for container,predictions in pairs(LoadedPredictions) do
		container = tonumber(container);
		if world.entityExists(container) and container > 0 then
			for _,prediction in ipairs(predictions) do
				local Leftover = ContainerHelper.PutItemsAt(container,prediction.Item,prediction.Slot - 1);
				if Leftover ~= nil then
					world.spawnItem(Leftover,SourcePosition);
				end
			end
		else
			for _,prediction in ipairs(predictions) do
				world.spawnItem(prediction.Item,SourcePosition);
			end
		end
	end
	for _,predictions in pairs(LoadedPredictionsForTossing) do
		for _,prediction in ipairs(predictions) do
			world.spawnItem(prediction.Item,SourcePosition);
		end
	end
	--Compatibility with older version of the mod
	if config.getParameter("Predictions") ~= nil then
		
		local PreviousContainers = config.getParameter("PreviousContainers");
		
		local OldPredictions = config.getParameter("Predictions");
		if OldPredictions ~= nil then
			
			for k,data in pairs(OldPredictions) do
				local Container = tonumber(k);
				
				if PreviousContainers ~= nil then
					local Index;
					for i,value in ipairs(PreviousContainers) do
						if Container == value then
							Index = i;
							break;
						end
					end
					if Index ~= nil then
						local Connections = ConduitCore.GetConnections("Containers");
						
						Container = Connections[Index] or -10;
						
					end
				end
				if world.entityExists(Container) then
					for _,p in ipairs(data) do
						local Item = ContainerHelper.PutItemsAt(Container,p.Item,p.Slot - 1);
						
						if Item ~= nil and Item.count > 0 then
							
							world.spawnItem(Item,SourcePosition,Item.count,Item.parameters);
						end
					end
				else
					for _,p in ipairs(data) do
						
						world.spawnItem(p.Item,SourcePosition,p.Item.count,p.Item.parameters);
					end
				end
			end
		end
		object.setConfigParameter("Predictions",nil);
		local OldTossings = config.getParameter("Dump");
		if OldTossings ~= nil then
			for _,data in pairs(OldTossings) do
				for _,prediction in ipairs(data) do
					world.spawnItem(p.Item,SourcePosition,p.Item.count,p.Item.parameters);
					
				end
			end
		end
		object.setConfigParameter("Dump",nil);
	end
end

--Adds any messages for the object to call
SetMessages = function()
	message.setHandler("__UISetInsertID__",function(_,_,newInsertID,newInsertUUID)
		InsertUUID = newInsertUUID or sb.makeUuid();
		object.setConfigParameter("InsertUUID",InsertUUID);
		if InsertID ~= newInsertID then
			InsertID = newInsertID;
			object.setConfigParameter("insertID",InsertID);
			InsertIDChange();
		end
	end);
	message.setHandler("__UIGetInsertID__",function(_,_,insertUUID)
		--sb.logInfo("GETTING INSERT ID");
		if InsertUUID ~= insertUUID then
			return {true,InsertID,InsertUUID};
		else
			return false;
		end
	end);
	message.setHandler("InsertionQueryContainers",function(_,_,uuid)
		return {Insertion.QueryContainers(uuid)};
	end);
end

InsertIDChange = function()
	
end

--Sets the Insert id
function Insertion.SetInsertID(id)
	if InsertID ~= id then
		InsertID = id;
		InsertIDChange();
		InsertUUID = sb.makeUuid();
		object.setConfigParameter("InsertUUID",InsertUUID);
		object.setConfigParameter("insertID",InsertID);

	end
end

--Called when the groups update
--GroupUpdate = function()
	--[[for Object,Connections,Master,k in Groups.GroupIterator() do
		
	end--]]
--end

--Called when a group is added
GroupAdd = function(Object,Connections,Master)
	--Add a prediction setup for the object
	
	if Master == SourceID then
		Predictions[Object] = {};
		PredictionsForTossing[Object] = {};
	end
end

--Called when a group is removed
GroupRemove = function(Object,Connections,OldMaster,NewMaster)
	
	
	
	
	
	
	--If this entity is the master
	if OldMaster == SourceID then
		
		--If no new master exists
		
		if NewMaster == nil then
			--Delete all the predictions for the object
			
			Predictions[Object] = {};
			PredictionsForTossing[Object] = {};
		else
			--Send the predictions to the new master
			
			
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
		--If there is a new master
		if NewMaster ~= nil then
			--Move The Predictions to the new master
			world.callScriptedEntity(NewMaster,"__Insertion__.SetPredictions",Object,Predictions[Object],PredictionsForTossing[Object]);
			Predictions[Object] = {};
			PredictionsForTossing[Object] = {};
		else
			--If the conduit is not uninitializing then delete the predictions, otherwise save them for later so it can be saved
			if not Uninitializing then
				--Delete the Predictions
				Predictions[Object] = {};
				PredictionsForTossing[Object] = {};
			end
		end
	--[[else
		--If there is a new master then just set the traversals coming here to a new insertion conduit
		if NewMaster ~= nil then
			local MasterPredictions = __Insertion__.GetMasterPredictions(Object,false);
			local MasterPredictionsForTossing = __Insertion__.GetMasterPredictions(Object,true);
			local MasterInsertionTable = world.callScriptedEntity(NewMaster,"__Insertion__.GetInsertionTable");
			for k,i in ipairs(MasterPredictions[Object]) do
				if world.entityExists(i.Traversal) and world.callScriptedEntity(i.Traversal,"__Traversal__.GetInsertionTable") == Insertion then
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",MasterInsertionTable);
				end
			end
			for k,i in ipairs(MasterPredictionsForTossing[Object]) do
				if world.entityExists(i.Traversal) and world.callScriptedEntity(i.Traversal,"__Traversal__.GetInsertionTable") == Insertion then
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",MasterInsertionTable);
				end
			end
		end--]]
	end
end

--
function __Insertion__.SetPredictions(Object,predictions,predictionsForTossing)
	
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
function Insertion.SendItem(Item,DestinationContainer,Slot,ExtractionID,PossibleSlots,TraversalColor,TraversalSpeed)
	--local Start = os.time();
	if TraversalSpeed == nil then
		TraversalSpeed = 1;
	elseif TraversalSpeed == 0 then
		TraversalSpeed = 1;
	end
	--sb.logInfo("2 Insertion = " .. sb.print(SourceID));
	--sb.logInfo("2 IS Connected to " .. sb.print(DestinationContainer) .. " = " .. sb.print(Insertion.IsConnectedTo(DestinationContainer)));
	if not Insertion.IsConnectedTo(DestinationContainer) then
		error("This insertion Conduit is not connected to the Object : " .. sb.print(DestinationContainer));
	end
	TraversalColor = TraversalColor or "red";
	PossibleSlots = PossibleSlots or "any";
	local StartPosition = world.entityPosition(ExtractionID);
	--sb.logInfo("Before Spawn");
	local Traversal = world.spawnProjectile("traversal" .. TraversalColor,{StartPosition[1] + 0.5,StartPosition[2] + 0.5});
	--sb.logInfo("After Spawn");
	--sb.logInfo("Speed = " .. sb.print(End - Start));

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
	--sb.logInfo("INSERTION SENT SLOT = " .. sb.print(Slot));
	local Prediction = {Item = Item,Slot = Slot,MaxStack = Insertion.GetItemConfig(Item).config.maxstack or 1000,Traversal = Traversal,PossibleSlots = PossibleSlots};
	AddPrediction(DestinationContainer,Prediction);
	world.callScriptedEntity(Traversal,"__Traversal__.Initialize",Insertion,DestinationContainer,"Conduits",TraversalSpeed);
	--local End = os.time();
	--sb.logInfo("Speed = " .. sb.print(End - Start));
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
			--sb.logInfo("PREDICTION = " .. sb.print(i));
			--Add Item into the Container
			ContainerHelper.PutItemsAt(Object,i.Item,i.Slot - 1);
		end
		for k,i in ipairs(Predictions) do
			RemovePrediction(Object,i);
		end
	else
		for k,i in ipairs(Predictions) do
			--Drop Items on the group
			world.spawnItem(i.Item,Position);
		end
	end
	for k,i in ipairs(PredictionsForTossing) do
		world.spawnItem(i.Item,Position);
	end
	if world.entityExists(Object) then
		for k,i in ipairs(PredictionsForTossing) do
			RemovePredictionForTossing(Object,i);
		end
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
	if world.entityExists(Object) then
		for k,i in ipairs(Predictions) do
			RemovePrediction(Object,i);
		end
		for k,i in ipairs(PredictionsForTossing) do
			RemovePredictionForTossing(Object,i);
		end
	end
end

function __Insertion__.SetContainerCache(Contents,UUID)
	if __Extraction__ ~= nil then
		return __Extraction__.SetContainerCache(Contents,UUID);
	else
		sb.logInfo("Replacing Insertion for " .. sb.print(SourceID) .. " from " .. sb.print(ContainerQueryUUID) .. " to = " .. sb.print(UUID));
		AllContainerItems = Contents;
		ContainerQueryUUID = UUID;
	end
end

function __Insertion__.SetContainerCachePortion(Contents,UUID,Container)
	if __Extraction__ ~= nil then
		return __Extraction__.SetContainerCachePortion(Contents,UUID,Container);
	else
		AllContainerItems[tostring(Container)] = Contents;
		ContainerQueryUUID = UUID; 
	end
end

--Gets the Container Cache UUID
function __Insertion__.GetContainerCacheUUID()
	if __Extraction__ ~= nil then
		return __Extraction__.GetContainerCacheUUID();
	else
		return ContainerQueryUUID;
	end
end

--Gets the Container Cache
function __Insertion__.GetContainerCache()
	if __Extraction__ ~= nil then
		return __Extraction__.GetContainerCache();
	else
		return AllContainerItems;
	end
end

--Queries all neighboring containers for changes
--Returns false if no changes have taken place
--Returns the table of items in all the containers and a new uuid if there's changes
function Insertion.QueryContainers(uuid,asTable)
	if Extraction ~= nil then
		return Extraction.QueryContainers(uuid,asTable);
	end
	local HasChanges = false;
	if AllContainerItems == nil then
		AllContainerItems = {};
		HasChanges = true;
	end
	local Containers = ConduitCore.GetConnections("Containers");
	if Containers == nil or Containers == false then return nil end;
	for _,container in ipairs(Containers) do
		if container ~= 0 then
			local StringContainer = tostring(container);
			if AllContainerItems[StringContainer] == nil then
				AllContainerItems[StringContainer] = {};
				HasChanges = true;
			end
			local ContainerContents = AllContainerItems[StringContainer];
			local Size = world.containerSize(container);
			for i=1,Size do
				local Item = world.containerItemAt(container,i - 1);
				if ContainerContents[i] == nil then
					ContainerContents[i] = "";
					HasChanges = true;
				end
				if ContainerContents[i] == nil then
					ContainerContents[i] = "";
					HasChanges = true;
				end
				if Item == nil then
					if ContainerContents[i] ~= "" then
						ContainerContents[i] = "";
						HasChanges = true;
					end
				else
					if ContainerContents[i] == "" then
						ContainerContents[i] = Item;
						HasChanges = true;
					else
						if root.itemDescriptorsMatch(Item,ContainerContents[i],true) == false then
							ContainerContents[i] = Item;
							HasChanges = true;
						else
							if Item.count ~= ContainerContents[i].count then
								ContainerContents[i].count = Item.count;
								HasChanges = true;
							end
						end
					end
				end
			end
		end
	end
	if HasChanges == true then
		ContainerQueryUUID = sb.makeUuid();
	end
	if uuid ~= ContainerQueryUUID then
		if asTable == true then
			return {AllContainerItems,ContainerQueryUUID};
		else
			return AllContainerItems,ContainerQueryUUID;
		end
	else
		return false;
	end
end

--Checks if the item can fit in the Object
function Insertion.ItemCanFit(Object,Item,Slots,Exact)
	if not world.entityExists(Object) then return nil end;
	local Inventory = GetInventoryWithPredictions(Object);
	local MaxStack = Insertion.GetItemConfig(Item).config.maxStack or 1000;
	Exact = Exact or false;
	if Slots == nil then
		Slots = "any";
	elseif type(Slots) == "number" then
		Slots = {Slots};
	end
	--Slots = Slots or "any";
	for slot in SlotIter(Slots,ContainerHelper.Size(Object)) do
		if Inventory[slot] == nil then
			--If the slot doesn't have anything in it then the item can go there
			return Item,slot;
		elseif root.itemDescriptorsMatch(Inventory[slot],Item,true) then
			--If the item in the slot and the item were trying to fit match
			local RemainingCount = MaxStack - Inventory[slot].count;
			if Item.count <= RemainingCount then
				return Item,slot;
			else
				if RemainingCount > 0 and Exact ~= true then
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
		
		if Tossing then
			return PredictionsForTossing;
		else
			return Predictions;
		end
	else
		if Master ~= nil and world.entityExists(Master) then
			return world.callScriptedEntity(Master,"__Insertion__.GetMasterPredictions",Object,Tossing);
		else
			return nil;
		end
	end
end

--Adds the prediction to the list and to the traversal's
AddPrediction = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object)[Object];
	if Predictions ~= nil then
		Predictions[#Predictions + 1] = prediction;
		if world.entityExists(prediction.Traversal) then
			world.callScriptedEntity(prediction.Traversal,"__Traversal__.AddPrediction",prediction);
		end
	end
end

--Removes the prediction from the list and from the traversal's
RemovePrediction = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object);
	if Predictions ~= nil then
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
end

--Adds the prediction to the list for tossing and to the traversal's
AddPredictionForTossing = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object,true)[Object];
		if Predictions ~= nil then
		Predictions[#Predictions + 1] = prediction;
		if world.entityExists(prediction.Traversal) then
			world.callScriptedEntity(prediction.Traversal,"__Traversal__.AddPredictionForTossing",prediction);
		end
	end
end

--Removes the prediction from the list for tossing and from the traversal's
RemovePredictionForTossing = function(Object,prediction)
	local Predictions = __Insertion__.GetMasterPredictions(Object,true);
	if Predictions ~= nil then
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
end

--Returns an iterator that iterates over the master predictions
PredictionIter = function(Object)
	local Predictions = __Insertion__.GetMasterPredictions(Object);
	if Predictions == nil or Predictions[Object] == nil then
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
	if not world.entityExists(Object) then return nil end;
	local Inventory = ContainerHelper.Items(Object);
	--Iterate over all the predictions
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
	Uninitializing = true;
	if Predictions ~= nil then
		
	--	
		for k,i in pairs(Predictions) do
			for m,prediction in ipairs(i) do
				if world.entityExists(prediction.Traversal) then
					
					world.callScriptedEntity(prediction.Traversal,"__Traversal__.SetInsertionTable",nil);
				end
			end
		end
	end
	--Set the Insertion Tables of the traversal coming here to the master
	for object in Groups.AllNeighbors() do
		
		local Master = Groups.GetMasterID(object);
		if world.entityExists(Master) then
			--If the master doesn't even exist then skip this step
			goto Continue;
		end
		if SourceID ~= Master then
			--Set the Insertion tables to be the new master's one
			local MasterPredictions = __Insertion__.GetMasterPredictions(object,false);
			local MasterPredictionsForTossing = __Insertion__.GetMasterPredictions(object,true);
			
		--	
			local MasterInsertionTable = world.callScriptedEntity(Master,"__Insertion__.GetInsertionTable");
			for k,i in ipairs(MasterPredictions[object]) do
				if world.entityExists(i.Traversal) and world.callScriptedEntity(i.Traversal,"__Traversal__.GetInsertionTable") == Insertion then
					
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",MasterInsertionTable);
				end
			end
			for k,i in ipairs(MasterPredictionsForTossing[object]) do
				if world.entityExists(i.Traversal) and world.callScriptedEntity(i.Traversal,"__Traversal__.GetInsertionTable") == Insertion then
					
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",MasterInsertionTable);
				end
			end
		else
			--Set the Insertion tables to be nil
			
			for k,i in ipairs(Predictions[object]) do
				if world.entityExists(i.Traversal) then
				--	
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",nil);
				end
			end
			for k,i in ipairs(PredictionsForTossing[object]) do
				if world.entityExists(i.Traversal) then
					
					world.callScriptedEntity(i.Traversal,"__Traversal__.SetInsertionTable",nil);
				end
			end
		end
		::Continue::
	end
	Groups.Uninitialize();
	if Dying == false then
		SavePredictions(Predictions,"StoredPredictions");
		SavePredictions(PredictionsForTossing,"StoredPredictionsForTossing");
	end
end

--Saves the Predictions to the Conduit
SavePredictions = function(pred,saveName)
	
	pred = pred or Predictions;
	saveName = saveName or "StoredPredictions";
	if pred ~= nil then
		
		local SavingPredictions = setmetatable({},StringTableMetatable);
		local Connections = ConduitCore.GetConnections("Containers");
		for group,predictions in pairs(pred) do
			local Index;
			group = tonumber(group);
			for k,connection in ipairs(Connections) do
				if connection == group then
					Index = k;
					break;
				end
			end
			if Index ~= nil then
				SavingPredictions[Index] = predictions;
			end
		end
		
		object.setConfigParameter(saveName,SavingPredictions);
	else
		object.setConfigParameter(saveName,nil);
	end
end

--Loads the Predictions from the conduit
LoadPredictions = function(saveName)
	local StoredPredictions = setmetatable(config.getParameter(saveName,{}),StringTableMetatable);
	local FinalPredictions = setmetatable({},StringTableMetatable);
	local Connections = ConduitCore.GetConnections("Containers");
	
	
	for ConnectionIndex,predictions in pairs(StoredPredictions) do
		ConnectionIndex = tonumber(ConnectionIndex);
		
		if Connections[ConnectionIndex] ~= nil and Connections[ConnectionIndex] ~= 10 then
			FinalPredictions[Connections[ConnectionIndex]] = predictions;
		else
			FinalPredictions[-ConnectionIndex] = predictions;
		end
	end
	
	return FinalPredictions;
end

--Returns the insertion table for the Conduit
function __Insertion__.GetInsertionTable()
	return Insertion;
end