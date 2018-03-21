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
end
