
--Variables

--Functions
--[[local ExecuteCommand;
local ExecuteCommandMulti;

--The init function for the Crafting Terminal UI Script
function init()
	--sb.logInfo("Mods Menu = " .. sb.printJson(root.assetJson("/_metadata"),1));
	--sb.logInfo("OS = " .. sb.print(os.execute("ls")));
	--local Result1,Result2 = os.execute("echo hello");
	--sb.logInfo(sb.print(Result1));
	--sb.logInfo(sb.print(Result2));
	--sb.logInfo("IO = " .. sb.print(io));
	--local File = io.popen("ls");
	--local Test = File:read("*a");
	--File:close();
	--sb.logInfo("Test = " .. sb.print(Test));
	--sb.logInfo(sb.print(os.execute("echo this is a test")));
	sb.logInfo(ExecuteCommandMulti(nil,"pwd","ls","cd ..","pwd","ls"));
end

--The update function for the Crafting Terminal UI Script
function update()

end

--Executes a single command in a terminal and closes the terminal
ExecuteCommand = function(command,readMode)
	local File = io.popen(command);
	local Text = File:read("*a");
	File:close();
	return Text;
end

--Executes multiple commands one after the other in a single terminal and closes it
ExecuteCommandMulti = function(readMode,...)
	local Commands = {...};
	if #Commands == 0 then return nil end;
	local CommandString = Commands[1];
	if #Commands > 1 then
		for _,command in ipairs(Commands) do
			CommandString = CommandString .. " && " .. command;
		end
	end
	return ExecuteCommand(CommandString,readMode);
end--]]