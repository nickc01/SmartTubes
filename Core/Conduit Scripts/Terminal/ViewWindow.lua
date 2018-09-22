--The Main Controller of the Main View Window in the Conduit Terminal UI
if ViewWindow ~= nil then return nil end;
require("/Core/Conduit Scripts/Terminal/TerminalUI.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");
require("/Core/UICore.lua");

--Declaration

--Public Table
ViewWindow = {};
local ViewWindow = ViewWindow;
--Private Table
__ViewWindow__ = {};
local __ViewWindow__ = __ViewWindow__;

--Variables
local Initialized = false;
local ViewChanged = false;
local Canvas;
local Position;
local Scale = 1;
local ScaleDest = Scale;
local ScaleSpeed = 7;
local ScaleMin = 0.125;
local ScaleMax = 2;
local Size;
local PlayerID;
local SourceID;
local SourcePosition;
local IndexToStringMeta = {
	__index = function(tbl,k)
		if type(k) == "number" then
			return rawget(tbl,tostring(k));
		else
			return rawget(tbl,k);
		end
	end,
	__newindex = function(tbl,k,value)
		if type(k) == "number" then
			return rawset(tbl,tostring(k),value);
		else
			return rawset(tbl,k,value);
		end
	end,
	__ipairs = function(tbl)
		local k,i = nil,nil;
		return function()
			k,i = next(tbl,k);
			if k == nil then
				return nil;
			end
			return tonumber(k),i;
		end
	end}
local ConduitPreviousData = setmetatable({},IndexToStringMeta);
local AddedRenderers = {};
local AnimationToImageCache = setmetatable({},IndexToStringMeta);
local BackgroundClickFunctions = {};
local BackgroundHeldDown = false;
local MovingTheBackground = false;
local MouseDifference;
local SmoothSetPosition = true;
local SmoothSteps = 7;
local SmoothDestination;
local SelectedObject;
local SelectedObjectControllers;
local JsonCache = {};
local UpdateFunctions = {};

--Images
local BackgroundImage = "/Blocks/Conduit Terminal/UI/Window/TileImage.png";
local BackgroundImageSize = {0,0,2000,2000};

--Functions
local NetworkChange;
local Update;
local DrawBackground;
local AnimationToImage;
local GetBaseController;
local AddRenderer;
local AddRendererWithController;
local RemoveRenderer;
local MoveRenderer;
local MoveRendererToTop;
local MoveRendererToBottom;
local ClearAllRenderers;
local GenerateRenderRects;
local GenerateCollisionRect;
local GenerateScreenRect;
local SetupConduitRenderer;
local SetupObjectRenderer;
local RenderToWindow;
local RenderRectToWindow;
local RenderLineToWindow;
local BackgroundScrolling;
local GetJson;
local SetPositionRaw;
local SetRendererCollisionState;
local SetRendererRenderingState;
local GetRendererCollisionState;
local GetRendererRenderingState;
local IsInTable;
local AddUpdateFunction;
local RemoveUpdateFunction;

--Initializes the ViewWindow
function ViewWindow.Initialize(canvasName)
	if Initialized == true then return nil end;
	Initialized = true;
	PlayerID = player.id();
	--sb.logInfo("MAIN OBJECT ON OTHER SIDE = " .. sb.print(config.getParameter("MainObject")));
	SourceID = config.getParameter("MainObject") or pane.sourceEntity();
	SourcePosition = world.entityPosition(SourceID);
	TerminalUI.Initialize();
	Canvas = widget.bindCanvas(canvasName or "mainCanvas");
	Size = Canvas:size();
	Position = {Size[1] / 2,Size[2] / 2};
	SmoothDestination = Position;
	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
	ViewWindow.AddBackgroundClickFunction(BackgroundScrolling);
end

--Called when the backgroun is clicked and no longer Clicking
--This function handles the mouse scrolling of the background
BackgroundScrolling = function(clicking)
	if clicking == true then
		local MousePos = Canvas:mousePosition();
		MouseDifference = {MousePos[1] - Position[1],MousePos[2] - Position[2]};
		MovingTheBackground = true;
	else
		MovingTheBackground = false;
	end
end

