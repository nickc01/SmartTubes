require("/Core/ConduitCore.lua");
require("/Core/ServerCore.lua");
require("/Core/ContainerHelper.lua");
--Declaration

--Public Table
Extraction = {};
local Extraction = Extraction;

--Private Table, PLEASE DONT TOUCH
__Extraction__ = {};
local __Extraction__ = __Extraction__;
--Variables
local SourceID;
local SourcePosition;
local Speed = 0;
local Stack = 0;
local Color;
local Colors;
local ColorToHex = {};
local Operators = {};
local Config;
local ConfigUUID;
local NewConfig;
local NewConfigUUID;
local SettingsUUID;
local ConfigIndex = 1;
local ConfigCache = {};
local AnyNumberTable = setmetatable({},{__index = function(_,k) return k end});
local ZeroIfNilMetatable = {__index = function(tbl,k)
	--sb.logInfo("Calling Metatable for = " .. sb.print(k));
	return rawget(tbl,k) or 0; end};
local LocalOnConfigUpdate = {};
local Data = {};
--Functions
local SetMessages;
local ConfigUpdate;
local IsCached;
local SetCachedConfigValue;
local GetCachedConfigValue;
local ResetCache;
local RandomIterator;
local StringToNumbers;
local CheckItemWithOperators;
local SetConfigs;
local AddConfig;
local RemoveConfig;
local UniIter;
local MakeNumberTable;
local SpeedUpdate;
local StackUpdate;
local ColorUpdate;

