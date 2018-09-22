require("/Core/UICore.lua");
require("/Core/ImageCore.lua");

--Variables
local Data = {};
local PlayerID;
local Timer = 0;
local ConfigCache = {};
local FacadeConfig;
local SelectedItem;
local SelectedItemCount;

--Functions
local IndexChange;
local BreakModeChange;
local GetConfig;
local UpdateConduitImage;
local UpdateItemCount;

--The Init function for the UI
function init()
	PlayerID = pane.sourceEntity();
	FacadeConfig = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	UICore.Initialize();
	UICore.SetDefinitionTable(Data);
	UICore.SetAsSyncedValues("Settings",PlayerID,"Index",1,"Breaking",false);
	Data.AddIndexChangeFunction(IndexChange);
	Data.AddBreakingChangeFunction(BreakModeChange);
	UpdateConduitImage();
end

function update(dt)
	local NewCount = world.entityHasCountOfItem(PlayerID,SelectedItem);
	if NewCount ~= SelectedItemCount then
		UpdateItemCount(NewCount);
	end
end

--Called when the conduit index is changed
IndexChange = function()
	UpdateConduitImage();
end

--Called when the remove Mode Checkbox is clicked
function removeMode()
	Data.SetBreaking(not Data.GetBreaking());
end

--Called when the break mode is changed
BreakModeChange = function()
	widget.setChecked("removeMode",Data.GetBreaking());
end

--Gets the Config of the item
GetConfig = function(itemName)
	if ConfigCache[itemName] == nil then
		ConfigCache[itemName] = root.itemConfig({name = itemName,count = 1});
	end
	return ConfigCache[itemName];
end

--Called when the right arrow is clicked
function IncrementConduit()
	local Index = Data.GetIndex() + 1;
	if Index > #FacadeConfig then
		Index = 1;
	end
	Data.SetIndex(Index);
end

--Called when the left arrow is clicked
function DecrementConduit()
	local Index = Data.GetIndex() - 1;
	if Index < 1 then
		Index = #FacadeConfig;
	end
	Data.SetIndex(Index);
end

--Called when the conduit image needs to be updated
UpdateConduitImage = function()
	
	local Facade = FacadeConfig[Data.GetIndex()];
	if Facade == nil then
		widget.setImage("conduitDisplay","");
		widget.setText("conduitText","");
	end
	local Conduit = Facade.conduit;
	local Config = GetConfig(Conduit);
	if Config.config.animationParts ~= nil and Config.config.animationParts.cables ~= nil then
		local Image = ImageCore.MakePathAbsolute(Config.config.animationParts.cables,Conduit);
		widget.setImage("conduitDisplay",Image .. ":default.none");
	end
	widget.setText("conduitText",Facade.displayName);
	SelectedItem = {name = Facade.item,count = 1}
	local Count = world.entityHasCountOfItem(PlayerID,SelectedItem);
	UpdateItemCount(Count);
end

--Called when the item count needs to be updated
UpdateItemCount = function(count)
	SelectedItemCount = count;
	if count == 0 then
		widget.setFontColor("amountText",{255,0,0});
	else
		widget.setFontColor("amountText",{255,255,255});
	end
	widget.setText("amountText","x" .. count);
end
