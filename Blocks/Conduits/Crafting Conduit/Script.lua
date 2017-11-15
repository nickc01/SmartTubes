local Cables;
local EntityID;

function init()
	EntityID = entity.id();
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddCondition("Crafters","category",function(value) return value == "crafting" end);
end

function die()
	Cables.Uninitialize();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	else
		Cables.Update();
	end
end
