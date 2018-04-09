
--Variables
local Info;

--Functions
local PlaceObject;

--The update loop, which checks if this builder can place the object
function update(dt)
	if Info ~= nil and world.material(Info.Position,"foreground") == false then
		PlaceObject();
	end
	
end

--Recieves the information about the facade to be placed
function ReceiveInfo(info)
	Info = info;
	
end

--Places the object into the world
PlaceObject = function()
	--[[local Params = {
		FacadeInfo = Info,
	};--]]
	local Params = Info.Parameters or {};
	Info.Parameters = nil;
	Params.FacadeInfo = Info;
	world.placeObject(Info.Object,Info.Position,nil,Params);
	--TODO 

	--REDESIGN THE FACADE.LUA FILE

	--TODO
	projectile.die();
end
























--[[local Info = nil;
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
end--]]