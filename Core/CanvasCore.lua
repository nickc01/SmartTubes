CanvasCore = {};

local Canvases = {};

function CanvasCore.New()
	return require("/Core/CanvasCore.lua");
end

function CanvasCore.AddCanvas(CanvasName,AliasName)
	for k,i in pairs(Canvases) do
		if i.Name == CanvasName then
			error(sb.print(CanvasName) .. " is already Added under the Alias Name : " .. sb.print(k));
		end
	end
	local Binding = widget.bindCanvas(CanvasName);
	Canvases[AliasName] = {Canvas = Binding,Name = CanvasName,Elements = {}};
	return Binding;
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
local function Lerp(A,B,T)
	return ((A - B) * T) + B;
end

local function vecAdd(A,B,C)
	if C == nil then
		return {A[1] + B[1],A[2] + B[2]};
	else
		return {A[1] + B,A[2] + C};
	end
end
local function rectVectAdd(A,B)
	return {A[1] + B[1],A[2] + B[2],A[3] + B[1],A[4] + B[2]};
end
local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]}
end

local function SetScrollerRect(RectMax,Size,Position,Mode)
	if Size < 1 then
		Size = 1;
	end
	if Position < 0 then
		Position = 0;
	elseif Position > 1 then
		Position = 1;
	end
	if Mode == "Vertical" then
		local Rect = {0,0,RectMax[3],RectMax[4] / Size};
		local RectTop = {0,RectMax[4] - Rect[4],RectMax[3],RectMax[4]};
		return {0,Lerp(RectTop[2],Rect[2],Position),RectMax[3],Lerp(RectTop[4],Rect[4],Position)};
	end
end

