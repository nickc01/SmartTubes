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

--Prediction Layout
--Item
--Slot
--MaxStack
--Traversal
--

--Functions
local SetMessages;
local GroupUpdate;
local GroupAdd;
local GroupRemove;
local GroupMasterChange;
local GetInventoryWithPredictions;

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

--Called when the groups update
GroupUpdate = function()
	--[[for Object,Connections,Master,k in Groups.GroupIterator() do
		
	end--]]
end

--Called when a group is added
GroupAdd = function(Object,Connections,Master)
	--Add a prediction setup for the object
	sb.logInfo("Adding Group");
	if Master == SourceID then
		Predictions[Object] = {};
		PredictionsForTossing[Object] = {};
	end
end

--Called when a group is removed
GroupRemove = function(Object,Connections,OldMaster,NewMaster)
	sb.logInfo("Removing Group");
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
		--Move The Predictions to the new master
		world.callScriptedEntity(Groups.GetMasterID(Object),"__Insertion__.SetPredictions",Object,Predictions[Object],PredictionsForTossing[Object]);
		Predictions[Object] = {};
		PredictionsForTossing[Object] = {};
	end
end

--
function __Insertion__.SetPredictions(Object,Predictions,PredictionsForTossing)
	Predictions[Object] = Predictions;
	PredictionsForTossing[Object] = PredictionsForTossing;
end

--Checks if the item can fit in the Object
function Insertion.ItemCanFit(Object,Item)
	
end

--Adds any messages for the object to call
SetMessages = function()
	
end

--Gets the Inventory of the object with it's predictions added to it
GetInventoryWithPredictions = function(Object)
	local Inventory = ContainerHelper.Items(Object);
	if Predictions[Object] ~= nil then
		for _,prediction in ipairs(Predictions[Object]) do
			if Inventory[prediction.Slot] == nil then
				--If Slot doesn't have anything
				--Add the  item into the slot
				Inventory[prediction.Slot] = {name = prediction.Item.name,count = prediction.Item.count};
			elseif root.itemDescriptorsMatch(Inventory[prediction.Slot],prediction.Item,true) then
				--If Inventory Item matches the prediction item
				if Inventory[prediction.Slot].count + prediction.Item.count > prediction.MaxStack then
					--If the Item can't fit inside the slot
					--TODO -- Find a new slot for the prediction item to fit in
					--TODO -- If it can't find one then remove the prediction and distribute it across all possible slots,
					--any leftovers will be added to the tossed predictions
				else
					--Add the predictions to the Inventory Slot
					Inventory[prediction.Slot].count = Inventory[prediction.Slot].count + prediction.Item.count;
				end
			else
				--TODO -- Find a new slot for the prediction item to fit in
				--TODO -- If it can't find one then remove the prediction and distribute it across all possible slots,
				--any leftovers will be added to the tossed predictions
			end
		end
	end
end

--Called to uninitialize the Insertion Conduit
function Insertion.Uninitialize()
	Groups.Uninitialize();
end