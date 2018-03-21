require("/Core/UICore.lua");

--Declaration

--Public table
ExtractionUI = {};
local ExtractionUI = ExtractionUI;

--Private Table, Please do not use
__ExtractionUI__ = {};
local __ExtractionUI__ = __ExtractionUI__;

--Variables
local Config;
local ConfigUUID;
local SourceID;
local ConfigList = "configArea.itemList";
local SearchText = "";
local ListItemIndexer = setmetatable({},{
	__index = function(tbl,k)
		for k,i in ipairs(tbl) do
			if i == k then
				return k;
			end
		end
		return nil;
	end,
	__call = function(tbl)
		tbl = setmetatable({},getmetatable(tbl));
	end,
	__newindex = function(tbl,k,v)
		rawset(tbl,k,v);
	end});
local DefaultTextBoxValues;
local SlotItem;

--Functions
local ConfigUpdated;
local OnConfigUpdateFunctions = setmetatable({},{
	__call = function(tbl,config)
		for _,func in ipairs(tbl) do
			func(config);
		end
	end});
local AddConfigToDisplay;
local DirectionalFilter;
local NumericalFilter;
local SendNewConfig;


--Initializes the Extraction UI
function ExtractionUI.Initialize()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	DefaultTextBoxValues = root.assetJson("/Blocks/Conduits/Extraction Conduit/UI/UI Defaults.json").Defaults;
	UICore.Initialize();
	widget.setText("itemNameBox",world.getObjectParameter(SourceID,"UIItemName",""));
	widget.setText("insertIDBox",world.getObjectParameter(SourceID,"UIInsertID",""));
	widget.setText("takeFromSideBox",world.getObjectParameter(SourceID,"UITakeFromSide",""));
	widget.setText("insertIntoSideBox",world.getObjectParameter(SourceID,"UIInsertIntoSide",""));
	widget.setText("takeFromSlotBox",world.getObjectParameter(SourceID,"UITakeFromSlot",""));
	widget.setText("insertIntoSlotBox",world.getObjectParameter(SourceID,"UIInsertIntoSlot",""));
	widget.setText("amountToLeaveBox",world.getObjectParameter(SourceID,"UIAmountToLeave",""));
	Config = world.getObjectParameter(SourceID,"Configs",{});
	ConfigUUID = world.getObjectParameter(SourceID,"ConfigUUID");
	OnConfigUpdateFunctions(Config);
	UICore.LoopCallContinuously(SourceID,ConfigUpdated,"__UIGetConfig__",function() return ConfigUUID end);
end


--Called when the config is updated
ConfigUpdated = function(NewConfig,NewUUID)
	Config = NewConfig;
	ConfigUUID = NewUUID;
	--[[for _,func in ipairs(OnConfigUpdateFunctions) do
		func(Config);
	end--]]
	OnConfigUpdateFunctions(Config);
	ExtractionUI.DisplayConfigs();
end

