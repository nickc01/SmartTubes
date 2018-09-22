if ColorCore ~= nil then return nil end

--Declaration
ColorCore = {};
local ColorCore = ColorCore;

--Variables

--Functions

--Converts RGB to HSV
function ColorCore.RGBToHSV(R,G,B)
	local DR,DG,DB = R / 255,G / 255,B / 255;
	local CMax = math.max(DR,DG,DB);
	local CMin = math.min(DR,DG,DB);
	--local CMax,CMin = ;
	local Delta = CMax - CMin;
	local Hue;
	if Delta == 0 then
		Hue = 0;
	elseif CMax == DR then
		Hue = 60 * (((DG - DB) / Delta) % 6);
	elseif CMax == DG then
		Hue = 60 * (((DB - DR) / Delta) + 2);
	elseif CMax == DB then
		Hue = 60 * (((DR - DG) / Delta) + 4);
	end
	local Sat;
	if CMax == 0 then
		Sat = 0;
	else
		Sat = Delta / CMax;
	end
	local Value = CMax;
	return Hue,Sat,Value;
end

--Converts HSV To RGB
function ColorCore.HSVToRGB(H,S,V)
	H = H % 360;
	local Chroma = S * V;
	local X = Chroma * (1 - math.abs(((H / 60) % 2) - 1));
	local M = V - C;
	local DR,DG,DB;
	if 0 <= H and H < 60 then
		DR,DG,DB = Chroma,X,0;
	elseif 60 <= H and H < 120 then
		DR,DG,DB = X,Chroma,0;
	elseif 120 <= H and H < 180 then
		DR,DG,DB = 0,Chroma,X;
	elseif 180 <= H and H < 240 then
		DR,DG,DB = 0,X,Chroma;
	elseif 240 <= H and H < 300 then
		DR,DG,DB = X,0,Chroma;
	elseif 300 <= H and H < 360 then
		DR,DG,DB = Chroma,0,X;
	end
	return DR * 255,DG * 255,DB * 255;
end