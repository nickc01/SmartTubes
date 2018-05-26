require("/Core/Conduit Scripts/Extraction.lua");

--Variables
local OldInit = init;
local OldUpdate = update;
local Debugging = false;
--local OldUninit = uninit;

--Functions
local Extract;
local Debug;

--Initializes the Extraction Conduit
function init()
	if OldInit ~= nil then OldInit() end;
	ConduitCore.Initialize();
	Extraction.Initialize();
	--local Test = setmetatable({},{__index = function(_,k) return k end});
	Extraction.AddOperator("#",function(Item,string) return root.itemType(Item.name) == string end);
	Extraction.AddOperator("&",function(Item,string) return string.find(string.lower(Item.name),string.lower(string)) ~= nil end);
	Extraction.AddOperator("@",function(Item,string) return root.itemConfig(Item).config.category == string end);
	Extraction.AddOperator("%",function(Item,string) return root.itemHasTag(Item.name,string) end);
end

--The Update Loop for the Extraction Conduit
function update(dt)
	if OldUpdate ~= nil then OldUpdate(dt) end;
	--sb.logInfo("A");
	if Extraction.HasContainers() then
	--sb.logInfo("B");		
		Extraction.RefreshConfig();
		if Extraction.IsConfigAvailable() and ConduitCore.FirstUpdateCompleted() then
			--sb.logInfo("C");
			--local Configs = Extraction.GetConfig();
			--sb.logInfo("Configs ~= nil = " .. sb.print(Configs ~= nil));
			--sb.logInfo("Configs = " .. sb.print(Configs));
			--if Configs ~= nil then
				--sb.logInfo("Configs Size = " .. sb.print(Extraction.AmountOfConfigs()));
			--end
			Debugging = Extraction.AmountOfConfigs() == 67;
			Extract();
			Extraction.CycleConfigIndex();
		end
	end
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	local Container = Extraction.GetContainer();
	Debug("Container = " .. sb.print(Container));
	
	if Container ~= nil then
		local Item,Slot = Extraction.GetItemFromContainer(Container,Debugging);
		Debug("Item = " .. sb.print(Item));
		Debug("Slot = " .. sb.print(Slot));
		
		if Item ~= nil then
			for _,Conduit in Extraction.InsertionConduitFinder() do
				
				if world.callScriptedEntity(Conduit,"PostExtract",Extraction,Item,Slot,Container) == 0 then
					return nil;
				end
			end
		end
	end
end

Debug = function(str)
	if Debugging == true then
		sb.logInfo(str);
	end
end

--The function that is called when the extraction conduit is uninitialized from the world
--[[function uninit()
	if OldUninit ~= nil then OldUninit() end;
end--]]