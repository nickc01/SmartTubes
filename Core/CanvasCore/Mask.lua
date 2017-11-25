Creator = {};
local Creator = Creator;


function Creator.Create(CanvasName,Rect)
	local Position = {Rect[1],Rect[2]};
	local Element = CreateElement(CanvasName);
	Element.SetPosition(Position);
	Element.SetParentMode(true);
	return Element.Finish();
end