if Server ~= nil then return nil end;

--Declaration

--Public Table
Server = {};
local Server = Server;

--Variables
local SyncedValues = {};
local PromiseLoopCalls = {};
local ResetPromiseLoopCalls = {};
local CoroutineCalls = {};
local ThreadToID = {};
local DefinitionTable = Server;
local Initialized = false;
local Dying = false;


--Functions
local Uninit;

--Initializes the ServerCore
function Server.Initialize()
	if Initialized == true then return nil end;
	Initialized = true;
	local OldUninit = uninit;
	uninit = function()
		if OldUninit ~= nil then
			OldUninit();
		end
		Uninit();
	end
	local OldDie = die;
	die = function()
		if OldDie ~= nil then
			OldDie();
		end
		Dying = true;
	end
	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		for _,func in pairs(PromiseLoopCalls) do
			func();
		end
		for id,Data in pairs(CoroutineCalls) do
			if coroutine.status(Data.Coroutine) == "dead" then
				CoroutineCalls[id] = nil;
				return nil;
			end
			local Value,Error = coroutine.resume(Data.Coroutine,dt);
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
end

function Server.AddAsyncCoroutine(Coroutine,onCancel)
	if Initialized == false then
		Server.Initialize();
	end
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
				for _,injection in pairs(CoroutineCalls[ID].Injections) do
					injection();
				end
			end
		end,
		Injections = {}
	}
	CoroutineCalls[ID] = Table;
	local Value,Error = coroutine.resume(Coroutine,0);
	if Value == false then
		if pcall(function()
			sb.logError(Error or "");
		end) then

		else
			error(Error);
		end
	elseif Value ~= nil then
		local Type = type(Value);
		if Type == "string" then
			sb.logInfo(Value);
		elseif Type == "function" then
			Value();
		end
	end
	return ID;
end

--Adds a coroutine injection
function Server.AddCoroutineInjection(OnCancel)
	local Running = coroutine.running();
	local Coroutine = CoroutineCalls[ThreadToID[Running]];
	if Coroutine ~= nil then
		local ID = sb.makeUuid();
		Coroutine.Injections[ID] = OnCancel;
		return ID;
	end
end

--Removes a coroutine injection
function Server.RemoveCoroutineInjection(ID)
	local Running = coroutine.running();
	local Coroutine = CoroutineCalls[ThreadToID[Running]];
	if Coroutine ~= nil and ID ~= nil then
		Coroutine.Injections[ID] = nil;
	end
end

--Cancels a coroutine
function Server.CancelCoroutine(ID)
	local Data = CoroutineCalls[ID];
	if Data ~= nil then
		if Data.OnCancel ~= nil then
			Data.OnCancel();
		end
		CoroutineCalls[ID] = nil;
	end
end

--Sets whether the group values should be saved on exit or not (true is the default)
function Server.SaveValuesOnExit(GroupName,bool)
	if SyncedValues[GroupName] ~= nil then
		SyncedValues[GroupName].SaveOnUninit = bool == true;
	end
end

--Sets up the values to be synced under the groupName
function Server.DefineSyncedValues(GroupName,...)
	if Initialized == false then
		Server.Initialize();
	end
	local NewSyncedValues = {
		Values = config.getParameter("__" .. GroupName .. "Save"),
		ValueNames = {},
		UUID = config.getParameter("__" .. GroupName .. "SaveUUID") or sb.makeUuid(),
		SaveOnUninit = true
	};
	local RetrievedValues = false;
	if NewSyncedValues.Values ~= nil then
		RetrievedValues = true;
	else
		NewSyncedValues.Values = {};
	end
	SyncedValues[GroupName] = NewSyncedValues;
	for ValueName,DefaultValue in Server.ParameterIter(2,...) do
		NewSyncedValues.ValueNames[#NewSyncedValues.ValueNames + 1] = ValueName;
		if RetrievedValues == false then
			NewSyncedValues.Values[ValueName] = DefaultValue;
		end

		local ChangeFunctions;

		local SetFunction = function(newValue,newUUID)
			if NewSyncedValues.Values[ValueName] ~= newValue then
				NewSyncedValues.Values[ValueName] = newValue;
				if ChangeFunctions ~= nil then
					for _,func in ipairs(ChangeFunctions) do
						func();
					end
				end
				NewSyncedValues.UUID = newUUID or sb.makeUuid();
				if object ~= nil then
					object.setConfigParameter("__" .. GroupName .. "SaveUUID",NewSyncedValues.UUID);
					object.setConfigParameter("__" .. GroupName .. "Save",NewSyncedValues.Values);
				end
			end
		end
		DefinitionTable["Set" .. ValueName] = SetFunction;
		local GetFunction = function()
			return NewSyncedValues.Values[ValueName];
		end
		DefinitionTable["Get" .. ValueName] = GetFunction;

		local AddChangeFunction = function(func)
			if ChangeFunctions == nil then
				ChangeFunctions = {func};
			else
				ChangeFunctions[#ChangeFunctions + 1] = func;
			end
		end

		message.setHandler("Set" .. ValueName,function(_,_,newValue,newUUID)
			SetFunction(newValue,newUUID);
		end);
	end
	message.setHandler("Update" .. GroupName,function(_,_,uuid)
		if NewSyncedValues.UUID == uuid then
			return false;
		else
			local ReturnTable = {};
			for _,valueName in ipairs(NewSyncedValues.ValueNames) do
				ReturnTable[valueName] = NewSyncedValues.Values[valueName];
			end
			return ReturnTable;
		end
	end);
end

--Sets a table that will have the functions defined when calling Server.DefineSyncedValues
--Defaults to the Server Table
function Server.SetDefinitionTable(tbl)
	DefinitionTable = tbl;
end

--Loops over the parameters and groups them by the pairs amount
function Server.ParameterIter(pairAmount,...)
	pairAmount = pairAmount or 1;
	if pairAmount == 1 then
		local Iterator = Server.UniIter({...});
		return function()
			local _,i = Iterator();
			return i;
		end
	elseif pairAmount > 1 then
		local ParameterCount = select("#",...);
		local CurrentStartIndex = 1;
		local Parameters = {...};
		return function()
			::Restart::
			if CurrentStartIndex > ParameterCount then
				return nil;
			end
			if Parameters[CurrentStartIndex] ~= nil then
				local ReturnValues = {};
				for i=0,pairAmount - 1 do
					ReturnValues[i + 1] = Parameters[CurrentStartIndex + i];
				end
				CurrentStartIndex = CurrentStartIndex + pairAmount;
				return table.unpack(ReturnValues);
			else
				CurrentStartIndex = CurrentStartIndex + pairAmount;
			end
			goto Restart;
		end
	else
		return function()
			return nil;
		end
	end
end

--Sets whether the group should save it's settings upon uninitialization or not
--[[function SaveOnUninit(groupName,bool)
	if SyncedValues[groupName] ~= nil then
		SyncedValues[groupName].SaveOnUninit = bool == true;
	end
end--]]

--Called when the object uninitializes
Uninit = function()
	if Dying == false then
		for Group,GroupValues in pairs(SyncedValues) do
			if object ~= nil and GroupValues.SaveOnUninit == true then
				object.setConfigParameter("__" .. Group .. "Save",GroupValues.Values);
				object.setConfigParameter("__" .. Group .. "SaveUUID",GroupValues.UUID);
			end
		end
	end
end