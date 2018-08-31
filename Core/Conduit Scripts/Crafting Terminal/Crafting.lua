require("/Core/ConduitCore.lua");
require("/Core/ServerCore.lua");

--Declaration
Crafting = {};
local Crafting = Crafting;

--Variables
local Data = {};
local LearntItems = {};
local LearntCrafters = {};
local QueryUUIDS = {};
local Data = {};
local FoundCrafters = {};
local ConnectedClients = {};
local ClientSize = 0;
local CraftingList = {};
local CraftListChanges = {};
local CraftListBatch = {};
local CurrencyToItemTbl = {};
local ItemToCurrencyTbl = {};

--Functions
local PostInit;
local NetworkUpdate;
local RefreshLearntItems;
local SetMessages;
local CheckForItem;
local GetExactItem;
local FindCrafter;
local OldUpdate = update;
local DecrementClientPing;
local FreezeCraft;
local CraftItem;
local WaitFor;
local CurrencyToItem;

--Initializes the Crafting Terminal
function Crafting.Initialize()
	local Currencies = root.assetJson("/currencies.config");
	for currency,info in pairs(Currencies) do
		CurrencyToItemTbl[currency] = info.representativeItem;
		ItemToCurrencyTbl[info.representativeItem] = currency;
	end
	LearntItems = config.getParameter("LearntItems") or {};
	LearntCrafters = config.getParameter("LearntCrafters") or {};
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.AddPostInitFunction(PostInit);
	--Create a default entry in the changes list
	CraftListChanges[#CraftListChanges + 1] = {
		UUID = sb.makeUuid(),
		TimeStamp = os.clock();
	}
	SetMessages();
	Server.SetDefinitionTable(Data);
	Server.DefineSyncedValues("Items","LearntItems",LearntItems);
	Server.DefineSyncedValues("Crafters","LearntCrafters",LearntCrafters);
	Server.SaveValuesOnExit("Items",false);
	Server.SaveValuesOnExit("Crafters",false);
	ConduitCore.AddNetworkUpdateFunction(NetworkUpdate);
	ConduitCore.Initialize();
end

update = function(dt)
	if OldUpdate ~= nil then
		OldUpdate(dt);
	end
	--sb.logInfo("UPDATE");
	for uuid,client in pairs(ConnectedClients) do
		--sb.logInfo("CLIENT = " .. sb.print(client));
		if DecrementClientPing(uuid,dt) == true then
			RemoveClient(uuid);
		end
	end
end

