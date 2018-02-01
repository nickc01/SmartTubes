
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
	if fireMode == "alt" then
		activeItem.interact("ScriptPane","/Items/Item Analyzer/UI/UI Config.config",activeItem.ownerEntityId());
	end
end

SetupAim = function()
	activeItem.setTwoHandedGrip(false);
	animator.resetTransformationGroup("itemana");
	--animator.rotateTransformationGroup("itemana",1.75 * math.pi,{-0.6,0.6});
	--animator.translateTransformationGroup("itemana",{0.55,0.3});
end

UpdateAim = function()
	local aim,direction = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end