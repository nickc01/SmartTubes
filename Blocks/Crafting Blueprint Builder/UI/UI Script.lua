require('/Core/ImageCore.lua');
require("/Core/CraftersCore.lua");
--Declaration
Monitor = {};
local Monitor = Monitor;

--Monitor Variables
local ScannedItem;
local ScanningSlotWidget = "scanningSlot";
local RecipeList = "recipeArea.itemList";
local InputElementSize;
local TopLeftCornerInputArea = {4,93};
local BottomRightCornerInputArea = {67,11};
local UpArrowFuncs = {};
local DownArrowFuncs = {};
local UpdateFuncs = {};
local Recipes;
local Currencies;
local LearntCrafters;

--Variables


--Functions
local ItemsEqual;
local Update;
local OldUpdate = update;
local SplitIter;


function init()
	InputElementSize = config.getParameter("gui.recipeArea.children.itemList.schema.listTemplate.inputList.schema.memberSize");
	Currencies = root.assetJson("/currencies.config");
	LearntCrafters = world.getProperty("LearntCrafters") or {};
	TopLeftCornerInputArea[2] = TopLeftCornerInputArea[2] - InputElementSize[2];
	sb.logInfo("InputSize = " .. sb.print(InputElementSize));
	sb.logInfo("TOpLeftCOrnerArea = " .. sb.print(TopLeftCornerInputArea));
	widget.registerMemberCallback(RecipeList,"UpArrowPress",UpArrowPress);
	widget.registerMemberCallback(RecipeList,"DownArrowPress",DownArrowPress);
	--[[widget.addListItem(RecipeList);
	widget.addListItem(RecipeList);
	InputElementSize = config.getParameter("gui.recipeArea.children.itemList.schema.memberSize");
	sb.logInfo("InputElementSize = " .. sb.print(InputElementSize));
	local Test = widget.addListItem(RecipeList);
	local Full = RecipeList .. "."  .. Test;
	local NewListPath = Full .. ".sampleList";
	local Position = widget.getPosition(NewListPath);
	sb.logInfo("Position = " .. sb.print(Position));
	widget.setPosition(NewListPath,{5,11});
	sb.logInfo("NewListPath = " .. sb.print(NewListPath));
	for i=1,4 do
		local NewElement = widget.addListItem(NewListPath);
		local FullElement = NewListPath .. "." .. NewElement .. ".TESTNUMBER";
		widget.setText(FullElement,tostring(i));
	end--]]
	--widget.addListItem(NewListPath);
	--widget.addListItem(NewListPath);
end

update = function(dt)
	if OldUpdate ~= nil then
		OldUpdate(dt);
	end
	for _,func in pairs(UpdateFuncs) do
		func(dt);
	end
end

function scannerClick()
	Monitor.SetScanningItem(player.swapSlotItem());
end

function scannerRClick()
	Monitor.SetScanningItem(nil);
end






