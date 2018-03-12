require("/Core/ConduitCore.lua");

--Definition

--Public Table
Groups = {};
local Groups = Groups;

--Private Table. PLEASE DONT TOUCH

__Groups__ = {};
local __Groups__ = __Groups__;

--Variables
local SourceID;
local SourcePosition;
local NeighborPoints = {{0,1},{0,-1},{-1,0},{1,0}};
local ConnectionType = "Containers";
local GroupUpdateFunctions = {};
local GroupRemovalFunctions = setmetatable({},{__call = function(tbl,Object,Connections,OldMaster,NewMaster)
	for k,i in ipairs(tbl) do
		i(Object,Connections,OldMaster,NewMaster);
	end end});
local GroupAdditionFunctions = setmetatable({},{__call = function(tbl,Object,Connections,Master)
	for k,i in ipairs(tbl) do
		i(Object,Connections,Master);
	end end});
local GroupMasterChangeFunctions = setmetatable({},{__call = function(tbl,Object,OldMaster,NewMaster)
	for k,i in ipairs(tbl) do
		i(Object,OldMaster,NewMaster);
	end end});
local GroupID = 1;

local GroupConnections = {};
local GroupDictionary = setmetatable({},{
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

--Functions
local GroupUpdate;
local GetNeighborsOf;
local GetRegionAroundPoints;

--Initializes the Groups
function Groups.Initialize()
	SourceID = entity.id();
	SourcePosition = entity.position();
	ConduitCore.AddConnectionUpdateFunction(function()
		sb.logInfo("Connection Update");
		Groups.Update();
	end);
end

GroupUpdate = function()
	--sb.logInfo("GroupUpdate");
	for i=1,#GroupUpdateFunctions do
		GroupUpdateFunctions[i]();
	end
	--sb.logInfo("Groups All = " .. sb.print(GroupConnections));
end

--Sets the Neighbor Points for Scanning
function Groups.SetNeighborPoints(points)
	NeighborPoints = points;
end

--Sets the Connection Type to use when retrieving the groups
function Groups.SetConnectionType(connectionType)
	ConnectionType = connectionType;
end

--Adds a function that is called when the group is updated
function Groups.OnUpdateFunction(func)
	GroupUpdateFunctions[#GroupUpdateFunctions + 1] = func;
end

--Sets an id that is used to find the right neighbors
function Groups.SetGroupID(id)
	GroupID = id;
end

--Gets the id that is used to find the right neighbors
function Groups.GetGroupID()
	--sb.logInfo("Getting ID");
	return GroupID;
end

--Returns true if it's the master connection of the ID
function Groups.IsMasterOf(id)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			if GroupConnections[GroupDictionary[id]].Master == SourceID then
				return true;
			else
				return false;
			end
		end
	--end
	return false;
end
--Returns the master of the neighbor
function Groups.GetMasterID(neighborID)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[neighborID] ~= nil then
			return GroupConnections[GroupDictionary[neighborID]].Master;
		end
	--end
end

--Returns an object reference to the master
function Groups.GetMaster(neighborID)
	local MasterID = Groups.GetMasterID(neighborID);
	if MasterID ~= nil then
		return world.callSciptedEntity(MasterID,"__Groups__.GetENV");
	end
end

--Gets all the connections to the neighbor
function Groups.GetConnections(neighborID)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			return GroupConnections[GroupDictionary[id]].Connections;
		end
	--end
end

--Gets the _ENV table for the Object
function __Groups__.GetENV()
	return _ENV;
end

--Sets the Master connection for the id
function __Groups__.SetMasterSelf(id,MasterID)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			local group = GroupConnections[GroupDictionary[id]];
			GroupMasterChangeFunctions(id,group.Master,MasterID);
			sb.logInfo(sb.print(SourceID) .. " is setting it's master 4 in" .. sb.print(id) .. " to = " .. sb.print(MasterID));
			--object.say("Master = " .. sb.print(SourceID));
			group.Master = MasterID;
			return nil;
		end
	--end
end

--Sets the Master connection for the id
function __Groups__.SetMaster(id,MasterID)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			local group = GroupConnections[GroupDictionary[id]];
			--Call Master Change Functions
			--for k,i in ipairs()
			GroupMasterChangeFunctions(id,group.Master,MasterID);
			group.Master = MasterID;
			sb.logInfo(sb.print(SourceID) .. " is setting it's master 3 in" .. sb.print(id) .. " to = " .. sb.print(MasterID));
			--object.say("Master = " .. sb.print(MasterID));
			for _,i in ipairs(group.Connections) do
				if i ~= SourceID then
					world.callScriptedEntity(i,"__Groups__.SetMasterSelf",id,MasterID);
				end
			end
			return nil;
		end
	--end
end

--Gets a new master that can be used, returns nil if there isn't one
function __Groups__.GetNewPossibleMaster(id)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			for _,i in ipairs(GroupConnections[GroupDictionary[id]].Connections) do
				if i ~= SourceID then
					return i;
				end
			end
			return nil;
		end
	--end
end

--Adds a connection to a group
function __Groups__.AddConnection(id,newConnection)
	--for _,group in ipairs(GroupConnections) do
		if GroupDictionary[id] ~= nil then
			local group = GroupConnections[GroupDictionary[id]];
			for k,i in ipairs(group.Connections) do
				if i == newConnection then return nil end;
			end
			sb.logInfo(sb.print(SourceID) .. " adding " .. sb.print(newConnection) .. " to " .. sb.print(id));
			group.Connections[#group.Connections + 1] = newConnection;
		end
	--end 
end

--Removes a connection to a group
function __Groups__.RemoveConnection(id,newConnection)
--	sb.logInfo("T");
	--for _,group in ipairs(GroupConnections) do
		--sb.logInfo("U");
		if GroupDictionary[id] ~= nil then
			local group = GroupConnections[GroupDictionary[id]];
			--sb.logInfo("V");
			for k,i in ipairs(group.Connections) do
			--	sb.logInfo("W");
				if i == newConnection then
					--sb.logInfo("X");
					sb.logInfo(sb.print(SourceID) .. " removing " .. sb.print(newConnection) .. " from " .. sb.print(id));
					table.remove(group.Connections,k);
					return nil;
				end
			end
		end
	--end 
end

--Adds a function that is called when a group is removed
function Groups.AddGroupRemovalFunction(func)
	GroupRemovalFunctions[#GroupRemovalFunctions + 1] = func;
end

--Adds a function that is called when a group is added
function Groups.AddGroupAdditionFunction(func)
	GroupAdditionFunctions[#GroupAdditionFunctions + 1] = func;
end

--Adds a function that is called when a group's master is changed
function Groups.AddGroupMasterChangeFunction(func)
	GroupMasterChangeFunctions[#GroupMasterChangeFunctions + 1] = func;
end

--Updates the Groups
function Groups.Update()
	sb.logInfo("UPDATING");
	local PostFunctions = setmetatable({},{__newindex = function(tbl,k,value) if #tbl < 1 then return rawset(tbl,k,value) else return nil end end});
	local Connections = ConduitCore.GetConnections(ConnectionType);
	sb.logInfo("Connections = " .. sb.print(Connections));
	for ConnectionIndex,Connection in ipairs(Connections) do
		if GroupConnections[ConnectionIndex] == nil then
			GroupConnections[ConnectionIndex] = {
				Object = 0,
				Connections = {SourceID},
				Master = SourceID
			}
		end
		local SelectedGroup = GroupConnections[ConnectionIndex];
		if Connection ~= SelectedGroup.Object then
			--sb.logInfo("Changing Object " .. sb.print(SelectedGroup.Object) .. " to " .. sb.print(Connection));
			--Remove Self from previous Connection
			if SelectedGroup.Object ~= 0 then
				local PossibleMaster;
				if SelectedGroup.Master == SourceID then
					PossibleMaster = __Groups__.GetNewPossibleMaster(Connection);
				end
				for k,i in ipairs(SelectedGroup.Connections) do
					if i ~= SourceID then
						world.callScriptedEntity(i,"__Groups__.RemoveConnection",Connection,SourceID);
						if SelectedGroup.Master == SourceID then
							if PossibleMaster ~= nil then
								world.callScriptedEntity(i,"__Groups__.SetMasterSelf",Connection,PossibleMaster);
							end
						end
					end
				end
				--Call Removal Functions
				--sb.logInfo("SelectedGroup = " .. sb.print(SelectedGroup));
				GroupRemovalFunctions(SelectedGroup.Object,SelectedGroup.Connections,SelectedGroup.Master,PossibleMaster);
				--[[for k,i in ipairs(GroupRemovalFunctions) do
					i(SelectedGroup.Object,SelectedGroup.Connections,SelectedGroup.Master,PossibleMaster);
				end--]]
			end

			--Scan for other connections and get master
			if Connection ~= 0 then
				local Neighbors = GetNeighborsOf(Connection);
				SelectedGroup.Object = Connection;
				SelectedGroup.Connections = GetNeighborsOf(Connection);
				GroupDictionary[Connection] = ConnectionIndex; 
				local Master = nil;
				--Get Master
				for k,i in ipairs(SelectedGroup.Connections) do
					if i ~= SourceID and world.callScriptedEntity(i,"Groups.IsMasterOf",Connection) == true then
						Master = i;
						break;
					end
				end
				--If no master was found
				if Master == nil then
					--__Groups__.SetMaster(Connection,SourceID);
					--sb.logInfo(sb.print(SourceID) .. " is setting it's master 1 in" .. sb.print(Connection) .. " to = " .. sb.print(SourceID));
					--object.say("Master = " .. sb.print(SourceID));
					SelectedGroup.Master = SourceID;
				else
					--sb.logInfo(sb.print(SourceID) .. " is setting it's master 2 in" .. sb.print(Connection) .. " to = " .. sb.print(Master));
					--object.say("Master = " .. sb.print(Master));
					SelectedGroup.Master = Master;
				end
				for k,i in ipairs(SelectedGroup.Connections) do
					if i ~= SourceID then
						world.callScriptedEntity(i,"__Groups__.AddConnection",Connection,SourceID);
					end
				end
				--Call Addition Functions
				GroupAdditionFunctions(SelectedGroup.Object,SelectedGroup.Connections,SelectedGroup.Master);
				--[[for k,i in ipairs(GroupAdditionFunctions) do
					i(SelectedGroup.Object,SelectedGroup.Connections,SelectedGroup.Master);
				end--]]
			else
				SelectedGroup.Object = 0;
				SelectedGroup.Connections = {SourceID};
				SelectedGroup.Master = SourceID;
				GroupDictionary[Object] = nil;
			end
			PostFunctions[#PostFunctions + 1] = GroupUpdate;
		end
		--end
	end
	if PostFunctions[1] ~= nil then
		PostFunctions[1]();
	end
end

--Returns a region that surrounds the points and moves the from the Absolute Position if specified
GetRegionAroundPoints = function(points,AbsolutePosition)
	local XLow,YLow,XHigh,YHigh;
	for i=1,#points do
		if XLow == nil or points[i][1] < XLow then
			XLow = points[i][1];
		end
		if XHigh == nil or points[i][1] > XHigh then
			XHigh = points[i][1];
		end
		if YLow == nil or points[i][2] < YLow then
			YLow = points[i][2];
		end
		if YHigh == nil or points[i][2] > YHigh then
			YHigh = points[i][2];
		end
	end
	if AbsolutePosition == nil then
		return {XLow - 1,YLow - 1,XHigh + 1,YHigh + 1};
	else
		return {XLow + AbsolutePosition[1] - 1,YLow + AbsolutePosition[2] - 1,XHigh + AbsolutePosition[1] + 1,YHigh + AbsolutePosition[2] + 1};
	end
end

--Gets the Neighbors of the Object using the Group ID
GetNeighborsOf = function(ObjectID)
	local Spaces = world.objectSpaces(ObjectID);
	local Region = GetRegionAroundPoints(Spaces,world.entityPosition(ObjectID));
	local AllObjects = world.objectLineQuery({Region[1],Region[2]},{Region[3],Region[4]});
	local Objects = {};
	for _,id in ipairs(AllObjects) do
		if world.callScriptedEntity(id,"Groups.GetGroupID") == GroupID and world.callScriptedEntity(id,"ConduitCore.IsConnectedGlobal",ObjectID) == true then
			Objects[#Objects + 1] = id;
		end
	end
	return Objects;
end

--Iterates all the groups
--[[function Groups.GroupIterator()
	if GroupConnections ~= nil then
		local func = ipairs(GroupConnections);
		return function()
			local k,i = func(GroupConnections);
			if i ~= nil then
				return i.Object,i.Connections,i.Master,k;
			else
				return nil;
			end
		end
	end
	return function()
		return nil;
	end
end--]]

--Called to uninitialize the groups
function Groups.Uninitialize()
	--if Connections ~= nil then
	--sb.logInfo("GroupConnections = " .. sb.print(GroupConnections));
	if GroupConnections ~= nil then
		for _,SelectedGroup in ipairs(GroupConnections) do
			--if GroupConnections[ConnectionIndex] ~= nil then
				--local SelectedGroup = GroupConnections[ConnectionIndex];
				--sb.logInfo("Selected Group = " .. sb.print(SelectedGroup));
				if SelectedGroup.Object ~= 0 then
					--sb.logInfo("A");
					for k,i in ipairs(SelectedGroup.Connections) do
						--sb.logInfo("B");
						if i ~= SourceID and world.entityExists(i) then
							--sb.logInfo("C");
							world.callScriptedEntity(i,"__Groups__.RemoveConnection",SelectedGroup.Object,SourceID);
							if SelectedGroup.Master == SourceID then
								--sb.logInfo("D");
								local PossibleMaster = __Groups__.GetNewPossibleMaster(SelectedGroup.Object);
								if PossibleMaster ~= nil then
									--sb.logInfo("E");
									sb.logInfo("PossibleMaster = " .. sb.print(PossibleMaster));
									world.callScriptedEntity(i,"__Groups__.SetMasterSelf",SelectedGroup.Object,PossibleMaster);
								end
								SelectedGroup.Master = PossibleMaster;
							end
						end
					end
				end
			--end
		end
	end
end

