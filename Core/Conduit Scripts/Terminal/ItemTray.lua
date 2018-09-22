if ItemTray ~= nil then return nil end;
require("/Core/UICore.lua");

--Definition
ItemTray = {};
local ItemTray = ItemTray;

--Variables
local SlotImage = "/interface/actionbar/actionbarcover.png";
local Canvas;
local Initialized = false;
local SourceID;
local SourcePosition;
local SourcePlayer;
local Size;
local Data = {};
local Hovering = false;
local RenderFunctions = {};
local RenderBackground = false;
local BackgroundColor;
local BackgroundRect;
local Position = 0;
local DestinationPostion = 0;
local SmoothPosition = true;
local SmoothSpeed = 7;
local RightBound;
local LeftBound;
local ItemRenders = {};
local Dragging = false;
local MouseOffset;
local SelectedTrayItem;
local Requesting = false;
local RequestFunction;
local RequestRenderID;

--Functions
local OnHover;
local ClearItems;
local AddItem;
local DefaultIsDown = false;
local DefaultClick;
local SetSelectedTrayItem;
local AddRenderer;
local RemoveRenderer;

--Initializes the Item Tray
function ItemTray.Initialize()
	if Initialized == true then return nil end;
	Initialized = true;
	SourceID = config.getParameter("MainObject") or pane.sourceEntity();
	SourcePosition = world.entityPosition(SourceID);
	SourcePlayer = player.id();
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("ItemTray",SourceID,"Tray",{});
	local OldUpdate = update;
	Canvas = widget.bindCanvas("itemTrayCanvas");
	Size = Canvas:size();
	BackgroundRect = {0,0,Size[1],Size[2]};
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
	Position = Size[1] / 2;
	RightBound = Size[1] - 40;
	LeftBound = 40;
	--[[for i=1,50 do
		AddItem({name = "perfectlygenericitem",count = 1});
	end--]]
end

--Returns the tray position offset
function ItemTray.GetOffset()
	return Position;
end

--Sets the tray position offset
function ItemTray.SetOffset(offset)
	if offset > RightBound then
		offset = RightBound;
	end
	if offset < LeftBound then
		offset = LeftBound;
	end
	if SmoothPosition == true then
		DestinationPostion = offset;
	else
		Position = offset;
	end
end

--The Update Loop for the Item Tray
Update = function(dt)
	Canvas:clear();
	if Dragging == true then
		local MousePos = Canvas:mousePosition();
		ItemTray.SetOffset(MousePos[1] - MouseOffset);
		--Position = MousePos - MouseOffset;
	end
	if SmoothPosition then
		Position = (DestinationPostion - Position) * SmoothSpeed * dt + Position;
	end
	--Position = Position + (dt * 5);
	for i=1,#RenderFunctions do
		RenderFunctions[i].Function();
	end
	for i=1,#ItemRenders do
		ItemRenders[i].Function();
	end
	if RenderBackground == true then
		Canvas:drawRect(BackgroundRect,BackgroundColor);
	end
end

