if SafeCommunicate ~= nil then return nil end;
require("/Core/Conduit Scripts/Terminal/TerminalUI.lua");
require("/Core/UICore.lua");

--Declaration
SafeCommunicate = {};
local SafeCommunicate = SafeCommunicate;

--Variables
local __SourceID__;
local SourceID = setmetatable({},{
	__call = function()
		if __SourceID__ == nil then
			__SourceID__ = config.getParameter("TerminalID") or pane.sourceEntity();
		end
		return __SourceID__;
	end
});
local Caches = {};

--Functions
local ExecuteScript;
local ExecuteScriptAsync;
local ExecuteOnSource;
local AsyncFinishPromise;
local IsCached;
local SetCache;
local GetCache;
local IntervenePromise;
local MakePromiseTable;
local sendEntityMessage;
local Initialized = false;

--Adds a safe calling function
local AddSafeFunction = function(name,callingName)
	SafeCommunicate[name] = function(...)
		SafeCommunicate.Initialize();
		return ExecuteOnSource(callingName,...);
	end
	SafeCommunicate[name .. "Async"] = function(...)
		SafeCommunicate.Initialize();
		--sb.logInfo("In Async");
		local Result = AsyncFinishPromise(SafeCommunicate[name](...));
		--sb.logInfo("Final Result for " .. sb.print(name .. "Async") .. " = " .. sb.print(Result));
		return Result;
		--
		--return AsyncFinishPromise(SafeCommunicate[name](...));
	end
end

--Adds a safe calling function that is cached, using the first parameter as a cache indexer
local AddSafeCachedFunction = function(name,callingName)
	SafeCommunicate[name] = function(...)
		SafeCommunicate.Initialize();
		local FirstParam = select(1,...);
		if IsCached(name,FirstParam) then
			return MakePromiseTable(GetCache(name,FirstParam));
		end
		local Promise = ExecuteOnSource(callingName,...);
		return IntervenePromise(Promise,function(result)
			SetCache(name,FirstParam,result);
		end);
	end
	SafeCommunicate[name .. "Async"] = function(...)
		SafeCommunicate.Initialize();
		return AsyncFinishPromise(SafeCommunicate[name](...));
	end
end

--Initializes the Safe Communication Api
function SafeCommunicate.Initialize()
	if Initialized == true then return nil end;
	Initialized = true;
	sendEntityMessage = world.sendEntityMessage;
	if SafeCommunicate.Override ~= nil then
		SafeCommunicate.Override();
	end
end

AddSafeFunction("GetContainerItems","world.containerItems");
AddSafeCachedFunction("GetObjectPosition","world.entityPosition");
AddSafeCachedFunction("GetObjectName","world.entityName");
AddSafeCachedFunction("GetObjectSpaces","world.objectSpaces");
AddSafeFunction("GetObjectParameter","world.getObjectParameter");
AddSafeCachedFunction("GetContainerSize","world.containerSize");
AddSafeFunction("GetContainerItemAt","world.containerItemAt");
AddSafeFunction("ContainerConsume","world.containerConsume");
AddSafeFunction("ContainerConsumeAt","world.containerConsumeAt");
AddSafeFunction("ContainerAvailable","world.containerAvailable");
AddSafeFunction("ContainerTakeAll","world.containerTakeAll");
AddSafeFunction("ContainerTakeAt","world.containerTakeAt");
AddSafeFunction("ContainerTakeNumItemsAt","world.containerTakeNumItemsAt");
AddSafeFunction("ContainerItemsCanFit","world.containerItemsCanFit");
AddSafeFunction("ContainerItemsFitWhere","world.containerItemsFitWhere");
AddSafeFunction("ContainerAddItems","world.containerAddItems");
AddSafeFunction("ContainerStackItems","world.containerStackItems");
AddSafeFunction("ContainerPutItemsAt","world.containerPutItemsAt");
AddSafeFunction("ContainerItemsApply","world.containerItemsApply");
AddSafeFunction("ContainerSwapItemsNoCombine","world.containerSwapItemsNoCombine");
AddSafeFunction("ContainerSwapItems","world.containerSwapItems");
AddSafeFunction("ObjectExists","world.entityExists");

