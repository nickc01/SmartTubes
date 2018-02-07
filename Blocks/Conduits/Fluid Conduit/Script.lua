local Cables;
local EntityID;
local Speed = 0;

local Sides = {"Left","Right","Top","Bottom","Center"};

local States = {};
local LiquidConfigs = setmetatable({}, { __mode = 'v' });
local ItemConfigs = setmetatable({}, { __mode = 'v' });
local Pump;
local LoopBackIter;
local InputPositions;
local OutputPositions;
local InputIndex = 1;
local OutputIndex = 1;
--local UpdateSlotItem;
local Mode = "Fill";
local Active = true;

local function GetLiquidConfig(Liquid)
	if type(Liquid) == "number" then Liquid = root.liquidName(Liquid) end;
	if LiquidConfigs[Liquid] == nil then
		LiquidConfigs[Liquid] = root.liquidConfig(Liquid);
	end
	return LiquidConfigs[Liquid].config;
end

local function GetItemConfig(ItemName)
	if ItemConfigs[ItemName] == nil then
		ItemConfigs[ItemName] = root.itemConfig(ItemName);
	end
	return ItemConfigs[ItemName].config;
end

local function SetDelta()
	local Value = math.ceil(((Speed * Speed) / 200) - (3.05 * Speed) + 60);
	--[[if Value < 10 then
		Value = 10;
	end--]]
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
		return vecAdd(entity.position(),0,-1);
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
	object.smash();
	ContainerCore.Init(24);
	EntityID = entity.id();
	Cables = CableCore;
	Mode = config.getParameter("OutputMode","ToLevel");
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	message.setHandler("SetState",function(_,_,Side,state)
		States[Side] = state;
		object.setConfigParameter(Side .. "State",state);
		UpdateInputsAndOutputs();
	end);
	message.setHandler("SetSpeed",function(_,_,speed)
		Speed = speed;
		object.setConfigParameter("Speed",speed);
		SetDelta();
	end);
	message.setHandler("SetMode",function(_,_,mode)
		Mode = mode;
		object.setConfigParameter("OutputMode",Mode);
	end);
	Speed = config.getParameter("Speed",0);
	SetDelta();
	for i=1,#Sides do
		States[Sides[i]] = config.getParameter(Sides[i] .. "State","Disabled");
	end
	UpdateInputsAndOutputs();
	--UpdateSlotItem();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	else
		if Active == true then
			Pump();
		end
		--script.setUpdateDelta(1);
		--ContainerCore.ContainerAddItems({name = "coalore",count = 1});
		--sb.logInfo("ContainerItems = " .. sb.print(ContainerCore.ContainerItemsRef()));
	end
end

function onInputNodeChange(args)
	--sb.logInfo("Active = " .. sb.print(not args.level));
	Active = not args.level;
end

function onNodeConnectionChange()
	Active = not object.getInputNodeLevel(0);
end

--local SlotItem = nil;

--[[UpdateSlotItem = function()
	local item = world.containerItemAt(entity.id(),0);
	if item ~= nil then
		SlotItem = item.name;
	else
		SlotItem = "none";
	end
end--]]

local LiquidBuffers = setmetatable({},{__mode = "v"});

local function FindValidLiquidItem()
	for i=1,ContainerCore.ContainerSize() do
		--sb.logInfo("I = " .. sb.print(i));
		local Item = ContainerCore.ContainerItemAt(i - 1);
		if Item ~= nil then
			local Config = GetItemConfig(Item.name);
			if Config.liquid ~= nil then
				return Item,Config.liquid;
			end
		end
		--[[if Item ~= nil and Config.liquid ~= nil then
			return Item,Config.liquid;
		end--]]
	end
end

