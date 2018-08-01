

--Declaration
CraftingUI = {};
local CraftingUI = CraftingUI;

--Variables
local CraftingItemList = "craftableItemsArea.itemList";
local SlotsPerRow = 12;
CraftingUI.Callbacks = setmetatable({},{
	__index = function(tbl,k)
		local Value = rawget(tbl,k);
		if Value == nil then
			return nil;
		else
			return Value;
		end
	end,
	__newindex = function(tbl,k,v)
		local Value = rawget(tbl,k);
		if Value == nil then
			Value = {v};
			rawset(tbl,k,Value);
			return Value;
		else
			Value[#Value + 1] = v;
			return Value;
		end
	end,
	__call = function(tbl,callbackName,...)
		local functions = CraftingUI.Callbacks[callbackName];
		if functions ~= nil then
			for i=1,#functions do
				functions[i](...);
			end
		end
	end});

--Functions

--Initializes the Crafting UI
function CraftingUI.Initialize()
	widget.registerMemberCallback(CraftingItemList,"__SlotClick__",__SlotClick__);
	widget.registerMemberCallback(CraftingItemList,"__SlotRightClick__",__SlotRightClick__);
	for row=1,20 do
		local NewSlot = widget.addListItem(CraftingItemList);
		local Full = CraftingItemList .. "." .. NewSlot;
		for slot=1,SlotsPerRow do
			local GlobalSlot = (row - 1) * SlotsPerRow + slot;
			local SlotPath = Full .. "." .. "slot" .. slot;
			widget.setVisible(SlotPath,true);
			widget.setVisible(SlotPath .. "count",true);
			widget.setItemSlotItem(SlotPath,{name = "perfectlygenericitem",count = 1});
			widget.setText(SlotPath .. "count",tostring(GlobalSlot));
		end
	end
end



__SlotClick__ = function(_,data)
	CraftingUI.Callbacks("SlotClick",tonumber(data));
end

__SlotRightClick__ = function(_,data)
	CraftingUI.Callbacks("SlotRightClick",tonumber(data));
end