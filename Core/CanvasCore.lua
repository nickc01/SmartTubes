CanvasCore = {};

local ClickCalls = {};
local CanvasResets = {};
local CanvasElements = {};
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

local function Lerp(A,B,t)
	return ((math.max(A,B) - math.min(A,B)) * t) + math.min(A,B);
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

function CanvasCore.AddElement(Canvas,Element)
	if CanvasElements[Canvas] == nil then
		CanvasElements[Canvas] = {Element};
		CanvasResets[Canvas] = true;
	else
		CanvasElements[Canvas][#CanvasElements[Canvas] + 1] = Element;
	end
	getmetatable(Element).IsElement = true;
end

function CanvasCore.AddClickCallback(Canvas,ClickCallbackName)
	_ENV[ClickCallbackName] = function(Position,Button,IsButtonDown)
		CanvasClick(Canvas,Position,Button,IsButtonDown);
	end
end

function CanvasCore.Update(dt)
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
	for k,i in pairs(CanvasResets) do
		if i == true then
			k:clear();
			for k,i in ipairs(CanvasElements[k]) do
				i.Draw();
			end
			CanvasResets[k] = false;
		end
	end
	for k,i in pairs(CanvasElements) do
		for m,n in ipairs(i) do
			getmetatable(n).UpdateFunc(dt);
		end
	end
end

function CanvasCore.CreateScrollbar(Canvas,BottomPosition,TopPosition,TopArrow,BottomArrow,ScrollArea,ScrollTile,ScrollTileTop,ScrollTileBottom,InitialScrollSize,InitialScrollPosition)
	if InitialScrollPosition < 0 then
		InitialScrollPosition = 0;
	end
	if InitialScrollPosition > 1 then
		InitialScrollPosition = 1;
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
	local ScrollRectBottom = {0,0,ScrollRectMax[3],ScrollRectMax[4] / InitialScrollSize};
	local ScrollRectTop = {0,ScrollRectMax[4] - (ScrollRectMax[4] / InitialScrollSize),ScrollRectMax[3],ScrollRectMax[4]};
	local Scrollbar;
	local ClickRect;
	local ScrollMeta = {
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
		ScrollRectBottom = ScrollRectBottom,
		ScrollRectTop = ScrollRectTop,
		Clicking = false,
		LastMousePos,
		UpdateFunc = function(dt)
			if Clicking == true then
				
			end
		end,
		Parent = nil,
		Callbacks = {},
		ScrollRectArea = {0,Lerp(ScrollRectTop[2],ScrollRectBottom[2],InitialScrollPosition),ScrollRectMax[3],Lerp(ScrollRectTop[4],ScrollRectBottom[4],InitialScrollPosition)}
	}
	ClickRect = rectVecAdd(ScrollMeta.ScrollRectArea,ScrollMeta.ScrollRectStart)
	Scrollbar = setmetatable({
		Draw = function()
			if ScrollMeta.Parent == nil then
				DrawScrollbar(ScrollMeta,Canvas);
			else
				DrawScrollbar(ScrollMeta,Canvas,ScrollMeta.Parent.Position);
			end
		end,
		GetPosition = function()
			return ScrollMeta.ScrollPosition;
		end,
		ChangePosition = function(Amount)
			Scrollbar.SetPosition(Scrollbar.GetPosition() + Amount);
		end,
		SetPosition = function(NewPosition)
			if NewPosition < 0 then
				NewPosition = 0;
			elseif NewPosition > 1 then
				NewPosition = 1;
			end
			ScrollMeta.ScrollPosition = NewPosition;
			local NewScrollRect = {0,Lerp(ScrollRectTop[2],ScrollRectBottom[2],NewPosition),ScrollRectMax[3],Lerp(ScrollRectTop[4],ScrollRectBottom[4],NewPosition)};

			ClickRect[1],ClickRect[2],ClickRect[3],ClickRect[4] =
			ClickRect[1] + NewScrollRect[1] - ScrollMeta.ScrollRectArea[1],
			ClickRect[2] + NewScrollRect[2] - ScrollMeta.ScrollRectArea[2],
			ClickRect[3] + NewScrollRect[3] - ScrollMeta.ScrollRectArea[3],
			ClickRect[4] + NewScrollRect[4] - ScrollMeta.ScrollRectArea[4]

			ScrollMeta.ScrollRectArea = NewScrollRect;

			if ScrollMeta.IsElement == true then
				CanvasResets[Canvas] = true;
			end
			if ScrollMeta.Callbacks.OnScrollerUpdate ~= nil then
				ScrollMeta.Callbacks.OnScrollerUpdate(NewPosition);
			end
		end,
		AddFunctionCallBack = function(OnScrollerUpdate)
			ScrollMeta.Callbacks.OnScrollerUpdate = OnScrollerUpdate;
		end
	},
	ScrollMeta);
	local OnClick = function(Position,Button,IsButtonDown)
		--sb.logInfo("You Clicked The Scrollbar");
		sb.logInfo("Button = " .. sb.print(Button));
		if Button == 0 then
			ScrollMeta.Clicking == IsButtonDown;
			LastMousePos = Canvas:mousePosition();
		end
	end
	CanvasCore.AddClickEvent(Canvas,OnClick,false,nil,nil,ClickRect);
	return Scrollbar;
end

CanvasClick = function(Canvas,Position,Button,IsButtonDown)
	for i=1,#ClickCalls do
		if ClickCalls[i].Canvas == Canvas and PosWithinRect(Position,ClickCalls[i].ClickArea) and ClickCalls[i].OnClick ~= nil then
			ClickCalls[i].Clicked = IsButtonDown;
			ClickCalls[i].StoredButton = Button;
			ClickCalls[i].OnClick(Position,Button,IsButtonDown);
		end
	end
end
