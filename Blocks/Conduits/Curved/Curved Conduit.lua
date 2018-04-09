require("/Core/ConduitCore.lua");

--TODO

--Variables
local EdgePoints;
local CenterPoint;
local ConnectionPoints;

--Functions
local SetConnectionPoints;
local SpriteUpdate;
local TraversalFunction;

--The Init Function of the Curved Conduit
function init()
	
	ConduitCore.Initialize();
	SetConnectionPoints();
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
		local StartDistances = {Distance(StartPoint,vecAdd(ConnectionPoints[1],EntityPos)),Distance(StartPoint,vecAdd(ConnectionPoints[2],EntityPos))};
		if StartDistances[1] > StartDistances[2] then
			if UseEdge == true then
				EndPoint = vecAdd(EdgePoints[1],EntityPos);
			else
				EndPoint = vecAdd(ConnectionPoints[1],EntityPos);
			end
		else
			if UseEdge == true then
				EndPoint = vecAdd(EdgePoints[2],EntityPos);
			else
				EndPoint = vecAdd(ConnectionPoints[2],EntityPos);
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


--Sets the Connection Points for this specific curved Conduit
SetConnectionPoints = function()
	local ObjectName = object.name();
	local ConduitSize = tonumber(string.match(ObjectName,"%d+"));
	if     string.find(ObjectName,"bl$") ~= nil then
		ConnectionPoints = {{-1,ConduitSize - 1},{ConduitSize - 1,-1}};
		EdgePoints = {{-0.5,ConduitSize - 1},{ConduitSize - 1,-0.5}};
		CenterPoint = {-1,-1};
	elseif string.find(ObjectName,"br$") ~= nil then
		ConnectionPoints = {{ConduitSize,ConduitSize - 1},{0,-1}};
		EdgePoints = {{ConduitSize - 0.5,ConduitSize - 1},{0,-0.5}};
		CenterPoint = {ConduitSize,-1};
	elseif string.find(ObjectName,"tl$") ~= nil then
		ConnectionPoints = {{-1,0},{ConduitSize - 1,ConduitSize}};
		EdgePoints = {{-0.5,0},{ConduitSize - 1,ConduitSize - 0.5}};
		CenterPoint = {-1,ConduitSize};
	elseif string.find(ObjectName,"tr$") ~= nil then
		ConnectionPoints = {{ConduitSize,0},{0,ConduitSize}};
		EdgePoints = {{ConduitSize - 0.5,0},{0,ConduitSize - 0.5}};
		CenterPoint = {ConduitSize,ConduitSize};
	end
	ConduitCore.SetConnectionPoints(ConnectionPoints);
	ConduitCore.SetSpriteFunction(SpriteUpdate);
	ConduitCore.SetTraversalFunction(TraversalFunction);
end

TraversalFunction = function(SourceTraversalID,StartPosition,NextID,Speed)
	local NextConduit = world.callScriptedEntity(SourceTraversalID,"Traversal.GetAtPathIndex",2);
	if world.entityExists(NextConduit) == true then
		if world.getObjectParameter(NextConduit,"conduitType") == "curved" then
			--SetTraversalFromCurve(true,1);
			return GetCurveFunction(world.entityPosition(SourceTraversalID),nil,Speed,true);
		else
			--SetTraversalFromCurve(false,2);
			world.callScriptedEntity(SourceTraversalID,"Traversal.AdvancePathIndex");
			return GetCurveFunction(world.entityPosition(SourceTraversalID),nil,Speed,false);
		end
	else
		return nil;
	end
end

--Called when the sprite needs updating
SpriteUpdate = function()
	local Connections = ConduitCore.GetGlobalConnections();
	
	
	if Connections[1] ~= 0 and Connections[2] ~= 0 then
		animator.setAnimationState("curveState","3");
	elseif Connections[1] ~= 0 and Connections[2] == 0 then
		animator.setAnimationState("curveState","2");
	elseif Connections[1] == 0 and Connections[2] ~= 0 then
		animator.setAnimationState("curveState","1");
	elseif Connections[1] == 0 and Connections[2] == 0 then
		animator.setAnimationState("curveState","0");
	end
end
