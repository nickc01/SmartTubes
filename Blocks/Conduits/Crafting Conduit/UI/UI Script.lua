require ("/Core/ArgonGUI/Argon.lua");
local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;
local UpdateCurrencySlot;
local UpdateCurrencyCount;
local SourceID;
local Recipes;
local Speeds = 0;
local SpeedMax = 20;
local Currencies = {};
local CurrencyIndex = 1;
local CurrencyAddedIndex = 1;
--Canvases
local RecipeCanvas;
local AddedRecipeCanvas;

--local AddedRecipes = {};

--Elements
local RecipeScrollbar;
local RecipeList;
local AddedRecipeScrollbar;
local AddedRecipeList;

local SelectedRecipeElement;
local SelectedAddedRecipeElement;

local SpeedItem = {name = "speedupgrade",count = 1};

local Rarities = {
	common = "/interface/inventory/itembordercommon.png",
	uncommon = "/interface/inventory/itemborderuncommon.png",
	rare = "/interface/inventory/itemborderrare.png",
	legendary = "/interface/inventory/itemborderlegendary.png",
	essential = "/interface/inventory/itemborderessential.png"
}

local function UniIter(tbl)
	for k,i in ipairs(tbl) do
		return ipairs(tbl);
	end
	return pairs(tbl);
end

local CraftingGroups;

local function GetCraftingGroup(group)
	if CraftingGroups[group] ~= nil then
		return CraftingGroups[group];
	end
	return nil;
end


local ItemConfigs = setmetatable({},{ __mode = 'v'})