function SafeCommunicate.SendEntityMessage(id,funcName,...)
	SafeCommunicate.Initialize();
	local Promise = sendEntityMessage(SourceID(),"SafeCommunicate.SendEntityMessage",id,funcName,...);
	local Result;
	local Error;
	local Finished = false;
	local Succeeded = false;
	local PromiseTable = {};
	PromiseTable.result = function()
		return Result;
	end
	PromiseTable.finished = function()
		return Finished;
	end
	PromiseTable.succeeded = function()
		return Succeeded;
	end
	PromiseTable.error = function()
		return Error;
	end
	local CoroutineID;
	CoroutineID = UICore.AddAsyncCoroutine(function()
		while(not Promise:finished()) do
			coroutine.yield();
		end
		local MessageID;
		if Promise:succeeded() then
			MessageID = Promise:result();
		else
			Succeeded = false;
			Error = Promise:error();
			UICore.CancelCoroutine(CoroutineID);
			return nil;
		end
		while(not Finished) do
			local IsDonePromise = sendEntityMessage(SourceID(),"SafeCommunicate.IsMessageDone",MessageID);
			while(not IsDonePromise:finished()) do
				coroutine.yield();
			end
			local IsDone;
			if IsDonePromise:succeeded() then
				IsDone = IsDonePromise:result();
			else
				Succeeded = false;
				Error = Promise:error();
				UICore.CancelCoroutine(CoroutineID);
				return nil;
			end
			if type(IsDone) == "table" then
				Succeeded = IsDone.Succeeded;
				Error = IsDone.Error;
				Result = IsDone.Result;
				UICore.CancelCoroutine(CoroutineID);
				return nil;
			end
		end
	end);
	--sb.logInfo("Returning = " .. sb.print(PromiseTable));
	return PromiseTable;
end

function SafeCommunicate.SendEntityMessageAsync(id,funcName,...)
	SafeCommunicate.Initialize();
	return SafeCommunicate.SendEntityMessage(id,funcName,...);
end

function SafeCommunicate.GetSourceID()
	SafeCommunicate.Initialize();
	return SourceID();
end

--Gets the Contents of the Container
--Returns a promise that will eventually return the actual result
--[[function SafeCommunicate.GetContainerItems(containerID)
	return ExecuteOnSource("SafeCommunicate.GetContainerItems",containerID);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetContainerItemsAsync(containerID)
	return AsyncFinishPromise(SafeCommunicate.GetContainerItems(containerID));
end

--Gets the Contents of the Container
--Returns a promise that will eventually return the actual result
function SafeCommunicate.GetObjectSpaces(containerID)
	return ExecuteOnSource("SafeCommunicate.GetObjectSpaces",containerID);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetObjectSpacesAsync(containerID)
	return AsyncFinishPromise(SafeCommunicate.GetObjectSpaces(containerID));
end

--Gets the Contents of the Container
--Returns a promise that will eventually return the actual result
function SafeCommunicate.GetContainerItemAt(containerID,offset)
	return ExecuteOnSource("SafeCommunicate.GetContainerItemAt",containerID,offset);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetContainerItemAtAsync(containerID,offset)
	return AsyncFinishPromise(SafeCommunicate.GetContainerItemAt(containerID,offset));
end

--Gets the Contents of the Container
--Returns a promise that will eventually return the actual result
function SafeCommunicate.GetContainerSize(containerID)
	if IsCached("ObjectSize",containerID) then
		return MakePromiseTable(GetCache("ObjectSize",containerID));
	end
	local Promise = ExecuteOnSource("SafeCommunicate.GetContainerSize",containerID);
	return IntervenePromise(Promise,function(result)
		SetCache("ObjectSize",containerID,result);
	end);
	--return ExecuteOnSource("SafeCommunicate.GetContainerSize",containerID);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetContainerSizeAsync(containerID)
	return AsyncFinishPromise(SafeCommunicate.GetContainerSize(containerID));
end

function SafeCommunicate.GetObjectParameter(containerID,value,default)
	return ExecuteOnSource("SafeCommunicate.GetObjectParameter",containerID,value,default);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetObjectParameterAsync(containerID,value,default)
	return AsyncFinishPromise(SafeCommunicate.GetObjectParameter(containerID,value,default));
end

function SafeCommunicate.GetObjectPosition(containerID)
	if IsCached("ObjectPosition",containerID) then
		return MakePromiseTable(GetCache("ObjectPosition",containerID));
	end
	local Promise = ExecuteOnSource("SafeCommunicate.GetObjectPosition",containerID);
	return IntervenePromise(Promise,function(result)
		SetCache("ObjectPosition",containerID,result);
	end);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetObjectPositionAsync(containerID)
	return AsyncFinishPromise(SafeCommunicate.GetObjectPosition(containerID));
end

function SafeCommunicate.GetObjectName(containerID)
	if IsCached("ObjectNames",containerID) then
		return MakePromiseTable(GetCache("ObjectNames",containerID));
	end
	local Promise = ExecuteOnSource("SafeCommunicate.GetObjectName",containerID);
	return IntervenePromise(Promise,function(result)
		SetCache("ObjectNames",containerID,result);
	end);
end

--Gets the Contents of the Container
--Returns the actual container's contents
--This function assumes it's in a coroutine
function SafeCommunicate.GetObjectNameAsync(containerID)
	return AsyncFinishPromise(SafeCommunicate.GetObjectName(containerID));
end--]]

