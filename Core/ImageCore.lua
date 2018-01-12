ImageCore = {};

local ImageCore = ImageCore;

local function GoUpDirectory(directory)
	
end

function ImageCore.SplitFrames(FrameFile)
	local Frames = root.assetJson(FrameFile);
	sb.logInfo("Frames = " .. sb.printJson(Frames,1));
end

local function GetJson(File)
	local Result = nil;
	pcall(function() Result = root.assetJson(File) end);
	return Result;
end

function ImageCore.GetFrameOfImage(Image)
	local Frame = string.gsub(Image,"%.png$",".frames");
	sb.logInfo("Frame = " .. sb.print(Frame));
	sb.logInfo("Frame Json = " .. sb.print(GetJson(Frame)));
	return Frame;
end
