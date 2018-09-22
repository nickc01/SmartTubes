
--Variables
local SourceID;
local SlotItem;
local CopyText = "";
local CopyAble = false;
local ExtensionList = {
	activeitem = {"activeitem"},
	augmentitem = {"augment"},
	beammingingtool = {"beamaxe"},
	codex = {"codex"},
	consumable = {"consumable"},
	flashlight = {"flashlight"},
	backarmor = {"back"},
	harvestingtool = {"harvestingtool"},
	headarmor = {"head"},
	inspectiontool = {"inspectiontool"},
	instrument = {"instrument"},
	generic = {"item"},
	legsarmor = {"legs"},
	item = {"item"},
	liquid = {"liquid","liqitem"},
	material = {"material","matitem"},
	miningtool = {"miningtool"},
	object = {"object"},
	paintingbeamtool = {"painttool"},
	thrownitem = {"thrownitem"},
	tillingtool = {"tillingtool"},
	wiretool = {"wiretool"}
}

--Functions
local UpdateStats;
local SetCopyText;
local CopyableUpdated;
local ColorizeJson;
local SafeAssetJson;

function init()
	SourceID = pane.sourceEntity();
	local Test = SafeAssetJson("/Blocks/Conduits/Extraction Conduit/test.object");
	if Test ~= nil then
		sb.logInfo("Test = " .. sb.printJson(Test,1));
	else
		sb.logInfo("Test = nil");
	end
end

function update(dt)
	local HasFocus = widget.hasFocus("copybox");
	if HasFocus ~= CopyAble then
		CopyAble = HasFocus;
		CopyableUpdated(CopyAble);
	end
end

--local function UpdateTags

UpdateStats = function()
	widget.setItemSlotItem("itemBox",SlotItem);
	if SlotItem == nil then
		SetCopyText("");
	else
		local Config = root.itemConfig(SlotItem);
		sb.logInfo("Config = " .. sb.print(Config));
		--local Data = Config.config;
		--[[if SlotItem.parameters ~= nil then
			for name,data in pairs(SlotItem.parameters) do
				Data[name] = data;
			end
		end--]]
		Config.CurrentItem = SlotItem;
		SetCopyText(Config);
	end
end

function itemBox()
	SlotItem = player.swapSlotItem();
	UpdateStats();
end

CopyableUpdated = function(copyable)
	--sb.logInfo("Copyable Updated = " .. sb.print(copyable));
	widget.setVisible("copyDisplayText",copyable);
end

function itemBoxRight()
	SlotItem = nil;
	UpdateStats();
end

SetCopyText = function(text)
	if type(text) == "table" then
		--CopyText = sb.printJson(text);
		--widget.setText("textArea.dataArea",sb.printJson(text,1));
		CopyText = DataToString(text,false,false);
		--sb.logInfo("Copy Text = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",DataToString(text,true,true));
	else
		CopyText = text;
		--sb.logInfo("CopyText = " .. sb.print(CopyText));
		widget.setText("textArea.dataArea",text);
	end
	widget.setText("copybox",CopyText);
	__copybox__();
end

function __copybox__()
	if widget.getText("copybox") ~= CopyText then
		widget.blur("copybox");
	end
	widget.setText("copybox",CopyText);
	--sb.logInfo("CopyBox = " .. sb.print(widget.getText("copybox")));
end

--Called when the copy button is clicked on
function copyButton()
	--sb.logInfo("Copy Button");
	widget.focus("copybox");
end

--Converts the data into string form
function DataToString(data,colorized,pretty)
	--sb.logInfo("RUNNING");
	colorized = colorized or false;
	pretty = pretty or false;
	if pretty == true then
		pretty = 1;
	else
		pretty = nil;
	end
	local NewLine;
	if pretty == 1 then
		NewLine = "\n";
	else
		NewLine = " ";
	end
	local FullPath = ItemToFileName(data.CurrentItem);
	--sb.logInfo("FullPath Result = " .. sb.print(FullPath));
	local Final = "{" .. NewLine;
	if colorized then
		Final = Final .. "^#ffa500;\"Data\": " .. sb.printJson(data.config,pretty) .. ",^reset;" .. NewLine;
	else
		Final = Final .. "\"Data\": " .. sb.printJson(data.config,pretty) .. ", ";
	end
	if FullPath ~= nil then
		if colorized then
			Final = Final .. "^#ff4a4a;\"FullPath\": " .. sb.printJson(FullPath,pretty) .. ",^reset;" .. NewLine;
		else
			Final = Final .. "\"FullPath\": " .. sb.printJson(FullPath,pretty) .. ", ";
		end
	else
		if colorized then
			Final = Final .. "^#ff4a4a;\"Directory\": " .. sb.printJson(data.directory,pretty) .. ",^reset;" .. NewLine;
		else
			Final = Final .. "\"Directory\": " .. sb.printJson(data.directory,pretty) .. ", ";
		end
	end
	if colorized then
		Final = Final .. "^#00a12a;\"Parameters\": " .. sb.printJson(data.parameters,pretty) .. "^reset;";
	else
		Final = Final .. "\"Parameters\": " .. sb.printJson(data.parameters,pretty);
	end
	Final = Final .. NewLine .. "}";
	return Final;