--Add a function that is called when the Config is updated
function ExtractionUI.AddOnConfigUpdateFunction(func)
	OnConfigUpdateFunctions[#OnConfigUpdateFunctions + 1] = func;
end

--Returns the latest config
function ExtractionUI.GetConfig()
	return Config;
end

--Displays the Configs in the gui
function ExtractionUI.DisplayConfigs()
	widget.clearListItems(ConfigList);
	ListItemIndexer();
	sb.logInfo("ALL Configs = " .. sb.printJson(Config,1));
	for _,config in ipairs(Config) do
		AddConfigToDisplay(config);
	end
end

--Adds a config to the display window
AddConfigToDisplay = function(config)
	if ExtractionUI.TextFulfillsSearch(config.itemName) then
		local NewItem = widget.addListItem(ConfigList);
		ListItemIndexer[#ListItemIndexer + 1] = NewItem;
		local ItemName = ConfigList .. "." .. NewItem .. ".";
		widget.setText(ItemName .. "itemName","Name : " .. config.itemName);
		widget.setText(ItemName .. "insertID","Insert ID : " .. config.insertID);
		widget.setText(ItemName .. "takeFromSide","Take From Side : " .. config.takeFromSide);
		widget.setText(ItemName .. "insertIntoSide","Insert Into Side : " .. config.insertIntoSide);
		widget.setText(ItemName .. "takeFromSlot","Take From Slot : " .. config.takeFromSlot);
		widget.setText(ItemName .. "insertIntoSlot","Insert Into Slot : " .. config.insertIntoSlot);
		widget.setText(ItemName .. "amountToLeave","Amount to Leave : " .. tostring(config.amountToLeave));
		widget.setText(ItemName .. "order",#ListItemIndexer);
		if config.isSpecific == true then
			widget.setText(ItemName .. "specific","specific");
		end
		if CheckItem({name = config.itemName,count = 1,parameters = config.specificData},config.isSpecific) == true then
			widget.setItemSlotItem(ItemName .. "itemImage",{name = config.itemName,count = 1,parameters = config.specificData});
		else
			widget.setItemSlotItem(ItemName .. "itemImage",nil);
		end
	else
		ListItemIndexer[#ListItemIndexer + 1] = 0;
	end
end

--Sends a message to set the Config
--[[function ExtractionUI.SetConfigs(Configs)
	
end--]]

--Sends the UI's config data to the Conduit
SendNewConfig = function()
	world.sendEntityMessage(SourceID,"SetConfigs",Config);
end

--Sets the text that is from the search bar
function ExtractionUI.SetSearchText(text)
	SearchText = text;
end

--Checks if the text passed in fulfills the search text
function ExtractionUI.TextFulfillsSearch(text)
	if SearchText == "" or string.find(string.lower(string.gsub(text,"[%s_.@#~]","")),string.lower(string.gsub(SearchText,"[%s_.@#~]",""))) ~= nil then
		return true;
	end
	return false;
end

--Returns all of the textbox values in this order:
--Item Name
--Insert ID
--Take From Sides
--Insert Into Sides
--Take From Slots
--Insert Into Slots
--Amount To Leave
function ExtractionUI.GetAllText()
	return ExtractionUI.GetText("itemNameBox"),
	ExtractionUI.GetText("insertIDBox"),
	ExtractionUI.GetText("takeFromSideBox"),
	ExtractionUI.GetText("insertIntoSideBox"),
	ExtractionUI.GetText("takeFromSlotBox"),
	ExtractionUI.GetText("insertIntoSlotBox"),
	ExtractionUI.GetText("amountToLeaveBox");
end

--Checks if the item is a real item
CheckItem = function(Item,exact)
	return root.itemDescriptorsMatch(Item,root.createItem(Item),exact);
end

--Gets the text of the textbox, or if nothing's in it then sets it to it's default value
function ExtractionUI.GetText(textBox,defaultValue)
	local Text = widget.getText(textBox);
	if Text == "" then
		Text = defaultValue or DefaultTextBoxValues[textBox] or "";
		widget.setText(textBox,Text);
	end
	return Text;
end

--Sets the Item in the item box
function ExtractionUI.SetItemInSlot(Item)
	if Item ~= nil then
		SlotItem = {name = Item.name,count = 1,parameters = Item.parameters};
		pane.playSound("/sfx/interface/item_pickup.ogg");
	else
		SlotItem = nil;
	end
	widget.setItemSlotItem("itemBox",SlotItem);
	if SlotItem ~= nil then
		widget.setText("itemNameBox",SlotItem.name);
		if widget.getChecked("autoCheckBox") == true then
			ExtractionUI.AddNewConfig();
		else
			ExtractionUI.GetAllText();
		end
	end
end

--Adds a new config based off of the text in the text boxes
function ExtractionUI.AddNewConfig()
	local IsSpecific = widget.getChecked("specificCheckBox") and SlotItem ~= nil and SlotItem.name == ExtractionUI.GetText("itemNameBox");
	local SpecificParameters;
	if IsSpecific then
		SpecificParameters = SlotItem.parameters;
	end
	Config[#Config + 1] = {
		itemName = ExtractionUI.GetText("itemNameBox"),
		insertID = ExtractionUI.GetText("insertIDBox"),
		takeFromSide = ExtractionUI.GetText("takeFromSideBox"),
		insertIntoSide = ExtractionUI.GetText("insertIntoSideBox"),
		takeFromSlot = ExtractionUI.GetText("takeFromSlotBox"),
		insertIntoSlot = ExtractionUI.GetText("insertIntoSlotBox"),
		amountToLeave = ExtractionUI.GetText("amountToLeaveBox"),
		isSpecific = IsSpecific,
		specificData = SpecificParameters
	}
	SendNewConfig();
end

--[[DirectionalFilter = function(text)
	
end--]]

--Saves it's settings and uninitializes the conduit
function ExtractionUI.Uninitialize()
	world.sendEntityMessage(SourceID,"__StoreValue__","UIItemName",widget.getText("itemNameBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertID",widget.getText("insertIDBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UITakeFromSide",widget.getText("takeFromSideBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertIntoSide",widget.getText("insertIntoSideBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UITakeFromSlot",widget.getText("takeFromSlotBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertIntoSlot",widget.getText("insertIntoSlotBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIAmountToLeave",widget.getText("amountToLeaveBox"));
end
