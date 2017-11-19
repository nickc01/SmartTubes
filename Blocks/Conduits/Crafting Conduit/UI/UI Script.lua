local RecipesList = "recipeArea.itemList";
local AddedRecipesList = "addedRecipeArea.itemList";
local UpdateRecipesForItem;

local RecipeScrollbar;

local HorizontalTestScrollbar;

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
	--sb.logInfo("IMG = " .. sb.print(IMG));
	return IMG;
	--sb.logInfo("Config = " .. sb.print(Config));
end

--[[
Doc for widget.addFlowImage();

--widget



--]]

function init()
	RecipeCanvas = CanvasCore.AddCanvas("recipeCanvas","RecipeCanvas");
	RecipeScrollbar = CanvasCore.AddScrollBar("RecipeCanvas",{122,2,131,169},nil,{
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
	},"Vertical",5,0.5);
	HorizontalTestBar = CanvasCore.AddScrollBar("RecipeCanvas",{0,0,121,9},100,{
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
	--RecipeScrollbar.Draw();
	--HorizontalTestBar.Draw();
--	RecipeScrollbar.SetSliderSize(5);
	--RecipeCanvas = widget.bindCanvas("recipeCanvas");
	--CanvasCore.AddClickCallback(RecipeCanvas,"RecipeCanvasClick");
	--[[RecipeCanvas = CanvasCore.InitCanvas("recipeCanvas","RecipeCanvasClick");
	RecipeScrollbar = CanvasCore.CreateScrollbar(
	RecipeCanvas,
	{126,3},
	{126,169},
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowUp.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowDown.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/ScrollArea.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderMid.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderTop.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderBottom.png",
	2,0.5
	);
	sb.logInfo("RecipeScrollbar = " .. sb.print(RecipeScrollbar));
	CanvasCore.AddElement(RecipeCanvas,RecipeScrollbar);--]]
	--RecipeScrollbar.Draw();
	--[[sb.logInfo("A = " .. sb.print(A));
	sb.logInfo("B = " .. sb.print(B));
	sb.logInfo("C = " .. sb.print(C));
	sb.logInfo("D = " .. sb.print(D))--]]
	--sb.logInfo("Widget = " .. sb.print(widget));
	--Canvas.Init();
	--widget.setSliderRange("requiredItemsSlider", 0, 1000);
	--widget.registerMemberCallback(RecipesList, "MoveRight", function() sb.logInfo("This is a test") end);
	--widget.registerMemberCallback(RecipesList, "MoveLeft", function() sb.logInfo("This is a test") end);
end

local Timer = 0;
local Deleted = false;

function update(dt)
	CanvasCore.Update(dt);
	--if Deleted == false then
	--	RecipeScrollbar.SetToMousePosition();
	--end
	--HorizontalTestBar.SetToMousePosition();;
end

local AllRecipes = {};

function UpdateRecipesForItem(item)
end

local RecipeItemSlot;
function RecipeItemBox()
	--sb.logInfo("CLICKED!");
	RecipeItemSlot = player.swapSlotItem();
	--sb.logInfo("Item = " .. sb.print(RecipeItemSlot));
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

function SliderUpdate(A,B,C,D)
	sb.logInfo("A = " .. sb.print(A));
	sb.logInfo("B = " .. sb.print(B));
	sb.logInfo("C = " .. sb.print(C));
	sb.logInfo("D = " .. sb.print(D));
end