end

--Converts an Item Name to it's file extension
function ItemToExtension(itemName)
	--local ItemConfig = root.itemConfig(itemName).config;
	local Type = root.itemType(itemName);
	if Type ~= nil then
		return ExtensionList[Type];
	end
end

function ItemToFileName(item)
	local Config = root.itemConfig(item);
	if Config ~= nil then
		--Attempt to find the file name
		local Name = item.name;
		local PrettyName = Config.config.shortdescription;
		--sb.logInfo("Name = " .. sb.print(Name));
		local Directory = Config.directory;
		--sb.logInfo("Directory = " .. sb.print(Directory));
		local Extensions = ItemToExtension(Name);
		--sb.logInfo("Extensions = " .. sb.print(Extensions));
		if Extensions == nil then return nil end;
		for _,Extension in ipairs(Extensions) do
			if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
				return Directory .. Name .. "." .. Extension,Name;
			elseif SafeAssetJson(Directory .. PrettyName .. "." .. Extension) ~= nil then
				return Directory .. PrettyName .. "." .. Extension,PrettyName;
			else
				local SpaceLessPrettyName = string.gsub(PrettyName," ","");
				if SafeAssetJson(Directory .. SpaceLessPrettyName .. "." .. Extension) ~= nil then
					return Directory .. SpaceLessPrettyName .. "." .. Extension,SpaceLessPrettyName;
				end
				SpaceLessPrettyName = string.lower(SpaceLessPrettyName);
				if SafeAssetJson(Directory .. SpaceLessPrettyName .. "." .. Extension) ~= nil then
					return Directory .. SpaceLessPrettyName .. "." .. Extension,SpaceLessPrettyName;
				end
				--sb.logInfo("NAME = " .. sb.print(Name));
				--sb.logInfo("Found Colon = " .. sb.print(string.find(Name,":.+")));
				--sb.logInfo("Match = " .. sb.print(string.match(Name,":(.+)")));
				if string.find(Name,":.+") ~= nil then
					--sb.logInfo("Match = " .. sb.print(string.match(Name,":(.+)")));
					Name = string.match(Name,":(.+)");
					if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
						return Directory .. Name .. "." .. Extension,Name;
					end
				elseif Extension == "liquid" or Extension == "liqitem" then
					if string.find(Name,"liquid.+") ~= nil then
						Name = string.match(Name,"liquid(.+)");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				elseif Extension == "material" or Extension == "matitem" then
					if string.find(Name,".+material") ~= nil then
						Name = string.match(Name,"(.+)material");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				elseif Extension == "codex" then
					if string.find(Name,".+%-codex") ~= nil then
						Name = string.match(Name,"(.+)%-codex");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				elseif Extension == "back" then
					if string.find(Name,".+back") ~= nil then
						Name = string.match(Name,"(.+)back");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				elseif Extension == "head" then
					if string.find(Name,".+head") ~= nil then
						Name = string.match(Name,"(.+)head");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				elseif Extension == "legs" then
					if string.find(Name,".+legs") ~= nil then
						Name = string.match(Name,"(.+)legs");
						if SafeAssetJson(Directory .. Name .. "." .. Extension) ~= nil then
							return Directory .. Name .. "." .. Extension,Name;
						end
					end
				end
			end
		end
		return nil;
	end
end

SafeAssetJson = function(asset)
	local Result = nil;
	coroutine.resume(coroutine.create(function()
		pcall(function()
			Result = root.assetJson(asset);
		end);
	end));
	return Result;
end