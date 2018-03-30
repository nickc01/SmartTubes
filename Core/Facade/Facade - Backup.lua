require("/Core/Versioning.lua");
require("/Core/ConduitRelations.lua");
local oldInit = init;

local PlaceMaterials;

local ItemToDrop;

local Item = nil;

local DropPosition = nil;

local CompatibilityLink;

Facaded = true;

function GetDropPosition()
	return DropPosition;
end

function GetFacadeDropItem()
	return Item;
end

function init()
	--Versioning.ExecuteOnce();
	if config.getParameter("AltAnimation") == nil then
		object.setConfigParameter("AltAnimation",root.itemConfig(Relations.GetConduitOfFacade(object.name())).config.animationParts.cables);
	end
	script.setUpdateDelta(1);
	DropPosition = entity.position();
	object.setConfigParameter("IsFacade",true);
	if oldInit ~= nil then
		oldInit();
	end
	if config.getParameter("placeBlock") ~= nil or config.getParameter("IsOccluded") == nil then
		CompatibilityLink();
		object.setConfigParameter("placeBlock",nil);
	end
	local Info = config.getParameter("Info");
	if Info ~= nil then
		PlaceMaterials(Info);
		object.setConfigParameter("FacadeIndicator",Info.Indicator);
		object.setConfigParameter("IsOccluded",Info.IsOccluded);
	end
	Item = config.getParameter("FacadeItem");
	message.setHandler("GetInteraction",function(_,_,SourcePlayer)
		local InteractAction;
		local InteractData;
		if config.getParameter("interactData") ~= nil then
			InteractAction = config.getParameter("interactAction");
			InteractData = root.assetJson(config.getParameter("interactData"))
		else
			local OnInteractData = nil;
			if onInteraction ~= nil then
				OnInteractData = onInteraction({sourceId = SourcePlayer,sourcePosition = world.entityPosition(SourcePlayer)});
			end
			if OnInteractData ~= nil then
				InteractAction = OnInteractData[1];
				InteractData = OnInteractData[2];
			end
		end
		if InteractAction ~= nil then
			if InteractData.scriptDelta == nil or InteractData.scriptDelta == 0 then
				InteractData.scriptDelta = 1;
			end
			if InteractData.scripts ~= nil then
				InteractData.scripts[#InteractData.scripts + 1] = "/Core/Facade/Facade GUI Controller.lua";
			end
			InteractData.FacadePlayerID = SourcePlayer;
			InteractData.MainObject = entity.id();
			return {InteractAction,InteractData};
		end
	end);
	message.setHandler("Destroy",function(_,_,position)
		object.setHealth(0);
		DropPosition = position;
	end);
end

CompatibilityLink = function()
	local Name = object.name();
	local FacadeConfig = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	for i=1,#FacadeConfig do
		if Name == FacadeConfig[i].normalBlock then
			object.setConfigParameter("IsOccluded",false);
			object.setConfigParameter("FacadeIndicator",FacadeConfig[i].indicator);
		elseif Name == FacadeConfig[i].occludedBlock then
			object.setConfigParameter("IsOccluded",true);
			object.setConfigParameter("FacadeIndicator",FacadeConfig[i].indicator);
		end
	end
end

local oldUpdate = update;

function update(dt)
	if oldUpdate ~= nil then
		oldUpdate(dt);
	end
	local Material = world.material(entity.position(),"foreground");
	if Material == false then
		object.setHealth(0);
	end
end

PlaceMaterials = function(Info)
	world.placeMaterial(Info.Position,"foreground",Info.Foreground,Info.ForegroundHue,true);
	if Info.Background == false then
		world.damageTiles({Info.Position},"background",Info.Position,"explosive",9999,0);
	end
	if Info.ForegroundMod ~= false and Info.ForegroundMod ~= nil then
		world.placeMod(Info.Position,"foreground",Info.ForegroundMod,Info.ForegroundModHue,true);
	end
	object.setConfigParameter("FacadeItem",Info.Item);
	object.setConfigParameter("Info",nil);
end

local oldDie = die;

function die()
	if oldDie ~= nil then
		oldDie();
	end
	if Item ~= nil and CableCore.Smashing == false then
		world.spawnItem({name = Item,count = 1},DropPosition,1);
	end
end
