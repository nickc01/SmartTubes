require("/Core/ServerCore.lua");

--Variables
local ExtractionConfigBuffer;
local Data = {};
local UsingTerminal = false;

--Functions
local oldInit = init;
local oldUninit = uninit;


function init()
	--sb.logInfo("Result = " .. sb.printJson(root.assetJson("/interface/windowconfig/playerinventory.config"),1));
	if oldInit ~= nil then
		oldInit();
	end
	Server.SetDefinitionTable(Data);
	Server.DefineSyncedValues("Settings","Index",1,"Breaking",false);
	message.setHandler("SetSwapItem",function(_,_,item)
		player.setSwapSlotItem(item);
	end);
	message.setHandler("SetCopyBuffer",function(_,isLocal,config)
		--sb.logInfo("COPY BUFFER LOCAL = " .. sb.print(isLocal));
		ExtractionConfigBuffer = config;
	end);
	message.setHandler("GetCopyBuffer",function()
		return ExtractionConfigBuffer;
	end);
	message.setHandler("BufferIsSet",function(_,isLocal)
		--sb.logInfo("Buffer Is Set Local = " .. sb.print(isLocal));
		return ExtractionConfigBuffer ~= nil;
	end);
	message.setHandler("UsingTerminal",function()
		return UsingTerminal == true;
	end);
	message.setHandler("SetUsingTerminal",function(_,_,bool)
		UsingTerminal = bool == true;
	end);
	message.setHandler("ConsumeItem",function(_,_,item,consumePartial,exact)
		return player.consumeItem(item,consumePartial,exact);
	end);
	message.setHandler("ConsumeCurrency",function(_,_,currencyName,amount)
		return player.consumeCurrency(currencyName,amount);
	end);
	message.setHandler("AmountOfItem",function(_,_,item,exact)
		if exact == nil then
			exact = true;
		end
		return player.hasCountOfItem(item,exact);
	end);
	message.setHandler("AmountOfCurrency",function(_,_,currencyName)
		return player.currency(currencyName);
	end);
end

--function TestFunction()
--	sb.logInfo("Test");
--end

function uninit()
	if oldUninit ~= nil then
		oldUninit();
	end
end

function stringTable(table,name,spacer)
	if table == nil then return name ..  " = nil" end;
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		--else
			--startingString = startingString .. "	" .. k .. " = " .. 
		elseif type(i) == "function" then
				startingString = startingString .. "	" .. k .. " = (FUNC) " .. sb.print(i);
		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. sb.print(i) .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end