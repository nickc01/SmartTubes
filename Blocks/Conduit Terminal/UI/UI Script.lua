require("/Core/ImageCore.lua");
local TitleImage = "/Blocks/Conduit Terminal/UI/Window/Title Bar.png";
local CloseImage = "/Blocks/Conduit Terminal/UI/Window/Close Button/Close Button.png";
local CloseHighlightedImage = "/Blocks/Conduit Terminal/UI/Window/Close Button/Close Button Highlighted.png";
local MainWindowColor = "/Blocks/Conduit Terminal/UI/Window/Main Window Coloring.png";
local LastDirective;
local LastColor;
local SourceID;
local Conduits;
local Clicked = false;
local MakeImageAbsolute;
local EntityPos;

local vecAdd;
local vecLerp;

local Animations = {};

local function SetupAnimationInfoForType(ConduitType,TestObject)
	--Animations[ConduitType] = {};
	Animations[ConduitType] = world.getObjectParameter(TestObject,"CustomAnimations");
	--local TypeAnimation = Animations[ConduitType];
	--local Animation = world.getObjectParameter(TestObject,"animation");
	--[[local Animation = world.getObjectParameter(TestObject,"animation");
	local Orientations = world.getObjectParameter(TestObject,"orientations");
	if Animation == "/Animations/Cable.animation" then
		--Is A Cable
		Animations[ConduitType].IsCable = true;
		Animations[ConduitType].Image = MakeImageAbsolute(ConduitType,"Main/Main.png",TestObject);
		sb.logInfo("Image = " .. sb.print(Animations[ConduitType].Image));
	else
		--Not a Cable
	end--]]
	--[[local Animation = world.getObjectParameter(TestObject,"animation");
	if Animations[ConduitType] == nil then
		Animations[ConduitType] = {};
	end
	if Animation ~= nil then
		--Is An Animation
		Animations[ConduitType].IsAnimation = true;
		local PartImages = world.getObjectParameter(TestObject,"animationParts");
		local AnimationFile = root.assetJson(Animation);
		Animations[ConduitType].GlobalTagDefaults = AnimationFile.globalTagDefaults or {};
		local PartStates = {};
		for k,i in pairs(PartImages) do
			PartStates[k] = {Types = {}};
			sb.logInfo("Animation File = " .. sb.printJson(AnimationFile,1));
			for m,n in pairs(AnimationFile.animatedParts.parts[k].partStates) do
				sb.logInfo("n = " .. sb.print(n));
				local Image = n.main.properties.image;
				Image = string.gsub(Image,"<partImage>",PartImages[k]);
				Image = string.gsub(Image,"<color>","default");
				Image = string.gsub(Image,"<frame>","1");
				for o,p in pairs(Animations[ConduitType].GlobalTagDefaults) do
					Image = string.gsub(Image,"<" .. o .. ">",p);
				end

				PartStates[k].Types[m] = MakeImageAbsolute(Image,TestObject);
			end
		end
		Animations[ConduitType].PartStates = PartStates;
	else
		--Is A Still Image
		Animations[ConduitType].IsAnimation = false;

	end--]]
end

local MainCanvas;

local function hsvToRgb(h, s, v)
	v = v or 1;
	s = s / 100;
	h = h / 360;
	local r, g, b
	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return {r * 255, g * 255, b * 255}
end

local Hue = 0.0;
local Sat = 0.0;

local UpdateColors;

local PreviousMousePos;

function init()
	SourceID = pane.sourceEntity();
	UpdateColors();
	MainCanvas = widget.bindCanvas("mainCanvas");
	Conduits = world.getObjectParameter(SourceID,"AllConduits",{});
	sb.logInfo("ALLCONDUITINITIAL = " .. sb.print(Conduits));
	for k,i in pairs(Conduits) do
		sb.logInfo("Setting Up Type = " .. sb.print(k));
		sb.logInfo("I[1] = " .. sb.print(i[1]));
		sb.logInfo("I = " .. sb.printJson(i,1));
		SetupAnimationInfoForType(k,i[1]);
	end
	--ImageCore.GetFrameOfImage("/Blocks/Conduits/Curved/5x/TR/Curve.png");
	EntityPos = world.entityPosition(SourceID);
end

local Offset = {156,84};
local MousePos;

local function RectVecSub(A,B)
	return {A[1] - B[1],A[2] - B[2],A[3] - B[1],A[4] - B[2]};
end

