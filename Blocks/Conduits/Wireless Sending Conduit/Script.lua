require("/Core/Conduit Scripts/Wireless.lua");
require("/Core/ConduitCore.lua");

--Variables
local ConnectedConnections;

--Functions
local ExtraPathFunction;
local OnNodeChangeFunction;

--Init function for wireless sending conduit
function init()
	ConduitCore.Initialize();
	ConduitCore.AddExtraPathFunction("Conduits",ExtraPathFunction);
	ConduitCore.AddExtraPathFunction("TerminalFindings",ExtraPathFunction);
	Wireless.AddNodeChangeFunction(OnNodeChangeFunction);
	
end

--Called when the network path is needed
ExtraPathFunction = function()
	--if ConnectedConnections == nil then
		local Connections = Wireless.GetOutputConnections();
		ConnectedConnections = {};
		if Connections ~= nil then
			for _,i in ipairs(Connections) do
				if world.getObjectParameter(i,"conduitType") == "receiver" then
					ConnectedConnections[#ConnectedConnections + 1] = i;
				end
			end
		end
	--end
	return ConnectedConnections;
end

function GetReceivingConnections()
	return ExtraPathFunction();
end

--Called when the Wireless Connections are changed
OnNodeChangeFunction = function()
	ConnectedConnections = nil;
	sb.logInfo("Nodes Changed = " .. sb.print(entity.id()));
end