require("/Core/Conduit Scripts/Wireless.lua");
require("/Core/ConduitCore.lua");

--Variables

--Functions
local TraversalPathFunction;

--Init function for wireless receiving conduit
function init()
	ConduitCore.Initialize();
	ConduitCore.SetTraversalFunction(TraversalPathFunction);
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
