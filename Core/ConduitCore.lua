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
local Connections = {};
local ConnectionTypes = {
	Conduits = {
		Condition = function(ID) return world.getObjectParameter(ID,"conduitType") ~= nil end,
		Connections = {};
	},
	TerminalFindings = {
		Condition = function(ID) return world.getObjectParameter(ID,"conduitType") ~= nil end,
		Connections = {}
	}
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
local PostInitFunctions = {};
local ExtraPathFunctions = {};
local OnSaveRetrieveFunctions = {};
local Facade = false;
local FacadeIndicator;
local FacadeDropItem;
local IsOccluded = false;
local Die;
local DroppingItems = true;
local DroppingPosition;
local LocalRegionRect;
local DefaultAnimated = true;
local UsingNetworkForType = {};
local IndexToStringMeta = {
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
	end,
	__ipairs = function(tbl)
		local k,i = nil,nil;
		return function()
			k,i = next(tbl,k);
			if k == nil then
				return nil;
			end
			return tonumber(k),i;
		end
	end}
local SaveSettings = {
	IsSaving = false,
	DropItem = nil,
	Parameters = {},
	DisplayName = nil,
	DropPosition = nil,
	Color = nil
};

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
	end end
local GetObjectByConnectionPoint;
local TraversalFunction = DefaultTraversalFunction;
local ValuesToTable;
local InitWithSavedParams;
local ConnectionPointIter;

--Initializes the Conduit
function ConduitCore.Initialize()
	--sb.logInfo("Spawning new Object = " .. sb.print(entity.id()));
	if Initialized == true then return nil else Initialized = true end;
	--sb.logInfo("INIT of conduit = " .. sb.print(entity.id()));
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
	LocalRegionRect = {SourcePosition[1] - 2,SourcePosition[2] - 2,SourcePosition[1] + 2,SourcePosition[2] + 2};
	DefaultAnimated = config.getParameter("animation") == "/Animations/Cable.animation";
	if config.getParameter("__HasSavedParameters") == true then
		object.setConfigParameter("__HasSavedParameters",nil);
		InitWithSavedParams(config.getParameter("__SavedValueNames"));
	end
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
		if not world.regionActive(LocalRegionRect) then
			world.loadRegion(LocalRegionRect);
			return nil;
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
		Die();
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

--Called when the conduit has some saved Parameters
InitWithSavedParams = function(SavedParameters)
	for _,func in ipairs(OnSaveRetrieveFunctions) do
		func(SavedParameters);
	end
end

--Returns the conduit's terminal Data
function ConduitCore.GetTerminalData()
	--sb.logInfo("CALLING CONDUIT");
	local FlipX = false;
	local FlipY = false;
	local AnimationName;
	local AnimationState;
	local AnimationFile;
	local AnimationParts;
	local AnimationSource;
	if DefaultAnimated or Facade then
		AnimationName = "cable";
		if Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] == 0 then
			AnimationState = "horizontal";
		elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
			AnimationState = "vertical";
		elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] ~= 0 then
			AnimationState = "corner";
		elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] == 0 then
			AnimationState = "corner";
			FlipY = true;
		elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] == 0 then
			AnimationState = "corner";
			FlipX,FlipY = true,true;
		elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] ~= 0 then
			AnimationState = "corner";
			FlipX = true;
		elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] ~= 0 then
			AnimationState = "triplehorizontal";
		elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
			AnimationState = "triplevertical";
			FlipX = true;
		elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] == 0 then
			AnimationState = "triplehorizontal";
			FlipY = true;
		elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
			AnimationState = "triplevertical";
		elseif Connections[3] ~= 0 and Connections[4] ~= 0 and Connections[1] ~= 0 and Connections[2] ~= 0 then
			AnimationState = "full";
		elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] == 0 then
			AnimationState = "none";
		elseif Connections[3] ~= 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] == 0 then
			AnimationState = "right";
		elseif Connections[3] == 0 and Connections[4] ~= 0 and Connections[1] == 0 and Connections[2] == 0 then
			AnimationState = "right";
			FlipX = true;
		elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] ~= 0 and Connections[2] == 0 then
			AnimationState = "up";
			FlipY = true;
		elseif Connections[3] == 0 and Connections[4] == 0 and Connections[1] == 0 and Connections[2] ~= 0 then
			AnimationState = "up";
		end
		if Facade then 
			if FacadeInfo == nil then
				require("/Core/FacadeInfo.lua");
			end
				local Config = FacadeInfo.FacadeToObjectConfig(object.name());
				AnimationFile = Config.config.animation;
				AnimationParts = Config.config.animationParts;
				AnimationSource = FacadeInfo.FacadeToObject(object.name());
		end
	end
	return {FlipX = FlipX,FlipY = FlipY,AnimationName = AnimationName,AnimationState = AnimationState,AnimationFile = AnimationFile,AnimationParts = AnimationParts,AnimationSource = AnimationSource};
