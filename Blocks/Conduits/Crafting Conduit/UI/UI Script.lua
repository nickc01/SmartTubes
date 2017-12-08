require ("/Core/ArgonGUI/Argon.lua");
local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;
--Canvases
local RecipeCanvas;

--Elements
local RecipeScrollbar;
local RecipeList;

local Rarities = {
	common = "/interface/inventory/itembordercommon.png",
	uncommon = "/interface/inventory/itemborderuncommon.png",
	rare = "/interface/inventory/itemborderrare.png",
	legendary = "/interface/inventory/itemborderlegendary.png",
	essential = "/interface/inventory/itemborderessential.png"
}

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
	--sb.logInfo("Item Config = " .. sb.print(GetConfig(ItemName)));
	--local Config = GetConfig(ItemName);
	--return Config.rarity;
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
	--[[local Scale = 1;
	local ImageSize = root.imageSize(IMG);
	if math.max(ImageSize[1],ImageSize[2]) > 16 then
		Scale = 16 / math.max(ImageSize[1],ImageSize[2]);
		ImageSize[1] = ImageSize[1] * Scale;
		ImageSize[2] = ImageSize[2] * Scale;
		IMG = IMG .. "?scalenearest=" .. tostring(Scale);
	end
	return IMG,{CenterPos[1] - ImageSize[1] / 2, CenterPos[2] - ImageSize[2] / 2};--]]
end
--[[local HorizontalTestScrollbar;
local TestMask;
local TestInsideMask;
local TestImage;
local TestAnchor;
local ImageMask1;
local ImageMask2;
local TestList;--]]

--[[local Colors = {
	{255,255,255},
	{255,0,255},
	{255,255,0},
	{0,255,255},
	{255,0,0},
	{0,255,0},
	{0,0,255}
};--]]

--local ItemImageSpacing = 2;


