Creator = {};
local Creator = Creator;

function Creator.Create(CanvasName,Position,ListImages,List)
	local InactiveSize = root.imageSize(ListImages.Inactive);
	local ActiveSize = root.imageSize(ListImages.Active);
	local SelectedSize = root.imageSize(ListImages.Selected);

	local ElementSize = {math.max(InactiveSize[1],ActiveSize[1],SelectedSize[1]),math.max(InactiveSize[2],ActiveSize[2],SelectedSize[2])};

	local Element = CreateElement(CanvasName);

	Element.AddSprite("Image",{0,0,ElementSize[1],ElementSize[2]},ListImages.Active);
	Element.SetPosition(Position or {0,0});
	Element.SetImageType = function(type)
		type = string.lower(type);
		if type == "inactive" then
			Element.SetSpriteImage("Image",ListImages.Inactive);
		elseif type == "active" then
			Element.SetSpriteImage("Image",ListImages.Active);
		elseif type == "selected" then
			Element.SetSpriteImage("Image",ListImages.Selected);
		end
	end

	Element.SetSpriteClickFunction("Image",function(Position,MouseType,IsDown)
		if MouseType == 0 and IsDown == true then
			List.SetSelectedElement(Element);
			Element.SetImageType("selected");
		end
	end);
	return Element;
end