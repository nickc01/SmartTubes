require("/Core/Debug.lua");
local Cables;
local Active = false;

local Controllers = {};

ExtractAndSend = nil;
local AddHandlers;
local UpdateController;
local GetController;
local SetController;
local Containers;
local ContainerToControllerIndex;
local EntityID;
local StoredRegion;
local CombinePredictions;
local BuildPrediction;
local FindSlot;
local Colors;
local AddAllPredictions;
--local AllTraversals;
local DropItems;
local ChangeTransferID;
local AddToInventory;
local RemapContainers;
local Threshold = 57;
local CramTraversal;
local PredictionAdditionRate;
local CrammedTraversals = {};
local PredictionCount = 0;
local FPS;
--local AllTraversals;
--local AllTraversalIter;
--local TestIter;

local Predictions = {};
local PredictionsForDumping = {};

local oldInit = init;
local Ready = false;
local EntityPosition = nil;

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function NonZero(A)
	if A == 0 then
		return 1;
	else
		return A;
	end
end

local function Average(A)
	local Total = 0;
	for i=1,#A do
		Total = Total + A[i];
	end
	return Total / #A;
end
local function ShakerLoop(tbl)
	local TableSize = #tbl;
	local Starter = (TableSize / 2) - ((TableSize / 2) % 2);
	local Up = Starter + 2;
	local Down = Starter - 2;
	local OddStart = Starter + 1;
	local OddUp = OddStart + 2;
	local OddDown = OddStart - 2;
	local DoUp = true;
	local DoEven = true;
	local StartOutputted = false;
	if Up > TableSize or Down < 1 or OddUp > TableSize or OddDown < 1 then
		local Indexer = 1;
		return function()
			if Indexer > TableSize then
				return nil;
			else
				Indexer = Indexer + 1;
				return Indexer - 1;
			end
		end
	else
		local Iter;
		Iter = function(doUp)
			if StartOutputted == false then
				StartOutputted = true;
				return Starter;
			end
				if doUp then
					if Up > TableSize then
						if Down < 1 then
							if DoEven == true then
								DoEven = false;
								Starter = OddStart;
								StartOutputted = false;
								Up = OddUp;
								Down = OddDown;
								DoUp = true;
								return Iter(DoUP);
							else
								return nil;
							end
						else
							return Iter(not doUp);
						end
					else
						Up = Up + 2;
						DoUp = not DoUp;
						return Up - 2;
					end
				else
					if Down < 1 then
						if Up > TableSize then
							if DoEven == true then
								DoEven = false;
								DoUp = true;
								Up = OddUp;
								Down = OddDown;
								Starter = OddStart;
								StartOutputted = false;
								return Iter(DoUP);
							else
								return nil;
							end
						else
							return Iter(not doUp);
						end
					else
						Down = Down - 2;
						DoUp = not DoUp;
						return Down + 2;
					end
				end
		end
		return function()
			return Iter(DoUp);
		end
	end
end

local function GetFPS()
	local Time = os.clock();
	local Averager = {60,60,60,60,60,60};
	GetFPS = function()
		local NewTime = os.clock();
		local FPS = 1 / ((NewTime - Time) / (60 * script.updateDt()));
		Averager[1],Averager[2],Averager[3],Averager[4],Averager[5],Averager[6] = Averager[2],Averager[3],Averager[4],Averager[5],Averager[6],FPS;
		Time = NewTime;
		return Average(Averager);
	end
	return 60.0000;
end

function init()
	--<TEST>
	--Active = true;
	--</TEST>
	--[[local TestArray = {1,2,3,4,5,6,7,8,9,10}
	DPrint("STARTARRAY");
	for i in ShakerLoop(TestArray) do
		DPrint(sb.print(i));
	end
	DPrint("ENDARRAY");--]]
	Cables = CableCore;
	EntityID = entity.id();
	if oldInit ~= nil then
		oldInit();
	end
	AddHandlers();
	Colors = {};
	script.setUpdateDelta(1);
	StoredRegion = config.getParameter("StoredRegion");
	Predictions = config.getParameter("Predictions",{});
	PredictionsForDumping = config.getParameter("Dump",{});
	for k,i in ipairs(root.assetJson("/Projectiles/Traversals/Colors.json").Colors) do
		Colors[i[1]] = i[2];
	end
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddCondition("Containers","objectType",function(value) return value == "container" end);
	Cables.AddAfterFunction(UpdateController);
	InsertID = config.getParameter("insertID");
	if InsertID == nil then
		InsertID = "";
		object.setConfigParameter("insertID",InsertID);
	end
	EntityPosition = entity.position();
end

AddHandlers = function()
	message.setHandler("ExtractAndSend",ExtractAndSend);
	message.setHandler("DropItems",DropItems);
	message.setHandler("ChangeTransferID",ChangeTransferID);
	message.setHandler("AddToInventory",AddToInventory);
	message.setHandler("SetInsertID",function(_,_,id)
		InsertID = id;
		Cables.UpdateExtractionConduits();
		object.setConfigParameter("insertID",id);
	end);
end

local oldUpdate = update;
local First = false;

local function FirstUpdate()
	StoredRegion = config.getParameter("StoredRegion");
	if StoredRegion == nil then
		local EntityPosition = entity.position();
		StoredRegion = {EntityPosition[1] - 5,EntityPosition[2] - 5,EntityPosition[1] + 5,EntityPosition[2] + 5};
	end
	--DPrint("REGION = " .. sb.print(StoredRegion));
	world.loadRegion(StoredRegion);
end

local CrammingCoroutine;

