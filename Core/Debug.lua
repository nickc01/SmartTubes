require("/Core/Debug.lua");

if sb == nil then
	sb = {};
end

local oldprint = sb.logInfo;

function Print(value)
	if type(value) == "string" then
		oldprint(value);
	else
		oldprint(sb.print(value));
	end
end

local CanPrint;

function sb.logInfo(value)
	DPrint(value);
end

function DPrint(value)
	if CanPrint == nil then
		CanPrint = root.assetJson("/Core/Debug.json").Debugging == true;
	end
	if CanPrint then
		Print(value);
	end
end