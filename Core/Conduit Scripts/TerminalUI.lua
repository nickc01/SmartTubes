require("/Core/UICore.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");

--Declaration

--Public Table
TerminalUI = {};
local TerminalUI = TerminalUI;

--View Window
ViewWindow = {};
local ViewWindow = ViewWindow;

--Private Table
local VWPrivate = {};

--Variables
local Data = {};
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
local AddedConduits = {};
local AddedTextures = {};
local AddedObjects = {};
local SelectedConduit;

--Functions
local Update;
local BuildObjectData;
local NetworkChange;
local BuildController;

--Initializes the Terminal UI
function TerminalUI.Initialize()
	PlayerID = player.id();
	SourceID = pane.sourceEntity();
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
	VWPrivate.Canvas = widget.bindCanvas("mainCanvas");
	VWPrivate.Size = VWPrivate.Canvas:size();
	VWPrivate.Position = {VWPrivate.Size[1] / 2,VWPrivate.Size[2] / 2};
	VWPrivate.Scale = 1;
end

--The Update Loop for the Terminal UI
Update = function(dt)
	VWPrivate.Canvas:clear();
	--Display Background
	--VWPrivate.Position[1] = VWPrivate.Position[1] + dt;
	--VWPrivate.Scale = VWPrivate.Scale + dt;
	VWPrivate.Canvas:drawTiledImage("/Blocks/Conduit Terminal/UI/Window/TileImage.png",{VWPrivate.Position[1] * 0.7,VWPrivate.Position[2] * 0.7},{0,0,2000,2000},0.1);
	local Position = VWPrivate.Canvas:mousePosition();
	--Render Textures
	for _,textureData in pairs(AddedTextures) do
		sb.logInfo("Rendering Texture");
		sb.logInfo("ScreenRect of Texture = " .. sb.print(textureData.ScreenRect));
		VWPrivate.Render(textureData.Texture,textureData.TextureRect,textureData.ScreenRect,textureData.Color);
	end
	for _,data in pairs(AddedConduits) do
		VWPrivate.RenderConduit(data);
		--Check for mouse hover
		if data.OnHover ~= nil and data.CollisionRect ~= nil then
			local Rect = data.CollisionRect;
			if data.Hovering == true then
				if (Position[1] < Rect[1] * VWPrivate.Scale + VWPrivate.Position[1] or Position[2] < Rect[2] * VWPrivate.Scale + VWPrivate.Position[2] or Position[1] > Rect[3] * VWPrivate.Scale + VWPrivate.Position[1] or Position[2] > Rect[4] * VWPrivate.Scale + VWPrivate.Position[2]) then
					data.Hovering = false;
					data.OnHover(false);
				end
			else
				if not (Position[1] < Rect[1] * VWPrivate.Scale + VWPrivate.Position[1] or Position[2] < Rect[2] * VWPrivate.Scale + VWPrivate.Position[2] or Position[1] > Rect[3] * VWPrivate.Scale + VWPrivate.Position[1] or Position[2] > Rect[4] * VWPrivate.Scale + VWPrivate.Position[2]) then
					data.Hovering = true;
					data.OnHover(true);
				end
			end
		end
	end
	for _,data in pairs(AddedObjects) do
		for index,texture in ipairs(data.Textures) do
			VWPrivate.Render(texture.Image,texture.TextureRect,data.ScreenRects[index],data.Color);
		end
	end
end

