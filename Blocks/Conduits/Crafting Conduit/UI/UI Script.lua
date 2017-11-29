require ("/Core/ArgonGUI/Argon.lua");
local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;
--Canvases
local RecipeCanvas;

--Elements
local RecipeScrollbar;
local HorizontalTestScrollbar;
local TestMask;
local TestInsideMask;
local TestImage;
local TestAnchor;
local ImageMask1;
local ImageMask2;

local ItemImageSpacing = 2;

local ItemConfigs = setmetatable({},{ __mode = 'v'})

local function GetConfig(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	return ItemConfigs[ItemName].config;
end

local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]}
end

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end
 
local function GetItemImage(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	local Config = ItemConfigs[ItemName];
	local IMG = Config.config.inventoryIcon;
	if string.find(IMG,"^/") == nil then
		local Directory = Config.directory;
		if string.find(Directory,"/$") == nil then
			IMG = Directory .. "/" .. IMG;
		else
			IMG = Directory .. IMG;
		end
	end
	return IMG;
end

function init()
	Argon.Init();
	RecipeCanvas = Argon.AddCanvas("recipeCanvas","RecipeCanvas");
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
	},"Vertical",5,0);
	--[[HorizontalTestBar = Argon.CreateElement("Scrollbar","RecipeCanvas",{0,0,1000,9},{
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
	},"Horizontal",100,0.5);--]]
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
local Deleted = false;
local Timer = 0;
local Timer2 = 0;
local MaskParent = true;
function update(dt)
	Argon.Update(dt);
	--RecipeScrollbar.SetToMousePosition();
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

local AllRecipes = {};

function UpdateRecipesForItem(item)
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