if UICore ~= nil then return nil end;

--Declaration

--Public Table
UICore = {};
local UICore = UICore;

--Private Table, PLEASE DON'T TOUCH
__UICore__ = {};
local __UICore__ = __UICore__;

--Variables
local PromiseLoopCalls = {};
local ResetPromiseLoopCalls = {};
local SyncedValues = {};
local DefinitionTable = UICore;

--Functions

--Initializes the UICore
function UICore.Initialize()
	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		for _,func in pairs(PromiseLoopCalls) do
			func();
		end
	end
end

--Continously calls a function and if it returns true then call the passed in function
function UICore.LoopCallContinuously(ID,func,Message,ParamFunc)
	if not world.entityExists(ID) then error(sb.print(ID) .. " doesn't exist") end;
	local Promise = world.sendEntityMessage(ID,Message,ParamFunc());
	--local Parameters = {...};
	local CallID = sb.makeUuid();
	PromiseLoopCalls[CallID] = function()
		if Promise:finished() then
			local Result = Promise:result();
			if Result ~= nil then
				local CallFunc = false;
				local CallFuncParameters = {};
				local Type = type(Result);
				if Type == "table" then
					--TODO
					CallFunc = Result[1] or false;
					CallFuncParameters = {};
					for i=1,select("#",table.unpack(Result)) do
						if i > 1 then
							CallFuncParameters[i - 1] = Result[i];
						end
					end
				else
					CallFunc = Result;
				end
				if CallFunc == true then
					func(table.unpack(CallFuncParameters));
				end
			end
			Promise = world.sendEntityMessage(ID,Message,ParamFunc());
		end
	end
	ResetPromiseLoopCalls[CallID] = function()
		Promise = world.sendEntityMessage(ID,Message,ParamFunc());
	end
	return CallID;
end

--Calls the message continously but only allows one return value and no parameters
function UICore.SimpleLoopCall(ID,Message,func)
	if not world.entityExists(ID) then error(sb.print(ID) .. " doesn't exist") end;
	local Promise = world.sendEntityMessage(ID,Message);
	local CallID = sb.makeUuid();
	PromiseLoopCalls[CallID] = function()
		if Promise:finished() then
			func(Promise:result());
			Promise = world.sendEntityMessage(ID,Message);
		end
	end
	ResetPromiseLoopCalls[CallID] = function()
		Promise = world.sendEntityMessage(ID,Message);
	end
	return CallID;
end

--Calls the message once and passes any results into the passed function
function UICore.CallMessageOnce(ID,Message,func,...)
	local Promise = world.sendEntityMessage(ID,Message,...);
	local CallID = sb.makeUuid();
	PromiseLoopCalls[CallID] = function()
		if Promise:finished() then
			func(Promise:result());
			--table.remove(PromiseLoopCalls,CallID);
			--table.remove(ResetPromiseLoopCalls,CallID);
			PromiseLoopCalls[CallID] = nil;
			ResetPromiseLoopCalls[CallID] = nil;
		end
	end
	ResetPromiseLoopCalls[CallID] = function()
		
	end
	return CallID;
end

--Resets a Loop Call To call again, mainly used for stability
function UICore.ResetLoopCall(CallID)
	ResetPromiseLoopCalls[CallID]();
end

--Iterates over any type of table
function UICore.UniIter(tbl)
	local k,i = nil;
	return function()
		k,i = next(tbl,k);
		return k,i;
	end
end

--If the table was intended to have it's indexes as "number" types, this will make sure it will
--This should be used when passing tables via world.sendEntityMessage because it can convert the indexes to "string" types
function UICore.MakeNumberTable(tbl)
	if type(next(tbl)) == "string" then
		local NewTable = {};
		for k,i in UICore.UniIter(tbl) do
			NewTable[tonumber(k)] = i;
		end
		return NewTable;
	else
		return tbl;
	end
end

--An Number Indexer that uses rawget
function UICore.Rawipairs(tbl)
	local i = 0;
	return function()
		i = i + 1;
		local Value = rawget(tbl,i);
		if Value == nil then
			return nil;
		else
			return i,Value;
		end
	end
end

--Sets a table that will have the functions defined when calling Server.DefineSyncedValues
--Defaults to the Server Table
function UICore.SetDefinitionTable(tbl)
	DefinitionTable = tbl;
end

--Loops over the parameters and groups them by the pairs amount
function UICore.ParameterIter(pairAmount,...)
	pairAmount = pairAmount or 1;
	if pairAmount == 1 then
		local Iterator = UICore.UniIter({...});
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

--Sets value names to synced over the server under the group name
--All the extra values should go under the following
--ValueName
--DefaultValue

--The ID can be a number or a function that returns a number
function UICore.SetAsSyncedValues(GroupName,ID,...)
	if type(ID) ~= "function" then
		local IDValue = ID;
		ID = function() return IDValue end;
	end
	local NewSyncedValues = {
		Values = world.getObjectParameter(ID(),"__" .. GroupName .. "Save"),
		ValueNames = {},
		ID = ID,
		UUID = world.getObjectParameter(ID(),"__" .. GroupName .. "SaveUUID") or sb.makeUuid();
	};
	local RetrievedValues = false;
	if NewSyncedValues.Values ~= nil then
		RetrievedValues = true;
	else
		NewSyncedValues.Values = {};
	end
	SyncedValues[GroupName] = NewSyncedValues;

	--local CallIndex = #PromiseLoopCalls + 1;
	local CallID = sb.makeUuid();

	for ValueName,DefaultValue in UICore.ParameterIter(2,...) do
		NewSyncedValues.ValueNames[#NewSyncedValues.ValueNames + 1] = ValueName;
		if RetrievedValues == false then
			NewSyncedValues.Values[ValueName] = DefaultValue;
		end

		local ChangeFunctions;
		
		local SetFunction = function(newValue)
			if NewSyncedValues.Values[ValueName] ~= newValue then
				NewSyncedValues.Values[ValueName] = newValue;
				if ChangeFunctions ~= nil then
					for _,func in ipairs(ChangeFunctions) do
						func();
					end
				end
				NewSyncedValues.UUID = sb.makeUuid();
				world.sendEntityMessage(NewSyncedValues.ID(),"Set" .. ValueName,newValue,NewSyncedValues.UUID);
				UICore.ResetLoopCall(CallID);
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
		DefinitionTable["Add" .. ValueName .. "ChangeFunction"] = AddChangeFunction;
	end

	local UpdateName = "Update" .. GroupName;
	local Promise = world.sendEntityMessage(NewSyncedValues.ID(),UpdateName,NewSyncedValues.UUID);
	local SettingValues = false;
	PromiseLoopCalls[CallID] = function()
		if Promise:finished() then
			local Result = Promise:result();
			if Result ~= nil and Result ~= false then
				SettingValues = true;
				for _,valueName in ipairs(NewSyncedValues.ValueNames) do
					DefinitionTable["Set" .. valueName](Result[valueName]);
				end
				SettingValues = false;
			end
			Promise = world.sendEntityMessage(NewSyncedValues.ID(),UpdateName,NewSyncedValues.UUID);
		end
	end
	ResetPromiseLoopCalls[CallID] = function()
		if SettingValues == false then
			Promise = world.sendEntityMessage(NewSyncedValues.ID(),UpdateName,NewSyncedValues.UUID);
		end
	end
	return CallID;
end