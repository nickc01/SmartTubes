
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
local Speed;
local Initialized = false;

--Functions
local UpdateMovement;
local InitializeMovement;
local UpdatePath;

--Initializes the Traversal
function __Traversal__.Initialize(insertion,destination,connectionType,speed,auto)
	SourceID = entity.id();
	Insertion = insertion;
	Destination = destination;
	ConnectionType = connectionType or "Conduits";
	Speed = speed or 1;
	
	if auto == nil then auto = true end;
	Initialized = true;
	if auto == true then
		OldUpdate = update;
		update = function(dt)
			if OldUpdate ~= nil then
				OldUpdate(dt);
			end
			if MovementFunction ~= nil then
				MovementFunction(dt);
			end
		end
		InitializeMovement();
	end
end

--Returns if the Traversal is initialized and running
function Traversal.IsInitialized()
	return Initialized;
end

--Updates the Movement so the traversal knows where to move to next
UpdateMovement = function()
	if PathIndex == #Path then
		return Traversal.Finish();
	end
	local StartPosition = world.entityPosition(Path[PathIndex]);
	--Check if traversal is over a conduit
	if StartPosition == nil--[[ or world.callScriptedEntity(Path[PathIndex],"IsConnectingTo",ConnectionType) ~= true--]] then
		--sb.logInfo("Start Position Nil");
		return Traversal.Drop();
	end
	local NextConduit = Path[PathIndex + 1];
	if not world.entityExists(NextConduit) then
		UpdatePath(Path[PathIndex]);
		if Path == nil then
		--sb.logInfo("Cannot Find a path");			
			return Traversal.Drop();
		end
		NextConduit = Path[PathIndex + 1];
		if not world.entityExists(NextConduit) then
			--sb.logInfo("Next conduit doesn't exist");
			return Traversal.Drop();
		end
	end
	local TraversalFunc = world.callScriptedEntity(NextConduit,"__ConduitCore__.GetTraversalPath",SourceID,StartPosition,Path[PathIndex],Speed);
	if TraversalFunc == nil then
		--If there is no Traversal Function for the object then try to reroute, otherwise, just drop
		UpdatePath(Path[PathIndex]);
		if Path == nil then
			--sb.logInfo("Can't find new path");
			return Traversal.Drop();
		end
		NextConduit = Path[PathIndex + 1];
		if NextConduit == nil or not world.entityExists(NextConduit) then
			--sb.logInfo("Next conduit in new path doesn't exist");
			return Traversal.Drop();
		else
			TraversalFunc = world.callScriptedEntity(NextConduit,"__ConduitCore__.GetTraversalPath",SourceID,StartPosition,Path[PathIndex],Speed);
			if TraversalFunc == nil then
				--sb.logInfo("TraversalFunc is nil");
				return Traversal.Drop();
			end
		end
	end
	
	MovementFunction = function(dt)
		if not world.entityExists(NextConduit) then
			--sb.logInfo("Movement for next conduit is nil");
			return Traversal.Drop();
		end
		local Pos,Rot,Stop = TraversalFunc(dt);
		if Pos == nil then return nil end;
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

--Returns the speed of the Traversal
function Traversal.GetSpeed()
	return Speed;
end

--Sets the speed of the Traversal
function Traversal.SetSpeed(speed)
	Speed = speed;
end

--Initializes the Movement Function for the first run
InitializeMovement = function()
	UpdatePath(world.objectAt(entity.position()));
	if Path == nil then
		--sb.logInfo("No Path to start with");
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

--Sets the Insertion Table that corresponds to the insertion conduit
function __Traversal__.SetInsertionTable(value)
--[[	if value == nil then
		
	else
		
	end--]]
	Insertion = value;
end

--Returns the currently set insertion table
function __Traversal__.GetInsertionTable()
	return Insertion;
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
	if Insertion ~= nil--[[ and world.entityExists(Insertion.GetID())--]] then
		world.callScriptedEntity(Insertion.GetID(),"__Insertion__.InsertTraversalItems",SourceID);
	else
		--sb.logInfo("Cannot insert items");
		Traversal.Drop();
	end
	projectile.die();
	return nil;
end

--Destroys the Traversal and Drops all of its contents
function Traversal.Drop()
	if Insertion ~= nil--[[ and world.entityExists(Insertion.GetID())--]] then
		world.callScriptedEntity(Insertion.GetID(),"__Insertion__.DropTraversalItems",SourceID);
	else
		local Position = entity.position();
		for _,prediction in ipairs(Predictions) do
			world.spawnItem(prediction.Item,Position);
		end
		Predictions = {};
	end
	projectile.die();
	return nil;
end

--Respawns the Traversal and goes to "AmountToMoveForward" down to the next conduit
function Traversal.Respawn(NewPosition,AmountToMoveForward)
	NewPosition = NewPosition or world.entityPosition(Path[PathIndex]);
	AmountToMoveForward = AmountToMoveForward or 1;
	local NewTraversal = world.spawnProjectile(projectile.getParameter("projectileName"),NewPosition);
	
	world.callScriptedEntity(NewTraversal,"__Traversal__.InitializeAfterRespawn",Traversal,Insertion,ConnectionType,Predictions,PredictionsForTossing,Path,PathIndex + AmountToMoveForward);
	if Insertion ~= nil then
		world.callScriptedEntity(Insertion.GetID(),"__Insertion__.TraversalRespawn",SourceID,NewTraversal);
	end
	projectile.die();
	return NewTraversal;
end

--Moves to Path Index forward by some amount
function Traversal.AdvancePathIndex(amount)
	amount = amount or 1;
	PathIndex = PathIndex + amount;
end

--Retrieves the conduit at the path index plus some amount
function Traversal.GetAtPathIndex(amount)
	amount = amount or 0;
	return Path[PathIndex + amount];
end

--Returns the size of the Path
function Traversal.PathSize()
	return #Path;
end

--Returns the current path index number
function Traversal.PathIndex()
	return PathIndex;
end

--Initializes the Conduit from a respawn
function __Traversal__.InitializeAfterRespawn(OldTraversal,insertion,connectionType,predictions,predictionsForTossing,path,NewIndex)
	__Traversal__.Initialize(insertion,OldTraversal.GetDestination(),connectionType,OldTraversal.GetSpeed(),false);
	Predictions = predictions or {};
	for _,prediction in ipairs(Predictions) do
		prediction.Traversal = SourceID;
	end
	PredictionsForTossing = predictionsForTossing or {};
	for _,prediction in ipairs(PredictionsForTossing) do
		prediction.Traversal = SourceID;
	end
	OldUpdate = update;
	Path = path;
	PathIndex = NewIndex;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		if MovementFunction ~= nil then
			MovementFunction(dt);
		end
	end
	UpdateMovement();
end

