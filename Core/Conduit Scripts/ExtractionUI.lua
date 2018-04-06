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
local SettingsUUID;
local SourceID;
local ConfigList = "configArea.itemList";
local SearchText = "";
local ListItemIndexer;
ListItemIndexer = setmetatable({},{
	__index = function(tbl,index)
		for configIndex,i in UICore.Rawipairs(tbl) do
			if i == index then
				return configIndex;
			end
		end
		return nil;
	end,
	__call = function(tbl)
		ListItemIndexer = setmetatable({},getmetatable(ListItemIndexer));
	end,
	__newindex = function(tbl,k,v)
		rawset(tbl,k,v);
	end});
local InverseListItemIndexer = setmetatable({},{
	__index = function(_,configIndex)
		return rawget(ListItemIndexer,configIndex);
	end});
local UISettings;
local DefaultTextBoxValues;
local SlotItem;
local GetConfigCallIndex;
local GetSettingsCallIndex;
local CopyBufferCallIndex;
local CheckItemCache = setmetatable({},{__mode = "k"});
local Speed = 0;
local Stack = 0;
local Color;
local Colors = {};
local ColorToHex = {};
local TraversalColorImage = "/Blocks/Conduits/Extraction Conduit/UI/Window/White Color.png?setcolor=";
local CopyBufferChangeFunctions;
local BufferIsSet = false;

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
local SpeedChange;
local StackChange;
local ColorChange;
local CopyBufferChange;
local AddPremadeConfig;


