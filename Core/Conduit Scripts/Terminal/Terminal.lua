require("/Core/ConduitCore.lua");
require("/Core/ServerCore.lua");

--Declaration

--Public Table
Terminal = {};
local Terminal = Terminal;

--Private Table, PLEASE DONT TOUCH
__Terminal__ = {};
local __Terminal__ = __Terminal__;

--Variables
local SourceID;
local SourcePosition;
local ContainerConnections = {};
local Insertion = {};
__Insertion__ = {};
local SentTraversals = {};
local ForceUpdate = false;
local UpdatingNetwork = false;

local Data = {};

--Functions
local PostInit;
local ConduitNetworkUpdate;
local Update;
local IsInList;
local PutItemInContainer;
local SetMessages;
local UpdateNetwork;
local Drop;
local ExtractFromContainer;
local Uninit;
local SplitIter;

--Initializes the Terminal
function Terminal.Initialize()
	SourceID = entity.id();
	--sb.logInfo("SOURCEID = " .. sb.print(SourceID));
	SourcePosition = entity.position();
	local OldUpdate = update;
	--sb.logInfo("Setting UPdate Function");
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
	local OldUninit = uninit;
	uninit = function()
		if OldUninit ~= nil then
			OldUninit();
		end
		Uninit();
	end
	Server.SetDefinitionTable(Data);
	Server.DefineSyncedValues("Settings","Color","red","Speed",0);
	ConduitCore.AddPostInitFunction(PostInit);
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.Initialize();
	SetMessages();
end

--Sets the Messages
SetMessages = function()
	message.setHandler("PutItemInContainer",function(_,_,item,container,slot,speed,color)
		return PutItemInContainer(item,container,slot,speed,color);
	end);
	message.setHandler("ExtractFromContainer",function(_,_,container,slot,amount)
		return ExtractFromContainer(container,slot,amount);
	end);
	message.setHandler("ExecuteScript",function(_,_,object,functionName,...)
		if object ~= nil and world.entityExists(object) then
			return world.callScriptedEntity(object,functionName,...);
		else
			return nil;
		end
	end);
	message.setHandler("ExtractFromNetwork",function(_,_,item,count,plusSend)
		return ExtractFromNetwork(item,count,plusSend);
	end);
end

--The Update Loop for the Terminal
Update = function(dt)
	--sb.logInfo("UPDATE 1");
	if ConduitCore.FirstUpdateCompleted() and UpdatingNetwork == false then
		Server.AddAsyncCoroutine(function()
			UpdateNetwork();
		end);
		--UpdateNetwork();
	end
	--UpdateNetwork();
end

