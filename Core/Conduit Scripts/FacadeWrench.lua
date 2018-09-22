require("/Core/ItemCore.lua");

--Declaration

--Public Table
FacadeWrench = {};
local FacadeWrench = FacadeWrench;

--Storage for Synced Variables
local Data = {};

--Variables
local OnMousePositionChange = {};
local CurrentPosition;
local Cursor;
local CursorType;
local PlayerID;
local UIConfig;
local Initialized = false;
local AimPosition;
local Timer = 0;
local DisableForPosition = false;
local FacadeConfig;
local MaterialConfigCache = {};
local CurrentlyActiveFacades = {};
local IndicatorTimer = 0;

--Functions
local UpdateCursor;
local RightClick;
local LeftClick;
local AimChanged;
local BreakingModeChanged;
local GetMaterialConfig;
local IsMaterialOccluded;
local IndicateFacades;

--Initializes the Facade Wrench
function FacadeWrench.Initialize()
	if Initialized == true then return false end;
	Initialized = true;
	UIConfig = root.assetJson("/Items/Facade Wrench/UI/UI Config.config");
	FacadeConfig = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	PlayerID = activeItem.ownerEntityId();
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("Settings",PlayerID,"Index",1,"Breaking",false);
	Data.AddBreakingChangeFunction(BreakingModeChanged);
	activeItem.setTwoHandedGrip(false);
	ItemCore.Initialize("wrench",{0.55,0.3},-45,{-0.6,0.6});
	ItemCore.AddMouseClickCallback(LeftClick);
	ItemCore.AddMouseRightClickCallback(RightClick);
	local NewPosition = activeItem.ownerAimPosition();
	local OldUpdate = update;
	update = function(dt,fireMode,shiftHeld)
		if OldUpdate ~= nil then
			OldUpdate(dt,fireMode,shiftHeld);
		end
		local NewPosition = activeItem.ownerAimPosition();
		local NewPositionRounded = {math.floor(NewPosition[1]),math.floor(NewPosition[2])};
		if AimPosition[1] ~= NewPositionRounded[1] or AimPosition[2] ~= NewPositionRounded[2] then
			AimPosition = NewPositionRounded;
			AimChanged();
		end
		Timer = Timer + dt;
		IndicatorTimer = IndicatorTimer + dt;
		if Timer > 3 then
			Timer = 0;
			if Cursor ~= nil then
				world.sendEntityMessage(Cursor,"Refresh");
			end
		end
		if IndicatorTimer > 2 then
			IndicatorTimer = 0;
			for f,indicator in pairs(CurrentlyActiveFacades) do
				world.sendEntityMessage(indicator,"Refresh");
			end
			IndicateFacades(FacadeWrench.GetAllFacades(AimPosition,10));
		end
	end
	local oldUninit = uninit;
	uninit = function()
		if oldUninit ~= nil then
			oldUninit();
		end
		if Cursor ~= nil then
			world.sendEntityMessage(Cursor,"Destroy");
		end
		for f,indicator in pairs(CurrentlyActiveFacades) do
			world.sendEntityMessage(indicator,"Destroy");
		end
	end
	AimPosition = {math.floor(NewPosition[1]),math.floor(NewPosition[2])};
	AimChanged();
	return true;
end

--Retrieves the current aiming position
function FacadeWrench.GetAimPosition()
	return AimPosition;
end

--Called when the break mode is changed
BreakingModeChanged = function()
	UpdateCursor();
end

--Returns whether a facade can be placed at the position
function FacadeWrench.CanBeFacaded(position)
	local Material = world.material(position,"foreground");
	local PlayerPosition = world.entityPosition(PlayerID);
	return not DisableForPosition and world.objectAt(position) == nil and Material ~= nil and Material ~= false and string.find(Material,"metamaterial:") == nil  and ((world.isTileProtected(position) == false and world.magnitude(position,PlayerPosition) <= 10) or player.isAdmin());
end

