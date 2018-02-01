require("/Core/Debug.lua");
local Configs;
local SourceID;
local ItemList = "configArea.itemList";
local ListItems;
local SearchText = "";
local Speed = 0;
local SpeedMax = 20;
local Stack = 0;
local Colors;
local SelectedColor;
local Image = "/Blocks/Conduits/Extraction Conduit/UI/Window/White Color.png?setcolor=";
local ItemName;
local SlotItem;
local ChangeConfig = false;

local ConduitName = "";
local DefaultName = "Extraction Conduit";

--TODO TODO TODO

-- MOVE DEFAULTNAME TO CONDUIT's Config

local PasteMessage;

local UpdatePasteButton;

local CanPaste = false;
local CanPasteMessage;

local function deepCopy(tbl)
	local newtable = {};
	for i=1,#tbl do
		newtable[i] = {};
		for k,v in pairs(tbl[i]) do
			newtable[i][k] = v;
		end
	end
	return newtable;
end

local function CleanUp(str,allowAny)
	allowAny = allowAny or true;
	if allowAny == true then
		local any = string.match(string.lower(str),"any");
		if any ~= nil then
			return "any";
		end
	end
	local Result = string.gsub(str,"[^%d%-,]*","");
	if Result == "" then
		return "any";
	end
	return Result;
