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
local ResetTraversal;

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
end

function init()
	message.setHandler("AddItemToDrop",AddItemToDrop);
	message.setHandler("SetSource",SetSource);
	ENTITYID = entity.id();
	
end

local function Finish()
	
	world.sendEntityMessage(SourceID,"AddToInventory",EntityID,ContainerID);
	projectile.die();
	
	return nil;
end

local function Drop()
	
	world.sendEntityMessage(SourceID,"DropItems",EntityID,ContainerID,entity.position());
	if DroppingItems ~= nil then
		local Position = entity.position();
		for i=1,#DroppingItems do
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
	
	local StartingConduit = world.objectAt(StartingPoint);
	if StartingConduit == nil then return nil end;
	local Findings = {{ID = StartingConduit}};
	local Next = {};
	local InsertConduits = {};
	local StartingConduits = world.callScriptedEntity(StartingConduit,"CableCore.GetConduits");
	if StartingConduits == nil then return nil end;
	for i=1,#StartingConduits do
		if StartingConduits[i] ~= -10 then
			Next[#Next + 1] = {ID = StartingConduits[i],Previous = 1};
		end
	end
	repeat
		local NewNext = {};
		for i=1,#Next do
			if world.entityExists(Next[i].ID) == true then
				local Conduits = world.callScriptedEntity(Next[i].ID,"CableCore.GetConduits");
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
	
	return Path,SelectedInsertionConduit.ID;
end
--[[local function SetTraversalFromCurve(UseEdge,DecreaseAmount)
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
end--]]

function Respawn(Position,ConduitAdvancement)
	ConduitAdvancement = ConduitAdvancement or 0;
	if ConduitAdvancement > -1 then
		if not (PathIndex - ConduitAdvancement > 0) then
			ConduitAdvancement = 0;
		end
	else
		if not (PathIndex - ConduitAdvancement <= #Path) then
			ConduitAdvancement = 0;
		end
	end
	local NewTraversal = world.spawnProjectile(projectile.getParameter("projectileName"),Position,SourceID);
	world.sendEntityMessage(SourceID,"ChangeTransferID",EntityID,NewTraversal,ContainerID);
	world.callScriptedEntity(NewTraversal,"StartTraversing",Path,Speed,ContainerID,PathIndex - ConduitAdvancement,SourceID,PossibleConduits,ConduitLimits,SideLimits);
	projectile.die();
	return NewTraversal;
end

function GoToNextConduit(Amount)
	Amount = Amount or 1;
	if Amount > -1 then
		if PathIndex - Amount > 0 then
			PathIndex = PathIndex - Amount;
		end
	else
		if PathIndex - Amount <= #Path then
			PathIndex = PathIndex - Amount;
		end
	end
end

function GetConduitInPath(Amount)
	Amount = Amount or 1;
	if Amount > -1 then
		if PathIndex - Amount > 0 then
			return Path[PathIndex - Amount];
		end
	else
		if PathIndex - Amount <= #Path then
			return Path[PathIndex - Amount];
		end
	end
end

ResetTraversal = function()
	if PathIndex == 1 then
		if Path[PathIndex] == SourceID and DroppingItems == nil then
			return Finish();
		else
			return Drop();
		end
	end
	local PreviousPosition = world.entityPosition(Path[PathIndex]);
	if PreviousPosition == nil or world.getObjectParameter(Path[PathIndex],"conduitType") == nil then
		return Drop();
	end
	local CallingConduit = Path[PathIndex - 1];
	if not world.entityExists(CallingConduit) then
		local NewID;
		local NewPath;
		NewPath,NewID = RecalculatePath(PreviousPosition);
		if NewPath == nil then
			return Drop();
		end
		Path = NewPath;
		SourceID = NewID;
		PathIndex = #Path;
		CallingConduit = Path[PathIndex - 1];
		--EndPosition = world.entityPosition(Path[PathIndex - 1]);
		if not world.entityExists(CallingConduit) or world.getObjectParameter(CallingConduit,"conduitType") == nil then
			return Drop();
		end
		--return Drop();
	end
	local Func = world.callScriptedEntity(CallingConduit,"CableCore.GetTraversalPath",EntityID,PreviousPosition,Path[PathIndex],Speed);
	if Func == nil then
		return Drop();
	end
	Traverser = function(dt)
		if not world.entityExists(CallingConduit) then
			return Drop();
		end
		local Pos,Rotation,Stop = Func(dt);
		if Pos == nil then return nil end;
		if Stop == true then
			mcontroller.setPosition(Pos);
			if Rotation ~= nil then
				mcontroller.setRotation(Rotation);
			end
			PathIndex = PathIndex - 1;
			ResetTraversal();
			return nil;
		else
			mcontroller.setPosition(Pos);
			if Rotation ~= nil then
				mcontroller.setRotation(Rotation);
			end
		end
	end




	--OLD CODE
	--[[return nil;

	if PathIndex == 1 then
		if Path[PathIndex] == SourceID and DroppingItems == nil then
			return Finish();
		else
			return Drop();
		end
	end
	local Position = world.entityPosition(Path[PathIndex]);
	if Position == nil or world.getObjectParameter(Path[PathIndex],"conduitType") == nil then
		return Drop();
	end
	local StartX = Position[1] + 0.5;
	local StartY = Position[2] + 0.5;
	local EndPosition = world.entityPosition(Path[PathIndex - 1]);
	if EndPosition == nil or world.getObjectParameter(Path[PathIndex - 1],"conduitType") == nil then
		local NewID;
		local NewPath;
		NewPath,NewID = RecalculatePath(Position);
		if NewPath == nil or (world.entityExists(Path[PathIndex]) == true and world.getObjectParameter(Path[PathIndex],"conduitType") == "curved") then
			return Drop();
		end
		Path = NewPath;
		SourceID = NewID;
		PathIndex = #Path;
		EndPosition = world.entityPosition(Path[PathIndex - 1]);
		if EndPosition == nil or world.getObjectParameter(Path[PathIndex - 1],"conduitType") == nil then
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
			Respawn({EndX,EndY});
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
	if world.getObjectParameter(Path[PathIndex - 1],"conduitType") == "curved" then
		if world.getObjectParameter(Path[PathIndex],"conduitType") == "curved" then
			if world.entityExists(Path[PathIndex - 2]) == true then
				if world.getObjectParameter(Path[PathIndex - 2],"conduitType") == "curved" then
					SetTraversalFromCurve(true,1);
				else
					SetTraversalFromCurve(false,2);
				end
			else
				return Drop();
			end
		else
			if world.entityExists(Path[PathIndex - 2]) == true then
				if world.getObjectParameter(Path[PathIndex - 2],"conduitType") == "curved" then
					SetTraversalFromCurve(true,1);
				else
					SetTraversalFromCurve(false,2);
				end
			else
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
	end--]]
end
function StartCramming()
	local Position = entity.position();
	projectile.die();
	return {Path = Path,Index = PathIndex,Speed = Speed,Position = Position};
end
local ReRouting = false;
function ReRoute(possibleConduits,removePossiblity)
	if ReRouting == false then
		ReRouting = true;
		ApplyLimits(possibleConduits,ConduitLimits,SideLimits,removePossiblity);
		if world.entityExists(Path[PathIndex]) == true and world.getObjectParameter(Path[PathIndex],"conduitType") ~= "curved" and world.entityExists(Path[PathIndex - 1]) == true and world.getObjectParameter(Path[PathIndex - 1],"conduitType") ~= "curved" then
			ReRoutedPath,ReRoutedID = RecalculatePath(world.entityPosition(Path[PathIndex]));
		end
		return ReRoutedID;
	else
		return "done";
	end
end

function StartTraversing(path,speed,containerID,pathIndex,altID,possibleConduits,conduitLimits,sideLimits)
	
	EntityID = entity.id();
	Started = true;
	SourceID = altID or projectile.sourceEntity();
	Path = path;
	ApplyLimits(possibleConduits,conduitLimits,sideLimits,nil);
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
end

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
			ReRouting = false;
			if ReRoutedPath ~= nil then
				if RedirectionIsCurved == false then
					Path = ReRoutedPath;
					ReRoutedPath = nil;
					PathIndex = #Path;
					SourceID = ReRoutedID;
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
						ReRoutedID = nil;
						ResetTraversal();
					end
				end
			end
		end
		Traverser(dt);
	end
end

--[[function uninit()
	
end--]]
