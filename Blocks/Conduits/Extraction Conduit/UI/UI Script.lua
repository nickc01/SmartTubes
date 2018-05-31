require("/Core/Conduit Scripts/ExtractionUI.lua");

--Variables
local OldInit = init;
local OldUninit = uninit;

--Functions
local ConfigUpdate;
local CopyBufferChange;

--Initializes the Extraction Conduit UI
function init()
	widget.setButtonEnabled("pasteButton",false);
	if OldInit ~= nil then
		OldInit();
	end
	ExtractionUI.AddCopyBufferChangeFunction(CopyBufferChange);
	ExtractionUI.Initialize();
end

--Uninitializes the Extraction UI
function uninit()
	if OldUninit ~= nil then
		OldUninit();
	end
	ExtractionUI.Uninitialize();
end

--Called when the item box is clicked
function itemBox()
	ExtractionUI.SetItemInSlot(player.swapSlotItem());
end

--Called when the item box is right clicked
function itemBoxRight()
	ExtractionUI.SetItemInSlot(nil);
end

--Called when the selected config item changes
--[[function SelectedItemChange()
	
end--]]
--Called when the player's copy buffer has changed
CopyBufferChange = function()
	widget.setButtonEnabled("pasteButton",ExtractionUI.CopyBufferIsSet());
end


--Called when the "copy" button is pressed
function Copy()
	ExtractionUI.CopyConfig(ExtractionUI.GetSelectedConfig());
	widget.setButtonEnabled("pasteButton",true);
end

--Called when the "paste" button is pressed
function Paste()
	ExtractionUI.PasteConfig();
end

--Called when the "Add" button is clicked
function Add()
	ExtractionUI.AddNewConfig();
end

--Called when the "Remove" button is clicked
function Remove()
	ExtractionUI.RemoveSelectedConfig();
end

--Called when the Up arrow button is clicked
function orderUp()
	local SelectedConfig = ExtractionUI.GetSelectedConfig();
	if ExtractionUI.MoveUpConfig(SelectedConfig) then
		ExtractionUI.SetSelectedConfig(SelectedConfig - 1);
	end
end

--Called when the Down arrow button is clicked
function orderDown()
	local SelectedConfig = ExtractionUI.GetSelectedConfig();
	if ExtractionUI.MoveDownConfig(SelectedConfig) then
		ExtractionUI.SetSelectedConfig(SelectedConfig + 1);
	end
end

--Called when the speed "plus" button is clicked
function SpeedAdd()
	local MaxSpeed = ExtractionUI.GetUISettings().MaxSpeed;
	local CurrentSpeed = ExtractionUI.GetSpeed();
	if CurrentSpeed < MaxSpeed and player.consumeItem({name = "speedupgrade",count = 1}) ~= nil then
		ExtractionUI.SetSpeed(CurrentSpeed + 1);
	end
end

--Called when the speed "minus" button is clicked
function SpeedRemove()
	local CurrentSpeed = ExtractionUI.GetSpeed();
	if CurrentSpeed > 0 then
		player.giveItem({name = "speedupgrade",count = 1});
		ExtractionUI.SetSpeed(CurrentSpeed - 1);
	end
end

--Called when the stack "plus" button is clicked
function StackAdd()
	local MaxStack = ExtractionUI.GetUISettings().MaxStack;
	local CurrentStack = ExtractionUI.GetStack();
	if CurrentStack < MaxStack and player.consumeItem({name = "stackupgrade",count = 1}) ~= nil then
		ExtractionUI.SetStack(CurrentStack + 1);
	end
end

--Called when the stack "minus" button is clicked
function StackRemove()
	local CurrentStack = ExtractionUI.GetStack();
	if CurrentStack > 0 then
		player.giveItem({name = "stackupgrade",count = 1});
		ExtractionUI.SetStack(CurrentStack - 1);
	end
end

