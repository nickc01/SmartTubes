local oldInit = init;

local Config = {Index = 1,Breaking = false};

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
end
