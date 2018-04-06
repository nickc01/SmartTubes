require("/Core/ServerCore.lua");

--Variables
local ExtractionConfigBuffer;
local Data = {};

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
	message.setHandler("SetCopyBuffer",function(_,_,config)
		ExtractionConfigBuffer = config;
	end);
	message.setHandler("GetCopyBuffer",function()
		return ExtractionConfigBuffer;
	end);
	message.setHandler("BufferIsSet",function()
		return ExtractionConfigBuffer ~= nil;
	end);
end

function uninit()
	if oldUninit ~= nil then
		oldUninit();
	end
end