require("/Core/ConduitCore.lua");

--Variables
local CraftingFilters = {};
--[[local _upstates = {};
local UpgradeStates = setmetatable({},{
	__index = function(tbl,k)
		return _upstates(tostring(k));
	end,
	__newindex = function(tbl,k,v)
		_upstates[tostring(k)] = v;
	end
});--]]
local UpgradeStates = {};

--Functions
local GetUIInfoOfObject;
local ConnectionUpdated;
local GetExactItem;
local PostInit;

--The Init function for the crafting conduit
function init()
	ConduitCore.AddConnectionType("Crafting",function(ID)
		local Interaction = GetUIInfoOfObject(ID);
		if Interaction ~= nil and Interaction[1] == "OpenCraftingInterface" then
			return true;
		end
		return false;
	end);
	ConduitCore.AddPostInitFunction(PostInit);
	ConduitCore.UpdateContinuously(true);
	ConduitCore.AddConnectionUpdateFunction(ConnectionUpdated);
	ConduitCore.Initialize();
end

--The Update function for the crafting conduit
function update(dt)
	local Connections = ConduitCore.GetConnections("Crafting");
	if Connections ~= false then
		for index,connection in ipairs(Connections) do
			if UpgradeStates[index] ~= "nil" then
				local UpgradeData = world.callScriptedEntity(connection,"currentStageData");
				if UpgradeStates[index] ~= UpgradeData then
					--ConnectionUpdated();
					sb.logInfo("Test");
					ConduitCore.TriggerConnectionUpdate();
				end
			end
		end
	end
end

PostInit = function()
	ConnectionUpdated();
end

--The Die function for the crafting conduit
function die()

end

--The Uninit function for the crafting conduit
function uninit()

end

ConnectionUpdated = function()
	CraftingFilters = {};
	UpgradeStates = {};
	for index,connection in ipairs(ConduitCore.GetConnections("Crafting")) do
		if connection == 0 then
			UpgradeStates[index] = "nil";
			goto NextConnection;
		end
		local UIInfo = GetUIInfoOfObject(connection);
		local UpgradeData = world.callScriptedEntity(connection,"currentStageData");
		if UpgradeData ~= nil then
			UpgradeStates[index] = UpgradeData;
		else
			UpgradeStates[index] = "nil";
		end
		if UIInfo ~= nil then
			local UIData = UIInfo[2];
			--sb.logInfo("UIDATA = " .. sb.print(UIData));
			local Filters = {};
			if UIData.filter ~= nil then
				for _,filter in ipairs(UIData.filter) do
					Filters[#Filters + 1] = filter;
				end
			end
			local UILink = UIData.config;
			local UI = root.assetJson(UILink);
			if UI.filter ~= nil then
				for _,filter in ipairs(UI.filter) do
					Filters[#Filters + 1] = filter;
				end
			end
			local Item = GetExactItem(connection);
			Item.CraftingFilters = Filters;
			Item.ID = connection;
			CraftingFilters[#CraftingFilters + 1] = Item;
			--CraftingFilters[world.entityName(connection)] = Filters;
		end
		::NextConnection::
	end
	sb.logInfo("Network");
	ConduitCore.TriggerNetworkUpdate("TerminalFindings");
	--sb.logInfo("Crafting Filters = " .. sb.print(CraftingFilters));
end

GetUIInfoOfObject = function(ID)
	if world.entityExists(ID) then
		local Interaction = world.callScriptedEntity(ID,"onInteraction",OnInteractData);
		if Interaction ~= nil then
			return Interaction;
		else
			local DataTable;
			local UpgradeData = world.callScriptedEntity(ID,"currentStageData");
			if UpgradeData == nil then
				DataTable = setmetatable({},{
					__index = function(tbl,k)
						return world.getObjectParameter(ID,k);
					end
				});
			else
				DataTable = UpgradeData;
			end
			local InteractAction = DataTable["interactAction"];
			if InteractAction ~= nil then
				return {InteractAction,DataTable["interactData"]};
			else
				return nil;
			end
		end
	end
	return nil;
end

--Gets the Exact item use to spawn the object, this includes the current upgrade state of the crafter
GetExactItem = function(id)
	local StageData = world.callScriptedEntity(id,"currentStateData");
	if StageData ~= nil then
		return {name = world.entityName(id),count = 1,parameters = StageData.itemSpawnParameters};
	else
		return {name = world.entityName(id),count = 1};
	end
end

--Returns the crafting filters connected to this crafting conduit
function GetCraftingFilters()
	return CraftingFilters;
end