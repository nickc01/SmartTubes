require("/Core/ConduitCore.lua");
require("/Core/ServerCore.lua");
require("/Core/ConduitCoreBasics.lua");
require("/Core/Async.lua");

--Declaration
Controller = {};
local Controller = Controller;

--Variables
local ItemsToCraft;
local Initialized = false;
--local CurrencyToItemTbl = {};
--local ItemToCurrencyTbl = {};
local TESTTIMER = 0;
local Schedules = {};
local LearntCrafters;

local ItemsToCraftMeta = {
	__index = function(tbl,k)
		if k == "__AllValues__" then
			return rawget(tbl,"__Values");
		end
		if rawget(tbl,"__Values") == nil then
			rawset(tbl,"__Values",{});
		end
		local Values = rawget(tbl,"__Values");
		for item,data in pairs(Values) do
			--sb.logInfo("Item = " .. sb.print(item));
			--sb.logInfo("K = " .. sb.print(k));
			--sb.logInfo("Exact = " .. sb.print(k.parameters ~= nil));
			--sb.logInfo("Match = " .. sb.print(root.itemDescriptorsMatch(item,k,true)));
			if root.itemDescriptorsMatch(item,k,k.parameters ~= nil) then
				return data;
			end
		end
		return nil;
	end,
	__newindex = function(tbl,k,v)
		if rawget(tbl,"__Values") == nil then
			rawset(tbl,"__Values",{});
		end
		local Values = rawget(tbl,"__Values");
		for item,data in pairs(Values) do
			if root.itemDescriptorsMatch(item,k,k.parameters ~= nil) then
				Values[item] = v;
				return nil;
			end
		end
		Values[k] = v;
	end
};

--Functions
--local FindInNetwork;
--local ConsumeFromNetwork;
--local WaitFor;
local PostInit;
local OldUpdate = update;
local ScheduleUpdate;
--local CraftingGroupsToItem;
--local GetItemsAndGroups;



--Initializes the Crafting Controller
function Controller.Initialize()
	if Initialized == false then
		Initialized = true;
		LearntCrafters = world.getProperty("LearntCrafters") or {};
		--[[local Currencies = root.assetJson("/currencies.config");
		for currency,info in pairs(Currencies) do
			CurrencyToItemTbl[currency] = info.representativeItem;
			ItemToCurrencyTbl[info.representativeItem] = currency;
		end--]]
		--sb.logInfo("INITIALIZED");
		message.setHandler("Controller.UpdateCraftingList",function(_,_,slotItems)
			Controller.UpdateCraftingList(slotItems);
		end);
		--sb.logInfo("SlotItems = " .. sb.print(config.getParameter("SlotItems")));
		Controller.UpdateCraftingList(config.getParameter("SlotItems") or {});
		--ConduitCore.AddPostInitFunction(PostInit);
		--sb.logInfo(stringTable(_ENV,"_ENV"));
	end
end

update = function(dt)
	if OldUpdate ~= nil then
		OldUpdate(dt);
	end
	TESTTIMER = TESTTIMER + dt;
	if TESTTIMER > 1 and TESTTIMER < 2 then
		TESTTIMER = 2;
		--sb.logInfo("TEST SCHEDULE = " .. sb.printJson(Controller.GetScheduleInfo({name = "perfectlygenericitem",count = 10}),1));
		--[[local Routine;
		Routine = Async.Create(function()
			sb.logInfo("A");
			local Network = ConduitCore.GetConduitNetwork();
			sb.logInfo("Network = " .. sb.print(Network));
			for _,conduit in ipairs(Network) do
				if world.getObjectParameter(conduit,"conduitType") == "extraction" then
					sb.logInfo("Calling");
					--local TestValue = world.callScriptedEntity(conduit,"TESTASYNCLOOP")();
					local TestValue = Async.Remote(conduit,"TESTASYNCLOOP","testing123");
					sb.logInfo("TestValue = " .. sb.print(TestValue));
					--Async.Cancel(Routine);
					return nil;
				end
			end
		end,function() sb.logInfo("Source Canceled") end);--]]
		--[[Async.Create(function()
			local Count = 0;
			while(true) do
				Count = Count + 1;
				coroutine.yield();
				if Count > 360 then
					Async.Cancel(Routine);
					break;
				end
			end
		end);--]]
		--[[Server.AddAsyncCoroutine(function()
			local ScheduleControl = Controller.Schedule({name = "perfectlygenericitem",count = 10});
			while(true) do
				local Amount = ScheduleControl.Request();
				if Amount == true then
					break;
				else
					--sb.logInfo("Amount2222 = " .. sb.print(Amount));
					if Amount > 0 then
						world.spawnItem({name = "perfectlygenericitem",count = Amount},entity.position());
					end
				end
				coroutine.yield();
			end
		end);--]]
	end
