local ButtonStates = {};
local SourceID;
local InitState;
local IncrementState;
local UpdateImage;
local SendState;
local Speed = 0;
local SpeedMax = 20;
local Mode;

local Sides = {"Left","Right","Top","Bottom","Center"};


local function SetMode(mode)
	Mode = mode;
	world.sendEntityMessage(SourceID,"SetMode",mode);
end

local function SetModeText(text)
	widget.setText("modeText",text);
end

function init()
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	Speed = world.getObjectParameter(SourceID,"Speed",0);
	Mode = world.getObjectParameter(SourceID,"OutputMode","ToLevel");
	if Mode == "ToLevel" then
		SetToLevel();
	elseif Mode == "Fill" then
		SetToFill();
	end
	widget.setText("speedUpgrades",Speed);
	ContainerCore.Init(SourceID);
	for i=1,#Sides do
		InitState(Sides[i]);
		UpdateImage(Sides[i]);
	end
	ContainerCore.Update();
end

function update(dt)
	--sb.logInfo("Updating");
	ContainerCore.Update();
end

function die()
	
end

function uninit()
	
end

function SetToLevel()
	SetMode("ToLevel");
	SetModeText("To Level");
	Dropdown(nil,false);
end

function SetToFill()
	SetMode("Fill");
	SetModeText("Fill");
	Dropdown(nil,false);
end

local Enabled = false;

function Dropdown(_,forceMode)
	if forceMode ~= nil then
		Enabled = forceMode;
	else
		Enabled = not Enabled;
	end
	if Enabled == true then
		widget.setVisible("modeAreaFill",true);
		widget.setVisible("modeAreaToLevel",true);
	else
		widget.setVisible("modeAreaFill",false);
		widget.setVisible("modeAreaToLevel",false);
	end
end


function ButtonPress(source)
	local Side = string.match(source,"(.*)Button");
	InitState(Side);
	IncrementState(Side);
	UpdateImage(Side);
	SendState(Side);
end

InitState = function(Side)
	if ButtonStates[Side] == nil then
		ButtonStates[Side] = world.getObjectParameter(SourceID,Side .. "State","Disabled");
	end
end
IncrementState = function(Side)
	if     ButtonStates[Side] == "Disabled" then
		ButtonStates[Side] = "Import";
	elseif ButtonStates[Side] == "Import" then
		ButtonStates[Side] = "Export";
	elseif ButtonStates[Side] == "Export" then
		ButtonStates[Side] = "Disabled";
	end
end

function SpeedAdd()
	local Original = Speed;
	Speed = Speed + 1;
	if Speed > SpeedMax then Speed = SpeedMax end;
	if Speed ~= Original and player.consumeItem({name = "speedupgrade",count = 1}) ~= nil then
		world.sendEntityMessage(SourceID,"SetSpeed",Speed);
		widget.setText("speedUpgrades",Speed);
	else
		Speed = Original;
	end
end

function SpeedRemove()
	local Original = Speed;
	Speed = Speed - 1;
	if Speed < 0 then Speed = 0 end;
	if Speed ~= Original then
		player.giveItem({name = "speedupgrade",count = 1});
		world.sendEntityMessage(SourceID,"SetSpeed",Speed);
		widget.setText("speedUpgrades",Speed);
	end
end

UpdateImage = function(Side)
	widget.setImage(Side .. "Image","/Blocks/Conduits/Fluid Conduit/UI/Window/Fluid Buttons/" .. ButtonStates[Side] .. ".png");
end

SendState = function(Side)
	world.sendEntityMessage(SourceID,"SetState",Side,ButtonStates[Side]);
end