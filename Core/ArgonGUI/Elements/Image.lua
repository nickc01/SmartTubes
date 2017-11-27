Creator = {};
local Creator = Creator;

function Creator.Create(CanvasName,Image,Position)
	local Element = CreateElement(CanvasName);
	local ImageSize = root.imageSize(Image);
	local Rect = {0,0,ImageSize[1],ImageSize[2]};
	Element.AddSprite("Image",Rect,Image);
	Element.SetPosition(Position or {0,0});
	Element.SetParentMode(true);
	Element.SetClippingBounds(Rect);
	return Element;
end