local function PumpLiquid(Position,TargetAmount)
	local MaxAmount = TargetAmount or 1.0;
	local Liquid = world.liquidAt(Position);
	--sb.logInfo("Here");
	if Liquid == nil then
		Liquid = {0,0};
	end
	if Liquid[2] <= MaxAmount then
		local Item,LiquidName = FindValidLiquidItem();
		if Item ~= nil then
			--local LiquidName = Item.liquid;
			if LiquidBuffers[LiquidName] == nil then
				local AmountCanFit = ContainerCore.ContainerItemsCanFit({name = Item.name,count = 1});
				LiquidBuffers[LiquidName] = {Amount = 0,Open = (AmountCanFit > 0)};
			end
			if world.material(Position,"foreground") == false then
				if LiquidBuffers[LiquidName].Amount >= (MaxAmount - Liquid[2]) then
					if world.spawnLiquid(Position,root.liquidId(LiquidName),MaxAmount - Liquid[2]) then
						LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (MaxAmount - Liquid[2]);
					end
				else
					if world.spawnLiquid(Position,root.liquidId(LiquidName),MaxAmount - Liquid[2]) and ContainerCore.ContainerAvailable(Item) > 0 then
						local AmountTaken = math.ceil(MaxAmount - LiquidBuffers[LiquidName].Amount);
						--sb.logInfo("Amount Taken = " .. sb.print(AmountTaken));
						--sb.logInfo("LiquidBuffer = " .. sb.print(LiquidBuffers[LiquidName].Amount));

						LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount + AmountTaken;
						LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (MaxAmount - Liquid[2]);
						--sb.logInfo("LiquidBuffer MID = " .. sb.print(LiquidBuffers[LiquidName].Amount));
						if LiquidBuffers[LiquidName].Amount > 1.0 then
							--sb.logInfo("Changing");
							local Modulus = LiquidBuffers[LiquidName].Amount % 1;
							--sb.logInfo("Modulus = " .. sb.print(Modulus));
							local Difference = LiquidBuffers[LiquidName].Amount - Modulus;
							AmountTaken = AmountTaken - Difference;
							LiquidBuffers[LiquidName].Amount = Modulus;
						end
						--sb.logInfo("LiquidBuffer FINAL = " .. sb.print(LiquidBuffers[LiquidName].Amount));
						--Item.count = Item.count - AmountTaken;
						--sb.logInfo("Consuming = " .. sb.print(Item) .. " Count = " .. sb.print(AmountTaken));
						ContainerCore.ContainerConsume(Item,AmountTaken);
						--sb.logInfo("Consumed = " .. sb.print(ContainerCore.ContainerConsume(Item,AmountTaken)));
								
					end
				end
			end
		end
	end
end
--local Buffer;

