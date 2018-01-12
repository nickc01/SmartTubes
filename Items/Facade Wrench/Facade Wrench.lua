
local UpdateAim;
local SetupAim;
local UpdateCursor;
local DestroyCursor;
local SpawnCursor;
local CheckPosition;

local Cursor = nil;
local IsValid = nil;
local DT = 1;
local BreakMode = false;

local FacadeConfig = nil;
local Config = nil;

local StoredPosition = nil;

local Promise = nil;
local SourceOBJ = nil;

local Offset = {0.5,0.5};
local Activated = false;

local UIConfig = nil;

local PreviousState = "none";

local UpdateAfterLimit;

local Indicators = nil;

local ItemConsumed = nil;

local function vecEq(A,B)
	if B == nil then return false end;
	return A[1] == B[1] and A[2] == B[2];
end

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]};
end

local function vecFloor(A)
	return {math.floor(A[1]),math.floor(A[2])};
end

local MouseClicked;

local function SendAndWait(ID,Name)
	local Promise = world.sendEntityMessage(ID,Name);
	while Promise:finished() == false do end;
	return Promise:result();
end

local Timer = 0;
local Limit = 0.25;

function init()
	SetupAim();
	FacadeConfig = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	UIConfig = root.assetJson("/Items/Facade Wrench/UI/UI Config.config");
	--sb.logInfo("Before = " .. sb.print(config.getParameter("test1")));
	--activeItem.setInstanceValue("test1","thisisatest");
	--sb.logInfo("After = " .. sb.print(config.getParameter("test1")));
	--sb.logInfo("EntityID = " .. sb.print(entity.id()));
	--sb.logInfo("ValueTest = " .. sb.print(config.getParameter("ValueTest")));
	UpdateAfterLimit();
end

