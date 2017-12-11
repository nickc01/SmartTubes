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

local Reset = false;

local Craft;
local IncrementCraftIndexer;

local CraftIndex = 0;

local RecipeInfo = {};

local FilterCache = {};

function init()
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
		sb.logInfo("VALUE = " .. sb.print(value));
		NewRecipes = value;
		object.setConfigParameter("Recipes",value);
		Reset = true;
	end);
	Recipes = config.getParameter("Recipes",{});
	sb.logInfo("INIT RECIPE = " .. sb.print(Recipes));
	CraftIndex = 0;
	IncrementCraftIndexer();
	Cables.AddAfterFunction(OnCableUpdate);
end

GetInteractionOfID = function(ID)
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
		Cables.Update();
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
	RecipeInfo[CraftIndex].Value = 0;
	IncrementCraftIndexer();
end

local function ItemsAvailable(Items)
	for k,i in ipairs(Items) do
		if ContainerCore.ContainerAvailable(i) == 0 then
			return false;
		end
	end
	return true;
end

Craft = function(dt)
	if Reset == true then
		Reset = false;
		Recipes = NewRecipes;
		NewRecipes = nil;
		RecipeInfo = {};
		CraftIndex = 0;
		IncrementCraftIndexer();
	end
	--sb.logInfo("Recipes = " .. sb.print(Recipes));
	--sb.logInfo("Recipe Size = " .. sb.print(#Recipes));
	if #Recipes > 0 then
		if RecipeInfo[CraftIndex] == nil then
			RecipeInfo[CraftIndex] = {Value = 0};
		end
		--sb.logInfo("Recipe Groups = " .. sb.print(Recipes[CraftIndex].Recipe.groups));
		--sb.logInfo("Can Craft : " .. sb.print(Recipes[CraftIndex].Recipe.output) .. " = " .. sb.print(CraftersHaveFilters(Recipes[CraftIndex].Recipe.groups)));
		--sb.logInfo("A");
		if CraftersHaveFilters(Recipes[CraftIndex].Recipe.groups) and ContainerCore.ContainerItemsCanFit(Recipes[CraftIndex].Recipe.output) > 0 and ItemsAvailable(Recipes[CraftIndex].Recipe.input) then
			--sb.logInfo("B");
			--CONSUME THE ITEMS
			RecipeInfo[CraftIndex].Value = RecipeInfo[CraftIndex].Value + ((1 / Recipes[CraftIndex].Recipe.duration) * dt);
			if RecipeInfo[CraftIndex].Value > 1 then
				--sb.logInfo("Crafted : " .. sb.print(Recipes[CraftIndex].Recipe.output));
				--world.spawnItem(Recipes[CraftIndex].Recipe.output,entity.position());
				ContainerCore.ContainerAddItems(Recipes[CraftIndex].Recipe.output);
				ResetAndNext();
			end
		else
			ResetAndNext();
		end
	end
end

local Dying = false;

function die()
	Dying = true;
	Cables.Uninitialize();
	local Position;
	if Facaded == true and GetDropPosition ~= nil then
		Position = GetDropPosition();
	end
	ContainerCore.Uninit(true,Position);
end

function uninit()
	if Dying == false then
		local Position;
		if Facaded == true and GetDropPosition ~= nil then
			Position = GetDropPosition();
		end
		ContainerCore.Uninit(false,Position);
	end
end