function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
		FirstUpdate();
	end
	if oldUpdate ~= nil then
		oldUpdate(dt);
	end
	Cables.Update();
	if Ready == false then
		if world.regionActive(StoredRegion) == true then
			RemapContainers();
			--DPrint("REG_IS = " .. sb.print(StoredRegion));
			AddAllPredictions();
			Ready = true;
		end
	end
	for i=#CrammedTraversals,1,-1 do
		local T = CrammedTraversals[i];
		T.Clock = T.Clock + (dt * T.Speed);
		if T.Clock > 1 then
			T.Index,T.Clock = T.Index - 1,0;
			if T.Index == 1 then
				AddToInventory(_,_,T.Traversal,T.Container);
				--DPrint("Adding to Inventory of " .. sb.print(T.Container));
				table.remove(CrammedTraversals,i);
			else
				--DPrint("Path Index = " .. sb.print(T.Path[T.Index]));
				if world.entityExists(T.Path[T.Index]) == false or world.getObjectParameter(T.Path[T.Index],"conduitType") == nil then
					DropItems(_,_,T.Traversal,T.Container,T.Position);
				else
					T.Position = world.entityPosition(T.Path[T.Index]);
				end
			end
		end
	end
	FPS = GetFPS();
	--DPrint("FPS = " .. sb.print(FPS));
	--DPrint("Threshold = " .. sb.print(Threshold));
	--DPrint("Less = " .. sb.print(FPS < Threshold));
	--[[DPrint("FPS = " .. sb.print(GetFPS()));
	DPrint("Threshold = " .. sb.print(Threshold));
	DPrint("Less = " .. sb.print(Threshold > GetFPS()));
	DPrint("Subtract = " .. sb.print(GetFPS() - Threshold));
	DPrint("FPS Type = " .. sb.print(type(GetFPS())));--]]
	--if FPS < Threshold then
	--	DPrint("Cramming");
	--	CramTraversal();
	--end
end

