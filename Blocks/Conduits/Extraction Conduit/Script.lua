require("/Core/Conduit Scripts/Extraction.lua");

--Variables
local OldInit = init;
local OldUpdate = update;
local MainRoutine;
local Enabled = true;
local HasInputNodes = false;

--Functions
local Extract;
local SafeResume;

--Initializes the Extraction Conduit
function init()
	if OldInit ~= nil then OldInit() end;
	ConduitCore.Initialize();
	Extraction.Initialize();
	HasInputNodes = config.getParameter("inputNodes") ~= nil;
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
			end
			if Extraction.HasContainers() then	
				Extraction.RefreshConfig();
				if Extraction.IsConfigAvailable() and ConduitCore.FirstUpdateCompleted() then
					for i=1,Extraction.AmountOfConfigs() do
						if Extract() == true then
							Extraction.CycleConfigIndex();
							break;
						else
							Extraction.CycleConfigIndex();
							coroutine.yield();
							if not Extraction.HasContainers() then
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
	coroutine.resume(MainRoutine,dt);
end

--The Main Extraction Function for the Extraction Conduit
Extract = function()
	--sb.logInfo("Extract");
	if HasInputNodes then
		local InputAmount = object.inputNodeCount();
		--sb.logInfo("Input Amount = " .. sb.print(InputAmount));
		for i=0,InputAmount - 1 do
			local Level = object.getInputNodeLevel(i);
			--sb.logInfo("Level = " .. sb.print(Level));
			if Level == true then
				--sb.logInfo("Valid");
				goto Valid;
			end
		end
		--sb.logInfo("Not Valid");
		return false;
	end
	::Valid::
	local Container = Extraction.GetContainer();
	if Container ~= nil then
		local Item,Slot = Extraction.GetItemFromContainer(Container);
		if Item ~= nil then
			for _,Conduit in Extraction.InsertionConduitFinder() do
				if world.callScriptedEntity(Conduit,"PostExtract",Extraction,Item,Slot,Container) == 0 then
					return true;
				end
			end
		end
	end
end

--Resumes the coroutine and if an error occurs, then it will print it out
SafeResume = function(routine,...)
	local Value,Error = coroutine.resume(routine,...);
	if Error ~= nil then
		sb.logError(Error);
	end
end