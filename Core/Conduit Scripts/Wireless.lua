--require("/Core/ConduitCore.lua");

--Declaration

--Public Table
Wireless = {};
local Wireless = Wireless;

--Variables
local InputCache;
local OutputCache;
local NodeChangeFunctions;

--Functions
local UniIter;
local TblEqual;

--Returns all the input connection for this 
function Wireless.GetInputConnections()
	if object.isInputNodeConnected(0) then
		--if InputCache == nil then
			local Nodes = object.getInputNodeIds(0);
			local Final = {};
			for i,_ in UniIter(Nodes) do
				Final[#Final + 1] = tonumber(i);
			end
			if InputCache ~= nil and not TblEqual(InputCache,Final) then
				--sb.logInfo("Updated = " .. sb.print(entity.id()));
				--sb.logInfo("Input Cache = " .. sb.print(InputCache));
				--sb.logInfo("Final = " .. sb.print(Final));
				--sb.logInfo("Equal = " .. sb.print(TblEqual(InputCache,Final)));
				InputCache = Final;
				onNodeConnectionChange();
			else
				InputCache = Final;
			end
			--InputCache = Final;
		--end
		return InputCache;
	end
end

--Returns all the output connection for this 
function Wireless.GetOutputConnections()
	if object.isOutputNodeConnected(0) then
		--if OutputCache == nil then
			local Nodes = object.getOutputNodeIds(0);
			local Final = {};
			for i,_ in UniIter(Nodes) do
				Final[#Final + 1] = tonumber(i);
			end
			if OutputCache ~= nil and not TblEqual(OutputCache,Final) then
				--sb.logInfo("Updated = " .. sb.print(entity.id()));
				--sb.logInfo("Output Cache = " .. sb.print(OutputCache));
				--sb.logInfo("Final = " .. sb.print(Final));
				--sb.logInfo("Equal = " .. sb.print(TblEqual(OutputCache,Final)));
				OutputCache = Final;
				onNodeConnectionChange();
			else
				OutputCache = Final;
			end
			--OutputCache = Final;
		--end
		return OutputCache;
	end
end

--Adds a function that is called when the Node Connections are changed
function Wireless.AddNodeChangeFunction(func)
	if NodeChangeFunctions == nil then
		NodeChangeFunctions = {func};
	else
		NodeChangeFunctions[#NodeChangeFunctions + 1] = func;
	end
end

--Returns true if this object is connected to the Output ID and false otherwise
function Wireless.IsConnectedToOutput(ID)
	local Connections = Wireless.GetOutputConnections();
	if Connections ~= nil then
		for _,i in ipairs(Connections) do
			if ID == i then return true end;
		end
	end
	return false;
end

--Returns true if this object is connected to the Input ID and false otherwise
function Wireless.IsConnectedToInput(ID)
	local Connections = Wireless.GetInputConnections();
	if Connections ~= nil then
		for _,i in ipairs(Connections) do
			if ID == i then return true end;
		end
	end
	return false;
end

--An iterator that can iterate over any table
UniIter = function(tbl)
	local k,i = nil;
	return function()
		k,i = next(tbl,k);
		return k,i;
	end
end




--Called when the nodes are changed
function onNodeConnectionChange()
	InputCache = nil;
	OutputCache = nil;
	if ConduitCore ~= nil then
		ConduitCore.TriggerNetworkUpdate("Conduits");
		ConduitCore.TriggerNetworkUpdate("TerminalFindings");
	end
	
	if NodeChangeFunctions ~= nil then
		for _,func in ipairs(NodeChangeFunctions) do
			func();
		end
	end
end

--Returns true if the tables are equal and false otherwise
TblEqual = function(a,b)
	if jsize(a) ~= jsize(b) then
		--sb.logInfo("A");
		return false;
	else
		for i=1,#a do
			--[[for j=1,#b do
				if a[i] ~= b[j] then
					return false;
				end
			end--]]
			if a[i] ~= b[i] then
				return false;
			end
		end
		return true;
	end
end