UpdateAfterLimit = function()
	if Cursor ~= nil then
		world.sendEntityMessage(Cursor,"Refresh");
	end
	if Indicators ~= nil then
		for i=1,#Indicators do
			world.sendEntityMessage(Indicators[i],"Destroy");
		end
	end
	Indicators = {};
	--sb.logInfo("Aim Position = " .. sb.print(vecFloor(activeItem.ownerAimPosition())));
	local Pos = activeItem.ownerAimPosition()--world.entityPosition(vecFloor(activeItem.ownerAimPosition()));
	if Pos ~= nil then
		local Objects = world.objectQuery(Pos,10);
		local offset = {0.5,0.5};
		for i=1,#Objects do
			local Indicator = world.getObjectParameter(Objects[i],"FacadeIndicator");
			if Indicator ~= nil then
				Indicators[#Indicators + 1] = world.spawnProjectile(Indicator,vecAdd(world.entityPosition(Objects[i]),offset));
			end
		end
	end
end

local First = false;

function update(dt,fireMode,shiftHeld)
	if First == false then
		First = true;
		local PreviousConfig = config.getParameter("PreviousConfig");
		--sb.logInfo("Previous Config = " .. sb.print(PreviousConfig));
		if PreviousConfig ~= nil then
			world.sendEntityMessage(activeItem.ownerEntityId(),"SetConfig",PreviousConfig);
			Config = PreviousConfig;
		end
	end
	Timer = Timer + dt;
	if Timer >= Limit then
		Timer = 0;
		UpdateAfterLimit();
	end
	if Promise ~= nil then
		if Promise:finished() == true then
			--sb.logInfo("Finished = " .. sb.print(Promise:finished()));
			local Interaction = Promise:result();
			if Interaction ~= nil then
				activeItem.interact(Interaction[1],Interaction[2],activeItem.ownerEntityId());
			end
			Promise = nil;
			SourceOBJ = nil;
		end
	end
	DT = dt;
	UpdateAim();
	if fireMode ~= PreviousState then
		PreviousState = fireMode;
		MouseClicked(fireMode,shiftHeld);
	end
	local Position = vecAdd(vecFloor(activeItem.ownerAimPosition()),Offset);
	local NewConfig = SendAndWait(activeItem.ownerEntityId(),"GetConfig");
	if StoredPosition ~= nil and (Config == nil or Config.Breaking ~= NewConfig.Breaking) then
		Config = NewConfig;
		IsValid = nil;
		UpdateCursor();
	else
		Config = NewConfig;
	end
	if vecEq(Position,StoredPosition) == false then
		StoredPosition = Position;
		if PreviousState == "primary" then
			PreviousState = "none";
		end
		IsValid = nil;
		UpdateCursor();
	end
end

local function GetBlock(Material)
	local config = root.materialConfig(Material);
	if config ~= nil and config.config.renderParameters ~= nil and config.config.renderParameters.occludesBelow == true then
		--sb.logInfo("OCCLUDED");
		return FacadeConfig[Config.Index].occludedBlock,true;
	end
	--sb.logInfo("NORMAL");
	return FacadeConfig[Config.Index].normalBlock,false;
end

local function EmbedInBlock(Position)
	local Background = world.material(Position,"background");
	local Foreground = world.material(Position,"foreground");
	if Background == false or Background == nil then
		Background = false;
	end
	if Foreground == false or Foreground == nil then return nil end;
	local HasBackground;
	if Background == false then
		HasBackground = false;
		world.placeMaterial(Position,"background","temporaryBackground",0,true);
	else
		HasBackground = Background;
	end
	local Object,IsOccluded = GetBlock(Foreground);
	--sb.logInfo("Material Above = " .. sb.print(world.objectAt(vecAdd(Position,{0,1}))));
	sb.logInfo("Item = " .. sb.print(ItemConsumed));
	local Info = 
	{
		--ADD OCLUDED BOOLEAN
		Background = HasBackground,
		Foreground = Foreground,
		ForegroundHue = world.materialHueShift(Position,"foreground"),
		ForegroundMod = world.mod(Position,"foreground"),
		ForegroundModHue = world.modHueShift(Position,"foreground"),
		Item = FacadeConfig[Config.Index].item,
		Object = Object,
		IsOccluded = IsOccluded,
		Indicator = FacadeConfig[Config.Index].indicator,
		ExtraParameters = ItemConsumed.parameters,
		Position = Position
	}
	world.damageTiles({Position},"foreground",Position,"explosive",9999,0);
	local Placer = world.spawnProjectile("facadebuilder",vecAdd(Position,{3,3}),activeItem.ownerEntityId());
	world.callScriptedEntity(Placer,"SendInfo",Info);
end

local function OnClick(shiftHeld)
	if IsValid == true then
		if Config.Breaking == false and (player.isAdmin() or player.hasItem({name = FacadeConfig[Config.Index].item,count = 1}) == true) then
			local ConsumedItem = player.getItemWithParameter("ContainsStoredInfoFor",FacadeConfig[Config.Index].item);
			sb.logInfo("Contains Item with stored Info = " .. sb.print(player.hasItemWithParameter("ContainsStoredInfoFor",FacadeConfig[Config.Index].item)));
			if ConsumedItem ~= nil then
				player.consumeItemWithParameter("ContainsStoredInfoFor",FacadeConfig[Config.Index].item,1);
				sb.logInfo("Consumed with parameter");
				ItemConsumed = ConsumedItem;
			else
				if player.isAdmin() == false then
					ItemConsumed = {name = FacadeConfig[Config.Index].item,count = 1};
					sb.logInfo("Consumed without parameter");
					player.consumeItem(ItemConsumed);
				end
			end
			IsValid = false;
			SpawnCursor(false);
			EmbedInBlock(StoredPosition);
		else
			local OBJ = world.objectAt(vecSub(StoredPosition,Offset));
			if OBJ ~= nil then
				IsValid = false;
				SpawnCursor(false);
				world.sendEntityMessage(OBJ,"Destroy",world.entityPosition(activeItem.ownerEntityId()));
			end
		end
	end
end

local function OnRightClick(shiftHeld)
	if shiftHeld == true then
		Config.Breaking = not Config.Breaking;
		world.sendEntityMessage(activeItem.ownerEntityId(),"SetConfig",Config);
		IsValid = nil;
		UpdateCursor();
	else
		local OBJ = world.objectAt(vecFloor(StoredPosition));
		if OBJ ~= nil then
			Promise = world.sendEntityMessage(OBJ,"GetInteraction",activeItem.ownerEntityId());
			SourceOBJ = OBJ;
		else
			activeItem.interact("ScriptPane",UIConfig,activeItem.ownerEntityId());
		end
	end
end

MouseClicked = function(fireMode,shiftHeld)
	if fireMode == "primary" then
		Activated = true;
		OnClick(shiftHeld);
	elseif fireMode == "alt" then
		Activated = true;
		OnRightClick(shiftHeld);
	end
end

function uninit()
	DestroyCursor();
	if Indicators ~= nil then
		for i=1,#Indicators do
			world.sendEntityMessage(Indicators[i],"Destroy");
		end
	end
end

CheckPosition = function(Position)
	--TODO
	if Config.Breaking == false then
		local Material = world.material(Position,"foreground");
		if world.objectAt(Position) == nil and Material ~= nil and Material ~= false and string.find(Material,"metamaterial:") == nil and (world.isTileProtected(Position) == false or player.isAdmin()) then
			return true;
		else
			return false;
		end
	else
		if world.objectAt(Position) ~= nil and world.getObjectParameter(world.objectAt(Position),"IsFacade") == true and (world.isTileProtected(Position) == false or player.isAdmin()) then
			return true;
		else
			return false;
		end
	end
end

SpawnCursor = function(valid)
	DestroyCursor();
	if valid == true then
		if Config.Breaking == true then
			Cursor = world.spawnProjectile("cursorValidR",StoredPosition);
		else
			Cursor = world.spawnProjectile("cursorValid",StoredPosition);
		end
	else
		if Config.Breaking == true then
			Cursor = world.spawnProjectile("cursorInvalidR",StoredPosition);
		else
			Cursor = world.spawnProjectile("cursorInvalid",StoredPosition);
		end
	end
end

DestroyCursor = function()
	if Cursor ~= nil then
		world.sendEntityMessage(Cursor,"Destroy");
	end
end

UpdateCursor = function()
	Activated = false;
	if world.magnitude(world.entityPosition(activeItem.ownerEntityId()),activeItem.ownerAimPosition()) > 10 and player.isAdmin() == false then
		IsValid = nil;
		DestroyCursor();
		return nil;
	end
	local OldValidicity = IsValid;
	local NewValidicity = CheckPosition(vecSub(StoredPosition,Offset));
	if NewValidicity ~= OldValidicity then
		SpawnCursor(NewValidicity);
		IsValid = NewValidicity;
	else
		if Cursor == nil then
			Cursor = world.spawnProjectile("cursorValid",StoredPosition);
		else
			world.sendEntityMessage(Cursor,"SetPosition",StoredPosition);
		end
	end
end

SetupAim = function()
	activeItem.setTwoHandedGrip(false);
	animator.resetTransformationGroup("wrench");
	animator.rotateTransformationGroup("wrench",1.75 * math.pi,{-0.6,0.6});
	animator.translateTransformationGroup("wrench",{0.55,0.3});
end

UpdateAim = function()
	local aim,direction = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end

function uninit()
	if Cursor ~= nil and world.entityExists(Cursor) then
		DestroyCursor();
	end
	activeItem.setInstanceValue("PreviousConfig",Config);
end
