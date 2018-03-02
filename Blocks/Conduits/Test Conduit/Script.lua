--local Cables;
--local EntityID;
--ConduitCore.Initialize();

--[[function TestFunc()
	return "hello :)";
end--]]


function init()
	--sb.logInfo("INIT");
	--sb.logInfo("Delta = " .. sb.print(script.updateDt()));
	--[[message.setHandler("THISISATEST",function(messageName,isLocal,funcTest)
		sb.logInfo("Result of FuncTest = " .. sb.print(funcTest()));
	end);
	world.sendEntityMessage(entity.id(),"THISISATEST",TestFunc);--]]
	--world.callScriptedEntity(entity.id(),"CallFunction",TestFunc);
	ConduitCore.Initialize();
	--EntityID = entity.id();
	--[[Cables = CableCore;
	if Cables == nil then
		Cables = ConduitCore;
	end--]]
	--Cables.Initialize();
	--Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
end

--[[function CallFunction(func)
	sb.logInfo("TestFunc = " .. sb.print(func()));
end--]]

--[[function die()
	Cables.Uninitialize();
end--]]

--[[local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	end
end--]]
