require ("/Core/TraversalCore.lua");

--Variables

--Functions

--Initializes the Traversal
function init()
	
end

--The Update Loop for the Traversal
function update(dt)
	if not Traversal.IsInitialized() then
		projectile.die();
	end
end

--Called when the traversal dies
function die()
	
end

--Called when the traversal uninitializes
function uninit()
	
end