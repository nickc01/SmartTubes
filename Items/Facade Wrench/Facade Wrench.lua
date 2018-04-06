require("/Core/Conduit Scripts/FacadeWrench.lua");

--Variables

--Functions

--The init function of the item
function init()
	if FacadeWrench.Initialize() then
		
	end
end

--[[function update(dt)
	UICore.SetIndex(UICore.GetIndex() + 1);
	sb.logInfo("Index = " .. sb.print(UICore.GetIndex()));
end--]]

--[[function ParamTest(...)
	local value = select(2,...);
	sb.logInfo("Value = " .. sb.print(value));
	sb.logInfo("Value Type = " .. sb.print(type(value)));
end--]]