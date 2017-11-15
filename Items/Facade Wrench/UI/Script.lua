
local Config;
local SourceID;
local FacadeConfig;

local SetConduit;

local Item;

local function SendAndWait(ID,Name)
	local Promise = world.sendEntityMessage(ID,Name);
	while Promise:finished() == false do end;
	return Promise:result();
end

local function UpdateItemCount()
	local Count = world.entityHasCountOfItem(SourceID,Item);
	if Count == 0 then
		widget.setFontColor("amountText",{255,0,0});
	else
		widget.setFontColor("amountText",{255,255,255});
	end
	widget.setText("amountText","x" .. Count);
end

function init()
	SourceID = pane.sourceEntity();
	Config = SendAndWait(SourceID,"GetConfig");
	widget.setChecked("removeMode",Config.Breaking);
	FacadeConfig = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	SetConduit();
end

function update(dt)
	NewConfig = SendAndWait(SourceID,"GetConfig");
	if NewConfig.Breaking ~= Config.Breaking then
		widget.setChecked("removeMode",NewConfig.Breaking);
	end
	Config = NewConfig;
	UpdateItemCount();
end

SetConduit = function()
	local Config = FacadeConfig[Config.Index];
	local Conduit = Config.conduit;
	local ConduitConfig = root.itemConfig({name = Conduit,count = 1});
	local Image;
	if ConduitConfig.config.animationParts ~= nil and ConduitConfig.config.animationParts.cables ~= nil then
		local Path = ConduitConfig.config.animationParts.cables;
		if string.find(Path,"^/") == nil then
			local Directory = ConduitConfig.directory;
			if string.find(Directory,"/$") == nil then
				Directory = Directory .. "/";
			end
			Path = Directory .. Path;
		end
		widget.setImage("conduitDisplay",Path .. ":default.none");
	end
	widget.setText("conduitText",Config.displayName);
	Item = {name = Config.item,count = 1};
end

function removeMode()
	Config.Breaking = widget.getChecked("removeMode");
	world.sendEntityMessage(SourceID,"SetConfig",Config);
end

function IncrementConduit()
	Config.Index = Config.Index + 1;
	if Config.Index > #FacadeConfig then
		Config.Index = 1;
	end
	world.sendEntityMessage(SourceID,"SetConfig",Config);
	SetConduit();
end

function DecrementConduit()
	Config.Index = Config.Index - 1;
	if Config.Index < 1 then
		Config.Index = #FacadeConfig;
	end
	world.sendEntityMessage(SourceID,"SetConfig",Config);
	SetConduit();
end
