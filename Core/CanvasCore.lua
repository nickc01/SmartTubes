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
local function rectVectSub(A,B)
	return {A[1] - B[1],A[2] - B[2],A[3] - B[1],A[4] - B[2]};
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
	elseif Mode == "Horizontal" then
		local Rect = {0,0,RectMax[3] / Size,RectMax[4]};
		local RectTop = {RectMax[3] - Rect[3],0,RectMax[3],RectMax[4]};
		return {Lerp(RectTop[1],Rect[1],Position),0,Lerp(RectTop[3],Rect[3],Position),RectMax[4]};
	end
end

function CanvasCore.Update(dt)
	for k,i in pairs(Canvases) do
		i.Canvas:clear();
		for m,n in ipairs(i.Elements) do
			if n.Update ~= nil then
				n.Update(dt);
			end
			n.Draw();
		end
	end
end

function CanvasCore.AddScrollBar(CanvasName,Origin,Length,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue)
	InitialSize = InitialSize or 1;
	InitialValue = InitialValue or 0;
	if Origin[3] ~= nil and Origin[4] ~= nil then
		local Length;
		if Mode == "Vertical" then
			Length = Origin[4] - Origin[2];
		elseif Mode == "Horizontal" then
			Length = Origin[3] - Origin[1];
		end
		return CanvasCore.AddScrollBar(CanvasName,{Origin[3] - ((Origin[3] - Origin[1]) / 2),Origin[4] - ((Origin[4] - Origin[2]) / 2)},Length,Scroller,ScrollerBackground,Arrows,Mode,InitialSize,InitialValue);
	end
	--sb.logInfo("Canvases = " .. sb.print(Canvases));
	local Canvas = Canvases[CanvasName].Canvas;
	local Element = {};
	local ElementController = {};
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

		Element.BottomArrow = {
			Center = BottomArrowCenter,
			RelativeCenter = BottomArrowCenter,
			Image = Arrows.Bottom
		}

		local TopArrowSize = root.imageSize(Arrows.Top);
		local TopArrowCenter;
		if Mode == "Vertical" then
			TopArrowCenter = {Origin[1],ScrollBarTopRight[2] - (TopArrowSize[2] / 2)};
		elseif Mode == "Horizontal" then
			TopArrowCenter = {ScrollBarTopRight[1] - (TopArrowSize[1] / 2),Origin[2]};
		end

		Element.TopArrow = {
			Center = TopArrowCenter,
			RelativeCenter = TopArrowCenter,
			Image = Arrows.Top
		}
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

		Element.BackgroundScrollerBottom = {
			Center = BackgroundScrollerBottomPos,
			RelativeCenter = BackgroundScrollerBottomPos,
			Image = ScrollerBackground.ScrollerBottom
		}

		local BackgroundScrollerTopSize = root.imageSize(ScrollerBackground.ScrollerTop);
		local BackgroundScrollerTopPos;
		if Mode == "Vertical" then
			BackgroundScrollerTopPos = {Origin[1],ScrollArea[4] - (BackgroundScrollerTopSize[2] / 2)};
		elseif Mode == "Horizontal" then
			BackgroundScrollerTopPos = {ScrollArea[3] - (BackgroundScrollerTopSize[1] / 2),Origin[2]};
		end

		Element.BackgroundScrollerTop = {
			Center = BackgroundScrollerTopPos,
			RelativeCenter = BackgroundScrollerTopPos,
			Image = ScrollerBackground.ScrollerTop
		}
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
		--local BackgrounmdScrollerRect = {Origin[1] - (ScrollerSize[1] / 2),ScrollArea[2],Origin[1] + (ScrollerSize[1] / 2),ScrollArea[4]};

		Element.BackgroundScroller = {
			Rect = BackgroundScrollerRect,
			RelativeRect = BackgroundScrollerRect,
			Image = ScrollerBackground.Scroller
		}

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
		Element.OriginOffset = vecSub(ScrollerStart,ScrollBarBottomLeft);
		Element.BackgroundScroller.RelativeRect = rectVectSub(Element.BackgroundScroller.RelativeRect,ScrollerStart);
		Element.BackgroundScrollerTop.RelativeCenter = vecSub(Element.BackgroundScrollerTop.RelativeCenter,ScrollerStart);
		Element.BackgroundScrollerBottom.RelativeCenter = vecSub(Element.BackgroundScrollerBottom.RelativeCenter,ScrollerStart);
		Element.TopArrow.RelativeCenter = vecSub(Element.TopArrow.RelativeCenter,ScrollerStart);
		Element.BottomArrow.RelativeCenter = vecSub(Element.BottomArrow.RelativeCenter,ScrollerStart);

		local ScrollRect = SetScrollerRect(ScrollerRegion,InitialSize,InitialValue,Mode);


		local ScrollerBottomSize = root.imageSize(Scroller.ScrollerBottom);
		local ScrollerTopSize = root.imageSize(Scroller.ScrollerTop);

		Element.Scroller = {
			Rect = rectVectAdd(ScrollRect,ScrollerStart),
			Image = Scroller.Scroller,
			Top = {
				Image = Scroller.ScrollerTop
			},
			Bottom = {
				Image = Scroller.ScrollerBottom,
				Size = ScrollerBottomSize
			},
			Start = ScrollerStart,
			Region = ScrollerRegion
		}
		if Mode == "Vertical" then
			Element.Scroller.Top.Position = vecAdd({ScrollRect[1],ScrollRect[4]},ScrollerStart);
			Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1],ScrollRect[2] - ScrollerBottomSize[2]},ScrollerStart);
			Element.Length = (ScrollerRegion[4] / InitialSize);
		elseif Mode == "Horizontal" then
			Element.Scroller.Top.Position = vecAdd({ScrollRect[3],ScrollRect[2]},ScrollerStart);
			Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1] - ScrollerBottomSize[1],ScrollRect[2]},ScrollerStart);
			Element.Length = (ScrollerRegion[3] / InitialSize);
		end
		Element.Size = InitialSize;
		Element.Value = InitialValue;
		Element.Controller = ElementController;
		Element.Mode = Mode;

		Element.ID = sb.makeUuid();

		Canvases[CanvasName].Elements[#Canvases[CanvasName].Elements + 1] = Element;

		Element.UpdatePosValues = function()
			local Position = ElementController.GetPosition();
			local ScrollRect = SetScrollerRect(ScrollerRegion,Element.Size,Element.Value,Element.Mode);
			Element.Scroller.Rect = rectVectAdd(ScrollRect,Position);
			if Element.Mode == "Vertical" then
				Element.Scroller.Top.Position = vecAdd({ScrollRect[1],ScrollRect[4]},Position);
				Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1],ScrollRect[2] - Element.Scroller.Bottom.Size[2]},Position);
				Element.Length = (ScrollerRegion[4] / Element.Size);
			elseif Element.Mode == "Horizontal" then
				Element.Scroller.Top.Position = vecAdd({ScrollRect[3],ScrollRect[2]},Position);
				Element.Scroller.Bottom.Position = vecAdd({ScrollRect[1] - Element.Scroller.Bottom.Size[1],ScrollRect[2]},Position);
				Element.Length = (ScrollerRegion[3] / Element.Size);
			end
			Element.BackgroundScroller.Rect = rectVectAdd(Element.BackgroundScroller.RelativeRect,Position);
			Element.BackgroundScrollerTop.Center = vecAdd(Element.BackgroundScrollerTop.RelativeCenter,Position);
			Element.BackgroundScrollerBottom.Center = vecAdd(Element.BackgroundScrollerBottom.RelativeCenter,Position);
			Element.TopArrow.Center = vecAdd(Element.TopArrow.RelativeCenter,Position);
			Element.BottomArrow.Center = vecAdd(Element.BottomArrow.RelativeCenter,Position);
		end
		
		Element.Draw = function()
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
			Element.Size = NewSize;
			Element.UpdatePosValues();
		end
		ElementController.SetSliderValue = function(NewValue)
			Element.Value = NewValue;
			Element.UpdatePosValues();
		end
		ElementController.GetSliderValue = function()
			return Element.Value;
		end
		ElementController.GetPosition = function()
			if Element.Parent ~= nil then
				return vecAdd(Element.Scroller.Start,Element.Parent.GetPosition());
			end
			return Element.Scroller.Start;
		end
		ElementController.GetRelativePosition = function()
			return Element.Scroller.Start;
		end
		ElementController.SetPosition = function(Pos)
			local NewPos = Pos;
			if Element.Parent ~= nil then
				NewPos = vecAdd(Pos,Element.GetPosition());
			end
			ElementController.SetRelativePosition(NewPos);
		end
		ElementController.SetRelativePosition = function(Pos)
			Element.Scroller.Start = Pos;
			Element.UpdatePosValues();
		end
		ElementController.SetToMousePosition = function()
			if Element.Mode == "Vertical" then
				ElementController.SetSliderValue((vecSub(Canvas:mousePosition(),ElementController.GetPosition())[2] - (Element.Length / 2)) / (ScrollerRegion[4] - ElementController.GetLength()));
			elseif Element.Mode == "Horizontal" then
				ElementController.SetSliderValue((vecSub(Canvas:mousePosition(),ElementController.GetPosition())[1] - (Element.Length / 2)) / (ScrollerRegion[3] - ElementController.GetLength()));
			end
		end
		ElementController.GetLength = function()
			return Element.Length;
		end
		ElementController.GetValueAtMousePosition = function()
			if Element.Mode == "Vertical" then
				return (vecSub(Canvas:mousePosition(),ElementController.GetPosition())[2] - (Element.Length / 2)) / (ScrollerRegion[4] - Element.Length);
			elseif Element.Mode == "Horizontal" then
				return (vecSub(Canvas:mousePosition(),ElementController.GetPosition())[1] - (Element.Length / 2)) / (ScrollerRegion[3] - Element.Length);
			end
		end
	end
	return ElementController;
end
