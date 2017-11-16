CanvasCore = {};

local ClickCalls = {};
local CanvasClick;

local function vecAdd(A,B,C)
	if C == nil then
		return {A[1] + B[1],A[2] + B[2]};
	else
		return {A[1] + B,A[2] + C};
	end
end

local function PosWithinRect(Pos,Rect)
	return Pos[1] >= Rect[1] and Pos[2] >= Rect[2] and Pos[1] <= Rect[3] and Pos[2] <= Rect[4];
end

local function rectVecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2],A[3] + B[1],A[4] + B[2]};
end

local function DrawScrollbar(Scrollbar,Canvas,ParentPos)
	ParentPos = ParentPos or {0,0};
	Canvas:drawImage(Scrollbar.BottomArrow.Asset,vecAdd(Scrollbar.BottomArrow.Position,ParentPos));
	Canvas:drawImage(Scrollbar.TopArrow.Asset,vecAdd(Scrollbar.TopArrow.Position,ParentPos));
	Canvas:drawTiledImage(Scrollbar.ScrollTile.Mid,{0,0},rectVecAdd(Scrollbar.ScrollRectArea,vecAdd(ParentPos,Scrollbar.ScrollRectStart)));
	Canvas:drawImage(Scrollbar.ScrollTile.Top,{Scrollbar.ScrollRectArea[3] + Scrollbar.ScrollRectStart[1] + ParentPos[1] + Scrollbar.ScrollTile.TopOffset[1],Scrollbar.ScrollRectArea[4] + Scrollbar.ScrollRectStart[2] + ParentPos[2] + Scrollbar.ScrollTile.TopOffset[2]});
	Canvas:drawImage(Scrollbar.ScrollTile.Bottom,{Scrollbar.ScrollRectArea[1] + Scrollbar.ScrollRectStart[1] + ParentPos[1] + Scrollbar.ScrollTile.BottomOffset[1],Scrollbar.ScrollRectArea[2] + Scrollbar.ScrollRectStart[2] + ParentPos[2] + Scrollbar.ScrollTile.BottomOffset[2]});
end

function CanvasCore.InitCanvas(CanvasName,ClickCallbackName)
	local NewCanvas = widget.bindCanvas(CanvasName);
	if ClickCallbackName ~= nil then
		CanvasCore.AddClickCallback(NewCanvas,ClickCallbackName);
	end
	return NewCanvas;
end

function CanvasCore.AddClickEvent(Canvas,OnClick,OnClickContinuous,OnHover,OnHoverContinuous,ClickArea)
	ClickCalls[#ClickCalls + 1] = {
		Canvas = Canvas,
		OnClick = OnClick,
		OnClickContinuous = OnClickContinuous or false,
		OnHover = OnHover,
		OnHoverContinuous = OnHoverContinuous or false,
		ClickArea = ClickArea,
		Hovered = false,
		Clicked = false
	}
end

function CanvasCore.AddClickCallback(Canvas,ClickCallbackName)
	_ENV[ClickCallbackName] = function(Position,Button,IsButtonDown)
		CanvasClick(Canvas,Position,Button,IsButtonDown);
	end
end

function CanvasCore.Update()
	for i=1,#ClickCalls do
		local CurrentCall = ClickCalls[i];
		if CurrentCall.OnHover ~= nil then
			local MousePos = CurrentCall.Canvas:mousePosition();
			if PosWithinRect(MousePos,CurrentCall.ClickArea) then
				if CurrentCall.Hovered == false or CurrentCall.OnHoverContinuous == true then
					CurrentCall.Hovered = true;
					CurrentCall.OnHoverContinuous(CurrentCall.Canvas,MousePos,true);
				end
				if CurrentCall.Clicked == true and CurrentCall.OnClickContinuous == true then
					CurrentCall.OnClick(CurrentCall.Canvas,MousePos,CurrentCall.StoredButton,true);
				end
			else
				if CurrentCall.Hovered == true then
					CurrentCall.Hovered = false;
					CurrentCall.OnHover(CurrentCall.Canvas,MousePos,false);
				end
			end
		end
	end
end

function CanvasCore.CreateScrollbar(Canvas,BottomPosition,TopPosition,TopArrow,BottomArrow,ScrollArea,ScrollTile,ScrollTileTop,ScrollTileBottom,InitialScrollSize,InitialScrollPosition)
	if InitialScrollPosition < 0 then
		InitialScrollPosition = 0;
	end
	if InitialScrollSize < 1 then
		InitialScrollSize = 1;
	end
	local BottomArrowSize = root.imageSize(BottomArrow);
	local TopArrowSize = root.imageSize(TopArrow);
	local Middle = {BottomPosition[1],math.floor(((TopPosition[2] - BottomPosition[2]) * 0.5) + BottomPosition[2])};
	local SizeScrollArea = {math.max(root.imageSize(ScrollTile)[1],root.imageSize(ScrollArea)[1]),TopPosition[2] - (BottomPosition[2] + BottomArrowSize[2])};
	local ScrollTopSize = root.imageSize(ScrollTileTop);
	local ScrollBottomSize = root.imageSize(ScrollTileBottom);
	local FirstHalf = {math.floor(SizeScrollArea[1] / 2),math.floor(SizeScrollArea[2] / 2)};
	local BottomScroll = {Middle[1] - FirstHalf[1],Middle[2] - FirstHalf[2]};
	local TopScroll = {Middle[1] + SizeScrollArea[1] - FirstHalf[1],Middle[2] + SizeScrollArea[2] - FirstHalf[2]};
	local ScrollRectStart = {BottomScroll[1],BottomScroll[2] + ScrollBottomSize[2]};
	local ScrollRectMax = {0,0,TopScroll[1] - ScrollRectStart[1],TopScroll[2] - ScrollTopSize[2] - ScrollRectStart[2]};
	local Scrollbar;
	Scrollbar = setmetatable({
		Draw = function(ParentPos)
			DrawScrollbar(getmetatable(Scrollbar),Canvas,ParentPos);
		end
	},
	{
		BottomArrow = 
		{
			Position = {BottomPosition[1] - math.floor(BottomArrowSize[1] / 2),BottomPosition[2] - math.floor(BottomArrowSize[2] / 2)},
			Asset = BottomArrow;
		},
		TopArrow = {
			Position = {TopPosition[1] - math.floor(TopArrowSize[1] / 2),TopPosition[2] - math.floor(TopArrowSize[2] / 2)},
			Asset = TopArrow
		},
		ScrollArea = {
			Position = BottomScroll,
			Asset = ScrollArea
		},
		ScrollTile = {
			Top = ScrollTileTop,
			Mid = ScrollTile,
			Bottom = ScrollTileBottom,
			BottomOffset = {0,-ScrollBottomSize[2]},
			TopOffset = {-ScrollTopSize[1],0}
		},
		ScrollSize = InitialScrollSize,
		ScrollPosition = InitialScrollPosition,
		ScrollRectStart = ScrollRectStart,
		ScrollRectMax = ScrollRectMax,
		ScrollRectArea = {0,0,ScrollRectMax[3],ScrollRectMax[4] / InitialScrollSize}
	});
	return Scrollbar;
end

CanvasClick = function(Canvas,Position,Button,IsButtonDown)
	for i=1,#ClickCalls do
		if ClickCalls[i].Canvas == Canvas and ClickCalls[i].OnClick ~= nil then
			ClickCalls[i].Clicked = IsButtonDown;
			ClickCalls[i].StoredButton = Button;
			ClickCalls[i].OnClick(Canvas,Position,Button,IsButtonDown);
		end
	end
end
