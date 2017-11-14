local Cables;

function init()
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	--Cables.Initialize();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	end
end

function die()
	Cables.Uninitialize();
end