Pump = function()
	for k,i in LoopBackIter(InputPositions,InputIndex) do
		--sb.logInfo("Input Position " .. k);
		InputIndex = k;
		local Liquid = world.liquidAt(i);
		if Liquid ~= nil then
			local LiquidName = root.liquidName(Liquid[1]);
			local LiquidConfig = GetLiquidConfig(Liquid[1]);
			if LiquidBuffers[LiquidName] == nil then
				local AmountCanFit = ContainerCore.ContainerItemsCanFit({name = LiquidConfig.itemDrop,count = 1});
				LiquidBuffers[LiquidName] = {Amount = 0,Open = (AmountCanFit > 0)};
			end
			if LiquidBuffers[LiquidName].Open then
				LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount + world.destroyLiquid(i)[2];
			end
		end
	end
	--[[sb.logInfo("Input Positions = " .. sb.print(InputPositions));
	for k,i in LoopBackIter(InputPositions,InputIndex) do
		InputIndex = k;
		--sb.logInfo("Looping");
		local Liquid = world.liquidAt(i);
		if Liquid ~= nil then
			local LiquidConfig = GetFluidConfig(Liquid[1]);
			if ContainerCore.ContainerItemsCanFit({name = LiquidConfig.itemDrop,count = 1}) > 0 then
				world.destroyLiquid(i);
				sb.logInfo("Liquid = " .. sb.print(Liquid));
				local LiquidName = root.liquidName(Liquid[1]);
				if LiquidBuffers[LiquidName] == nil then
					LiquidBuffers[LiquidName] = 0;
				end
				if Liquid[1] ~= BufferLiquid then
					Buffer = 0;
					BufferLiquid = Liquid[1];
				end
				sb.logInfo(sb.printJson(GetFluidConfig(Liquid[1])));
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
					end
				end
				break;
			end
		end
		--[[if Liquid[2] == 1 then
			sb.logInfo(sb.printJson(GetFluidConfig(Liquid[1])));
		end
	end--]]





	--for i=#LiquidBuffers,1,-1 do
	for k,i in pairs(LiquidBuffers) do
		if i.Amount > 1 then
			local Item = {name = GetLiquidConfig(k).itemDrop,count = 1}
			local AmountCanFit = ContainerCore.ContainerItemsCanFit(Item);
			if AmountCanFit > 0 then
				LiquidBuffers[k].Open = true;
				--sb.logInfo("AmountCanFit = " .. sb.print(AmountCanFit));
				--sb.logInfo("I.Amount = " .. sb.print(i.Amount));
				if AmountCanFit > i.Amount then
					AmountCanFit = math.floor(i.Amount);
				end
				Item.count = AmountCanFit;
				ContainerCore.ContainerAddItems(Item);
				LiquidBuffers[k].Amount = LiquidBuffers[k].Amount - Item.count;
				Item.count = 1;
				if ContainerCore.ContainerItemsCanFit(Item) > 0 then
					Open = true;
				else
					Open = false;
				end
			else
				LiquidBuffers[k].Open = false;
			end
		end
	end
	for k,i in LoopBackIter(OutputPositions,OutputIndex) do
		OutputIndex = k;
		if Mode == "ToLevel" then
			--[[local Liquid = world.liquidAt(i);
			sb.logInfo("Here");
			if Liquid == nil then
				Liquid = {0,0};
			end
			if Liquid[2] <= 1 then
				local Item,LiquidName = FindValidLiquidItem();
				if Item ~= nil then
					--local LiquidName = Item.liquid;
					if LiquidBuffers[LiquidName] == nil then
						local AmountCanFit = ContainerCore.ContainerItemsCanFit({name = Item.name,count = 1});
						LiquidBuffers[LiquidName] = {Amount = 0,Open = (AmountCanFit > 0)};
					end
					if world.material(i,"foreground") == false then
						if LiquidBuffers[LiquidName].Amount >= (1 - Liquid[2]) then
							if world.spawnLiquid(i,root.liquidId(LiquidName),1 - Liquid[2]) then
								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (1 - Liquid[2]);
							end
						else
							if world.spawnLiquid(i,root.liquidId(LiquidName),1 - Liquid[2]) then
								ContainerCore.ContainerConsume(Item,1);
								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount + 1;
								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (1 - Liquid[2]);
							end
						end
					end
				end
			end--]]
			PumpLiquid(i,1.0);
		elseif Mode == "Fill" then
			PumpLiquid(i,1.5);
			--[[local Liquid = world.liquidAt(i);
			--sb.logInfo("Here");
			if Liquid == nil then
				Liquid = {0,0};
			end
			local MaxAmount = 1.5;
			if Liquid[2] <= MaxAmount then
				local Item,LiquidName = FindValidLiquidItem();
				if Item ~= nil then
					--local LiquidName = Item.liquid;
					if LiquidBuffers[LiquidName] == nil then
						local AmountCanFit = ContainerCore.ContainerItemsCanFit({name = Item.name,count = 1});
						LiquidBuffers[LiquidName] = {Amount = 0,Open = (AmountCanFit > 0)};
					end
					if world.material(i,"foreground") == false then
						if LiquidBuffers[LiquidName].Amount >= (MaxAmount - Liquid[2]) then
							if world.spawnLiquid(i,root.liquidId(LiquidName),MaxAmount - Liquid[2]) then
								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (MaxAmount - Liquid[2]);
							end
						else
							if world.spawnLiquid(i,root.liquidId(LiquidName),MaxAmount - Liquid[2]) and ContainerCore.ContainerAvailable(Item) > 0 then
								local AmountTaken = math.ceil(MaxAmount - LiquidBuffers[LiquidName].Amount);
								--sb.logInfo("Amount Taken = " .. sb.print(AmountTaken));
								--sb.logInfo("LiquidBuffer = " .. sb.print(LiquidBuffers[LiquidName].Amount));

								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount + AmountTaken;
								LiquidBuffers[LiquidName].Amount = LiquidBuffers[LiquidName].Amount - (MaxAmount - Liquid[2]);
								--sb.logInfo("LiquidBuffer MID = " .. sb.print(LiquidBuffers[LiquidName].Amount));
								if LiquidBuffers[LiquidName].Amount > 1.0 then
									--sb.logInfo("Changing");
									local Modulus = LiquidBuffers[LiquidName].Amount % 1;
									--sb.logInfo("Modulus = " .. sb.print(Modulus));
									local Difference = LiquidBuffers[LiquidName].Amount - Modulus;
									AmountTaken = AmountTaken - Difference;
									LiquidBuffers[LiquidName].Amount = Modulus;
								end
								--sb.logInfo("LiquidBuffer FINAL = " .. sb.print(LiquidBuffers[LiquidName].Amount));
								--Item.count = Item.count - AmountTaken;
								--sb.logInfo("Consuming = " .. sb.print(Item) .. " Count = " .. sb.print(AmountTaken));
								ContainerCore.ContainerConsume(Item,AmountTaken);
								--sb.logInfo("Consumed = " .. sb.print(ContainerCore.ContainerConsume(Item,AmountTaken)));
								
							end
						end
					end
				end
			end--]]
		end
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
