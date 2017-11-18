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
	if Deleted == false then
		RecipeScrollbar.SetToMousePosition();
	end
	HorizontalTestBar.SetToMousePosition();
	Timer = Timer + dt;
	if Timer >= 1 and Deleted == false then
		sb.logInfo("Before = " .. sb.print(RecipeScrollbar));
		RecipeScrollbar.Delete();
		sb.logInfo("After = " .. sb.print(RecipeScrollbar));
		Deleted = true;
	end
	--RecipeScrollbar.SetPosition(RecipeScrollbar.GetPosition());
	--RecipeScrollbar.Draw();
	--HorizontalTestBar.Draw();
	--RecipeScrollbar.SetSliderSize(RecipeScrollbar.GetSliderSize() + 1);
	--RecipeScrollbar.SetSliderValue(RecipeScrollbar.GetSliderValue() + 0.01);
	--RecipeScrollbar.Draw();
	--local Position = vecSub(RecipeCanvas:mousePosition(),RecipeScrollbar.GetPosition());
	--Position[1] = 100 / Position[1];
	--Position[2] = Position[2] / RecipeScrollbar.GetLength();
--	RecipeScrollbar.SetSliderValue(Position[2]);
	--RecipeScrollbar.SetToMousePosition();
	--RecipeScrollbar.Draw();
	--widget.setSliderValue("requiredItemsSlider",widget.getSliderValue("requiredItemsSlider") + 1);
	--[[if Elements ~= nil then
		for k,i in ipairs(Elements) do
			--sb.logInfo("Element = " .. sb.print(i));
			local Position = widget.getPosition(i);
			Position[1] = Position[1] - 1;
			widget.setPosition(i,Position);
		end
	end--]]
	--sb.logInfo("Recipe Added = " .. sb.print(widget.addListItem("recipeArea.itemList")));
	--local ListItem = widget.addListItem("recipeArea.itemList");
	--widget.addListItem("recipeArea.itemList." .. ListItem .. ".requiredItems.itemList");
	--RecipeScrollbar.ChangePosition(dt * 0.1);
	--CanvasCore.Update(dt);
end

local AllRecipes = {};

function UpdateRecipesForItem(item)
	--DrawScrollbar(RecipeScrollbar,RecipeCanvas);
	
	--[[DrawMainScrollbar(
	{127,3},
	{127,169},
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowUp.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderArrowDown.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/ScrollArea.png",
	"/Blocks/Conduits/Crafting Conduit/UI/Window/SliderMid.png"
	);--]]
end

