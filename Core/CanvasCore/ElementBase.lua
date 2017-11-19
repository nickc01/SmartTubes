require ("/Core/Math.lua");
local vec = vec;
local rect = rect;
Element = {};

if CanvasCore == nil then
	error("ElementBase can only be used when CanvasCore is used");
end

local Drawables = {};

local Position;

local Controller = setmetatable({},{__index = function()
	error("This Element hasn't been finished yet");
end});

local ControllerBase = {};

ControllerBase.SetPosition(Pos)
	Element.GetController().ChangePosition(vec.sub(Pos,Position));
end

ControllerBase.ChangePosition(Diff)
	for k,i in pairs(Drawables) do
		i.Rect = rect.vecAdd(i.Rect,Diff);
	end
	Position = vec.Add(Position,Diff);
end

ControllerBase.SetAbsolutePosition(Pos)
	if Element.Parent ~= nil then
		local AbsPosition = vec.add(Position,Parent.GetController().GetAbsolutePosition());
		Element.GetController().ChangePosition(vec.sub(Pos,AbsPosition));
	else
		Element.GetController().ChangePosition(vec.sub(Pos,Position));
	end
end

ControllerBase.ChangeAbsolutePosition(Diff)
	Element.GetController().ChangePosition(Diff);
end

ControllerBase.GetPosition()
	return {Position[1],Position[2]};
end

ControllerBase.GetAbsolutePosition()
	if Element.Parent ~= nil then
		return vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
	end
	return {Position[1],Position[2]};
end

function Element.AddDrawable(Name,Rect,Image,IsTiled)
	Drawables[Name] = {
		Rect = Rect,
		Image = Image,
		IsTiled = IsTiled,
		TextureRect = rect.minimize(Rect)
	}
end

function Element.Draw()
	for k,i in pairs(Drawables) do
		if i.IsTiled == true then
			Element.Canvas:drawTiledImage(i.Image,{0,0},i.Rect);
		else
			Element.Canvas:drawImageRect(i.Image,Rect.TextureRect,i.Rect);
		end
	end
end

function Element.GetController()
	return Controller;
end

local Canvas;

function Element.SetCanvas(AliasName)
	Canvas = CanvasCore.GetCanvas(AliasName);
end

function Element.AddControllerValue(name,value)
	ControllerBase[name] = value;
end

function Element.Finish()
	if Canvas == nil then
		error("This element doesn't have a Canvas Alias Set, run SetCanvas() to set the element's Canvas Alias");
	end
	local LowestPoint;
	for k,i in pairs(Drawables) do
		if LowestPoint == nil then
			LowestPoint = {i.Rect[1],i.Rect[2]};
		else
			if i.Rect[1] < LowestPoint[1] then
				LowestPoint[1] = i.Rect[1];
			end
			if i.Rect[2] < LowestPoint[2] then
				LowestPoint[2] = i.Rect[2];
			end
		end
	end
	if LowestPoint == nil then
		LowestPoint = {0,0};
	end
	Position = LowestPoint;
	Controller = ControllerBase;
	ID = sb.makeUuid();
	return Controller;
end
