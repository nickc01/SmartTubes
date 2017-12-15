require ("/Core/ArgonGUI/Argon.lua");
local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;
local SourceID;
local Recipes;
local Speeds = 0;
local SpeedMax = 20;
--Canvases
local RecipeCanvas;
local AddedRecipeCanvas;

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
		local Element = RequiredItems.AddElement();
		--Required Item Amount
		local AmountText = Argon.CreateElement("Text",Canvas,{1,0},"Thin",7);
		AmountText.SetString(tostring(Recipe.input[i].count));
		Element.AddChild(AmountText);

		--Required Item Rarity Image
		local RequiredItemRarity = Argon.CreateElement("Image",Canvas,Rarities[GetItemRarity(Recipe.input[i].name)],{0,9});
		Element.AddChild(RequiredItemRarity);

		--Required Item Image
		local RequiredItemImage,RequiredItemPos = GetItemImage(Recipe.input[i].name,{9,18});
		local RequiredItem = Argon.CreateElement("Image",Canvas,RequiredItemImage,RequiredItemPos);
		Element.AddChild(RequiredItem);
	end
	for k,i in pairs(Recipe.currencyInputs) do
		if i <= 9999 then
			local Element = RequiredItems.AddElement();
			--Currency Amount
			local AmountText = Argon.CreateElement("Text",Canvas,{1,0},"Thin",7);
			AmountText.SetString(tostring(i));
			Element.AddChild(AmountText);
			--Required Currency Image
			local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
			local RequiredCurrency = Argon.CreateElement("Image",Canvas,RequiredCurrencyImage,RequiredCurrencyPos);
			Element.AddChild(RequiredCurrency);
		else
			local CurrencyRequired = i;
			repeat
				local Element = RequiredItems.AddElement();
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
				Element.AddChild(AmountText);
				--Required Currency Image
				local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
				local RequiredCurrency = Argon.CreateElement("Image",Canvas,RequiredCurrencyImage,RequiredCurrencyPos);
				Element.AddChild(RequiredCurrency);
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
		sb.logInfo("Group = " .. sb.print(Group));
		local CrafterItemImage,CrafterItemPos = nil,nil;
		if string.match(Group.SlotItem,"^/") == nil then
			CrafterItemImage,CrafterItemPos	= GetItemImage(Group.SlotItem,{11,18});
		else
			CrafterItemImage,CrafterItemPos = GetPosFromImage(Group.SlotItem,{11,18});
		end
		local CrafterItem = Argon.CreateElement("Image",Canvas,CrafterItemImage,CrafterItemPos);
		Element.AddChild(CrafterItem);
	end
	Element.Item = Item;
	Element.Recipe = Recipe;
	return Element;

	
end

function init()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	ContainerCore.Init(SourceID);
	Argon.Init();
	AddedRecipeCanvas = Argon.AddCanvas("addedRecipeCanvas","AddedRecipeCanvas");
	RecipeCanvas = Argon.AddCanvas("recipeCanvas","RecipeCanvas");
	Argon.SetClickCallback("RecipeCanvas","RecipeCanvasClick");
	Argon.SetClickCallback("AddedRecipeCanvas","AddedRecipeCanvasClick");
	RecipeScrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{122,1,131,171},{
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
	RecipeList = Argon.CreateElement("List","RecipeCanvas",{0,0,121,172},{
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
	AddedRecipeScrollbar = Argon.CreateElement("Scrollbar","AddedRecipeCanvas",{121,1,130,171},{
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
	AddedRecipeList = Argon.CreateElement("List","AddedRecipeCanvas",{0,0,121,172},{
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
	sb.logInfo("RETRIVED Recipes = " .. sb.print(Recipes));
	sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
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
end


function UpdateRecipesForItem(item)
	RecipeList.ClearList();
	if item ~= nil then
		local Recipes = root.recipesForItem(item.name);
		sb.logInfo("Item = " .. sb.printJson(item,1))
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		for k,i in ipairs(Recipes) do
			AddRecipeToList(item,i);
		end
		AddedRecipeScrollbar.SetSliderValue(0);
		AddedRecipeScrollbar.SetSliderValue(1);
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
			sb.logInfo("Recipes BEFORE = " .. sb.print(Recipes));
			sb.logInfo("INDEX = " .. sb.print(Index));
			local recipe = Recipes[Index];
			table.remove(Recipes,Index);
			table.insert(Recipes,Index - 1,recipe);
			--AddedRecipeList.MoveElementUp(SelectedAddedRecipeElement);
			UpdateAddedRecipeList();
			sb.logInfo("Recipes AFTER = " .. sb.print(Recipes));
			world.sendEntityMessage(SourceID,"SetRecipes",Recipes);
		end
	end
end

function orderDown()
	if SelectedAddedRecipeElement ~= nil then
		local Index = AddedRecipeList.GetElementIndex(SelectedAddedRecipeElement);
		if Index ~= nil and Index < #Recipes then
			sb.logInfo("INDEX = " .. sb.print(Index));
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