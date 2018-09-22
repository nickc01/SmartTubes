--Declaration
require("/Core/Conduit Scripts/Terminal/SafeCommunicate.lua");
if SafeCommunicate == nil then
	SafeCommunicate = {};
end

--Variables
local Overridden = false;
local EntityExists;

--Functions
local DefineOverride;


--Initiates the Override
function SafeCommunicate.Override()
	if Overridden == true then return nil end;
	Overridden = true;
	EntityExists = world.entityExists;
	DefineOverride(world,"containerItems","GetContainerItems");
	DefineOverride(world,"entityPosition","GetObjectPosition");
	DefineOverride(world,"entityName","GetObjectName");
	DefineOverride(world,"objectSpaces","GetObjectSpaces");
	DefineOverride(world,"getObjectParameter","GetObjectParameter");
	DefineOverride(world,"containerSize","GetContainerSize");
	DefineOverride(world,"containerItemAt","GetContainerItemAt");
	DefineOverride(world,"containerConsume","ContainerConsume");
	DefineOverride(world,"containerConsumeAt","ContainerConsumeAt");
	DefineOverride(world,"containerAvailable","ContainerAvailable");
	DefineOverride(world,"containerTakeAll","ContainerTakeAll");
	DefineOverride(world,"containerTakeAt","ContainerTakeAt");
	DefineOverride(world,"containerTakeNumItemsAt","ContainerTakeNumItemsAt");
	DefineOverride(world,"containerItemsCanFit","ContainerItemsCanFit");
	DefineOverride(world,"containerItemsFitWhere","ContainerItemsFitWhere");
	DefineOverride(world,"containerAddItems","ContainerAddItems");
	DefineOverride(world,"containerStackItems","ContainerStackItems");
	DefineOverride(world,"containerPutItemsAt","ContainerPutItemsAt");
	DefineOverride(world,"containerItemsApply","ContainerItemsApply");
	DefineOverride(world,"containerSwapItemsNoCombine","ContainerSwapItemsNoCombine");
	DefineOverride(world,"containerSwapItems","ContainerSwapItems");
	DefineOverride(world,"sendEntityMessage","SendEntityMessage");
	DefineOverride(world,"entityExists","ObjectExists");
	pane.oldsourceEntity = pane.sourceEntity;
	pane.sourceEntity = function()
		return SafeCommunicate.GetSourceID();
	end
	--[[world.entityPosition = function(id)
		return SafeCommunicate.GetObjectPositionAsync(id);
	end

	world.entityName = function(id)
		return SafeCommunicate.GetObjectNameAsync(id);
	end

	world.objectSpaces = function(id)
		return SafeCommunicate.GetObjectSpacesAsync(id);
	end

	world.getObjectParameter = function(id,name,default)
		return SafeCommunicate.GetObjectParameterAsync(id,name,default);
	end

	world.containerSize = function(id)
		return SafeCommunicate.GetContainerSizeAsync(id);
	end

	world.containerItems = function(id)
		return SafeCommunicate.GetContainerItemsAsync(id);
	end

	world.containerItemAt = function(id,offset)
		return SafeCommunicate.GetContainerItemAtAsync(id,offset);
	end--]]
end

DefineOverride = function(tbl,funcName,callName)
	tbl["old" .. funcName] = tbl[funcName];
	tbl[funcName] = function(...)
		return SafeCommunicate[callName .. "Async"](...);
	end
end
