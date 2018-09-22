Creator = {};
local Creator = Creator;


--[[
Images = 
{
	Normal,
	Pressed
]]
function Creator.Create(CanvasName,Position,Images,OnPress)
	local Element = CreateElement(CanvasName);
	Element.SetPosition(Position);

	local NormalSize = root.imageSize(Images.Normal);
	local PressedSize = root.imageSize(Images.Pressed);

	local Rect = {0,0,math.max(NormalSize[1],PressedSize[1]),math.max(NormalSize[2],PressedSize[2])};

	Element.AddSprite("Button",Rect,Images.Normal);

	local RadioMode = false;
	local RadioClick;

	Element.MakeRadioButton = function(bool,OnClick)
		RadioMode = bool;
		if bool == true then
			RadioClick = OnClick;
			Element.SetRadioImage = function(bool)
				if bool == true then
					Element.SetSpriteImage("Button",Images.Pressed);
				else
					Element.SetSpriteImage("Button",Images.Normal);
				end
			end
		else
			Element.SetRadioImage = nil;
		end
	end

	Element.SetSpriteClickFunction("Button",function(Position,MouseType,IsDown)
		if RadioMode == false then
			if MouseType == 0 then
				if OnPress == true then
					Element.SetSpriteImage("Button",Images.Pressed);
				else
					Element.SetSpriteImage("Button",Images.Normal);
				end
				if OnPress ~= nil then
					OnPress(IsDown);
				end
			end
		else
			if MouseType == 0 and IsDown == true then
				Element.SetRadioImage(true);
				if RadioClick ~= nil then
					RadioClick();
				end
			end
		end
	end);

	return Element;
end
