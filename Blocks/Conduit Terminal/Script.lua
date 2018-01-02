local Hue = 0;
local Saturation = 0;

local UpdateLooks;
local ScanForConduits;
local Cables;
local EntityID;
local UpdateCache = false;

function init()
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
	UpdateLooks();
	Cables.SetCableConnections({{-1,0},{0,-1},{-1,1},{-1,2},{0,3},{1,3},{2,3},{3,2},{3,1},{3,0},{2,-1},{1,-1}});
	Cables.AddCondition("Conduits","conduitType",function(value) return value ~= nil end);
	Cables.Initialize();
	sb.logInfo("ANIM");
	--sb.logInfo("Animated Parts = " .. sb.print(objectAnimator.getParameter("animatedParts")));
end

UpdateLooks = function()
	--object.setProcessingDirectives("?hueshift=" .. Hue .. "?saturation=" .. Saturation);
	animator.setGlobalTag("directives","?hueshift=" .. Hue .. "?saturation=" .. Saturation);
end

function ResetPathCache()
	--sb.logInfo("Cache Updated");
	UpdateCache = true;
	object.setConfigParameter("UpdateCache",UpdateCache);
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
					sb.logInfo("Adding = " .. sb.print(Next[i]));
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
	return AllConduits;
end

local First = false;
local FirstTimer = 0;

function update(dt)
	if First == true then
		if FirstTimer > 1 then
			First = nil;
			sb.logInfo("AllConduits = " .. sb.print(ScanForConduits()));
		else
			FirstTimer = FirstTimer + dt;
		end
	elseif First == false then
		First = true;
	end
	object.setProcessingDirectives("?hueshift=" .. Hue);
end

function die()
	Cables.Uninitialize();
end

function uninit()
	
end