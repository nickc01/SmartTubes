--This file provides functions for easier use of ConduitCore
if ConduitBasic ~= nil then return nil end;
--Declaration
require("/Core/ConduitCore.lua");
require("/Core/Async.lua");

ConduitBasic = {};
local ConduitBasic = ConduitBasic;

--Variables
local Currencies;
local IToCInternal;
local CToIInternal;
ConduitBasic.ItemToCurrency = setmetatable({},{
	__index = function(tbl,k)
		if Currencies == nil then
			Currencies = root.assetJson("/currencies.config");
			IToCInternal = {};
			CToIInternal = {};
			for currencyName,data in pairs(Currencies) do
				IToCInternal[data.representativeItem] = currencyName;
				CToIInternal[currencyName] = data.representativeItem;
			end
		end
		return IToCInternal[k];
	end});
ConduitBasic.CurrencyToItem = setmetatable({},{
	__index = function(tbl,k)
		if Currencies == nil then
			Currencies = root.assetJson("/currencies.config");
			IToCInternal = {};
			CToIInternal = {};
			for currencyName,data in pairs(Currencies) do
				IToCInternal[data.representativeItem] = currencyName;
				CToIInternal[currencyName] = data.representativeItem;
			end
		end
		return CToIInternal[k];
	end});

--Functions
local ConsumeFromPlayerAsync;
local FindOnPlayerAsync;
local WaitFor;
local DeepEqual;


--Reports how much of the item is extractable from the network
function ConduitBasic.FindInNetwork(item)
	local Amount = 0;
	local Network = ConduitCore.GetConduitNetwork();
	for i=1,#Network do
		local Type = world.getObjectParameter(Network[i],"conduitType");
		--sb.logInfo("Type = " .. sb.print(Type));
		if Type == "extraction" or Type == "io" then
			local Findings = world.callScriptedEntity(Network[i],"Extraction.FindItemInContainers",item);
			if Findings ~= nil then
				Amount = Amount + Findings.Total;
			end
		end
	end
	return Amount;
end

--Attempts to consume the amount of the item from the network
--Returns how much of the item has been consumed
function ConduitBasic.ConsumeFromNetwork(item,AmountToTake)
	AmountToTake = AmountToTake or item.count;
	local Total = AmountToTake;
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
						return Total;
					else
						world.containerConsume(tonumber(stringContainer),{name = item.name,count = amount,parameters = item.parameters});
						AmountToTake = AmountToTake - amount;
					end
				end
			end
		end
	end
	return Total - AmountToTake;
end

--Returns how much of the item is on the player
--Using the Async version provides more accuracy
function ConduitBasic.FindOnPlayer(playerID,item,doAsync)
	if doAsync == true then
		return FindOnPlayerAsync(playerID,item);
	end
	local Count = world.entityHasCountOfItem(playerID,{name = item.name,count = 1,parameters = item.parameters},true) or 0;
	if ItemToCurrency[item.name] ~= nil then
		Count = Count + world.entityCurrency(playerID,ItemToCurrency[item.name]);
	end
	return Count;
end

--Attempts to extract the amount from the player
--Returns true if successful, or false otherwise
function ConduitBasic.ConsumeFromPlayer(playerID,item,count,doAsync)
	if doAsync == true then
		return ConsumeFromPlayerAsync(playerID,item,count);
	end
	count = count or item.count;
	if ConduitBasic.FindOnPlayer(playerID,item,doAsync) < count then
		return false;
	end
	if ItemToCurrency[item.name] ~= nil then
		world.sendEntityMessage(playerID,"ConsumeCurrency",ItemToCurrency[item.name],count);
	else
		world.sendEntityMessage(playerID,"ConsumeItem",{name = item.name,count = count,parameters = item.parameters},false,true);
	end
	return true;
end

FindOnPlayerAsync = function(playerID,item)
	local Promise;
	if ItemToCurrency[item.name] ~= nil then
		Promise = world.sendEntityMessage(playerID,"AmountOfCurrency",ItemToCurrency[item.name]);
	else
		Promise = world.sendEntityMessage(playerID,"AmountOfItem",{name = item.name,count = 1,parameters = item.parameters});
	end
	return WaitFor(Promise);
end

ConsumeFromPlayerAsync = function(playerID,item,count)
	count = count or item.count;
	local Promise;
	if ItemToCurrency[item.name] ~= nil then
		Promise = world.sendEntityMessage(playerID,"ConsumeCurrency",ItemToCurrency[item.name],count);
	else
		Promise = world.sendEntityMessage(playerID,"ConsumeItem",{name = item.name,count = count,parameters = item.parameters},false,true);
	end
	local Value = WaitFor(Promise);
	if type(Value) == "boolean" then
		return Value;
	else
		return Value ~= nil;
	end
end

--Waits for a Promise to finish
WaitFor = function(Promise)
	while(not Promise:finished()) do
		coroutine.yield();
	end
	return Promise:result();
end