ExecuteScript = function(object,functionName,...)
    return sendEntityMessage(SourceID(),"ExecuteScript",object,functionName,...);
end

ExecuteScriptAsync = function(object,functionName,...)
    local Promise = ExecuteScript(object,functionName,...);
    while not Promise:finished() do
        coroutine.yield();
	end
	if not Promise:succeeded() then
		return nil;
	end
    return Promise:result();
end

ExecuteOnSource = function(functionName,...)
	--sb.logInfo("SourceID = " .. sb.print(SourceID()));
	--sb.logInfo("Executing = " .. sb.print(functionName) .. " on source");
	--sb.logInfo("SourceID = " .. sb.print(SourceID()));
	return sendEntityMessage(SourceID(),"SafeCommunicate.ExecuteOnSource",functionName,...);
end

AsyncFinishPromise = function(runningPromise)
	--sb.logInfo("runningPromise = " .. sb.print(runningPromise));
	while not runningPromise:finished() do
		coroutine.yield();
	end
	if not runningPromise:succeeded() then
		return nil;
	end
	--sb.logInfo("Result = " .. sb.print(runningPromise:result()));
	return runningPromise:result();
end

function SafeCommunicate.Await(promise)
	--sb.logInfo("promise = " .. sb.print(promise));
	return AsyncFinishPromise(promise);
end

function SafeCommunicate.AwaitAll(...)
	local Promises = {...};
	local Returns = {};
	for index,promise in ipairs(Promises) do
		Returns[index] = SafeCommunicate.Await(promise);
	end
	return table.unpack(Returns);
end

--Checks if the value is cached under the type
IsCached = function(type,name)
	if Caches[type] ~= nil and Caches[type][name] ~= nil then
		return true;
	end
	return false;
end

--Sets the value in the cache type
SetCache = function(type,name,value)
	if Caches[type] == nil then
		Caches[type] = {};
	end
	Caches[type][name] = value;
end

--Retrives the cached value in the type and name
GetCache = function(type,name)
	if Caches[type] ~= nil then
		return Caches[type][name];
	end
	return nil;
end

IntervenePromise = function(Promise,onResult)
	local NewPromise = {};
	NewPromise.result = function()
		local Result = Promise:result();
		onResult(Result);
		return Result;
	end
	NewPromise.succeeded = function()
		return Promise:succeeded();
	end
	NewPromise.error = function()
		return Promise:error();
	end
	NewPromise.finished = function()
		return Promise:finished();
	end
	return NewPromise;
end
--Create A Psydo-Promise with a value in it or a function that is called
MakePromiseTable = function(valueOrFunc)
	local NewPromise = {};
	if type(valueOrFunc) == "function" then
		NewPromise.result = function()
			return valueOrFunc();
		end
	else
		NewPromise.result = function()
			return valueOrFunc;
		end
	end
	NewPromise.succeeded = function()
		return true;
	end
	NewPromise.error = function()
		return nil;
	end
	NewPromise.finished = function()
		return true;
	end
	return NewPromise;
end




