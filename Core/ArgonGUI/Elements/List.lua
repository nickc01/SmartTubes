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
	local ListArea = rect.copy(Rect);
	local Element = CreateElement(CanvasName);
	Element.SetPosition({Rect[1],Rect[2]});
	Element.SetParentMode(true);
	Element.SetClippingBounds(rect.minimize(Rect));

	local InactiveSize = root.imageSize(ListImages.Inactive);
	local ActiveSize = root.imageSize(ListImages.Active);
	local SelectedSize = root.imageSize(ListImages.Selected);

	local ElementSize = {math.max(InactiveSize[1],ActiveSize[1],SelectedSize[1]),math.max(InactiveSize[2],ActiveSize[2],SelectedSize[2])};

	local AnchorPoint;

	local Offset;

	--local WindowLength;


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

	--[[if Direction == "up" or Direction == "down" then
		WindowLength = Rect[4] - Rect[2];
	else
		WindowLength = Rect[3] - Rect[1];
	end--]]

	local function RecalculatePosition()
		local TopRect;
		local BottomRect;
		local FirstChildPos;
		local LastChildPos;
		local FirstChild = AnchorPoint.GetFirstChild();
		local LastChild = AnchorPoint.GetLastChild();
		if FirstChild == nil or LastChild == nil then
			return nil;
		else
			FirstChildPos = FirstChild.GetPosition();
			LastChildPos = LastChild.GetPosition();
		end
		if Direction == "up" or Direction == "down" then
			TopRect = {ListArea[1],ListArea[4] - ElementSize[2] - (math.max(FirstChildPos[2],LastChildPos[2]) - math.min(FirstChildPos[2],LastChildPos[2]) ),ListArea[3],ListArea[4] - ElementSize[2]};
			BottomRect = {ListArea[1],ListArea[2],ListArea[3],ListArea[2] + (TopRect[4] - TopRect[2])};
		else
			
		end
		local Final = rect.vecSub(RectLerp(TopRect,BottomRect,1 - Value),Element.GetAbsolutePosition());
		if Direction == "up" or Direction == "down" then
			AnchorPoint.SetPosition({Final[1],-Final[2],Final[3],(Final[4] - Final[2]) - Final[2]});
		else
			--AnchorPoint.SetPosition({Final[1],-Final[2],Final[3],(Final[4] - Final[2]) - Final[2]});
		end
	end

	local function GetLastElementPosition()
		if AnchorPoint.GetChildCount() > 0 then
			return AnchorPoint.GetLastChild().GetPosition();
		else
			if Direction == "up" then
				return {0,-ElementSize[2]};
			elseif Direction == "down" then
				return {0,ListArea[4]};
			elseif Direction == "left" then
				return {0,ListArea[3]};
			elseif Direction == "right" then
				return {-ElementSize[1],0};
			end
		end
	end

	Element.AddControllerValue("AddElement",function()
		local Position = GetLastElementPosition();
		sb.logInfo("Last Element Position = " .. sb.print(Position));
		local NextElementPosition = vec.add(Position,Offset);
		sb.logInfo("Next Element Position = " .. sb.print(NextElementPosition));
		local NewChild = Argon.CreateElement("Mask",CanvasName,{NextElementPosition[1],NextElementPosition[2],NextElementPosition[1] + ElementSize[1],NextElementPosition[2] + ElementSize[2]});
		AnchorPoint.AddChild(NewChild,true);
		NewChild.AddChild(Argon.CreateElement("Image",CanvasName,ListImages.Active,{0,0}));
		sb.logInfo("Rel Pos = " .. sb.print(NewChild.GetPosition()));
		sb.logInfo("Abs Pos = " .. sb.print(NewChild.GetAbsolutePosition()));
		return NewChild;
	end);
	Element.AddControllerValue("RemoveElement",function(controller)
		if Element.GetController().RemoveChild(controller) == false then
			error("This List Element wasn't able to be removed");
		else
			controller.Delete();
		end
	end);

	Element.AddControllerValue("GetValue",function()
		return Value;
	end);

	Element.AddControllerValue("SetValue",function()
		
	end);

	Element.OnFinish(function()
		AnchorPoint = Argon.CreateElement("Anchor Point",CanvasName,{0,0});
		Element.GetController().AddChild(AnchorPoint);
		RecalculatePosition();
	end);

	if Scrollbar ~= nil then
		Scrollbar.OnValueChange(function(value)
			Value = value;
			RecalculatePosition();
		end);
	end


	return Element;

end
