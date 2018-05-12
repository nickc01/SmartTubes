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
end

--The Update Loop for the Terminal
Update = function(dt)
	--sb.logInfo("UPDATE 1");
	if ConduitCore.FirstUpdateCompleted() then
		UpdateNetwork();
	end
	--UpdateNetwork();
end

--Updates the Network
UpdateNetwork = function()
	if ForceUpdate == true or ConduitCore.NetworkHasChanged("TerminalFindings") and Data.SetNetwork ~= nil then
		local Network = ConduitCore.GetNetwork("TerminalFindings");
		local Containers = {};
		ForceUpdate = false;
		ContainerConnections = {};
		for _,conduit in ipairs(Network) do
			if world.entityExists(conduit) then
				local Pos = world.entityPosition(conduit);
				local ConnectedContainers = world.callScriptedEntity(conduit,"ConduitCore.GetConnections","Containers");
				if ConnectedContainers == false then
					ForceUpdate = true;
					return nil;
				end
				if ConnectedContainers ~= nil then
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
		local ConduitInfo = {};
		for _,conduit in ipairs(Network) do
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
				Info.Position = world.entityPosition(conduit);
				Info.TerminalData = world.callScriptedEntity(conduit,"ConduitCore.GetTerminalData");
				Info.ObjectName = world.entityName(conduit);
			--end
		end
		--sb.logInfo("ALL NETWORK CONTAINERS = " .. sb.printJson(Containers,1));
		Data.SetNetworkContainers(Containers);
		Data.SetConduitInfo(ConduitInfo);
		Data.SetNetwork(Network);
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
	world.callScriptedEntity(Traversal,"__Traversal__.Initialize",Insertion,Container,"Conduits",Data.GetSpeed());
end

--Extracts an item from the container
ExtractFromContainer = function(Container,Slot,Amount)
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