
--Variables
local SourceID;
local SlotItem;
local CopyText = "";
local CopyAble = false;

--Functions
local UpdateStats;
local SetCopyText;
local CopyableUpdated;

function init()
	SourceID = pane.sourceEntity();
end

function update(dt)
	local HasFocus = widget.hasFocus("copybox");
	if HasFocus ~= CopyAble then
		CopyAble = HasFocus;
		CopyableUpdated(CopyAble);
	end
end

--local function UpdateTags

UpdateStats = function()
	widget.setItemSlotItem("itemBox",SlotItem);
	if SlotItem == nil then
		--widget.setText("textArea.dataArea","");
		SetCopyText("");
	else
		local Config = root.itemConfig(SlotItem);
		local Data = Config.config;
		if SlotItem.parameters ~= nil then
			for name,data in pairs(SlotItem.parameters) do
				Data[name] = data;
			end
		end
		--widget.setText("textArea.dataArea",sb.printJson(Data,1));
		SetCopyText(Data);
	end
end

function itemBox()
	SlotItem = player.swapSlotItem();
	UpdateStats();
end

CopyableUpdated = function(copyable)
	sb.logInfo("Copyable Updated = " .. sb.print(copyable));
	widget.setVisible("copyDisplayText",copyable);
end

function itemBoxRight()
	SlotItem = nil;
	UpdateStats();
end

SetCopyText = function(text)
	if type(text) == "table" then
		CopyText = sb.printJson(text);
		sb.logInfo("CopyText = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",sb.printJson(text,1));
	else
		CopyText = text;
		sb.logInfo("CopyText = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",text);
	end
	__copybox__();
end

function __copybox__()
	if widget.getText("copybox") ~= CopyText then
		widget.blur("copybox");
	end
	widget.setText("copybox",CopyText);
	sb.logInfo("CopyBox = " .. sb.print(widget.getText("copybox")));
end

--Called when the copy button is clicked on
function copyButton()
	sb.logInfo("Copy Button");
	widget.focus("copybox");
end