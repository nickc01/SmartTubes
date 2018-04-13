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

--Initializes the Terminal
function Terminal.Initialize()
	SourceID = entity.id();
	sb.logInfo("SOURCEID = " .. sb.print(SourceID));
	SourcePosition = entity.position();
	Server.SetDefinitionTable(Data);
	ConduitCore.AddPostInitFunction(PostInit);
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.Initialize();
end

--The Post Init Function, called after the first update in ConduitCore
PostInit = function()
	sb.logInfo("POST INIT");
	Server.DefineSyncedValues("ConduitNetwork","Network",nil);
	sb.logInfo("DATA = " .. sb.print(Data));
	Data.SetNetwork(ConduitCore.GetConduitNetwork());
	ConduitCore.AddNetworkUpdateFunction(ConduitNetworkUpdate);
	Server.SaveValuesOnExit("ConduitNetwork",false);
end

--Called when the conduit network is updated
ConduitNetworkUpdate = function()
	sb.logInfo("Conduit Network Update");
	sb.logInfo("Conduit NETWORK = " .. sb.print(ConduitCore.GetConduitNetwork()));
	Data.SetNetwork(ConduitCore.GetConduitNetwork());
end
