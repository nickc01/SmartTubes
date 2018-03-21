
--Declaration

--Public Table
Traversal = {};
local Traversal = Traversal;

--Private Table, PLEASE DON'T TOUCH
__Traversal__ = {};
local __Traversal__ = __Traversal__;

--Variables
local SourceID;
local Insertion;
local Predictions = {};
local PredictionsForTossing = {};
local Destination;
local OldUpdate;
local MovementFunction;
local Path;
local PathIndex;
local ConnectionType;

--Functions
local UpdateMovement;
local InitializeMovement;
local UpdatePath;

--Initializes the Traversal
function Traversal.Initialize(insertion,destination,connectionType,auto)
	SourceID = entity.id();
	Insertion = insertion;
	Destination = destination;
	OldUpdate = update;
	ConnectionType = connectionType or "Conduits";
	auto = auto or true;
	if auto == true then
		update = function(dt)
			if OldUpdate ~= nil then
				OldUpdate(dt);
			end
			MovementFunction(dt);
		end
		InitializeMovement();
	end
end

--Updates the Movement so the traversal knows where to move to next
UpdateMovement = function()
	if PathIndex == #Path then
		return Traversal.Finish();
	end
	--sb.logInfo("PathIndex = " .. sb.print(PathIndex));
	--sb.logInfo("Path = " .. sb.print(Path));
	local StartPosition = world.entityPosition(Path[PathIndex]);
	--Check if traversal is over a conduit
	if StartPosition == nil--[[ or world.callScriptedEntity(Path[PathIndex],"IsConnectingTo",ConnectionType) ~= true--]] then
		return Traversal.Drop();
	end
	local NextConduit = Path[PathIndex + 1];
	if not world.entityExists(NextConduit) then
		UpdatePath(Path[PathIndex]);
		if Path == nil then
			return Traversal.Drop();
		end
		NextConduit = Path[PathIndex + 1];
		if not world.entityExists(NextConduit) then
			return Traversal.Drop();
		end
	end
	local TraversalFunc = world.callScriptedEntity(NextConduit,"__ConduitCore__.GetTraversalPath",SourceID,StartPosition,Path[PathIndex],1);
	if TraversalFunc == nil then
		return Traversal.Drop();
	end
	MovementFunction = function(dt)
		if not world.entityExists(NextConduit) then
			return Traversal.Drop();
		end
		local Pos,Rot,Stop = TraversalFunc(dt);
		if Stop == true then
			mcontroller.setPosition(Pos);
			if Rot ~= nil then
				mcontroller.setRotation(Rot);
			end
			PathIndex = PathIndex + 1;
			UpdateMovement();
		else
			mcontroller.setPosition(Pos);
			if Rot ~= nil then
				mcontroller.setRotation(Rot);
			end
		end
	end
end

--Initializes the Movement Function for the first run
InitializeMovement = function()
	UpdatePath(world.objectAt(entity.position()));
	if Path == nil then
		return Traversal.Drop();
	end
	UpdateMovement();
end

--Updates the Path the traversal uses to get to the destination
UpdatePath = function(SourceObject)
	if SourceObject ~= nil and world.entityExists(SourceObject) and Insertion ~= nil then
		Path = world.callScriptedEntity(SourceObject,"ConduitCore.GetPath",ConnectionType,Insertion.GetID());
		PathIndex = 1;
	else
		Path = nil;
		PathIndex = 0;
	end
end

--Nullifies the Insertion Table when the Insertion Conduit is destroyed
function __Traversal__.SetInsertionTable(value)
	Insertion = value;
end


--Removes a Prediction From the Traversal
function __Traversal__.RemovePrediction(Prediction)
	for k,i in ipairs(Predictions) do
		if i == Prediction then
			table.remove(Predictions,k);
			return nil;
		end
	end
end

--Adds a Prediction From the Traversal
function __Traversal__.AddPrediction(Prediction)
	Predictions[#Predictions + 1] = Prediction;
end

--Removes a Prediction for tossing From the Traversal
function __Traversal__.RemovePredictionForTossing(Prediction)
	for k,i in ipairs(PredictionsForTossing) do
		if i == Prediction then
			table.remove(PredictionsForTossing,k);
			return nil;
		end
	end
end

--Adds a Prediction for tossing From the Traversal
function __Traversal__.AddPredictionForTossing(Prediction)
	PredictionsForTossing[#PredictionsForTossing + 1] = Prediction;
end

--Returns the Traversal's Predictions
function __Traversal__.GetPredictions(Tossing)
	if Tossing == true then
		return PredictionsForTossing;
	else
		return Predictions;
	end
	--return Predictions,PredictionsForTossing;
end

--Returns the Traversal's Destination Container
function Traversal.GetDestination()
	return Destination;
end

--Completes the item transportation and adds its contents into the Destination Container
function Traversal.Finish()
	if Insertion ~= nil then
		world.callScriptedEntity(Insertion.GetID(),"__Insertion__.InsertTraversalItems",SourceID);
	else
		Traversal.Drop();
	end
	projectile.die();
end

--Destroys the Traversal and Drops all of its contents
function Traversal.Drop()
	if Insertion ~= nil then
		world.callScriptedEntity(Insertion.GetID(),"__Insertion__.DropTraversalItems",SourceID);
	else
		local Position = entity.position();
		for _,prediction in ipairs(Predictions) do
			world.spawnItem(prediction.Item,Position);
		end
		Predictions = {};
	end
	projectile.die();
end