--Initializes the Extraction Conduit
function Extraction.Initialize()
	SourceID = entity.id();
	SourcePosition = entity.position();
	Speed = config.getParameter("Speed",0);
	Stack = config.getParameter("Stack",0);
	--Server.SetDefinitionTable(Data);
	--Server.DefineSyncedValues("ExtractionName","ConduitName",config.getParameter("shortDescription"));
	local ColorData = root.assetJson("/Projectiles/Traversals/Colors.json").Colors;
	Colors = {};
	for _,color in ipairs(ColorData) do
		Colors[#Colors + 1] = color[2];
		ColorToHex[color[2]] = color[1];
	end
	if config.getParameter("SelectedColor") ~= nil then
		Color = Colors[config.getParameter("SelectedColor")];
		object.setConfigParameter("SelectedColor",nil);
	else
		Color = config.getParameter("Color","red");
	end
	SettingsUUID = config.getParameter("SettingsUUID");
	if SettingsUUID == nil then
		SettingsUUID = sb.makeUuid();
		 object.setConfigParameter("SettingsUUID",SettingsUUID);
	end
	script.setUpdateDelta(60 / (Speed + 1));
	Config = config.getParameter("Configs",{});
	ConfigUUID = config.getParameter("ConfigsUUID");
	if ConfigUUID == nil then
		 ConfigUUID = sb.makeUuid();
		 object.setConfigParameter("ConfigUUID",ConfigUUID);
	end
	NewConfig = Config;
	NewConfigUUID = ConfigUUID;
	ConduitCore.AddConnectionUpdateFunction(function()
		SetCachedConfigValue("TakeFromSidesWithIDs",nil);
		SetCachedConfigValue("InsertionConduits",nil);
	end);
	ConduitCore.AddNetworkUpdateFunction(function()
		SetCachedConfigValue("NetworkInsertConduits",nil);
		SetCachedConfigValue("InsertionConduits",nil);
	end);
	ConduitCore.UpdateContinuously(true);
	ConduitCore.AddConnectionType("Containers",function(ID) return ContainerHelper.IsContainer(ID) end);
	SetMessages();
end

--Sets the Messages required for this conduit
SetMessages = function()
	message.setHandler("SetConfigs",function(_,_,configs,UUID)
		SetConfigs(MakeNumberTable(configs),UUID);
	end);
	message.setHandler("SetSpeed",function(_,_,speed,newSettingsUUID)
		SettingsUUID = newSettingsUUID or sb.makeUuid();
		object.setConfigParameter("SettingsUUID",SettingsUUID);
		if Speed ~= speed then
			Speed = speed;
			SpeedUpdate();
		end
	end);
	message.setHandler("__UIGetSettings__",function(_,_,settingsUUID)
		if settingsUUID == SettingsUUID then
			return false;
		else
			return {true,SettingsUUID,Speed,Stack,Color};
		end
	end);
	message.setHandler("SetStack",function(_,_,stack,newSettingsUUID)
		--Stack = stack;
		SettingsUUID = newSettingsUUID or sb.makeUuid();
		object.setConfigParameter("SettingsUUID",SettingsUUID);
		if Stack ~= stack then
			Stack = stack;
			StackUpdate();
		end
	end);
	message.setHandler("SetColor",function(_,_,color,newSettingsUUID)
		SettingsUUID = newSettingsUUID or sb.makeUuid();
		object.setConfigParameter("SettingsUUID",SettingsUUID);
		if Color ~= color then
			Color = color;
			ColorUpdate();
		end
	end);
	message.setHandler("__UIGetConfig__",function(_,_,OldUUID)
		if OldUUID ~= NewConfigUUID then
			return {true,NewConfig,NewConfigUUID};
		else
			return false;
		end
	end);
	message.setHandler("__StoreValue__",function(_,_,Key,Value)
		object.setConfigParameter(Key,Value);
	end);
	message.setHandler("SetUISaveName",function(_,_,name)
		object.setConfigParameter("UISaveName",name);
	end);	
	message.setHandler("Extraction.SaveParameters",function(_,_,dropPosition)
		__Extraction__.SaveParameters();
		ConduitCore.DropAndSaveParameters(nil,dropPosition);
	end);
end

--Returns the Extraction Conduit's ID
function Extraction.GetID()
	return SourceID;
end

--Returns the Extraction Conduit's position
function Extraction.Position()
	return SourcePosition;
end

--Gets all the possible traversal colors
function Extraction.GetColors()
	return Colors;
end

--Gets the Currently selected color
function Extraction.GetSelectedColor()
	return Color;
end

--Saves the Extraction's parameters
function __Extraction__.SaveParameters(DisplayName)
	ConduitCore.AddSaveParameter("Speed",Speed);
	ConduitCore.AddSaveParameter("Stack",Stack);
	ConduitCore.AddSaveParameter("Color",Color);
	ConduitCore.AddSaveParameter("Configs",Config);
	ConduitCore.AddColorToSavedItem(ColorToHex[Color]);
	local SaveName = config.getParameter("UISaveName","");
	if SaveName ~= "" then
		ConduitCore.SetSaveName(SaveName);
		ConduitCore.AddSaveParameter("UISaveName",SaveName);
	end

	--If this conduit has an insertion table (ie, this conduit is an io conduit), then save it's parameters too
	if __Insertion__ ~= nil then
		__Insertion__.SaveParameters();
	end
end

--Sets the selected color
function Extraction.SetSelectedColor(color)
	if Color ~= color then
		Color = color;
		SettingsUUID = sb.makeUuid();
	end
end

--An iterator that iterates through the table in a random order
local function RandomIterator(t)
	local indexTable = {};
	for i=1,#t do
		indexTable[i] = i;
	end
	local Size = #indexTable;
  	while Size > 1 do
    	local k = math.random(Size);
    	indexTable[Size], indexTable[k] = indexTable[k], indexTable[Size];
    	Size = Size - 1;
 	end
	local n = 0;
	return function()
		n = n + 1;
		return indexTable[n],t[indexTable[n]];
	end
end

--Returns an iterator that iterates over all the neighboring containers based off of the config data
function Extraction.GetContainerIterator()
	local ExportIDs;
	--Retrieve the cached id table
	if not IsCached("TakeFromSidesWithIDs") then
		local Config = Extraction.GetConfig();
		local ExportSides;
		if not IsCached("TakeFromSides") then
			ExportSides = {};
			for str in string.gmatch(Config.takeFromSide,"[^,]+") do
				ExportSides[#ExportSides + 1] = string.lower(str);
			end
			if #ExportSides > 0 then
				if ExportSides[1] == "any" then
					ExportSides = {"right","down","left","up"};
				end
			end
			SetCachedConfigValue("TakeFromSides",ExportSides);
		else
			ExportSides = GetCachedConfigValue("TakeFromSides");
		end
		ExportIDs = {};
		local Containers = ConduitCore.GetConnections("Containers");
		for m,n in ipairs(ExportSides) do
			if n == "right" then
				ExportIDs[#ExportIDs + 1] = Containers[4];
			elseif n == "down" then
				ExportIDs[#ExportIDs + 1] = Containers[2];
			elseif n == "left" then
				ExportIDs[#ExportIDs + 1] = Containers[3];
			elseif n == "up" then
				ExportIDs[#ExportIDs + 1] = Containers[1];
			end
		end
		SetCachedConfigValue("TakeFromSidesWithIDs",ExportIDs);
	else
		ExportIDs = GetCachedConfigValue("TakeFromSidesWithIDs");
	end
	return RandomIterator(ExportIDs);
	--[[for k,i in RandomIterator(ExportIDs) do
		if i ~= 0 then
			return i;
		end
	end--]]
end

--Returns a neighboring container based off of the config data
function Extraction.GetContainer()
	for _,i in Extraction.GetContainerIterator() do
		if i ~= 0 then
			return i;
		end
	end
end

--Gets an item from the container based off of the config data
function Extraction.GetItemFromContainer(container)
	local Config = Extraction.GetConfig();
	local Slots;
	if not IsCached("TakeFromSlots") then
		Slots = {};
		--sb.logInfo("Config = " .. sb.print(Config));
		for number in StringToNumbers(Config.takeFromSlot) do
			Slots[#Slots + 1] = number;
		end
		if Slots[1] == "any" then
			Slots = AnyNumberTable;
		end
		SetCachedConfigValue("TakeFromSlots",Slots);
	else
		Slots = GetCachedConfigValue("TakeFromSlots");
	end
	local ContainerSize = ContainerHelper.Size(container);
	local AmountToLeave;
	local ForEntireInventory = false;
	if not IsCached("AmountToLeave") then
		AmountToLeave = {};
		for number in StringToNumbers(Config.amountToLeave) do
			if number == "any" then
				number = 0;
			end
			AmountToLeave[#AmountToLeave + 1] = number;
		end
		if #AmountToLeave == 1 then
			ForEntireInventory = true;
		end
		AmountToLeave = setmetatable(AmountToLeave,{__index = function(tbl,k)
			return rawget(tbl,k) or 0;
		end});
		SetCachedConfigValue("AmountToLeave",AmountToLeave);
	else
		AmountToLeave = GetCachedConfigValue("AmountToLeave");
		if #AmountToLeave == 1 then
			ForEntireInventory = true;
		end
	end
	local FinalCount = 0;
	for i=1,ContainerSize do
		local slot = Slots[i];
		if slot == nil then break end;
		--if slot ~= nil then
			local Item = ContainerHelper.ItemAt(container,slot - 1);
			if Item ~= nil then
				if Item.count > (Stack + 1) ^ 2 then
					Item.count = (Stack + 1) ^ 2;
				end
				--sb.logInfo("Beginning Check on " .. sb.print(Item));
				if ForEntireInventory then
					--sb.logInfo("A");
					local TotalInInventory = ContainerHelper.Available(container,{name = Item.name,count = 1,parameters = Item.parameters});
					--sb.logInfo("Total In Inventory = " .. sb.print(TotalInInventory));
					local AmountCanTake = TotalInInventory - AmountToLeave[1];
					if Item.count <= AmountCanTake then
						--sb.logInfo("B");
						--CheckItemWithOperators(Item); TODO
						if CheckItemWithOperators(Item) then
							--sb.logInfo("D");
							return Item,slot;
						end
					else
						--sb.logInfo("C");
						--local Count = AmountCanTake;
						Item = {name = Item.name,count = AmountCanTake,parameters = Item.parameters};
						--CheckItemWithOperators(Item); 
						if CheckItemWithOperators(Item) then
							--sb.logInfo("E");
							return Item,slot;
						end
					end
				else
					--sb.logInfo("F");
					if AmountToLeave[slot] ~= 0 then
						--sb.logInfo("Amount To Leave = " .. sb.print(AmountToLeave[slot]));
						--sb.logInfo("G");
						Item = {name = Item.name,count = Item.count - AmountToLeave[slot],parameters = Item.parameters};
						--CheckItemWithOperators(Item); TODO
						if CheckItemWithOperators(Item) then
							--sb.logInfo("H");
							return Item,slot;
						end
					else
						if CheckItemWithOperators(Item) then
							--sb.logInfo("I");
							return Item,slot;
						end
					end
				end
			end
		--end
	end
end

CheckItemWithOperators = function(item)
	if item ~= nil and item.count > 0 then
		local Config = Extraction.GetConfig();
		--If the item is specific
		if Config.isSpecific == true then
			sb.logInfo("SPECIFIC");
			return root.itemDescriptorsMatch(item,{name = item.name,count = item.count,parameters = Config.specificData},true);
		end
		if not IsCached("ItemCheckCache") then
			local ItemCheckCache = {};
			SetCachedConfigValue("ItemCheckCache",ItemCheckCache);
		end
		local ItemCheckCache = GetCachedConfigValue("ItemCheckCache");
		local CanCache = false;
		if item.parameters == nil or jsize(item.parameters) == 0 then
			if ItemCheckCache[item.name] ~= nil then
				return ItemCheckCache[item.name];
			else
				CanCache = true;
			end
		end
		local ItemNames;
		if not IsCached("ItemCheckers") then
			ItemNames = {
				Positives = {},
				Negatives = {}
			};
			for str in string.gmatch(Config.itemName,"[%w#&@%%_%^;:,<%.>]+,-") do
				local Table = ItemNames.Positives;
				if string.find(str,"^%^") ~= nil then
					Table = ItemNames.Negatives;
					str = string.match(str,"^%^(.+)");
				end
				local firstCharacter = string.sub(str,1,1);
				local OperationString = string.sub(str,2);
				for character,operation in pairs(Operators) do
					if character == firstCharacter then
						Table[#Table + 1] = function(item) return operation(item,OperationString) end;
						goto NextOperation;
					end
				end
				if str == "any" then
					Table[#Table + 1] = function() return true end;
					goto NextOperation;
				end
				Table[#Table + 1] = function(item) return item.name == str end;
				::NextOperation::
			end
			SetCachedConfigValue("ItemCheckers",ItemNames);
		else
			ItemNames = GetCachedConfigValue("ItemCheckers");
		end
		local Valid = true;
		for _,func in ipairs(ItemNames.Positives) do
			Valid = func(item);
			if Valid == false then
				if CanCache then
					ItemCheckCache[item.name] = false;
				end
				return false;
			end
		end
		for _,func in ipairs(ItemNames.Negatives) do
			Valid = not func(item);
			if Valid == false then
				if CanCache then
					ItemCheckCache[item.name] = false;
				end
				return false;
			end
		end
		--sb.logInfo("Returning Value = " .. sb.print(Valid));
		if CanCache then
			ItemCheckCache[item.name] = Valid;
		end
		return Valid;
	end
	--sb.logInfo("Returning False 3");
	return false;
end

--Returns an iterator of possible insertion conduits to send the item to
function Extraction.InsertionConduitFinder()
	--TODO
	local InsertionConduits;
	if not IsCached("InsertionConduits") then
		--sb.logInfo("Insertion Conduits Being Cached " .. sb.print(entity.id()));
		local NetworkInsertConduits;
		if not IsCached("NetworkInsertConduits") then
			local Network = ConduitCore.GetConduitNetwork();
			sb.logInfo("NETWORK = " .. sb.print(Network));
			NetworkInsertConduits = {};
			for k,i in ipairs(Network) do
				--sb.logInfo("First I = " .. sb.print(i));
				--sb.logInfo("First InsertID = " .. sb.print(world.getObjectParameter(i,"insertID")));
				if world.getObjectParameter(i,"insertID") ~= nil then
					NetworkInsertConduits[#NetworkInsertConduits + 1] = i;
				end
			end
			SetCachedConfigValue("NetworkInsertConduits",NetworkInsertConduits);
		else
			NetworkInsertConduits = GetCachedConfigValue("NetworkInsertConduits");
		end
		--sb.logInfo("NetworkInsertConduits = " .. sb.print(NetworkInsertConduits));
		local InsertIDs;
		if not IsCached("InsertIDs") then
			InsertIDs = {
				Valid = {},
				Invalid = {}
			};
			local Config = Extraction.GetConfig();
			for str in string.gmatch(Config.insertID,"[%w_%^!]+,-") do
				if string.find(str,"^%s*%^") ~= nil then
					InsertIDs.Invalid[#InsertIDs.Invalid + 1] = string.match(str,"^%s*%^(.*)") or "";
				else
					InsertIDs.Valid[#InsertIDs.Valid + 1] = str;
				end
			end
		else
			InsertIDs = GetCachedConfigValue("InsertIDs");
		end
		--sb.logInfo("Insert IDS = " .. sb.print(InsertIDs));
		InsertionConduits = {};
		for k,i in ipairs(NetworkInsertConduits) do
			local InsertID = world.getObjectParameter(i,"insertID");
			local Valid = false;
			for m,n in ipairs(InsertIDs.Valid) do
				if n == "any" or InsertID == n or (i == SourceID and n == "!self") then
					Valid = true;
					break;
				end
			end
			if Valid == true then
				for m,n in ipairs(InsertIDs.Invalid) do
					if n == "any" or InsertID == n or (i == SourceID and n == "!self") then
						Valid = false;
						break;
					end
				end
			end
			if Valid then
				InsertionConduits[#InsertionConduits + 1] = i;
			end
		end
		--sb.logInfo("FInal INSERTION CONDUITS = " .. sb.print(InsertionConduits));
		SetCachedConfigValue("InsertionConduits",InsertionConduits);
	else
		InsertionConduits = GetCachedConfigValue("InsertionConduits");
	end
	--sb.logInfo("InsertionConduits = " .. sb.print(InsertionConduits));
	return RandomIterator(InsertionConduits);
end

--function Extraction.

--Cycles the Config index to get the next config data
function Extraction.CycleConfigIndex()
	ConfigIndex = ConfigIndex + 1;
	if ConfigIndex > #Config then
		ConfigIndex = 1;
	end
end

--Sets the Config for the Extraction Conduit
SetConfigs = function(configs,UUID)
	NewConfig = configs;
	NewConfigUUID = UUID or sb.makeUuid();
	object.setConfigParameter("Configs",configs);
	object.setConfigParameter("ConfigsUUID",NewConfigUUID);
end

--Gets the latest config
function Extraction.GetConfig()
	if Config ~= nil then
		return Config[ConfigIndex];
	end
end

--Will update the config to the latest version
function Extraction.RefreshConfig()
	--sb.logInfo("Config Has Changed = " .. sb.print(ConfigHasChanged));
	if ConfigUUID ~= NewConfigUUID then
		--sb.logInfo("Refreshed");
		Config = NewConfig;
		ConfigUUID = NewConfigUUID;
		ConfigUpdate();
	end
end

--Returns if the Config is ready to be used
function Extraction.IsConfigAvailable()
	if Config ~= nil and #Config > 0 then
		return true;
	end
	return false;
end

--Gets the Speed Upgrades
function Extraction.GetSpeed()
	return Speed;
end

--Sets the Speed Upgrades
function Extraction.SetSpeed(speed)
	if Speed ~= speed then
		Speed = speed;
		SettingsUUID = sb.makeUuid();
		object.setConfigParameter("SettingsUUID",SettingsUUID);
		SpeedUpdate();
	end
end

--Gets the Stack Upgrades
function Extraction.GetStack()
	return Stack;
end

--Sets the Stack Upgrades
function Extraction.SetStack(stack)
	if Stack ~= stack then
		Stack = stack;
		SettingsUUID = sb.makeUuid();
		object.setConfigParameter("SettingsUUID",SettingsUUID);
		StackUpdate();
	end
end

--Called when the speed changes
SpeedUpdate = function()
	script.setUpdateDelta(60 / (Speed + 1));
	object.setConfigParameter("Speed",Speed);
end

--Called when the stack changes
StackUpdate = function()
	object.setConfigParameter("Stack",Stack);
end

--Called when the selected color changes
ColorUpdate = function()
	object.setConfigParameter("Color",Color);
end

--Called when the config is updated
ConfigUpdate = function()
	--sb.logInfo("Config is updated");
	ResetCache();
	for _,func in ipairs(LocalOnConfigUpdate) do
		func();
	end
	LocalOnConfigUpdate = {};
	Extraction.ResetConfigIndex();
end

--Resets the Config Index
function Extraction.ResetConfigIndex()
	ConfigIndex = 1;
end

--Add an operator that checks if the item matches it
function Extraction.AddOperator(character,Condition)
	if string.len(character) ~= 1 then error(sb.print(character) .. " needs to be a single character") end;
	Operators[character] = Condition;
end

--Removes an operator
function Extraction.RemoveOperator(character)
	--if string.len(character) ~= 1 then error(sb.print(character) .. " needs to be a single character");
	Operators[character] = nil;
end

--Checks to see if a Config Value is Cached
IsCached = function(ConfigValue)
	if ConfigCache[ConfigIndex] ~= nil and ConfigCache[ConfigIndex][ConfigValue] ~= nil then
		return true;
	end
	return false;
end

--Set a config value to be cached
SetCachedConfigValue = function(ConfigValue,value)
	if ConfigCache[ConfigIndex] == nil then
		ConfigCache[ConfigIndex] = {};
	end
	ConfigCache[ConfigIndex][ConfigValue] = value;
end

--Resets the entire cache
ResetCache = function()
	ConfigCache = {};
end

--Gets a cached config value
GetCachedConfigValue = function(ConfigValue)
	if ConfigCache[ConfigIndex] == nil then
		return nil;
	end
	return ConfigCache[ConfigIndex][ConfigValue];
end

--Gets the Insert Slots from the config
function Extraction.GetInsertSlots()
	if not IsCached("InsertSlots") then
		local Config = Extraction.GetConfig();
		local InsertSlots = {};
		for number in StringToNumbers(Config.insertIntoSlot) do
			InsertSlots[#InsertSlots + 1] = number;
		end
		if InsertSlots[1] == "any" then
			InsertSlots = "any";
		end
		SetCachedConfigValue("InsertSlots",InsertSlots);
		return InsertSlots;
	else
		return GetCachedConfigValue("InsertSlots");
	end
end

function Extraction.GetInsertSides()
	if not IsCached("InsertSides") then
		local Config = Extraction.GetConfig();
		local InsertSides = {};
		for str in string.gmatch(Config.insertIntoSide,"[^,]+") do
			InsertSides[#InsertSides + 1] = string.lower(str);
		end
		if InsertSides[1] == "any" then
			InsertSides = {"right","down","left","up"};
		end
		SetCachedConfigValue("InsertSides");
		return InsertSides;
	else
		return GetCachedConfigValue("InsertSides");
	end
end



--Extracts any number values from a string
StringToNumbers = function(str)
	if string.find(str,"any") ~= nil then
		local Returned = false;
		return function()
			if Returned == false then
				Returned = true;
				return "any";
			end
		end
	end
	local seperator = string.gmatch(str,"[^,]+");
	local StoredValues;
	local StoredIndex = 1;
	return function()
		if StoredValues ~= nil then
			if StoredIndex > #StoredValues then
				StoredValues = nil;
			else
				StoredIndex = StoredIndex + 1;
				return StoredValues[StoredIndex - 1];
			end
		end
		local Value = seperator();
		if Value == nil then
			return nil;
		end
		local First,Second = string.match(Value,"%D*(%d+)%D*%-%D*(%d+)");
		if Second ~= nil then
			First,Second = tonumber(First),tonumber(Second);
			StoredValues = {};
			StoredIndex = 2;
			if First > Second then First,Second = Second,First end;
			for i=First,Second do
				StoredValues[#StoredValues + 1] = i;
			end
			if #StoredValues ~= 0 then
				return StoredValues[1];
			end
		end
		First = string.match(Value,"%d+");
		if First ~= nil then
			return tonumber(First);
		end
	end
end

--Iterates over any type of table
UniIter = function(tbl)
	local k,i = nil;
	return function()
		k,i = next(tbl,k);
		return k,i;
	end
end

--If the table was intended to have it's indexes as "number" types, this will make sure it will
--This should be used when passing tables via world.sendEntityMessage because it can convert the indexes to "string" types
MakeNumberTable = function(tbl)
	if type(next(tbl)) == "string" then
		local NewTable = {};
		for k,i in UniIter(tbl) do
			NewTable[tonumber(k)] = i;
		end
		return NewTable;
	else
		return tbl;
	end
end