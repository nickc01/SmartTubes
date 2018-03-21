require("/Core/Conduit Scripts/ExtractionUI.lua");

--Variables

--Functions
local ConfigUpdate;

--Initializes the Extraction Conduit UI
function init()
	ExtractionUI.AddOnConfigUpdateFunction(ConfigUpdate);
	ExtractionUI.Initialize();
end


--Called when the Config is updated
ConfigUpdate = function(NewConfig)
	NewConfig[#NewConfig + 1] = {
		itemName = "perfectlygenericitem",
		insertID = "any",
		takeFromSide = "any",
		insertIntoSide = "any",
		takeFromSlot = "any",
		insertIntoSlot = "any",
		amountToLeave = 0,
		isSpecific = false
	}
	ExtractionUI.DisplayConfigs();
end

--Uninitializes the Extraction UI
function uninit()
	ExtractionUI.Uninitialize();
end

--Called when the item box is clicked
function itemBox()
	ExtractionUI.SetItemInSlot(player.swapSlotItem());
	--[[local Item = player.swapSlotItem();
	if Item ~= nil then
		Item.count = 1;
	end
	pane.playSound("/sfx/interface/item_pickup.ogg");--]]
end

--Called when the item box is right clicked
function itemBoxRight()
	--widget.setItemSlotItem("itemBox",nil);
	ExtractionUI.SetItemInSlot(nil);
end

--Called when the "Add" button is clicked
function Add()
	ExtractionUI.AddNewConfig();
end
