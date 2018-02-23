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
	local CachedValue = world.getProperty(Image);
	if CachedValue ~= nil then
		local Json = GetJson(CachedValue);
		if Json ~= nil then
			return CachedValue;
		else
			sb.logInfo("ATTENTION: THE ABOVE ERROR THAT YOU SEE IS NOT AN ERROR, SO IF YOU SEE IT, JUST IGNORE IT, IF YOU WANT TO KNOW WHY, ITS JUST AN ISSUE WITH ROOT.ASSETJSON THAT CAN'T BE WORKED AROUND AT THE MOMENT       : SMART TUBES");
		end
	end
	if string.find(Image,"^/") == nil then
		error("Image path must be absolute");
	end
	local Frame = string.gsub(Image,"%.png$",".frames");
	while Frame ~= nil do
		local Json = GetJson(Frame);
		if Json == nil then
			sb.logInfo("ATTENTION: THE ABOVE ERROR THAT YOU SEE IS NOT AN ERROR, SO IF YOU SEE IT, JUST IGNORE IT, IF YOU WANT TO KNOW WHY, ITS JUST AN ISSUE WITH ROOT.ASSETJSON THAT CAN'T BE WORKED AROUND AT THE MOMENT       : SMART TUBES");
			local Default = ImageCore.SetFileName(Frame,"default.frames");
			Json = GetJson(Default);
			if Json == nil then
				sb.logInfo("ATTENTION: THE ABOVE ERROR THAT YOU SEE IS NOT AN ERROR, SO IF YOU SEE IT, JUST IGNORE IT, IF YOU WANT TO KNOW WHY, ITS JUST AN ISSUE WITH ROOT.ASSETJSON THAT CAN'T BE WORKED AROUND AT THE MOMENT       : SMART TUBES");
				local NewFrame = ImageCore.MoveUpDirectory(Frame);
				if NewFrame ~= nil then
					Frame = ImageCore.SetFileName(NewFrame,ImageCore.GetFileName(Frame));
				else
					Frame = nil;
				end
			else
				world.setProperty(Default,Frame);
				return Default;
			end
		else
			world.setProperty(Image,Frame);
			return Frame;
		end
	end
end

function ImageCore.MoveUpDirectory(Path)
	if string.find(Path,".+/.+%..+") ~= nil then
		Path = string.match(Path,"(.+)/.+%..+");
	end

	if string.find(Path,".*/[^/]+$") ~= nil then
		return string.match(Path,"(.*)/[^/]+/?$");
	end
end

function ImageCore.SetFileName(Path,FileName,Extension)
	if string.find(Path,".+%..+") ~= nil then
		if Extension == nil then
			return string.match(Path,"(.+/)") .. FileName;
		else
			return string.match(Path,"(.+/)") .. FileName .. "." .. Extension;
		end
	else
		if string.find(Path,"/$") == nil then
			Path = Path .. "/";
		end
		if Extension == nil then
		return Path .. FileName;
		else
			return Path .. FileName .. "." .. Extension;
		end
	end
end

function ImageCore.GetFileName(Path)
	if string.find(Path,"[^/]+.%.+") ~= nil then
		return string.match(Path,"([^/]+.%..+)");
	end
end

function ImageCore.MakePathAbsolute(Path,ObjectSource)
	ObjectSource = ObjectSource or entity.id();
	if string.find(Path,"^/") ~= nil then
		return Path;
	else
		local DirectoryObject;
		if type(ObjectSource) == "string" then
			DirectoryObject = ObjectSource;
		else
			DirectoryObject = world.entityName(ObjectSource);
		end
		local Directory = root.itemConfig({name = DirectoryObject,count = 1}).directory;
		if string.find(Directory,"/$") == nil then
			Directory = Directory .. "/";
		end
		local FinalPath = Directory .. Path;
		return FinalPath;
	end
end

function ImageCore.ParseObjectAnimation(Object)
	if Object == nil then
		Object = entity.id();
	end
	local Config = nil;
	local Directory = nil;
	if type(Object) == "number" then
		Config = root.itemConfig({name = world.entityName(Object),count = 1});
	elseif type(Object) == "string" then
		Config = root.itemConfig({name = Object,count = 1});
	else
		error("Can't find an object to work on");
	end
	Directory = Config.directory;
	Config = Config.config;
	local AnimationFile = Config.animation;
	if AnimationFile == nil then
		error("This Object has no Animations");
	end
	AnimationFile = ImageCore.MakePathAbsolute(AnimationFile,Object);
	local AnimationData = root.assetJson(AnimationFile);
	local Animation = {
		Layers = {};
	};
	for k,i in pairs(AnimationData.animatedParts.stateTypes) do
		Animation.Layers[k] = {
			DefaultState = i.default,
			States = {}
		};
		for m,n in ipairs(i.states) do
			Animation.Layers[k].States[m] = {
			
			};
			--TODO TODO TODO
		end
	end
end