--Initializes the Extraction UI
function ExtractionUI.Initialize()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	sb.logInfo("SourceID = " .. sb.print(SourceID));
	sb.logInfo("Pane = " .. sb.print(pane));
	UISettings = root.assetJson("/Blocks/Conduits/Extraction Conduit/UI/UI Settings.json");
	DefaultTextBoxValues = UISettings.Defaults;
	local ConduitNameDefault = "Extraction Conduit";
	if InsertionUI ~= nil then
		ConduitNameDefault = "IO Conduit";
	end
	widget.setText("conduitNameBox",world.getObjectParameter(SourceID,"UISaveName",ConduitNameDefault));
	UICore.Initialize();
	--UICore.SetDefinitionTable(Data);
	--UICore.SetAsSyncedValues("ExtractionName",SourceID,"ConduitName","");
	widget.setText("itemNameBox",world.getObjectParameter(SourceID,"UIItemName",""));
	widget.setText("insertIDBox",world.getObjectParameter(SourceID,"UIInsertID",""));
	widget.setText("takeFromSideBox",world.getObjectParameter(SourceID,"UITakeFromSide",""));
	widget.setText("insertIntoSideBox",world.getObjectParameter(SourceID,"UIInsertIntoSide",""));
	widget.setText("takeFromSlotBox",world.getObjectParameter(SourceID,"UITakeFromSlot",""));
	widget.setText("insertIntoSlotBox",world.getObjectParameter(SourceID,"UIInsertIntoSlot",""));
	widget.setText("amountToLeaveBox",world.getObjectParameter(SourceID,"UIAmountToLeave",""));
	widget.setChecked("specificCheckBox",world.getObjectParameter(SourceID,"UIIsSpecific",false));
	widget.setChecked("autoCheckBox",world.getObjectParameter(SourceID,"UIAuto",false));
	Config = world.getObjectParameter(SourceID,"Configs",{});
	Config = UICore.MakeNumberTable(Config);
	ConfigUUID = world.getObjectParameter(SourceID,"ConfigUUID");
	SettingsUUID = world.getObjectParameter(SourceID,"SettingsUUID");
	local ColorData = root.assetJson("/Projectiles/Traversals/Colors.json").Colors;
	for _,color in ipairs(ColorData) do
		Colors[#Colors + 1] = color[2];
		ColorToHex[color[2]] = color[1];
	end
	Speed = world.getObjectParameter(SourceID,"Speed",0);
	if Speed ~= 0 then SpeedChange() end;
	Stack = world.getObjectParameter(SourceID,"Stack",0);
	if Stack ~= 0 then StackChange() end;
	Color = world.getObjectParameter(SourceID,"Color","red");
	ColorChange();
	OnConfigUpdateFunctions(Config);
	ExtractionUI.DisplayConfigs();
	GetConfigCallIndex = UICore.LoopCallContinuously(SourceID,ConfigUpdated,"__UIGetConfig__",function() return ConfigUUID end);
	GetSettingsCallIndex = UICore.LoopCallContinuously(SourceID,SettingsUpdated,"__UIGetSettings__",function() return SettingsUUID end);
	CopyBufferCallIndex = UICore.SimpleLoopCall(player.id(),"BufferIsSet",CopyBufferChange);
end


--Called when the config is updated
ConfigUpdated = function(NewConfig,NewUUID)
	Config = NewConfig;
	Config = UICore.MakeNumberTable(Config);
	ConfigUUID = NewUUID;
	OnConfigUpdateFunctions(Config);
	ExtractionUI.DisplayConfigs();
end

--Called when the conduit's settings are updated
SettingsUpdated = function(NewSettingsUUID,NewSpeed,NewStack,NewColor)
	SettingsUUID = NewSettingsUUID;
	if Speed ~= NewSpeed then
		Speed = NewSpeed;
		SpeedChange();
	end
	if Stack ~= NewStack then
		StackChange();
	end
	if Color ~= NewColor then
		ColorChange();
	end
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

--Sends the UI's config data to the Conduit
SendNewConfig = function()
	ConfigUUID = sb.makeUuid();
	world.sendEntityMessage(SourceID,"SetConfigs",Config,ConfigUUID);
	UICore.ResetLoopCall(GetConfigCallIndex);
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
	if exact ~= true then
		if CheckItemCache[Item.name] == nil then
			local Value = root.itemDescriptorsMatch(Item,root.createItem(Item),false);
			CheckItemCache[Item.name] = Value;
			return Value;
		else
			return CheckItemCache[Item.name];
		end
	end
	return root.itemDescriptorsMatch(Item,root.createItem(Item),exact == true);
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
	ExtractionUI.DisplayConfigs();
end

AddPremadeConfig = function(config)
	Config[#Config + 1] = config;
	SendNewConfig();
	ExtractionUI.DisplayConfigs();
end

--Removes a config at a specific index, returns true if successful
function ExtractionUI.RemoveConfig(index)
	if index > 0 and index <= #Config then
		table.remove(Config,index);
		SendNewConfig();
		ExtractionUI.DisplayConfigs();
		return true;
	end
	return false;
end

--Moves a config from the original index to the new index, returns true if successful
function ExtractionUI.MoveConfig(index,newIndex)
	if index > 0 and index <= #Config and newIndex > 0 and newIndex <= #Config then
		local config = table.remove(Config,index);
		table.insert(Config,newIndex,config);
		SendNewConfig();
		ExtractionUI.DisplayConfigs();
		return true;
	end
	return false;
end

--Moves a config up a level in the list, returns true if successful
function ExtractionUI.MoveUpConfig(index)
	return ExtractionUI.MoveConfig(index,index - 1);
end

--Moves a config down a level in the list, returns true if successful
function ExtractionUI.MoveDownConfig(index)
	return ExtractionUI.MoveConfig(index,index + 1);
end

--Removes the selected config from the list, returns true if successful
function ExtractionUI.RemoveSelectedConfig()
	local SelectedItem = widget.getListSelected(ConfigList);
	if SelectedItem ~= nil then
		local Index = ListItemIndexer[SelectedItem];
		if Index ~= nil then
			return ExtractionUI.RemoveConfig(Index);
		end
	end
	return false;
end

--Returns the selected config and it's index
function ExtractionUI.GetSelectedConfig()
	local SelectedItem = widget.getListSelected(ConfigList);
	if SelectedItem ~= nil then
		local Index = ListItemIndexer[SelectedItem];
		if Index ~= nil then
			return Index,Config[Index];
		end
	end
end

--Sets the selected config, returns true if successful
function ExtractionUI.SetSelectedConfig(index)
	local ListID = InverseListItemIndexer[index];
	if ListID ~= nil then
		widget.setListSelected(ConfigList,ListID);
		return true;
	end
	return false;
end

--Called when the Speed Has Changed
SpeedChange = function()
	widget.setText("speedUpgrades",Speed);
end

--Called when the stack has Changed
StackChange = function()
	widget.setText("stackUpgrades",Stack);
end

--Called when the color has Changed
ColorChange = function()
	widget.setImage("colorDisplay",TraversalColorImage .. ColorToHex[Color]);
end

--Gets the current set speed
function ExtractionUI.GetSpeed()
	return Speed;
end

--Sets the speed
function ExtractionUI.SetSpeed(speed)
	if Speed ~= speed then
		Speed = speed;
		SpeedChange();
		SettingsUUID = sb.makeUuid();
		world.sendEntityMessage(SourceID,"SetSpeed",Speed,SettingsUUID);
		UICore.ResetLoopCall(GetSettingsCallIndex);
	end
end

--Gets the current set stack upgrades
function ExtractionUI.GetStack()
	return Stack;
end

--Sets the stack upgrades
function ExtractionUI.SetStack(stack)
	if Stack ~= stack then
		Stack = stack;
		StackChange();
		SettingsUUID = sb.makeUuid();
		world.sendEntityMessage(SourceID,"SetStack",Stack,SettingsUUID);
		UICore.ResetLoopCall(GetSettingsCallIndex);
	end
end

--Gets the current set Color
function ExtractionUI.GetColor()
	return Color;
end

--Sets the color
function ExtractionUI.SetColor(color)
	if Color ~= color then
		Color = color;
		ColorChange();
		SettingsUUID = sb.makeUuid();
		world.sendEntityMessage(SourceID,"SetColor",Color,SettingsUUID);
		UICore.ResetLoopCall(GetSettingsCallIndex);
	end
end

--Increments to selected color to the next one, and returns true if successful
function ExtractionUI.IncrementColor()
	local Index;
	for k,color in ipairs(Colors) do
		if Color == color then
			Index = k;
			break;
		end
	end
	if Index ~= nil then
		if Index == #Colors then
			Index = 1;
		else
			Index = Index + 1;
		end
		ExtractionUI.SetColor(Colors[Index]);
		return true;
	end
	return false;
end

--Decrements to selected color to the previous one, and returns true if successful
function ExtractionUI.DecrementColor()
	local Index;
	for k,color in ipairs(Colors) do
		if Color == color then
			Index = k;
			break;
		end
	end
	if Index ~= nil then
		if Index == 1 then
			Index = #Colors;
		else
			Index = Index - 1;
		end
		ExtractionUI.SetColor(Colors[Index]);
		return true;
	end
	return false;
end

--Converts a color to hex
function ExtractionUI.ColorToHex(color)
	return ColorToHex[color];
end

--Gets the settings for the UI
function ExtractionUI.GetUISettings()
	return UISettings;
end

--Returns the source Object of the UI
function ExtractionUI.GetSourceID()
	return SourceID;
end

--Adds the config to the player's copy buffer
function ExtractionUI.CopyConfig(config)
	if type(config) == "number" then
		config = Config[config];
	end
	if config ~= nil then
		world.sendEntityMessage(player.id(),"SetCopyBuffer",config);
		UICore.ResetLoopCall(CopyBufferCallIndex);
	end
end

--Pastes the config into this conduit if there is one in the player's copy buffer
function ExtractionUI.PasteConfig()
	UICore.CallMessageOnce(player.id(),"GetCopyBuffer",function(copy)
		if copy ~= nil then
			AddPremadeConfig(copy);
		end
	end);
end

--Adds a function that is called when the copy buffer of the player is Changed
function ExtractionUI.AddCopyBufferChangeFunction(func)
	if CopyBufferChangeFunctions == nil then
		CopyBufferChangeFunctions = {func};
	else
		CopyBufferChangeFunctions[#CopyBufferChangeFunctions + 1] = func;
	end
end

--Returns true if the copy buffer has something in it
function ExtractionUI.CopyBufferIsSet()
	return BufferIsSet;
end

--Called when the copy buffer is Changed
CopyBufferChange = function(newBufferValue)
	if BufferIsSet ~= newBufferValue then
		BufferIsSet = newBufferValue;
	end
	if CopyBufferChangeFunctions ~= nil then
		for _,func in ipairs(CopyBufferChangeFunctions) do
			func();
		end
	end
end

--Sets all the text boxes based off of the config passed in, and returns true if successful
function ExtractionUI.SetTextToConfig(config)
	if type(config) == "number" then
		config = Config[config];
	end
	if config ~= nil then
		widget.setText("itemNameBox",config.itemName);
		widget.setText("insertIDBox",config.insertID);
		widget.setText("takeFromSideBox",config.takeFromSide);
		widget.setText("insertIntoSideBox",config.insertIntoSide);
		widget.setText("takeFromSlotBox",config.takeFromSlot);
		widget.setText("insertIntoSlotBox",config.insertIntoSlot);
		widget.setText("amountToLeaveBox",config.amountToLeave);
		widget.setChecked("specificCheckBox",config.isSpecific);
		if config.isSpecific then
			SlotItem = {name = config.itemName,count = 1,parameters = config.specificData};
			widget.setItemSlotItem("itemBox",SlotItem);
		end
		return true;
	end
	return false;
end

function ExtractionUI.SetHelpText(text)
	widget.setText("helpText",text);
end

--Saves it's settings and uninitializes the conduit
function ExtractionUI.Uninitialize()
	sb.logInfo("SourceID = " .. sb.print(SourceID));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIItemName",widget.getText("itemNameBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertID",widget.getText("insertIDBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UITakeFromSide",widget.getText("takeFromSideBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertIntoSide",widget.getText("insertIntoSideBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UITakeFromSlot",widget.getText("takeFromSlotBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIInsertIntoSlot",widget.getText("insertIntoSlotBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIAmountToLeave",widget.getText("amountToLeaveBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIIsSpecific",widget.getChecked("specificCheckBox"));
	world.sendEntityMessage(SourceID,"__StoreValue__","UIAuto",widget.getChecked("autoCheckBox"));
end
