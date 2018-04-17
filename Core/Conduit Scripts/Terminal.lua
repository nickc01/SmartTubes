require("/Core/ConduitCore.lua");
require("/Core/ServerCore.lua");

--Declaration

--Public Table
Terminal = {};
local Terminal = Terminal;

--Private Table, PLEASE DONT TOUCH
__Terminal__ = {};
local __Terminal__ = __Terminal__;

--Variables
local SourceID;
local SourcePosition;

local Data = {};

--Functions
local PostInit;
local ConduitNetworkUpdate;
local Update;
local IsInList;

--Initializes the Terminal
function Terminal.Initialize()
	SourceID = entity.id();
	sb.logInfo("SOURCEID = " .. sb.print(SourceID));
	SourcePosition = entity.position();
	local OldUpdate = update;
	sb.logInfo("Setting UPdate Function");
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
	Server.SetDefinitionTable(Data);
	ConduitCore.AddPostInitFunction(PostInit);
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.Initialize();
end

--The Update Loop for the Terminal
Update = function(dt)
	--sb.logInfo("UPDATE 1");
	if ConduitCore.NetworkHasChanged("Conduits") and Data.SetNetwork ~= nil then
		local Network = ConduitCore.GetConduitNetwork();
		local Containers = {
			Extraction = {},
			Insertion = {},
			IO = {}
		}
		for _,conduit in ipairs(Network) do
			if world.entityExists(conduit) then
				local ConnectedContainers = world.callScriptedEntity(conduit,"ConduitCore.GetConnections","Containers");
				if ConnectedContainers ~= nil then
					local Extraction = world.callScriptedEntity(conduit,"Extraction.IsExtraction");
					local Insertion = world.callScriptedEntity(conduit,"Insertion.IsInsertion");
					for _,container in ipairs(ConnectedContainers) do
						if container ~= 0 then
							if Extraction == true and Insertion == true and not IsInList(Containers.IO,container) then
								Containers.IO[#Containers.IO + 1] = container;
							elseif Extraction == true and not IsInList(Containers.Extraction,container) then
								Containers.Extraction[#Containers.Extraction + 1] = container;
							elseif Insertion == true and not IsInList(Containers.Insertion,container) then
								Containers.Insertion[#Containers.Insertion + 1] = container;
							end
						end
					end
				end
			end
		end
		sb.logInfo("ALL NETWORK CONTAINERS = " .. sb.printJson(Containers,1));
		Data.SetNetworkContainers(Containers);
		Data.SetNetwork(ConduitCore.GetConduitNetwork());
	end
end

--Returns true if the item is contained inside of the table, and false otherwise
IsInList = function(tbl,item)
	for i=1,#tbl do
		if tbl[i] == item then
			return true;
		end
	end
	return false;
end

--The Post Init Function, called after the first update in ConduitCore
PostInit = function()
	sb.logInfo("POST INIT");
	Server.DefineSyncedValues("ConduitNetwork","Network",nil,"NetworkContainers",nil);
	sb.logInfo("DATA = " .. sb.print(Data));
	ConduitCore.AddNetworkUpdateFunction(ConduitNetworkUpdate);
	Server.SaveValuesOnExit("ConduitNetwork",false);
end

--Called when the conduit network is updated
ConduitNetworkUpdate = function()
	sb.logInfo("Conduit Network Update");
	--sb.logInfo("Conduit NETWORK = " .. sb.print(ConduitCore.GetConduitNetwork()));
	--Data.SetNetwork(ConduitCore.GetConduitNetwork());
end
