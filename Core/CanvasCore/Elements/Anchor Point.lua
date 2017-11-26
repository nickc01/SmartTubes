Creator = {};
local Creator = Creator;


function Creator.Create(CanvasName,Position)
	local Element = CreateElement(CanvasName);
	Element.SetPosition(Position);
	Element.SetParentMode(true);
	return Element;
end
