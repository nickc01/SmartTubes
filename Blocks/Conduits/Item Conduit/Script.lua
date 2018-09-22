require("/Core/ConduitCore.lua");

--Variables
--local Enabled = true;

--Functions
--local Enable;

function init()
	ConduitCore.Initialize();
	--[[local InputCount = object.inputNodeCount();
	if InputCount > 0 then
		ConduitCore.SetTraversalFunction(TraversalPathFunction);
		onNodeConnectionChange();
	end--]]
end

--[[TraversalPathFunction = function(SourceTraversalID,StartPosition,PreviousID,Speed)
	onNodeConnectionChange();
	local EndPosition = entity.position();
	local Time = 0;
	if Enabled == true then
		return function(dt)
			Time = Time + dt * Speed;
			if Time >= 1 then
				return {EndPosition[1] + 0.5,EndPosition[2] + 0.5},nil,true;
			else
				return {0.5 + StartPosition[1] + (EndPosition[1] - StartPosition[1]) * Time,0.5 + StartPosition[2] + (EndPosition[2] - StartPosition[2]) * Time};
			end
		end
	end
end--]]

--[[function onInputNodeChange(args)
	onNodeConnectionChange();
end--]]

--[[function onNodeConnectionChange()
	sb.logInfo("Node Change");
	local InputCount = object.inputNodeCount();
	sb.logInfo("InputCount = " .. sb.print(InputCount));
	if InputCount == 0 then
		Enable(true);
	else	
		for i=0,InputCount - 1 do
			sb.logInfo("Node Level = " .. sb.print(object.getInputNodeLevel(i)));
			if object.getInputNodeLevel(i) == true then
				Enable(true);
				return nil;
			end
		end
		Enable(false);
	end
end--]]

--[[Enable = function(bool)
	sb.logInfo("Enabled = " .. sb.print(bool));
	if Enabled ~= bool then
		Enabled = bool;
		ConduitCore.EnableConnection("Conduits",bool);
	end
end--]]


