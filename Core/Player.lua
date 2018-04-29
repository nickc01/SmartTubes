require("/Core/ServerCore.lua");

--Variables
local ExtractionConfigBuffer;
local Data = {};
local UsingTerminal = false;

--Functions
local oldInit = init;
local oldUninit = uninit;


function init()
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
end

function TestFunction()
	sb.logInfo("Test");
end

function uninit()
	if oldUninit ~= nil then
		oldUninit();
	end
end