--Returns whether the facade at the position ca be broken
function FacadeWrench.CanBreakFacade(position)
	local PlayerPosition = world.entityPosition(PlayerID);
	return not DisableForPosition and world.objectAt(position) ~= nil and world.getObjectParameter(world.objectAt(position),"IsAFacade") == true and ((world.isTileProtected(position) == false and world.magnitude(position,PlayerPosition) <= 10) or player.isAdmin());
end

--Returns the break mode
function FacadeWrench.GetBreakMode()
	return Data.GetBreaking();
end

--Sets the Break Mode
function FacadeWrench.SetBreakMode(bool)
	Data.SetBreaking(bool);
end

--Info Template :
--Background
--Foreground
--Occluded
--Mod
--Position
--Object
--Parameters
--Item
--Indicator

--Places the facade in the block at the position, and adds any parameters specified to the block
function FacadeWrench.PlaceFacade(position,parameters)
	
	local CurrentConfig = FacadeConfig[Data.GetIndex()];
	if CurrentConfig ~= nil then
		local Info = {}
		local Background = world.material(position,"background") or false;
		local Foreground = world.material(position,"foreground") or false;
		if Foreground == false then return nil end;
		if Background == false then
			world.placeMaterial(position,"background","temporaryBackground",0,true);
		else
			Info.Background = Background;
		end
		Info.Occluded = IsMaterialOccluded(Foreground);
		Info.Mod = world.mod(position,"foreground");
		Info.Foreground = Foreground;
		Info.Position = position;
		if Info.Occluded then
			Info.Object = CurrentConfig.occludedBlock;
		else
			Info.Object = CurrentConfig.normalBlock;
		end
		Info.Parameters = parameters;
		Info.Item = CurrentConfig.item;
		Info.Indicator = CurrentConfig.indicator;
		world.damageTiles({position},"foreground",position,"explosive",9999,0);
		local Builder = world.spawnProjectile("facadebuilder",position,PlayerID);
		world.callScriptedEntity(Builder,"ReceiveInfo",Info);
	end
end

--Updates the cursor projectile
UpdateCursor = function()
	local NewCursor;
	if FacadeWrench.GetBreakMode() == true then
		if FacadeWrench.CanBreakFacade(AimPosition) then
			NewCursor = "cursorValidR";
		else
			NewCursor = "cursorInvalidR";
		end
	else
		if FacadeWrench.CanBeFacaded(AimPosition) then
			NewCursor = "cursorValid";
		else
			NewCursor = "cursorInvalid";
		end
	end
	
	if CursorType ~= NewCursor then
		
		--Destroy the old cursor and spawn the new one
		if Cursor ~= nil then
			world.sendEntityMessage(Cursor,"Destroy");
		end
		CursorType = NewCursor;
		Cursor = world.spawnProjectile(CursorType,{AimPosition[1] + 0.5,AimPosition[2] + 0.5});
	else
		--Move the current cursor to the new position
		
		if Cursor ~= nil then
			world.sendEntityMessage(Cursor,"SetPosition",{AimPosition[1] + 0.5,AimPosition[2] + 0.5});
		else
			Cursor = world.spawnProjectile(CursorType,{AimPosition[1] + 0.5,AimPosition[2] + 0.5});
		end
	end
end

--Called when the mouse is right clicked
RightClick = function()
	
	if ItemCore.IsShiftHeld() then
		DisableForPosition = false;
		Data.SetBreaking(not Data.GetBreaking());
	else
		local Object = world.objectAt(AimPosition);
		if Object ~= nil and world.getObjectParameter(Object,"IsAFacade") == true then
			UICore.CallMessageOnce(Object,"GetInteraction",function(interaction)
				if interaction ~= nil then
					activeItem.interact(interaction[1],interaction[2],PlayerID);
				end
			end,PlayerID);
		else
			activeItem.interact("ScriptPane",UIConfig,PlayerID);
		end
	end
end

