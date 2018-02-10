require("/Core/Debug.lua");
local Hue = 0;
local Saturation = 0;

local UpdateLooks;
local ScanForConduits;
local Cables;
local EntityID;
local UpdateCache = false;
local UINeedsUpdate = true;

function init()
	if root.assetJson("/Core/Debug.json").EnableExperimentalConduits == false then
		object.smash();
	end
	EntityID = entity.id();
	Cables = CableCore;
	Hue = config.getParameter("Hue",0);
	Saturation = config.getParameter("Saturation",0);
	message.setHandler("SetHue",function(_,_,newHue)
		Hue = newHue;
		object.setConfigParameter("Hue",newHue);
		UpdateLooks();
	end);
	message.setHandler("SetSaturation",function(_,_,newSat)
		Saturation = newSat;
		object.setConfigParameter("Saturation",newSat);
		UpdateLooks();
	end);
	message.setHandler("SetValue",function(_,_,Name,Value)
		object.setConfigParameter(Name,Value);
	end);
	message.setHandler("UINeedsUpdate",function()
		local Value = UINeedsUpdate;
		if UINeedsUpdate == true then
			UINeedsUpdate = false;
		end
		--sb.logInfo("_________________Returned Value = ".. sb.print(UINeedsUpdate));
		return Value;
	end);
	UpdateLooks();
	Cables.SetCableConnections({{-1,0},{0,-1},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.AddAfterFunction(ResetPathCache);
	Cables.Initialize();
	DPrint("ANIM");
	UpdateCache = true;
	ScanForConduits();
	--sb.logInfo("Animated Parts = " .. sb.print(objectAnimator.getParameter("animatedParts")));
end

UpdateLooks = function()
	animator.setGlobalTag("directives","?hueshift=" .. Hue .. "?saturation=" .. Saturation);
end

function ResetPathCache()
	DPrint("Cache Reset");
	UpdateCache = true;
	ScanForConduits();
	--object.setConfigParameter("UpdateCache",UpdateCache);
end

local AllConduitCache = nil;

ScanForConduits = function()
	if UpdateCache == false and AllConduitCache ~= nil then
		return AllConduitCache;
	end
	local Conduits = {};
	local Findings = {};
	local AllConduits = {};
	local Next = {{ID = EntityID}};
	repeat
		local NewNext = {};
		for i=1,#Next do
			if world.entityExists(Next[i].ID) then
				local Conduits = world.callScriptedEntity(Next[i].ID,"GetConduits");
				if Next[i].ID == EntityID then
					DPrint("SELF CONDUITS = " .. sb.print(Conduits));
				end
				world.callScriptedEntity(Next[i].ID,"AddExtractionConduit",EntityID);
				if Conduits ~= nil then
					for x=1,#Conduits do
						if Conduits[x] ~= -10 then
							local Valid = true;
							for y=1,#Findings do
								if Findings[y].ID == Conduits[x] then
									Valid = false;
									break;
								end
							end
							if Valid == true then
								for y=1,#NewNext do
									if NewNext[y].ID == Conduits[x] then
										Valid = false;
										break;
									end
								end
							end
							if Valid == true then
								for y=1,#Next do
									if i ~= y and Next[y].ID == Conduits[x] then
										Valid = false;
										break;
									end
								end
							end
							if Valid == true then
								NewNext[#NewNext + 1] = {ID = Conduits[x],Previous = #Findings + 1};
							end
						end
					end
					DPrint("Adding = " .. sb.print(Next[i]));
					Findings[#Findings + 1] = Next[i];
					local Type = world.getObjectParameter(Next[i].ID,"conduitType");
					if Type ~= nil then
						if AllConduits[Type] == nil then
							AllConduits[Type] = {};
						end
						AllConduits[Type][#AllConduits[Type] + 1] = Next[i].ID;
					end
				end
			end
		end
		Next = NewNext;
	until #Next == 0;
	AllConduitCache = AllConduits;
	object.setConfigParameter("AllConduits",AllConduits);
	UpdateCache = false;
	object.setConfigParameter("UpdateCache",UpdateCache);
	--object.setConfigParameter("UINeedsUpdate",true);
	UINeedsUpdate = true;
	return AllConduits;
end

--local First = false;
--local FirstTimer = 0;

function update(dt)
	--[[if First == true then
		if FirstTimer > 1 then
			First = nil;
			DPrint("AllConduits = " .. sb.print(ScanForConduits()));
		else
			FirstTimer = FirstTimer + dt;
		end
	elseif First == false then
		First = true;
	end--]]
	object.setProcessingDirectives("?hueshift=" .. Hue);
end

function die()
	Cables.Uninitialize();
end

function uninit()
	
end