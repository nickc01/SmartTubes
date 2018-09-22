local CurrentDirectory;
local vec = vec;
Argon = {};
local ElementCreators = {};

local Canvases = {};

local Core = {};

local ControllerIndex = {};

local ElementCreatorFunction = nil;

local function GetCurrentDirectory()
	if CurrentDirectory == nil then
		local Scripts = config.getParameter("scripts");
		for k,i in ipairs(Scripts) do
			CurrentDirectory = string.match(i,"(.+)Argon%.lua");
			if CurrentDirectory ~= nil then
				break;
			end
		end
		if CurrentDirectory == nil then
			for k,i in pairs(_SBLOADED) do
				CurrentDirectory = string.match(k,"(.+)Argon%.lua");
				if CurrentDirectory ~= nil then
					break;
				end
			end
			if CurrentDirectory == nil then
				error("Couldn't find directory containing Argon.lua");
			end
		end
		return CurrentDirectory;
	else
		return CurrentDirectory;
	end
end

local function AddElement(CanvasName,Element)
	Canvases[CanvasName].Elements[#Canvases[CanvasName].Elements + 1] = Element;
end
function Core.RemoveElement(CanvasName,Element)
	for k,i in ipairs(Canvases[CanvasName].Elements) do
		if i.GetID() == Element.GetID() then
			table.remove(Canvases[CanvasName].Elements,k);
			return nil;
		end
	end
end

function Argon.GetArgonDirectory()
	return CurrentDirectory;
end

function Core.GetElementByController(controller)
	return ControllerIndex[controller];
end

function Core.AddElement(CanvasName,Element)
	AddElement(CanvasName,Element);
end
local function DeletedFunction()
	error("This Controller Has Been Deleted");
end

function Core.DeleteElement(CanvasName,Element)
	if Element.Parent == nil then
		if Canvases[CanvasName] ~= nil then
			for k,i in ipairs(Canvases[CanvasName].Elements) do
				if i.GetID() == Element.GetID() then
					table.remove(Canvases[CanvasName].Elements,k);
					break;
				end
			end
			local Controller = Element.GetController();
			for k,i in pairs(Controller) do
				Controller[k] = DeletedFunction;
			end
			ControllerIndex[Element.GetController()] = nil;
		end
	end
end

function Argon.SetClickCallback(AliasName,FunctionName)
	_ENV[FunctionName] = function(Position,ButtonType,IsDown)
		
		for k,i in ipairs(Canvases[AliasName].Elements) do
			i.OnClick(Position,ButtonType,IsDown);
		end
	end
end
local RefCounter = 0;
function Argon.CreateElement(Type,CanvasAlias,...)
	if ElementCreators[Type] ~= nil then
		CreateElement = ElementCreatorFunction;
		RefCounter = RefCounter + 1;
		local Element = ElementCreators[Type](CanvasAlias,...);
		
		--Element.Core = Core;
		Element.SetCore(Core);
		Element.Type = Type;
		Element.Finish();
		AddElement(CanvasAlias,Element);
		ControllerIndex[Element.GetController()] = Element;
		RefCounter = RefCounter - 1;
		if RefCounter == 0 then
			CreateElement = nil;
		end
		return Element.GetController();
	else
		error("Element Type of " .. sb.print(Type) .. "doesn't exist");
	end
end

function Argon.AddCanvas(CanvasName,AliasName)
	for k,i in pairs(Canvases) do
		if i.Name == CanvasName then
			error(sb.print(CanvasName) .. " is already Added under the Alias Name : " .. sb.print(k));
		end
	end
	local Binding = widget.bindCanvas(CanvasName);
	Canvases[AliasName] = {Canvas = Binding,Name = CanvasName,Elements = {}};
	return Binding;
end

function Argon.GetCanvas(CanvasAlias)
	if Canvases[CanvasAlias] == nil then
		error(sb.print(CanvasAlias) .. " is not a valid Canvas Alias");
	end
	return Canvases[CanvasAlias].Canvas;
end

function Argon.Init()
	GetCurrentDirectory();
	require (CurrentDirectory .. "Math.lua");
	require (CurrentDirectory .. "ElementBase.lua");
	ElementCreatorFunction = CreateElement;
	CreateElement = nil;
	local ElementJson = root.assetJson(CurrentDirectory .. "Elements.json").Elements;
	for k,i in ipairs(ElementJson) do
		if i.Name ~= nil then
			if string.match(i.Script,"^/") ~= nil then
				require(i.Script);
			else
				require(CurrentDirectory .. i.Script);
			end
			if Creator ~= nil and Creator.Create ~= nil then
				ElementCreators[i.Name] = Creator.Create;
				Creator = nil;
			else
				error(sb.print(i.Script) .. " is either not a valid lua file or doesn't implement Creator.Create()");
			end
		end
	end
	
end

function Argon.Update(dt)
	for k,i in pairs(Canvases) do
		i.Canvas:clear();
		for m,n in ipairs(i.Elements) do
			if n.Update ~= nil then
				n.Update(dt);
			end
			--n.OnHover(i.Canvas:mousePosition());
			n.Draw();
		end
	end
end

function stringTable(table,name,spacer)
	if table == nil then return name ..  " = nil" end;
	if spacer == nil then spacer = "" end;
	local startingString = "\n" .. spacer ..  name .. " :\n" .. spacer .. "(";
	for k,i in pairs(table) do
		startingString = startingString .. "\n" .. spacer;
		if type(i) == "table" then
			startingString = startingString .. stringTable(i,k,spacer .. "	") .. ", ";
		--else
			--startingString = startingString .. "	" .. k .. " = " .. 
		elseif type(i) == "function" then
				startingString = startingString .. "	" .. k .. " = (FUNC) " .. sb.print(i);
		elseif type(i) == "boolean" then
			if i == true then
				startingString = startingString .. "	" .. k .. " = true, ";
			else
				startingString = startingString .. "	" .. k .. " = false, ";
			end
		elseif type(i) == "number" then
			startingString = startingString .. "	(NUM) " .. k .. " = " .. i .. ", ";
		else
			if i ~= nil then
				startingString = startingString .. "	" .. k .. " = " .. sb.print(i) .. ", ";
			else
				startingString = startingString .. "	" .. k .. " = nil, ";
			end
		end
	end
	startingString = startingString .. "\n" .. spacer .. ")";
	return startingString;
end