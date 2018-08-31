
--Declaration
RWindow = {};

--Variables
local GUIConfig;

--Functions

function RWindow.Initialize()
	GUIConfig = config.getParameter("gui");
	for elementName,element in pairs(GUIConfig) do
		sb.logInfo("Element = " .. sb.print(elementName));
		sb.logInfo("Data = " .. sb.print(element));
		sb.logInfo("Size = " .. sb.print(widget.getSize(elementName)));
		sb.logInfo("Position = " .. sb.print(widget.getPosition(elementName)));
	end
end