--Adds an object to be rendered
function ViewWindow.AddObject(object,position,color,OnClick,OnHover,Enabled,Scale)
	if Scale ~= nil then
		Scale = Scale - 1;
	else
		Scale = 1;
	end
	if Enabled == nil then
		Enabled = true;
	end
	local ObjectToImageData = ImageCore.ObjectToImage(object);
	local ObjectTable = {};
	ObjectTable.Textures = ObjectToImageData.Images;
	ObjectTable.Scale = Scale;
	ObjectTable.Position = position or world.entityPosition(object);
	ObjectTable.Position = VectorCore.Subtract(ObjectTable.Position,SourcePosition);
	local CollisionRegion = {};
	local Size = {};
	for _,image in ipairs(ObjectToImageData.Images) do
		local Rect = root.nonEmptyRegion(image.Image);
		if CollisionRegion[1] == nil or Rect[1] < CollisionRegion[1] then
			CollisionRegion[1] = Rect[1];
		end
		if CollisionRegion[2] == nil or Rect[2] < CollisionRegion[2] then
			CollisionRegion[2] = Rect[2];
		end
		if CollisionRegion[3] == nil or Rect[3] > CollisionRegion[3] then
			CollisionRegion[3] = Rect[3];
		end
		if CollisionRegion[4] == nil or Rect[4] > CollisionRegion[4] then
			CollisionRegion[4] = Rect[4];
		end
		if Size[1] == nil or image.Width > Size[1] then
			Size[1] = image.Width;
		end
		if Size[2] == nil or image.height > Size[2] then
			Size[2] = image.Height;
		end
	end
	ObjectTable.PositionalOffset = ObjectToImageData.Offset;
	ObjectTable.Color = color;
	local ScreenRects = {};
	for _,image in ipairs(ObjectToImageData.Images) do
		ScreenRects[#ScreenRects + 1] = {(ObjectTable.Position[1] + ObjectTable.PositionalOffset[1] / 8) * 8 - ((ObjectTable.Scale) / 2) * (image.Width / 8),(ObjectTable.Position[2] + ObjectTable.PositionalOffset[2] / 8) * 8 - ((ObjectTable.Scale) / 2) * (image.Height / 8),(ObjectTable.Position[1] + image.Width / 8 + ObjectTable.PositionalOffset[1] / 8) * 8 + ((ObjectTable.Scale) / 2) * (image.Width / 8),(ObjectTable.Position[2] + image.Height / 8 + ObjectTable.PositionalOffset[2] / 8) * 8 + ((ObjectTable.Scale) / 2) * (image.Height / 8)};
	end
	sb.logInfo("ScreenRects = " .. sb.print(ScreenRects));
	ObjectTable.ScreenRects = ScreenRects;
	ObjectTable.OnClick = OnClick;
	ObjectTable.OnHover = OnHover;
	ObjectTable.CollisionRect = {(ObjectTable.Position[1] + CollisionRegion[1] / 8 + ObjectTable.PositionalOffset[1] / 8) * 8 - ((ObjectTable.Scale) / 2) * (Size[1] / 8),(ObjectTable.Position[2] + CollisionRegion[2] / 8 + ObjectTable.PositionalOffset[2] / 8) * 8 - ((ObjectTable.Scale) / 2) * (Size[2] / 8),(ObjectTable.Position[1] + CollisionRegion[3] / 8 + ObjectTable.PositionalOffset[1] / 8) * 8 + ((ObjectTable.Scale) / 2) * (Size[1] / 8),(ObjectTable.Position[2] + CollisionRegion[4] / 8 + ObjectTable.PositionalOffset[2] / 8) * 8 + ((ObjectTable.Scale) / 2) * (Size[2] / 8)};
	local ObjectUUID = sb.makeUuid();
	AddedObjects[ObjectUUID] = ObjectTable;
	local Controller = {};
	Controller.GetObjectUUID = function()
		return ObjectUUID;
	end
	return Controller;
	--[[local ObjectToImageData = ImageCore.ObjectToImage(object);
	local ObjectTable = {};
	ObjectTable.OriginalTexture = object.Image;
	ObjectTable.Texture = ImageParams.Image;
	ObjectTable.OriginalTextureRect = ImageParams.TextureRect;
	ObjectTable.TextureRect = RectCore.Flip(ImageParams.TextureRect,TerminalData.FlipX,TerminalData.FlipY,true);
	ObjectTable.PositionalOffset = ObjectToImageData.Offset;
	ObjectTable.TextureWidth = ImageParams.Width;
	ObjectTable.TextureHeight = ImageParams.Height;
	ObjectTable.ScreenRect = {(position[1] + ObjectToImageData.Offset[1] / 8) * 8,(position[2] + ObjectToImageData.Offset[2] / 8) * 8,(position[1] + ImageParams.Width + ObjectToImageData.Offset[1] / 8) * 8,(position[2] + ImageParams.Height + ObjectToImageData.Offset[2] / 8) * 8};
	local CollisionRegion = root.nonEmptyRegion(ObjectTable.OriginalTexture);
	ObjectTable.CollisionRect = {(ObjectTable.Position[1] + CollisionRegion[1] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[2] / 8 + ObjectToImageData.Offset[2] / 8) * 8,(ObjectTable.Position[1] + CollisionRegion[3] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[4] / 8 + ObjectToImageData.Offset[2] / 8) * 8};--]]
end

--Called when the network has changed
NetworkChange = function()
	ViewWindow.ClearAllObjects();
	local Network = Data.GetNetwork();
	sb.logInfo("NETWORK UI HAS UPDATED");
	for _,conduit in ipairs(Network) do
		local Controller;
		local StoredTexture; 
		local OnHover = function(hovering)
			if hovering == true then
				local Texture = Controller.GetTexture();
				--sb.logInfo("Old Texture = " .. sb.print(Texture));
				if string.find(Texture,":") ~= nil then
					Texture = string.gsub(Texture,":","?setcolor=19db00:");
				else
					Texture = Texture .. "?setcolor=19db00";
				end
				--sb.logInfo("New Texture = " .. sb.print(Texture));
				local Position = Controller.GetPosition();
				local PositionalOffset = Controller.GetPositionalOffset();
				--sb.logInfo("Conduit Position = " .. sb.print(Position));
				StoredTexture = ViewWindow.AddTexture(Texture,{Position[1] + SourcePosition[1] + PositionalOffset[1] / 8,Position[2] + SourcePosition[2] + PositionalOffset[2] / 8},Controller.GetFlipX(),Controller.GetFlipY(),3);
				--sb.logInfo("Adding Texture");
			else
				--Controller.SetTexture(StoredTexture);
				--Controller.SetScale(1);
				--StoredTexture = nil;
				ViewWindow.RemoveTexture(StoredTexture.GetTextureID());
				StoredTexture = nil;
			end
		end
		Controller = ViewWindow.AddConduit(conduit,nil,nil,nil,OnHover);
	end
end

--Adds a conduit to be rendered
--[[
ObjectData = {
	ID,
	Position,
	PositionalOffset,
	Texture,
	TextureRect,
	OriginalTextureRect,
	TextureWidth,
	TextureHeight,
	ScreenRect,
	FlipX,
	FlipY,
	Color,
	Enabled
	--If not done then the below exists
	TerminalParameters
}
]]
function ViewWindow.AddConduit(object,position,color,OnClick,OnHover,Enabled)
	if Enabled == nil then
		Enabled = true;
	end
	local ObjectTable = {};
	ObjectTable.Position = position or world.entityPosition(object);
	ObjectTable.Position = VectorCore.Subtract(ObjectTable.Position,SourcePosition);
	ObjectTable.TerminalParameters = UICore.AsyncFunctionCall(object,"ConduitCore.GetTerminalImageParameters",ConduitPreviousData[object] or {FlipX = false,FlipY = false,AnimationName = nil,AnimationState = nil});
	local TerminalData,Done = ObjectTable.TerminalParameters();
	if TerminalData ~= nil then
		if TerminalData.AnimationName ~= nil then
			--sb.logInfo("Terminal Data = " .. sb.print(TerminalData));
			local Animation = ImageCore.ParseObjectAnimation(object);
			local CurrentLayer = Animation.Layers[TerminalData.AnimationName];
			local CurrentState = CurrentLayer.States[TerminalData.AnimationState];
			if CurrentState == nil then CurrentState = CurrentLayer.States[CurrentLayer.DefaultState] end;
			local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
			local ObjectToImageData = ImageCore.ObjectToImage(object);
			--ObjectData.ObjectToImageData = ObjectToImageData;
			ObjectTable.OriginalTexture = CurrentState.Image;
			ObjectTable.Texture = ImageParams.Image;
			ObjectTable.OriginalTextureRect = ImageParams.TextureRect;
			ObjectTable.TextureRect = RectCore.Flip(ImageParams.TextureRect,TerminalData.FlipX,TerminalData.FlipY,true);
			ObjectTable.PositionalOffset = ObjectToImageData.Offset;
			ObjectTable.TextureWidth = ImageParams.Width;
			ObjectTable.TextureHeight = ImageParams.Height;
			ObjectTable.ScreenRect = {(ObjectTable.Position[1] + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + ObjectToImageData.Offset[2] / 8) * 8,(ObjectTable.Position[1] + ImageParams.Width / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + ImageParams.Height / 8 + ObjectToImageData.Offset[2] / 8) * 8};
			local CollisionRegion = root.nonEmptyRegion(ObjectTable.OriginalTexture);
			ObjectTable.CollisionRect = {(ObjectTable.Position[1] + CollisionRegion[1] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[2] / 8 + ObjectToImageData.Offset[2] / 8) * 8,(ObjectTable.Position[1] + CollisionRegion[3] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[4] / 8 + ObjectToImageData.Offset[2] / 8) * 8};
		else
			ObjectTable.TempObject = ViewWindow.AddObject(object,position,color,OnClick,OnHover,Enabled,1);
			--return ViewWindow.AddObject(object,position,color,OnClick,OnHover,Enabled,1);
			--return 3;
		end
		ObjectTable.FlipX = TerminalData.FlipX;
		ObjectTable.FlipY = TerminalData.FlipY;
		sb.logInfo("FlipX 1 = " .. sb.print(TerminalData.FlipX));
		sb.logInfo("FlipY 1 = " .. sb.print(TerminalData.FlipY));
		ObjectTable.Color = color;
		ObjectTable.Enabled = Enabled;
		ObjectTable.OnClick = OnClick;
		ObjectTable.OnHover = OnHover;
		ObjectTable.ID = object;
		ObjectTable.Scale = 0;

		local ObjectID = sb.makeUuid();
		AddedConduits[ObjectID] = ObjectTable;
		ObjectTable.UUID = ObjectID;
		return BuildController(ObjectTable,ObjectID);
	else
		return ViewWindow.AddObject(object,position,color,OnClick,OnHover,Enabled,1);
	end
	--local Animation = ImageCore.ParseObjectAnimation(object);
	--local CurrentLayer = Animation.Layers[TerminalData.AnimationName];
	--local CurrentState = CurrentLayer.States[TerminalData.AnimationState] or CurrentLayer.States[CurrentLayer.DefaultState];
	--if CurrentState == nil then CurrentState = CurrentLayer.States[CurrentLayer.DefaultState] end;
	--local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);


	--local Texture;
	--local TextureRect;
	--local 