local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]}
end

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function AddRecipeToList(Item,Recipe)

	local GroupIndex = 0;
	local Group;
	for GroupIndex=1,#Recipe.groups do
		Group = GetCraftingGroup(Recipe.groups[GroupIndex]);
		if Group ~= nil then
			break;
		end
	end
	if Group == nil then
		return nil;
	end
	local Element = RecipeList.AddElement();

	--Output Item Rarity Image
	local SourceItemRarity = Argon.CreateElement("Image","RecipeCanvas",Rarities[GetItemRarity(Recipe.output.name)],{98,64});
	Element.AddChild(SourceItemRarity);

	--Output Item Image
	local SourceItemImage,SourceItemPos = GetItemImage(Recipe.output.name,{107,73});
	local SourceItem = Argon.CreateElement("Image","RecipeCanvas",SourceItemImage,SourceItemPos);
	Element.AddChild(SourceItem);
	--Output Item Amount
	local OutputAmountText = Argon.CreateElement("Text","RecipeCanvas",{99,54},"Thin",7);
	OutputAmountText.SetString(tostring(Recipe.output.count));
	Element.AddChild(OutputAmountText);


	--Required Items Scrollbar
	local RequiredItemsScrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{1,38,95,47},{
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
	local RequiredItems = Argon.CreateElement("List","RecipeCanvas",{1,48,95,90},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Active =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Selected =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
	},"Right",RequiredItemsScrollbar);
	-- Add Required Items
	for i=1,#Recipe.input do
		local Element = RequiredItems.AddElement();
		--Required Item Amount
		local AmountText = Argon.CreateElement("Text","RecipeCanvas",{1,0},"Thin",7);
		AmountText.SetString(tostring(Recipe.input[i].count));
		Element.AddChild(AmountText);

		--Required Item Rarity Image
		local RequiredItemRarity = Argon.CreateElement("Image","RecipeCanvas",Rarities[GetItemRarity(Recipe.input[i].name)],{0,9});
		Element.AddChild(RequiredItemRarity);

		--Required Item Image
		local RequiredItemImage,RequiredItemPos = GetItemImage(Recipe.input[i].name,{9,18});
		local RequiredItem = Argon.CreateElement("Image","RecipeCanvas",RequiredItemImage,RequiredItemPos);
		Element.AddChild(RequiredItem);
	end
	for k,i in pairs(Recipe.currencyInputs) do
		if i <= 9999 then
			local Element = RequiredItems.AddElement();
			--Currency Amount
			local AmountText = Argon.CreateElement("Text","RecipeCanvas",{1,0},"Thin",7);
			AmountText.SetString(tostring(i));
			Element.AddChild(AmountText);
			--Required Currency Image
			local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
			local RequiredCurrency = Argon.CreateElement("Image","RecipeCanvas",RequiredCurrencyImage,RequiredCurrencyPos);
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

				local AmountText = Argon.CreateElement("Text","RecipeCanvas",{1,0},"Thin",7);
				AmountText.SetString(tostring(SubtractedCurrency));
				Element.AddChild(AmountText);
				--Required Currency Image
				local RequiredCurrencyImage,RequiredCurrencyPos = GetItemImage(k,{9,18});
				local RequiredCurrency = Argon.CreateElement("Image","RecipeCanvas",RequiredCurrencyImage,RequiredCurrencyPos);
				Element.AddChild(RequiredCurrency);
			until (CurrencyRequired == 0);


		end
	end

	Element.AddChild(RequiredItems);

	--Crafted At Text
	--[[local AmountText = Argon.CreateElement("Text","RecipeCanvas",{1,0},"Default");
	AmountText.SetString(Recipe.groups);
	Element.AddChild(AmountText);--]]

	--Crafted At Scrollbar
	--[[local CraftedAtScrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{86,1,95,28},{
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
	CraftedAtScrollbar.HideWhenNecessary(true);
	Element.AddChild(CraftedAtScrollbar);

	--CraftedAtList

	CraftedAtList = Argon.CreateElement("List","RecipeCanvas",{0,10,121,172},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftedAtItem.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftedAtItem.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftedAtItem.png"
	},"Down");

	Element.AddChild(CraftedAtList);--]]
	--if Group ~= nil then
	--[[	local CraftedAtText = Argon.CreateElement("Text","RecipeCanvas",{1,22},"Default");
		local String = Recipe.groups[GroupIndex];
		if string.len(String) >= 20 then
			String = string.sub(String,1,-1);
			String = String .. "...";
		end
		CraftedAtText.SetString(String);
		Element.AddChild(CraftedAtText);
	else--]]
	local CraftedAtText = Argon.CreateElement("Text","RecipeCanvas",{1,2},"Default");
	CraftedAtText.SetString(Group.Name);
	--CraftedAtText.SetColor({255,255,255});
	Element.AddChild(CraftedAtText);

	if Group.SlotItem ~= nil then
		--Item Slot
		local ItemSlot = Argon.CreateElement("Image","RecipeCanvas","/interface/actionbar/actionbarcover.png",{2,9});
		Element.AddChild(ItemSlot);

		--Item Image
		sb.logInfo("Group = " .. sb.print(Group));
		local CrafterItemImage,CrafterItemPos = nil,nil;
		if string.match(Group.SlotItem,"^/") == nil then
			CrafterItemImage,CrafterItemPos	= GetItemImage(Group.SlotItem,{11,18});
		else
			CrafterItemImage,CrafterItemPos = GetPosFromImage(Group.SlotItem,{11,18});
		end
		local CrafterItem = Argon.CreateElement("Image","RecipeCanvas",CrafterItemImage,CrafterItemPos);
		Element.AddChild(CrafterItem);
	end

	--end
	--Crafting Scrollbar
	--[[local CraftingScrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{110,2,119,29},{
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
	CraftingScrollbar.HideWhenNecessary(true);
	Element.AddChild(CraftingScrollbar);

	--Crafting List
	CraftingList = Argon.CreateElement("List","RecipeCanvas",{0,2,106,29},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftingInfo.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftingInfo.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/CraftingInfo.png"
	},"Down",CraftingScrollbar);
	for i=1,#Recipe.groups do
		local CraftingElement = CraftingList.AddElement();
		local CraftingText = Argon.CreateElement("Text","RecipeCanvas",{1,0},"Default");
		CraftingText.SetString(Recipe.groups[i]);
		CraftingElement.AddChild(CraftingText);
	end

	Element.AddChild(CraftingList);--]]


	
end