function update(dt)
	local NewHue = world.getObjectParameter(SourceID,"Hue",0);
	local NewSat = world.getObjectParameter(SourceID,"Saturation",0);
	if Hue ~= NewHue or Sat ~= NewSat then
		Hue = NewHue;
		Sat = NewSat;
		UpdateColors();
	end
	MainCanvas:clear();
	local Scale = 1.3;
	local LerpFactor = 7 * dt;
	if Clicked == true then
		MousePos = MainCanvas:mousePosition();
	end
	if MousePos ~= nil then
		Offset[1] = Offset[1] + ((MousePos[1] - PreviousMousePos[1]) * LerpFactor * Scale);
		Offset[2] = Offset[2] + ((MousePos[2] - PreviousMousePos[2]) * LerpFactor * Scale);
		PreviousMousePos = vecLerp(PreviousMousePos,MousePos,LerpFactor);
	end
	--[[if Offset >= 200 then
		Offset = Offset - 200;
	end--]]
	MainCanvas:drawTiledImage("/Blocks/Conduit Terminal/UI/Window/TileImage.png",{Offset[1] * 0.7,Offset[2] * 0.7},{0,0,2000,2000},0.1,LastColor);
	for k,i in pairs(Conduits) do
		--sb.logInfo("Animations = " .. sb.print(Animations));
		if Animations[k] ~= nil and Animations[k].Image ~= nil then
			--sb.logInfo("Here");
			for m,n in ipairs(i) do
				local Pos = world.entityPosition(n);
				local State = world.getObjectParameter(n,"CustomAnimationState");
				--local Rotation = Animations[k].States[State].Rect;
				--local Rotation = world.getObjectParameter(n,"CustomAnimationRotation");
				--MainCanvas:drawImage(Animations[k].Image,{((Pos[1] - EntityPos[1]) * 8) + Offset[1],((Pos[2] - EntityPos[2]) * 8) + Offset[2]});
				local X = ((Pos[1] - EntityPos[1]) * 8) + Offset[1];
				local Y = ((Pos[2] - EntityPos[2]) * 8) + Offset[2];
				local RenderCoords = {0,0,0,0};
				local TexCoords = Animations[k].States[State].Rect;
				--local RenderPos = Animations[k].States[State].Rect;
				if world.getObjectParameter(n,"CustomFlipX",false) then
					RenderCoords[1] = X + Animations[k].States[State].Size[1];
					RenderCoords[3] = X;
					--RenderPos[1] = RenderPos[1] + Animations[k].States[State].Offset[1] * 2;
					--RenderPos[3] = RenderPos[3] + Animations[k].States[State].Offset[1] * 2;
				else
					RenderCoords[1] = X;
					RenderCoords[3] = X + Animations[k].States[State].Size[1];
				end

				if world.getObjectParameter(n,"CustomFlipY",false) then
					RenderCoords[2] = Y + Animations[k].States[State].Size[2];
					RenderCoords[4] = Y;
					--RenderPos[2] = RenderPos[2] + Animations[k].States[State].Offset[2] * 2;
					--RenderPos[4] = RenderPos[4] + Animations[k].States[State].Offset[2] * 2;
				else
					RenderCoords[2] = Y;
					RenderCoords[4] = Y + Animations[k].States[State].Size[2];
				end
				RenderCoords = RectVecSub(RenderCoords,Animations[k].States[State].Offset);
				MainCanvas:drawImageRect(Animations[k].Image,TexCoords,RenderCoords);
			end
		end
	end
	--sb.logInfo("Hue = " .. sb.print(Hue));
	--sb.logInfo("Sat = " .. sb.print(Sat));
	--PreviousMousePos = MousePos;
end

UpdateColors = function()
	local Directives = "?hueshift=" .. Hue .. "?saturation=" .. Sat;
	widget.setImage("MainTitle",TitleImage .. Directives);
	widget.setImage("MainWindowColor",MainWindowColor .. Directives);
	widget.setButtonImages("close",{
		base = CloseImage .. Directives,
		hover = CloseHighlightedImage .. Directives,
		pressed = CloseHighlightedImage .. Directives
	});
	--[[for k,i in pairs(Conduits) do
		for m,n in ipairs(i) do
			
		end
	end--]]
	LastDirective = Directives;
	LastColor = hsvToRgb(Hue,100 + Sat,1);
end

function CanvasClick(Position,ButtonType,IsDown)
	--sb.logInfo("ButtonType = " .. sb.print(ButtonType));
	if ButtonType == 0 then
		if IsDown == true then
			PreviousMousePos = MainCanvas:mousePosition();
			Clicked = true;
		else
			Clicked = false;
		end
	end
end

vecAdd = function(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

vecLerp = function(A,B,T)
	return {((B[1] - A[1]) * T) + A[1],((B[2] - A[2]) * T) + A[2]};
end

local OutputImages = setmetatable({}, { __mode = 'v' });

MakeImageAbsolute = function(ConduitType,Image,ObjectSource)
	if OutputImages[ConduitType] ~= nil then
		return OutputImages[ConduitType];
	end
	if string.find(Image,"^/") ~= nil then
		OutputImages[ConduitType] = Image;
		return Image;
	else
		sb.logInfo("Object Name = " .. sb.print(world.entityName(ObjectSource)));
		local Directory = root.itemConfig({name = world.entityName(ObjectSource),count = 1}).directory;
		if string.find(Directory,"/$") == nil then
			Directory = Directory .. "/";
		end
		local FinalImage = Directory .. Image;
		OutputImages[ConduitType] = FinalImage;
		return FinalImage;
	end
end

function die()
	
end

function uninit()
		
end
