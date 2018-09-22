

--Variables
local OldInit = init;
local OldUpdate = update;
local SourcePlayer;
local UsingTerminalMessage;
local SourceID;

--Functions

--The Init function for the Terminal GUI Controller
function init()
	if OldInit ~= nil then
		OldInit();
	end
	SourcePlayer = config.getParameter("SourcePlayer");
	SourceID = config.getParameter("MainObject");
	UsingTerminalMessage = world.sendEntityMessage(SourcePlayer,"UsingTerminal");
end

--The Update function for the Terminal GUI Controller
function update(dt)
	if OldUpdate ~= nil then
		OldUpdate(dt);
	end
	if UsingTerminalMessage:finished() then
		if UsingTerminalMessage:result() == false then
			pane.dismiss();
		else
			UsingTerminalMessage = world.sendEntityMessage(SourcePlayer,"UsingTerminal");
		end
	end
	if world.entityExists(SourceID) == false then
		pane.dismiss();
	end
end