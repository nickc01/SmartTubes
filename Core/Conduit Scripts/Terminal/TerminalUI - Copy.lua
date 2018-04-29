require("/Core/UICore.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");

--Declaration

--Public Table
TerminalUI = {};
local TerminalUI = TerminalUI;

--Canvas Tables
ViewWindow = {};

--Private Table
__ViewWindow__ = {};

--Variables
local PlayerID;
local SourceID;
local SourcePosition;
local Data = {};
local TestTimer = 0;
local GlideToPositions = true;
local GlideSpeed = 7;
local GlidingPosition;

--Directories
local ViewWindowCanvasBackground = "/Blocks/Conduit Terminal/UI/Window/TileImage.png";

--Canvases
local ViewWindowCanvas;
local ViewWindowOffset;
local ViewWindowScale = 1;

--Functions
local Update;
local NetworkChange;
local RenderMainBackground;
local InitCanvases;
local ConduitRenderCache = {};
local ConduitRenderFunctions = {};
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
local PreviousConduitRenderData = setmetatable({},IndexToStringMeta);
local ConduitRenderData = {
	Cache = {},
	QuickFunctions = {},
	PreviousData = setmetatable({},IndexToStringMeta);}
local ObjectRenderData = {
	Cache = {},
	QuickFunctions = {},
	PreviousData = setmetatable({},IndexToStringMeta);}
local MouseClickEvents = {};
local DefaultMouseClickEvent;
local MouseReleaseFunctions = {};
local MouseHoverEvents = {};
local Network = {};
local NetworkContainers = {};
local CheckHover;

--Initializes the Terminal UI
function TerminalUI.Initialize()
	PlayerID = player.id();
	SourceID = pane.sourceEntity();
	sb.logInfo("SourceID UI = " .. sb.print(SourceID));
	SourcePosition = world.entityPosition(SourceID);
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("ConduitNetwork",SourceID,"Network",{},"NetworkContainers",{});
	Data.AddNetworkChangeFunction(NetworkChange);
	NetworkChange();
	local OldUpdate = update;
	update = function(dt)
		Update(dt);
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
	end
	InitCanvases();
end

--Initializes the Canvases
InitCanvases = function()
	ViewWindowCanvas = widget.bindCanvas("mainCanvas");
	local ViewWindowSize = ViewWindowCanvas:size();
	ViewWindowOffset = {ViewWindowSize[1] / 2,ViewWindowSize[2] / 2};
end

