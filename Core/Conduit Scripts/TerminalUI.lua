require("/Core/UICore.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");

--Declaration

--Public Table
TerminalUI = {};
local TerminalUI = TerminalUI;

--Canvas Tables
ViewWindow = {};

--Variables
local PlayerID;
local SourceID;
local SourcePosition;
local Data = {};
local TestTimer = 0;

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

--Initializes the Terminal UI
function TerminalUI.Initialize()
	PlayerID = player.id();
	SourceID = pane.sourceEntity();
	sb.logInfo("SourceID UI = " .. sb.print(SourceID));
	SourcePosition = world.entityPosition(SourceID);
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("ConduitNetwork",SourceID,"Network",{});
	Data.AddNetworkChangeFunction(NetworkChange);
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
	for _,Conduit in ipairs(Data.GetNetwork()) do
		ViewWindow.RenderConduit(Conduit);
	end
end

--Called when the conduit network changes
NetworkChange = function()
	ConduitRenderCache = {};
	ConduitRenderFunctions = {};
end

--Renders the main background to the main viewing canvas
RenderMainBackground = function()
	--sb.logInfo("Draw");
	ViewWindowCanvas:drawTiledImage("/Blocks/Conduit Terminal/UI/Window/TileImage.png",{ViewWindowOffset[1] * 0.7,ViewWindowOffset[2] * 0.7},{0,0,2000,2000},0.1);
end


--Renders an image to the View Window
function ViewWindow.RenderImage(Image,Position,Scale,Color)
	Scale = Scale or 1;
	--sb.logInfo("Draw 3");
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
	TextureRect = RectCore.Flip(TextureRect,FlipHorizontal,FlipVertical,true);
	ScreenRect = RectCore.BaseMultiply(ScreenRect,8);
	--ScreenRect = RectCore.VectorAdd(ScreenRect,ViewWindowOffset);
	return function()
		--sb.logInfo("Draw 1");
		ViewWindowCanvas:drawImageRect(Texture,TextureRect,{ScreenRect[1] + ViewWindowOffset[1],ScreenRect[2] + ViewWindowOffset[2],ScreenRect[3] + ViewWindowOffset[1],ScreenRect[4] + ViewWindowOffset[2]},Color);
		return 0;
	end
end

--Renders an object to the View Window
function ViewWindow.RenderObject(Object,ScreenPosition,Color)
	--[[if ConduitRenderShortcuts[Object] ~= nil then
		ConduitRenderShortcuts[Object]();
		return nil;
	end--]]
	local RenderParams = ImageCore.ObjectToImage(Object);
	if RenderParams == nil then return 1 end;
	local Position = ScreenPosition or VectorCore.Subtract(world.entityPosition(Object),SourcePosition);
	--sb.logInfo("RenderParams = " .. sb.print(RenderParams));
	--local Funcs = {};
	for _,image in ipairs(RenderParams.Images) do
		--sb.logInfo("Offset = " .. sb.print(RenderParams.Offset));
		local ScreenRect = {Position[1] + (RenderParams.Offset[1] / 8),Position[2] + (RenderParams.Offset[2] / 8),Position[1] + (RenderParams.Offset[1] / 8) + image.Width,Position[2] + (RenderParams.Offset[2] / 8) + image.Height};
		ViewWindow.RenderImageRect(image.Image,image.TextureRect,ScreenRect,Color,RenderParams.Flip);
		--Funcs[#Funcs + 1] = ViewWindow.RenderRectFunction(image.Image,image.TextureRect,ScreenRect,Color,RenderParams.Flip);
	end
	--[[ConduitRenderShortcuts[Object] = function()
		for i=1,#Funcs do
			Funcs[i]();
		end
	end--]]
	return 0;
end

--Renders an animated object to the View Window
function ViewWindow.RenderConduit(object,ScreenPosition)
	--{FlipX = FlipX,FlipY = FlipY,AnimationName = AnimationName,AnimationState = AnimationState};
	--[[if ConduitRenderShortcuts[object] ~= nil then
		return ConduitRenderShortcuts[object]();
	end--]]
	--If there is a quicker render function defined, then use it
	if ConduitRenderFunctions[object] ~= nil then
		ConduitRenderFunctions[object]();
	end
	if object == nil or not world.entityExists(object) then
		return 5;
	end
	local ObjectData;
	local Done;
	if ConduitRenderCache[object] ~= nil then
		ObjectData,Done = ConduitRenderCache[object]();
	else
		ConduitRenderCache[object] = UICore.AsyncFunctionCall(object,"ConduitCore.GetTerminalImageParameters",{FlipX = false,FlipY = false,AnimationName = nil,AnimationState = nil});
		ObjectData,Done = ConduitRenderCache[object]();
	end
	--If there's object data, then the conduit can be rendered
	if ObjectData ~= nil then
		--If theres animation data that can be used, then utilize it, otherwise, just return a code 3
		if ObjectData.AnimationName ~= nil then
			--sb.logInfo("Object Data = " .. sb.print(ObjectData));
			local Animation = ImageCore.ParseObjectAnimation(object);
			--sb.logInfo("Animation = " .. sb.print(Animation));
			local CurrentLayer = Animation.Layers[ObjectData.AnimationName];
			local CurrentState = CurrentLayer.States[ObjectData.AnimationState];
			if CurrentState == nil then CurrentState = CurrentLayer.States[CurrentLayer.DefaultState] end;
			--local Image,Frame = CurrentState.Image,CurrentState.Layer;
			local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
			local ObjectImageData = ImageCore.ObjectToImage(object);
			--sb.logInfo("Image Params = " .. sb.print(ImageParams));
			local Position = ScreenPosition or VectorCore.Subtract(world.entityPosition(object),SourcePosition);
			local ScreenRect = {Position[1] + (ObjectImageData.Offset[1] / 8),Position[2] + (ObjectImageData.Offset[2] / 8),Position[1] + ImageParams.Width + (ObjectImageData.Offset[1] / 8),Position[2] + ImageParams.Height +(ObjectImageData.Offset[2] / 8)};
			ViewWindow.RenderImageRect(ImageParams.Image,ImageParams.TextureRect,ScreenRect,nil,ObjectData.FlipX,ObjectData.FlipY);
			--If we got all the render data we need from the object, then create a render function that can be used to render much faster
			if Done == true then
				local RenderFunction = ViewWindow.RenderRectFunction(ImageParams.Image,ImageParams.TextureRect,ScreenRect,nil,ObjectData.FlipX,ObjectData.FlipY);
				local StoredPosition = Position;
				ConduitRenderFunctions[object] = function(newPosition)
					--Update the position if it is changed
					if newPosition ~= nil and (newPosition[1] ~= StoredPosition[1] or newPosition[2] ~= StoredPosition[2]) then
						StoredPosition = newPosition;
						ScreenRect = {StoredPosition[1] + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + (ObjectImageData.Offset[2] / 8),StoredPosition[1] + ImageParams.Width + (ObjectImageData.Offset[1] / 8),StoredPosition[2] + ImageParams.Height +(ObjectImageData.Offset[2] / 8)};
						RenderFunction = ViewWindow.RenderRectFunction(ImageParams.Image,ImageParams.TextureRect,ScreenRect,Color,ObjectData.FlipX,ObjectData.FlipY);
					end
					RenderFunction();
					return 0;
				end
			end
			return 0;
		else
			return 3;
		end
		
		--TODO -- TODO -- TODO
		
	end
	return 2;
end