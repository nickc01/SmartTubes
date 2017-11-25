local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;

local RecipeScrollbar;

local HorizontalTestScrollbar;

local TestMask;

local RecipeCanvas;

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
	CanvasCore.Init();
	RecipeCanvas = CanvasCore.AddCanvas("recipeCanvas","RecipeCanvas");
	--[[RecipeScrollbar = CanvasCore.CreateElement("Scrollbar","RecipeCanvas",{122,1,131,171},{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderBottom.png"
	},
	{
		ScrollerTop = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderBackgroundTop.png",
		Scroller = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderBackgroundMid.png",
		ScrollerBottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderBackgroundBottom.png"
	},
	{
		Top = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowUp.png",
		Bottom = "/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowDown.png",
	},"Vertical",5,0);--]]
	HorizontalTestBar = CanvasCore.CreateElement("Scrollbar","RecipeCanvas",{0,0,121,9},{
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
	},"Horizontal",5,0.5);

	TestMask = CanvasCore.CreateElement("Mask","RecipeCanvas",{10,10,60,60});
	--sb.logInfo("Test Mask Position = " .. sb.print(TestMask.GetPosition()));
	--sb.logInfo("Horizontal Test Bar ID = " .. sb.print(HorizontalTestBar.GetID()));
	TestMask.AddChild(HorizontalTestBar);

end
local Deleted = false;
local Timer = 0;
function update(dt)
	CanvasCore.Update(dt);
	--TestMask.ChangePosition({0.1,0.1});
	--if Deleted == false then
		--RecipeScrollbar.SetToMousePosition();
	--end
	--Timer = Timer + dt;
	HorizontalTestBar.SetToMousePosition();
	--[[if Timer > 1 then
		HorizontalTestBar.SetAbsolutePosition(vecAdd(HorizontalTestBar.GetAbsolutePosition(),{0.1,0.1}));
		--HorizontalTestBar.SetAbsolutePosition({0,0});
		--sb.logInfo("Abs Position = " .. sb.print(HorizontalTestBar.GetAbsolutePosition()));
		--Timer = -1000;
	end--]]
	--[[Timer = Timer + dt;
	if Timer > 2 then
		if Deleted == false then
			sb.logInfo("Before = " .. sb.print(RecipeScrollbar));
			RecipeScrollbar.Delete();
			sb.logInfo("After = " .. sb.print(RecipeScrollbar));
			Deleted = true;
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