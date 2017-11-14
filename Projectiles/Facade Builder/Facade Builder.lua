
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
	world.placeObject(Info.Object,Info.Position,nil,{Info = Info});
	projectile.die();
end