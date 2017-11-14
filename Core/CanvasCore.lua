Canvas = {};

local Bindings = {};

function Canvas.Init()
	
end

function Canvas.GetBinding(bindingName)
	return Bindings[bindingName];
end

function Canvas.AddBinding(binding,bindingName)
	if Bindings[bindingName or binding] == nil then
		Bindings[bindingName or binding] = widget.bindCanvas(binding);
		if Bindings[bindingName or binding] == nil then
			error(sb.print(binding) .. " doesn't exist");
		end
	end
end

function Canvas.ClearBindings(binding,bindingName)
	Bindings = {};
end

function OnMouseClick(Position, MouseButton, MouseButtonDown)
	sb.logInfo("Clicked");
	sb.logInfo("Mouse Position = " .. sb.print(Position));
	sb.logInfo("Mouse Button = " .. sb.print(MouseButton));
	sb.logInfo("Mouse Button Down = " .. sb.print(MouseButtonDown));
end

function OnKeyPress(Key, KeyDown)
	sb.logInfo("KeyPress");
	sb.logInfo("Key = " .. sb.print(Key));
	sb.logInfo("KeyDown = " .. sb.print(KeyDown));
end
function canvasClickEvent(position, button, isButtonDown)
	sb.logInfo("MouseClick");
end

function canvasKeyEvent(key, isKeyDown)
	sb.logInfo("KeyPress");
end