--The Update Loop of the View Window
Update = function(dt)
	local MousePos = Canvas:mousePosition();
	if MovingTheBackground == true then
		ViewChanged = true;
		SetPositionRaw({MousePos[1] - MouseDifference[1],MousePos[2] - MouseDifference[2]});
	end
	local ScaleMoved = false;
	if SmoothSetPosition then
		if math.abs(SmoothDestination[1] - Position[1]) > 0.01 or math.abs(SmoothDestination[2] - Position[2]) > 0.01 then
			ViewChanged = true;
			ScaleMoved = true;
			--sb.logInfo("Moving To = " .. sb.print({(SmoothDestination[1] - Position[1]) * dt * SmoothSteps + Position[1],(SmoothDestination[2] - Position[2]) * dt * SmoothSteps + Position[2]}));
		end
		Scale = ((ScaleDest - Scale) * dt * ScaleSpeed) + Scale;
		Position = {(SmoothDestination[1] - Position[1]) * dt * SmoothSteps + Position[1],(SmoothDestination[2] - Position[2]) * dt * SmoothSteps + Position[2]};
	end
	for _,func in pairs(UpdateFunctions) do
		func(dt);
	end
	--sb.logInfo("Diff = " .. sb.print(ScaleDest - Scale));
	if ScaleMoved == false and math.abs(ScaleDest - Scale) > 0.00001 then
		ScaleMoved = true;
		ViewChanged = true;
		Scale = ((ScaleDest - Scale) * dt * ScaleSpeed) + Scale;
	end
	--if math.abs(ScaleDest - Scale) > 0.01 then
		--sb.logInfo("Scaling To = " .. sb.print(((ScaleDest - Scale) * dt * ScaleSpeed) + Scale));
		--Scale = ((ScaleDest - Scale) * dt * ScaleSpeed) + Scale;
		--SmoothDestination = {SmoothDestination[1] + (ScaleDest - Scale) * SmoothDestination[1],SmoothDestination[2] + (ScaleDest - Scale) * SmoothDestination[2]};
		--Position = {Position[1] - (ScaleDest - Scale) * Position[1],Position[2] - (ScaleDest - Scale) * Position[2]};
	--	ViewChanged = true;
	--end
	for _,renderer in pairs(AddedRenderers) do
		--Check for hovering
		if renderer.OnHover ~= nil then
			local Rect = renderer.CollisionRectFunction();
			if Rect ~= nil then
				if renderer.Hovering == true then
					if MousePos[1] < Rect[1] * Scale + Position[1] or MousePos[2] < Rect[2] * Scale + Position[2] or MousePos[1] > Rect[3] * Scale + Position[1] or MousePos[2] > Rect[4] * Scale + Position[2] then
						renderer.Hovering = nil;
						renderer.OnHover(false);
					end
				else
					if not (MousePos[1] < Rect[1] * Scale + Position[1] or MousePos[2] < Rect[2] * Scale + Position[2] or MousePos[1] > Rect[3] * Scale + Position[1] or MousePos[2] > Rect[4] * Scale + Position[2]) then
						renderer.Hovering = true;
						renderer.OnHover(true);
					end
				end
			end
		end
	end
	if ViewChanged == true then
		ViewChanged = false;
		Canvas:clear();
		DrawBackground();
		--[[for _,renderer in pairs(AddedRenderers) do
			renderer.Function();
		end--]]
		for i=1,#AddedRenderers do
			AddedRenderers[i].Function();
		end
	--else
		--sb.logInfo("BATCH");
	end
end

--Draws the background image to the Canvas
DrawBackground = function()
	Canvas:drawTiledImage(BackgroundImage,{Position[1] * 0.7 / Scale,Position[2] * 0.7 / Scale},BackgroundImageSize,0.1);
end

--Removes all the objects that are being rendered
function ViewWindow.Clear()
	ViewChanged = true;
	ClearAllRenderers();
end

--Sets the Position of the ViewWindow
function ViewWindow.SetPosition(position)
	ViewChanged = true;
	if SmoothSetPosition then
		SmoothDestination = {-(position[1] - SourcePosition[1]) * 8 * ScaleDest + Size[1] / 2,-(position[2] - SourcePosition[2]) * 8 * ScaleDest + Size[2] / 2};
	else
		Position = {-(position[1] - SourcePosition[1]) * 8 * ScaleDest + Size[1] / 2,-(position[2] - SourcePosition[2]) * 8 * ScaleDest + Size[2] / 2};
	end
end

--Sets whether it should smoothly transition to the new Position
function ViewWindow.SetPositionSmooth(bool)
	if bool == true then
		ViewChanged = true;
		SmoothDestination = Position;
	end
	SmoothSetPosition = bool == true;
end

--Gets the Position of the ViewWindow
function ViewWindow.GetPosition()
	return Position;
end

SetPositionRaw = function(position)
	ViewChanged = true;
	if SmoothSetPosition then
		SmoothDestination = position;
	else
		Position = position;
	end
end

--Adds a conduit to be rendered
--Returns 3 if the object isn't a valid conduit
function ViewWindow.AddConduit(object,position,color,onClick,onHover,scale,terminalData,objectName)
	if scale == nil then
		scale = 1;
	end
	--sb.logInfo("Position = " .. sb.print(world.entityPosition(object)));
	--sb.logInfo("SOURCE OBJECT NAME = " .. sb.print(objectName));
	objectName = objectName or world.entityName(object);
	local RelativePosition = VectorCore.Subtract(position or world.entityPosition(object),SourcePosition);
	local TerminalParameters,TerminalData;
	if terminalData == nil then
		TerminalParameters = UICore.AsyncFunctionCall(object,"ConduitCore.GetTerminalImageParameters",ConduitPreviousData[object] or {FlipX = false,FlipY = false,AnimationName = nil,AnimationState = nil});
		TerminalData = TerminalParameters();
	else
		TerminalData = terminalData;
	end
	--TODO Replace object in SetupConduitRenderer with objectName
	if TerminalData ~= nil then
		local Controller;
		local Render,CollisionRect;
		local Offset;
		local Textures;
		local FlipX,FlipY;
		if TerminalData.AnimationName ~= nil then
			Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupConduitRenderer(objectName,RelativePosition,color,TerminalData,scale);
		else
			Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
		end
		local RenderFunction = function()
			Render();
		end
		local CollisionRectFunction = function()
			return CollisionRect();
		end
		local UpdateID;
		UpdateID = AddUpdateFunction(function(dt)
			if TerminalParameters ~= nil then
				TerminalData,Done = TerminalParameters();
				if Done == true then
					if TerminalData.AnimationName ~= nil then
						Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupConduitRenderer(objectName,RelativePosition,color,TerminalData,scale);
					else
						Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
					end
					ViewChanged = true;
					ConduitPreviousData[object] = TerminalData;
					TerminalParameters = nil;
					RemoveUpdateFunction(UpdateID);
				end
			end
		end);
		ViewChanged = true;
		local RenderID,Controller = AddRendererWithController(RenderFunction,CollisionRectFunction,onClick,onHover);
		--Returns the Position of the Object
		Controller.GetPosition = function(includesOffset)
			-- TODO -- TODO -- TODO -- TODO -- TODO -- TODO
			if includesOffset == true then
				return {RelativePosition[1] + SourcePosition[1] + Offset[1] / 8,RelativePosition[2] + SourcePosition[2] + Offset[2] / 8};
			else
				return {RelativePosition[1] + SourcePosition[1],RelativePosition[2] + SourcePosition[2]};
			end
		end
		Controller.GetOffset = function()
			return Offset;
		end
		Controller.ObjectID = function()
			return object;
		end
		Controller.SetPosition = function(newPosition,includesOffset)
			if includesOffset == true then
				RelativePosition = {newPosition[1] - SourcePosition[1] - Offset[1] / 8,newPosition[2] - SourcePosition[2] - Offset[2] / 8};
			else
				RelativePosition = {newPosition[1] - SourcePosition[1],newPosition[2] - SourcePosition[2]};
			end
			ViewChanged = true;
			if TerminalData.AnimationName ~= nil then
				Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupConduitRenderer(objectName,RelativePosition,color,TerminalData,scale);
			else
				Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
			end
		end
		Controller.GetScale = function()
			return scale;
		end
		Controller.SetScale = function(newScale)
			if newScale ~= scale then
				scale = newScale;
				ViewChanged = true;
				if TerminalData.AnimationName ~= nil then
					Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupConduitRenderer(objectName,RelativePosition,color,TerminalData,scale);
				else
					Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
				end
			end
		end
		Controller.GetColor = function()
			return color;
		end
		Controller.SetColor = function(newColor)
			if newColor == nil then
				color = newColor;
			end
			if color == nil then
				color = newColor;
				ViewChanged = true;
				if TerminalData.AnimationName ~= nil then
					Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupConduitRenderer(objectName,RelativePosition,color,TerminalData,scale);
				else
					Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
				end
			else
				color[1],color[2],color[3],color[4] = newColor[1],newColor[2],newColor[3],newColor[4];
			end
		end
		Controller.GetTextures = function()
			return Textures;
		end
		Controller.GetCollisionRect = function()
			return CollisionRect();
		end
		Controller.FlipX = function()
			return FlipX;
		end
		Controller.FlipY = function()
			return FlipY;
		end
		return Controller;
	end
	return 3;
