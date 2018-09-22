

--Declaration
Callback = {};
local Callback = Callback;

--Variables

--Functions

--Creates a callback list ready for use
function Callback.Create()
	local Table;
	Table = setmetatable({
		Add = function(func)
			local Meta = getmetatable(Table);
			if Meta.List == nil then
				Meta.List = {};
			end
			for i=1,#Meta.List do
				if Meta.List[i] == func then
					return nil;
				end
			end
			Meta.List[#Meta.List + 1] = func;
			return nil;
		end,
		Remove = function(func)
			local Meta = getmetatable(Table);
			if Meta.List == nil then
				Meta.List = {};
			end
			for i=1,#Meta.List do
				if Meta.List[i] == func then
					table.remove(Meta.List,i);
					return nil;
				end
			end
			return nil;
		end,
		Call = function(...)
			getmetatable(Table).__call(...);
		end
	},{
		__call = function(tbl,...)
			local Meta = getmetatable(tbl);
			if Meta.List == nil then
				Meta.List = {};
			end
			for i=1,#Meta.List do
				Meta.List[i](...);
			end
			return nil;
		end
	});
	return Table;
end

--Creates a collection of callbacks ready to use
function Callback.CreateCollection()
	local Table = setmetatable({},{
		__index = function(tbl,callback)
			if rawget(tbl,callback) == nil then
				rawset(tbl,callback,Callback.Create());
			end
			return rawget(tbl,callback);
		end,
		__newindex = function(tbl,callback,v)
			return nil;
		end,
		__call = function(tbl,callback,...)
			return tbl[callback](...);
		end
	});
	return Table;
end