local function GetConfig(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	return ItemConfigs[ItemName].config;
end

local function GetItemRarity(ItemName)
	return string.lower(GetConfig(ItemName).rarity or "Common");
end

local function GetPosFromImage(Image,CenterPos)
	local Scale = 1;
	local ImageSize = root.imageSize(Image);
	if math.max(ImageSize[1],ImageSize[2]) > 16 then
		Scale = 16 / math.max(ImageSize[1],ImageSize[2]);
		ImageSize[1] = ImageSize[1] * Scale;
		ImageSize[2] = ImageSize[2] * Scale;
		Image = Image .. "?scalenearest=" .. tostring(Scale);
	end
	return Image,{CenterPos[1] - ImageSize[1] / 2, CenterPos[2] - ImageSize[2] / 2};
end

local function GetItemImage(ItemName,CenterPos)
	local IMG;
	local Config;
	if ItemConfigs[ItemName] == nil then
		Config = root.itemConfig(ItemName);
		ItemConfigs[ItemName] = Config;
	else
		Config = ItemConfigs[ItemName];
	end
	local IMG = Config.config.inventoryIcon;
	if string.find(IMG,"^/") == nil then
		local Directory = Config.directory;
		if string.find(Directory,"/$") == nil then
			IMG = Directory .. "/" .. IMG;
		else
			IMG = Directory .. IMG;
		end
	end
	return GetPosFromImage(IMG,CenterPos);
end


local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]}
end

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function AddRecipeToList(Item,Recipe,Canvas,List)
	Canvas = Canvas or "RecipeCanvas";
	List = List or RecipeList;
	local GroupIndex = 0;
	local Group;
	for GroupIndex=1,#Recipe.groups do
		Group = GetCraftingGroup(Recipe.groups[GroupIndex]);
		if Group ~= nil then
			break;
		end
	end
	if Group == nil then
		Group = {Name = "Unknown"};
	end
	local Element = List.AddElement();

	--Output Item Rarity Image
	local SourceItemRarity = Argon.CreateElement("Image",Canvas,Rarities[GetItemRarity(Recipe.output.name)],{98,64});
	Element.AddChild(SourceItemRarity);

	--Output Item Image
	local SourceItemImage,SourceItemPos = GetItemImage(Recipe.output.name,{107,73});
	local SourceItem = Argon.CreateElement("Image",Canvas,SourceItemImage,SourceItemPos);
	Element.AddChild(SourceItem);
	--Output Item Amount
	local OutputAmountText = Argon.CreateElement("Text",Canvas,{99,54},"Thin",7);
	OutputAmountText.SetString(tostring(Recipe.output.count));
	Element.AddChild(OutputAmountText);


	--Required Items Scrollbar
	local RequiredItemsScrollbar = Argon.CreateElement("Scrollbar",Canvas,{1,38,95,47},{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderRight.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderLeft.png",
		ScrollerHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderMidHL.png",
		ScrollerTopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderRightHL.png",
		ScrollerBottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderLeftHL.png"
	},
	{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundRight.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundLeft.png"
	},
	{
		Top = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowRight.png",
		Bottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowLeft.png",
		TopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowRightHL.png",
		BottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowLeftHL.png"
	},"Horizontal",5,0);
	Element.AddChild(RequiredItemsScrollbar);

	--Required Items List
	local RequiredItems = Argon.CreateElement("List",Canvas,{1,48,95,90},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Active =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Selected =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
	},"Right",RequiredItemsScrollbar);
	-- Add Required Items
	for i=1,#Recipe.input do
		local NewElement = RequiredItems.AddElement();
		--Required Item Amount
		local AmountText = Argon.CreateElement("Text",Canvas,{1,0},"Thin",7);
		AmountText.SetString(tostring(Recipe.input[i].count));
		NewElement.AddChild(AmountText);

		--Required Item Rarity Image
		local RequiredItemRarity = Argon.CreateElement("Image",Canvas,Rarities[GetItemRarity(Recipe.input[i].name)],{0,9});
		NewElement.AddChild(RequiredItemRarity);

		--Required Item Image
		local RequiredItemImage,RequiredItemPos = GetItemImage(Recipe.input[i].name,{9,18});
		local RequiredItem = Argon.CreateElement("Image",Canvas,RequiredItemImage,RequiredItemPos);
		local ItemName = Recipe.input[i].name;
		RequiredItem.SetClickFunction(function(Position,ButtonType,Clicking)
			--sb.logInfo("Clicking over Image = " .. sb.print(Clicking));
			--sb.logInfo("MouseType = " .. sb.print(ButtonType));
			if ButtonType == 0 then
				--sb.logInfo(sb.print(i) .. " mode = " .. sb.print(Clicking));
				if Clicking == true then
					Element.SetDescriptionActive(Clicking);
					Element.SetDescription(GetConfig(ItemName).shortdescription or ItemName);
				else
					Element.SetDescriptionActive(false);
				end
			end
		end);
		NewElement.AddChild(RequiredItem);
	end
	for k,i in pairs(Recipe.currencyInputs) do
		if i <= 9999 then
			local NewElement = RequiredItems.AddElement();
			--Currency Amount
			local AmountText = Argon.CreateElement("Text",Canvas,{1,0},"Thin",7);
			AmountText.SetString(tostring(i));
			NewElement.AddChild(AmountText);
			--Required Currency Image
			local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
			local RequiredCurrency = Argon.CreateElement("Image",Canvas,RequiredCurrencyImage,RequiredCurrencyPos);
			local ItemName = k;
			RequiredCurrency.SetClickFunction(function(Position,ButtonType,Clicking)
				--sb.logInfo("Clicking over Image = " .. sb.print(Clicking));
				--sb.logInfo("MouseType = " .. sb.print(ButtonType));
				if ButtonType == 0 then
					--sb.logInfo(sb.print(i) .. " mode = " .. sb.print(Clicking));
					if Clicking == true then
						Element.SetDescriptionActive(Clicking);
						Element.SetDescription(GetConfig(ItemName).shortdescription or ItemName);
					else
						Element.SetDescriptionActive(false);
					end
				end
			end);
			NewElement.AddChild(RequiredCurrency);
		else
			local CurrencyRequired = i;
			repeat
				local NewElement = RequiredItems.AddElement();
				--Currency Amount
				local SubtractedCurrency = nil;
				if CurrencyRequired <= 9999 then
					SubtractedCurrency = CurrencyRequired;
					CurrencyRequired = 0;
				else
					SubtractedCurrency = 9999;
					CurrencyRequired = CurrencyRequired - SubtractedCurrency;
				end

				local AmountText = Argon.CreateElement("Text",Canvas,{1,0},"Thin",7);
				AmountText.SetString(tostring(SubtractedCurrency));
				NewElement.AddChild(AmountText);
				--Required Currency Image
				local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
				local RequiredCurrency = Argon.CreateElement("Image",Canvas,RequiredCurrencyImage,RequiredCurrencyPos);
				local ItemName = k;
				RequiredCurrency.SetClickFunction(function(Position,ButtonType,Clicking)
					--sb.logInfo("Clicking over Image = " .. sb.print(Clicking));
					--sb.logInfo("MouseType = " .. sb.print(ButtonType));
					if ButtonType == 0 then
						--sb.logInfo(sb.print(i) .. " mode = " .. sb.print(Clicking));
						if Clicking == true then
							Element.SetDescriptionActive(Clicking);
							Element.SetDescription(GetConfig(ItemName).shortdescription or ItemName);
						else
							Element.SetDescriptionActive(false);
						end
					end
				end);
				NewElement.AddChild(RequiredCurrency);
			until (CurrencyRequired == 0);


		end
	end

	Element.AddChild(RequiredItems);

	local CraftedAtText = Argon.CreateElement("Text",Canvas,{1,2},"Default");
	CraftedAtText.SetString(Group.Name);
	--CraftedAtText.SetColor({255,255,255});
	Element.AddChild(CraftedAtText);

	if Group.SlotItem ~= nil then
		--Item Slot
		local ItemSlot = Argon.CreateElement("Image",Canvas,"/interface/actionbar/actionbarcover.png",{2,9});
		Element.AddChild(ItemSlot);

		--Item Image
		--sb.logInfo("Group = " .. sb.print(Group));
		local CrafterItemImage,CrafterItemPos = nil,nil;
		if string.match(Group.SlotItem,"^/") == nil then
			CrafterItemImage,CrafterItemPos	= GetItemImage(Group.SlotItem,{11,18});
		else
			CrafterItemImage,CrafterItemPos = GetPosFromImage(Group.SlotItem,{11,18});
		end
		local CrafterItem = Argon.CreateElement("Image",Canvas,CrafterItemImage,CrafterItemPos);
		Element.AddChild(CrafterItem);
	end
	--Description Background
	local DescriptionBackground = Argon.CreateElement("Image",Canvas,"/Blocks/Conduits/Crafting Conduit/UI/Window/ItemNameArea.png",{1,34});
	Element.AddChild(DescriptionBackground);

	--Description Text
	local DescriptionText = Argon.CreateElement("Text",Canvas,{2,40},"Default");
	DescriptionText.SetString("");
	--Max 15
	--CraftedAtText.SetColor({255,255,255});
	Element.AddChild(DescriptionText);

	Element.SetDescription = function(text)
		if string.len(text) > 15 then
			text = string.concat(1,14) .. "...";
		end
		DescriptionText.SetString(text);
	end

	Element.SetDescriptionActive = function(bool)
		DescriptionText.SetActive(bool);
		DescriptionBackground.SetActive(bool);
	end
	DescriptionText.SetActive(false);
	DescriptionBackground.SetActive(false);

	--Percentage Text
	local PercentageText = Argon.CreateElement("Text",Canvas,{96,39},"Default");
	PercentageText.SetString("");
	--CraftedAtText.SetColor({255,255,255});
	Element.AddChild(PercentageText);

	Element.Item = Item;
	Element.Recipe = Recipe;
	Element.SetPercentage = function(num)
		num = math.floor(num * 100);
		if num == 0 then
			PercentageText.SetString("");
		elseif num < 10 then
			PercentageText.SetString("  " .. tostring(num) .. "%");
		elseif num < 100 then
			PercentageText.SetString(" " .. tostring(num) .. "%");
		else
			PercentageText.SetString(tostring(num) .. "%");
		end
	end
	return Element;

	