--The Update Loop for the Terminal UI
Update = function(dt)
	ViewWindowCanvas:clear();
	RenderMainBackground();
	--local Network = Data.GetNetwork();
	local PostRender = {};
	if GlideToPositions and GlidingPosition ~= nil then
		ViewWindowOffset[1],ViewWindowOffset[2] = (GlidingPosition[1] - ViewWindowOffset[1]) * (GlideSpeed * dt) + ViewWindowOffset[1],(GlidingPosition[2] - ViewWindowOffset[2]) * (GlideSpeed * dt) + ViewWindowOffset[2];
	end
	--ViewWindow.SetToMousePosition();
	--[[for i=#Network,1,-1 do
		if ViewWindow.RenderConduit(Network[i]) == 3 then
			if world.entityName(Network[i]) == "conduitterminal" then
				--ViewWindow.RenderObject(Network[i]);
				PostRender[#PostRender + 1] = Network[i];
			end
		end
	end--]]
	for i=#Network,1,-1 do
		if ViewWindow.RenderConduit(Network[i].ID,nil,Network[i].Color) == 3 then
			if world.entityName(Network[i].ID) == "conduitterminal" then
				--ViewWindow.RenderObject(Network[i]);
				PostRender[#PostRender + 1] = Network[i];
			end
		end
	end
	local Containers = Data.GetNetworkContainers();
	if Containers ~= nil then
		for _,conduits in pairs(Containers) do
			for _,conduit in ipairs(conduits) do
				ViewWindow.RenderObject(conduit);
			end
		end
	end
	for i=#PostRender,1,-1 do
		ViewWindow.RenderObject(PostRender[i].ID,nil,PostRender[i].Color);
	end
end

--Called when the conduit network changes
NetworkChange = function()
	__ViewWindow__.ClearAllMouseEvents();
	__ViewWindow__.ClearAllMouseHoverEvents();
	ConduitRenderData.Cache = {};
	ConduitRenderData.QuickFunctions = {};
	local ConduitNetwork = Data.GetNetwork();
	Network = {};
	for _,conduit in ipairs(ConduitNetwork) do
		local 
		Network[#Network + 1] = {ID = conduit,Color = {255,255,255}};
		__ViewWindow__.AddMouseHoverEvent()
	end
end

--Renders the main background to the main viewing canvas
RenderMainBackground = function()
	ViewWindowCanvas:drawTiledImage("/Blocks/Conduit Terminal/UI/Window/TileImage.png",{ViewWindowOffset[1] * 0.7,ViewWindowOffset[2] * 0.7},{0,0,2000,2000},0.1);
end


--Renders an image to the View Window
function ViewWindow.RenderImage(Image,Position,Scale,Color)
	Scale = Scale or 1;
	ViewWindowCanvas:drawImage(Image,{(Position[1] / 8) + ViewWindowOffset[1],(Position[2] / 8) + ViewWindowOffset[2]},ViewWindowScale * Scale,Color);
end

--Converts World Positions to Screen Positions 
--function TerminalUI.WorldToScreenPosition()
	
--end

--Renders an image rect to the View Window
function ViewWindow.RenderImageRect(Texture,TextureRect,ScreenRect,Color,FlipHorizontal,FlipVertical)
	TextureRect = RectCore.Flip(TextureRect,FlipHorizontal,FlipVertical,true);
	ScreenRect = RectCore.BaseMultiply(ScreenRect,8);
	ScreenRect = RectCore.VectorAdd(ScreenRect,ViewWindowOffset);
	--sb.logInfo("Draw 2");
	ViewWindowCanvas:drawImageRect(Texture,TextureRect,ScreenRect,Color);
end

--Generates a function that will draw the image (calling the function returned from this is faster than just calling ViewWindow.RenderImageRect)
function ViewWindow.RenderRectFunction(Texture,TextureRect,ScreenRect,Color,FlipHorizontal,FlipVertical)
	local OriginalTextureRect = TextureRect;
	local OriginalScreenRect = ScreenRect;
	TextureRect = RectCore.Flip(TextureRect,FlipHorizontal,FlipVertical,true);
	ScreenRect = RectCore.BaseMultiply(ScreenRect,8);
	--ScreenRect = RectCore.VectorAdd(ScreenRect,ViewWindowOffset);
	local Enabled = true;
	return function(newColor,newTexture,newTextureRect,enable)
		--sb.logInfo("Draw 1");
		if enable ~= Enabled then
			Enabled = enable;
		end
		if newColor ~= Color then
			Color = newColor;
		end
		if newTexture ~= Texture then
			Texture = newTexture;
		end
		if newTextureRect ~= nil and not RectCore.Equal(newTextureRect,OriginalTextureRect) then
			OriginalTextureRect = newTextureRect;
			TextureRect = RectCore.Flip(OriginalTextureRect,FlipHorizontal,FlipVertical,true);
		end
		if Enabled then
			ViewWindowCanvas:drawImageRect(Texture,TextureRect,{(ScreenRect[1] * ViewWindowScale) + ViewWindowOffset[1],(ScreenRect[2] * ViewWindowScale) + ViewWindowOffset[2],(ScreenRect[3] * ViewWindowScale) + ViewWindowOffset[1],(ScreenRect[4] * ViewWindowScale) + ViewWindowOffset[2]},Color);
		end
		return 0;
	end
end

--Renders an object to the View Window
function ViewWindow.RenderObject(Object,ScreenPosition,Color)
	--If there's a quick function to use, then use it
	if ObjectRenderData.QuickFunctions[Object] ~= nil then
		return ObjectRenderData.QuickFunctions[Object](Color);
	end
	local RenderParams = ImageCore.ObjectToImage(Object);
	if RenderParams == nil then return 1 end;
	local Position = ScreenPosition or VectorCore.Subtract(world.entityPosition(Object),SourcePosition);
	local Funcs = {};
	for _,image in ipairs(RenderParams.Images) do
		local ScreenRect = {Position[1] + (RenderParams.Offset[1] / 8),Position[2] + (RenderParams.Offset[2] / 8),Position[1] + (RenderParams.Offset[1] / 8) + image.Width,Position[2] + (RenderParams.Offset[2] / 8) + image.Height};
		ViewWindow.RenderImageRect(image.Image,image.TextureRect,ScreenRect,Color,RenderParams.Flip);
		Funcs[#Funcs + 1] = ViewWindow.RenderRectFunction(image.Image,image.TextureRect,ScreenRect,Color,RenderParams.Flip);
	end
	ObjectRenderData.QuickFunctions[Object] = function(color)
		for i=1,#Funcs do
			local Result = Funcs[i](color);
			if Result ~= 0 then return Result end;
		end
		return 0;
	end
	return 0;
end

--Renders an animated object to the View Window
function ViewWindow.RenderConduit(object,ScreenPosition,Color)
	--If there is a quicker render function defined, then use it
	if ConduitRenderData.QuickFunctions[object] ~= nil then
		return ConduitRenderData.QuickFunctions[object](ScreenPosition,Color);
	end
	if object == nil or not world.entityExists(object) then
		return 5;
	end
	local ObjectData;
	local Done;
	if ConduitRenderData.Cache[object] ~= nil then
		ObjectData,Done = ConduitRenderData.Cache[object]();
	else
		ConduitRenderData.Cache[object] = UICore.AsyncFunctionCall(object,"ConduitCore.GetTerminalImageParameters",ConduitRenderData.PreviousData[object] or {FlipX = false,FlipY = false,AnimationName = nil,AnimationState = nil});
		ObjectData,Done = ConduitRenderData.Cache[object]();
	end
	--If there's object data, then the conduit can be rendered
	if ObjectData ~= nil then
		--If theres animation data that can be used, then utilize it, otherwise, just return a code 3
		if ObjectData.AnimationName ~= nil then
			local Animation = ImageCore.ParseObjectAnimation(object);
			local CurrentLayer = Animation.Layers[ObjectData.AnimationName];
			local CurrentState = CurrentLayer.States[ObjectData.AnimationState];
			if CurrentState == nil then CurrentState = CurrentLayer.States[CurrentLayer.DefaultState] end;
			local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
			local ObjectImageData = ImageCore.ObjectToImage(object);
			local Position = ScreenPosition or VectorCore.Subtract(world.entityPosition(object),SourcePosition);
			local ScreenRect = {Position[1] + (ObjectImageData.Offset[1] / 8),Position[2] + (ObjectImageData.Offset[2] / 8),Position[1] + ImageParams.Width + (ObjectImageData.Offset[1] / 8),Position[2] + ImageParams.Height +(ObjectImageData.Offset[2] / 8)};
			ViewWindow.RenderImageRect(ImageParams.Image,ImageParams.TextureRect,ScreenRect,Color,ObjectData.FlipX,ObjectData.FlipY);
			--If we got all the render data we need from the object, then create a render function that can be used to render much faster
			if Done == true then
				ConduitRenderData.PreviousData[object] = ObjectData;
				local RenderFunction = ViewWindow.RenderRectFunction(ImageParams.Image,ImageParams.TextureRect,ScreenRect,Color,ObjectData.FlipX,ObjectData.FlipY);
				local StoredPosition = Position;
				ConduitRenderData.QuickFunctions[object] = function(newPosition,newColor)
					--Update the position if it is changed
					if newColor ~= Color then
						Color = newColor;
					end
					if newPosition ~= nil and (newPosition[1] ~= StoredPosition[1] or newPosition[2] ~= StoredPosition[2]) then
						StoredPosition = newPosition;
						ScreenRect = {StoredPosition[1] + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + (ObjectImageData.Offset[2] / 8),StoredPosition[1] + ImageParams.Width + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + ImageParams.Height +(ObjectImageData.Offset[2] / 8)};
						RenderFunction = ViewWindow.RenderRectFunction(ImageParams.Image,ImageParams.TextureRect,ScreenRect,Color,ObjectData.FlipX,ObjectData.FlipY);
					end
					RenderFunction(Color);
					return 0;
				end
			end
			return 0;
		else
			return 3;
		end
	end
	return 2;
end

--Returns where the object will be positioned when rendered
function ViewWindow.ObjectRenderPosition(object)
	return VectorCore.Subtract(world.entityPosition(object),SourcePosition);
end

--Returns the rect that will render the object
function ViewWindow.ObjectRenderRect(object)
	--[[local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
	local ObjectImageData = ImageCore.ObjectToImage(object);
	local StoredPosition = ViewWindow.ObjectRenderPosition(object);
	ScreenRect = {StoredPosition[1] + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + (ObjectImageData.Offset[2] / 8),StoredPosition[1] + ImageParams.Width + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + ImageParams.Height +(ObjectImageData.Offset[2] / 8)};--]]
end

--Sets the View Window Position to the position passed
function ViewWindow.SetPosition(pos)
	if GlideToPositions then
		GlidingPosition = pos;
	else
		ViewWindowOffset = pos;
	end
end

--Sets the View Window Position to the Mouse Position
function ViewWindow.SetToMousePosition()
	ViewWindow.SetPosition(ViewWindowCanvas:mousePosition());
end

--Sets whether it should glide over to the new position, or just snap to it
function ViewWindow.GlideToNewPositions(bool)
	if bool == true and GlideToPositions == false then
		ViewWindowOffset = GlidingPosition;
		GlidingPosition = nil;
	end
	GlideToPositions = bool == true;
end

--Sets the Glide Speed
function ViewWindow.SetGlideSpeed(speed)
	GlideSpeed = speed;
end

--Adds an area that, when clicked on, calls the function
function __ViewWindow__.AddMouseClickEvent(rect,func)
	local MouseID = sb.makeUuid();
	MouseClickEvents[MouseID] = {Rect = rect,Function = func};
	return MouseID;
end

--Adds an area that when hovered over, will call the first function, and will call the second function when it's no longer being hovered over
function __ViewWindow__.AddMouseHoverEvent(rect,OnHoverFunc,NoHoverFunc)
	local HoverID = sb.makeUuid();
	MouseHoverEvents[HoverID] = {Rect = rect,OnHoverFunc = OnHoverFunc,NoHoverFunc = NoHoverFunc,Hovering = false};
	return HoverID;
end

--Removes a Mouse Hover event
function __ViewWindow__.RemoveMouseHoverEvent(hoverID)
	MouseHoverEvents[hoverID] = nil;
end

--Removes all Mouse Hover events
function __ViewWindow__.ClearAllMouseHoverEvents()
	MouseHoverEvents = {};
end

--Called to check for Hovering
CheckHover = function()
	local Position = ViewWindowCanvas:mousePosition();
	for _,event in pairs(MouseHoverEvents) do
		local Rect = event.rect;
		if event.Hovering then
			if (Position[1] < Rect[1] * ViewWindowScale + ViewWindowOffset[1] or Position[2] < Rect[2] * ViewWindowScale + ViewWindowOffset[2] or Position[1] > Rect[3] * ViewWindowScale + ViewWindowOffset[1] or Position[2] > Rect[4] * ViewWindowScale + ViewWindowOffset[2]) then
				event.Hovering = false;
				event.NoHoverFunc();
			end
		else
			if not (Position[1] < Rect[1] * ViewWindowScale + ViewWindowOffset[1] or Position[2] < Rect[2] * ViewWindowScale + ViewWindowOffset[2] or Position[1] > Rect[3] * ViewWindowScale + ViewWindowOffset[1] or Position[2] > Rect[4] * ViewWindowScale + ViewWindowOffset[2]) then
				event.Hovering = true;
				event.OnHoverFunc();
			end
		end
	end
end

--Sets the click function that is called when you click on the background
function ViewWindow.AddBackgroundClickEvent(func)
	DefaultMouseClickEvent = func;
end

--Removes a mouse event
function __ViewWindow__.RemoveMouseClickEvent(MouseID)
	MouseClickEvents[MouseID] = nil;
end

--Clears all of the mouse events
function __ViewWindow__.ClearAllMouseEvents()
	MouseClickEvents = {};
end

--Adds a function that is called when the mouse is released
function ViewWindow.AddMouseReleaseFunction(func)
	local ReleaseID = sb.makeUuid();
	MouseReleaseFunctions[ReleaseID] = func;
	return ReleaseID;
end

--Returns the Mouse Position Inside the View Window
function ViewWindow.MousePosition()
	return ViewWindowCanvas:mousePosition();
end

--Returns the View Window Position
function ViewWindow.Position()
	return ViewWindowOffset;
end

--Removes a function that is called when the mouse is released
function __ViewWindow__.RemoveMouseReleaseFunction(ReleaseID)
	MouseReleaseFunctions[ReleaseID] = nil;
end

--Adds a function that is called when the mouse hovers over a rect
--function

--Called when the mouse is clicked
function __ViewWindow__.OnMouseClick(Position,ButtonType,IsDown)
	if ButtonType == 0 then
		if IsDown == true then
			local Position = ViewWindowCanvas:mousePosition();
			local ClickedObject = false;
			for _,event in pairs(MouseClickEvents) do
				local Rect = event.Rect;
				--If the Position is inside the rect bounds
				if not (Position[1] < Rect[1] * ViewWindowScale + ViewWindowOffset[1] or Position[2] < Rect[2] * ViewWindowScale + ViewWindowOffset[2] or Position[1] > Rect[3] * ViewWindowScale + ViewWindowOffset[1] or Position[2] > Rect[4] * ViewWindowScale + ViewWindowOffset[2]) then
					event.Function();
					ClickedObject = true;
				end
			end
			if not ClickedObject and DefaultMouseClickEvent ~= nil then
				DefaultMouseClickEvent();
			end
		else
			for _,func in pairs(MouseReleaseFunctions) do
				func();
			end
		end
	end
end