end

--Schedules the item to be crafted
--Returns a Schedule Controller Table when successful, or false if not successful
function Controller.Schedule(item,playerID,doAsync)
	if useFound == nil then
		useFound = false;
	end
	local Info = Controller.GetScheduleInfo(item,false,playerID,doAsync);
	local ScheduleID = sb.makeUuid();
	Schedules[ScheduleID] = Info;
	--sb.logInfo("Initial Schedule = " .. sb.printJson(Schedules,1));
	ScheduleUpdate();
	local Leftovers = setmetatable({},ItemsToCraftMeta);
	local ScheduleController = {};
	local ExtractFromPlayer;
	ExtractFromPlayer = function(info)
		if info.Player ~= nil then
			local AmountFound = ConduitBasic.FindOnPlayer(info.Player.ID,info.Item,true);
			if AmountFound > info.Player.Found then
				AmountFound = info.Player.Found;
			end
			if AmountFound > 0 and ConduitBasic.ConsumeFromPlayer(info.Player.ID,info.Item,AmountFound,true) == true then
				info.Player.Consumed = AmountFound;
			end
		end
		if info.Requirements ~= nil then
			for _,requirement in ipairs(info.Requirements) do
				ExtractFromPlayer(requirement);
			end
		end
	end
	ExtractFromPlayer(Info);
	local _Request_;
	_Request_ = function(info,parentTable,consumeItem)
		--sb.logInfo("Requesting = " .. sb.print(info.Item.name));
		if info.Done == true then
			return true;
		end
		--local Total = 0;
		--[[if info.Found ~= nil then
			Total = Total + info.Found;
		end
		if info.Missing ~= nil then
			Total = Total + info.Missing;
		end
		if info.Craftable ~= nil then
			Total = Total + info.Craftable;
		end
		if info.Player ~= nil and info.Player.Found ~= nil then
			Total = Total + info.Player.Found;
		end--]]
		if info.Item.Count == 0 then
			info.Done = true;
			return true;
		end
		if Leftovers[info.Item] ~= nil then
			local Count = Leftovers[info.Item];
			Count = Count - 1;
			if Count == 0 then
				Count = nil;
			end
			if consumeItem == true then
				info.Item.count = info.Item.count - 1;
				Leftovers[info.Item] = Count;
			end
			return 1;
		end
		if info.Found ~= nil then
			if ConduitBasic.FindInNetwork(info.Item) > 0 then
				if consumeItem == true then
					if ConduitBasic.ConsumeFromNetwork(info.Item,1) ~= false then
						info.Found = info.Found - 1;
						info.Item.count = info.Item.count - 1;
						if info.Found == 0 then
							info.Found = nil;
						end
					end
				end
				return 1;
			else
				if info.Missing == nil then
					info.Missing = 0;
				end
				info.Missing = info.Missing + info.Found;
				--sb.logInfo("FAILED NETWORK");
				info.Found = nil;
			end
		end
		if info.Player ~= nil and info.Player.Found ~= nil then
			if info.Player.Consumed ~= nil then
				if consumeItem == true then
					info.Player.Consumed = info.Player.Consumed - 1;
					info.Player.Found = info.Player.Found - 1;
					info.Item.count = info.Item.count - 1;
					if info.Player.Consumed == 0 then
						info.Player.Consumed = nil;
					end
					if info.Player.Found == 0 then
						info.Player.Found = nil;
					end
				end
				return 1;
			end
			if ConduitBasic.FindOnPlayer(info.Player.ID,info.Item,true) > 0 then
				if consumeItem == true and ConduitBasic.ConsumeFromPlayer(info.Player.ID,info.Item,1,true) == true then
					info.Player.Found = Info.Player.Found - 1;
					info.Item.count = info.Item.count - 1;
					if info.Player.Found == 0 then
						info.Player.Found = nil;
					end
					--sb.logInfo("Found On Player 2 = " .. sb.print(info.Item.name));
					return 1;
				end
			else
				if info.Missing == nil then
					info.Missing = 0;
				end
				--sb.logInfo("FAILED PLAYER");
				info.Missing = info.Missing + info.Player.Found;
				info.Player.Found = nil;
			end
		end
		--FINISH WITH CRAFTING THE ITEM
		--sb.logInfo("Craftable = " .. sb.print(info.Craftable));
		if info.Requirements ~= nil and info.Craftable > 0 then
			local Craftable = false;
			--Check if crafters are still valid
			--sb.logInfo("Before Update = " .. sb.print(info.Crafters));
			info.Crafters = ConduitBasic.RefreshCrafter(info.Crafters);
			--sb.logInfo("After Update = " .. sb.print(info.Crafters));
			if not (info.Crafters == "Player" or jsize(info.Crafters) > 0) then
				if info.Missing == nil then
					info.Missing = 0;
				end
				--sb.logInfo("FAILED CRAFTER");
				info.Missing = info.Missing + info.Craftable;
				info.Craftable = 0;
				goto CraftExit;
			end
			for _,requirement in ipairs(info.Requirements) do
				local InputPerRecipe = requirement.AmountPerRecipe;
				local AmountCounter = 0;
				while(AmountCounter < InputPerRecipe) do
					local Request = _Request_(requirement.Data,requirement,false);
					if Request == 0 then
						if info.Missing == nil then
							info.Missing = 0;
						end
						info.Missing = info.Missing + info.Craftable;
						info.Craftable = 0;
						goto CraftExit;
						--return 0;
					else
						AmountCounter = AmountCounter + Request;
					end
				end
			end
			Craftable = true;
			if consumeItem == true then
				for _,requirement in ipairs(info.Requirements) do
					local InputPerRecipe = requirement.AmountPerRecipe;
					local AmountCounter = 0;
					while(AmountCounter < InputPerRecipe) do
						local Request = _Request_(requirement.Data,requirement,true);
						AmountCounter = AmountCounter + Request;
					end
					if AmountCounter > InputPerRecipe then
						local Count = Leftovers[requirement.Data.Item];
						if Count == nil then
							Count = AmountCounter - InputPerRecipe;
						else
							Count = Count + AmountCounter - InputPerRecipe;
						end
						if Leftovers[requirement.Data.Item] ~= nil then
							Leftovers[requirement.Data.Item] = Leftovers[requirement.Data.Item] + Count;
						else
							Leftovers[requirement.Data.Item] = Count;
						end
					end
				end
				local OldCraftableCount = info.Craftable;
				info.Craftable = info.Craftable - info.OutputPerRecipe;
				if info.Craftable < 0 then
					if Leftovers[info.Item] ~= nil then
						Leftovers[info.Item] = Leftovers[info.Item] - info.Craftable;
					else
						Leftovers[info.Item] = -info.Craftable;
					end
					info.Craftable = 0;
				end
				info.Item.count = info.Item.count - (OldCraftableCount - info.Craftable);
				--[[if info.Craftable == 0 then
					--info.Requirements = nil;
					info.Craftable = nil;
				end--]]
			end
			--sb.logInfo("Found On Craft = " .. sb.print(info.Item.name));
			return info.OutputPerRecipe;
		end
		::CraftExit::
		if info.Missing ~= nil then
			--sb.logInfo("Info = " .. sb.printJson(info,1));
			local PlayerID = nil;
			if info.Player ~= nil then
				PlayerID = info.Player.ID;
			end
			--coroutine.yield();
			--sb.logInfo("Test");
			local UpdatedSchedule = Controller.GetScheduleInfo({name = info.Item.name,count = info.Missing,parameters = info.Item.parameters},info.UseFound,PlayerID,true);
			--sb.logInfo("Missing1 = " .. sb.print(UpdatedSchedule.Missing));
			--sb.logInfo("Missing2 = " .. sb.print(info.Missing));
			if UpdatedSchedule.Missing == nil or UpdatedSchedule.Missing < info.Missing then
				if parentTable == nil then
					Schedules[ScheduleID] = UpdatedSchedule;
					Info = UpdatedSchedule;
				else
					parentTable.Data = UpdatedSchedule;
				end
				--sb.logInfo("Found On Reupdate = " .. sb.print(info.Item.name));
				return _Request_(UpdatedSchedule,parentTable,consumeItem);
			end

		end
		--sb.logInfo("Found None = " .. sb.print(info.Item.name));
		return 0;
	end
	--Requests some of the item
	--Returns the number of the item requested if successful
	--Returns true if done
	ScheduleController.Request = function()
		local Value = _Request_(Schedules[ScheduleID],nil,true);
		if Value == true then
			Schedules[ScheduleID] = nil;
		end
		ScheduleUpdate();
		return Value;
	end
	return ScheduleController;
