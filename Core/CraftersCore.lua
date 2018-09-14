

--Declaration
CraftersCore = {};
local CraftersCore = CraftersCore;

--Variables
local LearntCrafters;

--Functions
local GroupsToItem;
local AddLearntCrafter;
local GetFromLearntList;
local GetItemsAndGroups;
local TableIntersect;

--GroupsToItem = function(Groups)
function CraftersCore.GroupsToItem(Groups)
	--First, Check if it's in the Learnt List Already
	local Item = GetFromLearntList(Groups);
	if Item ~= nil then
		return Item;
	end
	--Second, Check the Network to see if it's there
	if ConduitCore ~= nil then
		local Network = ConduitCore.GetConduitNetwork();
		for _,conduit in ipairs(Network) do
			local Type = world.getObjectParameter(conduit,"conduitType");
			if Type == "crafting" then
				local Filters = world.callScriptedEntity(conduit,"GetCraftingFilters");
				if Filters ~= nil then
					for _,filter in ipairs(Filters) do
						if TableIntersect(filter.CraftingFilters,Groups) == true then
							AddLearntCrafter(filter.CraftingFilters,filter);
							return filter;
						end
					end
				end
			end
		end
	end
	--Third, check if the groups have the same name as an item
	for _,group in ipairs(Groups) do
		sb.logInfo("group = " .. sb.print(group));
		local Item = root.createItem({name = group,count = 3});
		if Item == nil or Item.name ~= group then
			Item = root.createItem({name = string.gsub(group,"%d",""),count = 4});;
			if Item == nil or Item.name ~= string.gsub(group,"%d","") then
				Item = nil;
			end
		end
		if Item ~= nil then
			sb.logInfo("Found Item = " .. sb.print(Item));
			--AddLearntCrafter(Groups,Item);
			--return Item;
			local Items = GetItemsAndGroups(Item);
			for _,data in ipairs(Items) do
				for _,group in ipairs(Groups) do
					for _,filter in ipairs(data.Filters) do
						if group == filter then
							AddLearntCrafter(data.Filters,data.Item);
							return data.Item;
						end
					end
				end
			end
		end
	end
	return nil;
end

AddLearntCrafter = function(Groups,Item)
	LearntCrafters = world.getProperty("LearntCrafters") or {};
	for _,data in ipairs(LearntCrafters) do
		if root.itemDescriptorsMatch(data.Item,Item,true) then
			return nil;
		end
	end
	LearntCrafters[#LearntCrafters + 1] = {Item = Item,Groups = Groups};
	world.setProperty("LearntCrafters",LearntCrafters);
end

GetFromLearntList = function(Groups)
	if LearntCrafters == nil then
		LearntCrafters = world.getProperty("LearntCrafters") or {};
	end
	for _,data in ipairs(LearntCrafters) do
		for _,firstGroup in ipairs(Groups) do
			if firstGroup == "plain" then
				return "Player";
			else
				for _,secondGroup in ipairs(data.Groups) do
					if firstGroup == secondGroup then
						return data.Item;
					end
				end
			end
		end
	end
	return nil;
end

--Retrieves all possible items and groups of an item
GetItemsAndGroups = function(item)
	local ItemConfig = root.itemConfig(item);
	local Items = {};
	if ItemConfig.config.upgradeStages ~= nil then
		for state,stateData in ipairs(ItemConfig.config.upgradeStages) do
			local Item = {name = item.name,count = 1,parameters = stateData.itemSpawnParameters};
			local Filters;
			local FilterSources = {};
			if stateData.interactData ~= nil then
				if stateData.interactData.filter ~= nil then
					FilterSources[#FilterSources + 1] = stateData.interactData.filter;
				end
				local UIConfig = stateData.interactData.config;
				local UIData = root.assetJson(UIConfig);
				if UIData.filter ~= nil then
					FilterSources[#FilterSources + 1] = UIData.filter;
				end
			end
			Filters = MergeContents(FilterSources);
			Items[#Items + 1] = {Item = Item,Filters = Filters};
		end
	else
		local Item = {name = item.name,count = 1};
		local Filters;
		local FilterSources = {};
		if ItemConfig.config.filter ~= nil then
			FilterSources[#FilterSources + 1] = ItemConfig.config.filter;
		end
		if ItemConfig.config.interactData ~= nil then
			if ItemConfig.config.interactData.filter ~= nil then
				FilterSources[#FilterSources + 1] = ItemConfig.config.interactData.filter;
			end
			local UIConfig = ItemConfig.config.interactData.config;
			local UIData = root.assetJson(UIConfig);
			if UIData.filter ~= nil then
				FilterSources[#FilterSources + 1] = UIData.filter;
			end
		end
		Filters = MergeContents(FilterSources);
		Items[#Items + 1] = {Item = Item,Filters = Filters};
	end
	return Items;
end

TableIntersect = function(A,B)
	for i=1,#A do
		for j=1,#B do
			if A[i] == B[j] then
				return true;
			end
		end
	end
	return false;
end

MergeContents = function(B)
	local Table = {};
	for _,tbl in ipairs(B) do
		for _,element in ipairs(tbl) do
			for _,tblElement in ipairs(Table) do
				if tblElement == element then
					goto NextElement;
				end
			end
			Table[#Table + 1] = element;
			::NextElement::
		end
	end
	return Table;
end