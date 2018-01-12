
local Info = nil;
local PlaceObject;

function SendInfo(info)
	Info = info;
end
function update(dt)
	if world.material(Info.Position,"foreground") == false then
		PlaceObject();
	end
end

PlaceObject = function()
	local Params = {};
	Params.Info = Info;
	if Info.ExtraParameters ~= nil then
		for k,i in ipairs(Info.ExtraParameters.RetainingParameters) do
			if Info.ExtraParameters[i] ~= nil then
				Params[i] = Info.ExtraParameters[i];
			end
		end
	end
	world.placeObject(Info.Object,Info.Position,nil,Params);
	projectile.die();
end