--Called when the mouse is left clicked
LeftClick = function()
	
	if Data.GetBreaking() == true then
		if FacadeWrench.CanBreakFacade(AimPosition) then
			local Object = world.objectAt(AimPosition);
			if Object ~= nil then
				--[[UICore.CallMessageOnce(Object,"DestroyFacade",function()
					UpdateCursor();
				end,world.entityPosition(PlayerID));--]]
				world.sendEntityMessage(Object,"DestroyFacade",world.entityPosition(PlayerID));
				DisableForPosition = true;
				UpdateCursor();
				IndicateFacades(FacadeWrench.GetAllFacades(AimPosition,10));
			end
		end
	else
		if FacadeWrench.CanBeFacaded(AimPosition) then
			local Valid = false;
			local ItemName = FacadeConfig[Data.GetIndex()].item;
			local ItemParameters;
			if player.isAdmin() then
				Valid = true;
			elseif player.hasItemWithParameter("__ParametersWithFacade",ItemName) then
				local ParameterizedItem = player.getItemWithParameter("__ParametersWithFacade",ItemName);
				player.consumeItemWithParameter("__ParametersWithFacade",ItemName,1);
				
				Valid = true;
				ItemParameters = ParameterizedItem.parameters;
			elseif player.hasItem({name = ItemName,count = 1}) == true then
				--Check for any facade items with stored parameters
				
				local ConsumedItem = player.consumeItem({name = ItemName,count = 1});
				
				Valid = true;
			end
			if Valid then
				FacadeWrench.PlaceFacade(AimPosition,ItemParameters);
				DisableForPosition = true;
				UpdateCursor();
			end
		end
	end
end

--Called when the aiming position has changed
AimChanged = function()
	DisableForPosition = false;
	UpdateCursor();
	local State = ItemCore.GetCurrentMouseState();
	if State == "left" then
		LeftClick();
	end
	IndicateFacades(FacadeWrench.GetAllFacades(AimPosition,10));
end

--Returns the config data of the material
GetMaterialConfig = function(material)
	if material ~= nil and material ~= false then
		if MaterialConfigCache[material] == nil then
			MaterialConfigCache[material] = root.materialConfig(material);
		end
		return MaterialConfigCache[material];
	end
end

--Returns true whether the block is occluded (or opaque)
IsMaterialOccluded = function(material)
	local Config = GetMaterialConfig(material);
	if Config ~= nil and Config.config.renderParameters ~= nil and Config.config.renderParameters.occludesBelow == true then
		return true;
	end
	return false;
end

--Gets all the facades within a certain radius of a Position
function FacadeWrench.GetAllFacades(Position,Radius)
	local Objects = world.objectQuery(Position,Radius);
	local Final = {};
	for i=1,#Objects do
		if world.getObjectParameter(Objects[i],"IsAFacade") == true then
			Final[#Final + 1] = Objects[i];
		end
	end
	return Final;
end

--Spawns in new indicators and destroy old ones
IndicateFacades = function(Facades)
	local ActivatedFacades = {};
	for _,facade in ipairs(Facades) do
		--Check if the facade is contained in the currently active ones
		for f,indicator in pairs(CurrentlyActiveFacades) do
			--If this facade is already active
			if facade == f then
				--Just move it to the activated facades and Continue
				ActivatedFacades[facade],CurrentlyActiveFacades[facade] = indicator,nil;
				goto Continue;
			end
		end
		--Otherwise, attempt to spawn the new indicator and add it to the activated facades
		local Indicator = world.getObjectParameter(facade,"FacadeIndicator");
		if Indicator ~= nil then
			local Position = world.entityPosition(facade);
			ActivatedFacades[facade] = world.spawnProjectile(Indicator,{Position[1] + 0.5,Position[2] + 0.5});
		end
		::Continue::
	end
	--Anything left in the old currently active facades list is destroyed
	for f,indicator in pairs(CurrentlyActiveFacades) do
		world.sendEntityMessage(indicator,"Destroy");
	end
	CurrentlyActiveFacades = ActivatedFacades;
end

