if FacadeInfo ~= nil then return nil end

--Declaration

--Public Table
FacadeInfo = {};
local FacadeInfo = FacadeInfo;

--Variables
local Initialized = false;
local Json;
local ObjectConfigCache = {};

--Functions
local Setup;
local GetObjectConfig;

--Sets the the Facade Info for use
Setup = function()
	if Initialized == false then
		Initialized = true;
		Json = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	end
end

--Gets the name of the conduit relating the Facade
function FacadeInfo.FacadeToObject(facadeName)
	Setup();
	for _,info in ipairs(Json) do
		--sb.logInfo("facadeName = " .. sb.print(facadeName));
		--sb.logInfo("info = " .. sb.print(info));
		if info.normalBlock == facadeName or info.occludedBlock == facadeName then
			--sb.logInfo("Returning = " .. sb.print(info.conduit));
			return info.conduit;
		end
	end
end

--Returns the Configuration of the object relating the facade
function FacadeInfo.FacadeToObjectConfig(facadeName)
	return GetObjectConfig(FacadeInfo.FacadeToObject(facadeName));
end

--Returns the config of an object
GetObjectConfig = function(objectName)
	if ObjectConfigCache[objectName] == nil then
		ObjectConfigCache[objectName] = root.itemConfig({name = objectName,count = 1});
	end
	return ObjectConfigCache[objectName];
end