SetMessages = function()
	message.setHandler("AddToLearntList",function(_,_,items)
		local ListUpdated = false;
		for _,item in ipairs(items) do
			if LearntItems[item.name] == nil then
				LearntItems[item.name] = {item};
				ListUpdated = true;
			else
				for i=1,#LearntItems[item.name] do
					if root.itemDescriptorsMatch(LearntItems[item.name],item,true) then
						goto Continue;
					end
				end
				LearntItems[item.name][#LearntItems[item.name] + 1] = item;
				ListUpdated = true;
				::Continue::
			end
		end
		if ListUpdated == true then
			RefreshLearntItems();
		end
	end);
	message.setHandler("CraftItem",function(_,_,item,useFound,recipe,playerID,noCraft)
		--sb.logInfo("RECIEVED PLAYER ID = " .. sb.print(playerID));
		return Crafting.CraftItem(item,useFound,recipe,playerID,noCraft);
	end);
	message.setHandler("CanCraftItem",function(item,useFound,recipe,playerID,noCraft)
		return Crafting.CanCraftItem(item,useFound,recipe,playerID,noCraft);
	end);
	message.setHandler("UpdateCraftList",function(_,_,uuid,clientUUID)
		--If the uuid equals nil then send the full list because this is a new client about to connect, and create a new client entry
		if uuid == nil then
			local Client = AddClient();
			SetClientUUID(Client,CraftListChanges[#CraftListChanges].UUID,CraftListChanges[#CraftListChanges].TimeStamp);
			return {CraftingList,CraftListChanges[#CraftListChanges].UUID,Client};
		else
			if uuid ~= CraftListChanges[#CraftListChanges].UUID then
				local Changes = {};
				local CurrentIndex = #CraftListChanges;
				--sb.logInfo("H");
				sb.logInfo("CurrentIndex = " .. sb.print(CurrentIndex));
				sb.logInfo("CraftListChanges = " .. sb.print(CraftListChanges));
				sb.logInfo("CraftListChanges INdexed = " .. sb.print(CraftListChanges[CurrentIndex]));
				while(CurrentIndex > 0 and CraftListChanges[CurrentIndex].UUID ~= uuid) do
					--Changes[#Changes + 1] = CraftListChanges[CurrentIndex];
					table.insert(Changes,1,CraftListChanges[CurrentIndex]);
					CurrentIndex = CurrentIndex - 1;
					sb.logInfo("CurrentIndex2 = " .. sb.print(CurrentIndex));
					sb.logInfo("CraftListChanges2 = " .. sb.print(CraftListChanges));
					sb.logInfo("CraftListChanges INdexed2 = " .. sb.print(CraftListChanges[CurrentIndex]));
					sb.logInfo("CurrentIndex Bool = " .. sb.print(CurrentIndex > 0));
					--sb.logInfo("CraftList Bool = " .. sb.print(CraftListChanges[CurrentIndex]))

					--sb.logInfo("CurrentIndex = " .. sb.print(CurrentIndex));
				end
				--sb.logInfo("G");
				SetClientUUID(clientUUID,CraftListChanges[#CraftListChanges].UUID,CraftListChanges[#CraftListChanges].TimeStamp);
				ResetClientPing(clientUUID);
				return {Changes,CraftListChanges[#CraftListChanges].UUID};
			else
				ResetClientPing(clientUUID);
				return false;
			end
		end
	end);
end

PostInit = function()
	--NetworkUpdate();
	--Crafting.CanCraftItem({name = "insertionconduit",count = 20});
	--[[Server.AddAsyncCoroutine(function()
		while(true) do
			NetworkUpdate(true);
			AddChange((CraftingList.Test or 0) + 1,"Test");
			--sb.logInfo("Test = " .. sb.print(CraftingList.Test));
		end
	end);--]]
	Server.AddAsyncCoroutine(function()
		while(true) do
			NetworkUpdate(true);
			--AddChange((CraftingList.Test or 0) + 1,"Test");
			--sb.logInfo("Test = " .. sb.print(CraftingList.Test));
		end
	end);
end

--Called when the network updates
NetworkUpdate = function()
	--Scan and update the Learnt Items List
	local Network = ConduitCore.GetNetwork("TerminalFindings");
	local ListUpdated = false;
	local LearntCraftersUpdated = false;
	FoundCrafters = {};
	for i=1,#Network do
		local ConduitType = world.getObjectParameter(Network[i],"conduitType");
		if ConduitType == "crafting" then
			local Filters = world.callScriptedEntity(Network[i],"GetCraftingFilters");
			for _,filter in ipairs(Filters) do
				FoundCrafters[#FoundCrafters + 1] = filter;
				for i=1,#LearntCrafters do
					if root.itemDescriptorsMatch(LearntCrafters[i],filter,true) then
						goto Continue;
					end
				end
				LearntCrafters[#LearntCrafters + 1] = filter;
				LearntCraftersUpdated = true;
				::Continue::
			end
		end
		local Contents;
		if ConduitType == "insertion" or ConduitType == "io" then
			Contents = world.callScriptedEntity(Network[i],"Insertion.QueryContainers",QueryUUIDS[Network[i]],true);
		elseif ConduitType == "extraction" then
			Contents = world.callScriptedEntity(Network[i],"Extraction.QueryContainers",QueryUUIDS[Network[i]],true);
		end
		if Contents ~= nil and Contents ~= false then
			QueryUUIDS[Network[i]] = Contents[2];
			Contents = Contents[1];
		end
		if Contents ~= nil and Contents ~= false then
			for stringContainer,containerContents in pairs(Contents) do
				--sb.logInfo("ContainerContents = " .. sb.print(containerContents));
				for _,item in ipairs(containerContents) do
					if item ~= nil and item ~= "" then
						if LearntItems[item.name] == nil then
							LearntItems[item.name] = {item};
							ListUpdated = true;
						else
							for i=1,#LearntItems[item.name] do
								--sb.logInfo("LearntItems = " .. sb.print(LearntItems[item.name][i]));
							--	sb.logInfo("Item = " .. sb.print(item));
								if root.itemDescriptorsMatch(LearntItems[item.name][i],item,true) then
									goto Continue;
								end
							end
							LearntItems[item.name][#LearntItems[item.name] + 1] = item;
							ListUpdated = true;
							::Continue::
						end
					end
				end
			end
			if Server.RunningCoroutine() ~= nil then
				--sb.logInfo("Yield");
				coroutine.yield();
			end
		end
	end
	--sb.logInfo("FOUND CRAFTERS = " .. sb.print(FoundCrafters));
	--sb.logInfo("Learnt List 2 = " .. sb.printJson(LearntItems,1));
	if ListUpdated == true then
		RefreshLearntItems();
	end
	if LearntCraftersUpdated == true then
		object.setConfigParameter("LearntCrafters",LearntCrafters);
		Data.SetLearntCrafters(LearntCrafters);
	end
	if Server.RunningCoroutine() ~= nil then
		--sb.logInfo("Yield 2");
		coroutine.yield();
	end
end

--Refreshes the Learnt Items list so it can be stored and retrieved by the UI
RefreshLearntItems = function()
	--sb.logInfo("Refreshed");
	object.setConfigParameter("LearntItems",LearntItems);
	Data.SetLearntItems(LearntItems);
end

--Will Attempt to craft the item, and will return info about why or why not
function Crafting.CraftItem(item,useFound,recipe,playerID,noCraft)
	sb.logInfo("CRAFTING");
	local Data = CheckForItem(item,useFound,recipe,playerID,noCraft);
	--if Data.Valid == true then
		sb.logInfo("CRAFTDATA = " .. sb.printJson(Data,1));
		--Data.ID = sb.makeUuid();
		local CraftID = sb.makeUuid();
		Data.FinalItem = item;
		sb.logInfo("VALID CRAFT");
		--sb.logInfo("Size of CraftingList = " .. sb.print(#CraftingList));
		--AddChangeOperation("Insert",{#CraftingList},Data);
		AddChange(Data,CraftID);
		local OnCancel = function()

		end
		Server.AddAsyncCoroutine(function()
			CraftItem(Data.FinalItem,Data,CraftID);
		end,OnCancel);
	--end
	return Data;
end

--Attempts to craft the item and returns the amount crafted
CraftItem = function(item,data,...)

	--if data.Valid == false then
--[[		sb.logInfo("Complete Data BEFORE = " .. sb.printJson(data,1));
		local TotalToGet = item.count;
		if data.FoundAmount ~= nil then
			if data.FoundOnPlayer ~= nil then
				AddChange(data.TotalNeeded - data.FoundOnPlayer,...,"TotalNeeded");
				--Take all the items out of the player
				world.sendEntityMessage(data.PlayerID,"ConsumeItem",{name = item.name,count = data.FoundOnPlayer,parameters = item.parameters},true,true);
				AddChange(0,...,"FoundOnPlayer");
			end
			AddChange(data.TotalNeeded - data.FoundAmount,...,"TotalNeeded");
			for stringConduit,conduitData in pairs(data.ConduitSources) do
				for stringContainer,amount in pairs(conduitData.Containers) do
					world.containerConsume(tonumber(stringContainer),{name = item.name,count = amount,parameters = item.parameters});
				end
			end
			AddChange(0,...,"FoundAmount");
			AddChange("__nil__",...,"ConduitSources");
			--Take All the Items out of the Conduits
		end
		if data.Craftable ~= nil then
			for _,info in ipairs(data.Recipe.Ingredients) do
				CraftItem(info.Item,info.Data,...,"Recipe","Ingredients","Data");
			end
		end
		sb.logInfo("Complete Data = " .. sb.printJson(data,1));--]]
	--end
end

--[[FullItemSearch = function(item,playerID,dontConsume)
	local TotalToFind = item.count;
	local Found = {};
	local Network = Data.GetConduitNetwork();
	for i=1,#Network do
		if world.entityExists(Network[i]) then
			local Type = world.getObjectParameter(Network[i],"conduitType");
			if Type == "extraction" or Type == "io" then
				local Findings = world.callScriptedEntity(Network[i],"Extraction.FindItemInContainers",item);
				if Findings.Total >= TotalToFind then
					--Extract out of Findings and Found Table and return true
					for stringContainer,Amount in pairs(Findings.Containers) do
						if Amount >= TotalToFind then
							if dontConsume ~= true then
								world.containerConsume(tonumber(stringContainer),{name = item.name,count = TotalToFind,parameters = item.parameters});
							end
							TotalToFind = 0;
							break;
						else
							if dontConsume ~= true then
								world.containerConsume(tonumber(stringContainer),{name = item.name,count = Amount,parameters = item.parameters});
							end
							TotalToFind = TotalToFind - Amount;
						end
					end
					for _,found in ipairs(Found) do
						for stringContainer,Amount in pairs(found.Containers) do
							if dontConsume ~= true then
								if Amount >= TotalToFind then
									world.containerConsume(tonumber(stringContainer),{name = item.name,count = TotalToFind,parameters = item.parameters});
								else
									world.containerConsume(tonumber(stringContainer),{name = item.name,count = Amount,parameters = item.parameters});
								end
							end
						end
					end
				else
					--Subtract from TotalToFind and Add to Found List
					Found[#Found + 1] = {
						Conduit = Network[i],
						Containers = Findings.Containers;
					}
					TotalToFind = TotalToFind - Findings.Total;
				end
			end
		end
	end
	if playerID ~= nil then
		local Count = world.entityHasCountOfItem(playerID,{name = item.name,count = 1,parameters = item.parameters},true);
		if Count >= TotalToFind then
			TotalToFind = 0;
			for _,found in ipairs(Found) do
				for stringContainer,Amount in pairs(found.Containers) do
					if dontConsume ~= true then
						if Amount >= TotalToFind then
							world.containerConsume(tonumber(stringContainer),{name = item.name,count = TotalToFind,parameters = item.parameters});
						else
							world.containerConsume(tonumber(stringContainer),{name = item.name,count = Amount,parameters = item.parameters});
						end
					end
				end
			end
		else
			TotalToFind = TotalToFind - Count;
		end
	end
	if TotalToFind == 0 then
		return true;
	else
		return false;
	end
	--If TotalToFind is not zero then try to scan and pull any items out of the player
	--If still not satisfied then return false
end--]]

--Check if the item is craftable, and returns a table of some information as to why or why not
function Crafting.CanCraftItem(item,useFound,recipe,playerID,noCraft)
	--Check if all the required recipe items are avaiable
	--sb.logInfo("Test");
	local Check = CheckForItem(item,useFound,recipe,playerID,noCraft);
	--if Check ~= nil then
		--sb.logInfo("Check = " .. sb.printJson(Check,1));
	--end
	return Check.Valid;
end

function Crafting.GetCraftInfo(item,useFound,recipe,playerID,noCraft)
	return CheckForItem(item,useFound,recipe,playerID,noCraft);
end

function FindAmountInNetwork(item)
	local Amount = 0;
	local Network = ConduitCore.GetConduitNetwork();
	for i=1,#Network do
		local Type = world.getObjectParameter(Network[i],"conduitType");
		if Type == "extraction" or Type == "io" then
			--sb.logInfo("Found Extraction = " .. sb.print(Network[i]));
			local Findings = world.callScriptedEntity(Network[i],"Extraction.FindItemInContainers",item);
			if Findings ~= nil then
				Amount = Amount + Findings.Total;
			end
		end
	end
	return Amount;
end

function ConsumeOutOfNetwork(item,AmountToTake)
	AmountToTake = AmountToTake or item.count;
	local Network = ConduitCore.GetConduitNetwork();
	for i=1,#Network do
		local Type = world.getObjectParameter(Network[i],"conduitType");
		if Type == "extraction" or Type == "io" then
			--sb.logInfo("Found Extraction = " .. sb.print(Network[i]));
			local Findings = world.callScriptedEntity(Network[i],"Extraction.FindItemInContainers",item);
			if Findings ~= nil then
				for stringContainer,amount in pairs(Findings.Containers) do
					if amount >= AmountToTake then
						world.containerConsume(tonumber(stringContainer),{name = item.name,count = AmountToTake,parameters = item.parameters});
						AmountToTake = 0;
						return true;
					else
						world.containerConsume(tonumber(stringContainer),{name = item.name,count = amount,parameters = item.parameters});
						AmountToTake = AmountToTake - amount;
					end
				end
			end
		end
	end
	return false;
end

function FindOnPlayer(playerID,item)
	local Count = world.entityHasCountOfItem(playerID,{name = item.name,count = 1,parameters = item.parameters},true) or 0;
	if ItemToCurrencyTbl[item.name] ~= nil then
		Count = Count + world.entityCurrency(playerID,ItemToCurrencyTbl[item.name]);
	end
	return Count;
end

function ConsumeFromPlayer(playerID,item,count)
	count = count or item.count;
	if ItemToCurrencyTbl[item.name] ~= nil then
		world.sendEntityMessage(playerID,"ConsumeCurrency",ItemToCurrencyTbl[item.name],count);
	else
		world.sendEntityMessage(playerID,"ConsumeItem",{name = item.name,count = count,parameters = item.parameters},false,true);
	end
end

--Table Layout
--[[
{
	Needed = {
		Amount,
		Multiplier
	}
	Ingredients = [
		--Recursive--
	],
	Output
}
]]
--[[function CheckForCraftability(item,optionalRecipe,playerID)
	local Recipes;
	if optionalRecipe ~= nil then
		Recipes = {optionalRecipe};
	else
		Recipes = root.recipesForItem(item.name);
	end
	if #Recipes == nil then
		return nil;
	end
	local Final = {
		Valid = true
	};
	local ValidRecipes = {};
	for _,recipe in ipairs(Recipes) do
		local NewRecipe = {
			Ingredients = {}
		};
		for _,ingredient in ipairs(recipe.input) do
			local IngredientResult = CheckForItem(ingredient,true,nil,playerID,ItemToCurrencyTbl[ingredient.name] ~= nil);
			if IngredientResult.Valid == false then
				goto Continue;
			end
			NewRecipe.Ingredients[#NewRecipe.Ingredients + 1] = IngredientResult;
		end

		::Continue::
	end
end--]]

--Table Layout
--[[
{
	Item,
	Valid,
	Error,
	TotalFound,
	Player = {
		Found,
		ID
	},
	Network = {
		Found
	}
	Craft = {
		Needed = {
			Amount,
			Leftovers,
			Multiplier
		}
		Ingredients = [
			--Recursive--
		],
		Output
	}

}--]]
CheckForItem = function(item,useFound,usedRecipe,playerID,noCraft)
	local Final = {
		Item = item,
		Valid = true,
		Error = nil
	}
	local LeftToFind = item.count;
	if useFound == nil then
		useFound = true;
	end
	if useFound == true then
		if playerID ~= nil then
			Final.Player = {
				Found = FindOnPlayer(playerID,item),
				ID = playerID;
			}
			if Final.Player.Found > LeftToFind then
				Final.Player.Found = LeftToFind;
				LeftToFind = 0;
			else
				LeftToFind = LeftToFind - Final.Player.Found;
			end
		end
		if LeftToFind ~= 0 then
			Final.Network = {
				Found = FindAmountInNetwork(item);
			}
			if Final.Network.Found > LeftToFind then
				Final.Network.Found = LeftToFind;
				LeftToFind = 0;
			else
				LeftToFind = LeftToFind - Final.Network.Found;
			end
		end
	end
	if LeftToFind == 0 then
		sb.logInfo("AAA");
		return Final;
	end
	if noCraft == nil then
		noCraft = false;
	end

	if noCraft == false then
		local Recipes;
		if usedRecipe ~= nil then
			Recipes = {usedRecipe};
		else
			Recipes = root.recipesForItem(item.name);
		end
		if #Recipes == 0 then
			Final.Valid = false;
			Final.Error = "Didn't find enough of " .. item.name;
			return Final;
		end
		local ValidRecipes = {};
		local RecipeErrors = {};
		for _,recipe in ipairs(Recipes) do
			local NewRecipe = {
				Ingredients = {},
				Needed = {},
				Output = recipe.output
			};
			local Multiplier = math.ceil(LeftToFind / recipe.output.count);
			local AmountToCraft = Multiplier * recipe.output.count;
			local Leftovers = AmountToCraft - LeftToFind;
			NewRecipe.Needed.Amount = AmountToCraft;
			NewRecipe.Needed.Leftovers = Leftovers;
			NewRecipe.Needed.Multiplier = Multiplier;
			for _,ingredient in ipairs(recipe.input) do
				local IngData = CheckForItem({name = ingredient.name,count = ingredient.count * Multiplier,parameters = ingredient.parameters},true,nil,playerID,false);
				if IngData.Valid == false then
					local Error = IngData.Error;
					if type(Error) == "table" then
						for _,error in ipairs(Error) do
							RecipeErrors[#RecipeErrors + 1] = error;
						end
					else
						RecipeErrors[#RecipeErrors + 1] = IngData.Error;
					end
					goto Continue;
				end
				NewRecipe.Ingredients[#NewRecipe.Ingredients + 1] = {
					Item = ingredient,
					Data = IngData
				}
			end
			ValidRecipes[#ValidRecipes + 1] = NewRecipe;
			::Continue::
		end
		if #ValidRecipes == 0 then
			Final.Valid = false;
			if #RecipeErrors == 0 then
				Final.Error = "No Valid Recipes for " .. item.name;
			else
				Final.Error = RecipeErrors;
			end
			sb.logInfo("EEE");
			return Final;
		else
			sb.logInfo("DDD");
			Final.Craft = ValidRecipes[1];
			return Final;
		end
	else
		Final.Valid = false;
		Final.Error = "Didn't find enough of " .. item.name .. " , ";
		sb.logInfo("BBB");
		return Final;
	end
	sb.logInfo("CCC");
	--[[if useFound == nil then
		useFound = true;
	end
	if noCraft == nil then
		noCraft = false;
	end
	sb.logInfo("Checking = " .. sb.print(item));
	local Result = {
		Valid = true,
	};
	local Network = ConduitCore.GetConduitNetwork();
	--The Amount of the item left to find, whether it is found in inventories, or via crafting, or both
	local CountRemaining = item.count;
	local RunningTotalMode = false;
	--If the item count is negative, then switch to a mode where it finds out how much of the item is possible to retrieve
	if CountRemaining < 0 or totalMode == true then
		RunningTotalMode = true;
		CountRemaining = 0;
	else
		Result.TotalNeeded = item.count;
	end
	--Result.EntireTotal = CountRemaining;
	if useFound == true then
		Result.TryingToFind = true;
		Result.ConduitSources = {};
		--Attempt to find as much of the item as you can in any inventories in the network or on the player
		--Result.FoundAmount = CountRemaining;
		local FoundAmount = 0;
		--Loop Through the network and find all of the item in it
		for i=1,#Network do
			local Type = world.getObjectParameter(Network[i],"conduitType");
			if Type == "extraction" or Type == "io" then
				sb.logInfo("Found Extraction = " .. sb.print(Network[i]));
				local Findings = world.callScriptedEntity(Network[i],"Extraction.FindItemInContainers",item);
				if Findings ~= nil then
					FoundAmount = FoundAmount + Findings.Total;
					Result.ConduitSources[tostring(Network[i])] = Findings;
				end
			end
		end
		sb.logInfo("PlayerID = " .. sb.print(playerID));
		--Find as much of the item on the player as you can
		if playerID ~= nil then
			local FoundOnPlayer = 0;
			--sb.logInfo("PLAYER TEST");
			local Count = world.entityHasCountOfItem(playerID,{name = item.name,count = 1,parameters = item.parameters},true);
			if item.currencyName ~= nil then
				Count = Count + world.entityCurrency(playerID,item.currencyName);
			end
			sb.logInfo("Count = " .. sb.print(Count));
			FoundOnPlayer = Count;
			FoundAmount = FoundAmount + FoundOnPlayer;
			Result.FoundOnPlayer = FoundOnPlayer;
			Result.PlayerID = playerID;
		end
		Result.FoundAmount = FoundAmount;
		Result.TotalAmount = FoundAmount;
		--If we are in running total mode, then continue to find out how much is craftable, even if there's more than enough found
		--If the noCraft flag is true, then just return
		if RunningTotalMode == true then
			CountRemaining = CountRemaining + FoundAmount;
			if noCraft == true then
				return Result;
			end
		else
			if FoundAmount >= CountRemaining then
				Result.FoundEnough = true;
				sb.logInfo("RC  Good -- Found enough items in the network to make it = " .. sb.print(item.name));
				return Result;
			else
				--Didn't find enough of the item to make it, but will now try to find out how much of the item can be crafted
				--But if noCraft is true, then it's not valid and return
				Result.FoundEnough = false;
				CountRemaining = CountRemaining - FoundAmount;
				if noCraft == true then
					Result.Valid = false;
					return Result;
				end
			end
		end
	else
		Result.TotalAmount = 0;
	end
	--First, find if there's any recipes for the item available, or use the recipe passed into the function
	local Recipes;
	if usedRecipe ~= nil then
		Recipes = {usedRecipe};
	else
		Recipes = root.recipesForItem(item.name);
	end
	sb.logInfo("RECIPES FOR " .. sb.print(item.name) .. " = " .. sb.printJson(Recipes,1));

	--If there are any valid recipes to use, the try to find out how much of the item can be crafted
	if #Recipes > 0 then
		--Since there are recipes available, find out which recipes will work and what recipes won't work
		Result.Craftable = true;
		--Result.CraftingAmount = CountRemaining;
		--Result.CraftItems = {};


		local WorkingRecipes = {};
		local FailedRecipes = {};
		for _,recipe in ipairs(Recipes) do
			local Recipe = {
				Crafter = nil,
				Valid = true
			};
			local Failed = false;
			--Find Crafter
			sb.logInfo("Groups = " .. sb.print(recipe.groups));
			Recipe.CraftingGroups = recipe.groups;

			--First, find out where the item is crafted at, if it can't find out where it's crafted, then the recipe is a failure and move to the next recipe
			local Crafter = FindCrafter(recipe.groups);
			if Crafter ~= nil then
				Recipe.Crafter = Crafter;
			else
				
				Failed = true;
				Recipe.Crafter = "Unknown";
				Recipe.Valid = false;
				sb.logInfo("Failed1 -- This Recipe's Crafter is Unknown for " .. sb.print(item.name));
				FailedRecipes[#FailedRecipes + 1] = Recipe;
			end
			--First, find out the maximum amount of the ingredients is available in the system
			local Ingredients = {};
			local OutputMultiplier;
			if RunningTotalMode == false then
				OutputMultiplier = math.ceil(item.count / recipe.output.count);
			end
			for _,ingredient in ipairs(recipe.input) do
				local IngredientCount = -1;
				if RunningTotalMode == false then
					IngredientCount = ingredient.count * OutputMultiplier;
				end
				local IngredientResult = CheckForItem({name = ingredient.name,count = IngredientCount,parameters = ingredient.parameters},nil,nil,playerID);
				sb.logInfo("IngredientResult for " .. sb.print(ingredient.name) .. " = " .. sb.printJson(IngredientResult,1));
				Ingredients[#Ingredients + 1] = {
					Item = ingredient,
					Total = IngredientResult.TotalAmount,
					Data = IngredientResult,
					AmountPerRecipe = ingredient.count
				}
			end
			for currency,count in pairs(recipe.currencyInputs) do
				sb.logInfo("________________currency = " .. sb.print(currency));
				local Item = CurrencyToItem(currency,count);
				Item.currencyName = currency;
				local IngredientResult = CheckForItem(Item,nil,nil,playerID,true);
				sb.logInfo("________________After");
				sb.logInfo("IngredientResult for 2 " .. sb.print(Item.name) .. " = " .. sb.printJson(IngredientResult,1));
				Ingredients[#Ingredients + 1] = {
					Item = Item,
					Total = IngredientResult.TotalAmount,
					Data = IngredientResult,
					AmountPerRecipe = count,
					Currency = currency
				}
			end
			Recipe.Ingredients = Ingredients;

			--Next, find the maximum recipe multipler
			local RecipeMultiplier;
			for _,ingredient in ipairs(Ingredients) do
				if RecipeMultiplier == nil then
					RecipeMultiplier = math.ceil(ingredient.Total / ingredient.Item.count);
				else
					local Multiplier = math.ceil(ingredient.Total / ingredient.Item.count);
					if Multiplier < RecipeMultiplier then
						RecipeMultiplier = Multiplier;
					end
				end
			end
			if RecipeMultiplier == nil then
				RecipeMultiplier = 0;
			end

			for _,ingredient in ipairs(Ingredients) do
				ingredient.TotalCraftable = ingredient.Item.count * RecipeMultiplier;
				if RunningTotalMode == false then
					ingredient.TotalNeeded = ingredient.AmountPerRecipe * OutputMultiplier;
				end
			end

			--If the multiplier is zero, then the recipe is invalid bacause there isn't enough of one or more of the ingredients in the network to even make the item
			if RecipeMultiplier == 0 then
				Failed = true;
				Recipe.Valid = false;
				Recipe.Multiplier = 0;
				Recipe.TotalOutput = 0;
				sb.logInfo("Failed2 -- There isn't enough of the ingredients to craft the item = " .. sb.print(item.name));
				FailedRecipes[#FailedRecipes + 1] = Recipe;
			else
				Recipe.Multiplier = RecipeMultiplier;
				Recipe.TotalOutput = recipe.output.count * RecipeMultiplier;
			end
			if Failed == false then
				WorkingRecipes[#WorkingRecipes + 1] = Recipe;
			end
			::NextRecipe::
		end

		--If there are working recipes, then find the one that give the most output
		--If there are no working recipes, then there is nothing that can be crafted here
		--Result.FailedRecipes = FailedRecipes;
		if #WorkingRecipes > 0 then
			local SelectedRecipe;
			for _,recipe in ipairs(WorkingRecipes) do
				if SelectedRecipe == nil then
					SelectedRecipe = recipe;
				else
					if recipe.TotalOutput > SelectedRecipe.TotalOutput then
						SelectedRecipe = recipe;
					end
				end
			end
			Result.Craftable = true;
			Result.CraftableOutput = SelectedRecipe.TotalOutput;
			sb.logInfo("CraftableOutput = " .. sb.print(Result.CraftableOutput));
			Result.TotalAmount = Result.TotalAmount + Result.CraftableOutput;
			Result.Recipe = SelectedRecipe;
		else	
			local SelectedRecipe;
			for _,recipe in ipairs(FailedRecipes) do
				if SelectedRecipe == nil then
					SelectedRecipe = recipe;
				else
					if recipe.TotalOutput > SelectedRecipe.TotalOutput then
						SelectedRecipe = recipe;
					end
				end
			end
			Result.Craftable = false;
			if SelectedRecipe ~= nil then
				Result.Recipe = SelectedRecipe;
			end
		end

		--If this is in running total mode, then just return
			if RunningTotalMode == true then
				return Result;
			else
				if Result.Craftable == true then
					--If this recipe is able to craft enough, then the Result is valid, and return
					if Result.CraftableOutput >= CountRemaining then
						Result.CraftedEnough = true;
						sb.logInfo("RD  Good -- This Result has enough to craft to fulfill the amount of " .. sb.print(item.name));
						return Result;
					else
						Result.CraftedEnough = false;
						Result.Valid = false;
						sb.logInfo("RE  Bad -- There isn't enough of the item to craft to fulfill the amount of " .. sb.print(item.name));
						return Result;
					end
				else
					sb.logInfo("RF  Bad -- There is nothing craftable of " .. sb.print(item.name));
					Result.Valid = false;
					return Result;
				end
			end
	else
		--
		if RunningTotalMode == true then
			return Result;
		end
		sb.logInfo("RB  Bad -- There are no recipes for this item at all for use for " .. sb.print(item.name));
		Result.Valid = false;
		return Result;
	end--]]
end

GetExactItem = function(id)
	local StageData = world.callScriptedEntity(id,"currentStateData");
	if StageData ~= nil then
		return {name = world.entityName(id),count = 1,parameters = StageData.itemSpawnParameters};
	else
		return {name = world.entityName(id),count = 1};
	end
end

FindCrafter = function(groups)
	for _,group in ipairs(groups) do
		for _,crafter in ipairs(FoundCrafters) do
			for _,filter in ipairs(crafter.CraftingFilters) do
				if filter == group then
					return crafter;
				end
			end
		end
	end
end

AddClient = function()
	local Client = {
		PingMax = 5,
		Ping = 5,
	}
	--sb.logInfo("ADDING CLIENT");
	local UUID = sb.makeUuid();
	ConnectedClients[UUID] = Client;
	ClientSize = ClientSize + 1;
	return UUID;
end

SetClientUUID = function(clientUUID,uuid,timeStamp)
	local Client = ConnectedClients[clientUUID];
	if Client ~= nil then
		Client.ChangesUUID = uuid;
		Client.ChangesTimeStamp = timeStamp;
	end
	--TODO -- Remove any changes from the list that are older
	UpdateChangesList();
end

ResetClientPing = function(clientUUID)
--	sb.logInfo("clientUUID = " .. sb.print(clientUUID));
	--sb.logInfo("COnnectedClients = " .. sb.print(ConnectedClients));
	local Client = ConnectedClients[clientUUID];
	if Client ~= nil then
		--sb.logInfo("Refreshing Client");
		Client.Ping = Client.PingMax;
	end
end

--Decreases the Client's ping, returns true if equal to or less than zero and false otherwise
DecrementClientPing = function(clientUUID,dt)
	local Client = ConnectedClients[clientUUID];
	if Client ~= nil then
		Client.Ping = Client.Ping - dt;
		--sb.logInfo("Decremented To = " .. sb.print(Client.Ping));
		return Client.Ping <= 0;
	end
end

RemoveClient = function(clientUUID)
	local Client = ConnectedClients[clientUUID];
	if Client ~= nil then
		--sb.logInfo("Removing Client");
		ConnectedClients[clientUUID] = nil;
		--sb.logInfo("REMOVING CLIENT");
		ClientSize = ClientSize - 1;
		UpdateChangesList();
	end
end

UpdateChangesList = function()
	local LatestUUID;
	local LatestTimeStamp;
	for _,client in pairs(ConnectedClients) do
		if LatestTimeStamp == nil or client.ChangesTimeStamp > LatestTimeStamp then
			LatestTimeStamp = client.ChangesTimeStamp;
			LatestUUID = client.ChangesUUID;
		end
	end
	if LatestUUID == nil then
		CraftListChanges = {};
		CraftListChanges[#CraftListChanges + 1] = {
			UUID = sb.makeUuid(),
			TimeStamp = os.clock();
		}
	else
		for i=#CraftListChanges,1,-1 do
			if CraftListChanges[i].TimeStamp < LatestTimeStamp then
				table.remove(CraftListChanges,i);
			end
		end
	end
end

--Adds a single change the list changes list
AddChange = function(newValue,...)
	local List = {...};
	CraftListChanges[#CraftListChanges + 1] = {
		UUID = sb.makeUuid(),
		TimeStamp = os.clock(),
		NewValue = newValue,
		PathToValue = List;
	}
	local TopTable = CraftingList;
	for i=1,#List - 1 do
		if TopTable[List[i]] == nil then
			TopTable[List[i]] = {};
		end
		local Value = TopTable[List[i]];
		if Value == "__nil__" then
			Value = nil;
		end
		TopTable = Value;
	end
	sb.logInfo("------------Added Change = " .. sb.print(CraftListChanges[#CraftListChanges]));
	TopTable[List[#List]] = newValue;
end

--Can be called multiple times to add multiple changes at once. they can added all at once when AddChangeFlush() is called
AddChangeBatch = function(newValue,...)
	local List = {...};
	CraftListBatch[#CraftListBatch + 1] = {
		UUID = sb.makeUuid(),
		TimeStamp = os.clock(),
		NewValue = newValue,
		PathToValue = List;
	}
end

--Does an operation on the table that is synced
--It does the operation on the table specified by the path and uses both the parameters and the value on the operation
--Operations include:
--Insert: Params = {index}: Value = ValueToInsert
--Remove: Params = {}: Value = IndexToRemove
AddChangeOperation = function(operation,operationParamTable,value,...)
	local List = {...};
	local NewChange = {
		UUID = sb.makeUuid(),
		TimeStamp = os.clock(),
		NewValue = newValue,
		PathToValue = List,
		Operation = operation,
		OperationParameters = operationParamTable
	}
	CraftListChanges[#CraftListChanges + 1] = NewChange;
	local TopTable = CraftingList;
	for i=1,#List do
		if TopTable[List[i]] == nil then
			TopTable[List[i]] = {};
		end
		TopTable = TopTable[List[i]];
	end
	if NewChange.Operation == "Insert" then
		table.insert(TopTable,operationParamTable[1],value);
	elseif NewChange.Operation == "Remove" then
		table.remove(TopTable,value);
	end
end

--Adds all the batches changes to the list
AddChangeFlush = function()
	for _,batch in ipairs(CraftListBatch) do
		CraftListChanges[#CraftListChanges + 1] = batch;
		local TopTable = CraftingList;
		for i=1,#batch.PathToValue - 1 do
			if TopTable[batch.PathToValue[i]] == nil then
				TopTable[batch.PathToValue[i]] = {};
			end
			TopTable = TopTable[batch.PathToValue[i]];
		end
		local Value = batch.NewValue;
		if Value == "__nil__" then
			Value = nil;
		end
		TopTable[batch.PathToValue[#batch.PathToValue]] = Value;
	end
end

FreezeCraft = function()
	coroutine.yield();
end

WaitFor = function(Promise)
	while(not Promise:finished()) do
		coroutine.yield();
	end
	return Promise:result();
end

CurrencyToItem = function(name,count)
	return {name = CurrencyList[name].representativeItem,count = count};
end