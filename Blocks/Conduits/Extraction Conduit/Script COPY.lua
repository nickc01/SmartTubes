local Cables;
local Config;
local ConfigIndex = 1;
local UpdateConfig = false;
local Speed = 0;
local Stack = 0;
local SelectedColor = 1;
local Colors = {};
local ColorNames = {};
local Extract;
local ConfigStorage = {};
local ExtractCache = {};
local CheckInventorySlot;
local FindInsertionConduit;
local CompatibilityLink;
local OnCableUpdate;
local EntityPosition;
local CheckInsertIDs;

local Operators = {};

local function AddOperator(op,func)
	Operators[op] = func;
end

local function CheckOperators(op,Item,string)
	for k,i in pairs(Operators) do
		if k == op then
			if Operators[op](Item,string) == true then
				return true;
			else
				return false;
			end
		end
	end
end

local function Store(name,value)
	if ConfigStorage[ConfigIndex] == nil then
		ConfigStorage[ConfigIndex] = {};
	end
	ConfigStorage[ConfigIndex][name] = value;
end
local function Retrieve(name)
	if ConfigStorage[ConfigIndex] ~= nil and ConfigStorage[ConfigIndex][name] ~= nil then
		return ConfigStorage[ConfigIndex][name];
	end
	return nil;
end

local function HasValue(name)
	if ConfigStorage[ConfigIndex] ~= nil and ConfigStorage[ConfigIndex][name] ~= nil then
		return true;
	end
	return false;
end

local function shuffle(t)
	local n = #t
  	while n > 1 do
    	local k = math.random(n)
    	t[n], t[k] = t[k], t[n]
    	n = n - 1
 	end
 	return t
end

local function RandomIter(t)
	local indexTable = {};
	for i=1,#t do
		indexTable[i] = i;
	end
	indexTable = shuffle(indexTable);
	local n = 0;
	return function()
		n = n + 1;
		return indexTable[n],t[indexTable[n]];
	end
end

local function toNumberOrNil(val)
	if val == nil then
		return nil;
	else
		return tonumber(val);
	end
end

local function StringToNumbers(str)
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

local DELTA = 1;

local function SetDelta()
	local Value = math.ceil(80 / (((Speed + 1) / 2) + 0.5));
	if Value < 10 then
		Value = 10;
	end
	
	DELTA = Value;
	script.setUpdateDelta(Value);
end

local function AddHandlers()
	message.setHandler("SetValue",function(_,_,name,var)
		object.setConfigParameter(name,var);
		if name == "Configs" then
			UpdateConfig = true;
		end
	end);
	message.setHandler("SetSpeed",function(_,_,speed)
		Speed = speed;
		object.setConfigParameter("Speed",speed);
		SetDelta();
	end);
	message.setHandler("SetStack",function(_,_,stack)
		Stack = stack;
		object.setConfigParameter("Stack",stack);
	end);
	message.setHandler("SetColor",function(_,_,selectedColor)
		SelectedColor = selectedColor;
		object.setConfigParameter("SelectedColor",selectedColor);
	end);
end

