if ImageCore ~= nil then return nil end;
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

function ImageCore.GetFrameOfImage(Image,Object)
	Image = string.gsub(Image,":.+$","");
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
		if Object ~= nil then
			Image = ImageCore.MakePathAbsolute(Image,Object);
		else
			error("Image path must be absolute");
		end
	end
	local Frame = string.gsub(Image,"%.png",".frames");
	while Frame ~= nil do
		--sb.logInfo("Scanning Frame = " .. sb.print());
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
		sb.logInfo("FileName = " .. sb.print(FileName));
		sb.logInfo("Path = " .. sb.print(Path));
		sb.logInfo("Match = " .. sb.print(string.match(Path,"(.+/)")));
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

local function TranslateImage(AnimationImage,PartImage,GlobalTags)
	local Final = AnimationImage;
	if PartImage ~= nil then
		Final = string.gsub(Final,"<partImage>",PartImage);
	end
	Final = string.gsub(Final,"<frame>","default");
	Final = string.gsub(Final,"<directives>","");
	Final = string.gsub(Final,"<color>","default");
	Final = string.gsub(Final,"<key>","default");
	if GlobalTags ~= nil then
		for k,i in pairs(GlobalTags) do
			Final = string.gsub(Final,"<" .. k .. ">",sb.print(i));
		end
	end
	Final = string.gsub(Final,"<.*>","");
	local Frame = nil;
	if string.find(AnimationImage,":") ~= nil then
		Frame = ImageCore.GetFrameOfImage(PartImage or AnimationImage);
	end
	sb.logInfo("FINAL = " .. sb.print(Final));
	return Final,Frame;
end

local CanvasImagesCache = {};

function ImageCore.MakeImageCanvasRenderable(img)
	if CanvasImagesCache[img] ~= nil then
		return CanvasImagesCache[img];
	end
	local Image,Frame = TranslateImage(img);
	if string.find(Image,":") == nil then
		return Image;
	else
		--sb.logInfo("Image = " .. sb.print(Image));
		if Frame == nil then
			--sb.logInfo("Frame Nil 1");
			return nil;
		end
		--sb.logInfo();
		--TODO TODO TODO -------------------------------------------------------------
		local FrameData = root.assetJson(Frame);
		--sb.logInfo("FrameData = " .. sb.printJson(FrameData,1));
		local FrameLink = string.match(Image,":(.*)");
		--sb.logInfo("FrameData = " .. sb.printJson(FrameData,1));
		if FrameData.aliases ~= nil then
			--sb.logInfo("A");
			local AliasesChecked = false;
			while (not AliasesChecked) do
			--sb.logInfo("B");			
				for k,i in pairs(FrameData.aliases) do
					if FrameLink == k then
						FrameLink = i;
						goto Continue;
					end
				end
				AliasesChecked = true;
				::Continue::
			end
		end
		local Pos;
		--sb.logInfo("Names = " .. sb.printJson(FrameData.frameGrid.names,1));
		--sb.logInfo("FrameLink = " .. sb.print(FrameLink));
		for k,i in ipairs(FrameData.frameGrid.names) do
			for m,n in ipairs(i) do
				if FrameLink == n then
					Pos = {m,k};
				end
			end
		end
		if Pos ~= nil then
			local Size = FrameData.frameGrid.size;
			local Dimensions = FrameData.frameGrid.dimensions;
			local Width = Dimensions[1] * Size[1];
			local Height = Dimensions[2] * Size[2];
			local CanvasTable = {
				Image = string.match(Image,"(.*):.*"),
				TextureRect = {Size[1] * (Pos[1] - 1),Height - (Size[2] * Pos[2]),Size[1] * Pos[1],Height - (Size[1] * (Pos[2] - 1))},
				Width = Size[1],
				Height = Size[2]
			};
			--sb.logInfo("CanvasTable = " .. sb.print(CanvasTable));
			CanvasImagesCache[img] = CanvasTable;
			return CanvasTable;
		end
		--sb.logInfo("End of function");
	end
end

function ImageCore.ObjectToImage(object)
	local ID;
	if type(object) == "number" then
		ID = object;
		object = world.entityName(object);
	end
	sb.logInfo("Name = " .. sb.print(object));
	if object == nil then
		sb.logInfo("Nil2 for " .. sb.print(object));
		return nil;
	end
	local Config = root.itemConfig({name = object,count = 1}).config;
	local Orientation = Config.orientations[1];
	local Images;
	local Offset;
	local Flip;
	if Orientation.leftImage ~= nil then
		Images = {Orientation.leftImage};
	elseif Orientation.rightImage ~= nil then
		Images = {Orientation.rightImage};
	elseif Orientation.imageLayers ~= nil then
		Images = {};
		for k,i in ipairs(Orientation.imageLayers) do
			Images[#Images + 1] = i.image;
		end
	elseif Orientation.dualImage ~= nil then
		Images = {Orientation.dualImage};
	elseif Orientation.image ~= nil then
		Images = {Orientation.image};
	end
	if Images == nil then
		sb.logInfo("Nil1 for " .. sb.print(object));
		return nil;
	end
	Offset = Orientation.imagePosition or {0,0};
	Offset[1] = Offset[1] / 8;
	Offset[2] = Offset[2] / 8;
	Flip = Orientation.flipImages or false;
	local FinalImages = {};
	for k,i in ipairs(Images) do
		FinalImages[#FinalImages + 1] = ImageCore.MakeImageCanvasRenderable(ImageCore.MakePathAbsolute(i,object));
	end
	sb.logInfo("Final for " .. sb.print(object));
	return {Images = FinalImages,Offset = Offset,Flip = Flip};
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
	for CurrentLayer,CurrentLayerData in pairs(AnimationData.animatedParts.stateTypes) do
		Animation.Layers[CurrentLayer] = {
			DefaultState = CurrentLayerData.default,
			States = {}
		};
		for CurrentState,CurrentStateData in pairs(CurrentLayerData.states) do
			Animation.Layers[CurrentLayer].States[CurrentState] = {};
		end
	end
	local GlobalTags = AnimationData.globalTagDefaults or {};
	local SpriteImages = Config.animationParts;
	for CurrentSprite,CurrentSpriteData in pairs(AnimationData.animatedParts.parts) do
		local Image = SpriteImages[CurrentSprite];
		for CurrentLayer,CurrentLayerData in pairs(CurrentSpriteData.partStates) do
			for CurrentState,CurrentStateData in pairs(CurrentLayerData) do
				local ModifierState = Animation.Layers[CurrentLayer].States[CurrentState];
				ModifierState.Image,ModifierState.Frame = TranslateImage(CurrentStateData.properties.image,ImageCore.MakePathAbsolute(Image,Object),GlobalTags);
			end
		end
	end
	return Animation;
end
