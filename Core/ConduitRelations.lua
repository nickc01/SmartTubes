if Relations == nil then

Relations = {};

Relations.Types = {
	Normal = "conduit",
	FacadeItem = "item",
	NormalFacade = "normalBlock",
	OccludedFacade = "occludedBlock",
	Indicator = "indicator",
	Name = "displayName"
};

local Config;

local function GetConfig()
	if Config == nil then
		Config = root.assetJson("/Blocks/Conduits/Facades.json").Facades;
	end
	return Config;
end

Relations.Convert = function(FromType,ToType,FromValue)
	local Config = GetConfig();
	for i=1,#Config do
		if Config[i][FromType] == FromValue and Config[i][ToType] ~= nil then
			--sb.logInfo("Value = " .. sb.print(Config[i][ToType]));
			return Config[i][ToType];
		end
	end
	error("Could not find Value ( " .. sb.print(FromValue) .. " ) that is of type ( " .. sb.print(FromType) .. " )");
end

Relations.GetConduitOfFacade = function(facadeName)
	if string.find(string.lower(facadeName),"occlude") ~= nil then
		return Relations.Convert(Relations.Types.OccludedFacade,Relations.Types.Normal,facadeName);
	else
		return Relations.Convert(Relations.Types.NormalFacade,Relations.Types.Normal,facadeName);
	end
end



















end