local oldinit = init;
function init()
	if oldinit ~= nil then
		oldinit();
	end
	
	Cables = CableCore;
	Speed = config.getParameter("Speed",0);
	Stack = config.getParameter("Stack",0);
	Config = config.getParameter("Configs",{});
	--object.setConfigParameter("ConduitName",config.getParameter("shortdescription",""));
	object.setConfigParameter("RetainingParameters",{"Speed","Stack","SelectedColor","Configs"});
	SelectedColor = config.getParameter("SelectedColor",1);
	EntityPosition = entity.position();
	for k, i in ipairs(root.assetJson("/Projectiles/Traversals/Colors.json").Colors) do
		Colors[#Colors + 1] = i[1];
		ColorNames[#ColorNames + 1] = i[2];
	end
	if config.getParameter("routeConfigs") ~= nil or config.getParameter("speeds") ~= nil or config.getParameter("stacks") ~= nil or type(SelectedColor) == "string" then
		CompatibilityLink();
	end
	--CompatibilityLink();
	
	math.randomseed(entity.id());
	
	script.setUpdateDelta(math.random(80,160));
	--script.setUpdateDelta(80);
	AddHandlers();
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	--Cables.AddCondition("Containers","objectType",function(value) return value == "container" end);
	Cables.AddAdvancedCondition("Containers",function(ID) return world.entityExists(ID) and (world.getObjectParameter(ID,"objectType") == "container" or world.callScriptedEntity(ID,"IsContainerCore") == true) end);
	AddOperator("#",function(Item,string) return root.itemType(Item.name) == string end);
	AddOperator("&",function(Item,string) return string.find(string.lower(Item.name),string.lower(string)) ~= nil end);
	AddOperator("@",function(Item,string) return root.itemConfig(Item).config.category == string end);
	AddOperator("%",function(Item,string) return root.itemHasTag(Item.name,string) end);
	Cables.AddAfterFunction(OnCableUpdate);
end

local function GetFPS()
	local Time = os.clock();
	GetFPS = function()
		local NewTime = os.clock();
		local FPS = 1 / ((NewTime - Time) / (60 * script.updateDt()));
		Time = NewTime;
		return FPS;
	end
	return 60;
end

local oldupdate = update;
local First = false;
local Time = nil;
local UpdateRate = 0;
local ConfigIndexResetted = false;
function update(dt)
	if First == false then
		Cables.Initialize();
	end
	if oldupdate ~= nil then
		oldupdate();
	else
		Cables.Update();
	end
	if First == true then
		if Extract() ~= true and #Config > 1 then
			while(true) do
				if Extract() == true or ConfigIndexResetted or #Config < 1 then
					ConfigIndexResetted = false;
					break;
				end
			end
		end
	else
		First = true;
	end
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

CompatibilityLink = function()
	local OldConfig = config.getParameter("routeConfigs");
	if OldConfig ~= nil then
		Config = {};
		for k,i in ipairs(OldConfig) do
			 Config[k] = {};
			 Config[k].itemName = i.itemName;
			 Config[k].insertID = i.insertID;
			 Config[k].takeFromSide = i.exportSide;
			 Config[k].insertIntoSide = i.insertSide;
			 Config[k].takeFromSlot = i.exportSlots;
			 Config[k].insertIntoSlot = i.insertSlots;
			 Config[k].isSpecific = false;
			 Config[k].amountToLeave = i.amountLeave;
		end
		object.setConfigParameter("Configs",Config);
		object.setConfigParameter("routeConfigs",nil);
	end
	if config.getParameter("speeds") ~= nil then
		Speed = config.getParameter("speeds",1) - 1;
		object.setConfigParameter("speeds",nil);
		object.setConfigParameter("Speed",Speed);
	end
	if config.getParameter("stacks") ~= nil then
		Stack = config.getParameter("stacks",1) - 1;
		object.setConfigParameter("stacks",nil);
		object.setConfigParameter("Stack",Stack);
	end
	local OldColor = config.getParameter("SelectedColor");
	if type(OldColor) == "string" then
		local OldSet = false;
		for i=1,#ColorNames do
			if ColorNames[i] == OldColor then
				OldColor = i;
				OldSet = true;
				break;
			end
		end
		if OldSet == false then
			OldColor = 1;
		end
		object.setConfigParameter("SelectedColor",OldColor);
		SelectedColor = OldColor;
	end
end

OnCableUpdate = function()
	
	ResetPathCache();
	--ExtractCache.ExportSides = nil;
end

local FirstRun = false;
Extract = function()
	
	if FirstRun == false then
		FirstRun = true;
		SetDelta();
	end
	if UpdateConfig == true then
		Config = config.getParameter("Configs",{});
		ConfigStorage = {};
		ExtractCache = {};
		UpdateConfig = false;
	end
	if #Config > 0 then
		ConfigIndex = ConfigIndex + 1;
		if ConfigIndex > #Config then
			ConfigIndex = 1;
			ConfigIndexResetted = true;
		end
		local ExportSides;
		if HasValue("TakeFromSides") == true then
			ExportSides = Retrieve("TakeFromSides");
		else
			ExportSides = {};
			for str in string.gmatch(Config[ConfigIndex].takeFromSide,"[^,]+") do
				ExportSides[#ExportSides + 1] = string.lower(str);
			end
			if #ExportSides > 0 then
				if ExportSides[1] == "any" then
					ExportSides = {"right","down","left","up"};
				end
			end
			Store("TakeFromSides",ExportSides);
		end
		local SelectedContainer;
			if Cables.CableTypes.Containers ~= nil then
				--ExtractCache.ExportSides = {};
				
				for k,i in RandomIter(ExportSides) do
					if i == "right" then
						if Cables.CableTypes.Containers[4] > 0 then
							SelectedContainer = Cables.CableTypes.Containers[4];
							--break;
							--ExtractCache.ExportSides[#ExtractCache.ExportSides + 1] = SelectedContainer;
						end
					elseif i == "down" then
						if Cables.CableTypes.Containers[2] > 0 then
							SelectedContainer = Cables.CableTypes.Containers[2];
							--ExtractCache.ExportSides[#ExtractCache.ExportSides + 1] = SelectedContainer;
							--break;
						end
					elseif i == "left" then
						if Cables.CableTypes.Containers[3] > 0 then
							SelectedContainer = Cables.CableTypes.Containers[3];
							--ExtractCache.ExportSides[#ExtractCache.ExportSides + 1] = SelectedContainer;
							--break;
						end
					elseif i == "up" then
						if Cables.CableTypes.Containers[1] > 0 then
							SelectedContainer = Cables.CableTypes.Containers[1];
							--ExtractCache.ExportSides[#ExtractCache.ExportSides + 1] = SelectedContainer;
							--break;
						end
					end
				end
			end
		--end
		if SelectedContainer == nil then return nil end;
		local SelectedSlot = nil;
		local FoundItem = nil;
		local ContainerSize;
		if world.callScriptedEntity(SelectedContainer,"IsContainerCore") == true then
			ContainerSize = world.callScriptedEntity(SelectedContainer,"ContainerCore.ContainerSize");
		else
			ContainerSize = world.containerSize(SelectedContainer);
		end
		
		
		--local ContainerSize = world.containerSize(SelectedContainer);
		if ContainerSize == nil then return nil end;
		
		if HasValue("TakeFromSlots") == true then
			local Numbers = Retrieve("TakeFromSlots");
			for i=1,#Numbers do
				FoundItem,SelectedSlot = CheckInventorySlot(SelectedContainer,Numbers[i],ContainerSize);
				if SelectedSlot ~= nil then
					break;
				end
			end
		else
			local Numbers = {};
			for number in StringToNumbers(Config[ConfigIndex].takeFromSlot) do
				Numbers[#Numbers + 1] = number;
				if SelectedSlot == nil then
					FoundItem,SelectedSlot = CheckInventorySlot(SelectedContainer,number,ContainerSize);
				end
			end
			Store("TakeFromSlots",Numbers);
		end
		
		if SelectedSlot == nil then return nil end;
		
		if HasValue("InsertIntoSides") == false then
			local InsertIntoSides = {};
			for str in string.gmatch(Config[ConfigIndex].insertIntoSide,"[^,]+") do
				InsertIntoSides[#InsertIntoSides + 1] = string.lower(str);
			end
			if #InsertIntoSides > 0 then
				if InsertIntoSides[1] == "any" then
					InsertIntoSides = {"right","down","left","up"};
				end
			end
			Store("InsertIntoSides",InsertIntoSides);
		end
		CheckInsertIDs();
		local InsertionConduit,Path,Occluded = FindInsertionConduit();
		
		if InsertionConduit ~= nil then
			
			local InsertIntoSides = Retrieve("InsertIntoSides");
			local InsertIntoSlots = nil;
			if HasValue("InsertIntoSlots") == true then
				InsertIntoSlots = Retrieve("InsertIntoSlots");
			else
				InsertIntoSlots = {};
				for number in StringToNumbers(Config[ConfigIndex].insertIntoSlot) do
					InsertIntoSlots[#InsertIntoSlots + 1] = number;
				end
				Store("InsertIntoSlots",InsertIntoSlots);
			end
			
			
			
			if world.entityExists(InsertionConduit) == true then
				world.sendEntityMessage(InsertionConduit,"ExtractAndSend",FoundItem,SelectedSlot,SelectedContainer,Path,InsertIntoSides,InsertIntoSlots,nil,Colors[SelectedColor],Speed + 1,nil,Retrieve("InsertID"),Occluded--[[,Retrieve("InsertID")--]]);
				return true;
				--world.callScriptedEntity(InsertionConduit,"ExtractAndSend",nil,nil,FoundItem,SelectedSlot,SelectedContainer,Path,InsertIntoSides,InsertIntoSlots,nil,Colors[SelectedColor],Speed + 1,nil,Retrieve("InsertID")--[[,Retrieve("InsertID")--]]);
			end

		end
	end
end

local function FulFillsConditions(Item)
	if Item ~= nil then
		
		
		
		
		if HasValue("Items") == true then
			Items = Retrieve("Items");
			local FulFills = false;
			local Nots = {};
			for str in string.gmatch(Config[ConfigIndex].itemName,"[%w#&@%%_%^;:,<%.>]+,-") do
				--Items[#Items + 1] = str;
				local FirstCharacter = string.sub(str,1,1);
				if FirstCharacter == "^" then
					Nots[#Nots + 1] = string.sub(str,2);
				else
					if FulFills == false then
						local RawName = string.sub(str,2);
						if str == Item.name then
							FulFills = true;
						elseif str == "any" then
							FulFills = true;
						else
							FulFills = CheckOperators(FirstCharacter,Item,RawName);
						end
					end
				end
			end
			if FulFills == true then
				if #Nots ~= 0 then
					for k,i in ipairs(Nots) do
						local FirstCharacter = string.sub(i,1,1);
						local RawName = string.sub(i,2);
						if i == Item.name then
							FulFills = false;
							break;
						elseif i == "any" then
							FulFills = false;
							break;
						else
							FulFills = not CheckOperators(FirstCharacter,Item,RawName);
							if FulFills == false then
								break;
							end
						end
					end
				end
			end
			return FulFills;
		else
			Items = {};
			local FulFills = false;
			local Nots = {};
			for str in string.gmatch(Config[ConfigIndex].itemName,"[%w#&@%%_%^;:,<%.>]+,-") do
				Items[#Items + 1] = str;
				local FirstCharacter = string.sub(str,1,1);
				if FirstCharacter == "^" then
					Nots[#Nots + 1] = string.sub(str,2);
				else
					if FulFills == false then
						local RawName = string.sub(str,2);
						if str == Item.name then
							FulFills = true;
						elseif str == "any" then
							FulFills = true;
						else
							FulFills = CheckOperators(FirstCharacter,Item,RawName);
						end
					end
				end
			end
			Store("Items",Items);
			if FulFills == true then
				if #Nots ~= 0 then
					for k,i in ipairs(Nots) do
						local FirstCharacter = string.sub(i,1,1);
						local RawName = string.sub(i,2);
						if i == Item.name then
							FulFills = false;
							break;
						elseif i == "any" then
							FulFills = false;
							break;
						else
							FulFills = not CheckOperators(FirstCharacter,Item,RawName);
							if FulFills == false then
								break;
							end
						end
					end
				end
			end
			return FulFills;
		end
	end
	return false;
end

local function TableEqual(o1, o2)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or TableEqual(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

local function CanBeExtracted(Item,Slot,ContainerID)
	local AmountToExtract = Item.count;
	if Config[ConfigIndex].isSpecific == true then
		if TableEqual(Item.parameters,Config[ConfigIndex].specificData) == false then
			return nil;
		end
	end
	if HasValue("AmountToLeave") == true then
		AmountToLeave = Retrieve("AmountToLeave");
	else
		AmountToLeave = {};
		for number in StringToNumbers(Config[ConfigIndex].amountToLeave) do
			if number == "any" then
				number = 0;
			end
			AmountToLeave[#AmountToLeave + 1] = number;
		end
		if #AmountToLeave == 0 then
			AmountToLeave[1] = 0;
		end
		if #AmountToLeave > 1 then
			local ContainerSize;
			if world.callScriptedEntity(ContainerID,"IsContainerCore") == true then
				ContainerSize = world.callScriptedEntity(ContainerID,"ContainerCore.ContainerSize");
			else
				ContainerSize = world.containerSize(ContainerID);
			end
			--local ContainerSize = world.containerSize(ContainerID);
			if #AmountToLeave < ContainerSize then
				for i=1,ContainerSize - #AmountToLeave do
					AmountToLeave[#AmountToLeave + 1] = 0;
				end
			end
		end
		Store("AmountToLeave",AmountToLeave);
	end
	if #AmountToLeave == 1 then
		local StoredCount = Item.count;
		Item.count = 1;
		local TotalInInventory;
		if world.callScriptedEntity(ContainerID,"IsContainerCore") == true then
			TotalInInventory = world.callScriptedEntity(ContainerID,"ContainerCore.ContainerAvailable",Item);
		else
			TotalInInventory = world.containerAvailable(ContainerID,Item);
		end
		--local TotalInInventory = world.containerAvailable(ContainerID,Item);
		Item.count = StoredCount;
		if TotalInInventory - AmountToExtract < AmountToLeave[1] then
			AmountToExtract = AmountToExtract - (AmountToLeave[1] - (TotalInInventory - AmountToExtract));
		end
		if AmountToExtract < 1 then
			return nil;
		end
		if AmountToExtract > (Stack + 1) ^ 2 then
			AmountToExtract = (Stack + 1) ^ 2;
		end
		return AmountToExtract;
	else
		local TotalInInventory = AmountToExtract;
		if TotalInInventory - AmountToExtract < AmountToLeave[Slot] then
			AmountToExtract = AmountToExtract - (AmountToLeave[Slot] - (TotalInInventory - AmountToExtract));
		end
		if AmountToExtract < 1 then
			return nil;
		end
		if AmountToExtract > (Stack + 1) ^ 2 then
			AmountToExtract = (Stack + 1) ^ 2;
		end
		return AmountToExtract;
	end
end

CheckInventorySlot = function(ContainerID,Slot,ContainerSize)
	if Slot == "any" then
		--Any Slot
		for i=1,ContainerSize do
			local Item;
			if world.callScriptedEntity(ContainerID,"IsContainerCore") == true then
				Item = world.callScriptedEntity(ContainerID,"ContainerCore.ContainerItemAt",i - 1);
			else
				Item = world.containerItemAt(ContainerID,i - 1);
			end
			--Item = world.containerItemAt(ContainerID,i - 1);
			if FulFillsConditions(Item) == true then
				local Count = CanBeExtracted(Item,i,ContainerID);
				if Count ~= nil then
					Item.count = Count;
					return Item,i;
				end
			end
		end
	else
		--Defined Slot
		local Item;
		if world.callScriptedEntity(ContainerID,"IsContainerCore") == true then
			Item = world.callScriptedEntity(ContainerID,"ContainerCore.ContainerItemAt",Slot - 1);
		else
			Item = world.containerItemAt(ContainerID,Slot - 1);
		end
		--local Item = world.containerItemAt(ContainerID,Slot - 1);
		if FulFillsConditions(Item) == true then
			local Count = CanBeExtracted(Item,Slot,ContainerID);
			if Count ~= nil then
				Item.count = Count;
				return Item,Slot;
			end
		end
	end
end

local function SelfContainerCount()
	if Cables.CableTypes.Containers ~= nil then
		return #Cables.CableTypes.Containers;
	end
	return 0;
end

function ResetPathCache()
	ExtractCache.Findings = nil;
	ExtractCache.InsertionConduits = nil;
end

CheckInsertIDs = function()
	if HasValue("InsertID") ~= true then
		local ValidInsertionConduits = nil;
		ValidInsertionConduits = {};
		ValidInsertionConduits.Valid = {};
		ValidInsertionConduits.Invalid = {};
		for str in string.gmatch(Config[ConfigIndex].insertID,"[%w_%^!]+,-") do
			if string.find(str,"^%s*%^") ~= nil then
				ValidInsertionConduits.Invalid[#ValidInsertionConduits.Invalid + 1] = string.match(str,"^%s*%^(.*)") or "";
			else
				ValidInsertionConduits.Valid[#ValidInsertionConduits.Valid + 1] = str;
			end
		end
		Store("InsertID",ValidInsertionConduits);
	end
end

FindInsertionConduit = function()
	--local SelfIID = config.getParameter("insertID");
	--if Cables.CableTypes.Conduits == nil then return nil end;
	if ExtractCache.InsertionConduits == nil then
		ExtractCache.InsertionConduits = {};
	end
	local InsertConduits;
	local Findings;
	if ExtractCache.Findings ~= nil and ExtractCache.InsertionConduits[ConfigIndex] ~= nil then
		Findings = ExtractCache.Findings;
		InsertConduits = ExtractCache.InsertionConduits[ConfigIndex];
		
	else
		
		local ValidInsertionConduits = nil;
		if HasValue("InsertID") == true then
			ValidInsertionConduits = Retrieve("InsertID");
		else
			CheckInsertIDs();
		end
		local SelfID = entity.id();
		Findings = {{ID = SelfID,Occluded = config.getParameter("IsOccluded",false)}};
		local Next = {};
		InsertConduits = {};
		local InsertID = config.getParameter("insertID");
		if InsertID ~= nil and SelfContainerCount() > 0 then
			local Valid = false;
			for _,v in ipairs(ValidInsertionConduits.Valid) do
				if v == "any" or v == InsertID or v == "!self" then
					Valid = true;
					break;
				end
			end
			if Valid == true then
				for _,v in ipairs(ValidInsertionConduits.Invalid) do
					if v == "any" or v == InsertID or v == "!self" then
						Valid = false;
						break;
					end
				end
				if Valid == true then
					InsertConduits[#InsertConduits + 1] = Findings[1];
				end
			end
		end
		if Cables.CableTypes.Conduits ~= nil then
			for i=1,4 do
				if Cables.CableTypes.Conduits[i] ~= -10 then
					Next[#Next + 1] = {ID = Cables.CableTypes.Conduits[i],Previous = 1,Occluded = world.getObjectParameter(Cables.CableTypes.Conduits[i],"IsOccluded",false)};
				end
			end
		end
		repeat
			local NewNext = {};
			for i=1,#Next do
				if world.entityExists(Next[i].ID) == true then
					local Conduits = world.callScriptedEntity(Next[i].ID,"CableCore.GetConduits");
					world.callScriptedEntity(Next[i].ID,"AddExtractionConduit",SelfID);
					if Conduits ~= nil then
						for x=1,#Conduits do
							if Conduits[x] ~= -10 then
								local Valid = true;
								for y=1,#Findings do
									if Findings[y].ID == Conduits[x] then
										Valid = false;
										break;
									end
								end
								if Valid == true then
									for y=1,#NewNext do
										if NewNext[y].ID == Conduits[x] then
											Valid = false;
											break;
										end
									end
								end
								if Valid == true then
									NewNext[#NewNext + 1] = {ID = Conduits[x],Previous = #Findings + 1,Occluded = world.getObjectParameter(Conduits[x],"IsOccluded",false)};
								end
							end
						end
						Findings[#Findings + 1] = Next[i];
						if world.entityExists(Next[i].ID) == true then
							local InsertID = world.getObjectParameter(Next[i].ID,"insertID");
							if InsertID ~= nil and world.callScriptedEntity(Next[i].ID,"ContainerCount") > 0 and world.callScriptedEntity(Next[i].ID,"AnySidesHaveContainers",Retrieve("InsertIntoSides")) == true then
								local Valid = false;
								for _,v in ipairs(ValidInsertionConduits.Valid) do
									if v == "any" or v == InsertID then
										Valid = true;
										break;
									end
								end
								if Valid == true then
									for _,v in ipairs(ValidInsertionConduits.Invalid) do
										if v == "any" or v == InsertID then
											Valid = false;
											break;
										end
									end
									if Valid == true then	
										InsertConduits[#InsertConduits + 1] = Next[i];
									end
								end
							end
						end
					end
				end
			end
			Next = NewNext;
		until #Next == 0;
		ExtractCache.Findings = Findings;
		ExtractCache.InsertionConduits[ConfigIndex] = InsertConduits;
	end

	if #InsertConduits == 0 then return nil end;
	local SelectedInsertionConduit = InsertConduits[math.random(1,#InsertConduits)];
	if not world.entityExists(SelectedInsertionConduit.ID) then
		ResetPathCache();
		return nil;
	end
	local NextLevel = SelectedInsertionConduit.Previous;
	local Path = {SelectedInsertionConduit.ID};
	local Occluded = true;
	if NextLevel ~= nil then
		repeat
			local Point = Findings[NextLevel];
			Path[#Path + 1] = Point.ID;
			NextLevel = Point.Previous;
			if Occluded == true then
				Occluded = Point.Occluded;
			end
		until NextLevel == nil
	end
	return SelectedInsertionConduit.ID,Path,Occluded;
end

function die()
	--Cables.UpdateOthers();
	local DropPos;
	if Facaded == true and GetDropPosition ~= nil then
		DropPos = GetDropPosition() or EntityPosition;
	else
		DropPos = EntityPosition;
	end
	if Cables.Smashing == false then
		world.spawnItem({name = "speedupgrade",count = Speed},DropPos);
		world.spawnItem({name = "stackupgrade",count = Stack},DropPos);
	end
	Cables.Uninitialize();
end

function uninit()
	
end
