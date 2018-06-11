require("/Core/Conduit Scripts/Extraction.lua");

--Variables
local OldInit = init;
local OldUpdate = update;
local Debugging = false;
local MainRoutine;
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
	MainRoutine = coroutine.create(function()
		while(true) do
			::Start::
			local Counter = 0;
			local Limit = math.ceil(80 / (((Extraction.GetSpeed() + 1) / 2) + 0.5));
			while Counter < Limit do
				coroutine.yield();
				Counter = Counter + 1;
				--sb.logInfo("Counter = " .. sb.print(Counter));
			end
			if Extraction.HasContainers() then
				--sb.logInfo("D");		
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
					for i=1,Extraction.AmountOfConfigs() do
						if Extract() == true then
							Extraction.CycleConfigIndex();
							--sb.logInfo("B");
							break;
						else
							Extraction.CycleConfigIndex();
							coroutine.yield();
							if not Extraction.HasContainers() then
								--sb.logInfo("A");
								goto Start;
							end
						end
					end
				end
			end
			coroutine.yield();
		end
	end);
end

--The Update Loop for the Extraction Conduit
function update(dt)
	if OldUpdate ~= nil then OldUpdate(dt) end;
	--sb.logInfo("Test");
	coroutine.resume(MainRoutine,dt);
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	local Container = Extraction.GetContainer();
	--Debug("Container = " .. sb.print(Container));
	
	if Container ~= nil then
		local Item,Slot = Extraction.GetItemFromContainer(Container,Debugging);
		--Debug("Item = " .. sb.print(Item));
		--Debug("Slot = " .. sb.print(Slot));
		
		if Item ~= nil then
			for _,Conduit in Extraction.InsertionConduitFinder() do
				
				if world.callScriptedEntity(Conduit,"PostExtract",Extraction,Item,Slot,Container) == 0 then
					return true;
				end
			end
		end
	end
end

Debug = function(str)
	if Debugging == true then
		--sb.logInfo(str);
	end
end

--The function that is called when the extraction conduit is uninitialized from the world
--[[function uninit()
	if OldUninit ~= nil then OldUninit() end;
end--]]