CramTraversal = function()
	if CrammingCoroutine == nil then
		CrammingCoroutine = coroutine.create(function() 
		--DPrint("PredictionCount = " .. sb.print(PredictionCount));
		local Counter = 0;
		local MaxCounter = math.ceil(NonZero(PredictionCount) / 10)
		MaxCounter = 1;
		--for j = 0,math.ceil(NonZero(PredictionCount) / 10) do
			for k,i in pairs(Predictions) do
				if i == nil then 
					CrammingCoroutine = nil;
					return nil;
				end
				for m in ShakerLoop(i) do
					local n = i[m];
					if n == nil then 
						CrammingCoroutine = nil;
						return nil;
					end
					if n.Crammed ~= true and world.entityExists(n.TraversalID) then
						--world.sendEntityMessage(n.TraversalID,"ForceDestroy");
						local Info = world.callScriptedEntity(n.TraversalID,"StartCramming");
						--DPrint("Path = " .. sb.print(Info.Path));
						--DPrint("PathIndex = " .. sb.print(Info.Index));
						--DPrint("Speed = " .. sb.print(Info.Speed));
						n.Crammed = true;
						PredictionCount = PredictionCount - 1;
						CrammedTraversals[#CrammedTraversals + 1] = {Path = Info.Path,Index = Info.Index,Speed = Info.Speed,Clock = 0,Traversal = n.TraversalID,Container = n.Container,SetPosition = Info.Position};
						Counter = Counter + 1;
						if Counter >= MaxCounter then
							coroutine.yield();
							Counter = 0;
						end
					end
				end
			end
			CrammingCoroutine = nil;
			return nil;
		end);
	end
	coroutine.resume(CrammingCoroutine);
end

local function AddPredictionGroup(ContainerID)
	Predictions[tostring(ContainerID)] = {};
end

local function GetPredictionGroup(ContainerID)
	ContainerID = tostring(ContainerID);
	if Predictions[ContainerID] == nil then
		Predictions[ContainerID] = {};
	end
	return Predictions[ContainerID];
end

local function AddPredictionAndSend(prediction)
	local predictionList = GetPredictionGroup(prediction.Container);
	local Contained = false;
	PredictionCount = PredictionCount + 1;
	predictionList[#predictionList + 1] = prediction;
end

local function GetDump(ContainerID)
	ContainerID = tostring(ContainerID);
	if PredictionsForDumping[ContainerID] == nil then
		PredictionsForDumping[ContainerID] = {};
	end
	return PredictionsForDumping[ContainerID];
end
local function AddToDump(ContainerID,value)
	ContainerID = tostring(ContainerID);
	if PredictionsForDumping[ContainerID] == nil then
		PredictionsForDumping[ContainerID] = {};
	end
	PredictionsForDumping[ContainerID][#PredictionsForDumping[ContainerID] + 1] = value;
end

--[[AllTraversals = function()
	local ContainerIndex = nil;
	local ContainerIndex,Container = next(Predictions,ContainerIndex);
	if Container == nil then return function() return nil end end;
	local NumberIndex = nil;
	local Number;
	local RestartLoop;
	RestartLoop = function()
		ContainerIndex,Container = next(Predictions,ContainerIndex);
		if ContainerIndex == nil then
			return nil;
		else
			NumberIndex = nil;
			NumberIndex,Number = next(Container,NumberIndex);
			if Number == nil then
				return RestartLoop();
			else
				return ContainerIndex,Number.TraversalID;
			end
		end
	end
	return function()
		NumberIndex,Number = next(Container,NumberIndex);
		if NumberIndex == nil then
			return RestartLoop();
		else
			return ContainerIndex,Number.TraversalID;
		end
	end
end--]]

--[[AllTraversals = function()
	local List = {};
	for k,i in pairs(Predictions) do
		DPrint("i = " .. sb.print(i));
		for m,n in ipairs(i) do
			DPrint("n = " .. sb.print(n));
			List[#List + 1] = n.TraversalID;
		end
	end
	return List;
end--]]

--[[AllTraversalIter = function()
	local BeginningIter = pairs(Predictions);
	local FirstK,FirstI = BeginningIter(Predictions);
	if FirstI == nil then return nil end;

	return function()
		return BeginningIter(Predictions);
	end
end--]]

--[[AllTraversals = function()
	local BeginningIter = pairs(Predictions);
	local _,CurrentBeginningValue = BeginningIter(Predictions);
end--]]

--[[AllTraversals = function()
	local BeginningIter = pairs(Predictions);
	local _,CurrentBeginningValue = BeginningIter(Predictions);
	if CurrentBeginningValue == nil then return nil end;
	local NumIter = ipairs(CurrentBeginningValue);
	local RefreshIters;
	RefreshIters = function()
		_,CurrentBeginningValue = BeginningIter();
		if CurrentBeginningValue == nil then
			return nil;
		else
			NumIter = ipairs(CurrentBeginningValue);
			local _,value = NumIter(CurrentBeginningValue);
			if value == nil then
				return RefreshIters();
			else
				return value;
			end
		end
	end
	return function()
		local _,value = NumIter(CurrentBeginningValue);
		if value == nil then
			value = RefreshIters();
		end
		return value;
	end
end--]]
ChangeTransferID = function(_,_,From,To,ContainerID)
	local Index = ContainerToControllerIndex(ContainerID);
	if Index == nil then return nil end;
	local C = GetController(Index);
	if C.Master ~= EntityID then
		world.sendEntityMessage(C.Master,"ChangeTransferID",From,To,ContainerID);
		return nil;
	end
	for m,n in pairs(Predictions) do
		for x=1,#n do
			if n[x].TraversalID == From then
				n[x].TraversalID = To;
			end
		end
	end
	for m,n in pairs(PredictionsForDumping) do
		for x=1,#n do
			if n[x].TraversalID == From then
				n[x].TraversalID = To;
			end
		end
	end
end

function ConduitIsConnectedTo(ID)
	for i=1,4 do
		if Cables.CableTypes.Containers ~= nil and Cables.CableTypes.Containers[i] == ID then
			return true;
		end
	end
	return false;
end

function IsMasterOf(ID)
	local Index = ContainerToControllerIndex(ID);
	if Index ~= nil and GetController(Index).Master == EntityID then
		return true;
	end
	return false;
end

local function SpacesToRect(spaces,position)
	local LowX,HighX,LowY,HighY = nil,nil,nil,nil;
	for i=1,#spaces do
		if LowX == nil or spaces[i][1] < LowX then
			LowX = spaces[i][1];
		end
		if HighX == nil or spaces[i][1] > HighX then
			HighX = spaces[i][1];
		end
		if LowY == nil or spaces[i][2] < LowY then
			LowY = spaces[i][2];
		end
		if HighY == nil or spaces[i][2] > HighY then
			HighY = spaces[i][2];
		end
	end
	return {position[1] + LowX,position[2] + LowY,position[1] + HighX,position[2] + HighY};
end

local function GetConduitsAtContainer(ID)
	local Rect = SpacesToRect(world.objectSpaces(ID),world.entityPosition(ID));
	local Objects = world.objectQuery({Rect[1] - 1,Rect[2] - 1},{Rect[3] + 1,Rect[4] + 1});
	local Conduits = {};
	local SelfID = entity.id();
	for i=1,#Objects do
		if Objects[i] ~= SelfID and world.callScriptedEntity(Objects[i],"ConduitIsConnectedTo",ID) == true then
			Conduits[#Conduits + 1] = Objects[i];
		end
	end
	return Conduits;
end

local function ChangeController(Index,value)
	--DPrint("INDEX_____ = " .. sb.print(Index));
	--DPrint(EntityID .. " Region Loaded = " .. sb.print(world.regionActive(StoredRegion)));
	if value == nil then
		if GetController(Index) ~= nil then
			local stringIndex = tostring(GetController(Index).Container);
			--DPrint("string index = " .. sb.print(stringIndex));
			--DPrint("Predictions INDEXER = " .. sb.printJson(Predictions,1));
			--DPrint("Predictions At index = " .. sb.print(Predictions[stringIndex]));
			local Position;
			if Predictions[stringIndex] ~= nil then
				for k,i in ipairs(Predictions[stringIndex]) do
					if i.Crammed == true then
						if Position == nil then
							Position = entity.position();
						end
						world.spawnItem(i.Item,Position,i.Item.count,i.Item.parameters);
					else
						if world.entityExists(i.TraversalID) == true and Active == true then
							--DPrint("DROPPING TRAVESAL");
							--DPrint(EntityID .. " DTC");
							--[[if i.Crammed == true then
								if Position == nil then
									Position = entity.position();
								end
								world.spawnItem(i.Item,Position,i.Item.count,i.Item.parameters);
							else
								world.sendEntityMessage(i.TraversalID,"AddItemToDrop",i.Item);
							end--]]
							world.sendEntityMessage(i.TraversalID,"AddItemToDrop",i.Item);
						end
					end
				end
				Predictions[stringIndex] = nil;
			end
			SetController(Index,nil);
		end
	else
		if GetController(Index) ~= nil then
			local stringIndex = tostring(GetController(Index).Container);
			if Predictions[stringIndex] ~= nil then
				for k,i in ipairs(Predictions[stringIndex]) do
					i.Container = value;
					if i.Crammed ~= true and world.entityExists(i.TraversalID) == true then
						world.callScriptedEntity(i.TraversalID,"ChangeContainer",value);
					end
				end
				local NewIndex = tostring(value);
				Predictions[NewIndex] = Predictions[stringIndex];
				Predictions[stringIndex] = nil;
			end
		end
		local InsertionConduits = GetConduitsAtContainer(value);
		for i=1,#InsertionConduits do
			world.callScriptedEntity(InsertionConduits[i],"AddConduit",value,EntityID);
		end
		local Master;
		for i=1,#InsertionConduits do
			if world.callScriptedEntity(InsertionConduits[i],"IsMasterOf",value) == true then
				Master = InsertionConduits[i];
				break;
			end
		end
		if Master == nil then
			Master = EntityID;
		end
		InsertionConduits[#InsertionConduits + 1] = EntityID;
		SetController(Index,{
			Container = value,
			Conduits = InsertionConduits,
			Master = Master
		});
	end
end

local function UpdateRegion()
	local EntityPos = entity.position();
	local XLow,YLow,XHigh,YHigh = EntityPos[1] - 5,EntityPos[2] - 5,EntityPos[1] + 5,EntityPos[2] + 5;
	for i=1,4 do
		if Cables.CableTypes.Containers[i] ~= -10 then
			for m,n in ipairs(world.objectSpaces(Cables.CableTypes.Containers[i])) do
				n = vecAdd(n,world.entityPosition(Cables.CableTypes.Containers[i]));
				if n[1] < XLow then
					XLow = n[1];
				end
				if n[2] < YLow then
					YLow = n[2];
				end
				if n[1] > XHigh then
					XHigh = n[1];
				end
				if n[2] > YHigh then
					YHigh = n[2];
				end
			end
		end
	end
	StoredRegion = {XLow,YLow,XHigh,YHigh};
end

UpdateController = function()
	if Active == true then
		local Updated = false;
		for i=1,4 do
			if Cables.CableTypes.Containers[i] == -10 and GetController(i) ~= nil then
				--DPrint(EntityID .. " NIL Changing from " .. sb.print(GetController(i)) .. " to nil");
				ChangeController(i,nil);
				Updated = true;
			elseif Cables.CableTypes.Containers[i] ~= -10 and (GetController(i) == nil or GetController(i).Container ~= Cables.CableTypes.Containers[i]) then
				--DPrint(EntityID .. " Changing from " .. sb.print(GetController(i)) .. " to " .. sb.print(Cables.CableTypes.Containers[i]));
				--ChangeController(i,nil);
				ChangeController(i,Cables.CableTypes.Containers[i]);
				Updated = true;
			end
		end
		if Updated == true then
			UpdateRegion();
			--DPrint("REGION UPDATED");
		end
	end
end

GetController = function(i)
	return Controllers[tostring(i)];
end
SetController = function(i,value)
	Controllers[tostring(i)] = value;
end

function AddConduit(Container,ID)
	if Active == true then
		local Index = ContainerToControllerIndex(Container);
		if Index == nil then
			UpdateController();
			Index = ContainerToControllerIndex(Container);
			if Index == nil then
				return nil;
			end
		end
		if Index ~= nil then
			local controller = GetController(Index);
			local Found = false;
			for i=1,#controller.Conduits do
				if controller.Conduits[i] == ID then
					Found = true;
					break;
				end
			end
			if Found == false then
				controller.Conduits[#controller.Conduits + 1] = ID;
			end
		end
	end
end

function RemoveConduit(Container,ID,predictions,predictionsForDumping,predictionCount)
	if Active == true then
		local Index = ContainerToControllerIndex(Container);
		if Index == nil then
			UpdateController();
			Index = ContainerToControllerIndex(Container);
			if Index == nil then
				return nil;
			end
		end
		if Index ~= nil then
			local controller = GetController(Index);
			for i=1,#controller.Conduits do
				if controller.Conduits[i] == ID then
					--DPrint("REMOVING CONDUIT: " .. sb.print(i));
					table.remove(controller.Conduits,i);
					break;
				end
			end
			if controller.Master == ID then
				controller.Master = nil;
				for i=1,#controller.Conduits do
					if world.callScriptedEntity(controller.Conduits[i],"IsMasterOf",controller.Container) == true then
						controller.Master = controller.Conduits[i];
						break;
					end
				end
				if controller.Master == nil then
					controller.Master = EntityID;
					if predictions ~= nil then
						Predictions = predictions;
						PredictionsForDumping = predictionsForDumping;
						PredictionCount = predictionCount;
						return true;
					end
				end
			end
		end
	end
end

function RemoveMaster(Container,ID)
	local Index = ContainerToControllerIndex(Container);
	if Index ~= nil then
		local C = GetController(Index);
		if C.Master == ID then
			C.Master = nil;
		end
	end
end

ContainerToControllerIndex = function(ID)
	for k,i in pairs(Controllers) do
		if i ~= nil and i.Container == ID then
			return tonumber(k);
		end
	end
end

local function shuffle(t)
	local n = #t;
	while n > 1 do 
		local k = math.random(n);
		t[n], t[k] = t[k], t[n];
		n = n - 1;
	end
	return t;
end

local function RandomIter(t)
	local indexTable = {};
	for i=1,#t do
		indexTable[i] = i;
	end
	indexTable = shuffle(indexTable);
	local n = 0;
	return function()
		n = n + 1;
		return indexTable[n],t[indexTable[n]];
	end
end

local function NumberToSideType(val)
	if val == 1 then
		return "up";
	elseif val == 2 then
		return "down";
	elseif val == 3 then
		return "left";
	elseif val == 4 then
		return "right";
	end
end

local function SideTypeToNumber(val)
	if val == "up" then
		return 1;
	elseif val == "down" then
		return 2;
	elseif val == "left" then
		return 3;
	elseif val == "right" then
		return 4;
	end
	return 10;
end

local Transferring = false;

ExtractAndSend = function(_,_,Item,Slot,Container,Path,InsertIntoSides,InsertIntoSlots,InsertContainer,Color,Speed,SourceConduit,ConduitLimits,Occluded)
	--DPrint("XA");
	if Ready == false or Transferring == true then return nil end;
	Transferring = true;
	if Active == false then
		Active = true;
		Predictions = {};
		PredictionsForDumping = {};
		Cables.Update();
		UpdateController();
	end
	world.loadRegion(StoredRegion)
	if InsertContainer == nil then
		for _,i in RandomIter(InsertIntoSides) do
			InsertContainer = Cables.CableTypes.Containers[SideTypeToNumber(i)];
			if InsertContainer ~= nil and InsertContainer ~= -10 then
				break;
			else
				InsertContainer = nil;
			end
		end
	end
	if InsertContainer == nil or world.entityExists(InsertContainer) == false then Transferring = false; return nil end;
	local ControllerIndex = ContainerToControllerIndex(InsertContainer);
	if ControllerIndex == nil then Transferring = false; return nil end;
	local CurrentController = GetController(ControllerIndex);
	if CurrentController.Master ~= EntityID then
		--world.callScriptedEntity(CurrentController.Master,"ExtractAndSend",nil,nil,Item,Slot,Container,Path,InsertIntoSides,InsertIntoSlots,InsertContainer,Color,Speed,EntityID,ConduitLimits);
		world.sendEntityMessage(CurrentController.Master,"ExtractAndSend",Item,Slot,Container,Path,InsertIntoSides,InsertIntoSlots,InsertContainer,Color,Speed,EntityID,ConduitLimits,Occluded);
		Transferring = false;
		return nil;
	end
	--DPrint("Master = " .. sb.print(CurrentController.Master));
	local ContainerPredictions = GetPredictionGroup(InsertContainer);
	local ContainerSize = world.containerSize(InsertContainer);
	local Inventory = world.containerItems(InsertContainer);
	if Inventory == nil then return nil end;
	CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
	local NewPrediction = {Item = Item,Container = InsertContainer,InsertSlots = InsertIntoSlots,MaxStack = root.itemConfig(Item).config.maxStack or 1000};
	local NewSlot,Count = FindSlot(NewPrediction,Inventory,ContainerSize,nil,true);
	--DPrint("Found SLot = " .. sb.print(NewSlot));
	if NewSlot ~= nil then
		NewPrediction.Slot = NewSlot;
		NewPrediction.Item.count = Count;
		--DPrint("XS");
		--world.spawnProjectile("electricbolt",vecAdd(world.entityPosition(Path[#Path]),{0.5,0.5}));
		if Occluded == false then
			NewPrediction.TraversalID = world.spawnProjectile("traversal" .. Colors[Color],vecAdd(world.entityPosition(Path[#Path]),{0.5,0.5}),SourceConduit or EntityID);
		else
			NewPrediction.TraversalID = sb.makeUuid();
		end
		--DPrint("XT");
		--DPrint("XT");
		if (Occluded == true or world.entityExists(NewPrediction.TraversalID) == true) and world.containerConsumeAt(Container,Slot - 1,Count) == true then
			--DPrint(EntityID .. " Adding Prediction of = " .. sb.printJson(NewPrediction));
			AddPredictionAndSend(NewPrediction);
			if Occluded == false then
				world.callScriptedEntity(NewPrediction.TraversalID,"StartTraversing",Path,Speed,InsertContainer,nil,nil,CurrentController.Conduits,ConduitLimits,InsertIntoSides);
			else
				NewPrediction.Crammed = true;
				CrammedTraversals[#CrammedTraversals + 1] = {Path = Path,Index = #Path,Speed = Speed,Clock = 0,Traversal = NewPrediction.TraversalID,Container = NewPrediction.Container,SetPosition = world.entityPosition(Path[#Path])};
			end
		end
	end
	--[[if FPS < Threshold then
		DPrint("CrammingE");
		--CramTraversal();
	end--]]
	Transferring = false;
	--DPrint("XB");
end

function ContainerCount()
	if Cables.CableTypes.Containers ~= nil then
		return #Cables.CableTypes.Containers;
	end
	return 0;
end

local function InventoryIter(t)
	local iterator = nil;
	if #t > 0 then
		for k,i in ipairs(t) do
			iterator = ipairs(t);
			return function()
				return iterator();
			end
		end
		iterator = pairs(t);
		return function()
			return iterator();
		end
	end
	return nil;
end

function AnySidesHaveContainers(Sides)
	local Valid = false;
	for _,v in ipairs(Sides) do
		local number = SideTypeToNumber(v);
		--DPrint("V = " .. sb.print(number));
		--DPrint("Cable Value = " .. sb.print(Cables.CableTypes.Containers[number]));
		if Cables.CableTypes.Containers[number] ~= -10 then
			Valid = true;
			break;
		end
	end
	--DPrint("Searching Position = " .. sb.print(entity.position()));
	--DPrint("FOUND SIDE FOR " .. sb.print(Sides) .. " = " .. sb.print(Valid));
	return Valid;
end

local function GetIndexType(t)
	if #t > 0 then
		for k,i in ipairs(t) do
			return "number";
		end
		return "string";
	end
	return "number";
end

CombinePredictions = function(inventory,predictions,ContainerSize)
	if inventory == nil then return nil end;
	local converter;
	if GetIndexType(inventory) == "string" then
		converter = function(v) return tostring(v) end;
	else
		converter = function(v) return v end;
	end
	local Size = #predictions;
	for i=1,Size do
		local Slot = converter(predictions[i].Slot);
		if inventory[Slot] == nil or (root.itemDescriptorsMatch(inventory[Slot],predictions[i].Item,true) and inventory[Slot].count + predictions[i].Item.count <= predictions[i].MaxStack) then
			if inventory[Slot] == nil then
				inventory[Slot] = {name = predictions[i].Item.name, count = predictions[i].Item.count, parameters = predictions[i].Item.parameters};
			else
				inventory[Slot].count = inventory[Slot].count + predictions[i].Item.count;
			end
		else
			BuildPrediction(predictions[i],predictions,inventory,converter,ContainerSize);
		end
	end
	for i=#predictions,1,-1 do
		if predictions[i].Dumping == true then
			table.remove(predictions,i);
		end
	end
end

FindSlot = function(prediction,inventory,ContainerSize,converter,ReduceCount)
	ReduceCount = ReduceCount or false;
	if converter == nil then
		if GetIndexType(inventory) == "number" then
			converter = function(v) return v end;
		else
			converter = function(v) return tostring(v) end;
		end
	end
	if prediction.InsertSlots[1] == "any" then
		for i=1,ContainerSize do
			local Slot = converter(i);
			if inventory[Slot] == nil or root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
				if ReduceCount == true then
					if inventory[Slot] == nil then
						return i,prediction.Item.count;
					end
					if inventory[Slot].count ~= prediction.MaxStack then
						local NewCount = prediction.Item.count;
						if inventory[Slot].count + prediction.Item.count > prediction.MaxStack then
							NewCount = NewCount - (NewCount + inventory[Slot].count - prediction.MaxStack);
						end
						return i,NewCount;
					end
				else
					if inventory[Slot] == nil or inventory[Slot].count + prediction.Item.count <= prediction.MaxStack then
						return i;
					end
				end
			end
		end
	else
		for k,i in ipairs(prediction.InsertSlots) do
			local Slot = converter(i);
			if inventory[Slot] == nil or root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
				if ReduceCount == true then
					if inventory[Slot] == nil then
						return i,prediction.Item.count;
					end
					if inventory[Slot].count ~= prediction.MaxStack then
						local NewCount = prediction.Item.count;
						if inventory[Slot].count + prediction.Item.count > prediction.MaxStack then
							NewCount = NewCount - (NewCount + inventory[Slot].count - prediction.MaxStack);
						end
						return i,NewCount;
					end
				else
					if inventory[Slot] == nil or inventory[Slot].count + prediction.Item.count <= prediction.MaxStack then
						return i;
					end
				end
			end
		end
	end
end

DropItems = function(_,_,TraversalID,ContainerID,Position)
	--DPrint("XA");
	--DPrint("DROPPING");
	--DPrint("TraversalID = " .. sb.print(TraversalID));
	--DPrint("ContainerID = " .. sb.print(ContainerID));
	--DPrint("Position = " .. sb.print(Position));
	if Position == nil then Position = entity.position() end;
	local Index = ContainerToControllerIndex(ContainerID);
	if Index == nil then return nil end;
	local CurrentController = GetController(Index);
	if CurrentController.Master ~= EntityID then
		world.sendEntityMessage(CurrentController.Master,"DropItems",TraversalID,ContainerID,Position);
		return nil;
	end
	--DPrint("XB");
	--DPrint();
	local ContainerPredictions = GetPredictionGroup(ContainerID);
	local ContainerSize = world.containerSize(ContainerID);
	local Inventory = world.containerItems(ContainerID);
	CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
	for i=#ContainerPredictions,1,-1 do
		--DPrint("XC");
		if ContainerPredictions[i].TraversalID == TraversalID then
			--DPrint("XD");
			--DPrint("DROPPINGA");
			world.spawnItem(ContainerPredictions[i].Item,Position,ContainerPredictions[i].Item.count,ContainerPredictions[i].Item.parameters);
			if ContainerPredictions[i].Crammed ~= true then
				PredictionCount = PredictionCount - 1;
			end
			table.remove(ContainerPredictions,i);
		end
	end
	--DPrint("XE");
	local dump = GetDump(ContainerID);
	for i=#dump,1,-1 do
		if dump[i].TraversalID == TraversalID then
			--DPrint("DROPPINGB");
			world.spawnItem(dump[i].Item,Position,dump[i].Item.count,dump[i].Item.parameters);
			if ContainerPredictions[i].Crammed ~= true then
				PredictionCount = PredictionCount - 1;
			end
			table.remove(dump,i);
		end
	end
end

BuildPrediction = function(prediction,Predictions,inventory,converter,ContainerSize)
	local Slot = converter(prediction.Slot);
	if root.itemDescriptorsMatch(inventory[Slot],prediction.Item,true) then
		local OriginalCount = prediction.Item.count;
		if inventory[Slot].count == prediction.MaxStack then
			--FIND NEW SLOT FOR PREDICTION
			local NewSlot = FindSlot(prediction,inventory,ContainerSize,converter);
			if NewSlot ~= nil then
				prediction.Slot = NewSlot;
				inventory[converter(NewSlot)] = prediction.Item;
			else
				prediction.Dumping = true;
				AddToDump(prediction.Container,prediction);
			end
		else
			prediction.Item.count = prediction.Item.count - (prediction.Item.count + inventory[Slot].count - prediction.MaxStack);
			inventory[Slot].count = prediction.MaxStack;
			local Leftover = OriginalCount - prediction.Item.count;
			local NewPrediction = {Item = {name = prediction.Item.name, count = Leftover,parameters = prediction.Item.parameters},Slot = prediction.Slot,MaxStack = prediction.MaxStack,Container = prediction.Container,InsertSlots = prediction.InsertSlots,TraversalID = prediction.TraversalID};
			--GENERATE NEW PREDICTION WITH THE LEFTOVER AMOUNT AND FIND A SLOT FOR IT
			local NewSlot = FindSlot(NewPrediction,inventory,ContainerSize,converter);
			if NewSlot ~= nil then
				NewPrediction.Slot = NewSlot;
				Predictions[#Predictions + 1] = NewPrediction;
				inventory[converter(NewSlot)] = NewPrediction.Item;
			else
				NewPrediction.Dumping = true;
				AddToDump(NewPrediction.Container,NewPrediction);
			end
		end

	else
		--FIND NEW SLOT FOR PREDICTION
		local NewSlot = FindSlot(prediction,inventory,ContainerSize,converter);
		if NewSlot ~= nil then
			prediction.Slot = NewSlot;
			inventory[converter(NewSlot)] = prediction.Item;
		else
			prediction.Dumping = true;
			AddToDump(prediction.Container,prediction);
		end
	end
end

RemapContainers = function()
	local PreviousContainers = config.getParameter("PreviousContainers");
	--DPrint(EntityID .. " Previous Containers = " .. sb.print(PreviousContainers));
	--DPrint(EntityID .. "Current Containers = " .. sb.print(Cables.CableTypes.Containers));
	if PreviousContainers == nil then return nil end;
	for i=1,4 do
		if Cables.CableTypes.Containers[i] ~= -10 and PreviousContainers[i] ~= -10 and Cables.CableTypes.Containers[i] ~= PreviousContainers[i] then
			--DPrint(EntityID .. " Predictions = " .. sb.printJson(Predictions,1));
			for m,n in pairs(Predictions) do
				local Container = tonumber(m);
				--DPrint(EntityID .. " I = " .. sb.print(i));
				--DPrint(EntityID .. " M = " .. sb.print(m));
				if Container == PreviousContainers[i] then
					--DPrint(EntityID .. " Remapping " .. PreviousContainers[i] .. "To " .. sb.print(Cables.CableTypes.Containers[i]));
					Predictions[tostring(Cables.CableTypes.Containers[i])] = Predictions[m];
					Predictions[m] = nil;
					for o,p in ipairs(Predictions[tostring(Cables.CableTypes.Containers[i])]) do
						p.Container = Cables.CableTypes.Containers[i];
					end
					break;
				end
			end
			--[[local OldContainer = tostring(Cables.CableTypes.Containers[i]);
			if Controller[OldContainer] ~= nil then
				Controller[tostring(PreviousContainers[i])] = Controller[OldContainer];
				Controller[OldContainer] = nil;
			end--]]
		end
	end
end

AddAllPredictions = function()
	local Position = entity.position();
	for k,i in pairs(Predictions) do
		local Container = tonumber(k);
		local Exists = world.entityExists(Container);
		for o,p in ipairs(i) do
			if Exists == true then
				local Item = world.containerPutItemsAt(Container,p.Item,p.Slot - 1);
				if Item ~= nil and Item.count > 0 then
					--DPrint("DROPPINGE");
					--DPrint("DROPPINGC");
					world.spawnItem(p.Item,Position,p.Item.count,p.Item.parameters);
				end
			else
				--DPrint("DROPPINGD");
				--DPrint("DROPPINGD");
				world.spawnItem(p.Item,Position,p.Item.count,p.Item.parameters);
			end
		end
	end
	Predictions = {};
	object.setConfigParameter("Predictions",Predictions);
	for k,i in pairs(PredictionsForDumping) do
		for o,p in ipairs(i) do
			--DPrint("DROPPINGC");
			--DPrint("DROPPINGE");
			world.spawnItem(p.Item,Position,p.Item.count,p.Item.parameters);
		end
	end
	PredictionsForDumping = {};
	PredictionCount = 0;
	object.setConfigParameter("Dump",PredictionsForDumping);
end

AddToInventory = function(_,_,Traversal,Container)
	--DPrint("ADDING");
	--DPrint("Container = " .. sb.print(Container));
	--DPrint("Traversal = " .. sb.print(Traversal));
	local Index = ContainerToControllerIndex(Container);
	--DPrint("CIndex = " .. sb.print(Index));
	if Index == nil then return nil end;
	local CurrentController = GetController(Index);
	if CurrentController.Master ~= EntityID then
		world.sendEntityMessage(CurrentController.Master,"AddToInventory",Traversal,Container);
		return nil;
	end
	--DPrint("AZ");
	--local PredictionGroup = Predictions[tostring(Container)];
	local ContainerPredictions = GetPredictionGroup(Container);
	local ContainerSize = world.containerSize(Container);
	local Inventory = world.containerItems(Container);
	local Exists = world.entityExists(Container);
	--DPrint("Exists = " .. sb.print(Exists));
	local Position = entity.position();
	CombinePredictions(Inventory,ContainerPredictions,ContainerSize);
	if ContainerPredictions ~= nil then
		--DPrint("BZ");
		--DPrint("Container Predictions = " .. sb.print(ContainerPredictions));
		for i=#ContainerPredictions,1,-1 do
			--DPrint("TraversalID = " .. sb.print(ContainerPredictions[i].TraversalID));
			--DPrint("Traversal = " .. sb.print(Traversal));
			if ContainerPredictions[i].TraversalID == Traversal then
				--DPrint("CZ");
				if Exists == true then
					--DPrint("DZ");
					local Item = world.containerPutItemsAt(Container,ContainerPredictions[i].Item,ContainerPredictions[i].Slot - 1);
					if Item ~= nil and Item.count > 0 then
						--DPrint("DROPPINGB");
						--DPrint("DROPPINGF");
						world.spawnItem(ContainerPredictions[i].Item,Position,ContainerPredictions[i].Item.count,ContainerPredictions[i].Item.parameters);
					end
				else
					--DPrint("DROPPINGA");
					--DPrint("DROPPINGG");
					world.spawnItem(ContainerPredictions[i].Item,Position,ContainerPredictions[i].Item.count,ContainerPredictions[i].Item.parameters);
				end
				if ContainerPredictions[i].Crammed ~= true then
					PredictionCount = PredictionCount - 1;
				end
				table.remove(ContainerPredictions,i);
			end
		end
	end
end
--TODO ---------------------------------------------------------------------------------------

function ReRouteFromID(FromID)
	if Active == true then
		--[[DPrint("FromID = " .. sb.print(FromID));
		DPrint("Controller = " .. sb.print(Controllers));
		DPrint("C ENTITYID = " .. sb.print(EntityID));
		if Predictions ~= nil then
			DPrint("Predictions = " .. sb.printJson(Predictions,1));
		else
			DPrint("Predictions = " .. sb.print(Predictions));
		end--]]
		for _,c in pairs(Controllers) do
			local Container = tostring(c.Container);
			--DPrint(1);
			if Predictions[Container] ~= nil then
				--DPrint(2);
				for m=#Predictions[Container],1,-1 do
					local n = Predictions[Container][m];
					--DPrint("SourceConduit = " .. sb.print(n.SourceConduit));
					if n.Crammed ~= true and world.entityExists(n.TraversalID) == true then
						local SourceID = world.callScriptedEntity(n.TraversalID,"GetSourceID");
						if SourceID == FromID then
							--DPrint(3);
							local Traversal = n.TraversalID;
							if world.entityExists(Traversal) == true then
								--DPrint("Conduits = " .. sb.print(c.Conduits));
								--DPrint("C = " .. sb.print(c));
								local ToID = world.callScriptedEntity(Traversal,"ReRoute",c.Conduits,FromID);
								if ToID == nil then
									--DPrint("DTB");
									world.sendEntityMessage(Traversal,"AddItemToDrop",n.Item);
									PredictionCount = PredictionCount - 1;
									table.remove(Predictions[Container],m);
								end
							end
						end
					end
				end
			end
		end
	end
end





local Dying = false;

local oldDie = die;
function die()
	Dying = true;
	--DPrint("Dying = " .. sb.print(Dying));
	if oldDie ~= nil then
		oldDie();
	end
	Cables.Uninitialize();
	--Cables.UpdateOthers();
end

local oldUninit = uninit;
function uninit()
	--DPrint("UNINIT OF INSERTION CONDUIT");
	if Dying == false then
		object.setConfigParameter("Predictions",Predictions);
		object.setConfigParameter("Dump",PredictionsForDumping);
		object.setConfigParameter("StoredRegion",StoredRegion);
		object.setConfigParameter("PreviousContainers",Cables.CableTypes.Containers);
	end
	--DPrint("ALL Predictions = " .. sb.printJson(Predictions,1));
	if oldUninit ~= nil then
		oldUninit();
	end
	if Active == true then
		Active = false;
		--DPrint("Controllers = " .. sb.print(Controllers));
		for _,c in pairs(Controllers) do
			--DPrint("F");
			local PredictionsSet = false;
			local PredictionID = nil;
			for i=1,#c.Conduits do
				if c.Conduits[i] ~= EntityID and world.entityExists(c.Conduits[i]) == true then
					if Dying == true then
						if PredictionsSet == true then
							world.callScriptedEntity(c.Conduits[i],"RemoveConduit",c.Container,EntityID);
						else
							if c.Master == EntityID then
								PredictionsSet = world.callScriptedEntity(c.Conduits[i],"RemoveConduit",c.Container,EntityID,Predictions,PredictionsForDumping,PredictionCount) == true;
								if PredictionsSet == true then PredictionID = c.Conduits[i] end;
							else
								world.callScriptedEntity(c.Conduits[i],"RemoveConduit",c.Container,EntityID);
							end
						end
					else
						world.callScriptedEntity(c.Conduits[i],"RemoveConduit",c.Container,EntityID);
					end
				end
			end
			--DPrint("E");
			if Dying == true then
				for k,i in ipairs(CrammedTraversals) do
					--DropItems(i.Traversal,i.Container,EntityPosition);
					AddToInventory(_,_,i.Traversal,i.Container);
				end
				if c.Master == EntityID then
					if PredictionsSet == true then
						--DPrint("SENDING TO Predicted ID");
						world.callScriptedEntity(PredictionID,"ReRouteFromID",EntityID);
					else
						local Container = tostring(c.Container);
						if Predictions[Container] ~= nil then
							for m,n in ipairs(Predictions[Container]) do
								if n.Crammed ~= true and world.entityExists(n.TraversalID) == true then
									--DPrint("DTA");
									world.sendEntityMessage(n.TraversalID,"AddItemToDrop",n.Item);
								end
							end
						end
					end
				else
					if world.entityExists(c.Master) == true then
						--DPrint("SENDING TO MASTER");
						world.callScriptedEntity(c.Master,"ReRouteFromID",EntityID);
					end
				end
			else
				--DPrint("FORCE DESTROYING");
				local Container = tostring(c.Container);
				if Predictions[Container] ~= nil then
					for o,p in ipairs(Predictions[Container]) do
						if p.Crammed ~= true and world.entityExists(p.TraversalID) == true then
							world.callScriptedEntity(p.TraversalID,"ForceDestroy");
						end
					end
				end
			end
		end
	end
end