end

--Clears the View Window of all objects
function ViewWindow.ClearAllObjects()
	AddedConduits = {};
	AddedObjects = {};
	AddedTextures = {};
	SelectedConduit = nil;
end

--Adds a raw texture to the render queue
function ViewWindow.AddTexture(texture,Position,FlipX,FlipY,Scale)
	local Data = {};
	if Scale == nil then
		Scale = 0;
	else
		Scale = Scale - 1;
	end
	local Position = VectorCore.Subtract(Position,SourcePosition);
	sb.logInfo("Texture Position = " .. sb.print(Position));
	local ImageData = ImageCore.MakeImageCanvasRenderable(texture);
	Data.OriginalTexture = texture;
	Data.Texture = ImageData.Image;
	Data.OriginalTextureRect = ImageData.TextureRect;
	Data.FlipX = FlipX;
	Data.FlipY = FlipY;
	Data.TextureRect = RectCore.Flip(ImageData.TextureRect,FlipX,FlipY,true);
	Data.ScreenRect = {Position[1] * 8 - (Scale / 2) * (ImageData.Width / 8),Position[2] * 8 - (Scale / 2) * (ImageData.Height / 8),(Position[1] + ImageData.Width / 8) * 8 + (Scale / 2) * (ImageData.Width / 8),(Position[2] + ImageData.Height / 8) * 8 + (Scale / 2) * (ImageData.Height / 8)};
	--Data.ScreenRect = {Position[1] * 8,Position[2] * 8,(Position[1] + ImageData.Width / 8) * 8,(Position[2] + ImageData.Height / 8) * 8};
	local TextureID = sb.makeUuid();
	AddedTextures[TextureID] = Data;
	local Controller = {};
	--Returns the texture id of the texture
	Controller.GetTextureID = function()
		return TextureID;
	end
	return Controller;
