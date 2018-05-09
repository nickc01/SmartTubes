require("/Core/Conduit Scripts/Wireless.lua");
require("/Core/ConduitCore.lua");

--Variables

--Functions
local TraversalPathFunction;
local ExtraPathFunction;
local OnNodeChangeFunction;

--Init function for wireless receiving conduit
function init()
	ConduitCore.Initialize();
	ConduitCore.SetTraversalFunction(TraversalPathFunction);
	Wireless.AddNodeChangeFunction(OnNodeChangeFunction);
	ConduitCore.AddExtraPathFunction("TerminalFindings",ExtraPathFunction);
end

--Any extra connections for the terminal to find
ExtraPathFunction = function()
	if ConnectedConnections == nil then
		local Connections = Wireless.GetInputConnections();
		ConnectedConnections = {};
		if Connections ~= nil then
			for _,i in ipairs(Connections) do
				if world.getObjectParameter(i,"conduitType") == "sender" then
					ConnectedConnections[#ConnectedConnections + 1] = i;
				end
			end
		end
	end
	return ConnectedConnections;
end

TraversalPathFunction = function(SourceTraversalID,PreviousPosition,PreviousID,Speed)
	local EndPosition = entity.position();
	if Wireless.IsConnectedToInput(PreviousID) then
		return function(dt)
			world.callScriptedEntity(SourceTraversalID,"Traversal.Respawn",{EndPosition[1] + 0.5,EndPosition[2] + 0.5});
			return nil;
		end
	else
		if ConduitCore.IsConnectedToConduit(PreviousID) then
			return ConduitCore.GetDefaultTraversalFunction()(SourceTraversalID,PreviousPosition,PreviousID,Speed);
		end
	end
end

--Called when the Wireless Connections are changed
OnNodeChangeFunction = function()
	ConnectedConnections = nil;
end
