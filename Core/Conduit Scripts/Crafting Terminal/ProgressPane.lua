require("/Core/UICore.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");
require("/Core/ResizeableWindow.lua");

--Declaration
ProgressPane = {};
local ProgressPane = ProgressPane;

--Variables
local CraftingList = {};
local ChangesUUID;
local ClientUUID;
local ProgressCanvas;
local ProgressCanvasSize;
local HighestAnchorPoint;
local LowestRelativePoint;
local SourceID;
local PlayerID;
local RenderQueue = {};
local SimpleRenderQueue = {};
local Displays = {};
local ObjectToMeta = {};
local DisplayToMeta = {};
local HoverTests = {};
local MouseTests = {};
local MainSlider;
local CurrentCanvasProgress = 0;
local SliderOffset = 0;
local DT;
local CraftingDisplays = {};

local DisplaySettings = {
	TitleHeight = 10,
	MainSpacing = 3,
	BackgroundColor = {43,77,20},
	TitleColor = {79, 142, 37},
	ChildrenHeightSpacing = 2,
	ChildrenSize = {22,22},
	SlotImage = "/interface/actionbar/actionbarcover.png",
	SlotImageSize = nil,
	SlotImageRect = nil,
	ChildrenColor = {99, 179, 47},
	ChildrenWarningColor = {179,159,47},
	ChildrenErrorColor = {179,47,47},
	ChildrenImage = "/Blocks/Crafting Terminal/UI/Window/Child Icon.png"
}

--Functions
local CraftListUpdated;
local AddToRenderQueue;
local RemoveFromRenderQueue;
local AddToSimpleRenderQueue;
local RemoveFromSimpleRenderQueue;
local MakeButton;
local NumberToString;
local GetDecimalPlace;
local MakeObjectFromData;