end

--Removes a raw texture from the render queue
function ViewWindow.RemoveTexture(textureID)
	AddedTextures[textureID] = nil;
end

--Removes a conduit from the render queue
function ViewWindow.RemoveConduit(ObjectID)
	AddedConduits[ObjectID] = nil;
end

--Removes an object from the render queue
function ViewWindow.RemoveObject(ObjectUUID)
	AddedObjects[ObjectUUID] = nil;
end

--[[BuildObjectData = function(ImageParams,ObjectToImageData)
	
end--]]

--Makes a controller that allows you to modify the data safely
BuildController = function(data,objectID)
	local Controller = {};
	--Changes the position of the object
	Controller.SetPosition = function(position)
		if position ~= nil and (data.Position[1] ~= position[1] or data.Position[2] ~= position[2]) then
			data.Position = position;
			data.ScreenRect = {(data.Position[1] + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + data.PositionalOffset[2] / 8) * 8,(data.Position[1] + data.TextureWidth / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + data.TextureHeight / 8 + data.PositionalOffset[2] / 8) * 8};
			local CollisionRegion = root.nonEmptyRegion(data.OriginalTexture);
			data.CollisionRect = {(data.Position[1] + CollisionRegion[1] / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + CollisionRegion[2] / 8 + data.PositionalOffset[2] / 8) * 8,(data.Position[1] + CollisionRegion[3] / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + CollisionRegion[4] / 8 + data.PositionalOffset[2] / 8) * 8};
		end
	end
	--Returns the position
	Controller.GetPosition = function()
		return data.Position;
	end
	--Sets the objects Texture
	Controller.SetTexture = function(texture,flipx,flipy)
		sb.logInfo("_flipx = " .. sb.print(flipx));
		sb.logInfo("_flipy = " .. sb.print(flipy));
		if texture ~= nil then
			local ImageData = ImageCore.MakeImageCanvasRenderable(texture);
			if flipx ~= nil then
				data.FlipX = flipx;
			end
			if flipy ~= nil then
				data.FlipY = flipy;
			end
			sb.logInfo("Image Data = " .. sb.print(ImageData));
			sb.logInfo("FlipX 3 = " .. sb.print(data.FlipX));
			sb.logInfo("FlipY 3 = " .. sb.print(data.FlipY));
			data.OriginalTexture = texture;
			data.Texture = ImageData.Image;
			data.OriginalTextureRect = ImageData.TextureRect;
			data.TextureRect = RectCore.Flip(data.OriginalTextureRect,data.FlipX,data.FlipY,true);
			data.TextureWidth = ImageData.Width;
			data.TextureHeight = ImageData.Height;
			data.Scale = 0;
			data.ScreenRect = {(data.Position[1] + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + data.PositionalOffset[2] / 8) * 8,(data.Position[1] + data.TextureWidth / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + data.TextureHeight / 8 + data.PositionalOffset[2] / 8) * 8};
			local CollisionRegion = root.nonEmptyRegion(data.OriginalTexture);
			data.CollisionRect = {(data.Position[1] + CollisionRegion[1] / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + CollisionRegion[2] / 8 + data.PositionalOffset[2] / 8) * 8,(data.Position[1] + CollisionRegion[3] / 8 + data.PositionalOffset[1] / 8) * 8,(data.Position[2] + CollisionRegion[4] / 8 + data.PositionalOffset[2] / 8) * 8};
		end
	end
	--returns the objects texture
	Controller.GetTexture = function()
		return data.OriginalTexture;
	end
	--returns the texture that is used in rendering
	Controller.GetRenderTexture = function()
		return data.Texture;
	end
	--Returns the texture Width
	Controller.GetTextureWidth = function()
		return data.TextureWidth;
	end
	--Returns the texture Height
	Controller.GetTextureHeight = function()
		return data.TextureHeight;
	end
	--Returns the Collision Rect
	Controller.GetCollisionRect = function()
		return data.CollisionRect;
	end
	--Gets the objects Scale
	Controller.GetScale = function()
		return data.Scale + 1;
	end
	--Returns the FlipX
	Controller.GetFlipX = function()
		return data.FlipX;
	end
	--Returns the FlipY
	Controller.GetFlipY = function()
		return data.FlipY;
	end
	--Returns the Object ID
	Controller.GetObjectID = function()
		return ObjectID;
	end
	--Returns the positional offset
	Controller.GetPositionalOffset = function()
		return data.PositionalOffset;
	end
	--Sets the objects Scale
	Controller.SetScale = function(scale)
		if scale - 1 ~= data.Scale then
			data.Scale = scale - 1;
			data.ScreenRect = {(data.Position[1] + data.PositionalOffset[1] / 8) * 8 - ((data.Scale) / 2) * (data.TextureWidth / 8),(data.Position[2] + data.PositionalOffset[2] / 8) * 8 - ((data.Scale) / 2) * (data.TextureHeight / 8),(data.Position[1] + data.TextureWidth / 8 + data.PositionalOffset[1] / 8) * 8 + ((data.Scale) / 2) * (data.TextureWidth / 8),(data.Position[2] + data.TextureHeight / 8 + data.PositionalOffset[2] / 8) * 8 + ((data.Scale) / 2) * (data.TextureHeight / 8)};
			local CollisionRegion = root.nonEmptyRegion(data.OriginalTexture);
			data.CollisionRect = {(data.Position[1] + CollisionRegion[1] / 8 + data.PositionalOffset[1] / 8) * 8 - ((data.Scale) / 2) * (data.TextureWidth / 8),(data.Position[2] + CollisionRegion[2] / 8 + data.PositionalOffset[2] / 8) * 8 - ((data.Scale) / 2) * (data.TextureHeight / 8),(data.Position[1] + CollisionRegion[3] / 8 + data.PositionalOffset[1] / 8) * 8 + ((data.Scale) / 2) * (data.TextureWidth / 8),(data.Position[2] + CollisionRegion[4] / 8 + data.PositionalOffset[2] / 8) * 8 + ((data.Scale) / 2) * (data.TextureHeight / 8)};
		end
		--TODO -- TODO -- TODO
	end
	return Controller;