end

--Adds an object to be rendered
function ViewWindow.AddObject(object,position,color,onClick,onHover,scale,objectName)
	if scale == nil then
		scale = 1;
	end
	objectName = objectName or world.entityName(object);
	local RelativePosition = VectorCore.Subtract(position or world.entityPosition(objectName),SourcePosition);
	local Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
	local RenderFunction = function()
		Render();
	end
	local CollisionRectFunction = function()
		return CollisionRect();
	end
	ViewChanged = true;
	local RenderID,Controller = AddRendererWithController(RenderFunction,CollisionRectFunction,onClick,onHover);
	Controller.GetPosition = function(includesOffset)
		-- TODO -- TODO -- TODO -- TODO -- TODO -- TODO
		if includesOffset == true then
			return {RelativePosition[1] + SourcePosition[1] + Offset[1] / 8,RelativePosition[2] + SourcePosition[2] + Offset[2] / 8};
		else
			return {RelativePosition[1] + SourcePosition[1],RelativePosition[2] + SourcePosition[2]};
		end
	end
	Controller.GetOffset = function()
		return Offset;
	end
	Controller.SetPosition = function(newPosition,includesOffset)
		if includesOffset == true then
			RelativePosition = {newPosition[1] - SourcePosition[1] - Offset[1] / 8,newPosition[2] - SourcePosition[2] - Offset[2] / 8};
		else
			RelativePosition = {newPosition[1] - SourcePosition[1],newPosition[2] - SourcePosition[2]};
		end
		ViewChanged = true;
		Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
	end
	Controller.GetScale = function()
		return scale;
	end
	Controller.SetScale = function(newScale)
		if newScale ~= scale then
			scale = newScale;
			ViewChanged = true;
			Render,CollisionRect,Offset,Textures,FlipX,FlipY = SetupObjectRenderer(objectName,RelativePosition,color,scale);
		end
	end
	Controller.GetColor = function()
		return color;
	end
	Controller.SetColor = function(newColor)
		ViewChanged = true;
		if color == nil or newColor == nil then
			color = newColor;
		else
			color[1],color[2],color[3],color[4] = newColor[1],newColor[2],newColor[3],newColor[4];
		end
	end
	Controller.ObjectID = function()
		return object;
	end
	Controller.GetTextures = function()
		return Textures;
	end
	Controller.GetCollisionRect = function()
		return CollisionRect();
	end
	Controller.FlipX = function()
		return FlipX;
	end
	Controller.FlipY = function()
		return FlipY;
	end
	return Controller;
end