--Called when the edit button is pressed
function Edit()
	if ExtractionUI.SetTextToConfig(ExtractionUI.GetSelectedConfig()) then
		ExtractionUI.RemoveSelectedConfig();
	end
end

--Called when the "save settings" button is pressed
function Save()
	world.sendEntityMessage(ExtractionUI.GetSourceID(),"Extraction.SaveParameters",world.entityPosition(player.id()));
end

--Called when the "right" color button is clicked
function ColorIncrement()
	ExtractionUI.IncrementColor();
end

--Called when the Conduit's name textbox is changed
function ConduitNameChange()
	world.sendEntityMessage(ExtractionUI.GetSourceID(),"SetUISaveName",widget.getText("conduitNameBox"));
end


--Called when the "left" color button is clicked
function ColorDecrement()
	ExtractionUI.DecrementColor();
end

--Called when the text in the search box has changed
function SearchChange()
	ExtractionUI.SetSearchKeyword(widget.getText("searchBox") or "");
end

--THE BOTTOM FUNCTIONS ARE FOR HELP BUTTONS

function itemNameHelp()
		ExtractionUI.SetHelpText( "               Item Name \n\nThe Name of the item or items you wish to transfer\n\nSpecify \"any\" for all items in container\n\nUse @ in front for item category\n\nUse # for item type\n\nUse & if the item name contains the word you specify\n\nUse ^ exclude certains results");
end

function insertIDHelp()
		local Text = "               Insert ID \n\nThe ID of the Insert Conduit you want to transfer to \n\nSpecify \"any\" to transfer to all Insert Conduits \n\nYou can specify multiple IDs seperated by commas\n\nUse ^ to exclude certain insertIDs";
		if world.getObjectParameter(ExtractionUI.GetSourceID(),"conduitType") == "io" then
			Text = Text .. "\n\nUse the \"!self\" macro to transfer to itself";
		end
		ExtractionUI.SetHelpText(Text);
end

function takeFromSideHelp()
		ExtractionUI.SetHelpText("           Take From Side \n\nThe Inventory you want to take items from \n\nFor Ex. , specifying \"left\" will take items from the left side of the Extraction Conduit \n\nYou can specify multiple values seperated by commas \n\nValid Sides : up,down,left,right \n\nSpecify \"any\" for all sides");
end

function insertIntoSideHelp()
		ExtractionUI.SetHelpText("           Insert Into Side \n\nThe Inventory you want to send items to \n\nFor Ex. , specifying \"left\" will put items into the left side of the specified Insertion Conduit \n\nYou can specify multiple values seperated by commas \n\nValid Sides : up,down,left,right \n\nSpecify \"any\" for all sides");
end

function takeFromSlotHelp()
		ExtractionUI.SetHelpText("            Take from Slot \n\nThe Slot you want to take items from \n\nYou can specify multiple slot numbers by seperating them with commas and/or dashes \n\n Specify \"any\" for all slots");
end

function insertIntoSlotHelp()
	ExtractionUI.SetHelpText("          Insert into Slot \n\nThe Slot you want to put items in \n\nYou can specify multiple slot numbers by seperating them with commas and/or dashes \n\n Specify \"any\" for all slots");
end

function itemBoxHelp()
	ExtractionUI.SetHelpText("                Config Slot \n\nPlace an item here and it will automatically fill in the information\n\nWhen auto is checked, items placed in the slot will be automatically added to the configs\n\nWhen specific is checked, it will do a more through check for the added item\n\nFor Example, if you want a specific type of sapling, make sure to check the \"specific\" box");
end

function searchHelp()
	ExtractionUI.SetHelpText("           Search Box \n\nUsed for searching for the config you want");
end

function amountToLeaveHelp()
	ExtractionUI.SetHelpText("       Amount To Leave \n\nThe Amount of the item(s) you want to leave in the inventory\n\nIf you use a single number, it will define how much of the item will be left in the entire inventory \n\nIf you have multiple numbers, then it will define how much of the item is left in each slot");
end