--Updates the Network
UpdateNetwork = function()
	if ForceUpdate == true or ConduitCore.NetworkHasChanged("TerminalFindings") and Data.SetNetwork ~= nil then
		if UpdatingNetwork == true then
			while(UpdatingNetwork == true) do
				coroutine.yield();
			end
		end
		UpdatingNetwork = true;
		local Injection = Server.AddCoroutineInjection(function() UpdatingNetwork = false; end);
		sb.logInfo("Network changed = " .. sb.print(ConduitCore.NetworkHasChanged("TerminalFindings")));
		sb.logInfo("Force CHange = " .. sb.print(ForceUpdate));
		sb.logInfo("Updating Network");
		local Network = ConduitCore.GetNetwork("TerminalFindings");
		local Containers = {};
		ForceUpdate = false;
		ContainerConnections = {};
		for _,conduit in ipairs(Network) do
			if world.entityExists(conduit) then
				local Pos = world.entityPosition(conduit);
				if world.callScriptedEntity(conduit,"ConduitCore.FullyLoaded") ~= true then
					ForceUpdate = true;
					UpdatingNetwork = false;
					return nil;
				end
				local ConnectedContainers = world.callScriptedEntity(conduit,"ConduitCore.GetConnections","Containers");
				--[[if ConnectedContainers == false then
					ForceUpdate = true;
					return nil;
				end--]]
				if ConnectedContainers ~= false then
					for _,container in ipairs(ConnectedContainers) do
						if container ~= 0 then
							local StringContainer = tostring(container);
							if ContainerConnections[StringContainer] == nil then
								ContainerConnections[StringContainer] = {
									Extraction = {},
									Insertion = {}
								}
							end
							local LocalContainerC = ContainerConnections[StringContainer];
							if Containers[StringContainer] == nil then
								Containers[StringContainer] = {
									Extraction = false,
									Insertion = false,
									Position = world.entityPosition(container),
									Name = world.entityName(container)
								}
							end
							if world.callScriptedEntity(conduit,"Extraction.IsExtraction") == true then
								if not IsInList(LocalContainerC.Extraction,conduit) then
									LocalContainerC.Extraction[#LocalContainerC.Extraction + 1] = conduit;
								end
								Containers[StringContainer].Extraction = true;
							end
							if world.callScriptedEntity(conduit,"Insertion.IsInsertion") == true then
								if not IsInList(LocalContainerC.Insertion,conduit) then
									LocalContainerC.Insertion[#LocalContainerC.Insertion + 1] = conduit;
								end
								Containers[StringContainer].Insertion = true;
							end
							--[[if Containers[StringContainer].Insertion == false then
								Containers[StringContainer].Insertion = world.callScriptedEntity(conduit,"Insertion.IsInsertion") == true;
							end--]]
						end
					end
				end
			end
		end
		sb.logInfo("FULL CONTAINER CONNECTIONS = " .. sb.print(ContainerConnections));
		local ConduitInfo = {};
		for index,conduit in ipairs(Network) do
			--if world.entityExists(conduit) then
				--sb.logInfo("Conduit = " .. sb.print(conduit));
				--sb.logInfo("Exists = " .. sb.print(world.entityExists(conduit)));
				local Info = {};
				ConduitInfo[tostring(conduit)] = Info;
				--Conduit Info Here
				Info.HasMenuData = false;
				local Data = world.callScriptedEntity(conduit,"ConduitCore.GetUI");
				--sb.logInfo("DATA RECIEVED = " .. sb.print(Data));
				--local UIType,UIData = Data.Type,Data.Interaction;
				if Data ~= nil then
					Info.UI = {Type = Data.Type,Data = Data.Interaction,Link = Data.Link};
					--sb.logInfo("INFO.UI = " .. sb.printJson(Info.UI,1));
					Info.HasMenuData = true;
				end
				--sb.logInfo("Printing Conduit of = " .. sb.print(conduit));
				--world.sendEntityMessage(conduit,"ConduitCore.RefreshNetwork","Conduits");
				--sb.logInfo("A");
				Info.Position = world.entityPosition(conduit);
				Info.TerminalData = world.callScriptedEntity(conduit,"ConduitCore.GetTerminalData");
				Info.ObjectName = world.entityName(conduit);
				sb.logInfo("Index = " .. sb.print(index));
				Info.ConduitType = world.getObjectParameter(conduit,"conduitType");
				if Info.ConduitType == "extraction" or Info.ConduitType == "io" then
					--Check if the Conduit hs extractable from the terminal
					if world.callScriptedEntity(conduit,"ConduitCore.GetConduitPath",SourceID) ~= nil then
						Info.Extractable = true;
					else
						Info.Extractable = false;
					end
					coroutine.yield();
				end
			--end
		end
		--sb.logInfo("ALL NETWORK CONTAINERS = " .. sb.printJson(Containers,1));
		Data.SetNetworkContainers(Containers);
		Data.SetConduitInfo(ConduitInfo);
		Data.SetNetwork(Network);
		Server.RemoveCoroutineInjection(Injection);
		UpdatingNetwork = false;
	end
end

--Returns true if the item is contained inside of the table, and false otherwise
IsInList = function(tbl,item)
	for i=1,#tbl do
		if tbl[i] == item then
			return true;
		end
	end
	return false;
end

--The Post Init Function, called after the first update in ConduitCore
PostInit = function()
	--sb.logInfo("POST INIT");
	Server.DefineSyncedValues("ConduitNetwork","Network",nil,"NetworkContainers",nil,"ConduitInfo",nil);
	Server.DefineSyncedValues("ItemTray","Tray",{});
	--sb.logInfo("DATA = " .. sb.print(Data));
	ConduitCore.AddNetworkUpdateFunction(ConduitNetworkUpdate);
	Server.SaveValuesOnExit("ConduitNetwork",false);
end

--Called when the conduit network is updated
ConduitNetworkUpdate = function()
	--sb.logInfo("Conduit Network Update");
	--sb.logInfo("Conduit NETWORK = " .. sb.print(ConduitCore.GetConduitNetwork()));
	--Data.SetNetwork(ConduitCore.GetConduitNetwork());
end

--Called when the traversal has reached it's destination
function __Insertion__.InsertTraversalItems(traversal)
	--TODO
	__Insertion__.DropTraversalItems(traversal);
end

--Called when the traversal has failed to reach it's destination
function __Insertion__.DropTraversalItems(traversal)
	--TODO
	local stringTraversal = tostring(traversal);
	local Data = SentTraversals[stringTraversal];
	Drop(Data.Item,world.entityPosition(traversal));
	SentTraversals[stringTraversal] = nil;
	return nil;
end

--Called when a traversal has been respawned into a new one
function __Insertion__.TraversalRespawn(OldTraversal,NewTraversal)
	SentTraversals[tostring(NewTraversal)],SentTraversals[tostring(OldTraversal)] = SentTraversals[tostring(OldTraversal)],nil;
end

--Returns the ID of this Conduit
Insertion.GetID = function()
	return SourceID;
end

--Called when the UI requests to put an item in a slot of a container
PutItemInContainer = function(item,container,slot)
	Server.AddAsyncCoroutine(function()
		UpdateNetwork();
		local ContainerData = Data.GetNetworkContainers();
		local ContainerInfo = ContainerData[tostring(container)];
		local ConnectedConduits = ContainerConnections[tostring(container)];
		if ContainerInfo.Insertion == true then
			if ConnectedConduits ~= nil and #ConnectedConduits.Insertion > 0 then
				local FirstInsertion = ConnectedConduits.Insertion[1];
				if world.entityExists(FirstInsertion) and world.callScriptedEntity(FirstInsertion,"Insertion.IsConnectedTo",container) == true then
					--local SendingItem =  Insertion.ItemCanFit(container,item,slot,false);
					--sb.logInfo("Insertion ID = " .. sb.print(FirstInsertion));
					--sb.logInfo("Is Connected to " .. sb.print(container) .. " = " .. sb.print(world.callScriptedEntity(FirstInsertion,"Insertion.IsConnectedTo",container) == true));
					local SendingItem = world.callScriptedEntity(FirstInsertion,"Insertion.ItemCanFit",container,item,slot,false);
					if SendingItem ~= nil then
						--Find a path that works and send the item over
						for _,insertion in ipairs(ConnectedConduits.Insertion) do
							if world.entityExists(insertion) then
								--sb.logInfo("Insertion ID = " .. sb.print(insertion));
								--sb.logInfo("Is Connected to " .. sb.print(container) ..  " = " .. sb.print(world.callScriptedEntity(insertion,"Insertion.IsConnectedTo",container) == true));
								local Path = ConduitCore.GetPath("Conduits",insertion);
								if Path ~= nil then
									--Send the Item
									--TODO Set up traversal color and traversal speed to be configurable
									--sb.logInfo("FINAL Slot = " .. sb.print(slot));
									world.callScriptedEntity(insertion,"Insertion.SendItem",SendingItem,container,slot,SourceID,{slot},Data.GetColor(),Data.GetSpeed());
									if SendingItem.count < item.count then
										Drop({name = SendingItem.name,count = item.count - SendingItem.count,parameters = SendingItem.parameters});
									end
									return 0;
								end
							end
						end
						Drop(item);
						return 2;
					end
				end
			end
		end
		Drop(item);
		return 1;
	end);
end

--Drops an item in front of the terminal
Drop = function(item,position)
	world.spawnItem(item,position or SourcePosition);
end

--Handles any extraction conduits sending items over
function PostExtract(Extraction,Item,Slot,Container)
	--TODO , Add a way to customize traversal and traversal speed
	local StartPosition = world.entityPosition(Extraction.GetID());
	local Traversal = world.spawnProjectile("traversal" .. Data.GetColor(),{StartPosition[1] + 0.5,StartPosition[2] + 0.5});
	SentTraversals[tostring(Traversal)] = {
		Item = Item
	}
	world.callScriptedEntity(Traversal,"__Traversal__.Initialize",Insertion,Container,"Conduits",Data.GetSpeed() + 1);
end

--Extracts an item from the container
ExtractFromContainer = function(Container,Slot,Amount)
	Server.AddAsyncCoroutine(function()
		UpdateNetwork();
		local ContainerData = Data.GetNetworkContainers();
		local ContainerInfo = ContainerData[tostring(Container)];
		local ConnectedConduits = ContainerConnections[tostring(Container)];
		if ContainerInfo.Extraction == true then
			if ConnectedConduits ~= nil and #ConnectedConduits.Extraction > 0 then
				local Item = world.containerItemAt(Container,Slot - 1);
				if Item ~= nil then
					--sb.logInfo("Amount = " .. sb.print(Amount));
					if Amount == nil or Amount > Item.count then
						Amount = Item.count;
					end
					for _,conduit in ipairs(ConnectedConduits.Extraction) do
						if world.entityExists(conduit) then
							local Path = world.callScriptedEntity(conduit,"ConduitCore.GetPath","Conduits",SourceID);
							if Path ~= nil then
								world.containerTakeNumItemsAt(Container,Slot - 1,Amount);
								
								world.callScriptedEntity(conduit,"Extraction.SendItem",{name = Item.name,count = Amount,parameters = Item.parameters},Container,Slot,SourceID);
								return true;
							end
						end
					end
					return 2;
				end
			end
		end
		return false;
	end);
end

--Called when the terminal is uninitialized
Uninit = function()
	for stringTraversal,data in pairs(SentTraversals) do
		local Traversal = tonumber(stringTraversal);
		if world.entityExists(Traversal) then
			world.callScriptedEntity(Traversal,"__Traversal__.SetInsertionTable",nil);
			world.callScriptedEntity(Traversal,"__Traversal__.AddPrediction",{Item = data.Item,Traversal = Traversal});
		end
	end
end

--Extracts the set amount of an item from any container in the network
--If sucessful, will return the amount that was extracted and all the containers it extracted from and along with them, the new contents and a new UUID for each
--If not sucessful, it will return the amount it was able to extract plus the above
function ExtractFromNetwork(item,count,plusSend)
	if plusSend == nil then
		plusSend = true;
	end
	count = count or item.count;
	local Network = Data.GetNetwork();
	if Network == nil then return nil end;
	local Return = {
		Amount = 0,
		DirectConduits = {},
		SideConduits = {}
	}
	local AmountToExtract = count;
	local ExtractedConduits = Return.DirectConduits;
	for _,conduit in ipairs(Network) do
		if world.entityExists(conduit) and (world.getObjectParameter(conduit,"conduitType") == "extraction" or world.getObjectParameter(conduit,"conduitType") == "io") then
			local ConduitInfo = {
				ID = conduit,
				UUID = nil,
				ContainerContents = {},
				Amount = 0
			};
			local ContainerContents = ConduitInfo.ContainerContents;
			local Connections = world.callScriptedEntity(conduit,"ConduitCore.GetConnections","Containers");
			if Connections ~= false then
				local AffectedContainers = {};
				for _,container in ipairs(Connections) do
					if world.entityExists(container) then
						local Available = world.containerAvailable(container,{name = item.name,count = 1,parameters = item.parameters});
						if Available > AmountToExtract then
							Available = AmountToExtract;
						end
						if Available > 0 then
							world.containerConsume(container,{name = item.name,count = Available,parameters = item.parameters});
							if plusSend == true then
								--Send the Item to the terminal
								sb.logInfo("Now Send");
								sb.logInfo("Available = " .. sb.print(Available));
								for number in SplitIter(Available,1000) do
									sb.logInfo("Sending = " .. sb.print(number));
									PostExtract(world.callScriptedEntity(conduit,"__Extraction__.GetExtraction"),{name = item.name,count = number,parameters = item.parameters},nil,container);
								end
							end
							ConduitInfo.Amount = ConduitInfo.Amount + Available;
							AmountToExtract = AmountToExtract - Available;
							AffectedContainers[#AffectedContainers + 1] = container;
						end
						local Contents = {};
						local Size = world.containerSize(container);
						for i=1,Size do
							Contents[i] = world.containerItemAt(container,i - 1) or "";
						end
						ContainerContents[tostring(container)] = Contents;
					end
				end
				if ConduitInfo.Amount > 0 then
					Return.Amount = Return.Amount + ConduitInfo.Amount;
					ConduitInfo.UUID = sb.makeUuid();
					for _,container in ipairs(AffectedContainers) do
						sb.logInfo("Container Connections = " .. sb.print(ContainerConnections));
						local LocalConnections = ContainerConnections[tostring(container)];
						for _,extraction in ipairs(LocalConnections.Extraction) do
							if extraction == conduit then
								world.callScriptedEntity(extraction,"__Extraction__.SetContainerCache",ContainerContents,ConduitInfo.UUID);
							else
								world.callScriptedEntity(extraction,"__Extraction__.SetContainerCachePortion",ContainerContents[tostring(container)],ConduitInfo.UUID,container);
								for i=1,#Return.SideConduits do
									if Return.SideConduits[i].ID == extraction then
										Return.SideConduits[i].UUID = ConduitInfo.UUID;
										Return.SideConduits[i].Contents = world.callScriptedEntity(insertion,"__Extraction__.GetContainerCache");
										goto AddedSideConduit;
									end
								end
								Return.SideConduits[#Return.SideConduits + 1] = {ID = extraction,UUID = ConduitInfo.UUID,Contents = world.callScriptedEntity(insertion,"__Extraction__.GetContainerCache")};
								::AddedSideConduit::
							end
						end
						for _,insertion in ipairs(LocalConnections.Insertion) do
							if insertion == conduit then
								world.callScriptedEntity(insertion,"__Insertion__.SetContainerCache",ContainerContents,ConduitInfo.UUID);
							else
								world.callScriptedEntity(insertion,"__Insertion__.SetContainerCachePortion",ContainerContents[tostring(container)],ConduitInfo.UUID,container);
								for i=1,#Return.SideConduits do
									if Return.SideConduits[i].ID == insertion then
										Return.SideConduits[i].UUID = ConduitInfo.UUID;
										Return.SideConduits[i].Contents = world.callScriptedEntity(insertion,"__Insertion__.GetContainerCache");
										goto AddedSideConduit;
									end
								end
								Return.SideConduits[#Return.SideConduits + 1] = {ID = insertion,UUID = ConduitInfo.UUID,Contents = world.callScriptedEntity(insertion,"__Insertion__.GetContainerCache")};
								::AddedSideConduit::
							end
						end
					end
					--world.callScriptedEntity(conduit,"__Extraction__.SetContainerCache",ContainerContents,ConduitInfo.UUID);
					ExtractedConduits[#ExtractedConduits + 1] = ConduitInfo;
					for index,sideConduit in ipairs(Return.SideConduits) do
						if sideConduit.ID == conduit then
							table.remove(Return.SideConduits,index);
							break;
						end
					end
				end
				if AmountToExtract == 0 then
					break;
				end
			end
		end
	end
	return Return;
end

--Iterates over a number while splitting it into sections
SplitIter = function(number,sectionSize)
	local Current = number;
	return function()
		if Current == 0 then
			return nil;
		end
		if Current <= sectionSize then
			local Ret = Current;
			Current = 0;
			return Ret;
		else
			local Ret = sectionSize;
			Current = Current - sectionSize;
			return Ret;
		end
	end
end