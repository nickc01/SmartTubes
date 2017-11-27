if vec == nil then
	require ("/Core/ArgonGUI/Math.lua");
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
			--sb.logInfo("Calling Parent");
			local ParentClip = Element.Parent.GetClippingBoundaries();
			--sb.logInfo("After Parent Call = " .. sb.print(ParentClip));
		--	sb.logInfo("Parent Clip = " .. sb.print(ParentClip));
			local LocalClip;
			if Clippable == true then
				LocalClip = rect.vecAdd(Element.GetLocalClippingBounds(),Element.GetController().GetAbsolutePosition());
			end
			if ParentClip == nil then
				--sb.logInfo("E");
				return LocalClip;
			end
			if ParentClip == "none" then
				--sb.logInfo("D");
				return ParentClip;
			end
			if LocalClip == nil then
				--sb.logInfo("C");
				return ParentClip;
			end
			if rect.intersects(ParentClip,LocalClip) then
				--sb.logInfo("B");
				return rect.intersection(ParentClip,LocalClip);
			else
				--sb.logInfo("A");
				return "none";
			end
		else
			local LocalClip;
			--sb.logInfo("Top Parent");
			if Clippable == true then
				LocalClip = rect.vecAdd(Element.GetLocalClippingBounds(),Element.GetController().GetAbsolutePosition());
			end
			--sb.logInfo("Top Mask = " .. sb.print(LocalClip));
			--sb.logInfo("Top Parent Clip + " .. sb.print(LocalClip));
			return LocalClip;
		end
	end

	local function UpdateClips()
		local Boundaries = Element.GetClippingBoundaries();
		--sb.logInfo("Boundaries = " .. sb.print(Boundaries));
		for k,i in ipairs(Drawables) do
			if Boundaries == nil then
				i.Rejected = false;
				i.Rect = i.OriginalRect;
				i.TextureRect = i.OriginalTextureRect;
				break;
			end
			if Boundaries == "none" then
				i.Rejected = true;
			else
				if rect.isInverted(Boundaries) then
					i.Rejected = true;
				else
					local Final,Offset = rect.cut(Boundaries,rect.vecAdd(i.OriginalRect,Element.GetController().GetAbsolutePosition()));
					if rect.isInverted(Final) then
						i.Rejected = true;
					else
						Final = rect.vecSub(Final,Element.GetController().GetAbsolutePosition());
						i.Rejected = false;
						i.Rect = Final;
						i.TextureRect = rect.vecAdd(rect.minimize(Final),{Offset[1],Offset[2]});
						if i.IsTiled == true then
							i.TextureOffset = {-Offset[1],-Offset[2]};
						end
					end
				end
			end
		end
	end

	Element.UpdateClips = function()
		UpdateClips();
		if ParentMode == true then
			for k,i in ipairs(Children) do
				i.UpdateClips();
			end
		end
	end

	ControllerBase.SetPosition = function(Pos)
		Element.GetController().ChangePosition(vec.sub(Pos,Position));
	end

	ControllerBase.ChangePosition = function(Diff)
		Position = vec.add(Position,Diff);
		Element.UpdateClips();
	end

	ControllerBase.SetAbsolutePosition = function(Pos)
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
		if Element.Parent ~= nil then
			return vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
		end
		return {Position[1],Position[2]};
	end

	Element.AddDrawable = function(Name,Rect,Image,IsTiled)
		Drawables[#Drawables + 1] = {
			Name = Name,
			Rect = Rect,
			OriginalRect = Rect,
			Image = Image,
			IsTiled = IsTiled,
			TextureRect = rect.minimize(Rect),
			OriginalTextureRect = rect.minimize(Rect),
			Rejected = false
		}
		if IsTiled == true then
			Drawables[#Drawables].TextureOffset = {0,0};
		end
		if Finished == true then
			Element.UpdateClips();
		end
	end

	Element.Clipping = function(bool)
		if bool == true then
			Clippable = true;
		else
			Clippable = false;
		end
	end
	Element.SetClippingBounds = function(rect)
		if Clippable == false then
			Element.Clipping(true);
		end
		ClippingBounds = {rect[1],rect[2],rect[3],rect[4]};
		Element.UpdateClips();
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
			Element.UpdateClips();
		end
	end

	Element.SetDrawableRect = function(Name,Rect)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				Drawables[k].OriginalRect = Rect;
				Element.UpdateClips();
				return nil;
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
	end

	Element.GetDrawableRect = function(Name)
		for k,i in ipairs(Drawables) do
			if i.Name == Name then
				return {i.OriginalRect[1],i.OriginalRect[2],i.OriginalRect[3],i.OriginalRect[4]};
			end
		end
		error("Drawable of " .. sb.print(Name) .. " doesn't exist");
	end

	Element.Draw = function()
		for k,i in ipairs(Drawables) do
			if i.Rejected == false then
				if i.IsTiled == true then
					Canvas:drawTiledImage(i.Image,i.TextureOffset,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()));
				else
					Canvas:drawImageRect(i.Image,i.TextureRect,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()));
				end
			end
		end
		if ParentMode == true then
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

	Element.AddChild = function(element,RetainPosition)
		if ParentMode == true then
			if element.Parent == nil then
				Children[#Children + 1] = element;
				local Position;
				if RetainPosition == true then
					Position = element.GetController().GetAbsolutePosition();
				end
				element.Parent = Element;
				element.Core.RemoveElement(CanvasAlias,element);
				if RetainPosition == true then
					element.GetController().SetAbsolutePosition(Position);
				end
				element.UpdateClips();
			else
				if element.Parent ~= Element then
					local Position;
					if RetainPosition == true then
						Position = element.GetController().GetAbsolutePosition();
					end
					element.Parent.RemoveChild(element);
					element.Parent = Element;
					Children[#Children + 1] = element;
					if RetainPosition == true then
						element.GetController().SetAbsolutePosition(Position);
					end
					element.UpdateClips();
				end
			end
		end
	end
	Element.RemoveChild = function(element,RetainPosition)
		for k,i in ipairs(Children) do
			if i.GetID() == element.GetID() then
				table.remove(Children,k);
				local Position;
				if RetainPosition == true then
					Position = element.GetController().GetAbsolutePosition();
				end
				element.Parent = nil;
				element.Core.AddElement(CanvasAlias,element);
				if RetainPosition == true then
					element.GetController().SetAbsolutePosition(Position);
				end
				element.UpdateClips();
				return true;
			end
		end
		return false;
	end

	ParentingController.AddChild = function(controller,RetainPosition)
		Element.AddChild(Element.Core.GetElementByController(controller),RetainPosition);
	end
	
	ParentingController.RemoveChild = function(controller,RetainPosition)
		Element.RemoveChild(Element.Core.GetElementByController(controller),RetainPosition);
	end

	Element.RemoveAllChildren = function()
		for k,i in ipairs(Children) do
			local Position = i.GetController().GetAbsolutePosition();
			i.Parent = nil;
			i.GetController().SetAbsolutePosition(Position);
		end
		Children = {};
		Element.UpdateClips();
	end

	ControllerBase.GetID = function()
		return ID;
	end

	Element.GetID = function()
		return ID;
	end

	Element.SetCanvas = function(AliasName)
		CanvasAlias = AliasName;
		Canvas = Argon.GetCanvas(AliasName);
	end
	Element.GetCanvas = function()
		return Canvas;
	end

	Element.AddControllerValue = function(name,value)
		ControllerBase[name] = value;
	end
	
	ControllerBase.Delete = function()
		if Element.Parent ~= nil then
			Element.Parent.RemoveChild(Element);
		end
		if ParentMode == true then
			for i=#Children,1,-1 do
				Children[i].GetController().Delete();
			end
		end
		Element.Core.DeleteElement(CanvasAlias,Element);
	end

	Element.Finish = function()
		if Finished == false then
			if Canvas == nil then
				error("This element doesn't have a Canvas Alias Set, run SetCanvas() to set the element's Canvas Alias");
			end
			if Position == nil then
				error("This element doesn't have a position set, run SetPosition(pos) to set the element's position");
			end
			Controller = ControllerBase;
			ID = sb.makeUuid();
			Finished = true;
			Element.UpdateClips();
			return Element;
		end
	end
	if CanvasName ~= nil then
		Element.SetCanvas(CanvasName);
	end
	return Element;
end

