
if Versioning == nil then
	Versioning = {};
	local Versioning = Versioning;
	local VersionFuncs = {};
	local CurrentVersion;
	local ForceMode;

	Versioning.GetCurrentVersion = function()
		if CurrentVersion == nil then
			CurrentVersion = root.assetJson("/Core/Versioning.json").Version;
		end
		return CurrentVersion;
	end

	local GetForceVersionMode = function()
		if ForceMode == nil then
			ForceMode = root.assetJson("/Core/Versioning.json").ForceVersionFuncs or false;
		end
		return ForceMode;
	end

	Versioning.AddLessOrEqualVersion = function(version,func)
		VersionFuncs[#VersionFuncs + 1] = {
			Version = version,
			Func = func,
			Mode = 5
		}
	end

	Versioning.AddLessVersion = function(version,func)
		VersionFuncs[#VersionFuncs + 1] = {
			Version = version,
			Func = func,
			Mode = 4
		}
	end

	Versioning.AddGreaterOrEqualVersion = function(version,func)
		VersionFuncs[#VersionFuncs + 1] = {
			Version = version,
			Func = func,
			Mode = 3
		}
	end

	Versioning.AddEqualVersion = function(version,func)
		VersionFuncs[#VersionFuncs + 1] = {
			Version = version,
			Func = func,
			Mode = 2
		}
	end

	Versioning.AddGreaterVersion = function(version,func)
		VersionFuncs[#VersionFuncs + 1] = {
			Version = version,
			Func = func,
			Mode = 1
		}
	end

	Versioning.AddVersion = Versioning.AddGreaterOrEqualVersion;

	local Once = false;

	Versioning.ExecuteOnce = function()
		if Once == false then
			Once = true;
			Versioning.Execute();
		end
	end

	Versioning.Execute = function()
		local StoredVersion = config.getParameter("StoredVersion",-1);
		local CurrentVersion = Versioning.GetCurrentVersion();
		if GetForceVersionMode() == false and StoredVersion == CurrentVersion then return nil end;
		for k,i in ipairs(VersionFunc) do
			if i.Mode == 3 then
				if i.Version >= CurrentVersion then
					i.Func(i.Version,CurrentVersion);
				end
			elseif i.Mode == 2 then
				if i.Version == CurrentVersion then
					i.Func(i.Version,CurrentVersion);
				end
			elseif i.Mode == 1 then
				if i.Version > CurrentVersion then
					i.Func(i.Version,CurrentVersion);
				end
			elseif i.Mode == 4 then
				if i.Version > CurrentVersion then
					i.Func(i.Version,CurrentVersion);
				end
			elseif i.Mode == 5 then
				if i.Version <= CurrentVersion then
					i.Func(i.Version,CurrentVersion);
				end
			end
		end
		object.setConfigParameter("StoredVersion",CurrentVersion);
	end
end



