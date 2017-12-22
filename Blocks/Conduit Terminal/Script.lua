local Hue = 0;
local Saturation = 0;

local UpdateLooks;

function init()
	Hue = config.getParameter("Hue",0);
	Saturation = config.getParameter("Saturation",0);
	message.setHandler("SetHue",function(_,_,newHue)
		Hue = newHue;
		object.setConfigParameter("Hue",newHue);
		UpdateLooks();
	end);
	message.setHandler("SetSaturation",function(_,_,newSat)
		Saturation = newSat;
		object.setConfigParameter("Saturation",newSat);
		UpdateLooks();
	end);
	UpdateLooks();
end

UpdateLooks = function()
	object.setProcessingDirectives("?hueshift=" .. Hue .. "?saturation=" .. Saturation);
end

function ResetPathCache()
	
end

function update(dt)
	Hue = Hue + 1;
	if Hue > 360 then
		Hue = 0;
	end
	object.setProcessingDirectives("?hueshift=" .. Hue);
end

function die()
	
end

function uninit()
	
end