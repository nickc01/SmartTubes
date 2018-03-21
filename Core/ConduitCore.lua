
--Declaration
if ConduitCore ~= nil then return nil end;
--Public Table
ConduitCore = {};
local ConduitCore = ConduitCore;

--Private Table, DO NOT USE PLEASE
__ConduitCore__ = {};
local __ConduitCore__ = __ConduitCore__;

--Variables
local Initialized = false;
local FirstUpdateComplete = false;
local ForceUpdate = false;
local Uninitialized = false;
local ConnectionPoints = {{0,1},{0,-1},{-1,0},{1,0}};
local Connections;
local ConnectionTypes = {
	Conduits = {
		Condition = function(ID) return world.getObjectParameter(ID,"conduitType") ~= nil end,
		Connections = {};
	};
};
local NumOfConnections = 4;
local SourceID;
local SourcePosition;
local UpdateContinously = false;
local Dying = false;
local NetworkCache = {};
local NetworkUpdateFunctions = {};
local FunctionTableTemplate;
local ConnectionUpdateFunctions = {};
local LocalNetworkUpdateFunctions = {};

--Functions
local PostInit;
local SetMessages;
local ConnectionUpdate;
local NetworkChange;
local UpdateOtherConnections;
local IsInTable;
local UpdateSprite;
local DefaultTraversalFunction = function(Traversal,StartPosition,PreviousID,Speed)
	local EndPosition = entity.position();
	local Time = 0;
	return function(dt)
		Time = Time + dt * Speed;
		if Time >= 1 then
			return {EndPosition[1] + 0.5,EndPosition[2] + 0.5},nil,true;
		else
			return {0.5 + StartPosition[1] + (EndPosition[1] - StartPosition[1]) * Time,0.5 + StartPosition[2] + (EndPosition[2] - StartPosition[2]) * Time};
		end
	end
end
local TraversalFunction = DefaultTraversalFunction;

--Initializes the Conduit
function ConduitCore.Initialize()
	if Initialized == true then return nil else Initialized = true end;
	if entity == nil then
		local OldInit = init;
		init = function()
			if OldInit ~= nil then
				OldInit();
			end
			ConduitCore.Initialize();
		end
		return nil;
	end
	SourceID = entity.id();
	SourcePosition = entity.position();
	local NoScriptDelta = false;
	if script.updateDt() == 0 then
		NoScriptDelta = true;
		script.setUpdateDelta(1);
	end
	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		PostInit();
		update = function(dt)
			if UpdateContinously == true then
				ConduitCore.Update();
			end
			if OldUpdate ~= nil then
				OldUpdate(dt);
			end
		end
		if NoScriptData then
			script.setUpdateDelta(0);
		end
	end
	local OldDie = die;
	die = function()
		if OldDie ~= nil then
			OldDie();
		end
		Dying = true;
	end
	local OldUninit = uninit;
	uninit = function()
		if OldUninit ~= nil then
			OldUninit();
		end
		ConduitCore.Uninitialize();
	end
	SetMessages();
end

--Sets the Current Entity's Messages
SetMessages = function()
	
end

--Initialization After the First Update Loop
PostInit = function()
	ForceUpdate = true;
	ConduitCore.Update();
	ForceUpdate = false;
	FirstUpdateComplete = true;
end

--Returns true if this is a conduit
function ConduitCore.IsConduit()
	return true;
end

--Updates itself and it's connections and returns whether the connections have changed or not
function ConduitCore.Update()
	--if FirstUpdateComplete == false then return nil end;
	if not (ForceUpdate or FirstUpdateComplete) then return nil end;
	if ConduitCore.UpdateSelf() then
		UpdateOtherConnections();
		return true;
	end
	return false;
