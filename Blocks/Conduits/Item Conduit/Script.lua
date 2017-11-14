local Cables;
local EntityID;

function init()
	--sb.logInfo("A = " .. sb.print(A));
	--sb.logInfo("B = " .. sb.print(B));
	--sb.logInfo("C = " .. sb.print(C));
	--sb.logInfo("D = " .. sb.print(D));
	--sb.logInfo("ITEM CONDUIT INIT");
	EntityID = entity.id();
	--sb.logInfo("INIT of " .. sb.print(EntityID));
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	--Cables.Initialize();
end

function die()
	Cables.Uninitialize();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	end
end

--[[function uninit()
	sb.logInfo("UNINIT");
	--Cables.Uninitialize();
	--sb.logInfo("Exists = " .. sb.print(world.entityExists(EntityID)));
	--sb.logInfo("ITEM CONDUIT UNINIT");
end--]]
