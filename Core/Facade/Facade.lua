require("/Core/ConduitCore.lua");


--Variables

--Functions
local OldInit = init;
local PlaceMaterials;

function init()
	if OldInit ~= nil then
		OldInit();
	end
	local Info = config.getParameter("FacadeInfo");
	if Info ~= nil then
		ConduitCore.SetAsFacade(Info.Indicator,Info.Occluded,Info.Item);
		object.setConfigParameter("FacadeIndicator",Info.Indicator);
		if config.getParameter("MaterialIsPlaced") ~= true then
			PlaceMaterials(Info);
			object.setConfigParameter("IsAFacade",true);
			object.setConfigParameter("MaterialIsPlaced",true);
		end
		message.setHandler("DestroyFacade",function(_,_,position)
			ConduitCore.Destroy(position);
		end);
		message.setHandler("GetInteraction",function(_,_,PlayerID)
			if config.getParameter("interactData") ~= nil then
				InteractAction = config.getParameter("interactAction");
				InteractData = root.assetJson(config.getParameter("interactData"))
			else
				local OnInteractData = nil;
				if onInteraction ~= nil then
					OnInteractData = onInteraction({sourceId = PlayerID,sourcePosition = world.entityPosition(PlayerID)});
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
				InteractData.SourcePlayer = PlayerID;
				InteractData.MainObject = entity.id();
				return {InteractAction,InteractData};
			end
		end);	
	end
end


--Places the Materials on top of the Facade
PlaceMaterials = function(Info)
	world.placeMaterial(Info.Position,"foreground",Info.Foreground,nil,true);
	if Info.Background == false then
		world.damageTiles({Info.Position},"background",Info.Position,"explosive",9999,0);
	end
end