end
--Updates itself without updating it's connections and returns whether the connections have changed or not
function ConduitCore.UpdateSelf()
	if not (ForceUpdate or FirstUpdateComplete) then return nil end;
	local PostFuncs = {};
	local ConnectionTypesAreChanged = {};
	local ConnectionsAreChanged = false;
	if Connections == nil then
		Connections = {};
	end
	for i=1,NumOfConnections do
		local Object = world.objectAt({SourcePosition[1] + ConnectionPoints[i][1],SourcePosition[2] + ConnectionPoints[i][2]});
		if Object == nil then
			if Connections[i] ~= 0 then
				Connections[i] = 0;
				ConnectionsAreChanged = true;
			end
			for ConnectionType,ConnectionData in pairs(ConnectionTypes) do
				if ConnectionData.Connections[i] ~= 0 then
					if ConnectionTypesAreChanged[ConnectionType] == nil then
						ConnectionTypesAreChanged[ConnectionType] = true;
						PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
						PostFuncs[#PostFuncs + 1] = function() __ConduitCore__.CallNetworkChangeFunctions(ConnectionType) end;
					end
					ConnectionData.Connections[i] = 0;
				end
			end
		else
			local Added = false;
			for ConnectionType,ConnectionData in pairs(ConnectionTypes) do
				if ConnectionData.Condition(Object) == true then
					if Added == false then
						Added = true;
						if Connections[i] ~= Object then
							Connections[i] = Object;
							ConnectionsAreChanged = true;
						end
					end
					--Set the Value to the object and update the network if needed
					if ConnectionData.Connections[i] ~= Object then
						if ConnectionTypesAreChanged[ConnectionType] == nil then
							ConnectionTypesAreChanged[ConnectionType] = true;
							PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
							PostFuncs[#PostFuncs + 1] = function() __ConduitCore__.CallNetworkChangeFunctions(ConnectionType) end;
						end
						ConnectionData.Connections[i] = Object;
					end
				else
					--Set the Value to 0 and update the network if needed
					if ConnectionData.Connections[i] ~= 0 then
						if ConnectionTypesAreChanged[ConnectionType] == nil then
							ConnectionTypesAreChanged[ConnectionType] = true;
							PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
							PostFuncs[#PostFuncs + 1] = function() __ConduitCore__.CallNetworkChangeFunctions(ConnectionType) end;
						end
						ConnectionData.Connections[i] = 0;
					end
				end
			end
			if Added == false then
				if Connections[i] ~= 0 then
					Connections[i] = 0;
					ConnectionsAreChanged = true;
				end
			end
		end
	end
	if #PostFuncs > 0 then
		for k,i in ipairs(PostFuncs) do
			i();
		end
	end
	if ConnectionsAreChanged == true then
		ConnectionUpdate();
	end
	return ConnectionsAreChanged;
end

--Called whenever the network changes
NetworkChange = function(ConnectionType)
	if NetworkCache[ConnectionType] ~= nil then
		NetworkCache[ConnectionType].NeedsUpdating = true;
	end
	for i=1,#LocalNetworkUpdateFunctions do
		LocalNetworkUpdateFunctions[i](ConnectionType);
	end
end

--Add a function that is called when the Network is changed for a certain connection type
function __ConduitCore__.AddOnNetworkChangeFunc(func,ConnectionType)
	if NetworkUpdateFunctions[ConnectionType] == nil then
		NetworkUpdateFunctions[ConnectionType] = {func};
	else
		local ConnectionFunctions = NetworkUpdateFunctions[ConnectionType];
		for i=1,#NetworkUpdateFunctions[ConnectionType] do
			if NetworkUpdateFunctions[ConnectionType][i] == func then
				return nil;
			end
		end
		NetworkUpdateFunctions[ConnectionType][#NetworkUpdateFunctions[ConnectionType] + 1] = func;
	end
end

--Calls all the network change functions of the Connection Type and removes them
function __ConduitCore__.CallNetworkChangeFunctions(ConnectionType)
	--sb.logInfo("__CONNECTIONTYPE = " .. sb.print(ConnectionType));
	--NetworkChange(ConnectionType);
	--sb.logInfo("Post");
	if NetworkUpdateFunctions[ConnectionType] ~= nil then
		for i=#NetworkUpdateFunctions[ConnectionType],1,-1 do
			local func = NetworkUpdateFunctions[ConnectionType][i];
			table.remove(NetworkUpdateFunctions[ConnectionType],i);
			func(ConnectionType);
		end
	end
end

--Checks if the value is in the numerical table
IsInTable = function(table,value)
	for i=1,#table do
		if table[i] == value then return true end;
	end
	return false;
end

--Returns the Entire Connection Tree for the "Conduit" Connection Type
function ConduitCore.GetConduitNetwork()
	return ConduitCore.GetNetwork("Conduits");
end

--Returns a Path From this conduit to the Entity "To" using the "Conduit" Connection Type
function ConduitCore.GetConduitPath(To)
	return ConduitCore.GetPath("Conduits",To);
end

--Returns true if this is connecting to anything with the Connection type
function ConduitCore.IsConnectingTo(connectionType)
	return ConnectionTypes[connectionType] ~= nil;
end

--Sets the Traversal function that is called to set the traversals position
--the function must return another function that takes the parameter : dt
--and must return a position,rotation (or nil for no rotation),and whether the traversal should stop calling the function or not
function ConduitCore.SetTraversalFunction(func)
	TraversalFunction = func;
end

--Returns the Currently Set Traversal Function
function ConduitCore.GetTraversalFunction()
	return TraversalFunction;
end

--Returns the Default Traversal Function
function ConduitCore.GetDefaultTraversalFunction()
	return DefaultTraversalFunction;
end

function __ConduitCore__.GetTraversalPath(Traversal,StartPosition,PreviousID,Speed)
	return TraversalFunction(Traversal,StartPosition,PreviousID,Speed);
end

--Returns a Path From this conduit to the Entity "To" using the Connection Type
function ConduitCore.GetPath(ConnectionType,To)
	if NetworkCache[ConnectionType] == nil then
		ConduitCore.GetNetwork(ConnectionType);
	end
	local PathNetwork = NetworkCache[ConnectionType].WithPath;
	local Path = {{ID = To}};
	local Node;
	for i=1,#PathNetwork do
		if PathNetwork[i].ID == To then
			Node = PathNetwork[i];
		end
	end
	if Node ~= nil then
		while(true) do
			if Node.Previous ~= nil then
				Path[#Path + 1] = Node.Previous;
				Node = Node.Previous;
			else
				break;
			end
		end
		local NewPath = {};
		for i=#Path,1,-1 do
			--sb.logInfo("Path Index in Pathfinder = " .. sb.print(Path[i]));
			NewPath[#NewPath + 1] = Path[i].ID;
		end
		return NewPath;
	end
end

--Returns the Entire Connection Tree for the Passed In Connection Type
function ConduitCore.GetNetwork(ConnectionType)
	if ConnectionTypes[ConnectionType] == nil then
		return nil;
	end
	if NetworkCache[ConnectionType] ~= nil and NetworkCache[ConnectionType].NeedsUpdating == false then
		return NetworkCache[ConnectionType].Normal;
	end
	--sb.logInfo("GENERATING NEW NETWORK");
	local Findings = {};
	local FindingsWithPath = {};
	local Next = {{ID = SourceID}};
	repeat
		local NewNext = {};
		for i=1,#Next do
			local Connections = world.callScriptedEntity(Next[i].ID,"ConduitCore.GetConnections",ConnectionType);
			if Connections == nil then goto Continue end;
			for _,connection in ipairs(Connections) do
				if connection ~= 0 then
					if IsInTable(Findings,connection) then
						goto NextConnection;
					end
					for k=1,#Next do
						if Next[k].ID == connection then
							goto NextConnection;
						end
					end
					NewNext[#NewNext + 1] = {ID = connection,Previous = Next[i]};
				end
				::NextConnection::
			end
			::Continue::
			Findings[#Findings + 1] = Next[i].ID;
			FindingsWithPath[#FindingsWithPath + 1] = Next[i];
		end
		Next = NewNext;
	until #Next == 0;
	if NetworkCache[ConnectionType] == nil then
		NetworkCache[ConnectionType] = {
			NeedsUpdating = false,
			Normal = Findings,
			WithPath = FindingsWithPath
		};
	else
		NetworkCache[ConnectionType].Normal = Findings;
		NetworkCache[ConnectionType].WithPath = FindingsWithPath;
	end
	for i=1,#Findings do
		if Findings[i] ~= SourceID then
			world.callScriptedEntity(Findings[i],"__ConduitCore__.AddOnNetworkChangeFunc",NetworkChange,ConnectionType);
		end
	end
	return Findings;
end
--Gets the Current Connections for the "Conduit" Connection Type
function ConduitCore.GetConduitConnections()
	return ConduitCore.GetConnections("Conduits");
end

--Gets the Current Connections for the Passed In Connection Type
function ConduitCore.GetConnections(ConnectionType)
	if ConnectionTypes[ConnectionType] ~= nil then
		return ConnectionTypes[ConnectionType].Connections;
	end
end

--Sets the function that is called when the sprite needs to be updated
function ConduitCore.SetSpriteUpdateFunction(func)
	UpdateSprite = func;
end

--Adds a function to a list of functions that are called when the Conduit Connections Are Updated
function ConduitCore.AddConnectionUpdateFunction(func)
	ConnectionUpdateFunctions[#ConnectionUpdateFunctions + 1] = func;
end

--Adds a function to a list of functions that are called when the Conduit Network is Updated
function ConduitCore.AddNetworkUpdateFunction(func)
	LocalNetworkUpdateFunctions[#LocalNetworkUpdateFunctions + 1] = func;
end

UpdateSprite = function()
	object.setProcessingDirectives("");
	if Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","horizontal");
	elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","vertical");
	elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","corner");
	elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","corner");
		object.setProcessingDirectives("?flipy");
	elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","corner");
		object.setProcessingDirectives("?flipxy");
	elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","corner");
		object.setProcessingDirectives("?flipx");
	elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","triplehorizontal");
	elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","triplevertical");
		object.setProcessingDirectives("?flipx");
	elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","triplehorizontal");
		object.setProcessingDirectives("?flipy");
	elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","triplevertical");
	elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","full");
	elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","none");
	elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","right");
	elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","right");
		object.setProcessingDirectives("?flipx");
	elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] == 0 then
		animator.setAnimationState("cable","up");
		object.setProcessingDirectives("?flipy");
	elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] ~= 0 then
		animator.setAnimationState("cable","up");
	end
end

--Called when the Connections have changed
ConnectionUpdate = function()
	UpdateSprite();
	for i=1,#ConnectionUpdateFunctions do
		ConnectionUpdateFunctions[i]();
	end
end

--Sets the Connection Points
function ConduitCore.SetConnectionPoints(connections)
	ConnectionPoints = connections;
	NumOfConnections = #connections;
end

--Sets if the conduit should update continously or not
function ConduitCore.UpdateContinuously(bool)
	UpdateContinously = bool == true;
end

--Sends an update Message to the Connections
UpdateOtherConnections = function()
	for i=1,NumOfConnections do
		if Connections[i] ~= nil and world.entityExists(Connections[i]) then
			world.callScriptedEntity(Connections[i],"ConduitCore.UpdateSelf");
		end
	end
end

--Returns true if this conduit is connected to the "id" using the "Conduit" Connection Type
function ConduitCore.IsConnectedToConduit(id)
	return ConduitCore.IsConnected(id,"Conduits");
end

--Returns true if this conduit is connected to the "id"
function ConduitCore.IsConnectedGlobal(id)
	if Connections ~= nil then
		for k,i in ipairs(Connections) do
			if i == id then return true end;
		end
	end
	return false;
end

--Returns true if this conduit is connected to the "id" using the Connection Type
function ConduitCore.IsConnected(id,connectionType)
	if ConnectionTypes[connectionType] ~= nil then
		for k,i in ipairs(ConnectionTypes[connectionType].Connections) do
			if i == id then return true end;
		end
	end
	return false;
end

--Adds a Connection Type
function ConduitCore.AddConnectionType(ConnectionType,ConditionFunction)
	if ConnectionTypes[ConnectionType] == nil then
		ConnectionTypes[ConnectionType] = {
			Condition = ConditionFunction,
			Connections = {}
		};
		ConduitCore.Update();
	end
end

--Removes a Connection Type
function ConduitCore.RemoveConnectionType(ConnectionType)
	if ConnectionTypes[ConnectionType] ~= nil then
		ConnectionTypes[ConnectionType] = nil;
		ConduitCore.Update();
	end
end

--Returns true if the Connection Type is added and false otherwise
function ConduitCore.HasConnectionType(ConnectionType)
	if ConnectionTypes[ConnectionType] == nil then
		return false;
	end
	return true;
end

--Uninitializes the Conduit
function ConduitCore.Uninitialize()
	if Uninitialized == true then return nil else Uninitialized = true end;
	if Dying == true then
		UpdateOtherConnections();
	end
end



