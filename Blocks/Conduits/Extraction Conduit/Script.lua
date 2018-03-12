require("/Core/Conduit Scripts/Extraction.lua");

--Variables
local OldInit = init;
local OldUpdate = update;
local OldDie = die;
local OldUninit = uninit;

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
	Extraction.RefreshConfig();
	if Extraction.IsConfigAvailable() then
		Extract();
	end
end

--The function that is called when the extraction conduit dies
function die()
	if OldDie ~= nil then OldDie() end;
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	local Container = Extraction.GetContainer();
	if Container ~= nil then
		--sb.logInfo("Item = " .. sb.print());
		local Item,Slot = Extraction.GetItemFromContainer(Container);
		for _,Conduit in Extraction.InsertionConduitFinder() do
			--sb.logInfo("Conduit = " .. sb.print(i));
		end
		--sb.logInfo("End");
		--sb.logInfo("Item = " .. sb.print(Item) .. " Slot = " .. sb.print(Slot));
		--if Item ~= nil then
		--	ContainerHelper.ConsumeAt(Container,Slot - 1,Item.count);
		--	world.containerConsumeAt(Container,Slot - 1,Item.count);
		--end

	end
	--sb.logInfo("Container Selected = " .. sb.print(Container));
end

--The function that is called when the extraction conduit is uninitialized from the world
function uninit()
	if OldUninit ~= nil then OldUninit() end;
end