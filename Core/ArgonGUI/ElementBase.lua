if vec == nil then
	require ("/Core/ArgonGUI/Math.lua");
end
local vec = vec;
local rect = rect;
function CreateElement(CanvasName)
	local Element = {};
	local Sprites = {};
	local SpritesByName = {};
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
	local Active = true;
	local UpdateFunc;
	local FinishFunc;
	local Core;

	local Controller = setmetatable({},{__index = function()
		error("This Element hasn't been finished yet");
	end});

	local ControllerBase = {};

	Element.SetCore = function(value)
		Core = value;
	end

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
		if Active == true then
			local Boundaries = Element.GetClippingBoundaries();
			--sb.logInfo("Boundaries = " .. sb.print(Boundaries));
			--sb.logInfo("Sprites Here = " .. sb.print(Sprites));
			for k,i in ipairs(Sprites) do
				--sb.logInfo("Clip Index = " .. sb.print(k));
				--sb.logInfo("CLipping = " .. sb.print(i.Name));
				if Boundaries == nil then
					--sb.logInfo("1");
					i.Rejected = false;
					i.Rect = i.OriginalRect;
					--sb.logInfo("I = " .. sb.printJson(i,1));
					--sb.logInfo("Setting Rect To " .. sb.print(i.OriginalRect));
					i.TextureRect = i.OriginalTextureRect;
				elseif Boundaries == "none" then
					i.Rejected = true;
					--sb.logInfo("2");
				else
					if rect.isInverted(Boundaries) then
						i.Rejected = true;
						--sb.logInfo("3");
					else
						local Final,Offset = rect.cut(Boundaries,rect.vecAdd(i.OriginalRect,Element.GetController().GetAbsolutePosition()));
						if rect.isInverted(Final) then
							i.Rejected = true;
							--sb.logInfo("4");
						else
							Final = rect.vecSub(Final,Element.GetController().GetAbsolutePosition());
							--sb.logInfo("5");
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
	end

	Element.UpdateClips = function()
		if Active == true then
			UpdateClips();
			if ParentMode == true then
				for k,i in ipairs(Children) do
					i.UpdateClips();
				end
			end
		end
	end

	Element.SetUpdateFunction = function(func)
		UpdateFunc = func;
	end

	--Element.SetSpriteClickFunction()

	ControllerBase.SetPosition = function(Pos)
		Element.GetController().ChangePosition(vec.sub(Pos,Position));
	end

	ControllerBase.ChangePosition = function(Diff)
		Position = vec.add(Position,Diff);
		Element.UpdateClips();
	end
	Element.ChangePosition = function(Diff)
		Element.GetController().ChangePosition();
	end

	ControllerBase.SetAbsolutePosition = function(Pos)
		if Element.Parent ~= nil then
			local CurrentAbsolutePosition = vec.add(Position,Element.Parent.GetController().GetAbsolutePosition());
			Element.GetController().ChangePosition(vec.sub(Pos,CurrentAbsolutePosition));
		else
			Element.GetController().SetPosition(Pos);
		end
	end
	Element.SetAbsolutePosition = function(Pos)
		Element.GetController().SetAbsolutePosition(Pos);
	end

	ControllerBase.ChangeAbsolutePosition = function(Diff)
		Element.GetController().ChangePosition(Diff);
	end
	Element.ChangeAbsolutePosition = function(Diff)
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
	Element.GetAbsolutePosition = function()
		return Element.GetController().GetAbsolutePosition();
	end

	Element.AddSprite = function(Name,Rect,Image,IsTiled,Color)
		if SpritesByName[Name] ~= nil then
			error("Sprite of " .. sb.print(Name) .. " already exists");
		end
		Sprites[#Sprites + 1] = {
			Name = Name,
			Rect = Rect,
			OriginalRect = rect.copy(Rect),
			Image = Image,
			IsTiled = IsTiled,
			Color = Color,
			TextureRect = rect.minimize(Rect),
			OriginalTextureRect = rect.minimize(Rect),
			Rejected = false
		}
		SpritesByName[Name] = #Sprites;
		if IsTiled == true then
			Sprites[#Sprites].TextureOffset = {0,0};
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

	Element.RemoveSprite = function(Name)
		if SpritesByName[Name] ~= nil then
			table.remove(Sprites,SpritesByName[Name]);
			table.remove(SpritesByName,Name);
			return true;
		end
		return false;
	end

	Element.SetPosition = function(pos)
		Position = pos;
		if Finished == true then
			Element.UpdateClips();
		end
	end

	Element.SetSpriteRect = function(Name,Rect)
	--[[	sb.logInfo("Sprites AT SET = " .. sb.print(Sprites));
		for k,i in ipairs(Sprites) do
			sb.logInfo("Name = " .. sb.print(i.Name));
		end--]]
		--[[for k,i in ipairs(Sprites) do
			if i.Name == Name then
				--sb.logInfo("Setting Rect for " .. sb.print(i.Name));
				--sb.logInfo("Current Rect = " .. sb.print(Rect));
				i.OriginalRect = rect.copy(Rect);
				--sb.logInfo("I In Set = " .. sb.print(i));
				Element.UpdateClips();
				return nil;
			end
		end--]]
		if SpritesByName[Name] ~= nil then
			Sprites[SpritesByName[Name]].OriginalRect = rect.copy(Rect);
			Element.UpdateClips();
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end
	Element.SetSpriteColor = function(Name,Color)
		--[[for k,i in ipairs(Sprites) do
			if i.Name == Name then
				i.Color = Color;
				Element.UpdateClips();
				return nil;
			end
		end
		error("Sprite of " .. sb.print(Name) .. " doesn't exist");--]]
		if SpritesByName[Name] ~= nil then
			Sprites[SpritesByName[Name]].Color = Color;
			Element.UpdateClips();
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end

	Element.SetSpriteClickFunction = function(Name,Func)
		--[[for k,i in ipairs(Sprites) do
			if i.Name == Name then
				i.ClickFunc = Func;
				return nil;
			end
		end
		error("Sprite of " .. sb.print(Name) .. " doesn't exist");--]]
		if SpritesByName[Name] ~= nil then
			Sprites[SpritesByName[Name]].ClickFunc = Func;
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end

	local ClickedSprites = nil;

	Element.OnClick = function(Position,ButtonType,IsDown)
		if Active == true then
			if IsDown == true then
				if ClickedSprites ~= nil then
					for k,i in ipairs(ClickedSprites) do
						i.ClickFunc(Position,ButtonType,false);
					end
				end
				ClickedSprites = {};
				for k,i in ipairs(Sprites) do
					if i.Rejected == false and i.ClickFunc ~= nil then
						if rect.isPosWithin(rect.vecAdd(i.Rect,Element.GetAbsolutePosition()),Position) then
							ClickedSprites[#ClickedSprites + 1] = i;
							i.ClickFunc(Position,ButtonType,IsDown);
						end
					end
				end
			
			else
				if ClickedSprites == nil then
					for k,i in ipairs(Sprites) do
						ClickedSprites = {};
						if i.ClickFunc ~= nil then
							if rect.isPosWithin(rect.vecAdd(i.Rect,Element.GetAbsolutePosition()),Position) then
								ClickedSprites[#ClickedSprites + 1] = i;
								i.ClickFunc(Position,ButtonType,IsDown);
							end
						end
					end
				else
					for k,i in ipairs(ClickedSprites) do
						i.ClickFunc(Position,ButtonType,IsDown);
					end
					ClickedSprites = nil;
				end
			end
		end
	end

	Element.GetSpriteRect = function(Name)
		--[[for k,i in ipairs(Sprites) do
			if i.Name == Name then
				return {i.OriginalRect[1],i.OriginalRect[2],i.OriginalRect[3],i.OriginalRect[4]};
			end
		end
		error("Sprite of " .. sb.print(Name) .. " doesn't exist");--]]
		if SpritesByName[Name] ~= nil then
			return rect.copy(Sprites[SpritesByName[Name]]);
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end

	Element.SetSpriteImage = function(Name,Image)
		sb.logInfo("Test");
		if SpritesByName[Name] ~= nil then
			Sprites[SpritesByName[Name]].Image = Image;
			sb.logInfo("Sprite = " .. sb.print(Sprites[SpritesByName[Name]]));
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end

	Element.GetSpriteImage = function(Name)
		if SpritesByName[Name] ~= nil then
			return Sprites[SpritesByName[Name]].Image;
		else
			error("Sprite of " .. sb.print(Name) .. " doesn't exist");
		end
	end

	Element.Draw = function()
		if Active == true then
			for k,i in ipairs(Sprites) do
				--sb.logInfo("Rendering Sprite of " .. sb.print(i.Name));
				if i.Rejected == false then
					--[[if i.Name == "Scroller" then
						sb.logInfo("Scroller's Rect = " .. sb.print(i.Rect));
					end--]]
					if i.IsTiled == true then
						Canvas:drawTiledImage(i.Image,i.TextureOffset,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()),nil,i.Color);
					else
						Canvas:drawImageRect(i.Image,i.TextureRect,rect.vecAdd(i.Rect,Controller.GetAbsolutePosition()),i.Color);
					end
				end
			end
			if ParentMode == true then
				for k,i in ipairs(Children) do
					i.Draw();
				end
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
		if Active == true then
			if ParentMode == true then
				for k,i in ipairs(Children) do
					i.Update(dt);
				end
			end
			if UpdateFunc ~= nil then
				UpdateFunc(dt);
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
				Core.RemoveElement(CanvasAlias,element);
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
				Core.AddElement(CanvasAlias,element);
				if RetainPosition == true then
					element.GetController().SetAbsolutePosition(Position);
				end
				element.UpdateClips();
				return true;
			end
		end
		return false;
	end

	Element.GetChildCount = function()
		if Children == nil then
			return 0;
		else
			return #Children;
		end
	end
	ControllerBase.GetChildCount = function()
		return Element.GetChildCount();
	end

	ControllerBase.GetFirstChild = function()
		local Child = Element.GetFirstChild();
		if Child ~= nil then
			return Child.GetController();
		end
	end

	ControllerBase.GetLastChild = function()
		local Child = Element.GetLastChild();
		if Child ~= nil then
			return Child.GetController();
		end
	end

	Element.GetFirstChild = function()
		if Children ~= nil and #Children > 0 then
			return Children[1];
		end
		return nil;
	end

	Element.GetLastChild = function()
		if Children ~= nil and #Children > 0 then
			return Children[#Children];
		end
		return nil;
	end

	ParentingController.AddChild = function(controller,RetainPosition)
		return Element.AddChild(Core.GetElementByController(controller),RetainPosition);
	end
	
	ParentingController.RemoveChild = function(controller,RetainPosition)
		return Element.RemoveChild(Core.GetElementByController(controller),RetainPosition);
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

	local OnDelete = {};
	
	ControllerBase.Delete = function()
		if Element.Parent ~= nil then
			Element.Parent.RemoveChild(Element);
		end
		if ParentMode == true then
			for i=#Children,1,-1 do
				Children[i].GetController().Delete();
			end
		end
		Core.DeleteElement(CanvasAlias,Element);
		for _,func in ipairs(OnDelete) do
			func();
		end
	end

	Element.Delete = function()
		Element.GetController().Delete();
	end

	ControllerBase.OnDelete = function(func)
		OnDelete[#OnDelete + 1] = func;
	end

	Element.OnFinish = function(func)
		FinishFunc = func;
	end

	ControllerBase.SetActive = function(bool)
		Active = bool;
		if Active == true then
			UpdateClips();
		else
			if ClickedSprites ~= nil then
				for k,i in ipairs(ClickedSprites) do
					i.ClickFunc(Position,ButtonType,false);
				end
				ClickedSprites = nil;
			end
		end
		if Children ~= nil then
			for k,i in ipairs(Children) do
				i.GetController().SetActive(bool);
			end
		end
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
			Element.SetCore = nil;
			if FinishFunc ~= nil then
				FinishFunc();
			end
			return Element;
		end
	end
	if CanvasName ~= nil then
		Element.SetCanvas(CanvasName);
	end
	return Element;
end

