require("/Core/Callback.lua");
require("/Core/UICore.lua");
require("/Core/Conduit Scripts/Crafting Terminal/ProgressPane.lua");

--Declaration
CraftingUI = {};
local CraftingUI = CraftingUI;

--Variables
local CraftingItemList = "craftableItemsArea.itemList";
local RequirementsItemList = "requirementsArea.itemList";
local SlotsPerRow = 12;
local Data = {};
local SourceID;
local PlayerID;
local SelectedItem;
local SelectedRecipes;
local SelectedRecipeIndex = 0;
local CurrencyData;
local MaximumStack;
--local ProgressCanvas;
--local ProgressCanvasSize;
--local AnchorPoint;
--local LowestRelativePoint;
--local CraftingDisplays = {};

local CraftingAreaEnabled = false;
local CraftingAreaWidgets = {
	"craftAreaStatic",
	"craftAreaDisplaySlot",
	"craftedAtSlot",
	"outputSlot",
	"outputSlotCount",
	"requirementsArea",
	"amountBox",
	"craftButton"
}
local RecipeAreaEnabled = false;
local RecipeAreaWidgets = {
	"previousRecipeButton",
	"nextRecipeButton",
	"recipeCount",
	"recipeCurrentCount",
	"recipeAreaStatic"
}
local RecipeMultiplier = 1;
CraftingUI.Callbacks = Callback.CreateCollection();
local AllRows = {};
local UniversalRefreshRoutine;

--local CraftingList = {};
--local ClientUUID;
--local ChangesUUID;

--Functions
local LearntItemsChange;
local EnableCraftingArea;
local EnableRecipeArea;
local SetAllSlots;
local GetLearntItemsSize;
local UpdateRecipeArea;
local SlotItems = {};
local CurrencyToItem;
local FindCrafterFromGroups;
local SplitNumberIter;
--local AddCraftInfo;
--local RemoveCraftInfo;
local OldUpdate = update;
--local CraftListUpdated;
--local GetPlayersInventory;

