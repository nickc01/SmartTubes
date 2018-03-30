require("/Core/Conduit Scripts/FacadeWrench.lua");

--Variables

--Functions

--The init function of the item
function init()
	if FacadeWrench.Initialize() then
		sb.logInfo("INIT");
		UICore.SetAsSyncedValues("testGroup",activeItem.ownerEntityId(),"value1",2,"value2",nil,"value3",6,nil,nil,"value5");
	end
end

--[[function ParamTest(...)
	local value = select(2,...);
	sb.logInfo("Value = " .. sb.print(value));
	sb.logInfo("Value Type = " .. sb.print(type(value)));
end--]]