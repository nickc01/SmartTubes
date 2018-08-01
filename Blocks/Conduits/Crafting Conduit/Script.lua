require("/Core/ConduitCore.lua");

--Variables

--Functions
local GetUIInfoOfObject;

--The Init function for the crafting conduit
function init()
	ConduitCore.Initialize();
	ConduitCore.AddConnectionType("Crafting",function(ID)
		local Interaction = GetUIInfoOfObject(ID);
		if Interaction ~= nil and Interaction[1] == "OpenCraftingInterface" then
			return true;
		end
		return false;
	end);
end

--The Update function for the crafting conduit
function update(dt)

end

--The Die function for the crafting conduit
function die()

end

--The Uninit function for the crafting conduit
function uninit()

end

GetUIInfoOfObject = function(ID)
	if world.entityExists(ID) then
		local Interaction = world.callScriptedEntity(ID,"onInteraction",OnInteractData);
		if Interaction ~= nil then
			return Interaction;
		else
			local InteractAction = world.getObjectParameter(ID,"interactAction");
			if InteractAction ~= nil then
				return {InteractAction,world.getObjectParameter(ID,"interactData")};
			else
				return nil;
			end
		end
	end
	return nil;
end