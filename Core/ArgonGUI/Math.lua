vec = {};
local vec = vec;
rect = {};
local rect = rect;

function vec.add(A,B)
	return {A[1] + B[1],A[2] + B[2]};
end

function vec.sub(A,B)
	return {A[1] - B[1],A[2] - B[2]};
end

function rect.vecAdd(A,B)
	return {A[1] + B[1],A[2] + B[2],A[3] + B[1],A[4] + B[2]};
end

function rect.vecSub(A,B)
	return {A[1] - B[1],A[2] - B[2],A[3] - B[1],A[4] - B[2]};
end
function rect.minimize(A)
	return {0,0,A[3] - A[1],A[4] - A[2]};
end

function rect.intersection(A,B)
	return {math.max(A[1],B[1]),math.max(A[2],B[2]),math.min(A[3],B[3]),math.min(A[4],B[4])};

end
function rect.copy(A)
	return {A[1],A[2],A[3],A[4]};
end

function rect.isWithin(Source,Target)
	return	Target[1] >= Source[1] and
			Target[2] >= Source[2] and
			Target[3] <= Source[3] and
			Target[4] <= Source[4];
end

--If Target falls within Source
function rect.cut(Source,Target)
	local FinalRect = {};
	local OffsetFromOriginal = {};
	if Target[1] < Source[1] then
		FinalRect[1] = Source[1];
		OffsetFromOriginal[1] = Source[1] - Target[1];
	else
		FinalRect[1] = Target[1];
		OffsetFromOriginal[1] = 0;
	end
	if Target[2] < Source[2] then
		FinalRect[2] = Source[2];
		OffsetFromOriginal[2] = Source[2] - Target[2];
	else
		FinalRect[2] = Target[2];
		OffsetFromOriginal[2] = 0;
	end
	if Target[3] > Source[3] then
		FinalRect[3] = Source[3];
		OffsetFromOriginal[3] = Source[3] - Target[3];
	else
		FinalRect[3] = Target[3];
		OffsetFromOriginal[3] = 0;
	end
	if Target[4] > Source[4] then
		FinalRect[4] = Source[4];
		OffsetFromOriginal[4] = Source[4] - Target[4];
	else
		FinalRect[4] = Target[4];
		OffsetFromOriginal[4] = 0;
	end
	return FinalRect,OffsetFromOriginal;
end

function rect.isInverted(A)
	return A[4] <= A[2] or A[3] <= A[1];
end

--[[function isWithin(A,B)
	return A[1] >= B[1] and A[1] <= B[3] and A[3] >= B[1] and A[3] <= B[3] and A[2] >= B[2] and A[2] <= B[4] and A[4] >= B[2] and A[4] <= B[4];
end--]]

function rect.intersects(first, second)
  if first[1] > second[3]
     or first[3] < second[1]
     or first[2] > second[4]
     or first[4] < second[2] then
    return false
  else
    return true
  end
end