end

--Renders the conduit
function VWPrivate.RenderConduit(ObjectTable)
	--sb.logInfo("Object Table = " .. sb.print(ObjectTable));
	if ObjectTable.TerminalParameters ~= nil then
		local TerminalData,Done = ObjectTable.TerminalParameters();
		if Done == true then
			if TerminalData.AnimationName ~= nil then
				local Animation = ImageCore.ParseObjectAnimation(ObjectTable.ID);
				local CurrentLayer = Animation.Layers[TerminalData.AnimationName];
				local CurrentState = CurrentLayer.States[TerminalData.AnimationState];
				if CurrentState == nil then CurrentState = CurrentLayer.States[CurrentLayer.DefaultState] end;
				local ImageParams = ImageCore.MakeImageCanvasRenderable(CurrentState.Image);
				local ObjectToImageData = ImageCore.ObjectToImage(ObjectTable.ID);

				ObjectTable.OriginalTexture = CurrentState.Image;
				ObjectTable.FlipX = TerminalData.FlipX;
				ObjectTable.FlipY = TerminalData.FlipY;
				sb.logInfo("FlipX 2 = " .. sb.print(TerminalData.FlipX));
				sb.logInfo("FlipY 2 = " .. sb.print(TerminalData.FlipY));
				ObjectTable.Texture = ImageParams.Image;
				ObjectTable.OriginalTextureRect = ImageParams.TextureRect;
				ObjectTable.TextureRect = RectCore.Flip(ImageParams.TextureRect,TerminalData.FlipX,TerminalData.FlipY,true);
				ObjectTable.PositionalOffset = ObjectToImageData.Offset;
				ObjectTable.TextureWidth = ImageParams.Width;
				ObjectTable.TextureHeight = ImageParams.Height;
				ObjectTable.ScreenRect = {(ObjectTable.Position[1] + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + ObjectToImageData.Offset[2] / 8) * 8,(ObjectTable.Position[1] + ImageParams.Width / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + ImageParams.Height / 8 + ObjectToImageData.Offset[2] / 8) * 8};
				local CollisionRegion = root.nonEmptyRegion(CurrentState.Image);
				ObjectTable.CollisionRect = {(ObjectTable.Position[1] + CollisionRegion[1] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[2] / 8 + ObjectToImageData.Offset[2] / 8) * 8,(ObjectTable.Position[1] + CollisionRegion[3] / 8 + ObjectToImageData.Offset[1] / 8) * 8,(ObjectTable.Position[2] + CollisionRegion[4] / 8 + ObjectToImageData.Offset[2] / 8) * 8};
				ConduitPreviousData[ObjectTable.ID] = TerminalData;
				ObjectTable.TerminalParameters = nil;
				ObjectTable.Scale = 0;
				if ObjectTable.TempObject ~= nil then
					ViewWindow.RemoveObject(ObjectTable.TempObject.GetObjectUUID());
					ObjectTable.TempObject = nil;
				end
			else
				ViewWindow.RemoveConduit(ObjectTable.UUID);
				if ObjectTable.TempObject == nil then
					return ViewWindow.AddObject(ObjectTable.ID);
				end
			end
		--else
			--return 3;
		end
	end
	if ObjectTable.Enabled == true and ObjectTable.Texture ~= nil then
		sb.logInfo("ScreenRect of conduit = " .. sb.print(ObjectTable.ScreenRect));
		VWPrivate.Render(ObjectTable.Texture,ObjectTable.TextureRect,ObjectTable.ScreenRect,ObjectTable.Color);
	end
end

--Renders to the View Window
function VWPrivate.Render(Texture,TextureRect,ScreenRect,Color)
	--sb.logInfo("COLOR = " .. sb.print(Color));
	VWPrivate.Canvas:drawImageRect(Texture,TextureRect,{(ScreenRect[1] * VWPrivate.Scale) + VWPrivate.Position[1],(ScreenRect[2] * VWPrivate.Scale) + VWPrivate.Position[2],(ScreenRect[3] * VWPrivate.Scale) + VWPrivate.Position[1],(ScreenRect[4] * VWPrivate.Scale) + VWPrivate.Position[2]},Color);
end

--Generates a Collision Rect around something
function VWPrivate.GenerateCollisionRect(Position,TextureCollisionRect,ObjectPositionOffset,ImageSizeX,ImageSizeY,Scale)
	-- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO 
end