end

function init()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	local CurrencyConfig = root.assetJson("/currencies.config");
	for k,i in pairs(CurrencyConfig) do
		Currencies[#Currencies + 1] = {item = i.representativeItem,currency = k};
	end
	UpdateCurrencySlot("currencyToAddSlot",CurrencyIndex);
	UpdateCurrencySlot("currencyAddedSlot",CurrencyAddedIndex);
	UpdateCurrencyCount();
	--sb.logInfo("Currencies = " .. sb.print(Currencies));
	ContainerCore.Init(SourceID);
	Argon.Init();
	AddedRecipeCanvas = Argon.AddCanvas("addedRecipeCanvas","AddedRecipeCanvas");
	RecipeCanvas = Argon.AddCanvas("recipeCanvas","RecipeCanvas");
	Argon.SetClickCallback("RecipeCanvas","RecipeCanvasClick");
	Argon.SetClickCallback("AddedRecipeCanvas","AddedRecipeCanvasClick");
	RecipeScrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{122,1,131,180},{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBottom.png",
		ScrollerHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderMidHL.png",
		ScrollerTopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderTopHL.png",
		ScrollerBottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBottomHL.png"
	},
	{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundBottom.png"
	},
	{
		Top = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowUp.png",
		Bottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowDown.png",
		TopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowUpHL.png",
		BottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowDownHL.png"
	},"Vertical",5,0);
	RecipeList = Argon.CreateElement("List","RecipeCanvas",{0,0,121,181},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemSelected.png"
	},"Down",RecipeScrollbar);
	RecipeList.OnSelectedElementChange(function(element)
		SelectedRecipeElement = element;
		if element ~= nil then
			widget.setButtonEnabled("addRecipeButton",true);
		else
			widget.setButtonEnabled("addRecipeButton",false);
		end
	end);
	--Added Recipe LIST
	AddedRecipeScrollbar = Argon.CreateElement("Scrollbar","AddedRecipeCanvas",{121,1,130,180},{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBottom.png",
		ScrollerHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderMidHL.png",
		ScrollerTopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderTopHL.png",
		ScrollerBottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBottomHL.png"
	},
	{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderBackgroundBottom.png"
	},
	{
		Top = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowUp.png",
		Bottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowDown.png",
		TopHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowUpHL.png",
		BottomHL = "/Blocks/Conduits/Crafting Conduit/UI/Window/Vertical Scroll Bar/SliderArrowDownHL.png"
	},"Vertical",5,0);
	AddedRecipeList = Argon.CreateElement("List","AddedRecipeCanvas",{0,0,121,181},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemSelected.png"
	},"Down",AddedRecipeScrollbar);
	AddedRecipeList.OnSelectedElementChange(function(element)
		SelectedAddedRecipeElement = element;
		if element ~= nil then
			widget.setButtonEnabled("removeRecipeButton",true);
			widget.setButtonEnabled("orderUp",true);
			widget.setButtonEnabled("orderDown",true);
		else
			widget.setButtonEnabled("removeRecipeButton",false);
			widget.setButtonEnabled("orderUp",false);
			widget.setButtonEnabled("orderDown",false);
		end
	end);
	CraftingGroups = root.assetJson("/Blocks/Conduits/Crafting Conduit/CraftingGroups.json").Groups;
	widget.setButtonEnabled("addRecipeButton",false);
	widget.setButtonEnabled("removeRecipeButton",false);
	widget.setButtonEnabled("orderUp",false);
	widget.setButtonEnabled("orderDown",false);
	local ReceivedRecipes = world.getObjectParameter(SourceID,"Recipes",{});
	--sb.logInfo("RETRIVED Recipes = " .. sb.print(Recipes));
	--sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
	Recipes = {};
	--[[for i=1,#Recipes do
		sb.logInfo("Adding Recipe");
		AddRecipeToList(Recipes[i].Item,Recipes[i].Recipe,"AddedRecipeCanvas",AddedRecipeList);
	end--]]
	for k,i in pairs(ReceivedRecipes) do
		AddRecipeToList(i.Item,i.Recipe,"AddedRecipeCanvas",AddedRecipeList);
		Recipes[tonumber(k)] = i;
	end
	AddedRecipeScrollbar.SetSliderValue(0);
	AddedRecipeScrollbar.SetSliderValue(1);
	Speeds = world.getObjectParameter(SourceID,"Speed",0);
	widget.setText("speedUpgrades",tostring(Speeds));
	ContainerCore.Update();