end

ScheduleUpdate = function()

end

--Returns info about scheduling
function Controller.GetScheduleInfo(item,useFound,playerID,doAsync)
	if useFound == nil then
		useFound = false;
	end
	local Result = {Item = item};
	local AmountNeeded = item.count;
	if useFound == true then
		Result.UseFound = true;
		--sb.logInfo("Finding = " .. sb.print(item));
		local FoundAmount = ConduitBasic.FindInNetwork(item);
		--sb.logInfo("Found Amount = " .. sb.print(FoundAmount));
		if FoundAmount > AmountNeeded then
			FoundAmount = AmountNeeded;
		end
		if FoundAmount > 0 then
			Result.Found = FoundAmount;
			AmountNeeded = AmountNeeded - FoundAmount;
		end
		if playerID ~= nil then
			Result.UsePlayer = true;
			local PlayerFound = ConduitBasic.FindOnPlayer(playerID,item,doAsync);
			if PlayerFound > AmountNeeded then
				PlayerFound = AmountNeeded;
			end
			if PlayerFound > 0 then
				Result.Player = {
					Found = PlayerFound,
					ID = playerID
				}
				AmountNeeded = AmountNeeded - PlayerFound;
			end
		end
	end
	if AmountNeeded > 0 then
		local Recipes = ItemsToCraft[item];
		--sb.logInfo("Recipes = " .. sb.print(Recipes));
		local WorkingRecipes = {};
		local FailedRecipes = {};
		if Recipes ~= nil then
			for _,recipe in ipairs(Recipes) do
				local Requirements = {};
				local MinInputMultiplier = nil;
				--sb.logInfo("Crafter = " .. sb.print(recipe.Crafter));
				--sb.logInfo("Found Crafters = " .. sb.print(ConduitBasic.FindCrafter(recipe.Crafter)));
				--sb.logInfo("Crafter = " .. sb.print(recipe.Crafter));
				local FoundCrafters = ConduitBasic.FindCrafter(recipe.Crafter);
				--sb.logInfo("Found Crafters = " .. sb.print(FoundCrafters));
				local AmountMultiplier = math.ceil(AmountNeeded / recipe.output.count);
				local TotalToCraft = AmountMultiplier * recipe.output.count;
				for _,input in ipairs(recipe.input) do
					--sb.logInfo("input = " .. sb.print(input));
					local NewRequirement = Controller.GetScheduleInfo({name = input.name,count = input.count * AmountMultiplier,parameters = input.parameters},true);
					local TotalCount = NewRequirement.Found or 0;
					if NewRequirement.Craftable ~= nil then
						TotalCount = TotalCount + NewRequirement.Craftable;
					end
					if MinInputMultiplier == nil then
						MinInputMultiplier = TotalCount / input.count;
					elseif TotalCount / input.count < MinInputMultiplier then
						MinInputMultiplier = TotalCount / input.count;
					end
					Requirements[#Requirements + 1] = {
						AmountPerRecipe = input.count,
						Data = NewRequirement;	
					};
				end
				--sb.logInfo("MinInputMultiplier = " .. sb.print(MinInputMultiplier));
				--sb.logInfo("Amount Multiplier = " .. sb.print(AmountMultiplier));
				--sb.logInfo("FoundCrafters = " .. sb.print(FoundCrafters));
				--sb.logInfo("Size = " .. sb.print(jsize(FoundCrafters)));
				if MinInputMultiplier == AmountMultiplier and (FoundCrafters ~= nil and FoundCrafters == "Player" or jsize(FoundCrafters) > 0) then
					WorkingRecipes[#WorkingRecipes + 1] = {
						TotalCraftable = TotalToCraft,
						Requirements = Requirements,
						Craftable = MinInputMultiplier * recipe.output.count,
						OutputPerRecipe = recipe.output.count,
						Crafters = FoundCrafters
					};
				else
					local Craftable = MinInputMultiplier * recipe.output.count;
					if jsize(FoundCrafters) == 0 then
						Craftable = 0;
					end
					FailedRecipes[#FailedRecipes + 1] = {
						TotalCraftable = TotalToCraft,
						Requirements = Requirements,
						Craftable = Craftable,
						--Craftable = 0,
						OutputPerRecipe = recipe.output.count,
						Crafters = FoundCrafters
					};
				end
				--[[if MinInputMultiplier ~= AmountMultiplier or (FoundCrafters ~= "Player" or jsize(FoundCrafters) == 0) then
					FailedRecipes[#FailedRecipes + 1] = {
						TotalCraftable = TotalToCraft,
						Requirements = Requirements,
						Craftable = MinInputMultiplier * recipe.output.count,
						OutputPerRecipe = recipe.output.count,
						Crafters = {}
					};
				else
					WorkingRecipes[#WorkingRecipes + 1] = {
						TotalCraftable = TotalToCraft,
						Requirements = Requirements,
						Craftable = MinInputMultiplier * recipe.output.count,
						OutputPerRecipe = recipe.output.count,
						Crafters = FoundCrafters
					};
				end--]]
			end
		end
		if #WorkingRecipes > 0 then
			Result.Requirements = WorkingRecipes[1].Requirements;
			Result.Craftable = AmountNeeded;
			Result.Leftovers = WorkingRecipes[1].TotalCraftable - AmountNeeded;
			--Result.Recipe = WorkingRecipes[1].Recipe;
			Result.OutputPerRecipe = WorkingRecipes[1].OutputPerRecipe;
			Result.Crafters = WorkingRecipes[1].Crafters;
			AmountNeeded = 0;
			--sb.logInfo("Working");
		elseif #FailedRecipes > 0 then
			Result.Requirements = FailedRecipes[1].Requirements;
			Result.Craftable = FailedRecipes[1].Craftable;
			AmountNeeded = AmountNeeded - Result.Craftable;
			Result.OutputPerRecipe = FailedRecipes[1].OutputPerRecipe;
			Result.Crafters = FailedRecipes[1].Crafters;
			--sb.logInfo("Failed");
		end
	end
	if AmountNeeded > 0 then
		Result.Missing = AmountNeeded;
	end
	return Result;
end


--Returns the Controller Table for easier access
function Controller.GetTable()
	return Controller;
end

--Updates the list of crafting recipes
function Controller.UpdateCraftingList(itemList,NoReplace)
	if NoReplace ~= true then
		object.setConfigParameter("SlotItems",ToNumberTable(itemList));
	end
	ItemsToCraft = setmetatable({},ItemsToCraftMeta);
	for _,item in ipairs(itemList) do
		local Recipes = ItemsToCraft[item.parameters.blueprintItem];
		if Recipes == nil then
			ItemsToCraft[item.parameters.blueprintItem] = {item.parameters.Recipe};
		else
			Recipes[#Recipes + 1] = item.parameters.Recipe;
		end
	end
end


--Makes sure a table is in numerical format
function ToNumberTable(tbl)
	if jsize(tbl) ~= #tbl then
		local Table = {};
		for k,i in pairs(tbl) do
			Table[tonumber(k)] = i;
		end
		return Table;
	end
	return tbl;
end