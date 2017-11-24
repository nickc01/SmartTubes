Creator = {};
local Creator = Creator;

local RotationMatrix = setmetatable({
	x1 = 0,y1 = -1,x2 = 1,y2 = 0
},{
	__mul = function(lhs,rhs)
		local tbl;
		if lhs.x1 ~= nil then
			tbl = rhs;
		else
			tbl = lhs;
		end
		if tbl[4] ~= nil then
			return {x1 * tbl[1] + y1 * tbl[2],x2 * tbl[1] + y2 * tbl[2],x1 * tbl[3] + y1 * tbl[4],x2 * tbl[3] + y2 * tbl[4]};
		elseif tbl[2] ~= nil then
			return {x1 * tbl[1] + y1 * tbl[2],x2 * tbl[1] + y2 * tbl[2]};
		end
	end
});

local function Lerp(A,B,T)
	return ((A - B) * T) + B;
end

local function Rectify(Pos,Size,IsCentered)
	if IsCentered == true then
		return {Pos[1] - (Size[1] / 2),Pos[2] - (Size[2] / 2),Pos[1] + (Size[1] / 2), Pos[2] + (Size[2] / 2)};
	else
		return {Pos[1],Pos[2],Pos[1] + Size[1],Pos[2] + Size[2]};
	end
end

local function RectMin(rect)
	return {0,0,rect[3] - rect[1],rect[4] - rect[2]};
end

local function SetScrollerRect(RectMax,Size,Value,Mode)
	if Size < 1 then
		Size = 1;
	end
	if Value < 0 then
		Value = 0;
	elseif Value > 1 then
		Value = 1;
	end
	if Mode == "Vertical" then
		local Rect = {RectMax[1],RectMax[2],RectMax[3],RectMax[4] / Size};
		local RectTop = {RectMax[1],RectMax[4] - (Rect[4] - Rect[2]),RectMax[3],RectMax[4]};
		return {0,Lerp(RectTop[2],Rect[2],Value),RectMax[3],Lerp(RectTop[4],Rect[4],Value)};
	elseif Mode == "Horizontal" then
		local Rect = {RectMax[1],RectMax[2],RectMax[3] / Size,RectMax[4]};
		local RectTop = {RectMax[3] - (Rect[3] - Rect[1]),RectMax[2],RectMax[3],RectMax[4]};
		return {Lerp(RectTop[1],Rect[1],Value),0,Lerp(RectTop[3],Rect[3],Value),RectMax[4]};
	end
end
--[[
Canvas.AddScrollBar()
CanvasName: The Alias Name of the Canvas
Origin: The Origin Position of the Scrollbar
Length: If Mode is Horizontal, this is the Width, if vertical, this is the Height
Scroller: The Textures for the Scroller, in the form:
{
	ScrollerTop: The Top of the Scroller, or if Horizontal, the Right Side of the Scroller
	Scroller: The Main Part of the Scroller, this will be tiled to fit the Length of the Scroller
	ScrollerBottom: The Bottom of the Scroller, or if Horizontal, the Left Side of the Scroller
}
ScrollerBackground: The Textures for the Scroller Background, in the form:
{
	ScrollerTop: The Top of the Scroller Background, or if Horizontal, the Right Side of the Scroller Background
	Scroller: The Main Part of the Scroller Background, this will be tiled to fit the Length of the Scroller Background
	ScrollerBottom: The Bottom of the Scroller Background, or if Horizontal, the Left Side of the Scroller Background
}
Arrows: The Textures for the Arrows, in the form:
{
	Top: The Image for the Top Arrow, or if Horizontal, the Right Arrow
	Bottom: The Image for the Bottom Arrow, or if Horizontal, the Left Arrow
}
Mode: The Type of Scroller, possible values are
{
	Horizontal: For a Horizontal Scrollbar
	Vertical: For a Vertical Scrollbar
}
]]