end
function update(dt)
	Argon.Update(dt);
	ContainerCore.Update();
	UpdateCurrencyCount();
	local RecipeNumbers = world.getObjectParameter(SourceID,"RecipeNumbers",{});
	for k,i in AddedRecipeList.ElementIter() do
		local Value = RecipeNumbers[k];
		if Value == nil then
			i.SetPercentage(0);
		else
			i.SetPercentage(Value);
		end
	end
end


function UpdateRecipesForItem(item,IsCurrency)
	RecipeList.ClearList();
	if item ~= nil then
		local Recipes = root.recipesForItem(item.name);
		--sb.logInfo("Item = " .. sb.printJson(item,1))
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		--sb.logInfo("Recipes = " .. sb.print(Recipes));
		for k,i in ipairs(Recipes) do
			i.IsCurrency = (IsCurrency == true);
			AddRecipeToList(item,i);
		end
		RecipeScrollbar.SetSliderValue(0);
		RecipeScrollbar.SetSliderValue(1);
	end
end

local RecipeItemSlot;
function RecipeItemBox()
	RecipeItemSlot = player.swapSlotItem();
	widget.setItemSlotItem("recipeItemBox",RecipeItemSlot);
	UpdateRecipesForItem(RecipeItemSlot);
end

function RecipeItemBoxRight()
	RecipeItemSlot = nil;
	widget.setItemSlotItem("recipeItemBox",RecipeItemSlot);
	UpdateRecipesForItem(RecipeItemSlot);
