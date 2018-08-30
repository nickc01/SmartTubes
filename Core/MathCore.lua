if RectCore ~= nil then return nil end;
--Declaration

--Public Table
RectCore = {};
local RectCore = RectCore;
VectorCore = {}
local VectorCore = VectorCore;

--Variables

--Functions

--Flips the Rect on either the horizontal, or vertical, or both axis
function RectCore.Flip(rect,flipx,flipy,makeNewTable)
	if flipx == true and flipy == true then
		if makeNewTable == true then
			return {rect[3],rect[4],rect[1],rect[2]};
		else
			rect[1],rect[2],rect[3],rect[4] = rect[3],rect[4],rect[1],rect[2];
			return rect;
		end
	elseif flipx == true then
		if makeNewTable == true then
			return {rect[3],rect[2],rect[1],rect[4]};
		else
			rect[1],rect[3] = rect[3],rect[1];
			return rect;
		end
	elseif flipy == true then
		if makeNewTable == true then
			return {rect[1],rect[4],rect[3],rect[2]};
		else
			rect[2],rect[4] = rect[4],rect[2];
			return rect;
		end
	end
	if makeNewTable == true then
		return {rect[1],rect[2],rect[3],rect[4]};
	else
		return rect;
	end
end

--Adds a vector to a rect
function RectCore.VectorAdd(rect,vector)
	return {rect[1] + vector[1],rect[2] + vector[2],rect[3] + vector[1],rect[4] + vector[2]};
end

--Returns whether the rects are equal
function RectCore.Equal(a,b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4];
end

--Multiplies the base position by some amount without changing the width and height
function RectCore.BaseMultiply(rect,amount)
	local Difference = {rect[3] - rect[1],rect[4] - rect[2]};
	local NewBase = {rect[1] * amount,rect[2] * amount};
	return {NewBase[1],NewBase[2],NewBase[1] + Difference[1],NewBase[2] + Difference[2]};
end

--Subtracts two vectors
function VectorCore.Subtract(A,B)
	return {A[1] - B[1],A[2] - B[2]};
end

--Returns true if the rects intersect
function RectCore.Intersect(A,B)
	return not (A[1] > B[3] or A[2] > B[4] or A[3] < B[1] or A[4] < B[2]);
end

function RectCore.VectIntersect(Rect,Vect)
	return not (Vect[1] > Rect[3] or Vect[1] < Rect[1] or Vect[2] > Rect[4] or Vect[2] < Rect[2]);
end
