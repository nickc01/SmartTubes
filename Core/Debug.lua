require("/Core/Debug.lua");

function Print(value)
	sb.logInfo(sb.print(value));
end

local CanPrint;

function DPrint(value)
	if CanPrint == nil then
		CanPrint = root.assetJson("/Core/Debug.json").Debugging == true;
	end
	if CanPrint then
		Print(value);
	end
end