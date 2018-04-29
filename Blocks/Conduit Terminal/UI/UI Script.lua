require("/Core/Conduit Scripts/Terminal/TerminalUI.lua");

--Variables
local Clicking

--Functions
local BackgroundClick;
local ClickRelease;
local ClickingBackground = false;
local Offset;
local PreviousMousePosition;

--The init function for the Terminal UI Script
function init()
	TerminalUI.Initialize();
	--ViewWindow.AddBackgroundClickEvent(BackgroundClick);
	--ViewWindow.AddMouseReleaseFunction(ClickRelease);
end

--The update function for the Terminal UI Script
function update()
	--ViewWindow.RenderImage("/Blocks/Conduit Terminal/Terminal.png",{0,0});
	--ViewWindow.RenderObject(pane.sourceEntity(),{0,0});
	--ViewWindow.RenderConduit(pane.sourceEntity());
	--if ClickingBackground then
	--	local NewMousePosition = ViewWindow.MousePosition();
		--ViewWindow.SetPosition(NewMousePosition);
	--	ViewWindow.SetPosition({Offset[1] + NewMousePosition[1],Offset[2] + NewMousePosition[2]});
	--end
end


--Called when the background is clicked on
--[[BackgroundClick = function()
	--OriginalPosition = ViewWindow.Position();
	--PreviousMousePosition = ViewWindow.MousePosition();
	local Position = ViewWindow.Position();
	local MousePosition = ViewWindow.MousePosition();
	Offset = {Position[1] - MousePosition[1],Position[2] - MousePosition[2]};
	ClickingBackground = true;
end--]]

--Called when the mouse is released
--[[ClickRelease = function()
	ClickingBackground = false;
end--]]