--[[UpdateRecipesForItem = function(Item)
	AllRecipes = {};
	widget.clearListItems(RecipesList);
	if Item ~= nil then
		local Recipes = root.recipesForItem(Item.name);
		sb.logInfo("Recipes = " .. sb.printJson(Recipes,1));
		if Recipes ~= nil then
			--Elements = {};
			local Elements = 0;
			for k,i in ipairs(Recipes) do
				local ItemSlot = widget.addListItem(RecipesList);
				widget.setItemSlotItem(RecipesList .. "." .. ItemSlot .. ".outputItemImage",i.output);

				--Canvas.AddBinding(RecipesList .. "." .. ItemSlot .. ".requiredItemsCanvas");

				--local RequiredItemsCanvas = Canvas.GetBinding(RecipesList .. "." .. ItemSlot .. ".requiredItemsCanvas");
				--RequiredItemsCanvas:drawImage("/interface/actionbar/actionbarcover.png",{0,0});
				sb.logInfo(RecipesList .. "." .. ItemSlot .. ".itemSlider");
				--widget.setSliderRange(RecipesList .. "." .. ItemSlot .. ".itemSlider", 0, 1000);
				widget.setSliderValue(RecipesList .. "." .. ItemSlot .. ".itemSlider",1);
				--sb.logInfo("Value = " .. sb.print(widget.getSliderValue(RecipesList)));
				for m,n in ipairs(i.input) do
				--for i=0,24 do
					local Layout = RecipesList .. "." .. ItemSlot .. ".requiredItems";
					--root.imageSize();
					local Image = GetItemImage(n.name);
					local ImageSize = root.imageSize(Image);
					local MaxSize = math.max(ImageSize[1],ImageSize[2]);
					local ScaleFactor = 1;
					if MaxSize > 16 then
						ScaleFactor = 16 / MaxSize;
					end
					--for j=1,10 do
						widget.addFlowImage(Layout,"slot" .. n.name,"/interface/actionbar/actionbarcover.png");
						if ScaleFactor == 1 then
							widget.addFlowImage(Layout,"item" .. n.name,Image);
						else
							widget.addFlowImage(Layout,"item" .. n.name,Image .. "?scalenearest=" .. ScaleFactor);
						end
						Elements = Elements + 1;
						widget.setPosition(Layout .. ".slot" .. n.name,{(18 * ((m * 1) - 1)),0});
						widget.setPosition(Layout .. ".item" .. n.name,{(18 * ((m * 1) - 1)) - (ImageSize[1] / 2) + 9,8 - (ImageSize[2] / 2)});
						if Elements > 4 then
							
						end
					--end
					--Elements[#Elements + 1] = RecipesList .. "." .. ItemSlot .. ".requiredItems.rain" .. i;
				end
				--widget.addFlowImage(RecipesList .. "." .. ItemSlot .. ".requiredItems","/interface/actionbar/actionbarcover.png","/interface/actionbar/actionbarcover.png");
				--widget.addFlowImage(RecipesList .. "." .. ItemSlot .. ".requiredItems","/interface/actionbar/actionbarcover.png","/interface/actionbar/actionbarcover.png");
				--widget.addFlowImage(RecipesList .. "." .. ItemSlot .. ".requiredItems","/interface/actionbar/actionbarcover.png","/interface/actionbar/actionbarcover.png");
				--[[sb.logInfo("ItemSlot = " .. sb.print(ItemSlot));
				sb.logInfo("Final = " .. sb.print(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList"));
				local StartingPos;
				local ItemSize;
				local Requirements = {};
				for i=1,k do
					Requirements[#Requirements + 1] = widget.addListItem(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList");
					--[[if StartingPos == nil then
						StartingPos = widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements[#Requirements]);
						ItemSize = widget.getSize(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements[#Requirements]);
					end
					--local Path = 
					--[[sb.logInfo("Requirement = " .. sb.print(Requirements));
					if StartingPos == nil then
						StartingPos = widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements);
						ItemSize = widget.getSize(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements);
						sb.logInfo("Size = " .. sb.print(ItemSize));
						sb.logInfo("Position = " .. sb.print(StartingPos));
					else
						sb.logInfo("Element Position = " .. sb.print(widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements)));
						--ItemSize = widget.getSize(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements);
						local NewPos = {1 * i,-(1 * i)};
						widget.setPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements,NewPos);
						sb.logInfo("Element Position2 = " .. sb.print(widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements)));
					end
				end
				for k,i in ipairs(Requirements) do
					sb.logInfo("Element Position = " .. sb.print(widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. i)));
					local ElementPos = widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. i);
					--ItemSize = widget.getSize(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements);
					--local NewPos = {1 * k,-(1 * k)};
					local NewPos = {ElementPos[2],ElementPos[1]};
					--widget.setPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. i,NewPos);
					sb.logInfo("Element Position2 = " .. sb.print(widget.getPosition(RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. i)));
				end
				--Elements[#Elements + 1] = RecipesList .. "." .. ItemSlot .. ".requiredItems.itemList." .. Requirements .. ".outputItemImage";
				--widget.setSliderEnabled(RecipesList .. "." .. ItemSlot .. ".requiredItems",false);
			end
		end
	end
end--]]

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