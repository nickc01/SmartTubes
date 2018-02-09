local Traverser = nil;
local Started = false;
local PossibleConduits = {};
local SideLimits = {};
local ConduitLimits;
local Path;
local SourceID;
local Speed;
local PathIndex = 1;
local ContainerID;
local EntityID;
local DroppingItems = nil;
local LastPosition = nil;

local ENTITYID;

local ReRoutedPath = nil;
local ReRoutedID = nil;
local RedirectionIsCurved = false;
local RedirectPathNumber = 0;

local Limits;

local ApplyLimits;

local function AddItemToDrop(_,_,Item)
	if DroppingItems == nil then
		DroppingItems = {};
	end
	DroppingItems[#DroppingItems + 1] = Item;
end

function ForceDestroy()
	projectile.die();
end

local function SetSource(_,_,NewSource)
	SourceID = NewSource;
	--sb.logInfo("NEWID_E ___________________________________________ = " .. sb.print(SourceID));
	--PossibleConduits[#PossibleConduits + 1] = NewSource;
end

function init()
	message.setHandler("AddItemToDrop",AddItemToDrop);
	message.setHandler("SetSource",SetSource);
	LastPosition = entity.position();
	ENTITYID = entity.id();
	sb.logInfo("Creating Traversal of " .. sb.print(entity.id()));
end

local function Finish()
	--sb.logInfo("Finished Traversing");
	sb.logInfo(sb.print(entity.id()) .. " adding to inventory to " .. sb.print(SourceID));
	world.sendEntityMessage(SourceID,"AddToInventory",EntityID,ContainerID);
	projectile.die();
	sb.logInfo(sb.print(entity.id()) .. " finished");
	return nil;
end

--[[local function RecalculatePath(StartingPoint)

end--]]

local function Drop()
	sb.logInfo(sb.print(entity.id()) .. " dropping to " .. sb.print(SourceID));
	world.sendEntityMessage(SourceID,"DropItems",EntityID,ContainerID,entity.position());
	if DroppingItems ~= nil then
		local Position = entity.position();
		for i=1,#DroppingItems do
			--sb.logInfo("DROPPINGH");
			world.spawnItem(DroppingItems[i],Position,DroppingItems[i].count,DroppingItems[i].parameters);
		end
	end
	DroppingItems = nil;
	projectile.die();
	return nil;
end

function ChangeContainer(NewContainer)
	ContainerID = NewContainer;
end

local function RecalculatePath(StartingPoint)
	sb.logInfo(sb.print(entity.id()) .. " recalc");
	--sb.logInfo(stringTable(PossibleConduits,"PossibleConduits"));
	local StartingConduit = world.objectAt(StartingPoint);
	--sb.logInfo("StartingConduit = " .. StartingConduit);
	--sb.logInfo("Start is " .. sb.print(StartingPoint));
	if StartingConduit == nil then return nil end;
	local Findings = {{ID = StartingConduit}};
	local Next = {};
	local InsertConduits = {};
	local StartingConduits = world.callScriptedEntity(StartingConduit,"GetConduits");
	if StartingConduits == nil then return nil end;
	for i=1,#StartingConduits do
		if StartingConduits[i] ~= -10 then
			Next[#Next + 1] = {ID = StartingConduits[i],Previous = 1};
		end
	end
	--sb.logInfo("Conduits to Start = " .. #StartingConduits);
	--sb.logInfo("PossibleConduits = " .. sb.print(PossibleConduits));
	repeat
		local NewNext = {};
		for i=1,#Next do
			if world.entityExists(Next[i].ID) == true then
				local Conduits = world.callScriptedEntity(Next[i].ID,"GetConduits");
				for x=1,#Conduits do
					if Conduits[x] ~= -10 then
						local Valid = true;
						for y=1,#Findings do
							if Findings[y].ID == Conduits[x] then
								Valid = false;
								break;
							end
						end
						if Valid == true then
							for y=1,#NewNext do
								if NewNext[y].ID == Conduits[x] then
									Valid = false;
									break;
								end
							end
						end
						if Valid == true then
							NewNext[#NewNext + 1] = {ID = Conduits[x],Previous = #Findings + 1};
						end
					end
				end
				Findings[#Findings + 1] = Next[i];
				local InsertID = world.getObjectParameter(Next[i].ID,"insertID");
				if InsertID ~= nil and world.callScriptedEntity(Next[i].ID,"ContainerCount") > 0 then
					for k,v in ipairs(PossibleConduits) do
						if Next[i].ID == v then
							InsertConduits[#InsertConduits + 1] = Next[i];
							break;
						end
					end
				end
			end
		end
		Next = NewNext;
	until #Next == 0;
	if #InsertConduits == 0 then return nil end;
	local SelectedInsertionConduit = InsertConduits[math.random(1,#InsertConduits)];
	--SourceID = SelectedInsertionConduit;
	local NextLevel = SelectedInsertionConduit.Previous;
	local Path = {SelectedInsertionConduit.ID};
	repeat
		local Point = Findings[NextLevel];
		Path[#Path + 1] = Point.ID;
		NextLevel = Point.Previous;
	until NextLevel == nil
	--sb.logInfo("RB");
	return Path,SelectedInsertionConduit.ID;
end

local ResetTraversal;
local function SetTraversalFromCurve(UseEdge,DecreaseAmount)
	local Iterator = world.callScriptedEntity(Path[PathIndex - 1],"GetCurveFunction",entity.position(),nil,Speed,UseEdge);
	Traverser = function()
		local Point,Rotation = Iterator();
		if Point == nil or world.entityExists(Path[PathIndex - 1]) == false then
			Traverser = nil;
			PathIndex = PathIndex - DecreaseAmount;
			ResetTraversal();
			return nil;
		else
			mcontroller.setRotation(Rotation);
			mcontroller.setPosition(Point);
		end
	end
end

ResetTraversal = function()
	--[[if DroppingItems ~= nil then
		for i=1,#DroppingItems do
			--sb.logInfo("DROPPING");
			world.spawnItem(DroppingItems[i],LastPosition,DroppingItems[i].count,DroppingItems[i].parameters);
		end
		projectile.die();
		return nil;
	end--]]
	LastPosition = entity.position();
	if PathIndex == 1 then
		--Finish();
		--return nil;
		if Path[PathIndex] == SourceID and DroppingItems == nil then
			return Finish();
		else
			--sb.logInfo("DROPA");
			return Drop();
		end
	end
	--if world.entityExists(Path[PathIndex]) == false then return Drop() end;
	local Position = world.entityPosition(Path[PathIndex]);
	if Position == nil or world.getObjectParameter(Path[PathIndex],"conduitType") == nil then
		--return nil;
		--sb.logInfo("DROPB");
		return Drop();
	end
	local StartX = Position[1] + 0.5;
	local StartY = Position[2] + 0.5;
	--[[if ReRouting == true then
		ReRouting = false;
		Path,SourceID = RecalculatePath(Position);
	end--]]
	--if world.entityExists(Path[PathIndex - 1]) == false then return Drop() end;
	local EndPosition = world.entityPosition(Path[PathIndex - 1]);
	if EndPosition == nil or world.getObjectParameter(Path[PathIndex - 1],"conduitType") == nil then
		local NewID;
		local NewPath;
		--sb.logInfo("PositionC = " .. sb.print(Position));
		NewPath,NewID = RecalculatePath(Position);
		--sb.logInfo("Path = " .. sb.print(Path[PathIndex]));
		if NewPath == nil or (world.entityExists(Path[PathIndex]) == true and world.getObjectParameter(Path[PathIndex],"conduitType") == "curved") then
			--return nil;
			--sb.logInfo("DROPC");
			return Drop();
		end
		Path = NewPath;
		SourceID = NewID;
		--sb.logInfo("NEWID_D ___________________________________________ = " .. sb.print(SourceID));
		PathIndex = #Path;
		EndPosition = world.entityPosition(Path[PathIndex - 1]);
		if EndPosition == nil or world.getObjectParameter(Path[PathIndex - 1],"conduitType") == nil then
			--Drop();
			--return nil;
			--sb.logInfo("DROPD");
			return Drop();
		end
	end
	local EndX = EndPosition[1] + 0.5;
	local EndY = EndPosition[2] + 0.5;
	local Timer = 0;
	mcontroller.setXVelocity(0);
	mcontroller.setYVelocity(0);
	if world.getObjectParameter(Path[PathIndex],"conduitType") == "sender" then
		if world.callScriptedEntity(Path[PathIndex],"IsConnectedWirelesslyTo",Path[PathIndex - 1]) == true then
			local NewTraversal = world.spawnProjectile(projectile.getParameter("projectileName"),{EndX,EndY},SourceID);
			world.sendEntityMessage(SourceID,"ChangeTransferID",EntityID,NewTraversal,ContainerID);
			--sb.logInfo("SourceID Before = " .. sb.print(SourceID));
			world.callScriptedEntity(NewTraversal,"StartTraversing",Path,Speed,ContainerID,PathIndex - 1,SourceID,PossibleConduits,ConduitLimits,SideLimits);
			projectile.die();
			return nil;
		else
			--sb.logInfo("DROPE");
			--return Drop();
			mcontroller.setXVelocity((EndX - StartX) * Speed);
			mcontroller.setYVelocity((EndY - StartY) * Speed);
			Traverser = function(dt)
				Timer = Timer + (dt * Speed);
				if Timer > 1 then
					PathIndex = PathIndex - 1;
					Traverser = nil;
					mcontroller.setXPosition(EndX);
					mcontroller.setYPosition(EndY);
					ResetTraversal();
					return nil;
				end
			end
		end
	end
	if world.getObjectParameter(Path[PathIndex - 1],"conduitType") == "curved" then
		if world.getObjectParameter(Path[PathIndex],"conduitType") == "curved" then
			--TODO
			if world.entityExists(Path[PathIndex - 2]) == true then
				if world.getObjectParameter(Path[PathIndex - 2],"conduitType") == "curved" then
					--[[local Iterator = world.callScriptedEntity(Path[PathIndex - 1],"GetCurveFunction",entity.position(),nil,Speed,true);
					Traverser = function()
						local Point,Rotation = Iterator();
						if Point == nil or world.entityExists(Path[PathIndex - 1]) == false then
							Traverser = nil;
							PathIndex = PathIndex - 1;
							ResetTraversal();
							return nil;
						else
							mcontroller.setRotation(Rotation);
							mcontroller.setPosition(Point);
						end
					end--]]
					SetTraversalFromCurve(true,1);
				else
					--[[local Iterator = world.callScriptedEntity(Path[PathIndex - 1],"GetCurveFunction",entity.position(),nil,Speed,false);
					Traverser = function()
						local Point,Rotation = Iterator();
						if Point == nil or world.entityExists(Path[PathIndex - 1]) == false then
							Traverser = nil;
							PathIndex = PathIndex - 2;
							ResetTraversal();
							return nil;
						else
							mcontroller.setRotation(Rotation);
							mcontroller.setPosition(Point);
						end
					end--]]
					SetTraversalFromCurve(false,2);
				end
			else
				--sb.logInfo("DROPF");
				return Drop();
			end
		else
			if world.entityExists(Path[PathIndex - 2]) == true then
				if world.getObjectParameter(Path[PathIndex - 2],"conduitType") == "curved" then
					--[[local Iterator = world.callScriptedEntity(Path[PathIndex - 1],"GetCurveFunction",entity.position(),nil,Speed,true);
					Traverser = function()
						local Point,Rotation = Iterator();
						if Point == nil or world.entityExists(Path[PathIndex - 1]) == false then
							Traverser = nil;
							PathIndex = PathIndex - 1;
							ResetTraversal();
							return nil;
						else
							mcontroller.setRotation(Rotation);
							mcontroller.setPosition(Point);
						end
					--]]
					SetTraversalFromCurve(true,1);
				else
					--[[local Iterator = world.callScriptedEntity(Path[PathIndex - 1],"GetCurveFunction",entity.position(),nil,Speed,false);
					Traverser = function()
						local Point,Rotation = Iterator();
						if Point == nil or world.entityExists(Path[PathIndex - 1]) == false then
							Traverser = nil;
							PathIndex = PathIndex - 2;
							ResetTraversal();
							return nil;
						else
							mcontroller.setRotation(Rotation);
							mcontroller.setPosition(Point);
						end
					end--]]
					SetTraversalFromCurve(false,2);
				end
			else
				--sb.logInfo("DROPG");
				return Drop();
			end
		end
	else
		mcontroller.setXVelocity((EndX - StartX) * Speed);
		mcontroller.setYVelocity((EndY - StartY) * Speed);
		Traverser = function(dt)
			Timer = Timer + (dt * Speed);
			if Timer > 1 then
				PathIndex = PathIndex - 1;
				Traverser = nil;
				mcontroller.setXPosition(EndX);
				mcontroller.setYPosition(EndY);
				ResetTraversal();
				return nil;
			end
		end
	end
end
function StartCramming()
	local Position = entity.position();
	projectile.die();
	return {Path = Path,Index = PathIndex,Speed = Speed,Position = Position};
end
local ReRouting = false;
function ReRoute(possibleConduits,removePossiblity)
	--sb.logInfo("CALLING REROUTED _____________________________");
	if ReRouting == false then
		ReRouting = true;
		--[[PossibleConduits = {};
		sb.logInfo("Possibilites Before = " .. sb.print(possibleConduits));
		for i=1,#possibleConduits do
			if possibleConduits[i] ~= removePossiblity then
				PossibleConduits[#PossibleConduits + 1] = possibleConduits[i];
			end
		end--]]
		--sb.logInfo("Possibilites Before = " .. sb.print(PossibleConduits));
		ApplyLimits(possibleConduits,ConduitLimits,SideLimits,removePossiblity);

		--sb.logInfo("Possibilites After = " .. sb.print(PossibleConduits));
		--SourceID = NewSource;
		--sb.logInfo("NEWID_A ___________________________________________ = " .. sb.print(SourceID));
		if world.entityExists(Path[PathIndex]) == true and world.getObjectParameter(Path[PathIndex],"conduitType") ~= "curved" and world.entityExists(Path[PathIndex - 1]) == true and world.getObjectParameter(Path[PathIndex - 1],"conduitType") ~= "curved" then
			ReRoutedPath,ReRoutedID = RecalculatePath(world.entityPosition(Path[PathIndex]));
		end
		--[[if world.entityExists(Path[PathIndex]) == true then
			if world.getObjectParameter(Path[PathIndex],"conduitType") == "curved" then
				for i=PathIndex,1,-1 do
					if world.entityExists(Path[i]) == true then
						if world.getObjectParameter(Path[PathIndex],"conduitType") ~= "curved" then
							ReRoutedPath,ReRoutedID = RecalculatePath(world.entityPosition(Path[i]));
							RedirectionIsCurved = true;
							RedirectPathNumber = i;
							break;
						end
					else
						break;
					end
				end
			else
				ReRoutedPath,ReRoutedID = RecalculatePath(world.entityPosition(Path[PathIndex]));
			end
		end-]]
		--sb.logInfo("DONE!");
		--sb.logInfo("Path = " .. sb.print(ReRoutedPath));
		--sb.logInfo("ID = " .. sb.print(ReRoutedID));
		return ReRoutedID;
	else
		return "done";
	end
end

function StartTraversing(path,speed,containerID,pathIndex,altID,possibleConduits,conduitLimits,sideLimits)
	sb.logInfo(sb.print(entity.id()) .. " starting traverse");
	EntityID = entity.id();
	Started = true;
	SourceID = altID or projectile.sourceEntity();
	--sb.logInfo("NEWID_B ___________________________________________ = " .. sb.print(SourceID));
	Path = path;
	ApplyLimits(possibleConduits,conduitLimits,sideLimits,nil);
	--PossibleConduits = possibleConduits;
	Speed = speed;
	if pathIndex == nil then
		PathIndex = #Path;
	else
		PathIndex = pathIndex;
	end
	ContainerID = containerID;
	ResetTraversal();
end

ApplyLimits = function(pConduits,cLimits,sLimits,exclusion)
	local Possibilites = {};
	for i=1,#pConduits do
		if pConduits[i] ~= exclusion and world.entityExists(pConduits[i]) == true then
			local InsertID = world.getObjectParameter(pConduits[i],"insertID");
			local Valid = false;
			if cLimits == "any" then
				Valid = true;
			else
				for _,v in ipairs(cLimits.Valid) do
					if v == "any" or v == InsertID then
						Valid = true;
						break;
					end
				end
				if Valid == true then
					for _,v in ipairs(cLimits.Invalid) do
						if v == "any" or v == InsertID then
							Valid = false;
							break;
						end
					end
				end
				if Valid == true then
					Possibilites[#Possibilites + 1] = pConduits[i];
				end
			end
		end
	end
	PossibleConduits = Possibilites;
	SideLimits = sLimits;
	ConduitLimits = cLimits;
	--[[local Possibilites = {};
	if conduitLimits ~= nil then
		for i=1,#possibleConduits do
			local Valid = false;
			if conduitLimits == "any" then 
				Valid ==
			end
			for j=1,#conduitLimits do
				
			end
		end
	else
		for i=1,#possibleConduits do
			if possibleConduits[i] ~= exclusion then
				Possibilites[#Possibilites + 1] = possibleConduits[i];
			end
		end
	end--]]
end

--[[function TransferData(path,PossibleConduits,speed,containerID,pathIndex)
	EntityID = entity.id();
	Started = true;
	SourceID = projectile.sourceEntity();
	Path = path;
	PossibleConduits = possibleConduits;
	Speed = speed;
	PathIndex = pathIndex;
	ContainerID = containerID;
	ResetTraversal();
end--]]

function GetSourceID()
	return SourceID;
end

function update(dt)
	if Started == false then
		projectile.die()
	end
	if world.material == nil then
		projectile.die();
		return nil;
	end
	if Traverser ~= nil then
		if ReRouting == true then
			--sb.logInfo("R is TRUE");
			ReRouting = false;
			if ReRoutedPath ~= nil then
				--sb.logInfo("REROUTED _____________________________");
				if RedirectionIsCurved == false then
					Path = ReRoutedPath;
					ReRoutedPath = nil;
					PathIndex = #Path;
					SourceID = ReRoutedID;
					--sb.logInfo("NEWID_C ___________________________________________ = " .. sb.print(SourceID));
					ReRoutedID = nil;
					ResetTraversal();
				else
					if PathIndex == RedirectPathNumber then
						Path = ReRoutedPath;
						ReRoutedPath = nil;
						PathIndex = #Path;
						SourceID = ReRoutedID;
						RedirectionIsCurved = false;
						RedirectPathNumber = 0;
						--sb.logInfo("NEWID_C ___________________________________________ = " .. sb.print(SourceID));
						ReRoutedID = nil;
						ResetTraversal();
					end
				end
			end
		end
		Traverser(dt);
	end
end

function uninit()
	sb.logInfo(sb.print(ENTITYID) .. " UNINIT");
end
