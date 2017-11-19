if vec == nil then
	require ("/Core/Math.lua");
end
local vec = vec;
local rect = rect;
function CreateElement(CanvasName)
	local Element = {};
	local Drawables = {};
	local Canvas;
	local Position;
	local ID;

	local Controller = setmetatable({},{__index = function()
		error("This Element hasn't been finished yet");
	end});

	local ControllerBase = {};

	ControllerBase.SetPosition = function(Pos)
		Element.GetController().ChangePosition(vec.sub(Pos,Position));
	end

	ControllerBase.ChangePosition = function(Diff)
		for k,i in pairs(Drawables) do
			i.Rect = rect.vecAdd(i.Rect,Diff);
		end
		Position = vec.Add(Position,Diff);
	end

	ControllerBase.SetAbsolutePosition = function(Pos)
		if Element.Parent ~= nil then
			local AbsPosition = vec.add(Position,Parent.GetController().GetAbsolutePosition());
			Element.GetController().ChangePosition(vec.sub(Pos,AbsPosition));
		else
			Element.GetController().ChangePosition(vec.sub(Pos,Position));
		end
	end

	ControllerBase.ChangeAbsolutePosition = function(Diff)
		Element.GetController().ChangePosition(Diff);
	end

	ControllerBase.GetPosition = function()
		return {Position[1],Position[2]};
	end

	ControllerBase.GetAbsolutePosition = function()
		if Element.Parent ~= nil then
			return vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
		end
		return {Position[1],Position[2]};
	end

	Element.AddDrawable = function(Name,Rect,Image,IsTiled)
		Drawables[Name] = {
			Rect = Rect,
			Image = Image,
			IsTiled = IsTiled,
			TextureRect = rect.minimize(Rect)
		}
	end

	Element.SetDrawableRect = function(Name,Rect)
		if Drawables[Name] == nil then
			error("Drawable of " .. sb.print(Name) .. " doesn't exist");
		end
		Drawables[Name].Rect = Rect;
	end

	Element.GetDrawableRect = function(Name)
		if Drawables[Name] == nil then
			error("Drawable of " .. sb.print(Name) .. " doesn't exist");
		end
		return Drawables[Name].Rect;
	end

	Element.Draw = function()
		for k,i in pairs(Drawables) do
			if i.IsTiled == true then
				Canvas:drawTiledImage(i.Image,{0,0},i.Rect);
			else
				Canvas:drawImageRect(i.Image,i.TextureRect,i.Rect);
			end
		end
	end

	Element.GetController = function()
		return Controller;
	end

	Element.SetCanvas = function(AliasName)
		Canvas = CanvasCore.GetCanvas(AliasName);
	end

	Element.AddControllerValue = function(name,value)
		ControllerBase[name] = value;
	end

	Element.Finish = function()
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
	if CanvasName ~= nil then
		Element.SetCanvas(CanvasName);
	end
	return Element;
end

