local Speed = 0;
local MinSize = 2;
local MaxSize = 5;
local ItemName = "curvedconduit2x2br";
local Size = MinSize;
local EntityID;
local EntityPosition;

local RequiredConduits;

local Progress = 0;

local AbleToCraft = false;

local function AddHandlers()
	message.setHandler("SetSpeed",function(_,_,speed)
		Speed = speed;
		object.setConfigParameter("Speed",speed);
	end);
	message.setHandler("SetSize",function(_,_,size)
		Size = size;
		Progress = 0;
		object.setConfigParameter("Progress",Progress);
		RequiredConduits = math.floor((2 * (Size ^ 2)) ^ 0.5);
		object.setConfigParameter("Size",size);
	end);
	message.setHandler("SetItemName",function(_,_,itemName)
		ItemName = itemName;
		object.setConfigParameter("ItemName",itemName);
	end);
end

function init()
	EntityPosition = entity.position();
	EntityID = entity.id();
	Speed = config.getParameter("Speed",0);
	Size = config.getParameter("Size",MinSize);
	RequiredConduits = math.floor((2 * (Size ^ 2)) ^ 0.5);
	ItemName = config.getParameter("ItemName","curvedconduit2x2br");
	AddHandlers();
	containerCallback();
end

function update(dt)
	if AbleToCraft == true then
		Progress = Progress + (dt * (Speed + 1));
		--sb.logInfo("Progress = " .. sb.print(Progress));
		object.setConfigParameter("Progress",Progress);
		if Progress >= 1 then
			world.containerConsumeAt(EntityID,0,RequiredConduits);
			world.containerPutItemsAt(EntityID,{name = ItemName,count = 1},1);
			Progress = 0;
			object.setConfigParameter("Progress",Progress);
		end
	end
end

function containerCallback()
	--sb.logInfo("Container Changed!");
	local InputSlot = world.containerItemAt(EntityID,0);
	local OutputSlot = world.containerItemAt(EntityID,1);
	if InputSlot ~= nil and InputSlot.name == "itemconduit" and InputSlot.count >= RequiredConduits and (OutputSlot == nil or (OutputSlot.name == ItemName and OutputSlot.count < 1000)) then
		AbleToCraft = true;
	else
		AbleToCraft = false;
		Progress = 0;
		object.setConfigParameter("Progress",Progress);
	end
	--sb.logInfo("Able To Craft = " .. sb.print(AbleToCraft));
end

function die()
	world.spawnItem({name = "speedupgrade",count = Speed},EntityPosition);
end






































--[[local CanTakeItems = false;
local EntityID = nil;
local ItemName = nil;
local RequiredConduits = nil;
local Speed = nil;

local function SetHandlers()
	message.setHandler("SetValue",function(_,_,name,value)
		object.setConfigParameter(name,value);
	end);
	message.setHandler("SetConduitInfo",function(_,_,itemName,requiredConduits,speed)
		ItemName = itemName;
		RequiredConduits = requiredConduits;
		Speed = speed;
	end);
	message.setHandler("AddToInventory",function()
		world.containerTakeAt(SourceID,0);
		world.containerPutItemsAt(SourceID,{name = ItemName,count = 1},1);
	end);
end

function init()
	EntityID = entity.id();
	Speed = config.getParameter("Speed",0);
	RequiredConduits = math.floor(2 * (config.getParameter("Size",2) ^ 2) ^ 0.5);
	ItemName = config.getParameter("ItemName","curvedconduit2x2br");
	SetHandlers();
	containerCallback();
end

function containerCallback()
	sb.logInfo("Container Changed!");
	local Item = world.containerItemAt(EntityID,0);
	local Output = world.containerItemAt(EntityID,1);
	if Item ~= nil and Item.name == "itemconduit" and Item.count >= RequiredConduits and (Output == nil or Output.name == ItemName) then
		CanTakeItems = true;
	else
		CanTakeItems = false;
	end
	object.setConfigParameter("CanTakeItems",CanTakeItems);
end--]]
