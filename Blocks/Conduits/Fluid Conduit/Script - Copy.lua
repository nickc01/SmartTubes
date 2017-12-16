local Cables;
local EntityID;
local Speed = 0;

local Sides = {"Left","Right","Top","Bottom","Center"};

local States = {};
local FluidConfigs = setmetatable({}, { __mode = 'v' });
local ItemConfigs = setmetatable({}, { __mode = 'v' });
local Pump;
local LoopBackIter;
local InputPositions;
local OutputPositions;
local InputIndex = 1;
local OutputIndex = 1;
local UpdateSlotItem;

local function GetFluidConfig(Liquid)
	if type(Liquid) == "number" then Liquid = root.liquidName(Liquid) end;
	if FluidConfigs[Liquid] == nil then
		FluidConfigs[Liquid] = root.liquidConfig(Liquid);
	end
	return FluidConfigs[Liquid].config;
end

local function GetItemConfig(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	return ItemConfigs[ItemName].config;
end

local function SetDelta()
	local Value = math.ceil(80 / (((Speed + 1) / 2) + 0.5));
	if Value < 10 then
		Value = 10;
	end
	script.setUpdateDelta(Value);
end

local function vecAdd(A,B,C)
	if C ~= nil then
		return {A[1] + B,A[2] + C};
	else
		return {A[1] + B[1],A[2] + B[2]};
	end
end

local function SideToDirection(Side)
	if Side == "Left" then
		return vecAdd(entity.position(),-1,0);
	elseif Side == "Right" then
		return vecAdd(entity.position(),1,0);
	elseif Side == "Top" then
		return vecAdd(entity.position(),0,1);
	elseif Side == "Bottom" then
		return vecAdd(entity.position(),-1,0);
	elseif Side == "Center" then
		return entity.position();
	end
end

local function UpdateInputsAndOutputs()
	InputPositions = {};
	OutputPositions = {};
	InputIndex = 1;
	OutputIndex = 1;
	for i=1,#Sides do
		if States[Sides[i]] == "Import" then
			InputPositions[#InputPositions + 1] = SideToDirection(Sides[i]);
		elseif States[Sides[i]] == "Export" then
			OutputPositions[#OutputPositions + 1] = SideToDirection(Sides[i]);
		end
	end
end

LoopBackIter = function(tbl,startIndex)
	startIndex = startIndex or 1;
	if #tbl > 0 then
		local StartIndex = startIndex;
		StartIndex = StartIndex + 1;
		if StartIndex > #tbl then
			StartIndex = 1;
		end
		local Indexer = 1;
		local MaxIndexer = #tbl;
		return function()
			if Indexer <= MaxIndexer then
				local Value = tbl[StartIndex];
				StartIndex = StartIndex + 1;
				if StartIndex > #tbl then
					StartIndex = 1;
				end
				Indexer = Indexer + 1;
				return StartIndex,Value;
			end
		end
	else
		return function() return nil end;
	end
end

function init()
	ContainerCore.Init(5);
	EntityID = entity.id();
	Cables = CableCore;
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	message.setHandler("SetState",function(_,_,Side,state)
		States[Side] = state;
		object.setConfigParameter(Side .. "State",state);
		UpdateInputsAndOutputs();
	end);
	message.setHandler("SetSpeed",function(_,_,speed)
		Speed = speed;
		SetDelta();
	end);
	Speed = config.getParameter("Speed",0);
	SetDelta();
	for i=1,#Sides do
		States[Sides[i]] = config.getParameter(Sides[i] .. "State","Disabled");
	end
	UpdateInputsAndOutputs();
	UpdateSlotItem();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	else
		Pump();
		script.setUpdateDelta(1);
		--ContainerCore.ContainerAddItems({name = "coalore",count = 1});
		--sb.logInfo("ContainerItems = " .. sb.print(ContainerCore.ContainerItemsRef()));
	end
end

local SlotItem = nil;

UpdateSlotItem = function()
	local item = world.containerItemAt(entity.id(),0);
	if item ~= nil then
		SlotItem = item.name;
	else
		SlotItem = "none";
	end
end

local LiquidBuffers = setmetatable({},{__mode = "v"});
--local Buffer;

Pump = function()
	--sb.logInfo("Test");
	--sb.logInfo("Input Positions = " .. sb.print(InputPositions));
	for k,i in LoopBackIter(InputPositions,InputIndex) do
		InputIndex = k;
		--sb.logInfo("Looping");
		local Liquid = world.liquidAt(i);
		if Liquid ~= nil then
			local LiquidConfig = GetFluidConfig(Liquid[1]);
			if ContainerCore.ContainerItemsCanFit({name = LiquidConfig.itemDrop,count = 1}) > 0 then
				world.destroyLiquid(i);
				--sb.logInfo("Liquid = " .. sb.print(Liquid));
				local LiquidName = root.liquidName(Liquid[1]);
				if LiquidBuffers[LiquidName] == nil then
					LiquidBuffers[LiquidName] = 0;
				end
				--[[if Liquid[1] ~= BufferLiquid then
					Buffer = 0;
					BufferLiquid = Liquid[1];
				end--]]
				--sb.logInfo(sb.printJson(GetFluidConfig(Liquid[1])));
				local OriginalBuffer = LiquidBuffers[LiquidName];
				LiquidBuffers[LiquidName] = LiquidBuffers[LiquidName] + Liquid[2];
				if LiquidBuffers[LiquidName] >= 1 then
					local Item = {name = LiquidConfig.itemDrop,count = math.floor(LiquidBuffers[LiquidName])}
					if Item.count > 1000 then
						Item.count = 1000;
					end
					if ContainerCore.ContainerItemsCanFit(Item) > 0 then
						ContainerCore.ContainerAddItems(Item);
						LiquidBuffers[LiquidName] = LiquidBuffers[LiquidName] - Item.count;
					else
						Item.count = 1;
						if ContainerCore.ContainerItemsCanFit(Item) > 0 then
							ContainerCore.ContainerAddItems(Item);
							LiquidBuffers[LiquidName] = LiquidBuffers[LiquidName] - Item.count;
						else
							LiquidBuffers[LiquidName] = OriginalBuffer;
						end
					end
					--[[local Result = ContainerCore.ContainerAddItems({name = LiquidConfig.itemDrop,count = math.floor(Buffer)});
					sb.logInfo("Result = " .. Result);
					if Result == nil then
						Buffer = Buffer - math.floor(Buffer);
						world.destroyLiquid(i);
					else
						Buffer = OriginalBuffer;
					end--]]
				end
				break;
			end
		end
		--[[if Liquid[2] == 1 then
			sb.logInfo(sb.printJson(GetFluidConfig(Liquid[1])));
		end--]]
	end
end

local Dying = false;

function die()
	Dying = true;
	Cables.Uninitialize();
	local Position;
	if Facaded == true and GetDropPosition ~= nil then
		Position = GetDropPosition();
	end
	ContainerCore.Uninit(true,Position);
end

function uninit()
	if Dying == false then
		local Position;
		if Facaded == true and GetDropPosition ~= nil then
			Position = GetDropPosition();
		end
		ContainerCore.Uninit(false,Position);
	end
end
