require("/Core/UICore.lua");
--Declaration
RWindow = {};

--Variables
local GUIConfig;
local Elements = {};

--Functions
local Update;

function RWindow.Initialize()
	GUIConfig = config.getParameter("gui");
	for elementName,element in pairs(GUIConfig) do
		sb.logInfo("Element = " .. sb.print(elementName));
		sb.logInfo("Data = " .. sb.print(element));
		sb.logInfo("Size = " .. sb.print(widget.getSize(elementName)));
		sb.logInfo("Position = " .. sb.print(widget.getPosition(elementName)));
		if widget.getPosition(elementName) ~= nil then
			Elements[elementName] = {
				Position = widget.getPosition(elementName),
				Size = widget.getSize(elementName),
			}
		end
	end


	local OldUpdate = update;
	update = function(dt)
		if OldUpdate ~= nil then
			OldUpdate(dt);
		end
		Update(dt);
	end
end

Update = function(dt)
	for elementName,element in pairs(Elements) do
		widget.setPosition(elementName,{element.Position[1] + 1,element.Position[2]});
		element.Position[1] = element.Position[1] + 1;
	end
	widget.setImage("background","/Blocks/Crafting Terminal/UI/Window/Test/MassiveBackground.png");
end


