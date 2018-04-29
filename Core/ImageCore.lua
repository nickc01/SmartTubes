if ImageCore ~= nil then return nil end;

--Declaration

--Public Table
ImageCore = {};
local ImageCore = ImageCore;

--Variables
local CanvasImagesCache = {};
local ObjectImageCache = {};
local ObjectAnimationCache = {};
local AnimationCache = {};


--Functions
local GetJson;
local TranslateImage;

--Returns the json value, or nil if the file doesn't exist or isn't a json file
GetJson = function(File)
	local Result = nil;
	pcall(function() Result = root.assetJson(File) end);
	return Result;
end

--Attempts to get the frame file corresponding to an image
function ImageCore.GetFrameOfImage(Image)
	--sb.logInfo("FRAME IMAGE BEFORE = " .. sb.print(Image));
	Image = string.gsub(Image,":.+$","");
	Image = string.gsub(Image,"%?.+$","");
	--sb.logInfo("FRAME IMAGE AFTER = " .. sb.print(Image));
	local CachedValue = world.getProperty(Image);
	if CachedValue ~= nil then
		local Json = GetJson(CachedValue);
		if Json ~= nil then
			return CachedValue;
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
		
		local Json = GetJson(Frame);
		if Json == nil then
			
			local Default = ImageCore.SetFileName(Frame,"default.frames");
			Json = GetJson(Default);
			if Json == nil then
				
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

--Takes in a path and moves it up a directory level
function ImageCore.MoveUpDirectory(Path)
	if string.find(Path,".+/.+%..+") ~= nil then
		Path = string.match(Path,"(.+)/.+%..+");
	end

	if string.find(Path,".*/[^/]+$") ~= nil then
		return string.match(Path,"(.*)/[^/]+/?$");
	end
end

--Sets the file name for a path
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

--Returns the file name of the path
function ImageCore.GetFileName(Path)
	if string.find(Path,"[^/]+.%.+") ~= nil then
		return string.match(Path,"([^/]+.%..+)");
	end
end

--Turns a local path into an absolue path based off of an object source
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

--Takes in an image and fills in the directives of the image
TranslateImage = function(AnimationImage,PartImage,GlobalTags)
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
	
	return Final,Frame;
end

--Adds a image directive to the image
function ImageCore.AddImageDirective(image,directive)
	if string.find(image,":") ~= nil then
		return string.gsub(image,":",directive .. ":");
	else
		return image .. directive;
	end
end

--Converts an image into something that can be used in canvas rendering
--Format : 
--Width
--Height
--Image
--TextureRect
function ImageCore.MakeImageCanvasRenderable(img)
	if CanvasImagesCache[img] ~= nil then
		return CanvasImagesCache[img];
	end
	--sb.logInfo("Input = " .. sb.print(img));
	local Image,Frame = TranslateImage(img);
	--sb.logInfo("Output = " .. sb.print(Image));
	--sb.logInfo("Output Frame = " .. sb.print(Frame));
	if string.find(Image,":") == nil then
		local Size = root.imageSize(Image);
		local Data = {
			Image = Image,
			Width = Size[1],
			Height = Size[2],
			TextureRect = {0,0,Size[1],Size[2]},
			Original = Image
		}
		CanvasImagesCache[img] = Data;
		--sb.logInfo("RETURN 1");
		return Data;
	else
		
		if Frame == nil then
			--sb.logInfo("Return 2");
			return nil;
		end
		
		--TODO TODO TODO -------------------------------------------------------------
		local FrameData = root.assetJson(Frame);
		--string.match(Image,":(.*)%?") or string.match(Image,":(.*)");
		local NonDirective = string.gsub(Image,"%?.*:",":");
		--sb.logInfo("Non Directive = " .. sb.print(NonDirective));
		local Directives = string.match(Image,"%?.*") or "";
		local FrameLink = string.match(NonDirective,":(.*)");
		
		if FrameData.aliases ~= nil then
			
			local AliasesChecked = false;
			while (not AliasesChecked) do
						
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
		
		--sb.logInfo("Frame Data = " .. sb.print(FrameData));
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
				Height = Size[2],
				Original = Image,
			};
			CanvasImagesCache[img] = CanvasTable;
			--sb.logInfo("Return 4");
			return CanvasTable;
		end
		--sb.logInfo("Return 3");
	end
