
local First = false;
local oldUpdate = update;
local MainObject = nil;
local PlayerID = nil;

function update(dt)
	if oldUpdate ~= nil then
		oldUpdate(dt);
	end
	if First == false then
		First = true;
		MainObject = config.getParameter("MainObject");
		MainObjectPosition = world.entityPosition(MainObject);
		PlayerID = pane.sourceEntity();
	end
	if world.magnitude(MainObjectPosition,world.entityPosition(PlayerID)) > 10 or world.entityExists(MainObject) == false then
		pane.dismiss();
	end
end
