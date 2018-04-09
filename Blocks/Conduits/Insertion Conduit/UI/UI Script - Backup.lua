require("/Core/UICore.lua");

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
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	if OldInit ~= nil then
		OldInit();
	end
	InsertID = world.getObjectParameter(SourceID,"insertID","");
	InsertUUID = world.getObjectParameter(SourceID,"InsertUUID");
	widget.setText("insertionIDBox",InsertID);
	InsertIDCall = UICore.LoopCallContinuously(SourceID,InsertIDUpdated,"__UIGetInsertID__",function() return InsertUUID end);
end

--Called when the insert ID is updated
InsertIDUpdated = function(newInsertID,newInsertUUID)
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