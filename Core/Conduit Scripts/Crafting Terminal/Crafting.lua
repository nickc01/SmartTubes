require("/Core/ConduitCore.lua");

--Declaration
Crafting = {};
local Crafting = Crafting;

--Variables

--Functions

--Initializes the Crafting Terminal
function Crafting.Initialize()
	ConduitCore.SetConnectionPoints({{0,-1},{-1,0},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	ConduitCore.Initialize();
end