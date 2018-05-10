if TerminalUI ~= nil then return nil end;
require("/Core/UICore.lua");
require("/Core/ImageCore.lua");
require("/Core/MathCore.lua");
require("/Core/Conduit Scripts/Terminal/ViewWindow.lua");
--require("/Core/Conduit Scripts/Terminal/ItemTray.lua");
require("/Core/Conduit Scripts/Terminal/ContainerViewArea.lua");

--Declaration

--Public Table
TerminalUI = {};
local TerminalUI = TerminalUI;

--Private Table
__TerminalUI__ = {};
local __TerminalUI__ = __TerminalUI__;

--Variables
local ColorDisplayImage = "/Blocks/Conduit Terminal/UI/Window/White Color.png?setcolor=";
local Data = {};
local PlayerID;
local SourceID;
local SourcePosition;
local SelectedObject;
local ClickedConduit;
local Initialized = false;
local Colors = {};
local ColorToHex = {};
local ColorIndex = 1;

--Functions
local Update;
--local BuildObjectData;
local NetworkChange;
local BackgroundClick;
local DefaultHover;
local ColorChange;
local SpeedChange;
--local BuildController;
--local CheckForMouseHover;

--Initializes the Terminal UI
function TerminalUI.Initialize()
	if Initialized == true then return nil end;
	Initialized = true;
	PlayerID = player.id();
	world.sendEntityMessage(PlayerID,"SetUsingTerminal",true);
	SourceID = config.getParameter("MainObject") or pane.sourceEntity();
	SourcePosition = world.entityPosition(SourceID);
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("ConduitNetwork",SourceID,"Network",{},"NetworkContainers",{},"ConduitInfo",{});
	UICore.SetAsSyncedValues("Settings",SourceID,"Color","red","Speed",0);
	Data.AddSpeedChangeFunction(SpeedChange);
	local ColorData = root.assetJson("/Projectiles/Traversals/Colors.json").Colors;
	Colors = {};
	for k,color in ipairs(ColorData) do
		Colors[#Colors + 1] = color[2];
		ColorToHex[color[2]] = color[1];
		if Data.GetColor() == color[2] then
			ColorIndex = k;
		end
	end
	Data.AddColorChangeFunction(ColorChange);
	ColorChange();
	SpeedChange();
	Data.AddNetworkChangeFunction(NetworkChange);
	ViewWindow.Initialize();
	ContainerArea.Initialize();
	--ItemTray.Initialize();
	ViewWindow.AddBackgroundClickFunction(BackgroundClick);
	NetworkChange();
	local OldUpdate = update;
	update = function(dt)
		Update(dt);
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
	end
	local OldUninit = uninit;
	uninit = function()
		if OldUninit ~= nil then
			OldUninit();
		end
		world.sendEntityMessage(PlayerID,"SetUsingTerminal",false);
	end
end

--The Update Loop for the Terminal UI
Update = function(dt)
	--[[if ContainerArea.HasContainer() then
		local Item = ContainerArea.ItemInSlot(2) or {name = "perfectlygenericitem",count = 0};
		ContainerArea.SetItemInSlot(2,{name = "perfectlygenericitem",count = Item.count + 1,parameters = Item.parameters});
	end--]]
end

BackgroundClick = function(clicking)
	if clicking == true then
		ViewWindow.SetSelectedObject(nil);
	end
end

--Called when the network has changed
NetworkChange = function()
	ContainerArea.SetContainer(nil);
	ViewWindow.SetSelectedObject(nil);
	local StartTime = TerminalUI.GetTime();
	--sb.logInfo("Start Time = " .. sb.print(StartTime));
	ViewWindow.Clear();
	local Network = Data.GetNetwork();
	local ConduitInfo = Data.GetConduitInfo();
	if Network == nil then return nil end;
	sb.logInfo("Network = " .. sb.printJson(Network,1));
	sb.logInfo("Conduit Info = " .. sb.printJson(ConduitInfo,1));
	--Render all conduits in the network
	for i=#Network,1,-1 do
		local Controllers;
		local Conduit;
		local ID = Network[i];
		local Info = ConduitInfo[tostring(ID)];
		local OnHover;
		local OnClick;
		if Info ~= nil and Info.HasMenuData == true and world.entityName(ID) ~= "conduitterminal" then
			--OnHover = GetDefaultHoverFunction(Conduit);
			OnHover = function(hovering)
				DefaultHover(Conduit,hovering);
			end
			--local Text;
			OnClick = function(clicking)
				if clicking == true then
					--Conduit.SetColor({255,0,0});
					local ConduitPos = Conduit.GetPosition();
					local MenuItems = {};
					if Info.UI ~= nil then
						--sb.logInfo("INFO = " .. sb.printJson(Info,1));
						if Info.UI.Link ~= nil then
							Info.UI.Data = root.assetJson(Info.UI.Link);
							Info.UI.Link = nil;
						end
						if Info.UI.Data.IsModified ~= true then
							local Data = Info.UI.Data;
							Data.IsModified = true;
							Data.SourcePlayer = PlayerID;
							Data.MainObject = ID;
							Data.scripts[#Data.scripts + 1] = "/Core/Conduit Scripts/Terminal/TerminalGUIController.lua";
						end
						--sb.logInfo("Main Object = " .. sb.print(Info.UI.Data.MainObject));
						MenuItems[#MenuItems + 1] = "Open UI";
						MenuItems[#MenuItems + 1] = function()
							player.interact(Info.UI.Type,Info.UI.Data,PlayerID);
						end
					end
					ViewWindow.SetSelectedObject(Conduit,table.unpack(MenuItems));
				end
			end
		end
		Conduit = ViewWindow.AddConduit(Network[i],Info.Position,nil,OnClick,OnHover);
	end

	--Render all the containers in the network
	--sb.logInfo("OBJECTS");
	local NetworkContainers = Data.GetNetworkContainers();
	--sb.logInfo("NETWORK CONTAINERS = " .. sb.print(NetworkContainers));
	for StringObject,data in pairs(NetworkContainers) do
		--for _,object in ipairs(data) do
		local object = tonumber(StringObject);
		local Controller;
		local OnClick = function(clicking)
			if clicking == true then
				local MenuItems = {};
				MenuItems[#MenuItems + 1] = "View Contents";
				MenuItems[#MenuItems + 1] = function()
					--TODO
					--Open up an area where you can view, extract, and insert items into it
					ContainerArea.SetContainer(object,data.Extraction,data.Insertion);
				end
				ViewWindow.SetSelectedObject(Controller,table.unpack(MenuItems));
			end
		end
		local OnHover = function(hovering)
			DefaultHover(Controller,hovering);
		end
		Controller = ViewWindow.AddObject(object,data.Position,nil,OnClick,OnHover);
		Controller.MoveToBottom();
		--end
	end
	local endTime = TerminalUI.GetTime();
	--sb.logInfo("end Time = " .. sb.print(endTime));
	--sb.logInfo("Difference = " .. sb.print(endTime - StartTime));
end

--Gets the Current Time Elapsed
function TerminalUI.GetTime()
	return os.clock();
end

--returns a default OnHover function
--[[GetDefaultHoverFunction = function(Controller)
	local Controllers;
	local OnHover = function(hovering)
		if hovering == true then
			if SelectedObject ~= nil then
				SelectedObject.RemoveHighlights();
			end
			Controllers = {};
			for _,texture in ipairs(Controller.GetTextures()) do
				local Controller = ViewWindow.AddTexture(ImageCore.AddImageDirective(texture,"?setcolor=19db00"),Controller.GetPosition(true),nil,nil,nil,3,Controller.FlipX(),Controller.FlipY());
				Controller.MoveToBottom();
				Controllers[#Controllers + 1] = Controller;
			end
			Controller.RemoveHighlights = function()
				for _,controller in ipairs(Controllers) do
					controller.Remove();
				end
				Controllers = nil;
				Controller.RemoveHighlights = nil;
			end
			SelectedObject = Controller;
		else
			if Controllers ~= nil then
				if ClickedController ~= Controller then
					Controller.RemoveHighlights = nil;
					for _,controller in ipairs(Controllers) do
						controller.Remove();
					end
					Controllers = nil;
				end
				if SelectedObject == Controller then
					SelectedObject = nil;
				end
			end
		end
	end
	return OnHover;
end--]]

--Default Functionality For the Hover function
DefaultHover = function(Controller,hovering)
	if hovering == true then
		if SelectedObject ~= nil then
			SelectedObject.RemoveHighlights();
		end
		local Controllers = {};
		for _,texture in ipairs(Controller.GetTextures()) do
			local Controller = ViewWindow.AddTexture(ImageCore.AddImageDirective(texture,"?setcolor=19db00"),Controller.GetPosition(true),nil,nil,nil,3,Controller.FlipX(),Controller.FlipY());
			Controller.MoveToBottom();
			Controllers[#Controllers + 1] = Controller;
		end
		Controller.__OtherControllers = Controllers;
		Controller.RemoveHighlights = function()
			for _,controller in ipairs(Controller.__OtherControllers) do
				controller.Remove();
			end
			Controller.__OtherControllers = nil;
			Controller.RemoveHighlights = nil;
		end
		SelectedObject = Controller;
	else
		if Controller.__OtherControllers ~= nil then
			if ClickedController ~= Controller then
				Controller.RemoveHighlights = nil;
				for _,controller in ipairs(Controller.__OtherControllers) do
					controller.Remove();
				end
				Controller.__OtherControllers = nil;
			end
			if SelectedObject == Controller then
				SelectedObject = nil;
			end
		end
	end
end

--Called when the "Add Speed Upgrade" button is clicked
function SpeedAdd()
	--sb.logInfo("Add");
	if Data.GetSpeed() < 20 and player.consumeItem({name = "speedupgrade",count = 1}) ~= nil then
		Data.SetSpeed(Data.GetSpeed() + 1);
	end
end

--Called when the "Remove Speed Upgrade" button is clicked
function SpeedRemove()
	--sb.logInfo("Remove");
	if Data.GetSpeed() > 0 then
		player.giveItem({name = "speedupgrade",count = 1});
		Data.SetSpeed(Data.GetSpeed() - 1);
	end
end

--Called when the "Color Increment" button is clicked
function ColorIncrement()
	ColorIndex = ColorIndex + 1;
	if ColorIndex > #Colors then
		ColorIndex = 1;
	end
	Data.SetColor(Colors[ColorIndex]);
end

--Called when the "Color Decrement" button is clicked
function ColorDecrement()
	ColorIndex = ColorIndex - 1;
	if ColorIndex < 0 then
		ColorIndex = #Colors;
	end
	Data.SetColor(Colors[ColorIndex]);
end

--Called when the Color is changed
ColorChange = function()
	widget.setImage("colorDisplay",ColorDisplayImage .. ColorToHex[Data.GetColor()]);
end

--Called when the Speed is changed
SpeedChange = function()
	widget.setText("speedUpgrades",tostring(Data.GetSpeed()));
end

--Gets the Terminal's current Speed
function TerminalUI.GetSpeed()
	return Data.GetSpeed();
end