require("/Core/ImageCore.lua");
require("/Core/Debug.lua");
local TitleImage = "/Blocks/Conduit Terminal/UI/Window/Title Bar.png";
local CloseImage = "/Blocks/Conduit Terminal/UI/Window/Close Button/Close Button.png";
local CloseHighlightedImage = "/Blocks/Conduit Terminal/UI/Window/Close Button/Close Button Highlighted.png";
local MainWindowColor = "/Blocks/Conduit Terminal/UI/Window/Main Window Coloring.png";
local ConduitTerminalImage = "/Blocks/Conduit Terminal/Terminal.png";
local LitConduitTerminalImage = "/Blocks/Conduit Terminal/TerminalWhite.png";
local LastDirective;
local LastColor;
local SourceID;
local Conduits;
local Clicked = false;
local MakeImageAbsolute;
local SourcePos;
local UIUpdateMessage;

local vecAdd;
local vecLerp;
local UpdateNetwork;
local Initialized = false;
local UIColor = nil;

--local Red,Green,Blue;

local Animations = {};

local function SetSourceValue(Name,Value)
	world.sendEntityMessage(SourceID,"SetValue",Name,Value);
end

local function CallMessageAsync(Object,FuncName,AltFunction,...)
	local Func;
	local Promise = world.sendEntityMessage(Object,FuncName,...);
	local Result = nil;
	local GotResult = false;
	Func = function()
		if GotResult == true then
			return Result;
		end
		if Promise:finished() == true then
			Result = Promise:result();
			GotResult = true;
			return Result;
		else
			if AltFunction ~= nil then
				return AltFunction();
			end
			return nil;
		end
	end
	return Func;
end

local function SetupAnimationInfoForType(ConduitType,TestObject)
	--DPrint("Result for " .. sb.print(ConduitType) .. " = " .. sb.print(world.getObjectParameter(TestObject,"CustomAnimations")));
	Animations[ConduitType] = world.getObjectParameter(TestObject,"CustomAnimations");
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

local function rgbToHsv(r, g, b, a)
  r, g, b, a = r / 255, g / 255, b / 255, a / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then s = 0 else s = d / max end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
    h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h * 360, s * 100, v, a
end

local Hue = 0.0;
local Sat = 0.0;

local UpdateColors;

local PreviousMousePos;

function init()
	SourceID = pane.sourceEntity();
	Hue = world.getObjectParameter(SourceID,"Hue",0);
	Sat = world.getObjectParameter(SourceID,"Saturation",0);
	UpdateColors();
	widget.setSliderValue("hueSlider",Hue);
	widget.setSliderValue("satSlider",Sat);
	MainCanvas = widget.bindCanvas("mainCanvas");
	--ImageCore.GetFrameOfImage("/Blocks/Conduits/Curved/5x/TR/Curve.png");
	SourcePos = world.entityPosition(SourceID);
	UpdateNetwork();
	Initialized = true;
	--UIUpdateMessage = world.sendEntityMessage(SourceID,"UINeedsUpdate",true);
end

local Offset = {156,84};
local MousePos;

local function RectVecSub(A,B)
	return {A[1] - B[1],A[2] - B[2],A[3] - B[1],A[4] - B[2]};
end

local NetworkData;

UpdateNetwork = function(NewConduits)
	if NewConduits ~= nil then
		--DPrint("Setting to New Conduits");
		Conduits = NewConduits;
	else
		Conduits = world.getObjectParameter(SourceID,"AllConduits",{});
	end
	--DPrint("Updating Network with = " .. sb.printJson(Conduits,1));
	--Conduits = NewConduits or world.getObjectParameter(SourceID,"AllConduits",{});
	--DPrint("ALLCONDUITINITIAL = " .. sb.print(Conduits));
	for k,i in pairs(Conduits) do
		--DPrint("Setting Up Type = " .. sb.print(k));
		--DPrint("I[1] = " .. sb.print(i[1]));
		--DPrint("I = " .. sb.printJson(i,1));
		SetupAnimationInfoForType(k,i[1]);
	end
	NetworkData = {};
	for k,i in pairs(Conduits) do
		for m,n in ipairs(i) do
			NetworkData[n] = {};
			--NetworkData[n].CustomFlipX = world.getObjectParameter(n,"CustomFlipX",false);
			--NetworkData[n].CustomFlipY = world.getObjectParameter(n,"CustomFlipY",false);
			NetworkData[n].FlipX = CallMessageAsync(n,"GetFlipX",function() return world.getObjectParameter(n,"CustomFlipX",false) end);
			NetworkData[n].FlipY = CallMessageAsync(n,"GetFlipY",function() return world.getObjectParameter(n,"CustomFlipY",false) end);
			--NetworkData[n].CustomAnimationState = world.getObjectParameter(n,"CustomAnimationState",false);
			NetworkData[n].AnimationState = CallMessageAsync(n,"GetAnimationState",function() return world.getObjectParameter(n,"CustomAnimationState",false) end);
			NetworkData[n].Image = CallMessageAsync(n,"GetTerminalImage",function() return world.getObjectParameter(n,"StoredTerminalImage"); end);
			NetworkData[n].Position = world.entityPosition(n);
			--DPrint("Position = " .. sb.print(NetworkData[n].Position));
		end
	end
	SetSourceValue("UINeedsUpdate",false);
