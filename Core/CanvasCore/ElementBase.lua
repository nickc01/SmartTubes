if vec == nil then
	require ("/Core/Math.lua");
end
local vec = vec;
local rect = rect;
function CreateElement(CanvasName)
	local Element = {};
	local Drawables = {};
	local ParentingController = {};
	local Canvas;
	local CanvasAlias;
	local Position;
	local ID;
	local Finished = false;
	local ParentMode = false;
	local Children;
	local ClippingBounds;
	local Clippable = false;

	local Controller = setmetatable({},{__index = function()
		error("This Element hasn't been finished yet");
	end});

	local ControllerBase = {};

	Element.GetClippingBoundaries = function()
		if Element.Parent ~= nil then
			local ParentClip = Element.Parent.GetClippingBoundaries();
			local LocalClip = rect.vecAdd(Element.GetLocalClippingBounds(),Element.GetController().GetAbsolutePosition());

		else
			
		end
	end

	local function UpdateClips()
		
	end

	ControllerBase.SetPosition = function(Pos)
		Element.GetController().ChangePosition(vec.sub(Pos,Position));
	end

	ControllerBase.ChangePosition = function(Diff)
		--[[for k,i in pairs(Drawables) do
			i.Rect = rect.vecAdd(i.Rect,Diff);
		end--]]
		Position = vec.add(Position,Diff);
		UpdateClips();
	end

	ControllerBase.SetAbsolutePosition = function(Pos)
		--sb.logInfo("Setting To Pos " .. sb.print(Pos));
		if Element.Parent ~= nil then
			local CurrentAbsolutePosition = vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
			Element.GetController().ChangePosition(vec.sub(Pos,CurrentAbsolutePosition));
		else
			Element.GetController().SetPosition(Pos);
		end
	end

	ControllerBase.ChangeAbsolutePosition = function(Diff)
		Element.GetController().ChangePosition(Diff);
	end

	ControllerBase.GetPosition = function()
		return {Position[1],Position[2]};
	end
	Element.GetPosition = function()
		return {Position[1],Position[2]};
	end

	ControllerBase.GetAbsolutePosition = function()
		--sb.logInfo("Parent = " .. sb.print(Element.Parent));
		if Element.Parent ~= nil then
		--	sb.logInfo("Local Position = " .. sb.print(Position));
		--	sb.logInfo("Parent Position = " .. sb.print(Element.Parent.GetController().GetAbsolutePosition()));
			--sb.logInfo("Abs Position = " .. sb.print(vec.add(Position,Element.Parent.GetController().GetAbsolutePosition())));
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
		if IsTiled == true then
			Drawables[#Drawables].TextureOffset = {0,0};
		end
		if Finished == true then
			UpdateClips();
		end
	end

	Element.Clipping = function(bool)
		if bool == true then
			Clippable = false;
		else
			Clippable = false;
		end
	end
	Element.SetClippingBounds = function(rect)
		if Clippable == true then
			ClippingBounds = rect;
		end
	end

	Element.GetLocalClippingBounds = function()
		return {ClippingBounds[1],ClippingBounds[2],ClippingBounds[3],ClippingBounds[4]};
	end

	Element.Clippable = function()
		return Clippable;
	end

	Element.RemoveDrawable = function(Name)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				table.remove(Drawables,k);
				return true;
			end
		end
		return false;
	end

	Element.SetPosition = function(pos)
		Position = pos;
		if Finished == true then
			UpdateClips();
		end
	end

	Element.SetDrawableRect = function(Name,Rect)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				Drawables[k].Rect = Rect;
				return nil;
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
		UpdateClips();
	end

	Element.GetDrawableRect = function(Name)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				return {i.Rect[1],i.Rect[2],i.Rect[3],i.Rect[4]};
				--return rect.vecSub(i.Rect,Position);
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
	end

	Element.Draw = function()
		for k,i in ipairs(Drawables) do
			--sb.logInfo("Getting VALUE");
			--sb.logInfo("DrawRect = " .. sb.print(rect.vecAdd(i.Rect,Controller.GetAbsolutePosition())) .. " Name = " .. sb.print(i.Name));
			--sb.logInfo("Absolute Position = " .. sb.print(Controller.GetAbsolutePosition()));
			--sb.logInfo("Rendering Pos = " .. sb.print(Controller.GetAbsolutePosition()));
			if i.IsTiled == true then
				Canvas:drawTiledImage(i.Image,i.TextureOffset,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()));
			else
				Canvas:drawImageRect(i.Image,i.TextureRect,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()));
			end
		end
		if ParentMode == true then
			--sb.logInfo("Children = " .. sb.print(Children));
			for k,i in ipairs(Children) do
				i.Draw();
			end
		end
	end

	Element.GetController = function()
		if Finished == true then
			return Controller;
		else
			return ControllerBase;
		end
	end
	Element.Update = function(dt)
		if ParentMode == true then
			for k,i in ipairs(Children) do
				i.Update(dt);
			end
		end
	end

	--[[local Children;
	Element.CanHaveChildren = false;

	Element.SetParentMode = function(bool)
		if bool == true then
			Children = {};
		else
			
		end
	end

	Element.SetParent = function(element)
		if element == nil and Element.Parent ~= nil then
			Element.Parent = nil;
			return nil;
		end
		if element ~= nil and element.CanHaveChildren == true then
			
		end
	end--]]
	local function GetAllChildren()
		if #Children == 0 then
			return function()
				return nil;
			end
		elseif #Children == 1 then
			local Returned = false;
			return function()
				if Returned == false then
					Returned = true;
					return Children[1];
				else
					return nil;
				end
			end
		end
		local Index = 1;
		local Size = #Children;
		return function()
			if Index <= Size then
				Index = Index + 1;
				return Children[Index - 1];
			end
			return nil;
		end
	end
	Element.SetParentMode = function(bool)
		if bool == true then
			Children = {};
			ParentMode = true;
			for k,i in pairs(ParentingController) do
				if Finished == false then
					ControllerBase[k] = i;
				else
					Controller[k] = i;
				end
			end
		else
			ParentMode = false;
			Element.RemoveAllChildren();
			for k,i in pairs(ParentingController) do
				if Finished == false then
					ControllerBase[k] = nil;
				else
					Controller[k] = nil;
				end
			end
		end
	end

	Element.GetParentMode = function()
		return ParentMode;
	end

	Element.AddChild = function(element)
		if ParentMode == true then
			if element.Parent == nil then
				Children[#Children + 1] = element;
				--local Position = element.GetController().GetAbsolutePosition();
				element.Parent = Element;
				Element.Core.RemoveElement(CanvasAlias,element);
				--element.GetController().SetAbsolutePosition(Position);
			else
				if element.Parent ~= Element then
					--local Position = element.GetController().GetAbsolutePosition();
					element.Parent = Element;
					--element.GetController().SetAbsolutePosition(Position);
				end
			end
		end
	end
	Element.RemoveChild = function(element)
		for k,i in ipairs(Children) do
			if i.GetID() == element.GetID() then
				table.remove(Children,k);
				--local Position = element.GetController().GetAbsolutePosition();
				element.Parent = nil;
				Element.Core.AddElement(CanvasAlias,element);
				--element.GetController().SetAbsolutePosition(Position);
				return true;
			end
		end
		return false;
	end

	ParentingController.AddChild = function(controller)
		Element.AddChild(Element.Core.GetElementByController(controller));
	end
	
	ParentingController.RemoveChild = function(controller)
		Element.RemoveChild(Element.Core.GetElementByController(controller));
	end

	Element.RemoveAllChildren = function()
		for k,i in ipairs(Children) do
			local Position = i.GetController().GetAbsolutePosition();
			i.Parent = nil;
			i.GetController().SetAbsolutePosition(Position);
		end
		Children = {};
	end

	ControllerBase.GetID = function()
		return ID;
	end

	Element.GetID = function()
		return ID;
	end

	Element.SetCanvas = function(AliasName)
		CanvasAlias = AliasName;
		Canvas = CanvasCore.GetCanvas(AliasName);
	end
	Element.GetCanvas = function()
		return Canvas;
	end

	Element.AddControllerValue = function(name,value)
		ControllerBase[name] = value;
	end
	
	ControllerBase.Delete = function(ChildrenToo)
		Element.Core.DeleteElement(CanvasAlias,Element);
	end
	
	--[[local function MakeRectsAbsolute()
		for k,i in ipairs(Drawables) do
			i.LocalRect = i.Rect;
			i.Rect = rect.vecAdd(i.Rect,Position);
		end
	end--]]

	Element.Finish = function()
		if Finished == false then
			if Canvas == nil then
				error("This element doesn't have a Canvas Alias Set, run SetCanvas() to set the element's Canvas Alias");
			end
			if Position == nil then
				error("This element doesn't have a position set, run SetPosition(pos) to set the element's position");
			end
			--MakeRectsAbsolute();
			Controller = ControllerBase;
			ID = sb.makeUuid();
			Finished = true;
			UpdateClips();
			return Element;
		end
	end
	if CanvasName ~= nil then
		Element.SetCanvas(CanvasName);
	end
	return Element;
end

