require("/Core/Conduit Scripts/Extraction.lua");

--Variables
local OldInit = init;
local OldUpdate = update;
--local OldUninit = uninit;

--Functions
local Extract;

--Initializes the Extraction Conduit
function init()
	if OldInit ~= nil then OldInit() end;
	ConduitCore.Initialize();
	Extraction.Initialize();
	--local Test = setmetatable({},{__index = function(_,k) return k end});
	--sb.logInfo("Test = " .. sb.print(Test[100]));
end

--The Update Loop for the Extraction Conduit
function update(dt)
	if OldUpdate ~= nil then OldUpdate(dt) end;
	--sb.logInfo("C");
	Extraction.RefreshConfig();
	if Extraction.IsConfigAvailable() then
		--sb.logInfo("D");		
		Extract();
	end
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	local Container = Extraction.GetContainer();
	--sb.logInfo("Container = " .. sb.print(Container));
	if Container ~= nil then
		local Item,Slot = Extraction.GetItemFromContainer(Container);
		--sb.logInfo("Item = " .. sb.print(Item));
		--sb.logInfo("Slot = " .. sb.print(Slot));
		if Item ~= nil then
			for _,Conduit in Extraction.InsertionConduitFinder() do
				--sb.logInfo("Conduit = " .. sb.print(Conduit));
				if world.callScriptedEntity(Conduit,"PostExtract",Extraction,Item,Slot,Container) == 0 then
					return nil;
				end
			end
		end
	end
end

--The function that is called when the extraction conduit is uninitialized from the world
--[[function uninit()
	if OldUninit ~= nil then OldUninit() end;
end--]]