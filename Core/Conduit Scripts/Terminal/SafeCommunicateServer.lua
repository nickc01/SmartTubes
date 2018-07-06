if SafeCommunicate ~= nil then return nil end;
require("/Core/ServerCore.lua");

--Declaration
SafeCommunicate = {};
local SafeCommunicate = SafeCommunicate;

--Variables
local Initialized = false;
local Messages = {};

--Functions

--Initializes the Safe Communication Library
function SafeCommunicate.Initialize()
	if Initialized == true then return nil end;
	Initialized = true;
	message.setHandler("SafeCommunicate.ExecuteOnSource",function(_,_,functionName,...)
		--sb.logInfo("Executing On Server");
		--return _ENV[functionName](...);
		--local Result = world.callScriptedEntity(entity.id(),functionName,...);
		--sb.logInfo("RESULT for = " .. sb.print(functionName) .. " = " .. sb.print(Result));
		--return Result;
		return world.callScriptedEntity(entity.id(),functionName,...);
	end);
	message.setHandler("SafeCommunicate.SendEntityMessage",function(_,_,id,functionName,...)
		local MessageID = sb.makeUuid();
		Messages[MessageID] = world.sendEntityMessage(id,functionName,...);
		return MessageID;
	end);
	message.setHandler("SafeCommunicate.IsMessageDone",function(_,_,messageID)
		if Messages[messageID] == nil then
			return nil;
		else
			local Promise = Messages[messageID];
			if Promise:finished() then
				local Return = {Succeeded = Promise:succeeded(),Result = Promise:result(),Error = Promise:error()};
				Messages[messageID] = nil;
				return Return;
			else
				return false;
			end
		end
	end);
end

--Gets the Container Items of a Container
--[[function SafeCommunicate.GetContainerItems(containerID)
	return world.containerItems(containerID);
end

function SafeCommunicate.GetContainerSize(containerID)
	return world.containerSize(containerID);
end

function SafeCommunicate.GetObjectParameter(containerID,value,default)
	return world.getObjectParameter(containerID,value,default);
end

function SafeCommunicate.GetObjectName(containerID)
	return world.entityName(containerID);
end

function SafeCommunicate.GetObjectPosition(containerID)
	return world.entityPosition(containerID);
end

function SafeCommunicate.GetContainerItemAt(containerID,offset)
	return world.containerItemAt(containerID,offset);
end

function SafeCommunicate.GetObjectSpaces(id)
	return world.objectSpaces(id);
end--]]