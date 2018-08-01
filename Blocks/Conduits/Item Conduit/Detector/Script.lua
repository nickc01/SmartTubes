require("/Core/ConduitCore.lua");

--Variables
--local Enabled = true;
local TraversalsCounted = 0;

--Functions
--local Enable;

function init()
	ConduitCore.Initialize();
	--[[local InputCount = object.inputNodeCount();
	if InputCount > 0 then
		ConduitCore.SetTraversalFunction(TraversalPathFunction);
		onNodeConnectionChange();
	end--]]
	ConduitCore.SetTraversalFunction(TraversalPathFunction);
end

TraversalPathFunction = function(SourceTraversalID,StartPosition,PreviousID,Speed)
	--onNodeConnectionChange();
	local EndPosition = entity.position();
	local Time = 0;
	local Added = false;
	--if Enabled == true then
		return function(dt)
			Time = Time + dt * Speed;
			if Time >= 1 then
				TraversalsCounted = TraversalsCounted - 1;
				sb.logInfo("TraversalsCounted2 = " .. sb.print(TraversalsCounted));
				if TraversalsCounted == 0 then
					sb.logInfo("Output = false");
					object.setAllOutputNodes(false);
				end
				return {EndPosition[1] + 0.5,EndPosition[2] + 0.5},nil,true;
			else
				if Time >= 0.75 / (Speed) then
					if Added == false then
						Added = true;
						TraversalsCounted = TraversalsCounted + 1;
						sb.logInfo("TraversalsCounted1 = " .. sb.print(TraversalsCounted));
						if TraversalsCounted == 1 then 
							sb.logInfo("Output = true");
							object.setAllOutputNodes(true);
						end
					end
				end
				return {0.5 + StartPosition[1] + (EndPosition[1] - StartPosition[1]) * Time,0.5 + StartPosition[2] + (EndPosition[2] - StartPosition[2]) * Time};
			end
		end
	--end
end