end

--Retrieves an image from the object that can be rendered in a canvas
--Format :
--Images (All the images used to render the object), which consists of {
----Width
----Height
----Image
----TextureRect
--}
--Offset (A 2D vector representing the image offset)
--Flip (whether the images should be flipped horizontally or not)
function ImageCore.ObjectToImage(object)
	if type(object) == "number" then
		object = world.entityName(object);
	end
	if object == nil then
		return nil;
	end
	if ObjectImageCache[object] ~= nil then
		return ObjectImageCache[object];
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
		
		return nil;
	end
	Offset = Orientation.imagePosition or {0,0};
	Flip = Orientation.flipImages or false;
	local FinalImages = {};
	for k,i in ipairs(Images) do
		FinalImages[#FinalImages + 1] = ImageCore.MakeImageCanvasRenderable(ImageCore.MakePathAbsolute(i,object));
	end
	ObjectImageCache[object] = {Images = FinalImages,Offset = Offset,Flip = Flip};
	return ObjectImageCache[object];
end

--Gets the animation data of the object and organizes it
--Format : 
--[[
	Animation : {
		Layers : [ (a table of all the layers needed to fully render this object)
			DefaultState, (the state that this layer is defaulted to)
			States : [ (a list of all the possible states the layer can be in)
				Image, (the image that is rendered when this state is used)
				Frame, (the frame file that goes along with the image)
			]
		]
	}
]]
function ImageCore.ParseObjectAnimation(Object)
	if Object == nil then
		Object = entity.id();
	end
	if type(Object) == "number" then
		Object = world.entityName(Object);
	end
	if ObjectAnimationCache[Object] ~= nil then
		return ObjectAnimationCache[Object];
	end
	local Config = root.itemConfig({name = Object,count = 1});
	local Directory = nil;
	Directory = Config.directory;
	Config = Config.config;
	local AnimationFile = Config.animation;
	if AnimationFile == nil then
		error("This Object has no Animations");
	end
	AnimationFile = ImageCore.MakePathAbsolute(AnimationFile,Object);
	local Animation = ImageCore.TranslateAnimationFile(AnimationFile,Config.animationParts,Object);
	ObjectAnimationCache[Object] = Animation;
	--sb.logInfo("New 2");
	return Animation;
end

--Takes in an animation file and translates it into something readable
function ImageCore.TranslateAnimationFile(file,AnimationParts,Object)
	if AnimationCache[file] ~= nil then
		if AnimationCache[file][Object] ~= nil then
			return AnimationCache[file][Object];
		end
	end
	local AnimationData = root.assetJson(file);
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
	local SpriteImages = AnimationParts;
	for CurrentSprite,CurrentSpriteData in pairs(AnimationData.animatedParts.parts) do
		local Image = SpriteImages[CurrentSprite];
		for CurrentLayer,CurrentLayerData in pairs(CurrentSpriteData.partStates) do
			for CurrentState,CurrentStateData in pairs(CurrentLayerData) do
				local ModifierState = Animation.Layers[CurrentLayer].States[CurrentState];
				ModifierState.Image,ModifierState.Frame = TranslateImage(CurrentStateData.properties.image,ImageCore.MakePathAbsolute(Image,Object),GlobalTags);
			end
		end
	end
	--AnimationCache[file] = Animation;
	if AnimationCache[file] == nil then
		AnimationCache[file] = {}; 
	end
	AnimationCache[file][Object] = Animation;
	return Animation;
end