end

function update(dt)
	--[[local NewHue = world.getObjectParameter(SourceID,"Hue",0);
	local NewSat = world.getObjectParameter(SourceID,"Saturation",0);
	if Hue ~= NewHue or Sat ~= NewSat then
		Hue = NewHue;
		Sat = NewSat;
		UpdateColors();
	end--]]
	MainCanvas:clear();
	if UIUpdateMessage == nil then
		UIUpdateMessage = world.sendEntityMessage(SourceID,"UINeedsUpdate");
	else
		if UIUpdateMessage:finished() then
			local Result,NewConduits = table.unpack(UIUpdateMessage:result() or {});
			if Result == true then
				UpdateNetwork(NewConduits);
			end
			UIUpdateMessage = world.sendEntityMessage(SourceID,"UINeedsUpdate");
		end
	end
	--[[if world.getObjectParameter(SourceID,"UINeedsUpdate") == true then
		UpdateNetwork();
	end--]]
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
	MainCanvas:drawTiledImage("/Blocks/Conduit Terminal/UI/Window/TileImage.png",{Offset[1] * 0.7,Offset[2] * 0.7},{0,0,2000,2000},0.1,LastColor);
	for k,i in pairs(Conduits) do
		if Animations[k] ~= nil then
			for m,n in ipairs(i) do
				if NetworkData[n].Position == nil then
					NetworkData[n].Position = world.entityPosition(n);
				end
				local Pos = NetworkData[n].Position;
				local State = NetworkData[n].AnimationState();
				local X = ((Pos[1] - SourcePos[1]) * 8) + Offset[1];
				local Y = ((Pos[2] - SourcePos[2]) * 8) + Offset[2];
				local RenderCoords = {0,0,0,0};
				local TexCoords = Animations[k].States[State].Rect;
				if NetworkData[n].FlipX() == true then
					RenderCoords[1] = X + Animations[k].States[State].Size[1];
					RenderCoords[3] = X;
				else
					RenderCoords[1] = X;
					RenderCoords[3] = X + Animations[k].States[State].Size[1];
				end

				if NetworkData[n].FlipY() == true then
					RenderCoords[2] = Y + Animations[k].States[State].Size[2];
					RenderCoords[4] = Y;
				else
					RenderCoords[2] = Y;
					RenderCoords[4] = Y + Animations[k].States[State].Size[2];
				end
				RenderCoords = RectVecSub(RenderCoords,Animations[k].States[State].Offset);
				local Image = NetworkData[n].Image()
				if Image ~= nil then
					MainCanvas:drawImageRect(Image,TexCoords,RenderCoords);
				end
			end
		end
	end
	MainCanvas:drawImage(ConduitTerminalImage,{Offset[1],Offset[2]});
	MainCanvas:drawImage(LitConduitTerminalImage,{Offset[1],Offset[2]},nil,LastColor);
end

UpdateColors = function()
	local Directives = "?hueshift=" .. Hue .. "?saturation=" .. -Sat;
	widget.setImage("MainTitle",TitleImage .. Directives);
	widget.setImage("MainWindowColor",MainWindowColor .. Directives);
	widget.setButtonImages("close",{
		base = CloseImage .. Directives,
		hover = CloseHighlightedImage .. Directives,
		pressed = CloseHighlightedImage .. Directives
	});
	LastDirective = Directives;
	LastColor = hsvToRgb(Hue,100 - Sat,1);
end

function CanvasClick(Position,ButtonType,IsDown)
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

local function SetColor()
	--[[DPrint("Old Hue = " .. sb.print(Hue));
	DPrint("Old Sat = " .. sb.print(Sat));
	DPrint("Last Color Old = " .. sb.print(LastColor));
	DPrint("New Hue = " .. sb.print(Hue));
	DPrint("New Sat = " .. sb.print(Sat));
	DPrint("Last Color New = " .. sb.print(LastColor));--]]
	world.sendEntityMessage(SourceID,"SetHue",Hue);
	world.sendEntityMessage(SourceID,"SetSaturation",Sat);
	UpdateColors();
end

function HueSlider()
	DPrint("Hue Change!");
	if Initialized then
		Hue = widget.getSliderValue("hueSlider");
		SetColor();
	end
end

function SatSlider()
	DPrint("Sat Change!");
	if Initialized then
		Sat = widget.getSliderValue("satSlider");
		SetColor();
	end
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