--[[local function AddListElement(index)
	local Test = TestList.AddElement();
	local Image = Argon.CreateElement("Image","RecipeCanvas","/Blocks/Conduits/Crafting Conduit/UI/Window/Test/ImageTest.png");
	local Text = Argon.CreateElement("Text","RecipeCanvas",{5,5});
	Text.SetString("This is a test!?!thjeklshfgjk;sdbnvioserah;giobrsd");

	local Scrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{10,1,19,60},{
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

	--[[local Scrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{0,0,80,9},{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderRight.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderLeft.png"
	},
	{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundRight.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderBackgroundLeft.png"
	},
	{
		Top = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowRight.png",
		Bottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/Horizontal Scroll Bar/SliderArrowLeft.png",
	},"Horizontal",4,0);
	Image.ChangePosition({2 * index,0});
	Test.AddChild(Image);
	Test.AddChild(Scrollbar);
	Test.AddChild(Text);
	--Image.SetColor(Colors[i]);
end--]]

function init()
	Argon.Init();
	RecipeCanvas = Argon.AddCanvas("recipeCanvas","RecipeCanvas");
	Argon.SetClickCallback("RecipeCanvas","RecipeCanvasClick");
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
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png"
	},"Down",RecipeScrollbar);
	CraftingGroups = root.assetJson("/Blocks/Conduits/Crafting Conduit/CraftingGroups.json").Groups;
	--[[RecipeList = Argon.CreateElement("List","RecipeCanvas",{0,10,121,172},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/ListItemDisabled.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/ListItemNormal.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/ListItemSelected.png"
	},"Down",RecipeScrollbar);--]]
	--[[RecipeCanvas = Argon.AddCanvas("recipeCanvas","RecipeCanvas");
	Argon.SetClickCallback("RecipeCanvas","RecipeCanvasClick");
	--TestImage = Argon.CreateElement("Image","RecipeCanvas","/Blocks/Conduits/Crafting Conduit/UI/Window/Test/ImageTest.png",{7,7});
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
	TestList = Argon.CreateElement("List","RecipeCanvas",{0,10,121,172},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/ListItemDisabled.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/ListItemNormal.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/ListItemSelected.png"
	},"down",RecipeScrollbar);
	for i=1,7 do
		AddListElement(i);
	end
	sb.logInfo("Added " .. TestList.ElementCount() .. " elements");--]]
	--HorizontalTestBar.ChangePosition({0,10});
	--TestMask = Argon.CreateElement("Mask","RecipeCanvas",{10,10,60,60});
	--TestInsideMask = Argon.CreateElement("Mask","RecipeCanvas",{10,10,30,30});
	--ImageMask1 = Argon.CreateElement("Image","RecipeCanvas","/Blocks/Conduits/Crafting Conduit/UI/Window/Test/ImageTestMask1.png");
	--ImageMask2 = Argon.CreateElement("Image","RecipeCanvas","/Blocks/Conduits/Crafting Conduit/UI/Window/Test/ImageTestMask2.png");

	--TestMask.AddChild(ImageMask1);
	--TestInsideMask.AddChild(ImageMask2);
	--sb.logInfo("Test Mask Position = " .. sb.print(TestMask.GetPosition()));
	--sb.logInfo("Horizontal Test Bar ID = " .. sb.print(HorizontalTestBar.GetID()));
	--TestMask.AddChild(TestInsideMask);
	--TestMask.AddChild(HorizontalTestBar);
	--TestImage.AddChild(TestMask,true);

end
--local Deleted = false;
--local Timer = 0;
--local Timer2 = 0;
--local MaskParent = true;
function update(dt)
	Argon.Update(dt);
	--[[Timer = Timer + dt;
	if Timer > 5 then
		TestList.RemoveLast();
		Timer = 0;
	end--]]
	--RecipeScrollbar.SetToMousePosition();
	--HorizontalTestBar.SetToMousePosition();
	--[[Timer = Timer + dt;
	Timer2 = Timer2 + dt;
	TestImage.ChangePosition({0.05,0.05});
	if Timer > 0 then
		HorizontalTestBar.SetToMousePosition();
	end
	if Timer > 1 then
		HorizontalTestBar.SetAbsolutePosition(vecAdd(HorizontalTestBar.GetAbsolutePosition(),{-1,0.0}));
	end
	if Timer2 > 1 then
		MaskParent = not MaskParent;
		Timer2 = Timer2 - 1;
		if MaskParent == true then
			sb.logInfo("Switching to First Mask");
			TestMask.AddChild(HorizontalTestBar,true);
		else
			sb.logInfo("Switching to Second Mask");
			TestInsideMask.AddChild(HorizontalTestBar,true);
		end
	end--]]
end

--[[local AllRecipes = {};

function UpdateRecipesForItem(item)
end-]]

function UpdateRecipesForItem(item)
	RecipeList.ClearList();
	if item ~= nil then
		local Recipes = root.recipesForItem(item.name);
		sb.logInfo("Item = " .. sb.printJson(item,1))
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		for k,i in ipairs(Recipes) do
			AddRecipeToList(item,i);
		end
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
	
end