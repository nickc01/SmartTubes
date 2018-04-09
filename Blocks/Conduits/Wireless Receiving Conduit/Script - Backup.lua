local Cables;

local WirelessUpdated = false;

local WirelessBuffer = nil;

local function UniIter(t)
	for _,_ in ipairs(t) do
		return ipairs(t);
	end
	return pairs(t);
end

local function GetWirelessConnectedConduits()
	
	if object.isInputNodeConnected(0) == true then
		local Inputs = object.getInputNodeIds(0);
		
		local Final = {};
		for i,_ in UniIter(Inputs) do
			if world.getObjectParameter(i,"conduitType") == "sender" then
				Final[#Final + 1] = i;
			end
		end
		if #Final == 0 then
			return nil;
		end
		return Final;
	end
	return nil;
end

local TraversalPathFunction = function(SourceTraversalID,PreviousPosition,PreviousID,Speed)
	local EndPosition = entity.position();
	if IsConnectedWirelesslyTo(PreviousID) then
		return function(dt)
			world.callScriptedEntity(SourceTraversalID,"Respawn",{EndPosition[1] + 0.5,EndPosition[2] + 0.5},1);
			return nil;
		end
	else
		if IsConnectedTo(PreviousID) then
			return CableCore.GetDefaultTraversalFunction()(SourceTraversalID,PreviousPosition,PreviousID,Speed);
		end
	end
end

function init()
	Cables = CableCore;
	--local OldGetConduits = GetConduits;
	Cables.SetConduitsFunction(function()
		local Final = {};
		local NearbyConduits = CableCore.GetConduitsDefault();
		if WirelessUpdated == false then
			WirelessUpdated = true;
			WirelessBuffer = GetWirelessConnectedConduits();
		end
		local WirelessConduits = WirelessBuffer;
		for k,i in ipairs(NearbyConduits) do
			Final[#Final + 1] = i;
		end
		if WirelessConduits ~= nil then
			for k,i in ipairs(WirelessConduits) do
				Final[#Final + 1] = i;
			end
		end
		return Final;
	end);
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.SetTraversalPathFunction(TraversalPathFunction);
	--Cables.Initialize();
end

local First = false;
function update(dt)
	if First == false then
		First = true;
		Cables.Initialize();
	end
end

function IsConnectedWirelesslyTo(ID)
	if WirelessUpdated == false then
		WirelessUpdated = true;
		WirelessBuffer = GetWirelessConnectedConduits();
	end
	if WirelessBuffer == nil then return false end;
	for _,i in ipairs(WirelessBuffer) do
		if i == ID then
			return true;
		end
	end
	return false;
end

function onNodeConnectionChange(args)
	
	Cables.UpdateExtractionConduits();
	WirelessBuffer = GetWirelessConnectedConduits();
end

function die()
	Cables.Uninitialize();
end
