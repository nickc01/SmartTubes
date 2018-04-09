Creator = {};
local Creator = Creator;

local function Lerp(A,B,T)
	return ((A - B) * T) + B;
end

local function SetScrollerRect(RectMax,Size,Value,Mode,MinSize)
	MinSize = MinSize or 3;
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
		if (Rect[4] - Rect[2]) < MinSize then
			Rect[4] = Rect[2] + MinSize;
		end
		local RectTop = {RectMax[1],RectMax[4] - (Rect[4] - Rect[2]),RectMax[3],RectMax[4]};
		return {0,Lerp(RectTop[2],Rect[2],Value),RectMax[3],Lerp(RectTop[4],Rect[4],Value)},Rect,RectTop;
	elseif Mode == "Horizontal" then
		local Rect = {RectMax[1],RectMax[2],RectMax[3] / Size,RectMax[4]};
		if (Rect[3] - Rect[1]) < MinSize then
			Rect[3] = Rect[1] + MinSize;
		end
		local RectTop = {RectMax[3] - (Rect[3] - Rect[1]),RectMax[2],RectMax[3],RectMax[4]};
		return {Lerp(RectTop[1],Rect[1],Value),0,Lerp(RectTop[3],Rect[3],Value),RectMax[4]},Rect,RectTop;
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
	ScrollerTopHL: The Top of the Scroller when highlighted, or if Horizontal, the Right Side of the Scroller
	ScrollerHL: The Main Part of the Scroller when highlighted, this will be tiled to fit the Length of the Scroller
	ScrollerBottomHL: The Bottom of the Scroller when highlighted, or if Horizontal, the Left Side of the Scroller
}
ScrollerBackground: The Textures for the Scroller Background, in the form:
{
	ScrollerTop: The Top of the Scroller Background, or if Horizontal, the Right Side of the Scroller Background
	Scroller: The Main Part of the Scroller Background, this will be tiled to fit the Length of the Scroller Background
	ScrollerBottom: The Bottom of the Scroller Background, or if Horizontal, the Left Side of the Scroller Background
	ScrollerTopHL: The Top of the Scroller Background when highlighted, or if Horizontal, the Right Side of the Scroller Background
	ScrollerHL: The Main Part of the Scroller Background when highlighted, this will be tiled to fit the Length of the Scroller Background
	ScrollerBottomHL: The Bottom of the Scroller Background when highlighted, or if Horizontal, the Left Side of the Scroller Background
}
Arrows: The Textures for the Arrows, in the form:
{
	Top: The Image for the Top Arrow, or if Horizontal, the Right Arrow
	Bottom: The Image for the Bottom Arrow, or if Horizontal, the Left Arrow
	TopHL: The Image for the Top Arrow when highlighted, or if Horizontal, the Right Arrow
	BottomHL: The Image for the Bottom Arrow when highlighted, or if Horizontal, the Left Arrow
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
		BottomArrow = {LocalRect[1],LocalRect[2],LocalRect[1] + BottomArrowSize[1],LocalRect[4]};
		TopArrow = {LocalRect[3] - TopArrowSize[1],LocalRect[2],LocalRect[3],LocalRect[4]};
		BackgroundScrollerTop = {TopArrow[1] - BackgroundScrollerTopSize[1],TopArrow[2],TopArrow[1],TopArrow[4]};
		BackgroundScrollerBottom = {BottomArrow[3],BottomArrow[2],BottomArrow[3] + BackgroundScrollerBottomSize[1],BottomArrow[4]};
		BackgroundScroller = {BackgroundScrollerBottom[3],BackgroundScrollerBottom[2],BackgroundScrollerTop[1],BackgroundScrollerTop[4]};
	end

	local ScrollRectTopCenter;
	local ScrollRectBottomCenter;

	local ScrollRectArea = rect.copy(BackgroundScroller);
	--Setting Scroller
	local ScrollRect,ScrollRectTopCenter,ScrollRectBottomCenter = SetScrollerRect(ScrollRectArea,InitialSize,InitialValue,Mode);

	ScrollRectBottomCenter = rect.center(ScrollRectBottomCenter);
	ScrollRectTopCenter = rect.center(ScrollRectTopCenter);

	local ScrollerTopSize = root.imageSize(Scroller.ScrollerTop);
	local ScrollerBottomSize = root.imageSize(Scroller.ScrollerBottom);
	local ScrollerBottom;
	local ScrollerTop;
	if Mode == "Vertical" then
		ScrollerBottom = {ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2],ScrollRect[3],ScrollRect[2]};
		ScrollerTop = {ScrollRect[1],ScrollRect[4],ScrollRect[3],ScrollRect[4] + ScrollerTopSize[2]};
		Element.Length = ((ScrollRectArea[4] - ScrollRectArea[2]) / InitialSize);
		--Element.Length = Element.Length - ScrollerTopSize[2] - ScrollerBottomSize[2];
	else
		ScrollerBottom = {ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2],ScrollRect[1],ScrollRect[4]};
		ScrollerTop = {ScrollRect[3],ScrollRect[2],ScrollRect[3] + ScrollerTopSize[1],ScrollRect[4]};
		Element.Length = ((ScrollRectArea[3] - ScrollRectArea[1]) / InitialSize);
		--Element.Length = Element.Length - ScrollerTopSize[1] - ScrollerBottomSize[1];
	end

	--Set Position
	Element.SetPosition(Position);

	--Add Sprites 
	Element.AddSprite("BottomArrow",BottomArrow,Arrows.Bottom);
	Element.AddSprite("TopArrow",TopArrow,Arrows.Top);
	Element.AddSprite("BackgroundScrollerTop",BackgroundScrollerTop,ScrollerBackground.ScrollerTop);
	Element.AddSprite("BackgroundScrollerBottom",BackgroundScrollerBottom,ScrollerBackground.ScrollerBottom);
	Element.AddSprite("BackgroundScroller",BackgroundScroller,ScrollerBackground.Scroller,true);
	Element.AddSprite("ScrollerTop",ScrollerTop,Scroller.ScrollerTop);
	Element.AddSprite("ScrollerBottom",ScrollerBottom,Scroller.ScrollerBottom);
	Element.AddSprite("Scroller",ScrollRect,Scroller.Scroller,true);
	local OnValueChange;

	local function RecalculateScrollValues()
		local ScrollRect;
		local ScrollerBottom;
		local ScrollerTop;

		ScrollRect,ScrollRectBottomCenter,ScrollRectTopCenter = SetScrollerRect(ScrollRectArea,Element.Size,Element.Value,Mode);
		ScrollRectBottomCenter = rect.center(ScrollRectBottomCenter);
		ScrollRectTopCenter = rect.center(ScrollRectTopCenter);

		if Mode == "Vertical" then
			--[[ScrollRect,ScrollRectBottomCenter,ScrollRectTopCenter = SetScrollerRect(ScrollRectArea,Element.Size,Element.Value,Mode);
			ScrollRectBottomCenter = rect.center(ScrollRectBottomCenter);
			ScrollRectTopCenter = rect.center(ScrollRectTopCenter);--]]
			ScrollerBottom = {ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2],ScrollRect[3],ScrollRect[2]};
			ScrollerTop = {ScrollRect[1],ScrollRect[4],ScrollRect[3],ScrollRect[4] + ScrollerTopSize[2]};
		else
			ScrollerBottom = {ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2],ScrollRect[1],ScrollRect[4]};
			ScrollerTop = {ScrollRect[3],ScrollRect[2],ScrollRect[3] + ScrollerTopSize[1],ScrollRect[4]};
		end

		Element.SetSpriteRect("ScrollerTop",ScrollerTop);
		Element.SetSpriteRect("ScrollerBottom",ScrollerBottom);
		
		Element.SetSpriteRect("Scroller",ScrollRect);
	end
	Element.Size = InitialSize;
	Element.Value = InitialValue;
	--Add Controller Functions


	Element.AddControllerValue("GetSliderSize",function()
		return Element.Size;
	end);

	local HideWhenNecessary = false;

	Element.AddControllerValue("SetSliderSize",function(NewSize)
		if NewSize < 1 then
			NewSize = 1;
		end
		if NewSize ~= Element.Size then
			Element.Size = NewSize;
			RecalculateScrollValues();
			if HideWhenNecessary == true then
				if Element.Size > 1 then
					Element.SetActive(true);
				else
					Element.SetActive(false);
				end
			end
			--[[if OnValueChange ~= nil then
				OnValueChange(Element.Value);
			end--]]
		end
	end);

	Element.AddControllerValue("SetSliderValue",function(NewValue)
		if NewValue < 0 then
			NewValue = 0;
		elseif NewValue > 1 then
			NewValue = 1;
		end
		
		
		if NewValue ~= Element.Value then
			Element.Value = NewValue;
			RecalculateScrollValues();
			if OnValueChange ~= nil then
				OnValueChange(Element.Value);
			end
		end
	end);
	Element.AddControllerValue("ChangeSliderValue",function(Diff)
		Element.GetController().SetSliderValue(Element.GetController().GetSliderValue() + Diff);
	end);


	Element.AddControllerValue("GetSliderValue",function()
		return Element.Value;
	end);
	Element.AddControllerValue("GetLength",function()
		return Element.Length;
	end);
	Element.AddControllerValue("SetToMousePosition",function(Offset)
		if Element.Size > 1 then
			Offset = Offset or 0;
			local AbsolutePosition = Element.GetAbsolutePosition();
			local BackgroundScrollerPos = vec.add(AbsolutePosition,ScrollRectArea);
			local MousePosition = Element.GetCanvas():mousePosition();
			if Mode == "Vertical" then
				local Value = (MousePosition[2] - ((ScrollRect[4] - ScrollRect[2]) / 2) - BackgroundScrollerPos[2]) / (ScrollRectTopCenter[2] - ScrollRectBottomCenter[2]);
				Element.GetController().SetSliderValue(Offset + Value);
				--Element.GetController().SetSliderValue(Offset + ((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[2]--[[ - (Element.Length / 2)--]]) / ((ScrollRectArea[4] - ScrollRectArea[2]) - Element.Length)));
			elseif Mode == "Horizontal" then
				local Value = (MousePosition[1] - ((ScrollRect[3] - ScrollRect[1]) / 2) - BackgroundScrollerPos[1]) / (ScrollRectTopCenter[1] - ScrollRectBottomCenter[1]);
				Element.GetController().SetSliderValue(Offset + Value);
				--Element.GetController().SetSliderValue(Offset + ((vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[1]--[[ - (Element.Length / 2)--]]) / ((ScrollRectArea[3] - ScrollRectArea[1]) - Element.Length)));
			end
		end
	end);
	Element.AddControllerValue("GetValueAtMousePosition",function()
		local AbsolutePosition = Element.GetAbsolutePosition();
		local BackgroundScrollerPos = vec.add(AbsolutePosition,ScrollRectArea);
		local MousePosition = Element.GetCanvas():mousePosition();
		if Mode == "Vertical" then
			return (MousePosition[2] - ((ScrollRect[4] - ScrollRect[2]) / 2) - BackgroundScrollerPos[2]) / (ScrollRectTopCenter[2] - ScrollRectBottomCenter[2]);
			--return (vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[2]--[[ - (Element.Length / 2)--]]) / ((ScrollRectArea[4] - ScrollRectArea[2]) - Element.Length);
		elseif Mode == "Horizontal" then
			return (MousePosition[1] - ((ScrollRect[3] - ScrollRect[1]) / 2) - BackgroundScrollerPos[1]) / (ScrollRectTopCenter[1] - ScrollRectBottomCenter[1]);
			--return (vec.sub(Element.GetCanvas():mousePosition(),Element.GetController().GetAbsolutePosition())[1]--[[ - (Element.Length / 2)--]]) / ((ScrollRectArea[3] - ScrollRectArea[1]) - Element.Length);
		end
	end);

	Element.AddControllerValue("HideWhenNecessary",function(bool)
		HideWhenNecessary = bool;
		if HideWhenNecessary == true then
			if Element.Size > 1 then
				Element.SetActive(true);
			else
				Element.SetActive(false);
			end
		end
	end);

	Element.AddControllerValue("OnValueChange",function(func)
		OnValueChange = func;
	end);

	local ScrollerClicked = false;
	local ScrollerOffset;
	local TopArrowClicked = false;
	local BottomArrowClicked = false;

	Element.SetUpdateFunction(function(dt)
		if ScrollerClicked == true then
			
			
			Element.GetController().SetToMousePosition(-ScrollerOffset);
			
		end
		if TopArrowClicked == true and Element.Size > 1 then
			Element.GetController().ChangeSliderValue((1 / Element.GetController().GetSliderSize()) * dt);
		end
		if BottomArrowClicked == true and Element.Size > 1 then
			Element.GetController().ChangeSliderValue(-(1 / Element.GetController().GetSliderSize()) * dt);
		end
	end);

	Element.SetSpriteClickFunction("Scroller",function(Position,MouseType,IsDown)
		
		if MouseType == 0 then
			
			ScrollerOffset = Element.GetController().GetValueAtMousePosition() - Element.GetController().GetSliderValue();
			ScrollerClicked = IsDown;
			if IsDown == true then
				if Scroller.ScrollerHL ~= nil then
					Element.SetSpriteImage("Scroller",Scroller.ScrollerHL);
				end
				if Scroller.ScrollerBottomHL ~= nil then
					Element.SetSpriteImage("ScrollerBottom",Scroller.ScrollerBottomHL);
				end
				if Scroller.ScrollerTopHL ~= nil then
					Element.SetSpriteImage("ScrollerTop",Scroller.ScrollerTopHL);
				end
			else
				Element.SetSpriteImage("Scroller",Scroller.Scroller);
				Element.SetSpriteImage("ScrollerBottom",Scroller.ScrollerBottom);
				Element.SetSpriteImage("ScrollerTop",Scroller.ScrollerTop);
			end
		end
	end);
	Element.SetSpriteClickFunction("TopArrow",function(Position,MouseType,IsDown)
		if MouseType == 0 then
			TopArrowClicked = IsDown;
			if IsDown == true then
				if Arrows.TopHL ~= nil then
					Element.SetSpriteImage("TopArrow",Arrows.TopHL);
				end
			else
				Element.SetSpriteImage("TopArrow",Arrows.Top);
			end
		end
	end);

	Element.SetSpriteClickFunction("BottomArrow",function(Position,MouseType,IsDown)
		if MouseType == 0 then
			BottomArrowClicked = IsDown;
			if IsDown == true then
				if Arrows.TopHL ~= nil then
					Element.SetSpriteImage("BottomArrow",Arrows.BottomHL);
				end
			else
				Element.SetSpriteImage("BottomArrow",Arrows.Bottom);
			end
		end
	end);

	Element.OnFinish(function()
		RecalculateScrollValues();
	end);

	return Element;
end