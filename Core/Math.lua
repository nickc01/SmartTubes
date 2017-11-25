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

function rect.intersect(A,B)
	local Rect = {};

end
function rect.copy(A)
	return {A[1],A[2],A[3],A[4]};
end
