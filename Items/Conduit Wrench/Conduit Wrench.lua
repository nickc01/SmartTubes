local SetupAim;
local UpdateAim;

function init()
	SetupAim();
end

function update(dt)
	UpdateAim();
end
















SetupAim = function()
	activeItem.setTwoHandedGrip(false);
	animator.resetTransformationGroup("wrench");
	animator.rotateTransformationGroup("wrench",1.75 * math.pi,{-0.6,0.6});
	animator.translateTransformationGroup("wrench",{0.55,0.3});
end

UpdateAim = function()
	local aim,direction = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end