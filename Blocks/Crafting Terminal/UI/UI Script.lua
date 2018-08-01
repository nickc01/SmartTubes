require("/Core/Conduit Scripts/Crafting Terminal/CraftingUI.lua");
--Variables

--Functions
local SlotClick;
local SlotRightClick;

--The init function for the Crafting Terminal UI Script
function init()
	CraftingUI.Callbacks["SlotClick"] = SlotClick;
	CraftingUI.Callbacks["SlotRightClick"] = SlotRightClick;
	CraftingUI.Initialize();
end

--The update function for the Crafting Terminal UI Script
function update()

end

SlotClick = function(slot)
	sb.logInfo("Clicked on = " .. sb.print(slot));
end

SlotRightClick = function(slot)
	sb.logInfo("Right Clicked on = " .. sb.print(slot));

end