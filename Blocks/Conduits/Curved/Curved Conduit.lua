local Cables = nil;

local NewFunc = nil;
local OldFunc = nil;
local CenterPoint = nil;
local CableConnections = nil;

local ConduitSize = nil;

local EdgePoints = nil;

local function AfterFunction()
	if Cables.CablesFound[1] ~= nil and Cables.CablesFound[2] ~= nil then
		animator.setAnimationState("curveState","3");
	elseif Cables.CablesFound[1] ~= nil and Cables.CablesFound[2] == nil then
		animator.setAnimationState("curveState","2");
	elseif Cables.CablesFound[1] == nil and Cables.CablesFound[2] ~= nil then
		animator.setAnimationState("curveState","1");
	elseif Cables.CablesFound[1] == nil and Cables.CablesFound[2] == nil then
		animator.setAnimationState("curveState","0");
	end
end

local function Distance(A,B)
	if B == nil then
		return ((A[1] ^ 2) + (A[2] ^ 2)) ^ 0.5;
	else
		return (((A[1] - B[1]) ^ 2) + ((A[2] - B[2]) ^ 2)) ^ 0.5;
	end
end

local function vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2]};
end

local function vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

local function vecNormalize(A)
	local dist = Distance(A);
	return {A[1] / dist,A[2] / dist};
end

local function Lerp(A,B,t)
	return {A[1] + (B[1] - A[1]) * t,A[2] + (B[2] - A[2]) * t};
end

local function Bezier(A,t)
	local NewList = {};
	for i=1,#A - 1 do
		NewList[#NewList + 1] = Lerp(A[i],A[i + 1],t);
	end
	if #NewList == 1 then
		return NewList[1];
	else
		return Bezier(NewList,t);
	end
end

function GetCurveFunction(StartPoint,EndPoint,Speed,UseEdge)
	local EntityPos = entity.position();
	if EndPoint == nil then
		local StartDistances = {Distance(StartPoint,vecAdd(CableConnections[1],EntityPos)),Distance(StartPoint,vecAdd(CableConnections[2],EntityPos))};
		if StartDistances[1] > StartDistances[2] then
			if UseEdge == true then
				EndPoint = vecAdd(EdgePoints[1],EntityPos);
			else
				EndPoint = vecAdd(CableConnections[1],EntityPos);
			end
		else
			if UseEdge == true then
				EndPoint = vecAdd(EdgePoints[2],EntityPos);
			else
				EndPoint = vecAdd(CableConnections[2],EntityPos);
			end
		end
		EndPoint = vecAdd(EndPoint,{0.5,0.5});
	end

	local OtherCorners = {{StartPoint[1],EndPoint[2]},{EndPoint[1],StartPoint[2]}};
	local Distances = {Distance(OtherCorners[1],vecAdd(CenterPoint,EntityPos)),Distance(OtherCorners[2],vecAdd(CenterPoint,EntityPos))};
	local MainCenter = nil;
	local BezierPoint = nil;
	if Distances[1] < Distances[2] then
		MainCenter = OtherCorners[1];
		BezierPoint = OtherCorners[2];
	else
		MainCenter = OtherCorners[2];
		BezierPoint = OtherCorners[1];
	end
	BezierPoint = Lerp(MainCenter,BezierPoint,1 - 0.06);

	local BezierPoints = {StartPoint,BezierPoint,EndPoint};
	local Timer = 0;
	local DerivativeSpeed = Distance(Bezier(BezierPoints,0.0),Bezier(BezierPoints,0.01)) / 0.01;
	return function(dt)
		Timer = Timer + (Speed * dt / DerivativeSpeed);
		if Timer > 1 then
			Timer = 1;
		end
		local Result = Bezier(BezierPoints,Timer);
		local DeltaPoint = vecSub(Result,MainCenter);
		if Timer == 1 then
			return Result,math.atan(DeltaPoint[2],DeltaPoint[1]),true;
		end
		return Result,math.atan(DeltaPoint[2],DeltaPoint[1]);
	end

end

local TraversalPathFunction = function(SourceTraversalID,StartPosition,NextID,Speed)
	local NextConduit = world.callScriptedEntity(SourceTraversalID,"GetConduitInPath",2);

	if world.entityExists(NextConduit) == true then
		if world.getObjectParameter(NextConduit,"conduitType") == "curved" then
			--SetTraversalFromCurve(true,1);
			return GetCurveFunction(world.entityPosition(SourceTraversalID),nil,Speed,true);
		else
			--SetTraversalFromCurve(false,2);
			world.callScriptedEntity(SourceTraversalID,"GoToNextConduit");
			return GetCurveFunction(world.entityPosition(SourceTraversalID),nil,Speed,false);
		end
	else
		return nil;
	end
end

function init()
	Cables = CableCore;
	OldFunc = GetConduits;
	GetConduits = function()
		return OldFunc();
	end
	local ObjectName = object.name();
	ConduitSize = tonumber(string.match(ObjectName,"%d+"));
	CableConnections = {};
	if     string.find(ObjectName,"bl$") ~= nil then
		CableConnections = {{-1,ConduitSize - 1},{ConduitSize - 1,-1}};
		EdgePoints = {{-0.5,ConduitSize - 1},{ConduitSize - 1,-0.5}};
		CenterPoint = {-1,-1};
	elseif string.find(ObjectName,"br$") ~= nil then
		CableConnections = {{ConduitSize,ConduitSize - 1},{0,-1}};
		EdgePoints = {{ConduitSize - 0.5,ConduitSize - 1},{0,-0.5}};
		CenterPoint = {ConduitSize,-1};
	elseif string.find(ObjectName,"tl$") ~= nil then
		CableConnections = {{-1,0},{ConduitSize - 1,ConduitSize}};
		EdgePoints = {{-0.5,0},{ConduitSize - 1,ConduitSize - 0.5}};
		CenterPoint = {-1,ConduitSize};
	elseif string.find(ObjectName,"tr$") ~= nil then
		CableConnections = {{ConduitSize,0},{0,ConduitSize}};
		EdgePoints = {{ConduitSize - 0.5,0},{0,ConduitSize - 0.5}};
		CenterPoint = {ConduitSize,ConduitSize};
	end
	Cables.SetCableConnections(CableConnections);
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.SetAfterFunction(AfterFunction);
	Cables.SetTraversalPathFunction(TraversalPathFunction);
end

local First = false;

function update(dt)
	DT = dt;
	if First == false then
		First = true;
		Cables.Initialize();
	end
end

function uninit()
	Cables.UpdateOthers();
end

function die()
	Cables.Uninitialize();
end
