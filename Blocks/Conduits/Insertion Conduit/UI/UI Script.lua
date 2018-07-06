require("/Core/UICore.lua");

--Public table
InsertionUI = {};

--Variables
local SourceID;
local InsertID;
local InsertUUID;
local InsertIDCall;

--Functions
local InsertIDUpdated;
local SetInsertID;
local OldInit = init;

--The init function of the Insertion UI
function init()
	--sb.logInfo(stringTable(_ENV,"Entire Script Table"));
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	if OldInit ~= nil then
		OldInit();
	end
	--UniqueID = sb.makeUuid();
	--sb.logInfo("Spawned = " .. sb.print(UniqueID));
	InsertID = world.getObjectParameter(SourceID,"insertID","");
	InsertUUID = world.getObjectParameter(SourceID,"InsertUUID");
	sb.logInfo("InsertID = " .. sb.print(InsertID));
	widget.setText("insertionIDBox",InsertID);
	InsertIDCall = UICore.LoopCallContinuously(SourceID,InsertIDUpdated,"__UIGetInsertID__",function() return InsertUUID end);
end

--Called when the insert ID is updated
InsertIDUpdated = function(newInsertID,newInsertUUID)
	--sb.logInfo()
	--sb.logInfo("InsertID Updated for = " .. sb.print(UniqueID));
	InsertID = newInsertID;
	InsertUUID = newInsertUUID;
	widget.setText("insertionIDBox",InsertID);
end

--Called when the text for the insertion id is updated
function UpdateInsertID()
	SetInsertID(widget.getText("insertionIDBox"));
end

--Sets the insertID
SetInsertID = function(id)
	if InsertID ~= id then
		InsertID = id;
		widget.setText("insertionIDBox",InsertID);
		InsertUUID = sb.makeUuid();
		world.sendEntityMessage(SourceID,"__UISetInsertID__",InsertID,InsertUUID);
		UICore.ResetLoopCall(InsertIDCall);
	end
end

function stringTable(table,name,spacer)
	if table == nil then return name ..  " = nil" end;
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		--else
			--startingString = startingString .. "	" .. k .. " = " .. 
		elseif type(i) == "function" then
				startingString = startingString .. "	" .. k .. " = (FUNC) " .. sb.print(i);
		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. sb.print(i) .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end

















--[[local SourceID;

local oldinit = init;
function init()
	if oldinit ~= nil then
		oldinit();
	end
	
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	widget.setText("insertionIDBox",world.getObjectParameter(SourceID,"insertID",""));
	widget.focus("insertionIDBox");
end

function UpdateInsertID()
	world.sendEntityMessage(SourceID,"SetInsertID",widget.getText("insertionIDBox"));
end--]]