end

--Sets the Current Entity's Messages
SetMessages = function()
	message.setHandler("ConduitCore.GetSpriteState",ConduitCore.GetSpriteState);
	message.setHandler("ConduitCore.GetTerminalImageParameters",ConduitCore.GetTerminalData);
end

--Initialization After the First Update Loop
PostInit = function()
	ForceUpdate = true;
	ConduitCore.Update();
	ForceUpdate = false;
	for _,func in ipairs(PostInitFunctions) do
		func();
	end
end

--Adds a function that is called during Post Initialization
function ConduitCore.AddPostInitFunction(func)
	PostInitFunctions[#PostInitFunctions + 1] = func;
end

--Returns true if the position fits inside any of the connection Points
function ConduitCore.FitsInConnectionPoints(position)
	if type(position[1]) == "table" then
		--has multiple positions
		for _,pos in ipairs(position) do
			for point in ConnectionPointIter() do
				if point[1] + SourcePosition[1] == pos[1] and point[2] + SourcePosition[2] == pos[2] then
					return true;
				end
			end
		end
	else
		--It's a single position
		for point in ConnectionPointIter() do
			if point[1] + SourcePosition[1] == position[1] and point[2] + SourcePosition[2] == position[2] then
				return true;
			end
		end
	end
	return false;
end

--Returns true if this is a conduit
function ConduitCore.IsConduit()
	return true;
end

--Returns true if the conduit has done it's first update
function ConduitCore.FirstUpdateCompleted()
	return FirstUpdateComplete;
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
		local Object = GetObjectByConnectionPoint(i);
		if Object == nil then
			if Connections[i] ~= 0 then
				Connections[i] = 0;
				ConnectionsAreChanged = true;
			end
			for ConnectionType,ConnectionData in pairs(ConnectionTypes) do
				if ConnectionData.Connections[i] ~= 0 then
					if ConnectionTypesAreChanged[ConnectionType] == nil then
						ConnectionTypesAreChanged[ConnectionType] = true;
						if UsingNetworkForType[ConnectionType] == true then
							PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
						end
						PostFuncs[#PostFuncs + 1] = function() __ConduitCore__.CallNetworkChangeFunctions(ConnectionType) end;
					end
					ConnectionData.Connections[i] = 0;
				end
			end
		else
			local Added = false;
			for ConnectionType,ConnectionData in pairs(ConnectionTypes) do
				if world.entityExists(Object) and ConnectionData.Condition(Object) == true and (world.callScriptedEntity(Object,"ConduitCore.IsConduit") ~= true or world.callScriptedEntity(Object,"ConduitCore.FitsInConnectionPoints",ConduitCore.GetAllSpaces(SourceID)) == true) then
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
							if UsingNetworkForType[ConnectionType] == true then
								PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
							end
							PostFuncs[#PostFuncs + 1] = function() __ConduitCore__.CallNetworkChangeFunctions(ConnectionType) end;
						end
						ConnectionData.Connections[i] = Object;
					end
				else
					--Set the Value to 0 and update the network if needed
					if ConnectionData.Connections[i] ~= 0 then
						if ConnectionTypesAreChanged[ConnectionType] == nil then
							ConnectionTypesAreChanged[ConnectionType] = true;
							if UsingNetworkForType[ConnectionType] == true then
								PostFuncs[#PostFuncs + 1] = function() NetworkChange(ConnectionType) end;
							end
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
	if FirstUpdateComplete == false then
		FirstUpdateComplete = true;
	end
	if #PostFuncs > 0 then
		--sb.logInfo("CALLING POST FUNCS From = " .. sb.print(SourceID));
		--sb.logInfo("Post Func Amount = " .. sb.print(#PostFuncs));
		for k,i in ipairs(PostFuncs) do
			i();
		end
	end
	--sb.logInfo("ALL CONNECTION TYPES = " .. sb.print(ConnectionTypes));
	if ConnectionsAreChanged == true then
		ConnectionUpdate();
	end
	return ConnectionsAreChanged;
end

--Forcefully triggers a Network change
function ConduitCore.TriggerNetworkUpdate(connectionType)
	if UsingNetworkForType[connectionType] == true then
		NetworkChange(connectionType);
	end
	__ConduitCore__.CallNetworkChangeFunctions(connectionType);
end

--Forcefully triggers a Connection change
function ConduitCore.TriggerConnectionUpdate(connectionType)
	ConnectionUpdate(connectionType);
end

--Called whenever the network changes
NetworkChange = function(ConnectionType)
	--sb.logInfo("NETWORK CHANGE = ".. sb.print(SourceID));
	--sb.logInfo("ConnectionType = " .. sb.print(ConnectionType));
	if NetworkCache[ConnectionType] ~= nil then
		NetworkCache[ConnectionType].NeedsUpdating = true;
	end
	--sb.logInfo("Network Cache = " .. sb.print(NetworkCache[ConnectionType]));
	for i=1,#LocalNetworkUpdateFunctions do
		LocalNetworkUpdateFunctions[i](ConnectionType);
	end
end

--Add a function that is called when the Network is changed for a certain connection type
function __ConduitCore__.AddOnNetworkChangeFunc(id,func,ConnectionType)
	--[[if NetworkUpdateFunctions[ConnectionType] == nil then
		NetworkUpdateFunctions[ConnectionType] = {func};
	else
		local ConnectionFunctions = NetworkUpdateFunctions[ConnectionType];
		for i=1,#NetworkUpdateFunctions[ConnectionType] do
			if NetworkUpdateFunctions[ConnectionType][i] == func then
				return nil;
			end
		end
		NetworkUpdateFunctions[ConnectionType][#NetworkUpdateFunctions[ConnectionType] + 1] = func;
		
	end--]]
	--sb.logInfo("ADDING " .. sb.print(id) .. " to " .. sb.print(SourceID));
	if NetworkUpdateFunctions[ConnectionType] == nil then
		NetworkUpdateFunctions[ConnectionType] = setmetatable({},IndexToStringMeta);
	end
	local NetworkGroup = NetworkUpdateFunctions[ConnectionType];
	NetworkGroup[id] = func;
end

--Removes a function that is called when the Network is changed for a certain connection type
function __ConduitCore__.RemoveOnNetworkChangeFunc(id,ConnectionType)
	if NetworkUpdateFunctions[ConnectionType] ~= nil then
		NetworkUpdateFunctions[ConnectionType][id] = nil;
	end
end

--Calls all the network change functions of the Connection Type and removes them
function __ConduitCore__.CallNetworkChangeFunctions(ConnectionType)
	
	--NetworkChange(ConnectionType);
	--sb.logInfo("CALLING OTHER NETWORK CHANGE FUNCTIONS = " .. sb.print(SourceID));
	if NetworkUpdateFunctions[ConnectionType] ~= nil then
		--[[for i=#NetworkUpdateFunctions[ConnectionType],1,-1 do
			local func = NetworkUpdateFunctions[ConnectionType][i];
			table.remove(NetworkUpdateFunctions[ConnectionType],i);
			func(ConnectionType);
		end--]]
		--sb.logInfo("NETWORK FUNCTIONS = " .. sb.print(NetworkUpdateFunctions[ConnectionType]));
		for ID,Func in pairs(NetworkUpdateFunctions[ConnectionType]) do
			--sb.logInfo("CALLING FUNC OF = " .. sb.print(ID));
			if ID ~= nil and Func ~= nil then
				NetworkUpdateFunctions[ConnectionType][ID] = nil;
				if world.entityExists(tonumber(ID)) then
					Func(ConnectionType);
				end
			end
		end
		--[[for ID in pairs(NetworkUpdateFunctions[ConnectionType]) do
			if ID ~= nil then
				NetworkUpdateFunctions[ConnectionType][ID] = nil;
			end
		end--]]
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
	if NetworkCache[ConnectionType] == nil or NetworkCache[ConnectionType].NeedsUpdating == true then
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
			
			NewPath[#NewPath + 1] = Path[i].ID;
		end
		return NewPath;
	end
end

--Checks if all the conduits in the Path are occluded (ie, behind a block)
function ConduitCore.PathIsOccluded(path)
	for _,id in ipairs(path) do
		if not world.entityExists(id) or world.callScriptedEntity(id,"ConduitCore.Occluded") ~= true then
			return false;
		end
	end
	return true;
end

--Returns true if the network has changed
function ConduitCore.NetworkHasChanged(ConnectionType)
	--sb.logInfo("THE CACHE is = " .. sb.print(NetworkCache[ConnectionType]));
	--if NetworkCache[ConnectionType] == nil or NetworkCache[ConnectionType].NeedsUpdating == true then
		--sb.logInfo("NETWORK HAS CHANGED_____________");
	--end
	return NetworkCache[ConnectionType] == nil or NetworkCache[ConnectionType].NeedsUpdating == true;
end

--Returns the Entire Connection Tree for the Passed In Connection Type
function ConduitCore.GetNetwork(ConnectionType)
	if ConnectionTypes[ConnectionType] == nil then
		return nil;
	end
	UsingNetworkForType[ConnectionType] = true;
	--sb.logInfo("CACHE = " .. sb.print(NetworkCache[ConnectionType]));
	if NetworkCache[ConnectionType] ~= nil and NetworkCache[ConnectionType].NeedsUpdating == false then
		--sb.logInfo("RETURNING CACHE");
		return NetworkCache[ConnectionType].Normal;
	end
	local Findings = {};
	local FindingsWithPath = {};
	local Next = {{ID = SourceID}};
	repeat
		local NewNext = {};
		for i=1,#Next do
			local Connections;
			if world.entityExists(Next[i].ID) then
				Connections = world.callScriptedEntity(Next[i].ID,"ConduitCore.GetConnectionsWithExtra",ConnectionType);
			else
				goto ContinueWithoutAddition;
			end
			if Connections == nil or Connections == false then goto Continue end;
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
					for k=1,#NewNext do
						if NewNext[k].ID == connection then
							goto NextConnection;
						end
					end
					--sb.logInfo("Adding New Connection " .. sb.print(connection));
					NewNext[#NewNext + 1] = {ID = connection,Previous = Next[i]};
				end
				::NextConnection::
			end
			::Continue::
			--sb.logInfo("New Finding = " .. sb.print(Next[i].ID));
			Findings[#Findings + 1] = Next[i].ID;
			FindingsWithPath[#FindingsWithPath + 1] = Next[i];
			::ContinueWithoutAddition::
		end
		--sb.logInfo("New Next = " .. sb.print(NewNext));
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
		NetworkCache[ConnectionType].NeedsUpdating = false;
	end
	for i=1,#Findings do
		if Findings[i] ~= SourceID and world.entityExists(Findings[i]) then
			world.callScriptedEntity(Findings[i],"__ConduitCore__.AddOnNetworkChangeFunc",SourceID,NetworkChange,ConnectionType);
		end
	end
	--sb.logInfo("NEW FINDINGS = " .. sb.print(Findings));
	return Findings;
end
--Gets the Current Connections for the "Conduit" Connection Type
function ConduitCore.GetConduitConnections()
	return ConduitCore.GetConnections("Conduits");
end

--Gets the Current Connections for the Passed In Connection Type, returns false if the First Update Hasn't been completed
function ConduitCore.GetConnections(ConnectionType)
	--sb.logInfo("FIRST UPDATE = " .. sb.print(FirstUpdateComplete));
	if FirstUpdateComplete and ConnectionTypes[ConnectionType] ~= nil then
		return ConnectionTypes[ConnectionType].Connections;
	end
	if FirstUpdateComplete == false then
		return false;
	end
	return false;
end

--Returns true if there are any connections
function ConduitCore.HasConnections(ConnectionType)
	if FirstUpdateComplete and ConnectionType[ConnectionType] ~= nil and #ConnectionTypes[ConnectionType].Connections > 0 then
		return true;
	else
		return false;
	end
end

--Returns true if the Conduit is fully loaded
function ConduitCore.FullyLoaded()
	return FirstUpdateComplete;
end

--Sets the function that is called when the sprite needs to be updated
function ConduitCore.SetSpriteFunction(func)
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
	if not IsOccluded and DefaultAnimated then
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
end

--Gets the current sprite state of the conduit, returns nil if this is occluded or isn't animating
function ConduitCore.GetSpriteState()
	if not IsOccluded and DefaultAnimated then
		return animator.animationState("cable");
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

--Gets the number of connection Points
function ConduitCore.NumOfConnectionPoints()
	return NumOfConnections;
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

--Adds a function that is called when the network is needed
--The function should return any Object IDs that should be part of the network
function ConduitCore.AddExtraPathFunction(connectionType,func)
	if ExtraPathFunctions[connectionType] == nil then
		ExtraPathFunctions[connectionType] = {func};
	else
		ExtraPathFunctions[connectionType][#ExtraPathFunctions[connectionType] + 1] = func;
	end
end

--Similar to ConduitCore.GetConnections but also includes the ExtraPathFunctions
function ConduitCore.GetConnectionsWithExtra(connectionType)
	if ExtraPathFunctions[connectionType] == nil then
		return ConduitCore.GetConduitConnections(connectionType);
	else
		local Final = {};
		local Connections = ConduitCore.GetConnections(connectionType);
		if Connections ~= nil and Connections ~= false then
			for _,connection in ipairs(Connections) do
				if connection ~= 0 then
					Final[#Final + 1] = connection;
				end
			end
		end
		for _,func in ipairs(ExtraPathFunctions[connectionType]) do
			local NewConnections = func(connectionType);
			if type(NewConnections) == "table" then
				for _,connection in ipairs(NewConnections) do
					if connection ~= 0 then
						Final[#Final + 1] = connection;
					end
				end
			else
				NewConnections[#NewConnections + 1] = NewConnections;
			end
		end
		return Final;
	end
end

--Gets the all the connection points, ignoring any ConnectionTypes
function ConduitCore.GetGlobalConnections()
	return Connections;
end

--Gets the Object based upon the connection point
GetObjectByConnectionPoint = function(pointIndex)
	--local Object = world.objectAt({SourcePosition[1] + ConnectionPoints[i][1],SourcePosition[2] + ConnectionPoints[i][2]});
	local ConnectionPoint = ConnectionPoints[pointIndex];
	local Type = type(ConnectionPoint);
	if Type == "table" then
		return world.objectAt({SourcePosition[1] + ConnectionPoint[1],SourcePosition[2] + ConnectionPoint[2]});
	elseif Type == "number" then
		return Type;
	elseif Type == "function" then
		local Value = ConnectionPoint();
		local ValueType = type(Value);
		if ValueType == "table" then
			return world.objectAt({SourcePosition[1] + Value[1],SourcePosition[2] + Value[2]});
		else
			return Value;
		end
	end
	return nil;
end

--Uninitializes the Conduit
function ConduitCore.Uninitialize()
	if Uninitialized == true then return nil else Uninitialized = true end;
	if Dying == true then
		for connectionType,_ in ipairs(ConnectionTypes) do
			if UsingNetworkForType[connectionType] == true then
				for _,finding in ipairs(ConduitCore.GetNetwork(connectionType)) do
					if world.entityExists(finding) then
						world.callScriptedEntity(finding,"__ConduitCore__.RemoveOnNetworkChangeFunc",SourceID,connectionType);
					end
				end
			end
		end
		UpdateOtherConnections();
	end
end

--Set this conduit as a facade
function ConduitCore.SetAsFacade(Indicator,Occluded,DropItem)
	Facade = true;
	FacadeIndicator = Indicator;
	if DropItem ~= nil then
		if type(DropItem) == "table" then
			FacadeDropItem = DropItem;
		else
			FacadeDropItem = {name = DropItem,count = 1};
		end
	end
	IsOccluded = Occluded or false;
end

--Returns whether this conduit is facaded
function ConduitCore.Facaded()
	return Facade;
end

--Returns whether this facaded conduit is occluded
function ConduitCore.Occluded()
	return IsOccluded;
end

--Returns the facade Indicator
function ConduitCore.FacadeIndicator()
	return FacadeIndicator;
end

--Destroys the conduit and drops any items at the position specified
function ConduitCore.Destroy(ItemDropPosition)
	DroppingPosition = ItemDropPosition;
	if Facade then
		object.smash();
	else
		object.setHealth(0);
	end
end

--Destroys the conduit without dropping anything
function ConduitCore.Smash()
	DroppingItems = false;
	object.smash(true);
end

--Sets the Item Drop Position
function ConduitCore.SetDropPosition(position)
	DroppingPosition = position;
end

--Drops the conduit and saves some of it's parameters to the DropItem
function ConduitCore.DropAndSaveParameters(DropItem,dropPosition)
	SaveSettings.IsSaving = true;
	SaveSettings.Position = dropPosition;
	if DropItem ~= nil and type(DropItem) ~= "table" then
		DropItem = {name = DropItem,count = 1};
	end
	SaveSettings.Item = DropItem or FacadeDropItem or {name = object.name(),count = 1};
	ConduitCore.Smash();
end

--Adds a parameter that will be saved onto the Item
function ConduitCore.AddSaveParameter(name,value)
	SaveSettings.Parameters[name] = value;
end

--Sets the display name of the saved resulting Item
function ConduitCore.SetSaveName(name)
	SaveSettings.DisplayName = name;
end

--Adds a color outline to the Saved Drop Item (color is in hex)
function ConduitCore.AddColorToSavedItem(color)
	SaveSettings.Color = color;
end

--Returns whether the conduit's parameters are being saved
function ConduitCore.IsSavingParameters()
	return SaveSettings.IsSaving;
end

--Adds a function that is called when the conduit is initialized with save parameters for the first time
function ConduitCore.AddSaveInitFunction(func)
	OnSaveRetrieveFunctions[#OnSaveRetrieveFunctions + 1] = func;
end

--Returns the positions that the object occupies
function ConduitCore.GetAllSpaces(object)
	local Pos = world.entityPosition(object);
	local Spaces = world.objectSpaces(object);
	local Final = {};
	for _,space in ipairs(Spaces) do
		Final[#Final + 1] = {Pos[1] + space[1],Pos[2] + space[2]};
	end
	return Final;
end

--Called when the object is Dying
Die = function()
	
	
	
	if Facade and not SaveSettings.IsSaving and DroppingItems and FacadeDropItem ~= nil then
		world.spawnItem(FacadeDropItem,DroppingPosition or SourcePosition,1);
	end
	if SaveSettings.IsSaving then
		--TODO -- Save Certain Parameters to the Item
		local Parameters = {
			__SavedValueNames = {};
		};
		for name,value in pairs(SaveSettings.Parameters) do
			Parameters[name] = value;
			Parameters.__SavedValueNames[#Parameters.__SavedValueNames + 1] = name;
		end
		if SaveSettings.DisplayName ~= nil and SaveSettings.DisplayName ~= "" then
			Parameters.__OriginalDisplayName = config.getParameter("shortdescription");
			Parameters.shortdescription = SaveSettings.DisplayName;
		end
		if SaveSettings.Color ~= nil then
			local Icon = config.getParameter("__OriginalIcon") or config.getParameter("inventoryIcon");
			Parameters.inventoryIcon = Icon .. "?border=1;" .. SaveSettings.Color .. "?fade=007800;0.1";
			Parameters.__OriginalIcon = Icon;
		end
		Parameters.__HasSavedParameters = true;
		if Facade then
			Parameters.__ParametersWithFacade = FacadeDropItem.name;
		end
		--[[Parameters.__ExtraValueNames = {};
		if Parameters.__OriginalDisplayName ~= nil then
			Parameters.ExtraValueNames[#Parameters.ExtraValueNames + 1] = "_OriginalDisplayName";
			Parameters.ExtraValueNames[#Parameters.ExtraValueNames + 1] = "shortdescription";
		end
		if SaveSettings.Color ~= nil then
			Parameters.ExtraValueNames[#Parameters.ExtraValueNames + 1] = "__OriginalIcon";
			Parameters.ExtraValueNames[#Parameters.ExtraValueNames + 1] = "inventoryIcon";
		end--]]

		
		
		
		
		
		world.spawnItem(SaveSettings.Item.name,SaveSettings.Position or DroppingPosition or SourcePosition,SaveSettings.Item.count,Parameters);
	end
end

--Iterates through the connection points and returns a position vector for each
ConnectionPointIter = function()
	local k = 0;
	local Max = #ConnectionPoints;
	return function()
		::Continue::
		k = k + 1;
		if k <= Max then
			local Type = type(ConnectionPoints[k]);
			if Type == "table" then
				return ConnectionPoints[k];
			elseif Type == "number" then
				return world.entityPosition(ConnectionPoints[k]);
			elseif Type == "function" then
				local Value = ConnectionPoint();
				local ValueType = type(Value);
				if ValueType == "table" then
					return Value;
				else
					return world.entityPosition(Value);
				end
			end
			goto Continue;
		end
	end
end

--Returns the UI of this Conduit, or nil if there isn't one
--Returns the Interaction Type and the Json Data
function ConduitCore.GetUI()
	local Type,Interaction;
	if onInteraction ~= nil then
		local Data = onInteraction();
		Type,Interaction = Data[1],Data[2];
	end
	if Type == nil or Interaction == nil then
		Type = config.getParameter("interactAction");
		if Type ~= nil then
			local Link = config.getParameter("interactData");
			if Link ~= nil then
				--Interaction = root.assetJson(Link);
				--sb.logInfo("INTERACTION == " .. sb.print(Link));
				return {Type = Type,Link = Link};
			end
		end
	else
		--sb.logInfo("INTERACTION == " .. sb.print(Interaction));
		return {Type = Type,Interaction = Interaction};
	end
	return nil;
end



