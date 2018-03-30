require("/Core/ItemCore.lua");

--Declaration

--Public Table
FacadeWrench = {};
local FacadeWrench = FacadeWrench;

--Variables
local OnMousePositionChange = {};
local CurrentPosition;
local Cursor;
local PlayerID;
local FacadeWrenchSettingsCall;
local Initialized = false;

--Functions
local UpdateCursor;

--Initializes the Facade Wrench
function FacadeWrench.Initialize()
	if Initialized == true then return false end;
	Initialized = true;
	PlayerID = activeItem.ownerEntityId();
	activeItem.setTwoHandedGrip(false);
	ItemCore.Initialize("wrench",{0.55,0.3},-45,{-0.6,0.6});
	local OldUpdate = update;
	update = function(dt,fireMode,shiftHeld)
		if OldUpdate ~= nil then
			OldUpdate(dt,fireMode,shiftHeld);
		end
	end
	return true;
	--TODO -- Activate the call to settings
end

--Updates the cursor projectile
UpdateCursor = function()
	
end