function Creator.Create(CanvasName,Rect,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue)
	InitialSize = InitialSize or 1;
	InitialValue = InitialValue or 0;
	sb.logInfo("Horizontal = " .. sb.print(Mode));
	if not (Mode == "Horizontal" or Mode == "Vertical") then
		error("Scrollbar Mode is Invalid");
	end
	local Element = CreateElement(CanvasName);
	local Position = {Rect[1],Rect[2]};
	local LocalRect = {Rect[1] - Position[1],Rect[2] - Position[2],Rect[3] - Position[1],Rect[4] - Position[2]};

	local BottomArrowSize = root.imageSize(Arrows.Bottom);
	local TopArrowSize = root.imageSize(Arrows.Top);
	local BackgroundScrollerTopSize = root.imageSize(ScrollerBackground.ScrollerTop);
	local BackgroundScrollerBottomSize = root.imageSize(ScrollerBackground.ScrollerBottom);

	local BottomArrow;
	local TopArrow;
	local BackgroundScrollerTop;
	local BackgroundScrollerBottom;
	local BackgroundScroller;
	if Mode == "Vertical" then
		BottomArrow = {LocalRect[1],LocalRect[2],LocalRect[3],LocalRect[2] + BottomArrowSize[2]};
		TopArrow = {LocalRect[1],LocalRect[4] - TopArrowSize[2],LocalRect[3],LocalRect[4]};
		BackgroundScrollerTop = {LocalRect[1],TopArrow[2] - BackgroundScrollerTopSize[2],LocalRect[3],TopArrow[2]};
		BackgroundScrollerBottom = {LocalRect[1],BottomArrow[4],LocalRect[3],BottomArrow[4] + BackgroundScrollerBottomSize[2]};
		BackgroundScroller = {BackgroundScrollerBottom[1],BackgroundScrollerBottom[4],BackgroundScrollerTop[3],BackgroundScrollerTop[2]};
	else
		--TODO
		BottomArrow = {LocalRect[1],LocalRect[2],LocalRect[1] + BottomArrowSize[1],LocalRect[4]};
		TopArrow = {LocalRect[3] - TopArrowSize[1],LocalRect[2],LocalRect[3],LocalRect[4]};
		BackgroundScrollerTop = {TopArrow[1] - BackgroundScrollerTopSize[1],TopArrow[2],TopArrow[1],TopArrow[4]};
		BackgroundScrollerBottom = {BottomArrow[3],BottomArrow[2],BottomArrow[3] + BackgroundScrollerBottomSize[1],BottomArrow[4]};
		BackgroundScroller = {BackgroundScrollerBottom[3],BackgroundScrollerBottom[2],BackgroundScrollerTop[1],BackgroundScrollerTop[4]};
	end

	local ScrollRectArea = rect.copy(BackgroundScroller);
	--Setting Scroller
	local ScrollRect = SetScrollerRect(ScrollRectArea,InitialSize,InitialValue,Mode);
	local ScrollerTopSize = root.imageSize(Scroller.ScrollerTop);
	local ScrollerBottomSize = root.imageSize(Scroller.ScrollerBottom);
	local ScrollerBottom;
	local ScrollerTop;
	if Mode == "Vertical" then
		ScrollerBottom = {ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2],ScrollRect[3],ScrollRect[2]};
		ScrollerTop = {ScrollRect[1],ScrollRect[4],ScrollRect[3],ScrollRect[4] + ScrollerTopSize[2]};
		Element.Length = ((ScrollRectArea[4] - ScrollRectArea[2]) / InitialSize);
	else
		ScrollerBottom = {ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2],ScrollRect[1],ScrollRect[4]};
		ScrollerTop = {ScrollRect[3],ScrollRect[2],ScrollRect[3] + ScrollerTopSize[1],ScrollRect[4]};
		Element.Length = ((ScrollRectArea[3] - ScrollRectArea[1]) / InitialSize);
	end

	--If Horizontal,then rotate Right
	--[[if Mode == "Horizontal" then
		--TODO
	end--]]

	--Set Position
	Element.SetPosition(Position);

	--Add Drawables 
	Element.AddDrawable("BottomArrow",BottomArrow,Arrows.Bottom);
	Element.AddDrawable("TopArrow",TopArrow,Arrows.Top);
	Element.AddDrawable("BackgroundScrollerTop",BackgroundScrollerTop,ScrollerBackground.ScrollerTop);
	Element.AddDrawable("BackgroundScrollerBottom",BackgroundScrollerBottom,ScrollerBackground.ScrollerBottom);
	Element.AddDrawable("BackgroundScroller",BackgroundScroller,ScrollerBackground.Scroller,true);
	Element.AddDrawable("ScrollerTop",ScrollerTop,Scroller.ScrollerTop);
	Element.AddDrawable("ScrollerBottom",ScrollerBottom,Scroller.ScrollerBottom);
	Element.AddDrawable("Scroller",ScrollRect,Scroller.Scroller,true);

	local function RecalculateScrollValues()
		local ScrollRect;
		local ScrollerBottom;
		local ScrollerTop;
		if Mode == "Vertical" then
			ScrollRect = SetScrollerRect(ScrollRectArea,Element.Size,Element.Value,Mode);
			ScrollerBottom = {ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2],ScrollRect[3],ScrollRect[2]};
			ScrollerTop = {ScrollRect[1],ScrollRect[4],ScrollRect[3],ScrollRect[4] + ScrollerTopSize[2]};
		else
			ScrollRect = SetScrollerRect(ScrollRectArea,Element.Size,Element.Value,Mode);
			ScrollerBottom = {ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2],ScrollRect[1],ScrollRect[4]};
			ScrollerTop = {ScrollRect[3],ScrollRect[2],ScrollRect[3] + ScrollerTopSize[1],ScrollRect[4]};
		end

		Element.SetDrawableRect("ScrollerTop",ScrollerTop);
		Element.SetDrawableRect("ScrollerBottom",ScrollerBottom);
		Element.SetDrawableRect("Scroller",ScrollRect);
	end
	Element.Size = InitialSize;
	Element.Value = InitialValue;
	--Add Controller Functions

	Element.AddControllerValue("GetSliderSize",function()
		return Element.Size;
	end);

	Element.AddControllerValue("SetSliderSize",function(NewSize)
		if NewSize < 1 then
			NewSize = 1;
		end
		Element.Size = NewSize;
		RecalculateScrollValues()
	end);

	Element.AddControllerValue("SetSliderValue",function(NewValue)
		if NewValue < 0 then
			NewValue = 0;
		elseif NewValue > 1 then
			NewValue = 1;
		end
		Element.Value = NewValue;
		RecalculateScrollValues()
	end);
	Element.AddControllerValue("GetSliderValue",function()
		return Element.Value;
	end);
	Element.AddControllerValue("GetLength",function()
		return Element.Length;
	end);
	Element.AddControllerValue("SetToMousePosition",function()
		if Mode == "Vertical" then
			Element.GetController().SetSliderValue((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[2] - (Element.Length / 2)) / ((ScrollRectArea[4] - ScrollRectArea[2]) - Element.Length));
		elseif Mode == "Horizontal" then
			Element.GetController().SetSliderValue((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[1] - (Element.Length / 2)) / ((ScrollRectArea[3] - ScrollRectArea[1]) - Element.Length));
		end
	end);
	return Element.Finish();