end
local function CleanUpDirectional(str)
	local any = string.match(string.lower(str),"any");
	if any ~= nil then
		return "any";
	end
	local directionTable = {};
	if string.find(string.lower(str),"up") ~= nil then
		directionTable[#directionTable + 1] = "up";
	end
	if string.find(string.lower(str),"down") ~= nil then
		directionTable[#directionTable + 1] = "down";
	end
	if string.find(string.lower(str),"left") ~= nil then
		directionTable[#directionTable + 1] = "left";
	end
	if string.find(string.lower(str),"right") ~= nil then
		directionTable[#directionTable + 1] = "right";
	end
	if #directionTable == 0 then
		return "any";
	end
	return table.concat(directionTable,", ");
end

local function CheckItem(Item,exact)
	return root.itemDescriptorsMatch(Item,root.createItem(Item),exact);
end

local function UpdateConfigsArea()
	widget.clearListItems(ItemList);
	ListItems = {};
	if #Configs > 0 then
		for i=1,#Configs do
			if SearchText == "" or string.find(string.lower(string.gsub(Configs[i].itemName,"[%s_.@#~]","")),string.lower(string.gsub(SearchText,"[%s_.@#~]",""))) ~= nil then
				local newItem = widget.addListItem(ItemList);
				ListItems[#ListItems + 1] = newItem;
				local listName = ItemList .. "." .. newItem .. ".";
				widget.setText(listName .. "itemName","Name : " .. Configs[i].itemName);
				widget.setText(listName .. "insertID","Insert ID : " .. Configs[i].insertID);
				widget.setText(listName .. "takeFromSide","Take From Side : " .. Configs[i].takeFromSide);
				widget.setText(listName .. "insertIntoSide","Insert Into Side : " .. Configs[i].insertIntoSide);
				widget.setText(listName .. "takeFromSlot","Take From Slot : " .. Configs[i].takeFromSlot);
				widget.setText(listName .. "insertIntoSlot","Insert Into Slot : " .. Configs[i].insertIntoSlot);
				widget.setText(listName .. "amountToLeave","Amount to Leave : " .. Configs[i].amountToLeave);
				widget.setText(listName .. "order",i);
				
				
				if Configs[i].isSpecific == true then
					widget.setText(listName .. "specific","specific");
				end

				if CheckItem({name = Configs[i].itemName,count = 1,parameters = Configs[i].specificData},Configs[i].isSpecific) == true then
					widget.setItemSlotItem(listName .. "itemImage",{name = Configs[i].itemName,count = 1,parameters = Configs[i].specificData});
				else
					widget.setItemSlotItem(listName .. "itemImage",nil);
				end
				--[[else
					if CheckItem(Configs[i].itemName) == true then
						widget.setItemSlotItem(listName .. "itemImage",{name = Configs[i].itemName,count = 1});
					else
						widget.setItemSlotItem(listName .. "itemImage",nil);
					end--]]
				--end
			else
				ListItems[#ListItems + 1] = 0;
			end
		end
	end
	if ChangeConfig == true then
		world.sendEntityMessage(SourceID,"SetValue","Configs",deepCopy(Configs));
		ChangeConfig = false;
	end
end

local function UpdateColor()
	widget.setImage("colorDisplay",Image .. Colors[SelectedColor]);
	world.sendEntityMessage(SourceID,"SetColor",SelectedColor);
end

function uninit()
	world.sendEntityMessage(SourceID,"SetValue","UIItemName",widget.getText("itemNameBox"));
	world.sendEntityMessage(SourceID,"SetValue","UIInsertID",widget.getText("insertIDBox"));
	world.sendEntityMessage(SourceID,"SetValue","UITakeFromSide",widget.getText("takeFromSideBox"));
	world.sendEntityMessage(SourceID,"SetValue","UIInsertIntoSide",widget.getText("insertIntoSideBox"));
	world.sendEntityMessage(SourceID,"SetValue","UITakeFromSlot",widget.getText("takeFromSlotBox"));
	world.sendEntityMessage(SourceID,"SetValue","UIInsertIntoSlot",widget.getText("insertIntoSlotBox"));
	world.sendEntityMessage(SourceID,"SetValue","UIAmountToLeave",widget.getText("amountToLeaveBox"));
	world.sendEntityMessage(SourceID,"SetValue","ConduitName",ConduitName);
end

function stringTable(table,name,spacer)
	if table == nil then return name ..  " = nil" end;
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		elseif type(i) == "function" then
				startingString = startingString .. "	" .. k .. " = (FUNC) " .. k;
		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. i .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end

local oldinit = init;

function init()
	if oldinit ~= nil then
		oldinit();
	end
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	Speed = world.getObjectParameter(SourceID,"Speed",0);
	Stack = world.getObjectParameter(SourceID,"Stack",0);
	Colors = {};
	SelectedColor = world.getObjectParameter(SourceID,"SelectedColor",1);
	for k,i in ipairs(root.assetJson("/Projectiles/Traversals/Colors.json").Colors) do
		Colors[#Colors + 1] = i[1];
	end
	ItemName = world.getObjectParameter(SourceID,"ItemName");
	SlotItem = world.getObjectParameter(SourceID,"SlotItem");
	widget.setText("itemNameBox",world.getObjectParameter(SourceID,"UIItemName",""));
	widget.setText("insertIDBox",world.getObjectParameter(SourceID,"UIInsertID",""));
	widget.setText("takeFromSideBox",world.getObjectParameter(SourceID,"UITakeFromSide",""));
	widget.setText("insertIntoSideBox",world.getObjectParameter(SourceID,"UIInsertIntoSide",""));
	widget.setText("takeFromSlotBox",world.getObjectParameter(SourceID,"UITakeFromSlot",""));
	widget.setText("insertIntoSlotBox",world.getObjectParameter(SourceID,"UIInsertIntoSlot",""));
	widget.setText("amountToLeaveBox",world.getObjectParameter(SourceID,"UIAmountToLeave",""));
	widget.setText("speedUpgrades",Speed);
	widget.setText("stackUpgrades",Stack);
	DefaultName = world.getObjectParameter(SourceID,"OriginalDescription") or world.getObjectParameter(SourceID,"shortdescription");
	--sb.logInfo("Default Name = " .. sb.print(DefaultName));
	ConduitName = world.getObjectParameter(SourceID,"shortdescription","");
	--sb.logInfo("Conduit Name = " .. sb.print(ConduitName));
	if ConduitName == DefaultName then
		ConduitName = "";
	end
	widget.setText("conduitNameBox",ConduitName);
	Configs = world.getObjectParameter(SourceID,"Configs",{});
	widget.setChecked("autoCheckBox",world.getObjectParameter(SourceID,"AutoValue",false));
	widget.setChecked("specificCheckBox",world.getObjectParameter(SourceID,"SpecificValue",false));
	UpdateConfigsArea();
	SelectedItemChange();
	UpdatePasteButton();
	UpdateColor();
	if SlotItem ~= nil then
		widget.setItemSlotItem("itemBox",SlotItem);
	elseif ItemName ~= nil then
		widget.setItemSlotItem("itemBox",{name = ItemName,count = 1});
	else
		widget.setItemSlotItem("itemBox",nil);
	end
end

local function GetTextWithDefault(widgetName,defaultValue)
	if widget.getText(widgetName) == "" then
		widget.setText(widgetName,defaultValue);
		return defaultValue;
	end
	return widget.getText(widgetName);
end

function itemBoxRight()
	widget.setItemSlotItem("itemBox",nil);
	ItemName = nil;
	SlotItem = nil;
	world.sendEntityMessage(SourceID,"SetValue","ItemName",ItemName);
	world.sendEntityMessage(SourceID,"SetValue","SlotItem",SlotItem);
end

function itemBox()
	local Item = player.swapSlotItem();
	if Item ~= nil then
		Item.count = 1;
		pane.playSound("/sfx/interface/item_pickup.ogg");
	end
	SlotItem = Item;
	widget.setItemSlotItem("itemBox",Item);
	GetTextWithDefault("itemNameBox","any");
	GetTextWithDefault("insertIDBox","any");
	GetTextWithDefault("takeFromSideBox","any");
	GetTextWithDefault("insertIntoSideBox","any");
	GetTextWithDefault("takeFromSlotBox","any");
	GetTextWithDefault("insertIntoSlotBox","any");
	GetTextWithDefault("amountToLeaveBox","0");
	if Item ~= nil then
		widget.setText("itemNameBox",Item.name);
		ItemName = Item.name;
		if widget.getChecked("autoCheckBox") == true then
			Add();
		end
	else
		ItemName = nil;
	end
	world.sendEntityMessage(SourceID,"SetValue","ItemName",ItemName);
	world.sendEntityMessage(SourceID,"SetValue","SlotItem",SlotItem);
end

function update(dt)
	if CanPasteMessage == nil then
		CanPasteMessage = world.sendEntityMessage(player.id(),"PlayerHasCopy");
	end
	--sb.logInfo("Finished = " .. sb.print(CanPasteMessage:finished()));
	if CanPasteMessage:finished() then
		DPrint("Can Paste = " .. sb.print(CanPasteMessage:result()));
		if CanPasteMessage:result() ~= CanPaste then
			CanPaste = CanPasteMessage:result();
			UpdatePasteButton();
		end
		CanPasteMessage = nil;
	end
	if PasteMessage ~= nil then
		if PasteMessage:finished() then
			local Value = PasteMessage:result();
			if Value ~= nil then
				Configs[#Configs + 1] = Value;
				ChangeConfig = true;
				UpdateConfigsArea();
			end
			PasteMessage = nil;
		end
	end
	--sb.logInfo("CanPasteMessage = " .. sb.print(CanPasteMessage));
end

UpdatePasteButton = function()
	if CanPaste == true then
		widget.setButtonEnabled("pasteButton",true);
	else
		widget.setButtonEnabled("pasteButton",false);
	end
end

local function AddConfig(ItemName,InsertID,TakeFromSide,InsertIntoSide,TakeFromSlot,InsertIntoSlot,AmountToLeave,IsSpecific,SpecificData)
	Configs[#Configs + 1] = {
		itemName = ItemName,
		insertID = InsertID,
		takeFromSide = CleanUpDirectional(TakeFromSide),
		insertIntoSide = CleanUpDirectional(InsertIntoSide),
		takeFromSlot = CleanUp(TakeFromSlot),
		insertIntoSlot = CleanUp(InsertIntoSlot),
		amountToLeave = CleanUp(AmountToLeave),
		isSpecific = IsSpecific,
		specificData = SpecificData
	};
	ChangeConfig = true;
	UpdateConfigsArea();
end

function Add()
	local data = nil;
	if SlotItem ~= nil and SlotItem.name == GetTextWithDefault("itemNameBox","any") and SlotItem.parameters ~= nil then
		data = SlotItem.parameters;
	end
	AddConfig(
		GetTextWithDefault("itemNameBox","any"),
		GetTextWithDefault("insertIDBox","any"),
		GetTextWithDefault("takeFromSideBox","any"),
		GetTextWithDefault("insertIntoSideBox","any"),
		GetTextWithDefault("takeFromSlotBox","any"),
		GetTextWithDefault("insertIntoSlotBox","any"),
		GetTextWithDefault("amountToLeaveBox","0"),
		widget.getChecked("specificCheckBox") and SlotItem ~= nil and SlotItem.name == GetTextWithDefault("itemNameBox","any"),
		data

	);
end

function Remove()
	local SelectedItem = widget.getListSelected(ItemList);
	for k,i in ipairs(ListItems) do
		if SelectedItem == i then
			table.remove(Configs,k);
			break;
		end
	end
	ChangeConfig = true;
	UpdateConfigsArea();
end

function SelectedItemChange()
	local SelectedItem = widget.getListSelected(ItemList);
	if SelectedItem ~= nil then
		widget.setButtonEnabled("removeButton",true);
		widget.setButtonEnabled("orderUp",true);
		widget.setButtonEnabled("orderDown",true);
		widget.setButtonEnabled("copyButton",true);
		widget.setButtonEnabled("editButton",true);
	else
		widget.setButtonEnabled("removeButton",false);
		widget.setButtonEnabled("orderUp",false);
		widget.setButtonEnabled("orderDown",false);
		widget.setButtonEnabled("copyButton",false);
		widget.setButtonEnabled("editButton",false);
	end
end

function AutoBoxUpdate()
	world.sendEntityMessage(SourceID,"SetValue","AutoValue",widget.getChecked("autoCheckBox"));
end

function SpecificBoxUpdate()
	world.sendEntityMessage(SourceID,"SetValue","SpecificValue",widget.getChecked("specificCheckBox"));
end

function orderUp()
	local SelectedItem = widget.getListSelected(ItemList);
	local Index = 0;
	for k,i in ipairs(ListItems) do
		if SelectedItem == i then
			local Value = Configs[k];
			table.remove(Configs,k);
			local incrementer = k - 1;
			if incrementer < 1 then incrementer = 1 end;
			Index = incrementer;
			table.insert(Configs,incrementer,Value);
			break;
		end
	end
	ChangeConfig = true;
	UpdateConfigsArea();
	widget.setListSelected(ItemList,ListItems[Index]);
end

function orderDown()
	local SelectedItem = widget.getListSelected(ItemList);
	local Index = 0;
	for k,i in ipairs(ListItems) do
		if SelectedItem == i then
			local Value = Configs[k];
			table.remove(Configs,k);
			local decrementer = k + 1;
			if decrementer > #Configs + 1 then decrementer = #Configs + 1 end;
			Index = decrementer;
			table.insert(Configs,decrementer,Value);
			break;
		end
	end
	ChangeConfig = true;
	UpdateConfigsArea();
	widget.setListSelected(ItemList,ListItems[Index]);
end

function SearchChange()
	if widget.getText("searchBox") ~= SearchText then
		SearchText = widget.getText("searchBox");
		UpdateConfigsArea();
	end
end

function SpeedAdd()
	local Original = Speed;
	Speed = Speed + 1;
	if Speed > SpeedMax then Speed = SpeedMax end;
	if Speed ~= Original and player.consumeItem({name = "speedupgrade",count = 1}) ~= nil then
		world.sendEntityMessage(SourceID,"SetSpeed",Speed);
		widget.setText("speedUpgrades",Speed);
	else
		Speed = Original;
	end
end

function SpeedRemove()
	local Original = Speed;
	Speed = Speed - 1;
	if Speed < 0 then Speed = 0 end;
	if Speed ~= Original then
		player.giveItem({name = "speedupgrade",count = 1});
		world.sendEntityMessage(SourceID,"SetSpeed",Speed);
		widget.setText("speedUpgrades",Speed);
	end
end

function StackAdd()
	local Original = Stack;
	Stack = Stack + 1;
	if Stack > 20 then Stack = 20 end;
	if Stack ~= Original and player.consumeItem({name = "stackupgrade",count = 1}) ~= nil then
		world.sendEntityMessage(SourceID,"SetStack",Stack);
		widget.setText("stackUpgrades",Stack);
	else
		Stack = Original;
	end
end

function StackRemove()
	local Original = Stack;
	Stack = Stack - 1;
	if Stack < 0 then Stack = 0 end;
	if Stack ~= Original then
		player.giveItem({name = "stackupgrade",count = 1});
		world.sendEntityMessage(SourceID,"SetStack",Stack);
		widget.setText("stackUpgrades",Stack);
	end
end

function ColorIncrement()
	SelectedColor = SelectedColor + 1;
	if SelectedColor > #Colors then
		SelectedColor = 1;
	end
	UpdateColor();
end

function ColorDecrement()
	SelectedColor = SelectedColor - 1;
	if SelectedColor < 1 then
		SelectedColor = #Colors;
	end
	UpdateColor();
end

function Copy()
	DPrint("Copy Pressed");
	local SelectedItem = widget.getListSelected(ItemList);
	local Index = 0;
	for k,i in ipairs(ListItems) do
		if SelectedItem == i then
			DPrint("Sending " .. sb.print(Configs[k]) .. " to player");
			world.sendEntityMessage(player.id(),"SetExtractionConfigCopy",Configs[k]);
			break;
		end
	end
end

function Paste()
	PasteMessage = world.sendEntityMessage(player.id(),"RetrieveExtractionConfigCopy");
end

function Edit()
	local SelectedItem = widget.getListSelected(ItemList);
	local Index = 0;
	for k,i in ipairs(ListItems) do
		if SelectedItem == i then
			local Value = Configs[k];
			table.remove(Configs,k);
			widget.setText("itemNameBox",Value.itemName or "");
			widget.setText("insertIDBox",Value.insertID or "");
			widget.setText("takeFromSideBox",Value.takeFromSide or "");
			widget.setText("insertIntoSideBox",Value.insertIntoSide or "");
			widget.setText("takeFromSlotBox",Value.takeFromSlot or "");
			widget.setText("insertIntoSlotBox",Value.insertIntoSlot or "");
			widget.setText("amountToLeaveBox",Value.amountToLeave or "");
			break;
		end
	end
	ChangeConfig = true;
	UpdateConfigsArea();
end

function Save()
	local Object = pane.sourceEntity();
	if Object ~= nil then
		local Params = world.getObjectParameter(Object,"RetainingParameters");
		--sb.logInfo("Params = " .. sb.print(Params));
		local Pos = world.entityPosition(Object);
		--sb.logInfo(stringTable(world,"World"));
		local Configs = {};
		if Params ~= nil then
			for k,i in ipairs(Params) do
				Configs[i] = world.getObjectParameter(Object,i);
			end
			local Icon = world.getObjectParameter(Object,"inventoryIcon");
			if string.find(Icon,"%?border=1;FF0000%?fade=007800;0%.1$") ~= nil then
				Configs["inventoryIcon"] = Icon;
			else
				Configs["inventoryIcon"] = Icon .. "?border=1;FF0000?fade=007800;0.1";
			end
			Configs["RetainingParameters"] = Params;
			Configs["OriginalDescription"] = world.getObjectParameter(Object,"OriginalDescription") or world.getObjectParameter(Object,"shortdescription");
			if ConduitName ~= nil and ConduitName ~= "" then
				Configs["shortdescription"] = ConduitName;
			else
				Configs["shortdescription"] = DefaultName;
			end
			DPrint("Configs = " .. sb.printJson(Configs,1));
			world.sendEntityMessage(Object,"SmashCableBlockAndSpawnItem",nil,world.entityPosition(Object),10,Configs);
		end
		--world.sendEntityMessage(Object,"SetRetainingMode");
	end
end

function ConduitNameChange()
	ConduitName = widget.getText("conduitNameBox");
end




function itemNameHelp()
		widget.setText("helpText", "               Item Name \n\nThe Name of the item or items you wish to transfer\n\nSpecify \"any\" for all items in container\n\nUse @ in front for item category\n\nUse # for item type\n\nUse & if the item name contains the word you specify\n\nUse ^ exclude certains results");
end
function insertIDHelp()
		local Text = "               Insert ID \n\nThe ID of the Insert Conduit you want to transfer to \n\nSpecify \"any\" to transfer to all Insert Conduits \n\nYou can specify multiple IDs seperated by commas\n\nUse ^ to exclude certain insertIDs";
		if world.getObjectParameter(SourceID,"conduitType") == "io" then
			Text = Text .. "\n\nUse the \"!self\" macro to transfer to itself";
		end
		widget.setText("helpText",Text);
end
function takeFromSideHelp()
		widget.setText("helpText","           Take From Side \n\nThe Inventory you want to take items from \n\nFor Ex. , specifying \"left\" will take items from the left side of the Extraction Conduit \n\nYou can specify multiple values seperated by commas \n\nValid Sides : up,down,left,right \n\nSpecify \"any\" for all sides");
end
function insertIntoSideHelp()
		widget.setText("helpText","           Insert Into Side \n\nThe Inventory you want to send items to \n\nFor Ex. , specifying \"left\" will put items into the left side of the specified Insertion Conduit \n\nYou can specify multiple values seperated by commas \n\nValid Sides : up,down,left,right \n\nSpecify \"any\" for all sides");
end
function takeFromSlotHelp()
		widget.setText("helpText","            Take from Slot \n\nThe Slot you want to take items from \n\nYou can specify multiple slot numbers by seperating them with commas and/or dashes \n\n Specify \"any\" for all slots");
end
function insertIntoSlotHelp()
	widget.setText("helpText","          Insert into Slot \n\nThe Slot you want to put items in \n\nYou can specify multiple slot numbers by seperating them with commas and/or dashes \n\n Specify \"any\" for all slots");
end
function itemBoxHelp()
	widget.setText("helpText","                Config Slot \n\nPlace an item here and it will automatically fill in the information\n\nWhen auto is checked, items placed in the slot will be automatically added to the configs\n\nWhen specific is checked, it will do a more through check for the added item\n\nFor Example, if you want a specific type of sapling, make sure to check the \"specific\" box");
end
function searchHelp()
	widget.setText("helpText","           Search Box \n\nUsed for searching for the config you want");
end
function amountToLeaveHelp()
	widget.setText("helpText","       Amount To Leave \n\nThe Amount of the item(s) you want to leave in the inventory\n\nIf you use a single number, it will define how much of the item will be left in the entire inventory \n\nIf you have multiple numbers, then it will define how much of the item is left in each slot");
end
