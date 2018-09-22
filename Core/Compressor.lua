--This file provides a way to comress and decompress large tables, so they can be more easily sent over the network
if Compressor ~= nil then return nil end;

--Declaration
Compressor = {};
local Compressor = {};

--Variables

--Functions

--Compresses the Table
function Compressor.Compress(tbl)
    if type(tbl) ~= "table" then return tbl end;
    local Tables = {};
    local RecurseFunction;
    RecurseFunction = function(destination,tbl)
        
    end
end