function CanvasCore.AddScrollBar(CanvasName,Origin,Length,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue)
	InitialSize = InitialSize or 1;
	InitialValue = InitialValue or 0;
	if Origin[3] ~= nil and Origin[4] ~= nil then
		return CanvasCore.AddScrollBar(CanvasName,{Origin[3] - ((Origin[3] - Origin[1]) / 2),Origin[4] - ((Origin[4] - Origin[2]) / 2)},Origin[4] - Origin[2],Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue);
	end
	--sb.logInfo("Canvases = " .. sb.print(Canvases));
	local Canvas = Canvases[CanvasName].Canvas;
	local Element = {};
	local ElementController = {};
	if Mode == "Vertical" then
		local Size = {math.max(root.imageSize(Scroller.Scroller)[1],root.imageSize(ScrollerBackground.Scroller)[1]),Length};
		local ScrollBarBottomLeft = {math.floor(Origin[1] - (Size[1] / 2)),math.floor(Origin[2] - (Size[2] / 2))};
		local ScrollBarTopRight = {ScrollBarBottomLeft[1] + Size[1],ScrollBarBottomLeft[2] + Size[2]};
		--local ScrollBarRect = {ScrollBarBottomLeft[1],ScrollBarBottomLeft[2],ScrollBarTopRight[1],ScrollBarTopRight[2]};

		local BottomArrowSize = root.imageSize(Arrows.Bottom);
		local BottomArrowCenter = {Origin[1],ScrollBarBottomLeft[2] + (BottomArrowSize[2] / 2)};

		Element.BottomArrow = {
			Center = BottomArrowCenter,
			Image = Arrows.Bottom
		}

		local TopArrowSize = root.imageSize(Arrows.Top);
		local TopArrowCenter = {Origin[1],ScrollBarTopRight[2] - (TopArrowSize[2] / 2)};

		Element.TopArrow = {
			Center = TopArrowCenter,
			Image = Arrows.Top
		}
		local ScrollArea = {ScrollBarBottomLeft[1],ScrollBarBottomLeft[2] + BottomArrowSize[2],ScrollBarTopRight[1],ScrollBarTopRight[2] - TopArrowSize[2]};

		local BackgroundScrollerBottomSize = root.imageSize(ScrollerBackground.ScrollerBottom);

		local BackgroundScrollerBottomPos = {Origin[1],ScrollArea[2] + (BackgroundScrollerBottomSize[2] / 2)};

		Element.BackgroundScrollerBottom = {
			Center = BackgroundScrollerBottomPos,
			Image = ScrollerBackground.ScrollerBottom
		}

		local BackgroundScrollerTopSize = root.imageSize(ScrollerBackground.ScrollerTop);

		local BackgroundScrollerTopPos = {Origin[1],ScrollArea[4] - (BackgroundScrollerTopSize[2] / 2)};

		Element.BackgroundScrollerTop = {
			Center = BackgroundScrollerTopPos,
			Image = ScrollerBackground.ScrollerTop
		}

		ScrollArea = {ScrollArea[1],ScrollArea[2] + BackgroundScrollerBottomSize[2],ScrollArea[3],ScrollArea[4] - BackgroundScrollerTopSize[2]};

		local BackgroundScrollerSize = root.imageSize(ScrollerBackground.Scroller);
		local ScrollerSize = root.imageSize(Scroller.Scroller);

		local BackgroundScrollerRect = {Origin[1] - (BackgroundScrollerSize[1] / 2),ScrollArea[2],Origin[1] + (BackgroundScrollerSize[1] / 2),ScrollArea[4]};
		--local BackgrounmdScrollerRect = {Origin[1] - (ScrollerSize[1] / 2),ScrollArea[2],Origin[1] + (ScrollerSize[1] / 2),ScrollArea[4]};

		Element.BackgroundScroller = {
			Rect = BackgroundScrollerRect,
			Image = ScrollerBackground.Scroller
		}

		local ScrollerStart = {Origin[1] - (ScrollerSize[1] / 2),BackgroundScrollerRect[2],Origin[1] + (ScrollerSize[1] / 2),BackgroundScrollerRect[4]};

		local ScrollerRegion = {0,0,ScrollerSize[1],ScrollerStart[4] - ScrollerStart[2]};

		--Element.ScrollerOrigin = ScrollerStart;
		--Element.ScrollerRegion = ScrollerRegion;

		local ScrollRect = SetScrollerRect(ScrollerRegion,InitialSize,InitialValue,Mode);

		local ScrollerBottomSize = root.imageSize(Scroller.ScrollerBottom);
		local ScrollerTopSize = root.imageSize(Scroller.ScrollerTop);

		Element.Scroller = {
			Rect = rectVectAdd(ScrollRect,ScrollerStart),
			Image = Scroller.Scroller,
			Size = ScrollerBottomSize[2] + ScrollRect[4] - ScrollRect[2] + ScrollerTopSize[2],
			Top = {
				Position = vecAdd({ScrollRect[1],ScrollRect[4]},ScrollerStart),
				Image = Scroller.ScrollerTop
			},
			Bottom = {
				Position = vecAdd({ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2]},ScrollerStart),
				Image = Scroller.ScrollerBottom,
				Size = ScrollerBottomSize
			},
			Start = ScrollerStart,
			Region = ScrollerRegion
		}
		Element.Size = InitialSize;
		Element.Value = InitialValue;
		Element.Length = (ScrollerRegion[4] / InitialSize);
		--sb.logInfo("Length = " .. sb.print(Element.Length));
		--sb.logInfo("Size = " .. sb.print(InitialSize));
		Element.Mode = Mode;
		
		ElementController.Draw = function()
			Canvas:drawImage(Element.BottomArrow.Image,Element.BottomArrow.Center,nil,nil,true);
			Canvas:drawImage(Element.TopArrow.Image,Element.TopArrow.Center,nil,nil,true);
			Canvas:drawImage(Element.BackgroundScrollerBottom.Image,Element.BackgroundScrollerBottom.Center,nil,nil,true);
			Canvas:drawImage(Element.BackgroundScrollerTop.Image,Element.BackgroundScrollerTop.Center,nil,nil,true);
			Canvas:drawTiledImage(Element.BackgroundScroller.Image,{0,0},Element.BackgroundScroller.Rect);
			Canvas:drawTiledImage(Element.Scroller.Image,{0,0},Element.Scroller.Rect);
			Canvas:drawImage(Element.Scroller.Bottom.Image,Element.Scroller.Bottom.Position);
			Canvas:drawImage(Element.Scroller.Top.Image,Element.Scroller.Top.Position);
		end
		ElementController.GetSliderSize = function()
			return Element.Size;
		end
		ElementController.SetSliderSize = function(NewSize)
			Canvas:clear();
			Element.Size = NewSize;
			local ScrollRect = SetScrollerRect(ScrollerRegion,Element.Size,Element.Value,Element.Mode);
			Element.Scroller.Rect = rectVectAdd(ScrollRect,Element.Scroller.Start);
			Element.Scroller.Top.Position = vecAdd({ScrollRect[1],ScrollRect[4]},Element.Scroller.Start);
			Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1],ScrollRect[2] - Element.Scroller.Bottom.Size[2]},Element.Scroller.Start);
			Element.Length = (ScrollerRegion[4] / Element.Size);
			Element.Scroller.Size = ScrollerTopSize[2] + ScrollRect[4] - ScrollRect[2] + ScrollerBottomSize[2];
		end
		ElementController.SetSliderValue = function(NewValue)
			Canvas:clear();
			Element.Value = NewValue;
			local ScrollRect = SetScrollerRect(ScrollerRegion,Element.Size,Element.Value,Element.Mode);
			Element.Scroller.Rect = rectVectAdd(ScrollRect,Element.Scroller.Start);
			Element.Scroller.Top.Position = vecAdd({ScrollRect[1],ScrollRect[4]},Element.Scroller.Start);
			Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1],ScrollRect[2] - Element.Scroller.Bottom.Size[2]},Element.Scroller.Start);
		end
		ElementController.GetSliderValue = function()
			return Element.Value;
		end
		ElementController.GetPosition = function()
			return Element.Scroller.Start;
		end
		ElementController.SetToMousePosition = function()
			local Position = 
			ElementController.SetSliderValue((vecSub(Canvas:mousePosition(),ElementController.GetPosition())[2] - (Element.Length / 2)) / (ScrollerRegion[4] - ElementController.GetLength()));
		end
		ElementController.GetLength = function()
			return Element.Length;
		end
	end
	return ElementController;
end