--Adds an item to be shown in the Tray
AddItem = function(item)
	local Renderer = {Item = item};
	local Icon = ImageCore.GetObjectIcon(item.name);
	local SlotIcon = SlotImage;
	local SlotTextureRect = {0,0,18,18};
	local RarityImage = ImageCore.RaritySlotImage(item.name);
	local RarityImageRect = {0,0,18,18};
	local TextPositioning = {
		horizontalAnchor = "right",
		verticalAnchor = "bottom"
	}
	local ItemPosition = #ItemRenders * 20;
	local CountText = tostring(9876);
	local RenderFunction = function()
		--TODO -- TODO -- TODO
		--sb.logInfo("Rendering");
		Canvas:drawImageRect(SlotIcon,SlotTextureRect,{ItemPosition + Position,12,ItemPosition + 18 + Position,30});
		Canvas:drawImageRect(RarityImage,RarityImageRect,{ItemPosition + Position,12,ItemPosition + 18 + Position,30});
		Canvas:drawImageRect(Icon.Image,Icon.TextureRect,{ItemPosition + 1 + Position,13,ItemPosition + 17 + Position,29});
		TextPositioning.position = {ItemPosition + 20 + Position,9};
		Canvas:drawText(CountText,TextPositioning,8);
	end
	local CollisionFunction = function()
		return {ItemPosition + Position,12,ItemPosition + Position + 18,30};
	end
	local OnClick = function(clicking)
		--TODO
		--sb.logInfo("Clicking Item = " .. sb.print(clicking));
	end
	LeftBound = LeftBound - 20;
	Renderer.OnClick = OnClick;
	Renderer.Function = RenderFunction;
	Renderer.CollisionFunction = CollisionFunction;
	local ID = sb.makeUuid();
	Renderer.ID = ID;
	ItemRenders[#ItemRenders + 1] = Renderer;
	return ID;
end

--Requests a item in the tray to be selected
--Calls the passed function and passes in the item and it's tray ID
function ItemTray.RequestSelection(selectionFunc)
	--TODO -- TODO -- TODO -- TODO -- TODO -- TODO -- TODO
	RequestFunction = selectionFunc;
	local TextPosition = {
		horizontalAnchor = "mid",
		verticalAnchor = "mid",
		position = {Size[1] / 2,5}
	}
	RequestRenderID = AddRenderer(function()
		--Canvas:drawText("Select a );
	end);
	Requesting = true;
end

--Cancels the incoming request made
function ItemTray.CancelRequest()
	if Requesting == true then
		Requesting = false;

	end
end

--Removes an item from the Tray
RemoveItem = function(ID)
	for i=#ItemRenders,1,-1 do
		if ItemRenders[i].ID == ID then
			table.remove(ItemRenders,i);
			return true;
		end
	end
	return false;
end

--Removes all items that are shown in the item tray
ClearItems = function()
	ItemRenders = {};
end

--Called when the background is clicked on
DefaultClick = function(clicking)
	if clicking == true then
		local MousePos = Canvas:mousePosition();
		MouseOffset = MousePos[1] - Position;
		Dragging = true;
	else
		Dragging = false;
	end
end

--Sets the Selected Tray item
SetSelectedTrayItem = function(ID)
	if SelectedTrayItem ~= ID then
		if SelectedTrayItem ~= nil then
			--TODO , unselect the existing Item
		end
		SelectedTrayItem = ID;
		if SelectedTrayItem ~= nil then
			--TODO , select the item
		end
	end
end

--Returns the index of the Tray Item
GetTrayItemIndex = function(ID)
	for i=1,#ItemRenders do
		if ItemRenders[i].ID == ID then
			return i;
		end
	end
	return nil;
end

--Adds a renderer to be rendered
AddRenderer = function(renderFunction)
	local ID = sb.makeUuid();
	RenderFunctions[#RenderFunctions + 1] = {ID = ID,Function = renderFunction};
	return ID;
end

--Removes a renderer
RemoveRenderer = function(ID)
	for i=#RenderFunctions,1,-1 do
		if RenderFunctions[i].ID == ID then
			table.remove(RenderFunctions,i);
			return nil;
		end
	end
end


--Main Handler for Item Tray Clicks
function __ClickItemTray__(position,buttonType,isDown)
	--sb.logInfo("Tray Clicked");
	local ClickingSomething = false;
	if buttonType == 0 then
		for i=1,#ItemRenders do
			local Collision = ItemRenders[i].CollisionFunction();
			if Collision ~= nil then
				if isDown == true then
					if not (position[1] > Collision[3] or position[1] < Collision[1] or position[2] > Collision[3] or position[2] < Collision[2]) then
						ItemRenders[i].Clicking = true;
						ItemRenders[i].OnClick(true);
						ClickingSomething = true;
					end
				else
					if ItemRenders[i].Clicking == true then
						ItemRenders[i].Clicking = nil;
						ItemRenders[i].OnClick(false);
					end
				end
			end
		end
	end
	if isDown == true and (ClickingSomething == false or buttonType == 1) then
		DefaultIsDown = true;
		DefaultClick(true);
	else
		if DefaultIsDown == true then
			DefaultIsDown = false;
			DefaultClick(false);
		end
	end
end

--Called when the mouse is hovering over the item Tray
--[[OnHover = function(hovering)
	sb.logInfo("Hovering = " .. sb.print(hovering));
	if hovering == true then
		local Item = player.swapSlotItem();
		if Item ~= nil then
			BackgroundColor = {0,128,0};
			RenderBackground = true;
		end
	else
		RenderBackground = false;
	end
end--]]
