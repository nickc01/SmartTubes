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

	--[[local CalculatePosition = function()
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
	end--]]

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
		Position = vec.add(Position,Diff);
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
	Element.GetPosition = function()
		return Position;
	end

	ControllerBase.GetAbsolutePosition = function()
		if Element.Parent ~= nil then
			return vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
		end
		return {Position[1],Position[2]};
	end

	Element.AddDrawable = function(Name,Rect,Image,IsTiled)
		Drawables[#Drawables + 1] = {
			Name = Name,
			Rect = Rect,
			Image = Image,
			IsTiled = IsTiled,
			TextureRect = rect.minimize(Rect)
		}
		--CalculatePosition();
	end

	Element.SetPosition = function(pos)
		Position = pos;
	end

	Element.SetDrawableRect = function(Name,Rect)
		--sb.logInfo("Drawables = " .. sb.printJson(Drawables,1));
		for k,i in ipairs(Drawables) do
			--sb.logInfo("i.Name = " .. sb.print(i.Name));
			--sb.logInfo("Name = " .. sb.print(Name));
			if i.Name == Name then
				Drawables[k].Rect = rect.vecAdd(Rect,Position);
				return nil;
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
		
	end

	Element.GetDrawableRect = function(Name)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				return rect.vecSub(i.Rect,Position);
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
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
	Element.GetCanvas = function()
		return Canvas;
	end

	Element.AddControllerValue = function(name,value)
		ControllerBase[name] = value;
	end
	
	ControllerBase.Delete = function()
		
	end
	
	local function MakeRectsAbsolute()
		for k,i in ipairs(Drawables) do
			i.LocalRect = i.Rect;
			i.Rect = rect.vecAdd(i.Rect,Position);
		end
	end

	Element.Finish = function()
		if Canvas == nil then
			error("This element doesn't have a Canvas Alias Set, run SetCanvas() to set the element's Canvas Alias");
		end
		if Position == nil then
			error("This element doesn't have a position set, run SetPosition(pos) to set the element's position");
		end
		MakeRectsAbsolute();
		Controller = ControllerBase;
		ID = sb.makeUuid();
		return Controller,Element;
	end
	if CanvasName ~= nil then
		Element.SetCanvas(CanvasName);
	end
	return Element;
end

