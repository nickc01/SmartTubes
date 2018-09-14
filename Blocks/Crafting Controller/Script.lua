require("/Core/ConduitCore.lua");
require("/Core/CraftingController.lua");
--Variables

--Functions

--the init function for the crafting controller
function init()
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.Initialize();
	Controller.Initialize();
end
