Creator = {};
local Creator = Creator;

local function Lerp(A,B,T)
	return ((A - B) * T) + B;
end

local function RectLerp(RectTop,RectBottom,Value)
	if Value > 1 then
		Value = 1;
	elseif Value < 0 then
		Value = 0;
	end
	return {Lerp(RectTop[1],RectBottom[1],Value),Lerp(RectTop[2],RectBottom[2],Value),Lerp(RectTop[3],RectBottom[3],Value),Lerp(RectTop[4],RectBottom[4],Value)};
end

--[[
	CanvasName - the Name of the Canvas
	Rect - The Rect for the Entire List
	ListImages - The Images for the list item
	{
		Inactive - The Image for an inactive element
		Active - The Image for an active element
		Selected - The Image for a selected element
	}
	Direction - Which way will the elements be placed when created, valid entries are :
	{
		Up,
		Down,
		Left,
		Right
	}
	Scrollbar - (Optional) will bind a scrollbar so you can navigate around the list
]]
function Creator.Create(CanvasName,Rect,ListImages,Direction,Scrollbar)
	local Scrollbar = Scrollbar;
	local ListArea = rect.copy(Rect);
	local Element = CreateElement(CanvasName);
	Element.SetPosition({Rect[1],Rect[2]});
	Element.SetParentMode(true,true);
	Element.SetClippingBounds(rect.minimize(Rect));

	local InactiveSize = root.imageSize(ListImages.Inactive);
	local ActiveSize = root.imageSize(ListImages.Active);
	local SelectedSize = root.imageSize(ListImages.Selected);

	local ElementSize = {math.max(InactiveSize[1],ActiveSize[1],SelectedSize[1]),math.max(InactiveSize[2],ActiveSize[2],SelectedSize[2])};

	local AnchorPoint;
	local AnchorElement;

	local Offset;

	local WindowLength;

	local SelectedElement;


	Direction = Direction or "down";
	Direction = string.lower(Direction);

	if Direction == "up" then
		Offset = {0,ElementSize[2]};
	elseif Direction == "down" then
		Offset = {0,-ElementSize[2]};
	elseif Direction == "left" then
		Offset = {-ElementSize[1],0};
	elseif Direction == "right" then
		Offset = {ElementSize[1],0};
	else
		error(sb.print(Direction) .. " is an invalid direction");
	end

	local Value = 0;

	--[[if Direction == "down" or Direction == "right" then
		Value = 1;
	end--]]

	if Direction == "up" or Direction == "down" then
		WindowLength = Rect[4] - Rect[2];
		Value = 1;
	else
		WindowLength = Rect[3] - Rect[1];
	end

	local function RecalculatePosition()
		AnchorPoint.SetPosition({0,0});
		local TopRect;
		local BottomRect;
		local FirstChildPos;
		local LastChildPos;
		local FirstChild = AnchorPoint.GetFirstChild();
		local LastChild = AnchorPoint.GetLastChild();
		if FirstChild == nil or LastChild == nil then
			if Scrollbar ~= nil then
				Scrollbar.SetSliderSize(1);
			end
			return nil;
		else
			FirstChildPos = FirstChild.GetPosition();
			LastChildPos = LastChild.GetPosition();
		end
		if Direction == "up" or Direction == "down" then
			local LowPoint = math.min(FirstChildPos[2],LastChildPos[2]);
			local HighPoint = math.max(FirstChildPos[2],LastChildPos[2]);
			BottomRect = {0,LowPoint,ListArea[3] - ListArea[1],LowPoint + ListArea[4] - ListArea[2]};
			TopRect = {0,(HighPoint + ElementSize[2]) - (BottomRect[4] - BottomRect[2]),ListArea[3] - ListArea[1],HighPoint + ElementSize[2]};
		else
			----------------------------------------------------------------------------------------
			local LowPoint = math.min(FirstChildPos[1],LastChildPos[1]);
			local HighPoint = math.max(FirstChildPos[1],LastChildPos[1]);
			BottomRect = {LowPoint,0,LowPoint + ListArea[3] - ListArea[1],ListArea[4] - ListArea[2]};
			TopRect = {(HighPoint + ElementSize[1]) - (BottomRect[3] - BottomRect[1]),0,HighPoint + ElementSize[1],ListArea[4] - ListArea[2]};
		end
		--sb.logInfo("FirstChildPos = " .. sb.print(FirstChildPos));
		--sb.logInfo("LastChildPos = " .. sb.print(LastChildPos));
		--sb.logInfo("TopRect = " .. sb.print(TopRect));
		--sb.logInfo("BottomRect = " .. sb.print(BottomRect));
		local Final = RectLerp(TopRect,BottomRect,Value);
		--sb.logInfo("FInal = " .. sb.print(Final));
		if Direction == "up" or Direction == "down" then
			--AnchorPoint.SetPosition({Final[1],-Final[2],Final[3],(Final[4] - Final[2]) - Final[2]});
			AnchorPoint.SetPosition({0,-Final[2]});
			--AnchorPoint.SetPosition(Final);
			if Scrollbar ~= nil then
				Scrollbar.SetSliderSize((math.max(FirstChildPos[2],LastChildPos[2]) - math.min(FirstChildPos[2],LastChildPos[2]) + ElementSize[2]) / WindowLength);
			end
		else
			--AnchorPoint.SetPosition({Final[1],-Final[2],Final[3],(Final[4] - Final[2]) - Final[2]});
			AnchorPoint.SetPosition({-Final[1],0});
			--AnchorPoint.SetPosition(Final);
			if Scrollbar ~= nil then
				Scrollbar.SetSliderSize((math.max(FirstChildPos[1],LastChildPos[1]) - math.min(FirstChildPos[1],LastChildPos[1]) + ElementSize[1]) / WindowLength);
			end
		end
	end

	local StartPos;

	local function GetLastElementPosition()
		if AnchorPoint.GetChildCount() > 0 then
			return AnchorPoint.GetLastChild().GetPosition();
		else
			if Direction == "up" then
				return {0,-ElementSize[2]};
			elseif Direction == "down" then
				return {0,ListArea[4] - ListArea[2]};
			elseif Direction == "left" then
				return {ElementSize[1],0};
			elseif Direction == "right" then
				return {-ElementSize[1],0};
			end
		end
	end

	local function PositionElements()
		local Pos = vec.copy(StartPos);
		for k,i in AnchorElement.ChildrenIter() do
			if i.GetController().Active() == true then
				Pos = vec.add(Pos,Offset);
				i.SetPosition(Pos);
			end
		end
	end

	local OnSelectedElementChange;

	Element.SetSelectedElement = function(value)
		if SelectedElement ~= value then
			if SelectedElement ~= nil then
				SelectedElement.SetImageType("active");
			end
			SelectedElement = value;
			if OnSelectedElementChange ~= nil then
				if value == nil then
					OnSelectedElementChange(nil);
				else
					OnSelectedElementChange(value.Parent.GetController());
				end
			end
		end
	end

	Element.AddControllerValue("AddElement",function()
		Element.SetSelectedElement(nil);
		local Position = GetLastElementPosition();
		--sb.logInfo("Last Element Position = " .. sb.print(Position));
		local NextElementPosition = vec.add(Position,Offset);
		--sb.logInfo("Next Element Position = " .. sb.print(NextElementPosition));
		local NewChild = Argon.CreateElement("Mask",CanvasName,{NextElementPosition[1],NextElementPosition[2],NextElementPosition[1] + ElementSize[1],NextElementPosition[2] + ElementSize[2]});
		--AnchorPoint.SetPosition({0,0});
		AnchorPoint.AddChild(NewChild);
		NewChild.AddChild(Argon.CreateElement("ListImage",CanvasName,nil,ListImages,Element));
		--sb.logInfo("Rel Pos = " .. sb.print(NewChild.GetPosition()));
		--sb.logInfo("Abs Pos = " .. sb.print(NewChild.GetAbsolutePosition()));
		RecalculatePosition();
		--sb.logInfo("Anchor Position = " .. sb.print(AnchorPoint.GetPosition()));
		--sb.logInfo("Element Position = " .. sb.print(Element.GetPosition()));
		return NewChild;
	end);
	Element.AddControllerValue("RemoveElement",function(controller)
		--sb.logInfo("Controller = " .. sb.print(AnchorPoint));
		if AnchorPoint.RemoveChild(controller) == false then
			error("This List Element wasn't able to be removed");
		else
			--if SelectedElement ~= nil and SelectedElement.GetController() == controller then
				Element.SetSelectedElement(nil);
			--end
			controller.Delete();
			PositionElements();
			RecalculatePosition();
		end
	end);

	Element.AddControllerValue("GetElementIndex",function(controller)
		for k,i in AnchorElement.ChildrenIter() do
			if i.GetController() == controller then
				return k;
			end
		end
	end);

	Element.AddControllerValue("GetSelectedElement",function()
		if SelectedElement ~= nil then
			return SelectedElement.Parent.GetController();
		end
	end);

	Element.AddControllerValue("OnSelectedElementChange",function(func)
		OnSelectedElementChange = func;
	end);

	Element.AddControllerValue("RemoveLast",function()
		if AnchorPoint.GetChildCount() > 0 then
			local LastChild = AnchorPoint.GetLastChild();
			if LastChild ~= nil then
				--if SelectedElement == LastChild then
					Element.SetSelectedElement(nil);
				--end
				Element.GetController().RemoveElement(LastChild);
				--[[AnchorPoint.RemoveChild(LastChild);
				LastChild.Delete();
				PositionElements();--]]
			end
		end
	end);

	Element.AddControllerValue("MoveElementUp",function(controller)
		Element.SetSelectedElement(nil);
		AnchorPoint.MoveChildUp(controller);
		PositionElements();
		RecalculatePosition();
	end);

	Element.AddControllerValue("MoveElementDown",function(controller)
		Element.SetSelectedElement(nil);
		AnchorPoint.MoveChildDown(controller);
		PositionElements();
		RecalculatePosition();
	end);

	Element.AddControllerValue("ClearList",function()
		Element.SetSelectedElement(nil);
		AnchorPoint.RemoveAllChildren(true);
		PositionElements();
		RecalculatePosition();
	end);

	Element.AddControllerValue("SetElementActive",function(controller,active)
		if controller.Active() ~= active then
			controller.SetActive(active);
			PositionElements();
			RecalculatePosition();
		end
	end);

	Element.AddControllerValue("ElementCount",function()
		return AnchorPoint.GetChildCount();
	end);

	Element.AddControllerValue("GetValue",function()
		return Value;
	end);

	Element.AddControllerValue("SetValue",function(value)
		if value > 1 then
			value = 1;
		elseif value < 0 then
			value = 0;
		end
		Value = value;
		RecalculatePosition();
	end);

	Element.AddControllerValue("SetScrollbar",function(scrollbar)
		Scrollbar = scrollbar;
		if Scrollbar ~= nil then
			Scrollbar.OnValueChange(function(value)
				Value = value;
				RecalculatePosition();
			end);
			Scrollbar.OnDelete(function()
				Scrollbar = nil;
			end);
		end
	end);

	Element.AddControllerValue("RemoveScrollbar",function()
		if Scrollbar ~= nil then
			Scrollbar.OnDelete(nil);
			Scrollbar.OnValueChange(nil);
			Scrollbar = nil;
		end
	end);

	Element.OnFinish(function()
		AnchorPoint = Argon.CreateElement("Anchor Point",CanvasName,{0,0});
		Element.AddChild(AnchorPoint);
		AnchorElement = Element.GetLastChild();
		StartPos = GetLastElementPosition();
		RecalculatePosition();
	end);

	if Scrollbar ~= nil then
		Scrollbar.OnValueChange(function(value)
			Value = value;
			RecalculatePosition();
		end);
		Scrollbar.OnDelete(function()
			Scrollbar = nil;
		end);
	end


	return Element;

end