ItemsEqual = function(a,b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b;
	else
		return root.itemDescriptorsMatch(a,b,true);
	end
end


--Monitor Functions

function Monitor.SetScanningItem(item)
	if not ItemsEqual(item,ScannedItem) then
		ScannedItem = item;
		widget.setItemSlotItem(ScanningSlotWidget,ScannedItem);
		widget.clearListItems(RecipeList);
		UpArrowFuncs = {};
		DownArrowFuncs = {};
		UpdateFuncs = {};
		Recipes = {};
		if ScannedItem ~= nil then
			local ItemRecipes = root.recipesForItem(ScannedItem.name);
			for _,recipe in ipairs(ItemRecipes) do
				sb.logInfo("recipe = " .. sb.print(recipe));
				local NewItem = widget.addListItem(RecipeList);
				Recipes[NewItem] = recipe;
				local Full = RecipeList .. "." .. NewItem;
				widget.setData(Full .. ".inputArrowUp",NewItem);
				widget.setData(Full .. ".inputArrowDown",NewItem);
				widget.setItemSlotItem(Full .. ".outputSlot",recipe.output);
				local Groups = recipe.groups;
				local Crafter = CraftersCore.GroupsToItem(Groups);
				--sb.logInfo("CRAFTER = " .. sb.print(Crafter));
				if Crafter == "Player" then
					widget.setItemSlotItem(Full .. ".crafterSlot","playerCrafter");
				elseif Crafter == nil then
					widget.setItemSlotItem(Full .. ".crafterSlot","unknownCrafter");
				else
					widget.setItemSlotItem(Full .. ".crafterSlot",Crafter);
				end
				if Crafter == nil then
					Crafter = "Unknown";
				end
				recipe.Crafter = Crafter;
				local InputList = Full .. ".inputList";
				widget.setPosition(InputList,{5,11});
				local CurrentInputPosition = {5,11};
				local Inputs = {};
				sb.logInfo("Recipe = " .. sb.printJson(recipe,1));
				local InputCount = 0;
				for _,input in ipairs(recipe.input) do
					local InputItem = widget.addListItem(InputList);
					local InputFull = InputList .. "." .. InputItem;
					Inputs[#Inputs + 1] = {
						Local = InputItem,
						Global = InputFull
					}
					InputCount = InputCount + 1;
					widget.setItemSlotItem(InputFull .. ".inputSlot",input);
				end
				for currency,amount in pairs(recipe.currencyInputs) do
					local CurrencyItem = Currencies[currency].representativeItem;
					for itemAmount in SplitIter(amount,1000) do
						local InputItem = widget.addListItem(InputList);
						local InputFull = InputList .. "." .. InputItem;
						Inputs[#Inputs + 1] = {
							Local = InputItem,
							Global = InputFull
						}
						InputCount = InputCount + 1;
						widget.setItemSlotItem(InputFull .. ".inputSlot",{name = CurrencyItem,count = itemAmount});
					end
				end
				--local TopInput = widget.getPosition(Inputs[1].Global);
				--sb.logInfo("TopInput = " .. sb.print(TopInput));
				local OldPosition = CurrentInputPosition[2];
				if InputCount > 0 then
					widget.setPosition(InputList,{CurrentInputPosition[1],TopLeftCornerInputArea[2] - widget.getPosition(Inputs[1].Global)[2] + CurrentInputPosition[2]});
				else
					widget.setPosition(InputList,{CurrentInputPosition[1],TopLeftCornerInputArea[2] + CurrentInputPosition[2]});
				end
				local NewPosition = widget.getPosition(InputList)[2];
				sb.logInfo("OldPosition = " .. sb.print(OldPosition));
				sb.logInfo("NewPosition = " .. sb.print(NewPosition));
				if InputCount > 4 then
					widget.setVisible(Full .. ".inputArrowUp",true);
					widget.setVisible(Full .. ".inputArrowDown",true);
					local Bottom = NewPosition - 1;
					local BottomInput = widget.getPosition(Inputs[1].Global);
					sb.logInfo("BottomInput = " .. sb.print(BottomInput));
					local Diff = 0 - BottomInput[2];
					local Top = OldPosition + 1;
					local Current = Bottom;
					local FinalCurrent = Current;
					sb.logInfo("Top = " .. sb.print(Top));
					sb.logInfo("Bottom = " .. sb.print(Bottom));
					sb.logInfo("Diff = " .. sb.print(Diff));

					UpdateFuncs[NewItem] = function(dt)
						FinalCurrent = (Current - FinalCurrent) * (dt * 7) + FinalCurrent;
						widget.setPosition(InputList,{CurrentInputPosition[1],FinalCurrent});
					end

					UpArrowFuncs[NewItem] = function(amount)
						Current = Current - amount;
						if Current < Bottom then
							Current = Bottom;
						end
						--widget.setPosition(InputList,{CurrentInputPosition[1],Current});
					end
					DownArrowFuncs[NewItem] = function(amount)
						Current = Current + amount;
						if Current > Top then
							Current = Top;
						end
						--widget.setPosition(InputList,{CurrentInputPosition[1],Current});
					end
				end
			end
		end
	end
end

CraftingGroupsToItem = function(Groups)
	--First, Check if it's in the Learnt List Already
	LearntCrafters = world.getProperty("LearntCrafters") or {};
	local Item = GetFromLearntList(Groups);
	if Item ~= nil then
		return Item;
	end
	--Second, Check the Network to see if it's there
	local Network = ConduitCore.GetConduitNetwork();
	for _,conduit in ipairs(Network) do
		local Type = world.getObjectParameter(conduit,"conduitType");
		if Type == "crafting" then
			local Filters = world.callScriptedEntity(conduit,"GetCraftingFilters");
			if Filters ~= nil then
				for _,filter in ipairs(Filters) do
					if TableIntersect(filter.CraftingFilters,Groups) == true then
						AddLearntCrafter(Groups,filter.CraftingFilters);
						return filter;
					end
				end
			end
		end
	end
	--Third, check if the groups have the same name as an item
	for _,group in ipairs(Groups) do
		local Item = root.createItem({name = group,count = 1});
		if Item ~= nil then
			AddLearntCrafter(Groups,Item);
			return Item;
		end
	end
	return nil;
	
end

AddLearntCrafter = function(Groups,Item)
	LearntCrafters = world.getProperty("LearntCrafters") or {};
	for groups,item in pairs(LearntCrafters) do
		if root.itemDescriptorsMatch(item,Item,true) then
			return nil;
		end
	end
	LearntCrafters[Groups] = Item;
	--object.setConfigParameter("LearntCrafters",LearntCrafters);
	world.setProperty("LearntCrafters",LearntCrafters);
end

GetFromLearntList = function(Groups)
	for groups,item in pairs(LearntCrafters) do
		if TableIntersect(groups,Groups) then
			return item;
		end
	end
	return nil;
end

function UpArrowPress(A,B)
	--sb.logInfo("A1 = " .. sb.print(A));
	--sb.logInfo("B1 = " .. sb.print(B));
	--sb.logInfo("C1 = " .. sb.print(C));
	--sb.logInfo("D1 = " .. sb.print(D));
	if UpArrowFuncs[B] ~= nil then
		UpArrowFuncs[B](InputElementSize[2]);
	end  
end

function DownArrowPress(A,B)
	if DownArrowFuncs[B] ~= nil then
		DownArrowFuncs[B](InputElementSize[2]);
	end
	--sb.logInfo("A2 = " .. sb.print(A));
	--sb.logInfo("B2 = " .. sb.print(B));
	--sb.logInfo("C2 = " .. sb.print(C));
	--sb.logInfo("D2 = " .. sb.print(D));
end

function blankClick()
	--If slot is empty
	local SlotItem = widget.itemSlotItem("blankBlueprintSlot");
	local SwapItem = player.swapSlotItem();
	if SlotItem == nil then
		--Set the slot Item equal to the Swap Item
		widget.setItemSlotItem("blankBlueprintSlot",SwapItem);
		player.setSwapSlotItem(nil);
	else
		--If the swap item is the same as the slot item
		if SwapItem ~= nil and root.itemDescriptorsMatch(SwapItem,SlotItem,true) then
			--Merge the contents
			local MaxStack = root.itemConfig(SlotItem).config.maxStack or 1000;
			local NewAmount = {name = SwapItem.name,count = SlotItem.count + SwapItem.count,parameters = SwapItem.parameters};
			if NewAmount.count > MaxStack then
				NewAmount.count = MaxStack;
			end
			widget.setItemSlotItem("blankBlueprintSlot",NewAmount);
			if NewAmount.count == SwapItem.count + SlotItem.count then
				player.setSwapSlotItem(nil);
			else
				local FinalSwapItem = {name = SwapItem.name,count = SwapItem.count + SlotItem.count - NewAmount.count,parameters = SwapItem.parameters};
				player.setSwapSlotItem(FinalSwapItem);
			end
		else
			--Just Swap the contents around
			widget.setItemSlotItem("blankBlueprintSlot",SwapItem);
			player.setSwapSlotItem(SlotItem);
		end
	end
end

function blankRClick()
	local SlotItem = widget.itemSlotItem("blankBlueprintSlot");
	if SlotItem == nil then return nil end;
	local SwapItem = player.swapSlotItem();
	local MaxStack = root.itemConfig(SlotItem).config.maxStack or 1000; 
	if SwapItem == nil or (root.itemDescriptorsMatch(SlotItem,SwapItem,true) == true and SwapItem.count < MaxStack) then
		if SwapItem == nil then
			local NewSwapItem = {name = SlotItem.name,count = 1,parameters = SlotItem.parameters};
			SlotItem.count = SlotItem.count - 1;
			if SlotItem.count == 0 then
				SlotItem = nil;
			end
			player.setSwapSlotItem(NewSwapItem);
			widget.setItemSlotItem("blankBlueprintSlot",SlotItem);
		else
			SwapItem.count = SwapItem.count + 1;
			SlotItem.count = SlotItem.count - 1;
			if SlotItem.count == 0 then
				SlotItem = nil;
			end
			player.setSwapSlotItem(SwapItem);
			widget.setItemSlotItem("blankBlueprintSlot",SlotItem);
		end
	end
end

function finalClick()
	if player.swapSlotItem() == nil then
		player.setSwapSlotItem(widget.itemSlotItem("blueprintSlot"));
		widget.setItemSlotItem("blueprintSlot",nil);
	end
end

function finalRClick()
	return finalClick();
end

function createBlueprint()
	local SlotItem = widget.itemSlotItem("blankBlueprintSlot");
	local BlueprintSlotItem = widget.itemSlotItem("blueprintSlot");
	local SelectedRecipe = widget.getListSelected(RecipeList);
	if SelectedRecipe ~= nil and BlueprintSlotItem == nil and SlotItem ~= nil and SlotItem.count > 0 and SlotItem.parameters ~= nil and SlotItem.parameters.blueprintItem == nil then
		local Recipe = Recipes[SelectedRecipe];
		local Output = Recipe.output;
		local Parameters = {};
		local Config = root.itemConfig(Output);
		sb.logInfo("Config = " .. sb.print(Config));
		local Image = ImageCore.MakePathAbsolute(Config.config.inventoryIcon,Output.name);
		local ImageSize = root.imageSize(Image);
		local Scaler = "";
		local Crop = "";
		if ImageSize[1] > 16 or ImageSize[2] > 16 then
			Scaler = "?scalenearest=" .. tostring(16 / ImageSize[1]) .. ";" .. tostring(16 / ImageSize[2]);
			ImageSize = {16,16};
		end
		--Crop = "?blendmult=/Items/Crafting Blueprint/Icon Crop.png";
		--[[if ImageSize[1] > 14 or ImageSize[2] > 14 then
			local TopCrop = math.floor((ImageSize[1] - 14) / 2);
			local BottomCrop = ImageSize[1] - 14 - TopCrop;
			local LeftCrop = math.floor((ImageSize[2] - 14) / 2);
			local RightCrop = ImageSize[2] - 14 - LeftCrop;
			--Crop = "?crop=1;1;1;1";
			--Crop = "?crop=" .. LeftCrop .. ";" .. BottomCrop .. ";" .. RightCrop .. ";" .. TopCrop;
		end--]]
		--Crop = Crop .. "?border=-1;FFFFFFFF;FFFFFFFF";
		--Parameters.inventoryIcon = "/Items/Crafting Blueprint/Icon Blend.png?blendmult=" .. Image .. "?blendscreen=/Items/Crafting Blueprint/Icon Transparency Filter.png";
		Parameters.inventoryIcon = Image .. Scaler .. Crop .. "?blendmult=" .. "/Items/Crafting Blueprint/Icon Blend.png" .. "?blendscreen=/Items/Crafting Blueprint/Icon Transparency Filter.png";
		Parameters.shortdescription = "Blueprint : " .. tostring(Output.count) .. "x " .. Config.config.shortdescription;
		Parameters.description = "^#fffa00;Inputs^reset; = ";
		Parameters.Recipe = Recipe;
		Parameters.Crafter = Recipe.Crafter;
		Parameters.blueprintItem = Output;
		--Parameters.Crafter = 
		local CrafterDescription = "";
		if type(Parameters.Crafter) == "table" then
			CrafterDescription = "Crafted At: " .. Parameters.Crafter.name .. "\n";
		else
			CrafterDescription = "Crafted At: " .. Parameters.Crafter .. "\n";
		end
		Parameters.description = CrafterDescription .. Parameters.description;
		local InputCount = 0;
		for _,input in ipairs(Recipe.input) do
			InputCount = InputCount + 1;
			Parameters.description = Parameters.description .. "^#ffb600;" .. input.name .. "^#ff6d42; " .. input.count .. "x^reset; , ";
		end
		for currency,amount in pairs(Recipe.currencyInputs) do
			InputCount = InputCount + 1;
			Parameters.description = Parameters.description .. "^#ffb600;" .. currency .. "^#ff6d42; " .. amount .. "x^reset; , ";
		end
		if InputCount > 0 then
			Parameters.description = string.sub(Parameters.description,0,-3);
		else
			Parameters.description = "No Inputs Needed";
		end
		widget.setItemSlotItem("blueprintSlot",{name = "craftingblueprint",count = 1,parameters = Parameters});
		SlotItem.count = SlotItem.count - 1;
		if SlotItem.count == 0 then
			SlotItem = nil;
		end
		widget.setItemSlotItem("blankBlueprintSlot",SlotItem);
	end
end

SplitIter = function(number,splitAmount)
	local Remaining = number;
	return function()
		if Remaining == 0 then
			return nil;
		elseif Remaining < splitAmount then
			local ReturnValue = Remaining;
			Remaining = 0;
			return ReturnValue;
		else
			Remaining = Remaining - splitAmount;
			return splitAmount;
		end
	end
end