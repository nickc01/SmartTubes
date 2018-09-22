if ItemCore ~= nil then return nil end;

require("/Core/UICore.lua");

--Declaration

--Public Table
ItemCore = {};
local ItemCore = ItemCore;

--Variables
local TransformationGroup;
local MouseClickCallbacks;
local MouseRightClickCallbacks;
local MouseHoldCallbacks;
local MouseRightHoldCallbacks;
local PreviousFireMode = "none";
local ShiftHeld = false;

--Functions
local MouseClick;
local MouseRightClick;
local MouseHeld;
local RightMouseHeld;

--Initializes the Item
function ItemCore.Initialize(transformationGroup,position,rotation,rotationPivot)
	TransformationGroup = transformationGroup;
	UICore.Initialize();
	local OldUpdate = update;
	update = function(dt,fireMode,shiftHeld)
		if OldUpdate ~= nil then
			OldUpdate(dt,fireMode,shiftHeld);
		end
		ItemCore.SetArmToMousePosition();
		ShiftHeld = shiftHeld;
		if fireMode ~= PreviousFireMode then
			PreviousFireMode = fireMode;
			if fireMode == "primary" then
				MouseClick();
			elseif fireMode == "alt" then
				MouseRightClick();
			end
		else
			if fireMode == "primary" then
				MouseHeld();
			elseif fireMode == "alt" then
				RightMouseHeld();
			end
		end
	end
	ItemCore.SetTransformation(position,rotation,rotationPivot);
end

--Returns the currently set transformation Group
function ItemCore.GetTransformationGroup()
	return TransformationGroup;
end

--Sets the currently set transformation Group
function ItemCore.SetTransformation(transformationGroup)
	TransformationGroup = transformationGroup;
end

--Sets the initial rotation and position of the item in the hand
function ItemCore.SetTransformation(position,rotation,rotationPivot)
	rotationPivot = rotationPivot or {0,0};
	animator.resetTransformationGroup(TransformationGroup);
	animator.resetTransformationGroup(TransformationGroup);
	animator.rotateTransformationGroup(TransformationGroup,(rotation / 180) * math.pi,rotationPivot);
	animator.translateTransformationGroup(TransformationGroup,position);
	ItemCore.SetArmToMousePosition();
end

--Rotates the hand to where the mouse position is
function ItemCore.SetArmToMousePosition()
	local aim,direction = activeItem.aimAngleAndDirection(0, ItemCore.GetMousePosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end

--Returns the Mouse Aim position
function ItemCore.GetMousePosition()
	return activeItem.ownerAimPosition();
end

--Adds a function that is called when the mouse is clicked
function ItemCore.AddMouseClickCallback(func)
	if MouseClickCallbacks == nil then
		MouseClickCallbacks = {func};
	else
		MouseClickCallbacks[#MouseClickCallbacks + 1] = func;
	end
end

--Adds a function that is called when the mouse is right clicked
function ItemCore.AddMouseRightClickCallback(func)
	if MouseRightClickCallbacks == nil then
		MouseRightClickCallbacks = {func};
	else
		MouseRightClickCallbacks[#MouseRightClickCallbacks + 1] = func;
	end
end

--Adds a function that is called when left click is held down
function ItemCore.AddMouseHoldCallback(func)
	if MouseClickCallbacks == nil then
		MouseHoldCallbacks = {func};
	else
		MouseHoldCallbacks[#MouseHoldCallbacks + 1] = func;
	end
end

--Adds a function that is called when right click is held down
function ItemCore.AddMouseRightHoldCallback(func)
	if MouseRightHoldCallbacks == nil then
		MouseRightHoldCallbacks = {func};
	else
		MouseRightHoldCallbacks[#MouseRightHoldCallbacks + 1] = func;
	end
end

--Returns if the shift key is down
function ItemCore.IsShiftHeld()
	return ShiftHeld;
end

--Returns "left" if the left mouse button is down
--Returns "right" if the right mouse button is down
--Returns "none" if neither of the buttons are down
function ItemCore.GetCurrentMouseState()
	if PreviousFireMode == "primary" then
		return "left";
	elseif PreviousFireMode == "alt" then
		return "right";
	else
		return "none";
	end
end

--Called when the mouse is clicked
MouseClick = function()
	if MouseClickCallbacks ~= nil then
		for _,func in ipairs(MouseClickCallbacks) do
			func();
		end
	end
end

--Called when the mouse is right clicked
MouseRightClick = function()
	if MouseRightClickCallbacks ~= nil then
		for _,func in ipairs(MouseRightClickCallbacks) do
			func();
		end
	end
end

--Called during when the left mouse button is held down
MouseHeld = function()
	
end

--Called during when the right mouse button is held down
RightMouseHeld = function()
	
end
