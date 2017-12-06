Creator = {};
local Creator = Creator;

function Creator.Create(CanvasName,Position)
	local Element = CreateElement(CanvasName);
	Element.SetPosition(Position);
	Element.SetParentMode(true,true);



	Element.AddControllerValue("AddButton",function(Position,Images,OnClick)

	end);


	return Element;
end
