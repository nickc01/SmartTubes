local SourceID;

local oldinit = init;
function init()
	if oldinit ~= nil then
		oldinit();
	end
	sb.logInfo("Insertion UI");
	SourceID = config.getParameter("MainObject");
	if SourceID == nil then
		SourceID = pane.sourceEntity();
	end
	widget.setText("insertionIDBox",world.getObjectParameter(SourceID,"insertID",""));
	widget.focus("insertionIDBox");
end

function UpdateInsertID()
	world.sendEntityMessage(SourceID,"SetInsertID",widget.getText("insertionIDBox"));
end