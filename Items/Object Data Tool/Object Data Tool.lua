
local PreviousState = "none";

function init()
	SetupAim();
end

function update(dt,fireMode)
	UpdateAim();
	if fireMode ~= PreviousState then
		PreviousState = fireMode;
		--sb.logInfo("Clicking TOOL!");
		OnClick(fireMode);
	end
end

function stringTable(table,name,spacer)
	if table == nil then return name ..  " = nil" end;
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		elseif type(i) == "function" then
				startingString = startingString .. "	" .. k .. " = (FUNC) " .. k;
		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. i .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end

function rgbToHex(rgb)
	local hexadecimal = '0X'

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

	return hexadecimal
end

function OnClick(fireMode)
	if fireMode == "primary" then
		local Object = world.objectAt(activeItem.ownerAimPosition());
		if Object ~= nil then
			local Params = world.getObjectParameter(Object,"RetainingParameters");
			--sb.logInfo("Params = " .. sb.print(Params));
			local Pos = world.entityPosition(Object);
			--sb.logInfo(stringTable(world,"World"));
			local Configs = {};
			if Params ~= nil then
				for k,i in ipairs(Params) do
					Configs[i] = world.getObjectParameter(Object,i);
				end
				--sb.logInfo("Configs = " .. sb.print(Configs));
				local R = math.random(0,255);
				local G = math.random(0,255);
				local B = math.random(0,255);
				--[[if R < 50 and G < 50 then
					B = 255 - R;
				end--]]
				local Icon = world.getObjectParameter(Object,"inventoryIcon");
				if string.find(Icon,"%?border=1;FF0000%?fade=007800;0%.1$") ~= nil then
					Configs["inventoryIcon"] = Icon;
				else
					Configs["inventoryIcon"] = Icon .. "?border=1;FF0000?fade=007800;0.1";
				end
				Configs["RetainingParameters"] = Params;
				world.sendEntityMessage(Object,"SmashCableBlockAndSpawnItem",nil,world.entityPosition(Object),10,Configs);
			end
			--world.sendEntityMessage(Object,"SetRetainingMode");
		end
	end
end

SetupAim = function()
	activeItem.setTwoHandedGrip(false);
	animator.resetTransformationGroup("objtool");
	animator.rotateTransformationGroup("objtool",1.75 * math.pi,{-0.6,0.6});
	animator.translateTransformationGroup("objtool",{0.55,0.3});
end

UpdateAim = function()
	local aim,direction = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition());
	activeItem.setArmAngle(aim);
	activeItem.setFacingDirection(direction);
end