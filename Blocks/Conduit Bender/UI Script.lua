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

--[[function ContainerPutItemsAt(ID,Item,Offset)
	local ContainerSize = world.containerSize(ID);
	if ContainerSize == nil or Offset + 1 > ContainerSize then
		return Item;
	end
	local ItemConfig = root.itemConfig(Item);
	if ItemConfig == nil then
		return Item;
	end
	local MaxStack = ItemConfig.config.maxStack or 1000;
	local ItemInSlot = world.containerItemAt(ID,Offset);
	local RemainingCount = Item.count;
	if ItemInSlot == nil then
		local OriginalCount = Item.count;
		if Item.count > MaxStack then
			Item.count = Item.count - (Item.count - MaxStack);
		end
		RemainingCount = RemainingCount - world.containerItemApply(ID,Item,Offset).count;
		Item.count = OriginalCount;
	else
		if root.itemDescriptorsMatch(ItemInSlot,Item,true) then
			if ItemInSlot.count >= MaxStack then
				return Item;
			else
				local OriginalCount = Item.count;
				if ItemInSlot.count + Item.count > MaxStack then
					Item.count = Item.count - (ItemInSlot.count + Item.count - MaxStack);
				end
				RemainingCount = OriginalCount - Item.count;
				world.containerSwapItems(ID,Item,Offset);
				Item.count = OriginalCount;
			end
		else
			return Item;
		end
	end
	if RemainingCount == 0 then
		return nil;
	end
	return {name = Item.name,count = RemainingCount,parameters = Item.parameters};
end--]]

function init()
	SourceID = pane.containerEntityId();
	RotationIndex = world.getObjectParameter(SourceID,"RotationIndex",1);
	UpdateSpeed(world.getObjectParameter(SourceID,"Speed",0));
	UpdateSize(world.getObjectParameter(SourceID,"Size",MinSize));
	world.sendEntityMessage(SourceID,"SetItemName",ItemName);
	--sb.logInfo("World = " .. sb.print(world));
	--world.containerAddItems(SourceID,{name = "coalore",count = 1});
	--world.containerPutItemsAt(SourceID,{name = "coalore",count = 1},1);
	--[[sb.logInfo("Container Size = " .. sb.print(world.containerSize(SourceID)));
	sb.logInfo("Container Items = " .. sb.print(world.containerItems(SourceID)));
	sb.logInfo("Container Item At = " .. sb.print(world.containerItemAt(SourceID,0)));
	sb.logInfo("Container Consume = " .. sb.print(world.containerConsume(SourceID,({name = "coalore",count = 1}))));
	sb.logInfo("Container Consume At = " .. sb.print(world.containerConsumeAt(SourceID,0,1)));
	sb.logInfo("Container Available = " .. sb.print(world.containerAvailable(SourceID,{name = "coalore",count = 1})));
	sb.logInfo("Container Take All = " .. sb.print(world.containerTakeAll(SourceID)));
	sb.logInfo("Container Add Items = " .. sb.print(world.containerAddItems(SourceID,{name = "coalore",count = 1})));
	sb.logInfo("Container Size = " .. sb.print(world.containerSize(SourceID)));
	sb.logInfo("Container Size = " .. sb.print(world.containerSize(SourceID)));
	sb.logInfo("Container Size = " .. sb.print(world.containerSize(SourceID)));
	sb.logInfo("Container Size = " .. sb.print(world.containerSize(SourceID)));
	sb.logInfo("Container Size = " .. sb.print(world.containerPutItemsAt(SourceID,{name = "coalore",count = 1},1)));
	sb.logInfo("Container Size = " .. sb.print(world.containerTakeAt(SourceID,0)));--]]
	--world.containerSwapItemsNoCombine(SourceID,{name = "coalore",count = 10},0);
	--world.containerItemApply(SourceID,{name = "coalore",count = 10},0);
	--world.sendEntityMessage(SourceID,"PutItemsAt",{name = "coalore",count = 5},0);
	--sb.logInfo("Put Items At = "  .. sb.print(ContainerPutItemsAt(SourceID,{name = "coalore",count = 1005},0)));
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
	--sb.logInfo("Value = " .. sb.print(value));
	widget.setText("size",tostring(value));
	world.sendEntityMessage(SourceID,"SetSize",value);
	RequiredConduits = math.floor((2 * (value ^ 2)) ^ 0.5);
	widget.setText("requiredConduits",tostring(RequiredConduits));	
	UpdateConduit(value);
end

function IncreaseSize()
	local Size = world.getObjectParameter(SourceID,"Size",MinSize);
	--sb.logInfo("Size Type = " .. sb.print(type(Size)));
	if Size < MaxSize then
		--sb.logInfo("Size Before = " .. sb.print(Size));
		Size = Size + 1;
		--sb.logInfo("Size After = " .. sb.print(Size));
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