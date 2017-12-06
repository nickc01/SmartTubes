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


local ItemConfigs = setmetatable({},{ __mode = 'v'})

local function GetConfig(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	return ItemConfigs[ItemName].config;
end

local function GetItemRarity(ItemName)
	sb.logInfo("Item Config = " .. sb.printJson(GetConfig(ItemName),1));
	--local Config = GetConfig(ItemName);
	--return Config.rarity;
	return string.lower(GetConfig(ItemName).rarity or "Common");
end

local function GetItemImage(ItemName,CenterPos)
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
	return IMG,{CenterPos[1] - root.imageSize(IMG)[1] / 2, CenterPos[2] - root.imageSize(IMG)[2] / 2};
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
	local Element = RecipeList.AddElement();

	--Output Item Rarity Image
	local SourceItemRarity = Argon.CreateElement("Image","RecipeCanvas",Rarities[GetItemRarity(Recipe.output.name)],{98,58});
	Element.AddChild(SourceItemRarity);

	--Output Item Image
	local SourceItemImage,SourceItemPos = GetItemImage(Recipe.output.name,{107,67});
	local SourceItem = Argon.CreateElement("Image","RecipeCanvas",SourceItemImage,SourceItemPos);
	Element.AddChild(SourceItem);
	--Output Item Amount
	local OutputAmountText = Argon.CreateElement("Text","RecipeCanvas",{99,48},"Thin",7);
	OutputAmountText.SetString(tostring(Recipe.output.count));
	Element.AddChild(OutputAmountText);


	--Required Items Scrollbar
	local Scrollbar = Argon.CreateElement("Scrollbar","RecipeCanvas",{1,30,95,39},{
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
	Element.AddChild(Scrollbar);
	--Requirements Text
	local Text = Argon.CreateElement("Text","RecipeCanvas",{1,71});
	Text.SetString("Requirements");
	Element.AddChild(Text);

	--Required Items List
	local RequiredItems = Argon.CreateElement("List","RecipeCanvas",{1,42,95,85},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Active =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
		Selected =  "/Blocks/Conduits/Crafting Conduit/UI/Window/Slot With Text.png",
	},"Right",Scrollbar);
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

	Element.AddChild(RequiredItems);
	
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
	RecipeList = Argon.CreateElement("List","RecipeCanvas",{0,10,121,172},{
		Inactive = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Active = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png",
		Selected = "/Blocks/Conduits/Crafting Conduit/UI/Window/List Item/RecipesItemNormal.png"
	},"Down",RecipeScrollbar);
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
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		for k,i in ipairs(Recipes) do
			AddRecipeToList(item,i);
		end
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