local oldInit = init;

local Config = {Index = 1,Breaking = false};

function init()
	if oldInit ~= nil then
		oldInit();
	end
	--sb.logInfo("Currency Test = " .. sb.printJson(root.itemConfig({name = "money",count = 1}),1));
	--sb.logInfo("_ENV = " .. sb.printJson({1,2},1));
	--[[for i in string.gmatch(sb.print(_ENV), "(.-:.-)[,}]") do
		sb.logInfo(i);
	end--]]
	--InterfaceInventory();
	--player.recordEvent("InterfaceInventory");
	--sb.logInfo(stringTable(_ENV,"_ENV"));
	--sb.logInfo("Json Object = " .. sb.print(jobject(1,2,3,4)));
	--player.interact("InterfaceInventory");
	message.setHandler("GetConfig",function(_,_)
		return Config;
	end);
	message.setHandler("SetConfig",function(_,_,value)
		sb.logInfo("Setting Config to " .. sb.print(value));
		Config = value;
	end);
	message.setHandler("SetSwapItem",function(_,_,item)
		player.setSwapSlotItem(item);
	end);
end

--[[function stringTable(table,name,spacer)
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
				startingString = startingString .. "	" .. k .. " = " .. sb.print(i) .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end--]]
