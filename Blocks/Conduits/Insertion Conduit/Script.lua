require("/Core/Conduit Scripts/Insertion.lua");

--Variables
local SideToConnection = setmetatable({},{
	__index = function(tbl,k)
		local Connections = ConduitCore.GetConnections("Containers");
		if k == "up" then
			return Connections[1];
		elseif k == "down" then
			return Connections[2];
		elseif k == "left" then
			return Connections[3];
		elseif k == "right" then
			return Connections[4];
		end
		return nil;
	end});

--Functions
local OldInit = init;
local OldUninit = uninit;

local function RandomIterator(t)
	local indexTable = {};
	for i=1,#t do
		indexTable[i] = i;
	end
	local Size = #indexTable;
  	while Size > 1 do
    	local k = math.random(Size);
    	indexTable[Size], indexTable[k] = indexTable[k], indexTable[Size];
    	Size = Size - 1;
 	end
	local n = 0;
	return function()
		n = n + 1;
		return indexTable[n],t[indexTable[n]];
	end
end

--Initializes the conduit
function init()
	Insertion.Initialize();
	if OldInit ~= nil then
		OldInit();
	end
end

--Called when the extraction is requesting an item to be sent
function PostExtract(Extraction,ExtractItem,ExtractSlot,ExtractContainer)
	--sb.logInfo("Post Extract");
	if not Insertion.Ready() then return 4 end;
	--sb.logInfo("Ready");
	for _,side in RandomIterator(Extraction.GetInsertSides()) do
		--sb.logInfo("Side = " .. sb.print(side));
		local Object = SideToConnection[side];
		--sb.logInfo("Object = " .. sb.print(Object));
		if Object ~= nil and Object ~= 0 then
			local Item,Slot = Insertion.ItemCanFit(Object,ExtractItem,Extraction.GetInsertSlots());
			--sb.logInfo("Insert Item = " .. sb.print(Item));
			--sb.logInfo("Insert Slot = " .. sb.print(Slot));
			if Item ~= nil then
				if ContainerHelper.ConsumeAt(ExtractContainer,ExtractSlot - 1,Item.count) ~= nil then
					if Insertion.SendItem(Item,Object,Slot,Extraction.GetID(),Extraction.GetInsertSlots(),Extraction.GetSelectedColor(),Extraction.GetSpeed() + 1) == true then
						--sb.logInfo("Sent");
						return 0;
					end
					return 2;
				end
				return 3;
			end
		end
	end
	return 1;
end

--Called when the object is uninitialized
function uninit()
	Insertion.Uninitialize();
	if OldUninit ~= nil then
		OldUninit();
	end
end
