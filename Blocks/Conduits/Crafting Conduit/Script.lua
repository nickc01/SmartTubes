require("/Core/Debug.lua");
local Cables;
local EntityID;
local Recipes;
local NewRecipes;
local GetInteractionOfID;
local CraftersHaveFilter;
local TableCheck;
local TableCompare;
local OnCableUpdate;
local OnInteractData;
local Currencies = {};
local CurrencyIndexList = {};
local CurrencyCount = nil;
local Position;

local Speeds = 0;
local CableUpdateInterval = 0.4;
local CableUpdateTimer = 0;
local RecipeTimers = {};

local Reset = false;

local Craft;
local IncrementCraftIndexer;

local CraftIndex = 0;

local RecipeInfo = {};

local FilterCache = {};

function init()
	if root.assetJson("/Core/Debug.json").EnableExperimentalConduits == false then
		object.smash();
	end
	Position = entity.position();
	local CurrencyConfig = root.assetJson("/currencies.config");
	CurrencyCount = config.getParameter("CurrencyCount",{});
	for k,i in pairs(CurrencyConfig) do
		Currencies[#Currencies + 1] = {item = i.representativeItem,currency = k};
		CurrencyIndexList[k] = #Currencies;
		if CurrencyCount[k] == nil then
			CurrencyCount[k] = 0;
		end
	end
	OnInteractData = {sourceId = entity.id(),sourcePosition = entity.position()};
	ContainerCore.Init(65);
	EntityID = entity.id();
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddAdvancedCondition("Crafters",function(ID) 
		local Interaction = GetInteractionOfID(ID);
		if Interaction ~= nil and Interaction[1] == "OpenCraftingInterface" then
			return true;
		end
		return false;
	end);
	message.setHandler("SetRecipes",function(_,_,value)
		--DPrint("VALUE = " .. sb.print(value));
		NewRecipes = value;
		object.setConfigParameter("Recipes",value);
		Reset = true;
	end);
	message.setHandler("SetSpeed",function(_,_,speed)
		Speeds = speed;
		object.setConfigParameter("Speed",speed);
	end);
	message.setHandler("SetCurrencyCount",function(_,_,currency,count)
		CurrencyCount[currency] = count;
		object.setConfigParameter("CurrencyCount",CurrencyCount);
	end);
	Speeds = config.getParameter("Speed",0);
	Recipes = config.getParameter("Recipes",{});
	--DPrint("INIT RECIPE = " .. sb.print(Recipes));
	CraftIndex = 0;
	IncrementCraftIndexer();
	Cables.AddAfterFunction(OnCableUpdate);
end

GetInteractionOfID = function(ID)
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

CraftersHaveFilters = function(filters)
	if Cables.CableTypes.Crafters ~= nil then
		for i=1,#Cables.CableTypes.Crafters do
			if Cables.CableTypes.Crafters[i] ~= -10 then
				local Interaction = GetInteractionOfID(Cables.CableTypes.Crafters[i]);
				if Interaction ~= nil then
					if Interaction[2].filter ~= nil and TableCompare(Interaction[2].filter,filters) then
						return true;
					else
						if Interaction[2].config ~= nil then
							local Filter = root.assetJson(Interaction[2].config).filter;
							if Filter ~= nil and TableCompare(Filter,filters) then
								return true;
							end
						end
					end
				end
			end
		end
		return false;
	end
	return false;
end

TableCheck = function(tbl,value)
	if tbl ~= nil then
		if type(tbl) ~= "table" then
			return tbl == value;
		end
		for i=1,#tbl do
			if tbl[i] == value then
				return true;
			end
		end
		return false;
	end
	return false;
end

TableCompare = function(A,B)
	for i=1,#A do
		for j=1,#B do
			if A[i] == B[j] then
				return true;
			end
		end
	end
	return false;
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	else
		if CableUpdateTimer >= CableUpdateInterval then
			CableUpdateTimer = 0;
			Cables.Update();
		else
			CableUpdateTimer = CableUpdateTimer + dt;
		end
		Craft(dt);
	end
end

IncrementCraftIndexer = function()
	CraftIndex = CraftIndex + 1;
	if CraftIndex > #Recipes then
		CraftIndex = 1;
	end
end

local function ResetAndNext()
	RecipeInfo[CraftIndex] = 0;
	IncrementCraftIndexer();
end

local function ItemsAvailable(Items,matchParameters)
	for k,i in ipairs(Items) do
		if ContainerCore.ContainerAvailable(i,matchParameters) == 0 then
			return false;
		end
	end
	return true;
end

local function ConsumeItems(Items,matchParameters)
	for k,i in ipairs(Items) do
		if ContainerCore.ContainerConsume(i,nil,matchParameters) == false then
			return false;
		end
	end
	return true;
end

local function CurrenciesAvailable(currencies)
	for k,i in pairs(currencies) do
		if CurrencyCount[k] < i then
			return false;
		end
	end
	return true;
end

local function ConsumeCurrencies(currencies)
	for k,i in pairs(currencies) do
		CurrencyCount[k] = CurrencyCount[k] - i;
	end
	object.setConfigParameter("CurrencyCount",CurrencyCount);
	return true;
end

local function IsACurrency(ItemName)
	DPrint("ItemName = " .. sb.print(ItemName));
	for k,i in ipairs(Currencies) do
		DPrint("Comparison = " .. sb.print(i));
		if i.item == ItemName then
			return i.currency;
		end
	end
	return nil;
end

--[[local function GetCurrencyByItem(ItemName)
	for k,i in ipairs(Currencies) do
		if i.item == ItemName then
			return i.currency;
		end
	end
end--]]

Craft = function(dt)
	local SetInfo = false;
	if Reset == true then
		Reset = false;
		Recipes = NewRecipes;
		NewRecipes = nil;
		RecipeInfo = {};
		SetInfo = true;
		CraftIndex = 0;
		IncrementCraftIndexer();
	end
	--DPrint("Recipes = " .. sb.print(Recipes));
	--DPrint("Recipe Size = " .. sb.print(#Recipes));
	if #Recipes > 0 then
		if RecipeInfo[CraftIndex] == nil then
			RecipeInfo[CraftIndex] = 0
			SetInfo = true;
		end
		--DPrint("Recipe Groups = " .. sb.print(Recipes[CraftIndex].Recipe.groups));
		--DPrint("Can Craft : " .. sb.print(Recipes[CraftIndex].Recipe.output) .. " = " .. sb.print(CraftersHaveFilters(Recipes[CraftIndex].Recipe.groups)));
		--DPrint("A");
		if CraftersHaveFilters(Recipes[CraftIndex].Recipe.groups) and ContainerCore.ContainerItemsCanFit(Recipes[CraftIndex].Recipe.output) > 0 and ItemsAvailable(Recipes[CraftIndex].Recipe.input,Recipes[CraftIndex].Recipe.matchInputParameters) and CurrenciesAvailable(Recipes[CraftIndex].Recipe.currencyInputs) then
			--DPrint("B");
			--CONSUME THE ITEMS
				RecipeInfo[CraftIndex] = RecipeInfo[CraftIndex] + ((1 / Recipes[CraftIndex].Recipe.duration) * (dt * ((Speeds + 1) / 2)));
				if RecipeInfo[CraftIndex] > 1 then
					--DPrint("Crafted : " .. sb.print(Recipes[CraftIndex].Recipe.output));
					--world.spawnItem(Recipes[CraftIndex].Recipe.output,entity.position());
					if ConsumeItems(Recipes[CraftIndex].Recipe.input,Recipes[CraftIndex].Recipe.matchInputParameters) then
						ConsumeCurrencies(Recipes[CraftIndex].Recipe.currencyInputs);
						local Currency = IsACurrency(Recipes[CraftIndex].Recipe.output.name);
						if Currency ~= nil then
							CurrencyCount[Currency] = CurrencyCount[Currency] + Recipes[CraftIndex].Recipe.output.count;
							object.setConfigParameter("CurrencyCount",CurrencyCount);
						else
							ContainerCore.ContainerAddItems(Recipes[CraftIndex].Recipe.output);
						end
					end
					ResetAndNext();
				end
				SetInfo = true;
			--[[else
				ResetAndNext();
			end--]]
		else
			if RecipeInfo[CraftIndex] ~= 0 then
				SetInfo = true;
			end
			ResetAndNext();
		end
	end
	if SetInfo == true then
		object.setConfigParameter("RecipeNumbers",RecipeInfo);
	end
end

local Dying = false;

function die()
	Dying = true;
	Cables.Uninitialize();
	if Facaded == true and GetDropPosition ~= nil then
		Position = GetDropPosition();
	end
	for k,i in ipairs(Currencies) do
		if CurrencyCount[i.currency] > 0 then
			world.spawnItem({name = i.item,count = CurrencyCount[i.currency]},Position);
		end
	end
	ContainerCore.Uninit(true,Position);
end

function uninit()
	if Dying == false then
		object.setConfigParameter("CurrencyCount",CurrencyCount);
		if Facaded == true and GetDropPosition ~= nil then
			Position = GetDropPosition();
		end
		ContainerCore.Uninit(false,Position);
	end
end
