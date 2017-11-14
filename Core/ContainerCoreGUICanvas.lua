
ContainerCore = {};

local Slots = 0;

local SourceID;

function ContainerCore.Init(sourceID)
	if sourceID == nil then
		error("SourceID is required");
	end
	SourceID = sourceID;
end

function ContainerCore.SetCanvasAsInventory(Canvas,Width,Height,SpacingVec,StartCorner,Image)
	Image = Image or "/interface/actionbar/actionbarcover.png";
	--Width = Width or 1;
	--Height = Height or 1;
	SpacingVec = SpacingVec or {0,0};
	local ImageSize = root.imageSize(Image);
	if ImageSize == nil then
		error(sb.print(Image) .. " is an invalid image");
	end
	--StartCorner = StartCorner or {0,0};
	local Inventory = widget.bindCanvas(Canvas);
	local InvSize = Inventory:size();
	if Width == nil then
		if StartCorner == nil then
			Width = math.floor((InvSize[1] + SpacingVec[1]) / (ImageSize[1] + SpacingVec[1]));
		else
			Width = math.floor((InvSize[1] - StartCorner[1] + SpacingVec[2]) / (ImageSize[1] + SpacingVec[1]));
		end
	end
	if Height == nil then
		if StartCorner == nil then
			Height = math.floor((InvSize[2] + SpacingVec[1]) / (ImageSize[2] + SpacingVec[2]));
		else
			Height = math.floor((InvSize[2] - StartCorner[2] + SpacingVec[2]) / (ImageSize[2] + SpacingVec[2]));
		end
	end
	--[[local LeftOverSpaceWidth;
	if StartCorner == nil then
		LeftOverSpaceWidth = InvSize[1] / Width;
	else
		LeftOverSpaceWidth = (InvSize[1] - StartCorner[1]) / Width;
	end--]]
	sb.logInfo("Width = " .. sb.print(Width));
	sb.logInfo("InvSize = " .. sb.print(InvSize[1] - SpacingVec[1]));
	sb.logInfo("Space Per Piece = " .. sb.print((ImageSize[1] + SpacingVec[1])));
	sb.logInfo("Space Consumed = " .. sb.print(Width * (ImageSize[1] + SpacingVec[1])));
	sb.logInfo("Left Over 2 = " .. sb.print((InvSize[1] - SpacingVec[1]) - (Width * (ImageSize[1] + SpacingVec[1]))));
	local LeftOverSpace;
	if StartCorner == nil then
		LeftOverSpace = { (InvSize[1] + SpacingVec[1]) - (Width * (ImageSize[1] + SpacingVec[1])), (InvSize[2] + SpacingVec[2]) - (Height * (ImageSize[2] + SpacingVec[2])) };
	else
		LeftOverSpace = { (InvSize[1] + SpacingVec[1] - StartCorner[1]) - (Width * (ImageSize[1] + SpacingVec[1])), (InvSize[2] + SpacingVec[2] - StartCorner[2]) - (Height * (ImageSize[2] + SpacingVec[2])) };
	end
	sb.logInfo("LeftOverSpace = " .. sb.print(LeftOverSpace));
--	local MaxSizeWidth = 
	--local MaxSizeHeight = math.floor((InvSize[2] - StartCorner[2]) / (ImageSize[2] + SpacingVec[2]));
	sb.logInfo("Max Size Width = " .. sb.print(MaxSizeWidth));
	--Width = Width or (Inventory:size()[1])
	--Width = Width or 1;
	--Width = MaxSizeWidth;
	--Height = MaxSizeHeight;
	local HalfX1 = math.floor(LeftOverSpace[1] / 2);
	local HalfX2 = math.floor(LeftOverSpace[1] - HalfX1);
	local HalfY1 = math.floor(LeftOverSpace[2] / 2);
	local HalfY2 = math.floor(LeftOverSpace[2] - HalfY1);
	if StartCorner == nil then
		StartCorner = {math.min(HalfX1,HalfX2),math.min(HalfY1,HalfY2)};
	end
	Slots = Slots + (Width * Height);
	for i=0,Width - 1 do
		for j=0,Height - 1 do
			Inventory:drawImage(Image,{StartCorner[1] + (ImageSize[1] * i) + (SpacingVec[1] * i),(StartCorner[2] + (ImageSize[2] * j) + (SpacingVec[2] * j))});
		end
	end
	_ENV[Canvas .. "C"] = function(A,B,C)
		sb.logInfo("Click");
		sb.logInfo("A = " .. sb.print(A));
		sb.logInfo("B = " .. sb.print(B));
		sb.logInfo("C = " .. sb.print(C));
	end
	_ENV[Canvas .. "K"] = function(A,B,C)
		sb.logInfo("Key");
		sb.logInfo("A = " .. sb.print(A));
		sb.logInfo("B = " .. sb.print(B));
		sb.logInfo("C = " .. sb.print(C));
	end
end

function ContainerCore.Update()
	
end