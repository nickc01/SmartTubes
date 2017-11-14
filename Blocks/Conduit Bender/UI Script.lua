local SpeedMax = 10;
local MaxSize = 5;
local MinSize = 2;
local RequiredConduits = 2;
local SourceID;
local BeginningPath = "/Blocks/Conduits/Curved/";
local ItemName = nil;

local CanTakeItems = false;
local Progress = 0;

local RotationIndex = 1;

local Rotations = {"BR","BL","TL","TR"};

local UpdateSpeed = nil;
local UpdateSize = nil;
local UpdateConduit = nil;

function init()
	SourceID = pane.containerEntityId();
	RotationIndex = world.getObjectParameter(SourceID,"RotationIndex",1);
	UpdateSpeed(world.getObjectParameter(SourceID,"Speed",0));
	UpdateSize(world.getObjectParameter(SourceID,"Size",MinSize));
	world.sendEntityMessage(SourceID,"SetItemName",ItemName);
end

function update(dt)
	Progress = world.getObjectParameter(SourceID,"Progress",0);
	widget.setProgress("progress",Progress);
end

function die()
	
end

function uninit()
	
end

function RotateLeft()
	RotationIndex = RotationIndex - 1;
	if RotationIndex < 1 then
		RotationIndex = #Rotations;
	end
	world.sendEntityMessage(SourceID,"SetValue","RotationIndex",RotationIndex);
	UpdateConduit();
end

function RotateRight()
	RotationIndex = RotationIndex + 1;
	if RotationIndex > #Rotations then
		RotationIndex = 1;
	end
	world.sendEntityMessage(SourceID,"SetValue","RotationIndex",RotationIndex);
	UpdateConduit();
end

UpdateConduit = function(Size)
	if Size == nil then Size = world.getObjectParameter(SourceID,"Size",MinSize) end;
	widget.setImage("conduitToCraft",BeginningPath .. Size .. "x/" .. Rotations[RotationIndex] .. "/Curve.png:default.0");
	ItemName = "curvedconduit" .. Size .. "x" .. Size .. string.lower(Rotations[RotationIndex]);
	world.sendEntityMessage(SourceID,"SetItemName",ItemName);
	widget.setPosition("conduitToCraft",{53 + (4 * (5 - Size)),28 + (4 * (5 - Size))});
end

UpdateSize = function(value)
	sb.logInfo("Value = " .. sb.print(value));
	widget.setText("size",tostring(value));
	world.sendEntityMessage(SourceID,"SetSize",value);
	RequiredConduits = math.floor((2 * (value ^ 2)) ^ 0.5);
	widget.setText("requiredConduits",tostring(RequiredConduits));	
	UpdateConduit(value);
end

function IncreaseSize()
	local Size = world.getObjectParameter(SourceID,"Size",MinSize);
	sb.logInfo("Size Type = " .. sb.print(type(Size)));
	if Size < MaxSize then
		sb.logInfo("Size Before = " .. sb.print(Size));
		Size = Size + 1;
		sb.logInfo("Size After = " .. sb.print(Size));
		UpdateSize(Size);
	end
end

function DecreaseSize()
	local Size = world.getObjectParameter(SourceID,"Size",MinSize);
	if Size > MinSize then
		Size = Size - 1;
		UpdateSize(Size);
	end
end

UpdateSpeed = function(value)
	widget.setText("speedUpgrades",tostring(value));
	world.sendEntityMessage(SourceID,"SetSpeed",value);
end

function IncreaseSpeed()
	local Speed = world.getObjectParameter(SourceID,"Speed",0);
	if Speed < SpeedMax and player.consumeItem({name = "speedupgrade",count = 1}) ~= nil then
		Speed = Speed + 1;
		UpdateSpeed(Speed);
	end
end

function DecreaseSpeed()
	local Speed = world.getObjectParameter(SourceID,"Speed",0);
	if Speed > 0 then
		Speed = Speed - 1;
		player.giveItem({name = "speedupgrade",count = 1});
		UpdateSpeed(Speed);
	end
end