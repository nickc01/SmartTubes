Groups = {};
local Groups = Groups;

local SpawnedGroups = {};

function Groups.Find(Identifier)
	
end

function Groups.Uninit()
	
end


function Groups.New(Identifier)
	if type(Identifier) ~= "number" then
		error("Identifier should be a number");
	end
	if SpawnedGroups[Identifier] ~= nil then
		error("This Identifier is already registered");
	end
	local Group = {};
	SpawnedGroups[Identifier] = Group;

	--Group Data

	local ID = nil;
	local Master = nil;

	Group.SetObjectID = function(ObjectID)
		if ID == ObjectID then
			return nil;
		end
		if ID ~= nil and world.entityExists(ID) then
			--TODO
			--Notify other Neighbors that this object is leaving the group
		end
		ID = ObjectID;
		--TODO
		--Scan for other objects with the same Group Identifier

		--If none are found then set itself to be Master of the Group
	end

	Group.Update = function()
		--TODO Check if ObjectID still exists, if not, then notify other neighbors
	end

	Group.GetMaster = function()
		
		return Master;
	end












	return Group;
end