end

--[[function Creator.CreateOLD(CanvasName,Origin,Length,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue)
	InitialSize = InitialSize or 1;
	InitialValue = InitialValue or 0;
	if Origin[3] ~= nil and Origin[4] ~= nil then
		local Length;
		if Mode == "Vertical" then
			Length = Origin[4] - Origin[2];
		elseif Mode == "Horizontal" then
			Length = Origin[3] - Origin[1];
		end
		return Creator.Create(CanvasName,{Origin[3] - ((Origin[3] - Origin[1]) / 2),Origin[4] - ((Origin[4] - Origin[2]) / 2)},Length,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue);
	end
	local Element = CreateElement(CanvasName);
	if Mode ~= nil then
		local Size;
		if Mode == "Vertical" then
			Size = {math.max(root.imageSize(Scroller.Scroller)[1],root.imageSize(ScrollerBackground.Scroller)[1]),Length};
		elseif Mode == "Horizontal" then
			Size = {Length,math.max(root.imageSize(Scroller.Scroller)[2],root.imageSize(ScrollerBackground.Scroller)[2])};
		end
		local ScrollBarBottomLeft = {math.floor(Origin[1] - (Size[1] / 2)),math.floor(Origin[2] - (Size[2] / 2))};
		local ScrollBarTopRight = {ScrollBarBottomLeft[1] + Size[1],ScrollBarBottomLeft[2] + Size[2]};

		local BottomArrowSize = root.imageSize(Arrows.Bottom);
		local BottomArrowCenter;
		if Mode == "Vertical" then
			BottomArrowCenter = {Origin[1],ScrollBarBottomLeft[2] + (BottomArrowSize[2] / 2)};
		elseif Mode == "Horizontal" then
			BottomArrowCenter = {ScrollBarBottomLeft[1] + (BottomArrowSize[1] / 2),Origin[2]};
		end
		Element.AddDrawable("BottomArrow",Rectify(BottomArrowCenter,BottomArrowSize,true),Arrows.Bottom);

		local TopArrowSize = root.imageSize(Arrows.Top);
		local TopArrowCenter;
		if Mode == "Vertical" then
			TopArrowCenter = {Origin[1],ScrollBarTopRight[2] - (TopArrowSize[2] / 2)};
		elseif Mode == "Horizontal" then
			TopArrowCenter = {ScrollBarTopRight[1] - (TopArrowSize[1] / 2),Origin[2]};
		end

		Element.AddDrawable("TopArrow",Rectify(TopArrowCenter,TopArrowSize,true),Arrows.Top);
		local ScrollArea;
		if Mode == "Vertical" then
			ScrollArea = {ScrollBarBottomLeft[1],ScrollBarBottomLeft[2] + BottomArrowSize[2],ScrollBarTopRight[1],ScrollBarTopRight[2] - TopArrowSize[2]};
		elseif Mode == "Horizontal" then
			ScrollArea = {ScrollBarBottomLeft[1] + BottomArrowSize[1],ScrollBarBottomLeft[2],ScrollBarTopRight[1] - TopArrowSize[1],ScrollBarTopRight[2]};
		end

		local BackgroundScrollerBottomSize = root.imageSize(ScrollerBackground.ScrollerBottom);
		local BackgroundScrollerBottomPos;
		if Mode == "Vertical" then
			BackgroundScrollerBottomPos = {Origin[1],ScrollArea[2] + (BackgroundScrollerBottomSize[2] / 2)};
		elseif Mode == "Horizontal" then
			BackgroundScrollerBottomPos = {ScrollArea[1] + (BackgroundScrollerBottomSize[1] / 2),Origin[2]};
		end

		Element.AddDrawable("BackgroundScrollerBottom",Rectify(BackgroundScrollerBottomPos,BackgroundScrollerBottomSize,true),ScrollerBackground.ScrollerBottom);

		local BackgroundScrollerTopSize = root.imageSize(ScrollerBackground.ScrollerTop);
		local BackgroundScrollerTopPos;
		if Mode == "Vertical" then
			BackgroundScrollerTopPos = {Origin[1],ScrollArea[4] - (BackgroundScrollerTopSize[2] / 2)};
		elseif Mode == "Horizontal" then
			BackgroundScrollerTopPos = {ScrollArea[3] - (BackgroundScrollerTopSize[1] / 2),Origin[2]};
		end

		Element.AddDrawable("BackgroundScrollerTop",Rectify(BackgroundScrollerTopPos,BackgroundScrollerTopSize,true),ScrollerBackground.ScrollerTop);

		if Mode == "Vertical" then
			ScrollArea = {ScrollArea[1],ScrollArea[2] + BackgroundScrollerBottomSize[2],ScrollArea[3],ScrollArea[4] - BackgroundScrollerTopSize[2]};
		elseif Mode == "Horizontal" then
			ScrollArea = {ScrollArea[1] + BackgroundScrollerBottomSize[1],ScrollArea[2],ScrollArea[3] - BackgroundScrollerTopSize[1],ScrollArea[4]};
		end

		local BackgroundScrollerSize = root.imageSize(ScrollerBackground.Scroller);
		local ScrollerSize = root.imageSize(Scroller.Scroller);

		local BackgroundScrollerRect;
		if Mode == "Vertical" then
			BackgroundScrollerRect = {Origin[1] - (BackgroundScrollerSize[1] / 2),ScrollArea[2],Origin[1] + (BackgroundScrollerSize[1] / 2),ScrollArea[4]};
		elseif Mode == "Horizontal" then
			BackgroundScrollerRect = {ScrollArea[1],Origin[2] - (BackgroundScrollerSize[2] / 2),ScrollArea[3],Origin[2] + (BackgroundScrollerSize[2] / 2)};
		end

		Element.AddDrawable("BackgroundScroller",BackgroundScrollerRect,ScrollerBackground.Scroller,true);

		local ScrollerStart;
		local ScrollerRegion;
		local ScrollRect;
		if Mode == "Vertical" then
			ScrollerStart = {Origin[1] - (ScrollerSize[1] / 2),BackgroundScrollerRect[2],Origin[1] + (ScrollerSize[1] / 2),BackgroundScrollerRect[4]};
			ScrollerRegion = {0,0,ScrollerSize[1],ScrollerStart[4] - ScrollerStart[2]};
		elseif Mode == "Horizontal" then
			ScrollerStart = {BackgroundScrollerRect[1],Origin[2] - (ScrollerSize[2] / 2),BackgroundScrollerRect[3],Origin[2] + (ScrollerSize[2] / 2)};
			ScrollerRegion = {0,0,ScrollerStart[3] - ScrollerStart[1],ScrollerSize[2]};
		end

		local ScrollRect = SetScrollerRect(ScrollerRegion,InitialSize,InitialValue,Mode);

		local ScrollerBottomSize = root.imageSize(Scroller.ScrollerBottom);
		local ScrollerTopSize = root.imageSize(Scroller.ScrollerTop);

		Element.AddDrawable("Scroller",rect.vecAdd(ScrollRect,ScrollerStart),Scroller.Scroller,true);
		local TopScrollerPos;
		local BottomScrollerPos;
		if Mode == "Vertical" then
			TopScrollerPos = Rectify(vec.add({ScrollRect[1],ScrollRect[4]},ScrollerStart),ScrollerTopSize);
			BottomScrollerPos = Rectify(vec.add({ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2]},ScrollerStart),ScrollerBottomSize);
			Element.Length = (ScrollerRegion[4] / InitialSize);
		elseif Mode == "Horizontal" then
			TopScrollerPos = Rectify(vec.add({ScrollRect[3],ScrollRect[2]},ScrollerStart),ScrollerTopSize);
			BottomScrollerPos = Rectify(vec.add({ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2]},ScrollerStart),ScrollerBottomSize);
			Element.Length = (ScrollerRegion[3] / InitialSize);
		end

		Element.AddDrawable("ScrollerTop",TopScrollerPos,Scroller.ScrollerTop);
		Element.AddDrawable("ScrollerBottom",BottomScrollerPos,Scroller.ScrollerBottom);

		local ElementPosition = Element.GetPosition();
		Element.ScrollerData = {
			Region = rect.vecSub(rect.vecAdd(ScrollerRegion,ScrollerStart),ElementPosition),
			Size = InitialSize,
			Value = InitialValue,
			Mode = Mode,
		}

		local function CalculateScrollerValues()
			local ScrollRect = SetScrollerRect(Element.ScrollerData.Region,Element.ScrollerData.Size,Element.ScrollerData.Value,Element.ScrollerData.Mode);
			local TopScrollerPos;
			local BottomScrollerPos;
			if Element.ScrollerData.Mode == "Vertical" then
				TopScrollerPos = {ScrollRect[1],ScrollRect[4],ScrollRect[1] + ScrollerTopSize[1],ScrollRect[4] + ScrollerTopSize[2]};
				BottomScrollerPos = {ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2],ScrollRect[1] + ScrollerBottomSize[1],ScrollRect[2]};
			elseif Element.ScrollerData.Mode == "Horizontal" then
				TopScrollerPos = {ScrollRect[3],ScrollRect[2],ScrollRect[3] + ScrollerTopSize[1],ScrollRect[2] + ScrollerTopSize[2]};
				BottomScrollerPos = {ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2],ScrollRect[1],ScrollRect[2] + ScrollerBottomSize[2]};
			end
			Element.SetDrawableRect("Scroller",ScrollRect);
			Element.SetDrawableRect("ScrollerTop",TopScrollerPos);
			Element.SetDrawableRect("ScrollerBottom",BottomScrollerPos);
		end

		Element.AddControllerValue("GetSliderSize",function()
			return Element.ScrollerData.Size;
		end);

		Element.AddControllerValue("SetSliderSize",function(NewSize)
			if NewSize < 1 then
				NewSize = 1;
			end
			Element.ScrollerData.Size = NewSize;
			CalculateScrollerValues();
		end);

		Element.AddControllerValue("SetSliderValue",function(NewValue)
			if NewValue < 0 then
				NewValue = 0;
			elseif NewValue > 1 then
				NewValue = 1;
			end
			Element.ScrollerData.Value = NewValue;
			CalculateScrollerValues();
		end);
		Element.AddControllerValue("GetSliderValue",function()
			return Element.ScrollerData.Value;
		end);
		Element.AddControllerValue("GetLength",function()
			return Element.Length;
		end);
		Element.AddControllerValue("SetToMousePosition",function()
			if Element.ScrollerData.Mode == "Vertical" then
				Element.GetController().SetSliderValue((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[2] - (Element.Length / 2)) / (ScrollerRegion[4] -Element.GetController().GetLength()));
			elseif Element.ScrollerData.Mode == "Horizontal" then
				Element.GetController().SetSliderValue((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[1] - (Element.Length / 2)) / (ScrollerRegion[3] -Element.GetController().GetLength()));
			end
		end);
		return Element.Finish();
	end
end--]]
