local Cables;
local EntityID;
local Recipes;

function init()
	EntityID = entity.id();
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddCondition("Crafters","category",function(value) return value == "crafting" end);
	message.setHandler("SetRecipes",function(_,_,value)
		sb.logInfo("VALUE = " .. sb.print(value));
		Recipes = value;
		object.setConfigParameter("Recipes",value);
	end);
	Recipes = config.getParameter("Recipes",{});
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