--Initializes the Crafting UI
function CraftingUI.Initialize()
	--TEST
	--ProgressCanvas:drawRect({0,0,ProgressCanvasSize[1],ProgressCanvasSize[2]},{255,0,0});
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	PlayerID = pane.sourceEntity();
	--GetPlayersInventory();
	--sb.logInfo("Items = " .. sb.print(world.containerItems(pane.sourceEntity())));
	widget.registerMemberCallback(CraftingItemList,"__SlotClick__",__SlotClick__);
	widget.registerMemberCallback(CraftingItemList,"__SlotRightClick__",__SlotRightClick__);
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("Items",SourceID,"LearntItems",nil);
	UICore.SetAsSyncedValues("Crafters",SourceID,"LearntCrafters",nil);
	MaximumStack = root.assetJson("/items/defaultParameters.config:defaultMaxStack");
	--sb.logInfo("Maximum Stack = " .. sb.print(MaximumStack));
	Data.AddLearntItemsChangeFunction(LearntItemsChange);
	LearntItemsChange();
	ProgressPane.Initialize();
	--[[UICore.AddAsyncCoroutine(function()
		while(true) do
			local Promise = world.sendEntityMessage(SourceID,"UpdateCraftList",ChangesUUID,ClientUUID);
			while not Promise:finished() do
				coroutine.yield();
			end
			--if Promise:result() ~= nil then
			--	sb.logInfo("Promise = " .. sb.printJson(Promise:result(),1));
			--end
			if ClientUUID == nil then
				--Recieving a fresh new table
				CraftingList,ChangesUUID,ClientUUID = table.unpack(Promise:result());
				CraftListUpdated();
			else
				--Receiving potential updates for the table
				if Promise:result() ~= false then
					local Changes;
					Changes,ChangesUUID = table.unpack(Promise:result());
					--local Changes,ChangesUUID = table.unpack(Promise:result());
					for _,change in ipairs(Changes) do
						local TopTable = CraftingList;
						sb.logInfo("PathTOValue = " .. sb.print(change));
						if change.Operation == nil then
							for i=1,#change.PathToValue - 1 do
								if TopTable[change.PathToValue[i] ] == nil then
									TopTable[change.PathToValue[i] ] = {};
								end
								TopTable = TopTable[change.PathToValue[i] ];
							end
						else
							for i=1,#change.PathToValue do
								if TopTable[change.PathToValue[i] ] == nil then
									TopTable[change.PathToValue[i] ] = {};
								end
								TopTable = TopTable[change.PathToValue[i] ];
							end
						end
						if change.Operation == nil then
							TopTable[change.PathToValue[#change.PathToValue] ] = change.NewValue;
						else
							if change.Operation == "Insert" then
								table.insert(TopTable,change.OperationParameters[1],change.NewValue);
							elseif change.Operation == "Remove" then
								table.remove(TopTable,change.NewValue);
							end
						end
					end
					CraftListUpdated();
				end
			end
		end
	end);--]]
end

--Called when the crafting list is updated
--CraftListUpdated = function()
--	sb.logInfo("CraftList = " .. sb.printJson(CraftingList));
--end

--[[update = function(dt)
	if OldUpdate ~= nil then
		OldUpdate(dt);
	end

end--]]

LearntItemsChange = function()
	local LearntItems = Data.GetLearntItems();
	if LearntItems ~= nil then
		if UniversalRefreshRoutine ~= nil then
			UICore.CancelCoroutine(UniversalRefreshRoutine);
		end
		UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
			SetAllSlots();
		end);
	end
end

__SlotClick__ = function(_,data)
	CraftingUI.Callbacks("SlotClick",tonumber(data));
end

__SlotRightClick__ = function(_,data)
	CraftingUI.Callbacks("SlotRightClick",tonumber(data));
end

--Enables and disables the display area for crafting items
EnableCraftingArea = function(bool)
	if CraftingAreaEnabled ~= bool then
		CraftingAreaEnabled = bool;
		for _,w in ipairs(CraftingAreaWidgets) do
			widget.setVisible(w,bool);
		end
	end
end

--Enables and disables the display area for recipe listing
EnableRecipeArea = function(bool)
	if RecipeAreaEnabled ~= bool then
		RecipeAreaEnabled = bool;
		for _,w in ipairs(RecipeAreaWidgets) do
			widget.setVisible(w,bool);
		end
	end
end

--Sets the current selected item to be displayed in the menu for crafting
function CraftingUI.SetSelectedItem(item)
	SelectedItem = item;
	if SelectedItem ~= nil then
		sb.logInfo("LearntCrafters = " .. sb.printJson(Data.GetLearntCrafters() or {},1));
		widget.setItemSlotItem("craftAreaDisplaySlot",item);
		local Recipes = root.recipesForItem(item.name);
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		if #Recipes == 0 then
			SelectedRecipeIndex = 0;
			EnableCraftingArea(false);
			EnableRecipeArea(false);
			widget.setVisible("craftAreaDisplaySlot",true);
			widget.setVisible("noRecipesLabel",true);
		else
			widget.setVisible("noRecipesLabel",false);
			EnableCraftingArea(true);
			SelectedRecipeIndex = 1;
			SelectedRecipes = Recipes;
			if #Recipes > 1 then
				EnableRecipeArea(true);
				--SelectedRecipeIndex = 1;
				widget.setText("recipeCount",#Recipes);
				widget.setText("recipeCurrentCount",SelectedRecipeIndex);
				widget.setText("amountBox","1");
				RecipeMultiplier = 1;
				UpdateRecipeArea(Recipes[SelectedRecipeIndex]);
			else
				SelectedRecipeIndex = 1;
				widget.setText("amountBox","1");
				--RecipeMultiplier = 1;
				UpdateRecipeArea(Recipes[1]);
			end
		end
	else
		EnableCraftingArea(false);
		SelectedRecipeIndex = 0;
		EnableRecipeArea(false);
		widget.setVisible("noRecipesLabel",false);
	end
end

--Updates the Recipe Area Based off of the passed in recipe
UpdateRecipeArea = function(recipe)
	widget.clearListItems(RequirementsItemList);
	for _,input in ipairs(recipe.input) do
		local TotalCount = input.count * RecipeMultiplier;
		sb.logInfo("TotalCount = " .. sb.print(TotalCount));
		sb.logInfo("input = " .. sb.print(input));
		for number in SplitNumberIter(TotalCount,9999) do
			sb.logInfo("number = " .. sb.print(number));
			local RowID = widget.addListItem(RequirementsItemList);
			widget.setItemSlotItem(RequirementsItemList .. "." .. RowID .. ".slot",{name = input.name,count = 1,parameters = input.parameters});
			widget.setText(RequirementsItemList .. "." .. RowID .. ".slotcount",number);
		end
	end
	for currency,amount in pairs(recipe.currencyInputs) do
		local Name = CurrencyToItem(currency);
		sb.logInfo("currency = " .. sb.print(currency));
		if Name ~= nil then
			sb.logInfo("Name = " .. sb.print(Name));
			local TotalCount = amount * RecipeMultiplier;
			for number in SplitNumberIter(TotalCount,9999) do
				local RowID = widget.addListItem(RequirementsItemList);
				widget.setItemSlotItem(RequirementsItemList .. "." .. RowID .. ".slot",{name = Name,count = 1});
				widget.setText(RequirementsItemList .. "." .. RowID .. ".slotcount",number);
			end
		end
	end
	local CrafterItem = FindCrafterFromGroups(recipe.groups);
	if CrafterItem == nil then
		CrafterItem = {name = "unknownCrafter",count = 1};
	end
	widget.setItemSlotItem("craftedAtSlot",CrafterItem);
	widget.setText("outputSlotCount",recipe.output.count * RecipeMultiplier);
	widget.setItemSlotItem("outputSlot",{name = recipe.output.name,count = 1,parameters = recipe.output.parameters});
end

function CraftingUI.GetSlotItem(slot)
	return SlotItems[slot];
end

--Sets all the slot items from the Learnt Items List
SetAllSlots = function()
	local LearntItems = Data.GetLearntItems();
	local Size = GetLearntItemsSize();
	if Size == 0 then 
		widget.clearListItems(CraftingItemList);
		--sb.logInfo("CLEARED");
		AllRows = {};
		SlotItems = {};
		return nil;
	end
	local TotalRowsNeeded = math.ceil(Size / SlotsPerRow);
	--sb.logInfo("Size = " .. sb.print(Size));
	--sb.logInfo("Total Rows Needed = " .. sb.print(TotalRowsNeeded));
	if #AllRows > TotalRowsNeeded then
		for i=#AllRows,TotalRowsNeeded + 1,-1 do
			widget.removeListItem(CraftingItemList,i);
			AllRows[i] = nil;
		end
	elseif TotalRowsNeeded > #AllRows then
		for i=#AllRows + 1,TotalRowsNeeded do
			AllRows[i] = widget.addListItem(CraftingItemList);
		end
	end
	local Row = 1;
	local Slot = 0;
	local GlobalSlot = 0;
	--sb.logInfo("AllRows = " .. sb.print(AllRows));
	local RowID = AllRows[Row];
	local Full = CraftingItemList .. "." .. RowID;
	local SlotPath = nil;
	for item,variants in pairs(LearntItems) do
		for _,variant in ipairs(variants) do
			Slot = Slot + 1;
			if Slot > SlotsPerRow then
				Slot = 1;
				Row = Row + 1;
				--sb.logInfo("Row = " .. sb.print(Row));
				RowID = AllRows[Row];
				Full = CraftingItemList .. "." .. RowID;
				SlotPath = Full .. "." .. "slot" .. Slot;
			else
				SlotPath = Full .. "." .. "slot" .. Slot;
			end
			GlobalSlot = GlobalSlot + 1;
			widget.setVisible(SlotPath,true);
			widget.setData(SlotPath,tostring(GlobalSlot));
			SlotItems[GlobalSlot] = {name = variant.name,count = 1,parameters = variant.parameters};
			widget.setItemSlotItem(SlotPath,SlotItems[GlobalSlot]);
			--[[if UICore.RunningCoroutine() ~= nil then
				coroutine.yield();
			end--]]
		end
	end
	--[[if Slot < SlotsPerRow then
		for i=SlotsPerRow,Slot + 1,-1 do
			local GlobalSlot = (Row - 1) * SlotsPerRow + i;
			widget.setVisible(SlotPath,false);
			SlotItems[GlobalSlot] = nil;
			widget.setItemSlotItem(SlotPath,nil);
		end
	end--]]
end

function RecipePrevious()
	if SelectedRecipeIndex > 1 then
		SelectedRecipeIndex = SelectedRecipeIndex - 1;
		widget.setText("recipeCurrentCount",SelectedRecipeIndex);
		widget.setText("amountBox","1");
		RecipeMultiplier = 1;
		UpdateRecipeArea(SelectedRecipes[SelectedRecipeIndex]);
	end
end

function RecipeNext()
	if SelectedRecipeIndex < #SelectedRecipes then
		SelectedRecipeIndex = SelectedRecipeIndex + 1;
		widget.setText("recipeCurrentCount",SelectedRecipeIndex);
		widget.setText("amountBox","1");
		RecipeMultiplier = 1;
		UpdateRecipeArea(SelectedRecipes[SelectedRecipeIndex]);
	end
end

--Returns the total amount of items in the learnt items list
GetLearntItemsSize = function()
	local Size = 0;
	local LearntItems = Data.GetLearntItems();
	if LearntItems == nil then return 0 end;
	for item,variants in pairs(LearntItems) do
		Size = Size + #variants;
	end
	return Size;
end

--Converts the name of a currency to it's item name
CurrencyToItem = function(currencyName)
	if CurrencyData == nil then
		CurrencyData = root.assetJson("/currencies.config");
	end
	if CurrencyData[currencyName] ~= nil then
		return CurrencyData[currencyName].representativeItem;
	end
end

--Finds the crafter based off of the groups
FindCrafterFromGroups = function(groups)
	local LearntCrafters = Data.GetLearntCrafters();
	for _,group in ipairs(groups) do
		for _,crafter in ipairs(LearntCrafters) do
			for _,filter in ipairs(crafter.CraftingFilters) do
				if filter == group then
					return {name = crafter.name,count = 1,parameters = crafter.parameters};
				end
			end
		end
	end
end

--Called when the craft button is press
function CraftPress()
	--TODO
	sb.logInfo("Press");
	sb.logInfo("SelectedItem = " .. sb.print(SelectedItem));
	if SelectedItem ~= nil and SelectedRecipeIndex ~= 0 then
		sb.logInfo("P2");
		
		UICore.CallMessageOnce(SourceID,"CraftItem",function(Data)
			if Data ~= nil then
				sb.logInfo("RECIEVED DATA = " .. sb.printJson(Data,1));
			else
				sb.logInfo("RECIEVED DATA = nil");
			end
		end,{name = SelectedItem.name,count = SelectedItem.count * RecipeMultiplier,parameters = SelectedItem.parameters},false,SelectedRecipes[SelectedRecipeIndex],player.id());
	end
end

--Called when the amount box has changed
function AmountChange()
	-- TODO
	local Number = tonumber(widget.getText("amountBox"));
	if Number == nil then
		Number = 0;
	end
	if Number == 0 then
		Number = 1;
	end
	--(9999 / SelectedRecipes[SelectedRecipeIndex].output.count)
	if Number > 9999 then
		Number = 9999;
		widget.setText("amountBox",tostring(Number));
	end
	--sb.logInfo("SelectedRecipes = " .. sb.print(SelectedRecipes));
	--sb.logInfo("SelectedRecipeIndex = " .. sb.print(SelectedRecipeIndex));
	if SelectedRecipeIndex ~= 0 then
		RecipeMultiplier = math.ceil((Number / SelectedRecipes[SelectedRecipeIndex].output.count));
		if SelectedRecipes[SelectedRecipeIndex].output.count * RecipeMultiplier > 9999 then
			RecipeMultiplier = math.floor(9999 / SelectedRecipes[SelectedRecipeIndex].output.count);
			--sb.logInfo("RecipeMultiplier = " .. sb.print(RecipeMultiplier));
			widget.setText("amountBox",tostring(RecipeMultiplier * SelectedRecipes[SelectedRecipeIndex].output.count));
		end
		UpdateRecipeArea(SelectedRecipes[SelectedRecipeIndex]);
	end
end

--Iterates over a number while splitting it up into components
SplitNumberIter = function(number,component)
	local Total = number;
	return function()
		if Total == 0 then
			return nil;
		elseif Total >= component then
			Total = Total - component;
			return component;
		else
			local Final = Total;
			Total = 0;
			return Final;
		end
	end
end