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

--Functions

--Initializes the UICore
function UICore.Initialize()
	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		for _,func in ipairs(PromiseLoopCalls) do
			func();
		end
	end
end

--Continously calls a function and if it returns true then call the passed in function
function UICore.LoopCallContinuously(ID,func,Message,ParamFunc)
	if not world.entityExists(ID) then error(sb.print(ID) .. " doesn't exist") end;
	local Promise = world.sendEntityMessage(ID,Message,ParamFunc());
	--local Parameters = {...};
	PromiseLoopCalls[#PromiseLoopCalls + 1] = function()
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
	ResetPromiseLoopCalls[#ResetPromiseLoopCalls + 1] = function()
		Promise = world.sendEntityMessage(ID,Message,ParamFunc());
	end
	return #PromiseLoopCalls;
end

--Calls the message continously but only allows one return value and no parameters
function UICore.SimpleLoopCall(ID,Message,func)
	if not world.entityExists(ID) then error(sb.print(ID) .. " doesn't exist") end;
	local Promise = world.sendEntityMessage(ID,Message);
	PromiseLoopCalls[#PromiseLoopCalls + 1] = function()
		if Promise:finished() then
			func(Promise:Result());
			Promise = world.sendEntityMessage(ID,Message);
		end
	end
	ResetPromiseLoopCalls[#ResetPromiseLoopCalls + 1] = function()
		Promise = world.sendEntityMessage(ID,Message);
	end
	return #PromiseLoopCalls;
end

--Resets a Loop Call To call again, mainly used for stability
function UICore.ResetLoopCall(Index)
	ResetPromiseLoopCalls[Index]();
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

--Sets value names to synced over the server under the group name
function UICore.SetAsSyncedValue(GroupName,...)
	
end