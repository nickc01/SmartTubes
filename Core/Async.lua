
--Declaration

Async = {};
local Async = Async;

--Variables
local Initialized = false;
local Coroutines = {};
local ThreadToID = {};

--Functions
local Update;

--Initializes the Async Library
function Async.Initialize()
	if Initialized == true then return true end;
	Initialized = true;
	local OldUpdate = update;
	__RemoteCoroutines = {};
	__EntityID = entity.id();
	local OldYield = coroutine.yield;
	coroutine.yield = function()
		--sb.logInfo("NEW YIELD");
		local CurrentCoroutine = coroutine.running();
		local Remoted = false;
		for _,routine in pairs(__RemoteCoroutines) do
			if routine.Routine == CurrentCoroutine then
				Remoted = true;
				break;
			end
		end
		if Remoted == true then
			--sb.logInfo("Test1");
			OldYield();
			--sb.logInfo("Inside");
			if world.entityExists(__EntityID) == false then
				error("Entity: (" .. sb.print(__EntityID) .. ") has unloaded while running a coroutine on it");
			end
		else
		--	sb.logInfo("Outside");
			--sb.logInfo("Test2");
			OldYield();
		end
	end
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
	return true;
end

function Async.Yield()
	coroutine.yield();
end

Update = function(dt)
	for id,Data in pairs(Coroutines) do
		if coroutine.status(Data.Coroutine) == "dead" then
			Coroutines[id] = nil;
			return nil;
		end
		ExecutingCoroutine = id;
		local Value,Error = coroutine.resume(Data.Coroutine,dt);
		ExecutingCoroutine = nil;
		if Value == false then
			error(Error or "");
		elseif Value ~= nil then
			local Type = type(Value);
			if Type == "string" then
				sb.logInfo(Value);
			elseif Type == "function" then
				Value();
			end
		end
	end
end

--Creates an Async Coroutine
function Async.Create(Coroutine,onCancel)
	Async.Initialize();
	local ID = sb.makeUuid();
	local Coroutine = coroutine.create(function()
		ThreadToID[coroutine.running()] = ID;
		Coroutine();
		ThreadToID[coroutine.running()] = nil;
	end);
	local Table = {
		Coroutine = Coroutine,
		OnCancel = function()
			if onCancel ~= nil then
				onCancel();
				for _,injection in pairs(Coroutines[ID].Injections) do
					injection();
				end
			end
		end,
		Injections = {}
	}
	Coroutines[ID] = Table;
	return ID;
end

--Returns the Currently Running Async Function
function Async.Running()
	local RunningCoroutine = coroutine.running();
	for _,routine in pairs(__RemoteCoroutines) do
		if routine.Routine == RunningCoroutine then
			return routine.Table.Running();
		end
	end
	return ExecutingCoroutine;
end

--Injects a function into the coroutine that is called when the coroutine is canceled
function Async.AddInjection(OnCancel)
	--sb.logInfo("Adding Injection");
	Async.Initialize();
	--sb.logInfo("Remote Coroutines = " .. sb.print(__RemoteCoroutines));
	local RunningCoroutine = coroutine.running();
	for _,routine in pairs(__RemoteCoroutines) do
		if routine.Routine == RunningCoroutine then
			return routine.Table.AddInjection(OnCancel);
		end
	end
	local Running = ExecutingCoroutine;
	local Coroutine = Coroutines[Running];
	if Coroutine ~= nil then
		local ID = sb.makeUuid();
		Coroutine.Injections[ID] = OnCancel;
		return ID;
	end
end

function Async.RemoveInjection(ID)
	Async.Initialize();
	local RunningCoroutine = coroutine.running();
	for _,routine in pairs(__RemoteCoroutines) do
		if routine.Routine == RunningCoroutine then
			return routine.Table.RemoveInjection(ID);
		end
	end
	local Running = ExecutingCoroutine;
	local Coroutine = Coroutines[Running];
	if Coroutine ~= nil and ID ~= nil then
		Coroutine.Injections[ID] = nil;
	end
end

--Cancels a coroutine
function Async.Cancel(ID)
	Async.Initialize();
	local RunningCoroutine = coroutine.running();
	for _,routine in pairs(__RemoteCoroutines) do
		if routine.Routine == RunningCoroutine then
			return routine.Table.Cancel(ID);
		end
	end
	--[[if __RemoteCoroutines[RunningCoroutine] ~= nil then
		return __RemoteCoroutines[RunningCoroutine].Cancel(ID);
	end--]]
	ID = ID or ExecutingCoroutine;
	local Data = Coroutines[ID];
	if Data ~= nil then
		if Data.OnCancel ~= nil then
			Data.OnCancel();
		end
		Coroutines[ID] = nil;
	end
end

--Calls an asyncronous function at another object
function Async.Remote(ID,functionName,...)
	Async.Initialize();
	if not world.entityExists(ID) then
		error("Object of ID: (" .. sb.print(ID) .. ") doesn't exist");
	end
	local RemoteInitialized = world.callScriptedEntity(ID,"Async.Initialize");
	if RemoteInitialized == true then

	else
		error("This Remote Object with the ID: (" .. sb.print(ID) .. ") and Name: (" .. sb.print(world.entityName(ID)) .. ") doesn't use the Async Library");
	end
	local ExecRoutine = ExecutingCoroutine;
	local RunningCoroutine = coroutine.running();
	if __RemoteCoroutines[RunningCoroutine] ~= nil then
		ExecRoutine = __RemoteCoroutines[RunningCoroutine].Running();
	end
	local Function = world.callScriptedEntity(ID,"Async.RemoteReceive",ExecRoutine,functionName,Async);
	if Function ~= nil then
		return Function(...);
	end
end

--This method is called from another object attempting to do an async Remote Call
function Async.RemoteReceive(CoroutineID,functionName,AsyncTable)
	local Name = functionName .. ".";
	local TopTable = _ENV;
	local Steps = 0;
	for path in string.gmatch(Name,"(.-)%.") do
		if type(TopTable) ~= "table" then
			return nil;
		end
		Steps = Steps + 1;
		--sb.logInfo("path = " .. sb.print(path));
		--sb.logInfo("Path = " .. sb.print(path));
		TopTable = TopTable[path];
		--sb.logInfo("Table Now = " .. sb.print(TopTable));
	end
	if Steps == 0 then
		TopTable = TopTable[functionName];
	end
	--sb.logInfo("TopTable Final = " .. sb.print(TopTable));
	if type(TopTable) == "function" then
		return function(...)
			local Params = {...};
			local C = coroutine.running();
			--sb.logInfo("Current = " .. sb.print(C));
			local ID = sb.makeUuid();
			__RemoteCoroutines[ID] = {
				Routine = C,
				Table = AsyncTable
			}
			--sb.logInfo("Remote1 = " .. sb.print(__RemoteCoroutines));
			local Value;
			local Status,Error = pcall(function()
				Value = {TopTable(table.unpack(Params))};
			end);
			--local Value = {TopTable(...)};
			__RemoteCoroutines[ID] = nil;
			if Status == false then
				error(Error);
			end
			--[[if type(Value) ~= "table" then
				return Value;
			end--]]
			return table.unpack(Value);
		end
	else
		return nil;
	end
end