--Finds the current upgrade state of the object, as well as the State's Data, nor nil if the object isn't upgradable
function ConduitBasic.GetCurrentCrafterState(ObjectID)
	local UpgradeStates = world.getObjectParameter(ObjectID,"upgradeStages");
	if UpgradeStates == nil then
		return nil;
	end
	local CurrentStateData = world.callScriptedEntity(connection,"currentStageData");
	for state,stateData in ipairs(UpgradeStates) do
		if DeepEqual(stateData.itemSpawnParameters,CurrentStateData.itemSpawnParameters) == true then
			return state,CurrentStateData;
		end
	end
	return nil;
end

--Finds the crafter in the system and returns both the ID of the crafters and the ID of the conduits it's connected to
function ConduitBasic.FindCrafter(item)
	if item == "Unknown" then
		--sb.logInfo("R1");
		return {};
	elseif item == "Player" then
		--sb.logInfo("R2");
		return item;
	end
	local Network = ConduitCore.GetConduitNetwork();
	local Objects = {};
	local ObjectAdder = setmetatable({},{
		__index = function(tbl,ID)
			return Object[ID];
		end,
		__newindex = function(tbl,ID,Connection)
			if Objects[ID] == nil then
				Objects[ID] = {Connection};
			else
				for _,connection in ipairs(Objects[ID]) do
					if connection == Connection then
						return nil;
					end
				end
				Objects[ID][#Objects[ID] + 1] = Connection;
			end
		end});
	--sb.logInfo("Network = " .. sb.printJson(Network,1));
	for _,conduit in ipairs(Network) do
		local Type = world.getObjectParameter(conduit,"conduitType");
		if Type == "crafting" then
			--sb.logInfo("Found Crafting Conduit = " .. sb.print(conduit));
			local Connections = world.callScriptedEntity(conduit,"ConduitCore.GetConnections","Crafting");
			if Connections ~= false and ConduitBasic.GenerateBiPath(conduit,entity.id()) ~= nil then
				for _,connection in ipairs(Connections) do
				--	sb.logInfo("CONNECTION = " .. sb.print(connection));
					--sb.logInfo("ConnectionName = " .. sb.print(world.entityName(connection)));
					if connection ~= 0 then
						if world.entityName(connection) == item.name then
							--[[local UpgradeData = world.callScriptedEntity(connection,"currentStageData");
							if UpgradeData ~= nil then
								--TODO -- TODO -- TODO -- TODO -- TODO -- TODO
							end--]]
							--if  then
								local State,Data = ConduitBasic.GetCurrentCrafterState(connection);

								if State ~= nil then
									--ObjectAdder[connection] = conduit;
									if DeepEqual(Data.itemSpawnParameters,item.parameters) == true then
										ObjectAdder[connection] = conduit
									end
								else
									ObjectAdder[connection] = conduit
								end
							--end
						end
					end
				end
			end
		end
	end
	--sb.logInfo("Objects = " .. sb.print(Objects));
	--sb.logInfo("R3");
	--sb.logInfo("Objects = " .. sb.print(Objects));
	return Objects;
end

function ConduitBasic.RefreshCrafter(foundCrafters)
	if foundCrafters == "Player" then
		return "Player";
	end
	local NewCrafters = {};
	for id,conduits in pairs(foundCrafters) do
		id = tonumber(id);
		local ValidConduits = {};
		for _,conduit in ipairs(conduits) do
			if world.entityExists(conduit) == true and ConduitBasic.GenerateBiPath(conduit,entity.id()) ~= nil then
				ValidConduits[#ValidConduits + 1] = conduit;
			end
		end
		if #ValidConduits > 0 then
			NewCrafters[id] = ValidConduits;
		end
	end
	return NewCrafters;
end

--Deep Scans the Tables to see if they are equal
DeepEqual = function(A,B)
	if type(A) == "table" and type(B) == "table" then
		for index,value in pairs(A) do
			if type(value) == "table" and type(B[index]) == "table" then
				if DeepEqual(value,B[index]) == false then
					return false;
				end
			else
				if A ~= B then
					return false;
				end
			end
		end
		return true;
	end
	return A == B;
end

--Generates a Path from Conduit A to Conduit B, or nil if a path isn't possible
function ConduitBasic.GeneratePath(A,B)
	return world.callScriptedEntity(A,"ConduitCore.GetConduitPath",B);
end

--Generates a BiDirectional Path; One path from A To B, and the other From B to A
--Returns nil if the bidirectional Path is not possible
function ConduitBasic.GenerateBiPath(A,B)
	local Path = {};
	Path[#Path + 1] = world.callScriptedEntity(A,"ConduitCore.GetConduitPath",B);
	Path[#Path + 1] = world.callScriptedEntity(B,"ConduitCore.GetConduitPath",A);
	if #Path == 2 then
		return Path;
	end
	return nil;
end

--Transmits an Item from Conduit A To Conduit B, with the specified color and speed
--A Speed of Zero represents insta-speed
function ConduitBasic.TransmitAsync(A,B,Color,Speed)
	Speed = Speed or 1;
	Color = Color or "red";
end