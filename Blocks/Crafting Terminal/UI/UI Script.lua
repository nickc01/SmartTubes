require("/Core/Conduit Scripts/Crafting Terminal/CraftingUI.lua");
--Variables

--Functions
local SlotClick;
local SlotRightClick;

--The init function for the Crafting Terminal UI Script
function init()
	CraftingUI.Callbacks["SlotClick"].Add(SlotClick);
	CraftingUI.Callbacks["SlotRightClick"].Add(SlotRightClick);
	CraftingUI.Initialize();
end

--The update function for the Crafting Terminal UI Script
function update()

end

SlotClick = function(slot)
	sb.logInfo("Clicked on = " .. sb.print(slot));
	CraftingUI.SetSelectedItem(CraftingUI.GetSlotItem(slot));
end

SlotRightClick = function(slot)
	sb.logInfo("Right Clicked on = " .. sb.print(slot));
	CraftingUI.SetSelectedItem(nil);
end