end

function RecipeItemBoxHelp()
	widget.setText("helpText","             Recipe Item Slot\nThis is where you put the item you want to craft\n\nWhen added, recipes for that item will be listed in the Recipes Pane\n\nYou can click on a required item to see its name\n\nOnce you select a recipe from the pane, you can add it so that it can be crafted\n\nIf this conduit is connected to the right crafter, and all the ingredients are stored in the conduit's inventory,  it will start crafting the item");
end

function CurrencyAreaHelp()
	widget.setText("helpText","               Currency Area\n\nThis is where you can view, add,  and remove currency\n\nYou can see how much currency is currently stored by using the top area\n\n The craft button allows you to craft the currency displayed\n\nYou can add and remove a certain amount of currency using the bottom area");
end

function AddRecipe()
	if SelectedRecipeElement ~= nil then
		AddRecipeToList(SelectedRecipeElement.Item,SelectedRecipeElement.Recipe,"AddedRecipeCanvas",AddedRecipeList);
		Recipes[#Recipes + 1] = {Item = SelectedRecipeElement.Item,Recipe = SelectedRecipeElement.Recipe};
		world.sendEntityMessage(SourceID,"SetRecipes",Recipes);
	end
end

function RemoveRecipe()
	if SelectedAddedRecipeElement ~= nil then
		--sb.logInfo("REMOVING");
		local Index = AddedRecipeList.GetElementIndex(SelectedAddedRecipeElement);
		if Index ~= nil then
			--sb.logInfo("Index = " .. sb.print(Index));
			AddedRecipeList.RemoveElement(SelectedAddedRecipeElement);
			table.remove(Recipes,Index);
			world.sendEntityMessage(SourceID,"SetRecipes",Recipes);
		end
	end
end

local function UpdateAddedRecipeList()
	local PreviousValue = AddedRecipeScrollbar.GetSliderValue();
	AddedRecipeList.ClearList();
	for k,i in ipairs(Recipes) do
		AddRecipeToList(i.Item,i.Recipe,"AddedRecipeCanvas",AddedRecipeList);
	end
	AddedRecipeScrollbar.SetSliderValue(0);
	AddedRecipeScrollbar.SetSliderValue(PreviousValue);
end

function orderUp()
	if SelectedAddedRecipeElement ~= nil then
		local Index = AddedRecipeList.GetElementIndex(SelectedAddedRecipeElement);
		if Index ~= nil and Index > 1 then
			--sb.logInfo("Recipes BEFORE = " .. sb.print(Recipes));
			--sb.logInfo("INDEX = " .. sb.print(Index));
			local recipe = Recipes[Index];
			table.remove(Recipes,Index);
			table.insert(Recipes,Index - 1,recipe);
			--AddedRecipeList.MoveElementUp(SelectedAddedRecipeElement);
			UpdateAddedRecipeList();
			--sb.logInfo("Recipes AFTER = " .. sb.print(Recipes));
			world.sendEntityMessage(SourceID,"SetRecipes",Recipes);
		end
	end
end

function orderDown()
	if SelectedAddedRecipeElement ~= nil then
		local Index = AddedRecipeList.GetElementIndex(SelectedAddedRecipeElement);
		if Index ~= nil and Index < #Recipes then
			--sb.logInfo("INDEX = " .. sb.print(Index));
			local recipe = Recipes[Index];
			table.remove(Recipes,Index);
			table.insert(Recipes,Index + 1,recipe);
			UpdateAddedRecipeList();
			--AddedRecipeList.MoveElementDown(SelectedAddedRecipeElement);
			world.sendEntityMessage(SourceID,"SetRecipes",Recipes);
		end
	end
end

function SpeedAdd()
	if Speeds < SpeedMax and player.consumeItem(SpeedItem) then
		Speeds = Speeds + 1;
		widget.setText("speedUpgrades",tostring(Speeds));
		world.sendEntityMessage(SourceID,"SetSpeed",Speeds);
	end
end

function SpeedRemove()
	if Speeds > 0 then
		Speeds = Speeds - 1;
		player.giveItem(SpeedItem);
		widget.setText("speedUpgrades",tostring(Speeds));
		world.sendEntityMessage(SourceID,"SetSpeed",Speeds);
	end
end

currencySpinner = {};

function currencySpinner.up()
	local text = widget.getText("currencyNumberBox");
	if text == "" then
		text = "0";
	end
	local value = tonumber(text);
	if value < 9999 then
		value = value + 1;
		widget.setText("currencyNumberBox",value);
	end
end

function currencySpinner.down()
	local text = widget.getText("currencyNumberBox");
	if text == "" then
		text = "0";
	end
	local value = tonumber(text);
	if value > 0 then
		value = value - 1;
		widget.setText("currencyNumberBox",value);
	end
end

UpdateCurrencySlot = function(slot,index)
	widget.setItemSlotItem(slot,{name = Currencies[index].item,count = 1});
end

UpdateCurrencyCount = function(count)
	if count == nil then
		local CurrencyCounts = world.getObjectParameter(SourceID,"CurrencyCount",{});
		if CurrencyCounts[Currencies[CurrencyAddedIndex].currency] == nil then
			widget.setText("currencyAddedAmount",tostring(0));
		else
			widget.setText("currencyAddedAmount",tostring(CurrencyCounts[Currencies[CurrencyAddedIndex].currency]));
		end
	else
		if CurrencyIndex == CurrencyAddedIndex then
			widget.setText("currencyAddedAmount",tostring(count));
		end
	end
end

function CurrencyAddRight()
	if CurrencyIndex < #Currencies then
		CurrencyIndex = CurrencyIndex + 1;
	end
	UpdateCurrencySlot("currencyToAddSlot",CurrencyIndex);
end

function CurrencyAddLeft()
	if CurrencyIndex > 1 then
		CurrencyIndex = CurrencyIndex - 1;
	end
	UpdateCurrencySlot("currencyToAddSlot",CurrencyIndex);
end

function CurrencyRight()
	if CurrencyAddedIndex < #Currencies then
		CurrencyAddedIndex = CurrencyAddedIndex + 1;
	end
	UpdateCurrencySlot("currencyAddedSlot",CurrencyAddedIndex);
	UpdateCurrencyCount();
end

function CurrencyLeft()
	if CurrencyAddedIndex > 1 then
		CurrencyAddedIndex = CurrencyAddedIndex - 1;
	end
	UpdateCurrencySlot("currencyAddedSlot",CurrencyAddedIndex);
	UpdateCurrencyCount();
end

function AddCurrency()
	local CurrencyCounts = world.getObjectParameter(SourceID,"CurrencyCount",{});
	local Count = 0;
	local Currency = Currencies[CurrencyIndex].currency;
	if CurrencyCounts[Currency] ~= nil then
		Count = CurrencyCounts[Currency];
	end
	local Text = widget.getText("currencyNumberBox");
	if Text == "" then
		Text = "0";
	end
	local Diff = tonumber(Text);
	--[[sb.logInfo("Num = " .. sb.print(9999999999999999999));
	if Count + Diff > 9999999999999999999 then
		Diff = 9999999999999999999 - Count;
	end--]]
	if Diff > player.currency(Currency) then
		Diff = player.currency(Currency);
	end
	sb.logInfo("Diff = " .. sb.print(Diff));
	if player.consumeCurrency(Currency,Diff) then
		Count = Count + Diff;
		world.sendEntityMessage(SourceID,"SetCurrencyCount",Currency,Count);
		if CurrencyAddedIndex ~= CurrencyIndex then
			CurrencyAddedIndex = CurrencyIndex;
			UpdateCurrencySlot("currencyAddedSlot",CurrencyAddedIndex);
		end
		UpdateCurrencyCount(Count);
	end
end

function RemoveCurrency()
	local CurrencyCounts = world.getObjectParameter(SourceID,"CurrencyCount",{});
	local Count = 0;
	if CurrencyCounts[Currencies[CurrencyIndex].currency] ~= nil then
		Count = CurrencyCounts[Currencies[CurrencyIndex].currency];
	end
	local Text = widget.getText("currencyNumberBox");
	if Text == "" then
		Text = "0";
	end
	local Diff = tonumber(Text);
	if Diff > Count then
		Diff = Count;
	end
	if Diff > 0 then
		world.spawnItem({name = Currencies[CurrencyIndex].item,count = Diff},world.entityPosition(player.id()));
		if CurrencyAddedIndex ~= CurrencyIndex then
			CurrencyAddedIndex = CurrencyIndex;
			UpdateCurrencySlot("currencyAddedSlot",CurrencyAddedIndex);
		end
	end
	Count = Count - Diff;
	world.sendEntityMessage(SourceID,"SetCurrencyCount",Currencies[CurrencyIndex].currency,Count);
	UpdateCurrencyCount(Count);
end

function CraftCurrency()
	RecipeItemSlot = {name = Currencies[CurrencyAddedIndex].item,count = 1};
	widget.setItemSlotItem("recipeItemBox",RecipeItemSlot);
	UpdateRecipesForItem(RecipeItemSlot);
end