--Adds some text to be rendered
function ViewWindow.AddText(text,startPosition,textMap,textImage,color)
	textMap = textMap or "/Core/ArgonGUI/Elements/Text/Default.json";
	textImage = textImage or "/Core/ArgonGUI/Elements/Text/Default.png";
	local Map = GetJson(textMap).Map;
	local Texture = textImage;
	local TextureRects;
	local ScreenRects;
	local GenerateText = function()
		TextureRects,ScreenRects = {},{};
		local Position = {startPosition[1] - SourcePosition[1],startPosition[2] - SourcePosition[2]};
		for char in string.gmatch(text,".") do
			--sb.logInfo("Char = " .. sb.print(char));
			if char == " " then
				Position[1] = Position[1] + Map.WidthOfSpace / 8;
			else
				local CharDimensions;
				local PosOffset;
				local CharPos;
				if Map.BigCharacters[char] ~= nil then
					CharDimensions = Map.TextSize;
					PosOffset = Map.TextOffset;
					CharPos = Map.BigCharacters[char];
				elseif Map.SmallCharacters[char] ~= nil then
					CharDimensions = Map.SmallSize;
					PosOffset = Map.SmallOffset;
					CharPos = Map.SmallCharacters[char];
				end
				if CharDimensions ~= nil then
					TextureRects[#TextureRects + 1] = {CharPos[1],CharPos[2],CharPos[1] + CharDimensions[1],CharPos[2] + CharDimensions[2]};
					--RelativePosition,Offset,ImageSizeX,ImageSizeY,Scale
					ScreenRects[#ScreenRects + 1] = GenerateScreenRect(Position,{0,0},CharDimensions[1],CharDimensions[2],1);
					--Position[1] = Position[1] + CharDimensions[1] + PosOffset[1];
					--Position[2] = Position[2] + PosOffset[2];
					Position[1] = Position[1] + (CharDimensions[1] + PosOffset[1]) / 8;
					Position[2] = Position[2] + PosOffset[2] / 8;
				end
			end
		end
	end
	GenerateText();
	local RenderFunction = function()
		--sb.logInfo("RENDERING");
		for i=1,#ScreenRects do
			--sb.logInfo("RENDERTEXT");
			RenderToWindow(textImage,TextureRects[i],ScreenRects[i],color);
		end
	end
	--sb.logInfo("Adding");
	ViewChanged = true;
	local RenderID,Controller = AddRendererWithController(RenderFunction);
	Controller.GetText = function()
		return text;
	end
	Controller.SetText = function(newText)
		if newText ~= text then
			text = newText;
			ViewChanged = true;
			GenerateText();
		end
	end
	Controller.GetPosition = function()
		return startPosition;
	end
	Controller.SetPosition = function(newPosition)
		startPosition = newPosition;
		ViewChanged = true;
		GenerateText();
	end
	Controller.GetFullWidth = function()
		local LowX,HighX;
		for i=1,#ScreenRects do
			if LowX == nil or ScreenRects[i][1] < LowX then
				LowX = ScreenRects[i][1];
			end
			if HighX == nil or ScreenRects[i][3] > HighX then
				HighX = ScreenRects[i][3];
			end
		end
		if LowX == nil or HighX == nil then
			return 0;
		else
			return (HighX - LowX) / 8;
		end
	end
	Controller.GetFullHeight = function()
		local LowY,HighY;
		for i=1,#ScreenRects do
			if LowY == nil or ScreenRects[i][2] < LowY then
				LowY = ScreenRects[i][2];
			end
			if HighY == nil or ScreenRects[i][4] > HighY then
				HighY = ScreenRects[i][4];
			end
		end
		if LowY == nil or HighY == nil then
			return 0;
		else
			return (HighY - LowY) / 8;
		end
	end
	return Controller;
end

--Adds a texture to be rendered
function ViewWindow.AddTexture(texture,position,color,onClick,onHover,scale,FlipX,FlipY)
	local RenderTexture = ImageCore.MakeImageCanvasRenderable(texture);
	local RelativePosition = VectorCore.Subtract(position,SourcePosition);
	local TextureRect = RectCore.Flip(RenderTexture.TextureRect,FlipX,FlipY,true);
	local Texture = RenderTexture.Image;
	--Texture,RelativePosition,Offset,Scale,ImageSizeX,ImageSizeY
	ViewChanged = true;
	local ScreenRect,CollisionRect = GenerateRenderRects(Texture,RelativePosition,{0,0},scale,RenderTexture.Width,RenderTexture.Height);
	--TODO -- TODO -- TODO -- TODO, add call the add renderer and make a controller
	local RenderFunction = function()
		RenderToWindow(Texture,TextureRect,ScreenRect,color);
	end
	local CollisionRectFunction = function()
		return CollisionRect;
	end
	local RenderID,Controller = AddRendererWithController(RenderFunction,CollisionRectFunction,onClick,onHover);
	Controller.GetPosition = function()
		return {RelativePosition[1] + SourcePosition[1],RelativePosition[2] + SourcePosition[2]};
	end
	Controller.GetOffset = function()
		return {0,0};
	end
	Controller.SetPosition = function(newPosition)
		ViewChanged = true;
		RelativePosition = {newPosition[1] - SourcePosition[1],newPosition[2] - SourcePosition[2]};
		ScreenRect,CollisionRect = GenerateRenderRects(RenderTexture.Image,RelativePosition,{0,0},scale,RenderTexture.Width,RenderTexture.Height);
	end
	Controller.GetScale = function()
		return scale;
	end
	Controller.SetScale = function(newScale)
		if newScale ~= scale then
			scale = newScale;
			ViewChanged = true;
			ScreenRect,CollisionRect = GenerateRenderRects(RenderTexture.Image,RelativePosition,{0,0},scale,RenderTexture.Width,RenderTexture.Height);
		end
	end
	Controller.GetColor = function()
		return color;
	end
	Controller.GetCollisionRect = function()
		return CollisionRect();
	end
	Controller.SetColor = function(newColor)
		color = newColor;
		ViewChanged = true;
		--if 
	--	color[1],color[2],color[3],color[4] = newColor[1],newColor[2],newColor[3],newColor[4];
	end
	Controller.GetTextures = function()
		return {texture};
	end
	return Controller;
end

--Sets up a rect to be rendered
function ViewWindow.AddRect(Rect,color,OnClick,OnHover)
	local ScreenRect = {(Rect[1] - SourcePosition[1]) * 8,(Rect[2] - SourcePosition[2]) * 8,(Rect[3] - SourcePosition[1]) * 8,(Rect[4] - SourcePosition[2]) * 8};
	local RenderFunction = function()
		RenderRectToWindow(ScreenRect,color);
	end
	local CollisionRectFunction = function()
		return ScreenRect;
	end
	ViewChanged = true;
	local RenderID,Controller = AddRendererWithController(RenderFunction,CollisionRectFunction,OnClick,OnHover);
	Controller.GetColor = function()
		return color;
	end
	Controller.SetColor = function(newColor)
		ViewChanged = true;
		color = newColor;
	end
	Controller.GetRect = function()
		return Rect;
	end
	Controller.GetCollisionRect = function()
		return ScreenRect;
	end
	Controller.SetRect = function(newRect)
		Rect = newRect;
		ViewChanged = true;
		ScreenRect = {(Rect[1] - SourcePosition[1]) * 8,(Rect[2] - SourcePosition[2]) * 8,(Rect[3] - SourcePosition[1]) * 8,(Rect[4] - SourcePosition[2]) * 8};
	end
	return Controller;
end

--Sets up a line to be rendered
function ViewWindow.AddLine(StartPos,EndPos,color,LineWidth)
	local FinalStartPos = {(StartPos[1] - SourcePosition[1]) * 8,(StartPos[2] - SourcePosition[2]) * 8};
	local FinalEndPos = {(EndPos[1] - SourcePosition[1]) * 8,(EndPos[2] - SourcePosition[2]) * 8};
	local RenderFunction = function()
		RenderLineToWindow(FinalStartPos,FinalEndPos,color,LineWidth);
	end
	ViewChanged = true;
	local RenderID,Controller = AddRendererWithController(RenderFunction);
	Controller.GetColor = function()
		return color;
	end
	Controller.SetColor = function(newColor)
		ViewChanged = true;
		color = newColor;
	end
	Controller.GetStartPos = function()
		return StartPos;
	end
	Controller.SetStartPos = function(newStartPos)
		ViewChanged = true;
		StartPos = newStartPos;
		FinalStartPos = {(StartPos[1] - SourcePosition[1]) * 8,(StartPos[2] - SourcePosition[2]) * 8};
	end
	Controller.GetEndPos = function()
		return StartPos;
	end
	Controller.SetEndPos = function(newEndPos)
		ViewChanged = true;
		EndPos = newEndPos;
		FinalEndPos = {(EndPos[1] - SourcePosition[1]) * 8,(EndPos[2] - SourcePosition[2]) * 8};
	end
	return Controller;
end

--Sets up the conduit renderer
SetupConduitRenderer = function(object,relativePosition,color,TerminalData,scale)
	--sb.logInfo("ANIMATION SOURCE = " .. sb.print(TerminalData.AnimationSource));
	local RenderImage,Offset,OriginalImage = AnimationToImage(object,TerminalData.AnimationName,TerminalData.AnimationState,TerminalData.AnimationFile,TerminalData.AnimationParts,TerminalData.AnimationSource);
	local ScreenRect,CollisionRect = GenerateRenderRects(OriginalImage,relativePosition,Offset,scale,RenderImage.Width,RenderImage.Height);
	local TextureRect = RectCore.Flip(RenderImage.TextureRect,TerminalData.FlipX,TerminalData.FlipY,true);
	local RenderTexture = RenderImage.Image;
	local Render = function()
		RenderToWindow(RenderTexture,TextureRect,ScreenRect,color);
	end
	local CollisionRectFunction = function()
		return CollisionRect;
	end
	return Render,CollisionRectFunction,Offset,{OriginalImage},TerminalData.FlipX,TerminalData.FlipY;
end

--Sets up the Object renderer
SetupObjectRenderer = function(object,RelativePosition,color,scale)
	local ImageData = ImageCore.ObjectToImage(object);
	--sb.logInfo("ImageData = " .. sb.print(ImageData));
	--sb.logInfo("Object = " .. sb.print(object));
	local CollisionRegion = {};
	local ImageSize = {};
	local ScreenRects = {};
	local ImageTable = {};
	local TextureRects = {};
	for _,image in ipairs(ImageData.Images) do
		--sb.logInfo("Original Image = " .. sb.print(image.Original));
		local Region = root.nonEmptyRegion(image.Original);
		--sb.logInfo("REGION = " .. sb.print(Region));
		ImageTable[#ImageTable + 1] = image.Original;
		if CollisionRegion[1] == nil or Region[1] < CollisionRegion[1] then
			CollisionRegion[1] = Region[1];
		end
		if CollisionRegion[2] == nil or Region[2] < CollisionRegion[2] then
			CollisionRegion[2] = Region[2];
		end
		if CollisionRegion[3] == nil or Region[3] > CollisionRegion[3] then
			CollisionRegion[3] = Region[3];
		end
		if CollisionRegion[4] == nil or Region[4] > CollisionRegion[4] then
			CollisionRegion[4] = Region[4];
		end
		if ImageSize[1] == nil or image.Width > ImageSize[1] then
			ImageSize[1] = image.Width;
		end
		if ImageSize[2] == nil or image.Height > ImageSize[2] then
			ImageSize[2] = image.Height;
		end
		ScreenRects[#ScreenRects + 1] = GenerateScreenRect(RelativePosition,ImageData.Offset,image.Width,image.Height,scale);
		TextureRects[#TextureRects + 1] = RectCore.Flip(image.TextureRect,ImageData.Flip,false,true);
	end
	--sb.logInfo("IMAGESIZE = " .. sb.print(ImageSize));
	--sb.logInfo("CollisionRegion = " .. sb.print(CollisionRegion));
	local CollisionRect = GenerateCollisionRect(RelativePosition,CollisionRegion,ImageData.Offset,ImageSize[1],ImageSize[2],scale);
	--sb.logInfo("GENERATED COLLISION RECT = " .. sb.print(CollisionRect));
	local Render = function()
		for i,texture in ipairs(ImageData.Images) do
			RenderToWindow(texture.Image,TextureRects[i],ScreenRects[i],color);
		end
	end
	local CollisionRectFunction = function()
		return CollisionRect;
	end
	return Render,CollisionRectFunction,ImageData.Offset,ImageTable,ImageData.Flip,false;
end

--Gets an image from an object's animation name and state
--Returns the image properties and the image offset
AnimationToImage = function(Object,Name,State,File,AnimationParts,AnimationSource)
	--sb.logInfo("Animation To Image Object = " .. sb.print(Object));
	local Animation;
	if File ~= nil then
		Animation = ImageCore.TranslateAnimationFile(File,AnimationParts or world.getObjectParameter(Object,"animationParts"),AnimationSource or Object);
	else
		Animation = ImageCore.ParseObjectAnimation(Object);
	end
	local CurrentLayer = Animation.Layers[Name];
	local CurrentState = CurrentLayer.States[State] or CurrentLayer.States[CurrentLayer.DefaultState];
	local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
	local ObjectToImageData = ImageCore.ObjectToImage(Object);
	return ImageParams,ObjectToImageData.Offset,CurrentState.Image;
end

--Returns a Controller base
GetBaseController = function()
	local Controller = {};
	return Controller;
end

--Adds a renderer
AddRenderer = function(renderFunction,CollisionRectFunction,OnClick,OnHover,Controller)
	local RenderID = sb.makeUuid();
	if Controller ~= nil then
		Controller = setmetatable(Controller,{
			SetToNull = false,
			__index = function(tbl,k)
				if SetToNull == false then
					return rawget(tbl,k);
				else
					return nil;
				end
			end
		});
	end
	AddedRenderers[#AddedRenderers + 1] = {ID = RenderID,Function = renderFunction,CollisionRectFunction = CollisionRectFunction,OnClick = OnClick,OnHover = OnHover,Controller = Controller,RenderEnabled = true,CollisionEnabled = CollisionRectFunction ~= nil};
	return RenderID;
end

--Adds a renderer and creates a base controller for it
AddRendererWithController = function(renderFunction,CollisionRectFunction,OnClick,OnHover)
	local Controller = {};
	local RenderID = AddRenderer(renderFunction,CollisionRectFunction,OnClick,OnHover,Controller);
	
	--Removes this object
	Controller.Remove = function()
		ViewChanged = true;
		RemoveRenderer(RenderID);
	end

	--Moves this object up a set amount of Layers
	Controller.MoveLayers = function(amount)
		ViewChanged = true;
		MoveRenderer(RenderID,amount);
	end

	--Moves the object to the top layer
	Controller.MoveToTop = function()
		ViewChanged = true;
		MoveRendererToTop(RenderID);
	end

	--Moves the object to the bottom layer
	Controller.MoveToBottom = function()
		ViewChanged = true;
		MoveRendererToBottom(RenderID);
	end

	--Gets the Current state of Collision
	Controller.CollisionEnabled = function()
		return GetRendererCollisionState(RenderID);
	end

	--Sets the Current state of Collision
	Controller.SetCollisionEnabled = function(bool)
		return GetRendererCollisionState(RenderID,bool);
	end

	--Gets the Current state of Rendering
	Controller.CollisionEnabled = function()
		return GetRendererRenderingState(RenderID);
	end

	--Sets the Current state of Rendering
	Controller.SetCollisionEnabled = function(bool)
		return GetRendererRenderingState(RenderID,bool);
	end

	return RenderID,Controller;
end

--Removes a renderer
RemoveRenderer = function(RenderID)
	for i=#AddedRenderers,1,-1 do
		if AddedRenderers[i].ID == RenderID then
			if AddedRenderers[i].Controller ~= nil then
				local Meta = getmetatable(AddedRenderers[i].Controller);
				if Meta ~= nil then
					Meta.SetToNull = true;
				end
			end
			table.remove(AddedRenderers,i);
			return nil;
		end
	end
end

--Sets the collision state of a renderer
SetRendererCollisionState = function(renderID,bool)
	for i=#AddedRenderers,1,-1 do
		if AddedRenderers[i].ID == renderID then
			AddedRenderers[i].CollisionEnabled = bool == true;
			return nil;
		end
	end
end

--Sets the render state of a renderer
SetRendererRenderingState = function(renderID,bool)
	for i=#AddedRenderers,1,-1 do
		if AddedRenderers[i].ID == renderID then
			AddedRenderers[i].RenderEnabled = bool == true;
			return nil;
		end
	end
end

--Gets the collision state of a renderer
GetRendererCollisionState = function(renderID)
	for i=#AddedRenderers,1,-1 do
		if AddedRenderers[i].ID == renderID then
			return AddedRenderers[i].CollisionEnabled;
		end
	end
end

--Gets the render state of a renderer
GetRendererRenderingState = function(renderID)
	for i=#AddedRenderers,1,-1 do
		if AddedRenderers[i].ID == renderID then
			return AddedRenderers[i].RenderEnabled;
		end
	end
end


--Moves a renderer up a set amount of Layers
-- A Positive value moves up, a negative value moves down
MoveRenderer = function(RenderID,Amount)
	local Size = #AddedRenderers;
	if Amount ~= nil and Amount ~= 0 then
		for i=Size,1,-1 do
			if AddedRenderers[i].ID == RenderID then
				if Amount > 0 then
					if i < Size then
						local Item = table.remove(AddedRenderers,i);
						if i + Amount >= Size then
							AddedRenderers[Size] = Item;
						else
							table.insert(AddedRenderers,i + Amount,Item);
						end
					end
				else
					if i > 1 then
						if i + Amount < 1 then
							Amount = -i + 1;
						end
						table.insert(AddedRenderers,i + Amount,table.remove(AddedRenderers,i));
					end
				end
				return nil;
			end
		end
	end
end

--Moves a renderer to the top of all the Layers
MoveRendererToTop = function(RenderID)
	MoveRenderer(RenderID,#AddedRenderers);
end

--Moves a renderer to the bottom of all the Layers
MoveRendererToBottom = function(RenderID)
	MoveRenderer(RenderID,-#AddedRenderers);
end

--Removes all the renderers
ClearAllRenderers = function()
	AddedRenderers = {};
end

--Generates Render Rects based off of a Texture
GenerateRenderRects = function(Texture,RelativePosition,Offset,Scale,ImageSizeX,ImageSizeY)
	local NonEmptyRegion = root.nonEmptyRegion(Texture);
	if ImageSizeX == nil or ImageSizeY == nil then
		local ImageSize = root.imageSize(Texture);
		if ImageSizeX == nil then
			ImageSizeX = ImageSize[1];
		end
		if ImageSizeY == nil then
			ImageSizeY = ImageSize[2];
		end
	end
	local CollisionRect = GenerateCollisionRect(RelativePosition,NonEmptyRegion,Offset,ImageSizeX,ImageSizeY,Scale);
	local ScreenRect = GenerateScreenRect(RelativePosition,Offset,ImageSizeX,ImageSizeY,Scale);
	return ScreenRect,CollisionRect;
end

--Generates a Collision Rect around something
GenerateCollisionRect = function(RelativePosition,NonEmptyTextureRegion,Offset,ImageSizeX,ImageSizeY,Scale)
	Offset = Offset or {0,0};
	if Scale == nil then
		Scale = 0;
	else
		Scale = Scale - 1;
	end
	return {(RelativePosition[1] + NonEmptyTextureRegion[1] / 8 + Offset[1] / 8) * 8 - Scale,(RelativePosition[2] + NonEmptyTextureRegion[2] / 8 + Offset[2] / 8) * 8 - Scale,(RelativePosition[1] + NonEmptyTextureRegion[3] / 8 + Offset[1] / 8) * 8 + Scale,(RelativePosition[2] + NonEmptyTextureRegion[4] / 8 + Offset[2] / 8) * 8 + Scale};
end

--Generates a Screen Rect for an Object
GenerateScreenRect = function(RelativePosition,Offset,ImageSizeX,ImageSizeY,Scale)
	Offset = Offset or {0,0};
	if Scale == nil then
		Scale = 0;
	else
		Scale = Scale - 1;
	end
	return {(RelativePosition[1] + Offset[1] / 8) * 8 - Scale,(RelativePosition[2] + Offset[2] / 8) * 8 - Scale,(RelativePosition[1] + ImageSizeX / 8 + Offset[1] / 8) * 8 + Scale,(RelativePosition[2] + ImageSizeY / 8 + Offset[2] / 8) * 8 + Scale};
end

--Renders to the View Window
RenderToWindow = function(Texture,TextureRect,ScreenRect,Color)
	--sb.logInfo("ScreenRect = " .. sb.print(ScreenRect));
	local Final = {(ScreenRect[1] * Scale) + Position[1],(ScreenRect[2] * Scale) + Position[2],(ScreenRect[3] * Scale) + Position[1],(ScreenRect[4] * Scale) + Position[2]};
	if not (Final[1] > Size[1] or Final[2] > Size[2] or Final[3] < 0 or Final[4] < 0) then
		Canvas:drawImageRect(Texture,TextureRect,Final,Color);
	end
end

--Renders a rect to the View Window
RenderRectToWindow = function(ScreenRect,Color)
	Canvas:drawRect({(ScreenRect[1] * Scale) + Position[1],(ScreenRect[2] * Scale) + Position[2],(ScreenRect[3] * Scale) + Position[1],(ScreenRect[4] * Scale) + Position[2]},Color);
end

--Renders a line to the View Window
RenderLineToWindow = function(StartPos,EndPos,Color,LineWidth)
	LineWidth = LineWidth or 1;
	Canvas:drawLine({(StartPos[1] * Scale) + Position[1],(StartPos[2] * Scale) + Position[2]},{(EndPos[1] * Scale) + Position[1],(EndPos[2] * Scale) + Position[2]},Color,LineWidth * Scale);
end

--The internal function that is called when the user clicks in the view Window
function __ViewWindow__.OnMouseClick(position,buttonType,isDown)
	local MousePos = position;
	if buttonType == 0 then
		if BackgroundHeldDown == true then
			for _,func in ipairs(BackgroundClickFunctions) do
				func(false);
			end
			BackgroundHeldDown = false;
		end
		local ClickedOnObject = false;
		local DisabledObjects = {};
		for _,renderer in UICore.ReverseIpairs(AddedRenderers) do
			if renderer.OnClick ~= nil then
				if isDown == true and not IsInTable(DisabledObjects,renderer.Controller) then
					local Rect = renderer.CollisionRectFunction();
					if Rect ~= nil then
						if not (MousePos[1] < Rect[1] * Scale + Position[1] or MousePos[2] < Rect[2] * Scale + Position[2] or MousePos[1] > Rect[3] * Scale + Position[1] or MousePos[2] > Rect[4] * Scale + Position[2]) then
							renderer.Clicking = true;
							renderer.OnClick(true,position);
							ClickedOnObject = true;
							local Overlapping = ViewWindow.GetControllersInArea(Rect);
							for i=1,#Overlapping do
								if Overlapping[i] ~= renderer.Controller then
									DisabledObjects[#DisabledObjects + 1] = Overlapping[i];
								end
							end
							--sb.logInfo("Amount Overlapping = " .. sb.print(#Overlapping));
							--error("Break Point");
						end
					end
				else
					if renderer.Clicking == true then
						renderer.Clicking = nil;
						renderer.OnClick(false,position);
					end
				end
			end
		end
		if ClickedOnObject == false and isDown == true then
			for _,func in ipairs(BackgroundClickFunctions) do
				func(true);
			end
			BackgroundHeldDown = true;
		end
	end
end

--Adds a function that is called when the background is clicked on
function ViewWindow.AddBackgroundClickFunction(func)
	BackgroundClickFunctions[#BackgroundClickFunctions + 1] = func;
end

--Sets the Selected Object and adds in buttons to click
--pass in nil to remove the selected object
--when you add buttons, you pass in a name, then a function for it right after
function ViewWindow.SetSelectedObject(Controller,...)
	SelectedObject = Controller;
	if SelectedObjectControllers ~= nil then
		for _,controller in ipairs(SelectedObjectControllers) do
			controller.Remove();
		end
		SelectedObjectControllers = nil;
	end
	if SelectedObject ~= nil then
		local Controllers = {};
		SelectedObjectControllers = Controllers;
		--local ObjectPosition = SelectedObject.GetPosition(true);
		local TextureWidth,TextureHeight;
		local ObjectCollision = SelectedObject.GetCollisionRect();
		TextureWidth,TextureHeight = ObjectCollision[3] - ObjectCollision[1],ObjectCollision[4] - ObjectCollision[2];
		local ObjectPosition = {ObjectCollision[1] / 8 + SourcePosition[1],ObjectCollision[2] / 8 + SourcePosition[2]};
		ViewWindow.SetPosition(ObjectPosition);
		local StartPosition = {ObjectPosition[1],ObjectPosition[2]}
		for name,func in UICore.ParameterIter(2,...) do
			local Text = ViewWindow.AddText(name,StartPosition);
			Controllers[#Controllers + 1] = Text;
			Text.SetPosition({StartPosition[1] - Text.GetFullWidth(),StartPosition[2] - Text.GetFullHeight() + TextureHeight / 8});
			StartPosition[2] = StartPosition[2] - Text.GetFullHeight();
			local TextPos = Text.GetPosition();
			local BackgroundRect = {TextPos[1],TextPos[2],TextPos[1] + Text.GetFullWidth(),TextPos[2] + Text.GetFullHeight()};
			local Rect;
			local ClickFunction = function(clicking)
				if clicking == true then
					--[[if not world.entityExists(Controller.ObjectID()) then
						return nil;
					end--]]
					if func ~= nil then
						func();
					end
				end
			end
			local HoverFunction = function(hovering)
				if hovering == true then
					Rect.SetColor({80,80,255});
				else
					Rect.SetColor({0,0,255});
				end
			end
			Rect = ViewWindow.AddRect(BackgroundRect,{0,0,255},ClickFunction,HoverFunction);
			Rect.MoveLayers(-1);
			Controllers[#Controllers + 1] = Rect;
		end
		Controllers[#Controllers + 1] = ViewWindow.AddLine(ObjectPosition,{ObjectPosition[1] + TextureWidth / 8,ObjectPosition[2]},{0,0,255},3);
		Controllers[#Controllers + 1] = ViewWindow.AddLine({ObjectPosition[1] + TextureWidth / 8,ObjectPosition[2]},{ObjectPosition[1] + TextureWidth / 8,ObjectPosition[2] + TextureHeight / 8},{0,0,255},3);
		Controllers[#Controllers + 1] = ViewWindow.AddLine({ObjectPosition[1] + TextureWidth / 8,ObjectPosition[2] + TextureHeight / 8},{ObjectPosition[1],ObjectPosition[2] + TextureHeight / 8},{0,0,255},3);
		Controllers[#Controllers + 1] = ViewWindow.AddLine({ObjectPosition[1],ObjectPosition[2] + TextureHeight / 8},ObjectPosition,{0,0,255},3);
	end
end

--Returns the selected object controller
function ViewWindow.GetSelectedObject()
	return SelectedObject;
end

--Returns all the object controllers that are within the rect
function ViewWindow.GetControllersInArea(rect)
	local Controllers = {};
	for _,renderer in ipairs(AddedRenderers) do
		--sb.logInfo("RENDERER = " .. sb.print(renderer));
		if renderer.CollisionRectFunction ~= nil then
			local CollisionRect = renderer.CollisionRectFunction();
			--sb.logInfo("COllisionRect = " .. sb.print(CollisionRect));
			--sb.logInfo("Rect = " .. sb.print(rect));
			--sb.logInfo("CollisionRect = " .. sb.print(CollisionRect));
			--sb.logInfo("Intersecting = " .. sb.print(RectCore.Intersect(rect,CollisionRect)));
			if RectCore.Intersect(rect,CollisionRect) then
				Controllers[#Controllers + 1] = renderer.Controller;
				--renderer.Controller.SetColor({255,255,0});
			end
		end
	end
	return Controllers;
end

--Returns the contents of the json, with caching
GetJson = function(file)
	if JsonCache[file] == nil then
		JsonCache[file] = root.assetJson(file);
	end
	return JsonCache[file];
end

--Returns true if the object is in the Table
IsInTable = function(tbl,value)
	for i=1,#tbl do
		if tbl[i] == value then
			return true;
		end
	end
	return false;
end

--Adds an update function
AddUpdateFunction = function(func)
	local ID = sb.makeUuid();
	UpdateFunctions[ID] = func;
	return ID;
end

--Removes an update function
RemoveUpdateFunction = function(ID)
	UpdateFunctions[ID] = nil;
end

--Clicked when the "Zoom In" Button is clicked
function __ViewWindowZoomIn()
	local V = 2;
	if ScaleDest * V > ScaleMax then
		V = ScaleMax / ScaleDest;
	end
	ScaleDest = ScaleDest * V;
	SmoothDestination = {SmoothDestination[1] * V,SmoothDestination[2] * V};
	SmoothDestination = {SmoothDestination[1] - (((V - 1) * Size[1]) / 2),SmoothDestination[2] - (((V - 1) * Size[2]) / 2)};
end

--Clicked when the "Zoom Out" Button is clicked
function __ViewWindowZoomOut()
	local V = 2;
	if ScaleDest / V < ScaleMin then
		V = ScaleDest / ScaleMin;
	end
	ScaleDest = ScaleDest / V;
	--sb.logInfo("Dest = " .. sb.print(SmoothDestination));
	SmoothDestination = {SmoothDestination[1] + (((V - 1) * Size[1]) / 2),SmoothDestination[2] + (((V - 1) * Size[2]) / 2)};
	--SmoothDestination = {SmoothDestination[1] + (Size[1] / 1.4),SmoothDestination[2] + (Size[2] / 1.4)};
	--SmoothDestination = {SmoothDestination[1] / 1.4,SmoothDestination[2] / 1.4};
	SmoothDestination = {SmoothDestination[1] / V,SmoothDestination[2] / V};
end