--Initializes the Progress Pane
function ProgressPane.Initialize()
	--sb.logInfo("Test = " .. sb.print(config.getParameter("gui")));
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	RWindow.Initialize();
	DisplaySettings.SlotImageSize = root.imageSize(DisplaySettings.SlotImage);
	DisplaySettings.SlotImageRect = {0,0,DisplaySettings.SlotImageSize[1],DisplaySettings.SlotImageSize[2]};
	PlayerID = pane.sourceEntity();
	ProgressCanvas = widget.bindCanvas("progressCanvas");
	ProgressCanvasSize = ProgressCanvas:size();
	HighestAnchorPoint = {0,ProgressCanvasSize[2]};
	LowestRelativePoint = {0,0};
	MainSlider = ProgressPane.CreateSlider();
	MainSlider.SetPosition({ProgressCanvasSize[1] - 9,0});
	MainSlider.SetSize(ProgressCanvasSize[2]);
	UICore.AddAsyncCoroutine(function()
		while(true) do
			local Promise = world.sendEntityMessage(SourceID,"UpdateCraftList",ChangesUUID,ClientUUID);
			while not Promise:finished() do
				coroutine.yield();
			end
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
								if TopTable[change.PathToValue[i]] == nil then
									TopTable[change.PathToValue[i]] = {};
								end
								TopTable = TopTable[change.PathToValue[i]];
							end
						else
							for i=1,#change.PathToValue do
								if TopTable[change.PathToValue[i]] == nil then
									TopTable[change.PathToValue[i]] = {};
								end
								TopTable = TopTable[change.PathToValue[i]];
							end
						end
						if change.Operation == nil then
							local Value = change.NewValue;
							if Value == "__nil__" then
								Value = nil;
							end
							TopTable[change.PathToValue[#change.PathToValue]] = Value;
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
	end);
	UICore.AddAsyncCoroutine(function()
		while(true) do
			DT = coroutine.yield();
			ProgressCanvas:clear();
			local MousePosition = ProgressCanvas:mousePosition();
			for _,func in pairs(HoverTests) do
				func(MousePosition);
			end
			if CurrentCanvasProgress ~= MainSlider.GetProgress() then
				if #Displays == 0 then
					SliderOffset = 0;
				else
					local Top = 0;
					local Bottom = Displays[#Displays].GetBottomAnchor()[2] - DisplaySettings.MainSpacing;
					--sb.logInfo("ActualBottom = " .. sb.print(Displays[#Displays].GetBottomAnchor()));
					--sb.logInfo("Top = " .. sb.print(Top));
					--sb.logInfo("BBBBBBBBBBBBBBBBBBBBottom = " .. sb.print(Bottom));
					--SliderOffset = (Top) * MainSlider.GetProgress();
					SliderOffset = ((Top - Bottom) * (MainSlider.GetProgress() / MainSlider.GetProgressSize()));
					--sb.logInfo("SliderOffset = " .. sb.print(SliderOffset));
					--sb.logInfo("Progress = " .. sb.print(MainSlider.GetProgress()));
				end
				CurrentCanvasProgress = MainSlider.GetProgress();
			end
			for i=1,#RenderQueue do
				RenderQueue[i].Func();
			end
			for i=1,#SimpleRenderQueue do
				SimpleRenderQueue[i].Func();
			end
			--coroutine.yield();
		end
	end);
end

--Called whenever the Crafting List is updated
CraftListUpdated = function()
	--sb.logInfo("_____________________Crafting List = " .. sb.printJson(CraftingList,1));
	local FoundUUIDS = {};
	for uuid,data in pairs(CraftingList) do
		FoundUUIDS[#FoundUUIDS + 1] = uuid;
		if CraftingDisplays[uuid] == nil then
			CraftingDisplays[uuid] = ProgressPane.CreateNewDisplay();
			CraftingDisplays[uuid].SetTitle("Crafting");
			CraftingDisplays[uuid].AddObject(MakeObjectFromData(CraftingDisplays[uuid],data.FinalItem,data),data.FinalItem.name);
		else
			UpdateObjectData(CraftingDisplays[uuid],CraftingDisplays[uuid].GetObject(data.FinalItem.name),data.FinalItem,data);
		end
		local Display = CraftingDisplays[uuid];
	end
	for uuid,display in pairs(CraftingDisplays) do
		for i=1,#FoundUUIDS do
			if uuid == FoundUUIDS[i] then
				goto Continue;
			end
		end
		CraftingDisplays[uuid] = nil;
		display.Delete();
		::Continue::
	end
end

MakeObjectFromData = function(Display,Item,Data)
	local Object = ProgressPane.CreateDisplayObject();
	--[[Object.SetItem(Item);
	Object.SetItemCount(Data);
	if Data.Valid == false then
		Object.SetColor(DisplaySettings.ChildrenErrorColor);
	else
		Object.SetColor(DisplaySettings.ChildrenColor);
	end--]]
	if Data.Recipe ~= nil then
		for _,ingredient in ipairs(Data.Recipe.Ingredients) do
			Object.AddObject(MakeObjectFromData(Display,ingredient.Item,ingredient.Data),ingredient.Item.name);
		end
	end
	UpdateObjectData(Display,Object,Item,Data);
	return Object;
end

UpdateObjectData = function(Display,Object,Item,Data)
	if Data.Valid == false then
		Object.SetColor(DisplaySettings.ChildrenErrorColor);
	else
		Object.SetColor(DisplaySettings.ChildrenColor);
	end
	Object.SetItem(Item);
	Object.SetItemCount(Data.TotalNeeded);
	if Data.Recipe ~= nil then
		for _,ingredient in ipairs(Data.Recipe.Ingredients) do
			--Object.AddObject(MakeObjectFromData(Display,ingredient.Item,ingredient.Data,ingredient.Item.name));
			UpdateObjectData(Display,Object.GetObject(ingredient.Item.name),ingredient.Item,ingredient.Data);
		end
	end
	--if Data.Valid == false then
		--If couldn't find enough

	--end
end

--Progress canvas click callback
function __progressCanvasClick(position,buttonType,isDown)
	for _,func in pairs(MouseTests) do
		func(position,buttonType,isDown);
	end
end
--Creates a new Display Renderer for the CraftData
function ProgressPane.CreateNewDisplay()
	local Display = {};
	local Meta = {};
	DisplayToMeta[Display] = Meta;
	local TopAnchor;
	local TitleRect;
	local BackgroundRect;
	local TitleTextPositioning;
	local TitleText = "";
	local TitleTextSize = 8;
	local BottomAnchor;
	local Children = {};
	local NameTable = {};

	Display.IsDisplay = true;

	local Render = function()
		--Render the Title bar
		ProgressCanvas:drawRect(SubtractSliderOffset(BackgroundRect),DisplaySettings.BackgroundColor);
		ProgressCanvas:drawRect(SubtractSliderOffset(TitleRect),DisplaySettings.TitleColor);
		ProgressCanvas:drawText(TitleText,SubtractSliderOffset(TitleTextPositioning),TitleTextSize);
		for i=1,#Children do
			ObjectToMeta[Children[i]].Render();
		end
	end
	Meta.UpdateChildren = function()
		local ChildrenStartPos = {2,TitleRect[4] - DisplaySettings.ChildrenHeightSpacing - DisplaySettings.ChildrenSize[2]};
		--sb.logInfo("ChildrenStartPos = " .. sb.print(ChildrenStartPos));
		for i=1,#Children do
			local meta = ObjectToMeta[Children[i]];
			meta.SetPosition(ChildrenStartPos);
			meta.UpdateChildren();
			local NextPosition = Children[i].GetLowestPoint();
			ChildrenStartPos[2] = NextPosition[2] - DisplaySettings.ChildrenSize[2] - DisplaySettings.ChildrenHeightSpacing;
			--sb.logInfo("NEXT ChildrenStartPos = " .. sb.print(ChildrenStartPos));
			--ChildrenStartPos[2] = ChildrenStartPos[2] - 2 - DisplaySettings.ChildrenHeightSpacing;
		end
	end


	if #Displays > 0 then
		local Anchor = Displays[#Displays].GetBottomAnchor();
		TopAnchor = {Anchor[1],Anchor[2] - DisplaySettings.MainSpacing};
	else
		TopAnchor = {HighestAnchorPoint[1],HighestAnchorPoint[2]};
	end
	Meta.CalculateRects = function()
		TitleRect = {0,TopAnchor[2],ProgressCanvasSize[1],TopAnchor[2] - DisplaySettings.TitleHeight};
		TitleTextPositioning = {
			position = {TitleRect[1] + 1,TitleRect[2] - 1},
			horizontalAnchor = "left",
			verticalAnchor = "top"
		}
		Meta.UpdateChildren();
		if #Children > 0 then
			BottomAnchor = Children[#Children].GetLowestPoint();
		else
			BottomAnchor = {0,TitleRect[4]};
		end
		BackgroundRect = {0,TopAnchor[2],ProgressCanvasSize[1],BottomAnchor[2] - (DisplaySettings.MainSpacing)};
		if #Displays > 1 and Displays[#Displays] ~= Display then
			for i=1,#Displays - 1 do
				if Displays[i] == Display then
					DisplayToMeta[Displays[i + 1]].CalculateRects();
				end
			end
		end
		--BottomAnchor[2] = BottomAnchor[2] - DisplaySettings.MainSpacing;
		--sb.logInfo("BackgroundRect = " .. sb.print(BackgroundRect));
	end
	local UpdateRenderParams = function(topAnchor)
		TopAnchor = topAnchor;
		Meta.CalculateRects();
		--sb.logInfo("UPDATED BOTTOM ANCHOR = " .. sb.print(BottomAnchor));
		return BottomAnchor;
	end
	local RenderID = AddToRenderQueue(Render,UpdateRenderParams);
	Meta.CalculateRects();
	--MainSlider.SetProgress();


	--Returns the Bottom Anchor of the Display
	Display.GetBottomAnchor = function()
		return {BottomAnchor[1],BottomAnchor[2]};
		
	end

	--Sets the title text and text size
	Display.SetTitle = function(text,size)
		size = size or 8;
		text = text or "";
		TitleText = text;
		TitleTextSize = size;
	end

	Display.AddObject = function(Object,optionalName)
		if ObjectToMeta[Object] ~= nil then
			local meta = ObjectToMeta[Object];
			if meta.Owner ~= nil then
				meta.Owner.RemoveObject(Object);
			end
			meta.Owner = Display;
			if optionalName ~= nil then
				NameTable[optionalName] = Object;
			end
			Children[#Children + 1] = Object;
			Meta.UpdateChildren();
			Meta.CalculateRects();
			UpdateRenderQueue();
		else
			error("This is not a valid Object");
		end
	end

	Display.GetObject = function(name)
		return NameTable[name];
	end

	Display.RemoveObject = function(Object)
		if type(Object) == "string" then
			Display.RemoveObject(NameTable[Object]);
			NameTable[Object] = nil;
		end
		if ObjectToMeta[Object] ~= nil then
			local meta = ObjectToMeta[Object];
			if meta.Owner == Display then
				for i=1,#Children do
					if Children[i] == Object then
						table.remove(Children,i);
						meta.Owner = nil;
						Meta.UpdateChildren();
						Meta.CalculateRects();
						UpdateRenderQueue();
						return nil;
					end
				end
			else
				error("This object is not a child of this parent");
			end
		else
			error("This is not a valid Object");
		end
	end

	--Deletes the Display
	Display.Delete = function()
		for i=1,#Children do
			Children[i].Delete();
		end
		RemoveFromRenderQueue(RenderID);
	end

	Displays[#Displays + 1] = Display;
	return Display;
end

--Adds a render function to the render queue
AddToRenderQueue = function(func,updateParamsFunc)
	local ID = sb.makeUuid();
	RenderQueue[#RenderQueue + 1] = {
		ID = ID,
		Func = func,
		Update = updateParamsFunc
	}
	--sb.logInfo("_ADDING = " .. sb.print(RenderQueue[#RenderQueue]));
	return ID;
end

--Creates a display object
function ProgressPane.CreateDisplayObject()
	local Object = {};
	local Meta = {};
	local Children = {};
	local ChildrenTop;
	local ChildrenBottom;
	local LineDuets = {};
	local RenderRect;
	local SlotRect;
	local RenderMiddle;
	local RenderItem;
	local RenderItemImage;
	local RenderItemRarityImage;
	local RenderItemRarityImageProgressBottom;
	local RenderItemRarityImageProgressTop;
	local RenderItemRarityImageProgressTopTextureRect;
	local RenderItemRarityImageProgressTopRect;
	local RenderItemRarityImageRect = {0,0,18,18};
	local RenderItemRarityRect;
	local RenderItemTextureRect;
	local CountNumber = 0;
	local CountNumberString = "";
	local CountNumberPosition = {
		horizontalAnchor = "right",
		verticalAnchor = "bottom"
	}
	local RenderItemRect;
	local ProgressBarEnabled = false;
	local CurrentProgress = 1;
	local TestID = sb.makeUuid();
	local NameTable = {};
	local ChildColor = DisplaySettings.ChildrenColor;
	Meta.OnDeleteFunctions = {};
	Meta.Owner = nil;
	Meta.Position = {0,0};
	Meta.Render = function()
		if Meta.Owner ~= nil then
			--ProgressCanvas:drawRect(SubtractSliderOffset(RenderRect),DisplaySettings.ChildrenColor);
			ProgressCanvas:drawImage(DisplaySettings.ChildrenImage,SubtractSliderOffset(RenderMiddle),nil,ChildColor,true);
			ProgressCanvas:drawImage(DisplaySettings.SlotImage,SubtractSliderOffset(RenderMiddle),nil,nil,true);
			if RenderItem ~= nil then
				if ProgressBarEnabled == true then
					ProgressCanvas:drawImage(RenderItemRarityImageProgressBottom,SubtractSliderOffset(RenderMiddle),nil,nil,true);
					ProgressCanvas:drawImageRect(RenderItemRarityImageProgressTop,RenderItemRarityImageProgressTopTextureRect,SubtractSliderOffset(RenderItemRarityImageProgressTopRect));
				else
					ProgressCanvas:drawImage(RenderItemRarityImage,SubtractSliderOffset(RenderMiddle),nil,nil,true);
				end
				ProgressCanvas:drawImageRect(RenderItemImage,RenderItemTextureRect,SubtractSliderOffset(RenderItemRect));
				ProgressCanvas:drawText(CountNumberString,SubtractSliderOffset(CountNumberPosition),8);
			end
			for i=2,#LineDuets,2 do
				ProgressCanvas:drawLine(SubtractSliderOffset(LineDuets[i - 1]),SubtractSliderOffset(LineDuets[i]));
			end
			for i=1,#Children do
				ObjectToMeta[Children[i]].Render();
			end
		end
	end

	Meta.UpdateChildren = function()
		LineDuets = {};
		local ChildrenStartPos = {Meta.Position[1] + math.floor(DisplaySettings.ChildrenSize[1] / 2),Meta.Position[2] - DisplaySettings.ChildrenHeightSpacing - DisplaySettings.ChildrenSize[2]};
		--sb.logInfo("ObjectTest for " .. sb.print(TestID) .. " = " .. sb.print(ChildrenStartPos));
		for i=1,#Children do
			local meta = ObjectToMeta[Children[i]];
			meta.SetPosition(ChildrenStartPos);
			meta.UpdateChildren();
			LineDuets[#LineDuets + 1] = {Meta.Position[1] + 5,Meta.Position[2] - 1};
			LineDuets[#LineDuets + 1] = {LineDuets[#LineDuets][1],ObjectToMeta[Children[i]].Position[2] + 5};
			LineDuets[#LineDuets + 1] = {LineDuets[#LineDuets][1],ObjectToMeta[Children[i]].Position[2] + 5};
			LineDuets[#LineDuets + 1] = {ObjectToMeta[Children[i]].Position[1],ObjectToMeta[Children[i]].Position[2] + 5};
			local NextPosition = Children[i].GetLowestPoint();
			ChildrenStartPos[2] = NextPosition[2] - DisplaySettings.ChildrenSize[2] - DisplaySettings.ChildrenHeightSpacing;
			--sb.logInfo("NEXT2 ChildrenStartPos = " .. sb.print(ChildrenStartPos));
			--ChildrenStartPos[2] = ChildrenStartPos[2] - 2 - DisplaySettings.ChildrenHeightSpacing;
		end
	end
	Meta.AddOnDeleteFunction = function(func)
		Meta.OnDeleteFunctions[#Meta.OnDeleteFunctions + 1] = func;
	end
	Meta.RemoveOnDeleteFunction = function(func)
		for i=1,#Meta.OnDeleteFunctions do
			if Meta.OnDeleteFunctions[i] == func then
				table.remove(Meta.OnDeleteFunctions,i);
				return nil;
			end
		end
	end

	Meta.SetPosition = function(position)
		Meta.Position = {position[1],position[2]};
		--sb.logInfo("Setting Position for = " .. sb.print(TestID));
		--sb.logInfo("Position = " .. sb.print(Meta.Position));
		RenderRect = {Meta.Position[1],Meta.Position[2],Meta.Position[1] + DisplaySettings.ChildrenSize[1], Meta.Position[2] + DisplaySettings.ChildrenSize[2]};
		RenderMiddle = {(RenderRect[3] - RenderRect[1]) / 2 + RenderRect[1],(RenderRect[4] - RenderRect[2]) / 2 + RenderRect[2]};
		--SlotRect = {RenderMiddle[1] - DisplaySettings.SlotImageSize[1] / 2,RenderMiddle[2] - DisplaySettings.SlotImageSize[2] / 2,RenderMiddle[1] + DisplaySettings.SlotImageSize[1],RenderMiddle[2] + DisplaySettings.SlotImageSize[2]};
		if RenderItem ~= nil then
			--sb.logInfo("Position = " .. sb.print(Meta.Position));
			RenderItemRect = {3 + Meta.Position[1],3 + Meta.Position[2],19 + Meta.Position[1],19 + Meta.Position[2]};
			RenderItemRarityRect = {2 + Meta.Position[1],2 + Meta.Position[2],20 + Meta.Position[1],20 + Meta.Position[2]};
			CountNumberPosition.position = {Meta.Position[1] + DisplaySettings.ChildrenSize[1],Meta.Position[2] - 1};
			--sb.logInfo("____________________RENDER RECT = " .. sb.print(RenderItemRect));
			if ProgressBarEnabled == true then
				Object.SetProgress(Object.GetProgress());
			end

		end
		Meta.UpdateChildren();
	end

	Object.SetItem = function(item)
		if item == nil then
			RenderItem = nil;
			RenderItemImage = nil;
			RenderItemTextureRect = nil;
		else
			local Config = root.itemConfig(item);
			local Image = Config.config.inventoryIcon;
			local Renderable = ImageCore.MakeImageCanvasRenderable(ImageCore.MakePathAbsolute(Image,item));
			RenderItem = item;
			Object.SetItemCount(item.count or 1);
			RenderItemImage = Renderable.Image;
			RenderItemRarityImage = ImageCore.RaritySlotImage(item.name);
			RenderItemTextureRect = Renderable.TextureRect;
			RenderItemRect = {3 + Meta.Position[1],3 + Meta.Position[2],19 + Meta.Position[1],19 + Meta.Position[2]};
			RenderItemRarityRect = {2 + Meta.Position[1],2 + Meta.Position[2],20 + Meta.Position[1],20 + Meta.Position[2]};
			CountNumberPosition.position = {Meta.Position[1] + DisplaySettings.ChildrenSize[1],Meta.Position[2] - 1};
			--sb.logInfo("RarityRect = " .. sb.print(RenderItemRarityRect));
			if ProgressBarEnabled == true then
				Object.SetProgress(Object.GetProgress());
			end
		end
	end

	Object.GetParent = function()
		return Meta.Owner;
	end

	Object.GetDisplay = function()
		local Parent = Object.GetParent();
		if Parent == nil then
			return nil;
		end
		while(true) do
			if Parent.IsDisplay == true then
				return Parent;
			else
				Parent = Parent.GetParent();
				if Parent == nil then
					return nil;
				end
			end
		end
	end

	Object.GetItem = function()
		return RenderItem;
	end

	Object.SetColor = function(color)
		ChildColor = color;
	end

	Object.SetItemCount = function(count)
		if count ~= CountNumber then
			CountNumber = count;
			CountNumberString = NumberToString(count);
		end
	end

	Object.GetItemCount = function()
		return CountNumber;
	end

	Object.EnableProgressBar = function(bool)
		ProgressBarEnabled = bool == true;
		Object.SetProgress(1);
	end

	Object.GetProgress = function()
		return CurrentProgress;
	end

	Object.SetProgress = function(progress)
		if progress > 1 then
			progress = 1;
		elseif progress < 0 then
			progress = 0;
		end
		CurrentProgress = progress;
		if RenderItem ~= nil then
			RenderItemRarityImageProgressBottom = RenderItemRarityImage .. "?brightness=-50";
			local Size = root.imageSize(RenderItemRarityImage);
			local Reduction = math.floor(Size[2] * (1 - CurrentProgress));
			RenderItemRarityImageProgressTop = RenderItemRarityImage;
			RenderItemRarityImageProgressTopRect = {2 + Meta.Position[1],2 + Meta.Position[2] + Reduction,20 + Meta.Position[1],20 + Meta.Position[2]};
			RenderItemRarityImageProgressTopTextureRect = {0,Reduction,Size[1],Size[2]};
		end
	end

	ObjectToMeta[Object] = Meta;

	Object.GetPosition = function()
		return {Meta.Position[1],Meta.Position[2]};
	end

	Object.AddObject = function(object,optionalName)
		if ObjectToMeta[object] ~= nil then
			local meta = ObjectToMeta[object];
			if meta.Owner ~= nil then
				meta.Owner.RemoveObject(object);
			end
			if optionalName ~= nil then
				NameTable[optionalName] = object;
			end
			meta.Owner = object;
			Children[#Children + 1] = object;
			Meta.UpdateChildren();
			local Display = Object.GetDisplay();
			if Display ~= nil then
				UpdateRenderQueue();
			end
		else
			error("This is not a valid Object");
		end
	end

	Object.GetObject = function(name)
		return NameTable[name];
	end

	Object.RemoveObject = function(object)
		if type(object) == "string" then
			Object.RemoveObject(NameTable[object]);
		end
		if ObjectToMeta[object] ~= nil then
			local meta = ObjectToMeta[object];
			if meta.Owner == Object then
				for i=1,#Children do
					if Children[i] == object then
						table.remove(Children,i);
						meta.Owner = nil;
						Meta.UpdateChildren();
						local Display = Object.GetDisplay();
						if Display ~= nil then
							UpdateRenderQueue();
						end
						return nil;
					end
				end
			else
				error("This object is not a child of this parent");
			end
		else
			error("This is not a valid Object");
		end
	end

	Object.GetLowestPoint = function()
		if #Children > 0 then
			return Children[#Children].GetLowestPoint();
		else
			return Object.GetPosition();
		end
	end

	--TODO GET POSITION, SET POSITION, UPDATE CHILDREN
	return Object;
end

RemoveFromRenderQueue = function(ID)
	for i=1,#RenderQueue do
		if RenderQueue[i].ID == ID then
			--sb.logInfo("Removing = " .. sb.print(ID));
			table.remove(RenderQueue,i);
			--[[local TopAnchor = {HighestAnchorPoint[1],HighestAnchorPoint[2]};
			for i=1,#RenderQueue do
				TopAnchor = RenderQueue[i].Update(TopAnchor);
				TopAnchor = {TopAnchor[1],TopAnchor[2] - DisplaySettings.MainSpacing};
			end--]]
			UpdateRenderQueue();
			return nil;
		end
	end
end

UpdateRenderQueue = function()
	local TopAnchor = {HighestAnchorPoint[1],HighestAnchorPoint[2]};
	for i=1,#RenderQueue do
		TopAnchor = RenderQueue[i].Update(TopAnchor);
		TopAnchor = {TopAnchor[1],TopAnchor[2] - DisplaySettings.MainSpacing};
	end
	--Update Progress Size
	if #Displays == 0 then
		--Set To Default
		MainSlider.SetProgressSize(1);
	else
		local Top = HighestAnchorPoint[2];
		local Bottom = Displays[#Displays].GetBottomAnchor()[2] - DisplaySettings.MainSpacing;
		--sb.logInfo("BottomAnchor = " .. sb.print(Displays[#Displays].GetBottomAnchor()));
		--local MaxProgressSize = (Top - Bottom) / Top;
		local MaxProgressSize = (Top - Bottom) / Top;
		local ClampedProgress = MainSlider.GetProgress() / MainSlider.GetProgressSize();
		local NewProgress = ClampedProgress * MaxProgressSize;
		--Progress = (Top - Result) / (Top - Bottom)
		--sb.logInfo("Top Anchor = " .. sb.print(TopAnchor));
		--sb.logInfo("RenderQueue Size = " .. sb.print(#RenderQueue));
		--sb.logInfo("Top = " .. sb.print(Top));
		--sb.logInfo("Bottom = " .. sb.print(Bottom));
		--sb.logInfo("ClampedProgress = " .. sb.print(ClampedProgress))
		--sb.logInfo("NewProgress = " .. sb.print(NewProgress));
		--sb.logInfo("MaxProgressSize = " .. sb.print(MaxProgressSize));
		--sb.logInfo("Top = " .. sb.print(Top));
		--sb.logInfo("Bottom = " .. sb.print(Bottom));
		MainSlider.SetProgressSize(MaxProgressSize);
		MainSlider.SetProgress(NewProgress);
		--sb.logInfo("SliderOffset = " .. sb.print(SliderOffset));
		--sb.logInfo("Progress = " .. sb.print(MainSlider.GetProgress()));
	end
	--local ClampedProgress = MainSlider.GetProgress() / MainSlider.GetProgress();
	--MainSlider.SetProgressSize();
end

--Adds a render function to the render queue
AddToSimpleRenderQueue = function(func)
	local ID = sb.makeUuid();
	SimpleRenderQueue[#SimpleRenderQueue + 1] = {
		ID = ID,
		Func = func
	}
	return ID;
end

RemoveFromSimpleRenderQueue = function(ID)
	for i=1,#SimpleRenderQueue do
		if SimpleRenderQueue[i].ID == ID then
			table.remove(SimpleRenderQueue,i);
			return nil;
		end
	end
end

NumberToString = function(num)
	num = math.floor(num);
	if num <= 1 then
		return "";
	end
    --Million
    if num >= 1000000 then
        local Number = num / 1000000;
        local Final = math.floor(Number);
        if Number < 10 then
            Final = Final + (GetDecimalPlace(Number,1) / 10);
        end
        if Number < 1 then
            Final = Final + (GetDecimalPlace(Number,2) / 100);
        end
        return tostring(Final) .. "M";
    --Thousand
    elseif num >= 1000 then
        local Number = num / 1000;
        local Final = math.floor(Number);
        if Number < 10 then
            Final = Final + (GetDecimalPlace(Number,1) / 10);
        end
        if Number < 1 then
            Final = Final + (GetDecimalPlace(Number,2) / 100);
        end
        return tostring(Final) .. "K";
        --Leave Alone
    else
        return tostring(num);
    end
end

GetDecimalPlace = function(num,n)
    num = math.abs(num);
    for i=1,n do
        local Number,Decimal = math.modf(num);
        if Decimal == nil then return 0 end;
        num = Decimal * 10;
        if num == 0 then
            return 0;
        end
    end
    return math.floor(num);
end

--Creates a Vertical Slider Area
function ProgressPane.CreateSlider()
	local Slider = {};
	local Meta = {};
	local Position = {0,0};
	local Size = 100;
	local Progress = 0;
	local ProgressSize = 1;
	local ScrollerClicked = false;
	local ArrowClicked;
	local ScrollerHeightOffset;
	local ScrollerHovered = false;

	--Images
	local ImageTop = "/Blocks/Crafting Terminal/UI/Window/SliderTop.png";
	local ImageMid = "/Blocks/Crafting Terminal/UI/Window/SliderMid.png";
	local ImageBottom = "/Blocks/Crafting Terminal/UI/Window/SliderBottom.png";
	local Images = {
		Regular = {},
		Background = {},
		Highlights = {}
	}
	local Arrows = {
		Regular = {},
		Highlights = {}
	}
	--Rects
	local CoverageArea;
	local MiddleLine;
	local TopArrowRect;
	local BottomArrowRect;
	local ScrollAreaRect;
	local BackgroundRects = {};
	local ScrollRects = {};

	local Render = function()
		--sb.logInfo("Drawing");

		--Draw Background Scroller
		--Top
		--ProgressCanvas:drawImageRect(Images.Background.Top,Images.TopTexRect,BackgroundRects.Top);
		--Mid
		--ProgressCanvas:drawTiledImage(Images.Background.Mid,{0,0},BackgroundRects.Mid);
		--Bottom
		--ProgressCanvas:drawImageRect(Images.Background.Bottom,Images.BottomTexRect,BackgroundRects.Bottom);
		if ScrollerClicked == true then
			local MousePosition = ProgressCanvas:mousePosition();
			local ActualScrollPosition = MousePosition[2] - ScrollerHeightOffset;
			--ClampedProgress = (Top - Result) / (Top - Bottom) 		-- Range 0-1
			--Progress = ((Top - Result) / Top - Bottom) * ProgresSize 		-- Range 0-ProgressSize
			--local Percentage = ((ActualScrollPosition - ScrollRects.Min[2]) / (ScrollRects.Max[2] - ScrollRects.Min[2])) * ProgressSize;
			local Top = ScrollRects.Min[2];
			local Bottom = ScrollRects.Max[2];
			local Result = ActualScrollPosition;
			--sb.logInfo("__Top = " .. sb.print(Top));
			--sb.logInfo("__Bottom = " .. sb.print(Bottom));
			--sb.logInfo("__Result = " .. sb.print(Result));
			--sb.logInfo("__Top = " .. sb.print(Top));
			local Percentage = ((Top - Result) / (Top - Bottom)) * ProgressSize;
			if ProgressSize == 1 then
				Percentage = 0;
			end
			--sb.logInfo("ActualScrollPosition = " .. sb.print(ActualScrollPosition));
			--sb.logInfo("ScrolLRects = " .. sb.print(ScrollRects));
			--sb.logInfo("ProgressSize = " .. sb.print(ProgressSize));
			--sb.logInfo("Percentage = " .. sb.print(Percentage));
			--sb.logInfo("ClampedPercentage = " .. sb.print(Percentage / ProgressSize));
			Slider.SetProgress(Percentage);

		end

		--sb.logInfo("Current Arrow Clicked = " .. sb.print(ArrowClicked));
		if ArrowClicked == "top" then
			Slider.SetProgress(Slider.GetProgress() - (1 * DT));
		elseif ArrowClicked == "bottom" then
			Slider.SetProgress(Slider.GetProgress() + (1 * DT));
		end



		--Draw Main Scroller
		if ScrollerHovered == true then
			ProgressCanvas:drawImageRect(Images.Highlights.Top,Images.TopTexRect,ScrollRects.CurrentTop);
			--Mid
			ProgressCanvas:drawTiledImage(Images.Highlights.Mid,{0,0},ScrollRects.Current);
			--Bottom
			ProgressCanvas:drawImageRect(Images.Highlights.Bottom,Images.BottomTexRect,ScrollRects.CurrentBottom);
		else
			ProgressCanvas:drawImageRect(Images.Regular.Top,Images.TopTexRect,ScrollRects.CurrentTop);
			--Mid
			ProgressCanvas:drawTiledImage(Images.Regular.Mid,{0,0},ScrollRects.Current);
			--Bottom
			ProgressCanvas:drawImageRect(Images.Regular.Bottom,Images.BottomTexRect,ScrollRects.CurrentBottom);
		end

		--Top Arrow
		--sb.logInfo("Arrows.Regular.Top = " .. sb.print(Arrows.Regular.Top));
		--sb.logInfo("Arrows.TopTextRect = " .. sb.print(Arrows.TopTexRect));
		--sb.logInfo("TopArrowRect = " .. sb.print(TopArrowRect));
		ProgressCanvas:drawImageRect(Arrows.Regular.Top,Arrows.TopTexRect,TopArrowRect);
		--Bottom Arrow
		ProgressCanvas:drawImageRect(Arrows.Regular.Bottom,Arrows.BottomTexRect,BottomArrowRect);
	end
	
	local HoverTest = function(position)
		--[[if RectCore.VectIntersect(ScrollRects.TotalArea,position) then

		end--]]
		ScrollerHovered = RectCore.VectIntersect(ScrollRects.TotalArea,position);
	end

	local MouseTest = function(position,buttonType,IsDown)
		--sb.logInfo("ButtonType = " .. sb.print(buttonType));
		if buttonType == 0 then
			--sb.logInfo("ArrowClicked = " .. sb.print(ArrowClicked));
			--sb.logInfo("IsDown = " .. sb.print(IsDown));
			if ScrollerClicked == true and IsDown == false then
				ScrollerClicked = false;
			else
				if ArrowClicked ~= nil and IsDown == false then
					ArrowClicked = nil;
				elseif RectCore.VectIntersect(TopArrowRect,position) then
					ArrowClicked = "top";
				elseif RectCore.VectIntersect(BottomArrowRect,position) then
					ArrowClicked = "bottom";
				else
					if IsDown == true and RectCore.VectIntersect(ScrollRects.TotalArea,position) then
						ScrollerClicked = true;
						ScrollerHeightOffset = position[2] - ScrollRects.Current[2];
					end
				end
			end
		end
	end

	local MouseID = AddToMouseTests(MouseTest);
	local HoverID = AddToHoverTests(HoverTest);
	local RenderID = AddToSimpleRenderQueue(Render);

	Images.Regular.Top = "/Blocks/Crafting Terminal/UI/Window/SliderTop.png";
	Images.Regular.Mid = "/Blocks/Crafting Terminal/UI/Window/SliderMid.png";
	Images.Regular.Bottom = "/Blocks/Crafting Terminal/UI/Window/SliderBottom.png";

	Images.Background.Top = "/Blocks/Crafting Terminal/UI/Window/SliderTop.png?brightness=-75";
	Images.Background.Mid = "/Blocks/Crafting Terminal/UI/Window/SliderMid.png?brightness=-75";
	Images.Background.Bottom = "/Blocks/Crafting Terminal/UI/Window/SliderBottom.png?brightness=-75";

	Images.Highlights.Top = "/Blocks/Crafting Terminal/UI/Window/SliderTop.png?brightness=100";
	Images.Highlights.Mid = "/Blocks/Crafting Terminal/UI/Window/SliderMid.png?brightness=100";
	Images.Highlights.Bottom = "/Blocks/Crafting Terminal/UI/Window/SliderBottom.png?brightness=100";

	Images.TopSize = root.imageSize(Images.Regular.Top);
	Images.TopTexRect = {0,0,Images.TopSize[1],Images.TopSize[2]};
	Images.MidSize = root.imageSize(Images.Regular.Mid);
	Images.MidTexRect = {0,0,Images.MidSize[1],Images.MidSize[2]};
	Images.BottomSize = root.imageSize(Images.Regular.Bottom);
	Images.BottomTexRect = {0,0,Images.BottomSize[1],Images.BottomSize[2]};
	local ImageWidth = Images.MidSize[1];

	Arrows.Regular.Top = "/Blocks/Crafting Terminal/UI/Window/SliderArrowUp.png";
	Arrows.Regular.Bottom = "/Blocks/Crafting Terminal/UI/Window/SliderArrowDown.png";
	Arrows.TopSize = root.imageSize(Arrows.Regular.Top);
	Arrows.BottomSize = root.imageSize(Arrows.Regular.Bottom);
	Arrows.TopTexRect = {0,0,Arrows.TopSize[1],Arrows.TopSize[2]};
	Arrows.BottomTexRect = {0,0,Arrows.BottomSize[1],Arrows.BottomSize[2]};
	--Functions
	local UpdateSize;
	local UpdatePosition;
	local UpdateProgress;
	local UpdateProgressSize;
	local UpdateMainRects;

	Slider.GetProgress = function()
		return Progress;
	end
	Images.Regular.Top = "/Blocks/Crafting Terminal/UI/Window/SliderTop.png";
	Images.Regular.Mid = "/Blocks/Crafting Terminal/UI/Window/SliderMid.png";
	Images.Regular.Bottom = "/Blocks/Crafting Terminal/UI/Window/SliderBottom.png";
	Slider.SetProgress = function(progress)
		if progress < 0 or ProgressSize <= 1 then
			progress = 0;
		elseif progress > ProgressSize then
			progress = ProgressSize;
		end
		Progress = progress;
		UpdateProgress();
	end

	Slider.GetProgressSize = function()
		return ProgressSize;
	end

	Slider.SetProgressSize = function(progressSize)
		if progressSize < 1 then
			progressSize = 1;
		end
		local ClampedProgress = Progress / ProgressSize;
		ProgressSize = progressSize;

		UpdateProgressSize();
		Slider.SetProgress(ClampedProgress * ProgressSize);
	end

	Slider.GetPosition = function()
		return {Position[1],Position[2]};
	end

	Slider.SetPosition = function(position)
		Position = {position[1],position[2]};
		UpdatePosition();
	end

	Slider.GetSize = function()
		return Size;
	end

	Slider.SetSize = function(size)
		Size = size;
		UpdateSize();
	end

	UpdateSize = function()
		UpdateMainRects();
	end

	UpdatePosition = function()
		UpdateMainRects();
	end

	UpdateProgress = function()
		--sb.logInfo("Progress = " .. sb.print(Progress));
		--sb.logInfo("ProgressSize = " .. sb.print(ProgressSize));
		ScrollRects.Current = {ScrollRects.Min[1],ScrollRects.Min[2] - ((ScrollRects.Min[2] - ScrollRects.Max[2]) * (Progress / ProgressSize)),ScrollRects.Min[3],ScrollRects.Min[4] - ((ScrollRects.Min[4] - ScrollRects.Max[4]) * (Progress / ProgressSize))};
		ScrollRects.CurrentTop = {ScrollRects.Current[1],ScrollRects.Current[4],ScrollRects.Current[3],ScrollRects.Current[4] + Images.TopSize[2]};
		ScrollRects.CurrentBottom = {ScrollRects.Current[1],ScrollRects.Current[2] - Images.BottomSize[2],ScrollRects.Current[3],ScrollRects.Current[2]};
		ScrollRects.TotalArea = {ScrollRects.CurrentBottom[1],ScrollRects.CurrentBottom[2],ScrollRects.CurrentTop[3],ScrollRects.CurrentTop[4]};
		--sb.logInfo("ScrollRects = " .. sb.print(ScrollRects));
	end

	UpdateProgressSize = function()
		ScrollRects.Min = {BackgroundRects.Top[1],BackgroundRects.Top[2] - ((BackgroundRects.Top[2] - BackgroundRects.Bottom[4]) / ProgressSize),BackgroundRects.Top[3],BackgroundRects.Top[2]};
		ScrollRects.Max = {BackgroundRects.Bottom[1],BackgroundRects.Bottom[4],BackgroundRects.Bottom[3],(BackgroundRects.Top[2] - BackgroundRects.Bottom[4]) / ProgressSize + BackgroundRects.Bottom[4]};
		ScrollRects.PixelHeight = ScrollRects.Min[2] - ScrollRects.Max[2];
		ScrollRects.StartPos = ScrollRects.Max[2];
		UpdateProgress();
	end

	UpdateMainRects = function()
		CoverageArea = {Position[1],Position[2],Position[1] + ImageWidth,Position[2] + Size};
		MiddleLine = (CoverageArea[3] - CoverageArea[1]) / 2 + CoverageArea[1];
		TopArrowRect = {MiddleLine - (Arrows.TopSize[1] / 2),CoverageArea[4] - Arrows.TopSize[2],MiddleLine + (Arrows.TopSize[1] / 2),CoverageArea[4]};
		BottomArrowRect = {MiddleLine - (Arrows.BottomSize[1] / 2),CoverageArea[2],MiddleLine + (Arrows.BottomSize[1] / 2),CoverageArea[2] + Arrows.BottomSize[2]};
		ScrollAreaRect = {TopArrowRect[1],BottomArrowRect[4],BottomArrowRect[3],TopArrowRect[2]};
		BackgroundRects.Top = {ScrollAreaRect[1],ScrollAreaRect[4] - Images.TopSize[2],ScrollAreaRect[3],ScrollAreaRect[4]};
		BackgroundRects.Bottom = {ScrollAreaRect[1],ScrollAreaRect[2],ScrollAreaRect[3],ScrollAreaRect[2] + Images.BottomSize[2]};
		BackgroundRects.Mid = {BackgroundRects.Top[1],BackgroundRects.Bottom[4],BackgroundRects.Bottom[3],BackgroundRects.Top[2]};
		--sb.logInfo("BackgroundRects = " .. sb.printJson(BackgroundRects,1));
		--sb.logInfo("ScrollAreaRect = " .. sb.print(ScrollAreaRect));
		--sb.logInfo("BottomArrowRect = " .. sb.print(BottomArrowRect));
		---sb.logInfo("TopArrowRect = " .. sb.print(TopArrowRect));
		--sb.logInfo("CoverageArea = " .. sb.print(CoverageArea));
		UpdateProgressSize();
	end

	UpdateMainRects();

	Slider.Delete = function()
		RemoveFromSimpleRenderQueue(RenderID);
		RemoveFromMouseTests(MouseID);
		RemoveFromHoverTests(HoverID);
		for index in pairs(Slider) do
			Slider[index] = nil;
		end
	end
	--UpdatePosition();
	--UpdateSize();
	--UpdateProgress();
	--UpdateProgressSize();
	return Slider;
end

AddToMouseTests = function(func)
	local ID = sb.makeUuid();
	MouseTests[ID] = func;
	return ID;
end

RemoveFromMouseTests = function(ID)
	MouseTests[ID] = nil;
end

AddToHoverTests = function(func)
	local ID = sb.makeUuid();
	HoverTests[ID] = func;
	return ID;
end

RemoveFromHoverTests = function(ID)
	HoverTests[ID] = nil;
end

SubtractSliderOffset = function(rect)
	if rect.position ~= nil then
		return {position = SubtractSliderOffset(rect.position),horizontalAnchor = rect.horizontalAnchor,verticalAnchor = rect.verticalAnchor,wrapWidth = rect.wrapWidth};
	end
	if #rect == 4 then
		return {rect[1],rect[2] + SliderOffset,rect[3],rect[4] + SliderOffset};
	else
		return {rect[1],rect[2] + SliderOffset};
	end
end