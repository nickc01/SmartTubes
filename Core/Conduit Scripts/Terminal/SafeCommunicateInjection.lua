--Requirements
require("/Core/UICore.lua");
require("/Core/Conduit Scripts/Terminal/SafeCommunicateOverride.lua");

--Declaration
local Private = {};

--Variables
SafeCommunicateInjected = true;
local FuncInfo = {};
local FuncTops = {};
local MainRoutine;
local StoredDT = 0;
local Initialized = false;
local StringToLuaLink = function(link)
	local Tbl = _ENV;
	local Link;
	for word in string.gmatch(link,"([^%.]+)") do
		if Link == nil then
			Link = word;
		else
			if Tbl[Link] == nil then
				Tbl[Link] = {};
			end
			Tbl = Tbl[Link];
			Link = word;
		end
	end
	return Tbl,Link;
end

--Functions
Private.Old = {};

function Private.init()
	--sb.logInfo("Should be On Top Init");
	SafeCommunicate.Initialize();
	local ScriptCallbacks = config.getParameter("scriptWidgetCallbacks");
	sb.logInfo("Script Callbacks = " .. sb.print(ScriptCallbacks));
	--StringToLuaLink("test1.t4.best.link.ever.tbl");
	for _,callback in ipairs(ScriptCallbacks) do
		--local Tbl,Link = StringToLuaLink(callback);
		Private.AddTopFunc(callback,function(valid,nextFunc,...)
			local Args = {...};
			if nextFunc ~= nil then
				UICore.AddAsyncCoroutine(function()
					if Initialized == true then
						nextFunc(table.unpack(Args));
					end
				end);
			end
		end);
	end
end

function Private.initHandler(valid,nextFunc)
	if MainRoutine == nil then
		MainRoutine = sb.makeUuid();
	end
	if nextFunc ~= nil then
		UICore.QuickAsync(MainRoutine,function()
			nextFunc();
			Initialized = true;
			Private.CheckTopFunc("update");
		end);
	end
end

function Private.update(dt)
	--sb.logInfo("Should be On Top Update");
end

function Private.updateHandler(valid,nextFunc,dt)
	if nextFunc ~= nil then
		if UICore.AsyncDone(MainRoutine) then
			local FinalDT = StoredDT + dt;
			StoredDT = 0;
			UICore.QuickAsync(MainRoutine,function()
				nextFunc(StoredDT + dt);
				Private.CheckTopFunc("update");
			end);
		else
			StoredDT = StoredDT + dt;
		end
	end
end

function Private.die()

end

function Private.uninit()
	--sb.logInfo("Should be On Top Uninit");	
end

function Private.AddTopFunc(funcName,NextFuncHandler)
	local Func;
	local Tbl,Link = StringToLuaLink(funcName);
	Func = function(...)
		if FuncInfo[Func].Valid == nil then
			--[[if Private.Old[funcName] ~= nil then
				sb.logInfo("Running Old");
				--Private.Old[funcName](...);
			end--]]
			if NextFuncHandler ~= nil then
				NextFuncHandler(false,FuncInfo[Func].NextFunc,...);
			else
				if FuncInfo[Func].NextFunc ~= nil then
					FuncInfo[Func].NextFunc(...);
				end
			end
		elseif FuncInfo[Func].Valid == true then
			if Tbl[Link] == Func then
				--sb.logInfo("Still Valid");
				--sb.logInfo("Calling");
				if Private[funcName] ~= nil then
					Private[funcName](...);
				end
				--[[if Private.Old[funcName] ~= nil then
					Private.Old[funcName](...);
				end--]]
				if NextFuncHandler ~= nil then
					NextFuncHandler(true,FuncInfo[Func].NextFunc,...);
				else
					if FuncInfo[Func].NextFunc ~= nil then
						FuncInfo[Func].NextFunc(...);
					end
				end
			else
				Private.AddTopFunc(funcName);
				--sb.logInfo("Invalidaded and replacing");
				FuncInfo[Func].Valid = nil;
				--[[if Private.Old[funcName] ~= nil then
					Private.Old[funcName](...);
				end--]]
				if NextFuncHandler ~= nil then
					NextFuncHandler(false,FuncInfo[Func].NextFunc,...);
				else
					if FuncInfo[Func].NextFunc ~= nil then
						FuncInfo[Func].NextFunc(...);
					end
				end
			end
		end
	end
	FuncInfo[Func] = {NextFunc = Tbl[Link],Valid = true};
	FuncTops[funcName] = Func;
	--Private.Old[funcName] = _ENV[funcName];
	Tbl[Link] = Func;
end

function Private.CheckTopFunc(funcName)
	local Tbl,Link = StringToLuaLink(funcName);
	local Func = FuncTops[funcName];
	if Tbl[Link] == Func then
		--sb.logInfo("Still Valid");
		--sb.logInfo("Calling");
		--Private[funcName](...);
		--[[if Private.Old[funcName] ~= nil then
			Private.Old[funcName](...);
		end--]]
		--[[if NextFuncHandler ~= nil then
			NextFuncHandler(true,FuncInfo[Func].NextFunc,...);
		else
			if FuncInfo[Func].NextFunc ~= nil then
				FuncInfo[Func].NextFunc(...);
			end
		end--]]
	else
		Private.AddTopFunc(funcName);
		--sb.logInfo("Invalidaded and replacing");
		FuncInfo[Func].Valid = nil;
		--[[if Private.Old[funcName] ~= nil then
			Private.Old[funcName](...);
		end--]]
		--[[if NextFuncHandler ~= nil then
			NextFuncHandler(false,FuncInfo[Func].NextFunc,...);
		else
			if FuncInfo[Func].NextFunc ~= nil then
				FuncInfo[Func].NextFunc(...);
			end
		end--]]
	end
end


Private.AddTopFunc("init",Private.initHandler);
Private.AddTopFunc("update",Private.updateHandler);
Private.AddTopFunc("die",Private.dieHandler);
Private.AddTopFunc("uninit",Private.uninitHandler);