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
	
end

--The Update Loop for the Extraction Conduit
function update(dt)
	if OldUpdate ~= nil then OldUpdate(dt) end;
	
	Extraction.RefreshConfig();
	if Extraction.IsConfigAvailable() then
				
		Extract();
	end
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	local Container = Extraction.GetContainer();
	
	if Container ~= nil then
		local Item,Slot = Extraction.GetItemFromContainer(Container);
		
		
		if Item ~= nil then
			for _,Conduit in Extraction.InsertionConduitFinder() do
				
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