
local PreviousState = "none";

function init()
	SetupAim();
end

function update(dt,fireMode)
	UpdateAim();
	if fireMode ~= PreviousState then
		PreviousState = fireMode;
		OnClick(fireMode);
	end
end

function OnClick(fireMode)
	if fireMode == "primary" then
		local Object = world.objectAt(activeItem.ownerAimPosition());
		if Object ~= nil and world.getObjectParameter(Object,"objectType") == "container" then
			local Config = root.assetJson("/Items/Inventory Item Analyzer/UI/UI Config.config");
			Config.InventoryItems = world.containerItems(Object);
			activeItem.interact("ScriptPane",Config,activeItem.ownerEntityId());
		end
		--activeItem.interact("ScriptPane","/Items/Inventory Item Analyzer/UI/UI Config.config",activeItem.ownerEntityId());
	end
end

SetupAim = function()
	activeItem.setTwoHandedGrip(false);
	animator.resetTransformationGroup("itemana");
end

UpdateAim = function()
	local aim,direction = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end
