local oldInit = init;

local Config = {Index = 1,Breaking = false};

local ExtractionConfigCopy = nil;

function init()
	if oldInit ~= nil then
		oldInit();
	end
	message.setHandler("GetConfig",function(_,_)
		return Config;
	end);
	message.setHandler("SetConfig",function(_,_,value)
		Config = value;
	end);
	message.setHandler("SetSwapItem",function(_,_,item)
		player.setSwapSlotItem(item);
	end);
	message.setHandler("SetExtractionConfigCopy",function(_,_,config)
		sb.logInfo("Recieved = " .. sb.print(config));
		ExtractionConfigCopy = config;
	end);
	message.setHandler("RetrieveExtractionConfigCopy",function()
		return ExtractionConfigCopy;
	end);
	message.setHandler("PlayerHasCopy",function()
		sb.logInfo("Value = " .. sb.print(ExtractionConfigCopy));
		return ExtractionConfigCopy ~= nil;
	end);
end
