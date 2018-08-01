if AllItems ~= nil then return nil end;
require("/Core/UICore.lua");

--Declaration
AllItems = {};
local AllItems = AllItems;

--Variables
local AllItemsBackground = "/Blocks/Conduit Terminal/UI/Window/AllItemsArea.png";
local AllItemsBackgroundSize;
local Initialized = false;
local Enabled = false;
local Canvas;
local Size;
local GlideDestination;
local GlideSpeed = 6;
local Position;
local SourceID;
local AllItemsDefaultPosition = {120,-169};
local AllItemsOpenPosition = {120,2};
local BoundElements = {};
local Loading = false;
local SlotsPerRow = 12;
local AllItemsList = "allItemsInventoryArea.itemList";
local SlotRows = {};
local MainLoadingRoutine;
local LoadingCircleRoutine;
local BufferSetRoutine;
local Loading = false;
local LoadingCircleRotation;
local LoadingCircleRotationSpeed = 7;
local ConduitContainerUUIDMap = {};
local ItemBuffer = {};
local NumericItemTable = {};
local InventoryItems = {};
local InventoryItemsRefreshable = true;
local SettingInventoryItems = false;
local InternalInventoryItems = {};
local InternalInventorySize = 0;
local FPS;
local SortingAlgoritm = function(item1,item2) return item1.count > item2.count end;
local SearchKeyword = "";
local SearchAlgorithm = function(Item,keyword) return string.find(string.lower(Item.name),string.lower(keyword)) ~= nil end;
local SearchRoutine;
local UniversalRefreshRoutine;
local SelectedItem;
local AddedContainers = {};
local Buffer = {
    Modes = {
        Default = {
            List = {},
            Buffer = {},
            Updated = false,
            CurrentlyZero = {},
            Algorithm = function(item,sourceID,sourceInfo) return item end,
            ContainerAlgorithm = function(container,sourceID,sourceInfo) return true end,
            AddedContainers = {}
        }
    },
    Current = "Default"};
local CurrentSortingMode = "Default";
local PatternCharacters = {".","%","(",")","+","-","*","?","[","]","^","$"};
local ConduitContentsBatched;


--Functions
local Update;
local AddAllBoundElements;
local BindElement;
local __SlotClick__;
local __SlotRightClick__;
local OnEnable;
local ExecuteScript;
local ExecuteScriptAsync;
local SendEntityMessageAsync;
local GetDecimalPlace;
local NumberToString;
local IfNumEqual;
local SetSortingAlgorithm;
local SetSearchKeyword;
local SetSearchAlgorithm;
local ApplySearch;
local StartUpAllItemsArea;
local SetSelectedItem;
local GetTableChanges;
local AddContainer;
local RemoveContainer;
local AddAllItemBuffers;
local GetConduitContentsAsync;
local GetConduitContentsCached;
local StartConduitContentsBatch;
local GetConduitContentsBatch;
local LoopOrOnce;
local Depatternize;
--TEST
--local Result;
--local AddOnDoneLoadingFunction;

--Initializes the All Items Area
function AllItems.Initialize()
    if Initialized == true then return nil end;
    --TEST
    --local Test = coroutine.create(function(path)
    --    sb.logInfo("Path = " .. sb.print(path));
     --   Result = root.assetJson(path);
    --end);
    --coroutine.resume("Blocks/Conduits/Item Conduit/ItemTest.object");
    --sb.logInfo("Result = " .. sb.print(Result));
    FPS = 1 / script.updateDt();
    SourceID = pane.sourceEntity();
    Initialized = true;
        AllItemsBackgroundSize = root.imageSize(AllItemsBackground);
    local OldUpdate = update;
    update = function(dt)
        if OldUpdate ~= nil then
            OldUpdate(dt);
        end
        Update(dt);
    end
    widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotClick__",__SlotClick__);
    widget.registerMemberCallback("allItemsInventoryArea.itemList","__SlotRightClick__",__SlotRightClick__);
    Canvas = widget.bindCanvas("allItemsCanvas");
    GlideDestination = AllItemsDefaultPosition;
    widget.setPosition("allItemsCanvas",GlideDestination);
    Position = {GlideDestination[1],GlideDestination[2]};
    Size = Canvas:size();
    Canvas:drawImageRect(AllItemsBackground,{0,0,AllItemsBackgroundSize[1],AllItemsBackgroundSize[2]},{0,0,Size[1],Size[2]});
    AddAllBoundElements();
    AddAllItemBuffers();
    StartUpAllItemsArea();
end

--Adds all of the buffer types needed
AddAllItemBuffers = function()
    Buffer.AddNewBuffer("DefaultExtractable",function(item,sourceID,sourceInfo)
        if sourceInfo.Extractable == true then
            return item;
        else
            return false;
        end
    end,
    function (container,sourceID,sourceInfo)
        if sourceInfo.Extractable == true then
            return true;
        else
            return false;
        end
    end);
end

--Adds any bound elements
AddAllBoundElements = function()
    BindElement("allItemsInventoryArea");
    BindElement("allItemsLoadingCircle");
    BindElement("allItemsSearchBox");
    BindElement("allItemsSettingsArea");
    BindElement("allItemsOpenerArrow");
    BindElement("allItemsSearchIcon");
    BindElement("allItemsSelectedItemSlot");
    BindElement("allItemsSelectedItemBackground");
    BindElement("allItemsSelectedItemAmountBox");
    BindElement("allItemsExtractButton");
    BindElement("allItemsExtractableCheckbox");
    widget.setVisible("allItemsLoadingCircle",false);
    widget.setVisible("allItemsSettingsArea",false);
    widget.setVisible("allItemsSearchIcon",false);
    widget.setVisible("allItemsSearchBox",false);
    widget.setVisible("allItemsSelectedItemSlot",false);
    widget.setVisible("allItemsSelectedItemBackground",false);
    widget.setVisible("allItemsExtractButton",false);
    widget.setVisible("allItemsExtractableCheckbox",false);
end

--Binds an element to move with the All Items Canvas
BindElement = function(elementName)
    --BoundElements[#BoundElements + 1] = elementName;
    local RelativePosition = widget.getPosition(elementName);
    widget.setPosition(elementName,{AllItemsDefaultPosition[1] + RelativePosition[1],AllItemsDefaultPosition[2] + RelativePosition[2]});
    widget.setVisible(elementName,true);
    BoundElements[#BoundElements + 1] = {Name = elementName,RelativePosition = RelativePosition};
end


--Enables the All Items Area
function AllItems.Enable(bool)
    if bool == nil then
        bool = true;
    end
    if Enabled ~= bool then
        Enabled = bool;
        if Enabled == true then
            GlideDestination = AllItemsOpenPosition;
        else
            GlideDestination = AllItemsDefaultPosition;
        end
        OnEnable(bool);
    end
end

--TEST TEST TEST
local Counter = 0;

--The Update Loop for the All Items Area
Update = function(dt)
   --[[ Counter = Counter + dt;
   -- sb.logInfo("Counter = " .. sb.print(Counter));
    if Counter > 5 and Counter < 6 then
        Counter = 6;
       -- sb.logInfo("Setting");
        InventoryItems[500] = nil;
    end--]]
  --[[  for i=1,5 do
        InventoryItems[#InventoryItems + 1] = {name = "perfectlygenericitem",count = (#InventoryItems % 1000) + 1};
    end--]]
    --InventoryItems[500] = {name = "perfectlygenericitem",count = 1};
    --local CurrentPosition = widget.getPosition("allItemsCanvas");
    Position = {(GlideDestination[1] - Position[1]) / GlideSpeed + Position[1],(GlideDestination[2] - Position[2]) / GlideSpeed + Position[2]};
   -- sb.logInfo("Position = " .. sb.print(Position));
    widget.setPosition("allItemsCanvas",Position);
    for i=1,#BoundElements do
        local Element = BoundElements[i];
        widget.setPosition(Element.Name,{Element.RelativePosition[1] + Position[1],Element.RelativePosition[2] + Position[2]});
    end
    if GlideDestination[1] ~= Position[1] and math.abs(GlideDestination[1] - Position[1]) < 0.3 then
        --GlideDestination[1] = Position[1];
        Position[1] = GlideDestination[1];
    end
    if GlideDestination[2] ~= Position[2] and math.abs(GlideDestination[2] - Position[2]) < 0.3 then
       -- GlideDestination[2] = Position[2];
       Position[2] = GlideDestination[2];
    end
end

--Called when the AllItemsArea is clicked
function __AllItemsAreaClick__(position,buttonType,isDown)
    if buttonType == 0 and isDown == true then
        if not Enabled then
            AllItems.Enable(not Enabled);
        end
    end
end

--Called when the slot is clicked on
__SlotClick__ = function(name,data)
    if Loading == false then
       -- sb.logInfo("Clicked on slot = " .. sb.print(data));
       -- sb.logInfo("Item in Slot = " .. sb.print(InventoryItems.GetItem(tonumber(data))))
       -- sb.logInfo("Item in buffer = " .. sb.print(Buffer.GetFromBuffer(InventoryItems.GetItem(tonumber(data)),"DefaultExtractable")));
        --SetSelectedItem(InventoryItems.GetItemWithSort(tonumber(data)));
        local ItemInSlot = InventoryItems.GetItem(tonumber(data));
        --sb.logInfo("Item In Slot = " .. sb.print(ItemInSlot));
        local BufferItem = Buffer.GetFromBuffer(ItemInSlot,"DefaultExtractable");
        if BufferItem == nil then
            if ItemInSlot ~= nil then
                BufferItem = {name = ItemInSlot.name,count = 0,parameters = ItemInSlot.parameters};
            end
        end
        SetSelectedItem(BufferItem);
    end
end

--Called when the slot is right clicked
__SlotRightClick__ = function(name,data)
    if Loading == false then
        SetSelectedItem(nil);
    end
end










--Called when the Enable Variable is changed
OnEnable = function(enabled)
    if enabled == true then
        
    else
       --[[ if MainLoadingRoutine ~= nil then
            UICore.CancelCoroutine(MainLoadingRoutine);
            MainLoadingRoutine = nil;
        end--]]
    end
    widget.setVisible("allItemsSettingsArea",enabled);
    widget.setVisible("allItemsSearchIcon",enabled);
    widget.setVisible("allItemsSearchBox",enabled);
    widget.setVisible("allItemsExtractableCheckbox",enabled);
    widget.focus("allItemsSearchBox");
end

--Calls a script on the passed in object on the server side
--Returns a promise to that call
ExecuteScript = function(object,functionName,...)
    return world.sendEntityMessage(SourceID,"ExecuteScript",object,functionName,...);
end

--Calls a script on the passed in object on the server side
--Returns the value that was returns from the server function
--THIS MUST BE USED IN A COUROUTINE
ExecuteScriptAsync = function(object,functionName,...)
    local Promise = ExecuteScript(object,functionName,...);
    while not Promise:finished() do
        --sb.logInfo("YIELD");
        coroutine.yield();
    end
    return Promise:result();
end

--Sends an entity message async
--THIS MUST BE USED IN A COROUTINE
SendEntityMessageAsync = function(object,functionName,...)
    local Promise = world.sendEntityMessage(object,functionName,...);
    while not Promise:finished() do
        coroutine.yield();
    end
    return Promise:result();
end

--Returns the (n * 10)th decimal place of a number (ignores negative numbers)
GetDecimalPlace = function(num,n)
    num = math.abs(num);
    for i=1,n do
        local Number,Decimal = math.modf(num);
        if Decimal == nil then return 0 end;
        num = Decimal * 10;
        if num == 0 then
            return 0;
        end
    end
    return math.floor(num);
end

--Converts a number into a string variant of only 4 characters
NumberToString = function(num)
    num = math.floor(num);
    --Million
    if num >= 1000000 then
        local Number = num / 1000000;
        local Final = math.floor(Number);
        if Number < 10 then
            Final = Final + (GetDecimalPlace(Number,1) / 10);
        end
        if Number < 1 then
            Final = Final + (GetDecimalPlace(Number,2) / 100);
        end
        --local Tenth = GetDecimalPlace(Number,1);
        --local Hundreth = GetDecimalPlace(Number,2);
        --local Final = Number + (Tenth / 10) + (Hundreth / 100);
       -- sb.logInfo("FINAL NUMBER M = " .. sb.print(Final));
        return tostring(Final) .. "M";
    --Thousand
    elseif num >= 1000 then
        local Number = num / 1000;
        local Final = math.floor(Number);
        if Number < 10 then
            Final = Final + (GetDecimalPlace(Number,1) / 10);
        end
        if Number < 1 then
            Final = Final + (GetDecimalPlace(Number,2) / 100);
        end
        --local Tenth = GetDecimalPlace(Number,1);
        --local Hundreth = GetDecimalPlace(Number,2);
        --local Final = Number + (Tenth / 10) + (Hundreth / 100);
        --sb.logInfo("FINAL NUMBER K = " .. sb.print(Final));
        return tostring(Final) .. "K";
        --Leave Alone
    else
        return tostring(num);
    end
end



--Inventory Items Functions

--Sets the item at the slot
function InventoryItems.SetItem(item,slot,forceSyncronous)
    if forceSyncronous ~= true and coroutine.running() ~= nil then
        while(SettingInventoryItems == true) do
            coroutine.yield();
        end
    end
    --sb.logInfo("Setting 3");    
    SettingInventoryItems = true;
    --sb.logInfo("Value In = " .. sb.print(rawget(InternalInventoryItems,slot)));
    --sb.logInfo("Value Out = " .. sb.print(item));
   -- sb.logInfo("Type In = " .. sb.print(type(rawget(InternalInventoryItems,slot))));
   -- sb.logInfo("Type Out = " .. sb.print(type(item)));
   --[[ if type(rawget(InternalInventoryItems,slot)) == type(item) then
        --sb.logInfo("Short Circuit");
        SettingInventoryItems = false;
        return nil;
    end--]]
    local RowNumber = math.ceil(slot / SlotsPerRow);
    local SlotAtRow = ((slot - 1) % SlotsPerRow) + 1;
    if RowNumber > #SlotRows then
        if RowNumber - 1 ~= 0 then
            for row=#SlotRows,RowNumber - 1 do
                if SlotRows[row] == nil then
                    local NewSlot = widget.addListItem(AllItemsList);
                    SlotRows[row] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
                end
                local Top = SlotRows[row].Full;
                for i=1,SlotsPerRow do
                     widget.setVisible(Top .. ".slot" .. i,true);
                    widget.setVisible(Top .. ".slot" .. i .. "background",true);
                    widget.setData(Top .. ".slot" .. i,((row - 1) * SlotsPerRow) + i);
                end
            end
        end
        local NewSlot = widget.addListItem(AllItemsList);
        SlotRows[RowNumber] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
    end
    local Slot = SlotRows[RowNumber].Full .. ".slot" .. SlotAtRow;
    if item == nil then
        widget.setItemSlotItem(Slot,nil);
        widget.setText(Slot .. "count","");
    else
        widget.setItemSlotItem(Slot,{name = item.name,count = 1,parameters = item.parameters});
        widget.setText(Slot .. "count",NumberToString(item.count));
    end
    rawset(InternalInventoryItems,slot,item);
    --InternalInventoryItems[slot] = item;
    local IsNil = true;
    for row=#SlotRows,1,-1 do
        local RowPath = SlotRows[row].Full;
        local RowEmpty = true;
        for slot=SlotsPerRow,1,-1 do
            local SlotPath = RowPath .. ".slot" .. slot;
            -- sb.logInfo("SLOTPATH = " .. sb.print(SlotPath));
            -- sb.logInfo("Item = " .. sb.print(widget.itemSlotItem(SlotPath)));
            if IsNil == true then
                IsNil = widget.itemSlotItem(SlotPath) == nil;
            else
                if widget.itemSlotItem(SlotPath) ~= nil then
                    break;
                end
            end
            if RowEmpty == true then
                RowEmpty = widget.itemSlotItem(SlotPath) == nil;
            end
            widget.setVisible(SlotPath,not IsNil);
            widget.setVisible(SlotPath .. "background",not IsNil);
        end
        if IsNil and RowEmpty then
            table.remove(SlotRows,row);
            widget.removeListItem(AllItemsList,row);
        end
    end
    SettingInventoryItems = false;
    --sb.logInfo("InternalInventoryItems = " .. sb.print(InternalInventoryItems));
end

--Gets the item at the slot
function InventoryItems.GetItem(slot)
    --return rawget(InternalInventoryItems,slot);
   -- sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
   --sb.logInfo("Internal Inventory Items = " .. sb.print(#InternalInventoryItems));
    return InternalInventoryItems[slot];
end

--Gets the item with the sorting and searching applied
--function InventoryItems.GetItemWithSort(slot)
    --return ApplySearch(InternalInventoryItems)[slot];
--end

--Refreshes the specified slot only
function InventoryItems.RefreshSlot(slot)
    local Item = ApplySearch(InternalInventoryItems)[slot];
    if type(Item) ~= "table" then
        widget.setItemSlotItem(SlotPath,nil);
        widget.setText(SlotPath .. "count","");
    else
        widget.setItemSlotItem(SlotPath,{name = Item.name,count = 1,parameters = Item.parameters});
        widget.setText(SlotPath .. "count",NumberToString(Item.count));
        widget.setVisible(SlotPath,true);
        widget.setVisible(SlotPath .. "background",true);
    end
end

--Refreshes the Items in the Inventory
function InventoryItems.Refresh()
    if coroutine.running() ~= nil then
        while(SettingInventoryItems == true) do
            coroutine.yield();
        end
    end
    if #InternalInventoryItems == 0 then
        InventoryItems.Clear(true);
    end
    --sb.logInfo("Setting 2");    
    SettingInventoryItems = true;
    local HideSlot = true;
    --sb.logInfo("InternalInventoryItems = " .. sb.print(InternalInventoryItems));    
    local SortedTable = ApplySearch(InternalInventoryItems);
    for row=#SlotRows,1,-1 do
        for slot=SlotsPerRow,1,-1 do
            local GlobalSlot = (row - 1) * SlotsPerRow + slot;
            local SlotPath = SlotRows[row].Full .. ".slot" .. slot;
            local Item = SortedTable[GlobalSlot];
            --sb.logInfo("Item = " .. sb.print(Item));
            --sb.logInfo("Global Slot = " .. sb.print(GlobalSlot));
            if type(Item) ~= "table" then
                widget.setItemSlotItem(SlotPath,nil);
                widget.setText(SlotPath .. "count","");
            else
                HideSlot = false;
                widget.setItemSlotItem(SlotPath,{name = Item.name,count = 1,parameters = Item.parameters});
                widget.setText(SlotPath .. "count",NumberToString(Item.count));
                widget.setVisible(SlotPath,true);
                widget.setVisible(SlotPath .. "background",true);
            end
            if HideSlot == true then
               -- sb.logInfo("Removing Slot");                
                widget.setVisible(SlotPath,false);
                widget.setVisible(SlotPath .. "background",false);
            end
        end
        if HideSlot == true then
            --sb.logInfo("Removing Row");
            widget.removeListItem(AllItemsList,row);
            table.remove(SlotRows,row);
        end
    end
    SettingInventoryItems = false;
end

--Sets all the slots to a table
--If topDown is true, then it will refresh from the top down
function InventoryItems.SetAllSlots(tbl,topDown,forceSyncronous)
    if InventoryItemsRefreshable == false then return nil end;
    if forceSyncronous ~= true and coroutine.running() ~= nil then
        while(SettingInventoryItems == true or InventoryItemsRefreshable == false) do
            coroutine.yield();
        end
    end
   -- sb.logInfo("Running");
    SettingInventoryItems = true;
    local Injection;
    if forceSyncronous ~= true and coroutine.running() ~= nil then
        Injection = UICore.AddCoroutineInjection(function()
           -- sb.logInfo("INJECTION!!!");
            --sb.logInfo("Stopping");            
            InventoryItems.Clear(true);
            InternalInventoryItems = {};
            InternalInventorySize = 0;
            SettingInventoryItems = false;
        end);
    end
    if tbl == nil then
        InventoryItems.Clear(true);
        InternalInventoryItems = {};
        SettingInventoryItems = false;
        InternalInventorySize = 0;
        return nil;
    end
    local SortedTable = ApplySearch(tbl);
    --sb.logInfo("Size = " .. sb.print(#SortedTable));
    local MaxSlot = #SortedTable;
    local RowNumber = math.ceil(MaxSlot / SlotsPerRow);
    local SlotAtRow = ((MaxSlot - 1) % SlotsPerRow) + 1;
    if InternalInventoryItems ~= nil then
        if InternalInventorySize ~= #SortedTable then
            if #SlotRows < RowNumber then
                for i=#SlotRows,RowNumber do
                    local NewSlot = widget.addListItem(AllItemsList);
                    SlotRows[#SlotRows + 1] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
                end
            elseif #SlotRows > RowNumber then
               --[[ for i=RowNumber,#SlotRows,-1 do
                    widget.removeListItem(AllItemsList,i);
                    table.remove(SlotRows,i);
                end--]]
                for i=#SlotRows,RowNumber + 1,-1 do
                    widget.removeListItem(AllItemsList,i - 1);
                    table.remove(SlotRows,i);
                end
            end
            --sb.logInfo("Slot Rows After = " .. sb.print(#SlotRows));
            InternalInventorySize = #SortedTable;
        end
    else
        for i=1,RowNumber do
            local NewSlot = widget.addListItem(AllItemsList);
            SlotRows[#SlotRows + 1] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
        end
    end
    local OldInventory = InternalInventoryItems;
    InternalInventoryItems = {};
    if topDown ~= true then
        --sb.logInfo("SLots 2 = " .. sb.print(#SlotRows));
        local Hide = true;
        for row=RowNumber,1,-1 do
            for slot=SlotsPerRow,1,-1 do
                --TODO Setup Slot
                local GlobalSlot = (row - 1) * SlotsPerRow + slot;
                local SlotPath = SlotRows[row].Full .. ".slot" .. slot;
                local Value = SortedTable[GlobalSlot];
                local Previous;
                if OldInventory ~= nil then
                    Previous = OldInventory[GlobalSlot];
                else
                    Previous = 0;
                end
                --If the slot is 
                --[[if Previous == nil or (Previous.count ~= Value.count) then

                end--]]
            -- sb.logInfo("Previous = " .. sb.print(Previous));
            -- sb.logInfo("Value = " .. sb.print(Value));
                if Previous == 0 or (Value ~= nil and (root.itemDescriptorsMatch(Value,Previous,true) == false or Previous.count ~= Value.count)) or (Value == nil and Value ~= Previous) then
                    if Value == nil then
                        if Hide then                
                            widget.setVisible(SlotPath,false);
                            widget.setVisible(SlotPath .. "background",false);
                            widget.setVisible(SlotPath .. "count",false);
                        else
                            widget.setVisible(SlotPath,true);
                            widget.setVisible(SlotPath .. "background",true);
                            widget.setVisible(SlotPath .. "count",true);
                            widget.setItemSlotItem(SlotPath,nil);
                            widget.setData(SlotPath,tostring(GlobalSlot));
                            widget.setText(SlotPath .. "count","");
                        end
                    else
                        Hide = false;
                        widget.setVisible(SlotPath,true);
                        widget.setVisible(SlotPath .. "background",true);
                        widget.setVisible(SlotPath .. "count",true);
                        widget.setItemSlotItem(SlotPath,{name = Value.name,count = 1,parameters = Value.parameters});
                        widget.setData(SlotPath,tostring(GlobalSlot));
                        widget.setText(SlotPath .. "count",NumberToString(Value.count));
                    end
                end
                if Value ~= nil then
                    InternalInventoryItems[GlobalSlot] = {name = Value.name,count = Value.count,parameters = Value.parameters};
                end
                if (GlobalSlot > 200 or not Enabled) and GlobalSlot % 2 == 0 and forceSyncronous ~= true and coroutine.running() ~= nil then
                    coroutine.yield();
                end
            end
            if forceSyncronous ~= true and coroutine.running() ~= nil then
                coroutine.yield();
            end
        end
    else
        --Find the slot where all other slots after it are hidden
        local HideSlot;
        for row=RowNumber,1,-1 do
            for slot=SlotsPerRow,1,-1 do
                local GlobalSlot = (row - 1) * SlotsPerRow + slot;
                if SortedTable[GlobalSlot] ~= nil then
                    HideSlot = GlobalSlot;
                    goto ExitFinder;
                end
            end
        end
        ::ExitFinder::
       -- sb.logInfo("SLots 1 = " .. sb.print(#SlotRows));
        if HideSlot ~= nil then
            local NormalTime;
            for row=1,RowNumber do
                --sb.logInfo("SliderValue = " .. sb.print(widget.getSliderValue(AllItemsList)));
                for slot=1,SlotsPerRow do
                    local GlobalSlot = (row - 1) * SlotsPerRow + slot;
                    local SlotPath = SlotRows[row].Full .. ".slot" .. slot;
                    if GlobalSlot > HideSlot then
                        widget.setVisible(SlotPath,false);
                        widget.setVisible(SlotPath .. "background",false);
                        widget.setVisible(SlotPath .. "count",false);
                    else
                        widget.setVisible(SlotPath,true);
                        widget.setVisible(SlotPath .. "background",true);
                        widget.setVisible(SlotPath .. "count",true);
                        widget.setData(SlotPath,tostring(GlobalSlot));
                        local Value = SortedTable[GlobalSlot];
                        local Previous;
                        if OldInventory ~= nil then
                            Previous = OldInventory[GlobalSlot];
                        else
                            Previous = 0;
                        end
                        if Previous == 0 or (Value ~= nil and (root.itemDescriptorsMatch(Value,Previous,true) == false or Previous.count ~= Value.count)) or (Value == nil and Value ~= Previous) then
                            if Value == nil then
                                widget.setItemSlotItem(SlotPath,nil);
                                widget.setText(SlotPath .. "count","");
                            else
                                widget.setItemSlotItem(SlotPath,{name = Value.name,count = 1,parameters = Value.parameters});
                                widget.setText(SlotPath .. "count",NumberToString(Value.count));
                            end
                        end
                        if Value ~= nil then
                            InternalInventoryItems[GlobalSlot] = {name = Value.name,count = Value.count,parameters = Value.parameters};
                        end
                        if (GlobalSlot > 200 or not Enabled) and GlobalSlot % 2 == 0 and forceSyncronous ~= true and coroutine.running() ~= nil then
                            coroutine.yield();
                        end
                        --[[if GlobalSlot > 100 then
                            if forceSyncronous ~= true and coroutine.running() ~= nil then
                                coroutine.yield();
                            end
                        end--]]
                    end
                end
                if forceSyncronous ~= true and coroutine.running() ~= nil then
                    coroutine.yield();
                end
            end
        end
    end
    if forceSyncronous ~= true and coroutine.running() ~= nil then
        UICore.RemoveCoroutineInjection(Injection);
    end
    --InternalInventoryItems = NewInventory;
    SettingInventoryItems = false;
    --sb.logInfo("Ending");    
end

--Clears the entire inventory
function InventoryItems.Clear(notTable)
    if notTable ~= true then
        InternalInventoryItems = {};
    end
    SlotRows = {};
    widget.clearListItems(AllItemsList);
end

--Shows the loading circle in the inventory Items Area
function InventoryItems.EnableLoading()
    if LoadingCircleRoutine == nil then
        --Create a loading circle function
        Loading = true;
        LoadingCircleRoutine = UICore.AddAsyncCoroutine(function()
            widget.setVisible("allItemsLoadingCircle",true);
            LoadingCircleRotation = 0;
            while (true) do
                LoadingCircleRotation = LoadingCircleRotation + coroutine.yield() * LoadingCircleRotationSpeed;
                widget.setImageRotation("allItemsLoadingCircle",LoadingCircleRotation);
            end
        end);
    end
end

--Hides the loading circle in the inventory Items Area
function InventoryItems.DisableLoading()
    if LoadingCircleRoutine ~= nil then
        Loading = false;
        UICore.CancelCoroutine(LoadingCircleRoutine);
        widget.setVisible("allItemsLoadingCircle",false);
        LoadingCircleRoutine = nil;
    end
end

--Returns "first" if a and b are equal, and "second" otherwise
IfNumEqual = function(a,b,first,second)
    if a == b then
        return first;
    else
        return second;
    end
end

--Sets the Current Sorting algorithm
SetSortingAlgorithm = function(func)
    SortingAlgoritm = func;
end

--Sets the Current Search keyword, set to "" for no searching to be applied
SetSearchKeyword = function(word)
    word = Depatternize(word);
    if SearchKeyword ~= word then
        if UniversalRefreshRoutine ~= nil then
            UICore.CancelCoroutine(UniversalRefreshRoutine);
        end
        SearchKeyword = word;
       -- if Loading == false then
            UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
                --sb.logInfo("Search Started");
                --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
                InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
                UICore.CancelCoroutine(UniversalRefreshRoutine);
            end,function()
                --sb.logInfo("Search Canceled");
                --SettingInventoryItems = false;
                UniversalRefreshRoutine = nil;
            end);
        --end
    end
end

--Sets the Current Search algorithm
SetSearchAlgorithm = function(func)
    SearchAlgorithm = func;
    if Loading == false then 
        InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
    end
end

-- Sets the selected Item in the right side pane
SetSelectedItem = function(item)
    SelectedItem = item;
    if SelectedItem ~= nil then
        widget.setVisible("allItemsSelectedItemSlot",true);
        widget.setVisible("allItemsSelectedItemBackground",true);
        widget.setItemSlotItem("allItemsSelectedItemSlot",{name = item.name,count = 1,parameters = item.parameters});
        widget.setVisible("allItemsSelectedItemAmountBox",true);
        widget.setText("allItemsSelectedItemAmountBox",tostring(item.count));
        widget.setVisible("allItemsExtractButton",true);
    else
        widget.setVisible("allItemsSelectedItemSlot",false);
        widget.setItemSlotItem("allItemsSelectedItemSlot",nil);
        widget.setVisible("allItemsSelectedItemBackground",false);
        widget.setVisible("allItemsSelectedItemAmountBox",false);
        widget.setVisible("allItemsExtractButton",false);
    end
end

--Applies the Search algorithm over a table and returns a new table with the results
ApplySearch = function(tbl)
    if SearchKeyword == "" then
        return tbl;
    end
    local NewTableCount = 0;
    local NewTable = {};
    for i=1,#tbl do
       -- sb.logInfo("Item = " .. sb.print(tbl[i]));
       -- sb.logInfo("Keyword = " .. sb.print(SearchKeyword));
        if SearchAlgorithm(tbl[i],SearchKeyword) == true then
           -- sb.logInfo("Matches");
            NewTableCount = NewTableCount + 1;
            NewTable[NewTableCount] = tbl[i];
        end
    end
    --sb.logInfo("Final = " .. sb.print(NewTable));
    return NewTable;
end

--Called when the all Items Area Search Box is updated
__allItemsSearchBoxUpdated = function()
    --[[if Loading then
        widget.setText("allItemsSearchBox","");
    else
        SetSearchKeyword(widget.getText("allItemsSearchBox"));
    end--]]
    local Text = widget.getText("allItemsSearchBox");
    SetSearchKeyword(widget.getText("allItemsSearchBox"));
end

--Starts Up the Routine that displays all the items
StartUpAllItemsArea = function()
    MainLoadingRoutine = UICore.AddAsyncCoroutine(function()
        --Set the Values to thier default state
        InventoryItemsRefreshable = false;
        InventoryItems.EnableLoading();
        InventoryItems.Clear();
        local Network = TerminalUI.GetNetwork();
        local NetworkInfo = TerminalUI.GetNetworkInfo();
        StartConduitContentsBatch(Network,NetworkInfo);
        --Go through all the conduits in the network
        for _,conduit in ipairs(Network) do
            local ConduitInfo = NetworkInfo[tostring(conduit)];
            if ConduitInfo == nil then goto Continue end;
            --Get the contents of the conduit
            --local Contents = GetConduitContentsAsync(conduit,true);
            local Contents = GetConduitContentsBatch(conduit,true);
            --If there is container connected to this conduit
            if Contents ~= nil then
                --Loop through all the containers and their contents
                for stringContainer,ContainerItems in pairs(Contents) do
                    --If the container is already added, then increment the container counter and move to the next container
                   --[[ if AddContainer(Container) == 1 then
                        --Add the contents of the container to the Buffer
                        for slot,item in ipairs(ContainerItems) do
                            Buffer.AddToBuffers(item,conduit,ConduitInfo);
                        end
                    end--]]
                    Buffer.AddContainerToBuffers(tonumber(stringContainer),ContainerItems,conduit,ConduitInfo);
                end
            end
            ::Continue::
        end
        --TODO -- TODO -- TODO Convert the buffer to a numerical table and display the table
        InventoryItemsRefreshable = true;
        local RefreshDone = false;
        UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
            --sb.logInfo("Search Started");
            --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
            InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
            UICore.CancelCoroutine(UniversalRefreshRoutine);
        end,function()
            --sb.logInfo("Search Canceled");
            --SettingInventoryItems = false;
            RefreshDone = true;
            UniversalRefreshRoutine = nil;
        end);
        --InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
        InventoryItems.DisableLoading();
        while(RefreshDone == false) do
            coroutine.yield();
        end
        --Go Into passive mode, where you make sure the inventory items stay up to date
        while(true) do
            local NewNetwork = TerminalUI.GetNetwork();
            --If the Network Has Changed
            if Network ~= NewNetwork then
                --Get all the added and removed conduits
                local Added,Removed = GetTableChanges(NewNetwork,Network);
                --Loop through all the Removed conduits and their contents
                for _,conduit in ipairs(Removed) do
                    if NetworkInfo[tostring(conduit)] == nil then
                        goto Continue;
                    end
                    local Contents = GetConduitContentsCached(conduit);
                    if Contents ~= nil then
                        for stringContainer,ContainerItems in pairs(Contents) do
                            Buffer.RemoveContainerFromBuffers(tonumber(stringContainer),ContainerItems,conduit,NetworkInfo[tostring(conduit)]);
                        end
                    end
                    EraseConduitContentsCache(conduit);
                    ::Continue::
                end
                --Loop through all the Added Conduits and their contents
                local NewNetworkInfo = TerminalUI.GetNetworkInfo();
                for _,conduit in ipairs(Added) do
                    if NewNetworkInfo[tostring(conduit)] == nil then
                        goto Continue;
                    end
                    local Contents = GetConduitContentsAsync(conduit,nil,NewNetworkInfo);
                    if Contents ~= nil then
                        for stringContainer,ContainerItems in pairs(Contents) do
                            Buffer.AddContainerToBuffers(tonumber(stringContainer),ContainerItems,conduit,NewNetworkInfo[tostring(conduit)]);
                        end
                    end
                    ::Continue::
                end
                Network = NewNetwork;
                NetworkInfo = NewNetworkInfo;
            end
            --Loop through all the conduits in the current network to keep the system up to date
            for _,conduit in ipairs(Network) do
                if NetworkInfo[tostring(conduit)] == nil then
                    goto Continue;
                end
                local PreviousContents = GetConduitContentsCached(conduit);
                local Contents = GetConduitContentsAsync(conduit);
                if Contents ~= nil and Contents ~= false then
                   -- sb.logInfo("Contents Have changed");
                    --The Contents have been updated
                    --Remove the previous contents
                    if PreviousContents ~= nil then
                        for stringContainer,ContainerItems in pairs(PreviousContents) do
                            --sb.logInfo("Removing = " .. sb.print(stringContainer));
                            Buffer.RemoveContainerFromBuffers(tonumber(stringContainer),ContainerItems,conduit,NetworkInfo[tostring(conduit)]);
                        end
                    end
                    --Add the current contents
                    for stringContainer,ContainerItems in pairs(Contents) do
                        Buffer.AddContainerToBuffers(tonumber(stringContainer),ContainerItems,conduit,NetworkInfo[tostring(conduit)]);
                    end
                end
                ::Continue::
            end
            RefreshDone = false;
            if UniversalRefreshRoutine ~= nil then
                UICore.CancelCoroutine(UniversalRefreshRoutine);
            end
            UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
                --sb.logInfo("Search Started");
                --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
                InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
                UICore.CancelCoroutine(UniversalRefreshRoutine);
            end,function()
                --sb.logInfo("Search Canceled");
                --SettingInventoryItems = false;
                RefreshDone = true;
                UniversalRefreshRoutine = nil;
            end);
            --InventoryItems.SetAllSlots(Buffer.GetBufferList());
            while(RefreshDone == false) do
                coroutine.yield();
            end
            --InventoryItems.Refresh();
        end
    end);
end

--Called when the arrow is clicked
function __allItemsArrowClicked()
    --TODO
    AllItems.Enable(not Enabled);
end

--Called when the extract button in the all items pane is clicked
function __AllItemsExtract()
    --sb.logInfo("EXTRACTING");
    --TODO Extract the selected Item
    local Item = widget.itemSlotItem("allItemsSelectedItemSlot");
   --[[ if Item == nil or ItemBuffer[Item.name] == nil then
        return nil;
    end--]]
    --sb.logInfo("Item = " .. sb.print(Item));
    local Count = widget.getText("allItemsSelectedItemAmountBox");
    if Count == "" then
        Count = 0;
    else
        Count = tonumber(Count);
    end
    --world.sendEntityMessage(SourceID,"ExtractFromNetwork",Item,Count);
    --[[UICore.CallMessageOnce(SourceID,"ExtractFromNetwork",function(result)
        if result == nil then
            sb.logInfo("result = nil");
        else
            sb.logInfo("result = " .. sb.printJson(result,1));
        end
    end,Item,Count);--]]
    UICore.CallMessageOnce(SourceID,"ExtractFromNetwork",function(result)
        --[[if result == nil then
            sb.logInfo("result = nil");
        else
            sb.logInfo("result = " .. sb.printJson(result,1));
        end--]]
        if result ~= nil and result.Amount > 0 then
            local NetworkInfo = TerminalUI.GetNetworkInfo();
            for _,conduit in ipairs(result.DirectConduits) do
                local StringConduit = tostring(conduit.ID);
                if ConduitContainerUUIDMap[StringConduit] == nil then
                   -- sb.logInfo("Replacing = nil for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit] = {Contents = conduit.ContainerContents,ID = conduit.UUID};
                else
                    --sb.logInfo("Replacing = " .. sb.print(ConduitContainerUUIDMap[StringConduit].ID) .. " for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit].Contents = conduit.ContainerContents;
                    ConduitContainerUUIDMap[StringConduit].ID = conduit.UUID;
                end
                Buffer.RemoveFromBuffers({name = Item.name,count = conduit.Amount,parameters = Item.parameters},conduit.ID,NetworkInfo[StringConduit]);
            end
            for _,conduit in ipairs(result.SideConduits) do
                local StringConduit = tostring(conduit.ID);
                if ConduitContainerUUIDMap[StringConduit] == nil then
                   -- sb.logInfo("Replacing = nil for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit] = {Contents = conduit.Contents,ID = conduit.UUID};
                else
                   -- sb.logInfo("Replacing = " .. sb.print(ConduitContainerUUIDMap[StringConduit].ID) .. " for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit].Contents = conduit.Contents;
                    ConduitContainerUUIDMap[StringConduit].ID = conduit.UUID;
                end
            end
            if UniversalRefreshRoutine ~= nil then
                 UICore.CancelCoroutine(UniversalRefreshRoutine);
             end
             UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
                --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
                InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
                UICore.CancelCoroutine(UniversalRefreshRoutine);
            end,function()
             --sb.logInfo("Buffer Canceled");
                --SettingInventoryItems = false;
                UniversalRefreshRoutine = nil;
            end);
            --InventoryItems.SetAllSlots(Buffer.GetBufferList(),true,true);
        end
    end,Item,Count,true);
end

--Called when the Extractable checkbox is clicked
function __ExtractableUpdate()
    if widget.getChecked("allItemsExtractableCheckbox") == true then
        Buffer.SetCurrentBuffer("DefaultExtractable");
    else
        Buffer.SetCurrentBuffer("Default");
    end
end

--Gets the current Sorting Mode
function Buffer.GetCurrentBuffer()
    return Buffer.Current;
end

--Sets the Current Sorting Mode
function Buffer.SetCurrentBuffer(bufferName)
   -- sb.logInfo("Buffer Call");
    if Buffer.Current ~= bufferName then
        if UniversalRefreshRoutine ~= nil then
           -- sb.logInfo("SENDING CANCEL");
            UICore.CancelCoroutine(UniversalRefreshRoutine);
        end
        Buffer.Current = bufferName;
        --if Loading == false then
            --sb.logInfo("Setting New Buffer");
            UniversalRefreshRoutine = UICore.AddAsyncCoroutine(function()
                --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
                InventoryItems.SetAllSlots(Buffer.GetBufferList(),true);
                UICore.CancelCoroutine(UniversalRefreshRoutine);
            end,function()
             --sb.logInfo("Buffer Canceled");
                --SettingInventoryItems = false;
                UniversalRefreshRoutine = nil;
            end);
        --end
    end
end
--Adds an item to the buffers
--If buffer name is non-nil, then only add it to that buffer
function Buffer.AddToBuffers(item,sourceID,sourceInfo,bufferName)
    if type(item) ~= "table" then return nil end;
    for mode,data in LoopOrOnce(Buffer.Modes,bufferName) do
        local result = data.Algorithm(item,sourceID,sourceInfo);
        local Item;
        if result == true then
            Item = item;
        elseif type(result) == "table" then
            Item = result;
        end
        if Item ~= nil then
            if data.Buffer[Item.name] ~= nil then
                local Variants = data.Buffer[Item.name];
                for _,variant in ipairs(Variants) do
                    if root.itemDescriptorsMatch(variant,Item,true) then
                        if variant.count == 0 and Item.count > 0 then
                            data.CurrentlyZero[variant] = nil;
                        end
                        variant.count = variant.count + Item.count;
                        goto Continue;
                    end
                end
                data.Updated = true;
                Variants[#Variants + 1] = {name = Item.name,count = Item.count,parameters = Item.parameters};
            else
                data.Updated = true;
                data.Buffer[item.name] = {{name = Item.name,count = Item.count,parameters = Item.parameters}};
            end
        end
        ::Continue::
    end
end

--Gets an item from buffer
function Buffer.GetFromBuffer(item,bufferName)
    if item == nil then return nil end;
    bufferName = bufferName or Buffer.GetCurrentBuffer();
    local data = Buffer.Modes[bufferName];
    if data ~= nil then
        local Variants = data.Buffer[item.name];
        if Variants ~= nil then
            for _,variant in ipairs(Variants) do
                if root.itemDescriptorsMatch(variant,item,true) then
                    return variant;
                end
            end
        end
    end
    --return Buffer.Modes[bufferName].Buffer[item.name]
end

--Removes an item from the buffers
--If buffer name is non-nil, then only remove it from that buffer
function Buffer.RemoveFromBuffers(item,sourceID,sourceInfo,bufferName)
    if type(item) ~= "table" then return nil end;
    for mode,data in LoopOrOnce(Buffer.Modes,bufferName) do
        local result = data.Algorithm(item,sourceID,sourceInfo);
        local Item;
        if result == true then
            Item = item;
        elseif type(result) == "table" then
            Item = result;
        end
        if Item ~= nil then
            if data.Buffer[Item.name] ~= nil then
                local Variants = data.Buffer[Item.name];
                for _,variant in ipairs(Variants) do
                    if root.itemDescriptorsMatch(variant,Item,true) then
                        if variant.count > 0 then
                            variant.count = variant.count - Item.count;
                            if variant.count <= 0 then
                                data.CurrentlyZero[variant] = true;
                                data.Updated = true;
                                variant.count = 0;
                            end
                        end
                        goto Continue;
                    end
                end
            end
        end
        ::Continue::
    end
end

--Adds a new sorting mode
function Buffer.AddNewBuffer(name,algorithm,containerAlgorithm)
    Buffer.Modes[name] = {
        List = {},
        Buffer = {},
        Updated = false,
        CurrentlyZero = {},
        Algorithm = algorithm,
        ContainerAlgorithm = containerAlgorithm,
        AddedContainers = {}
    }
end

--Adds an entire container's contents to the buffers
function Buffer.AddContainerToBuffers(container,contents,sourceID,sourceInfo)
    for mode,data in pairs(Buffer.Modes) do
        if data.ContainerAlgorithm(container,sourceID,sourceInfo) == true and AddContainer(container,mode) == 1 then
            --sb.logInfo("Adding = " .. sb.print(container));
            for slot,item in ipairs(contents) do
                Buffer.AddToBuffers(item,sourceID,sourceInfo,mode);
            end
        end
    end
end

--Removes an entire container's contents from the buffers
function Buffer.RemoveContainerFromBuffers(container,contents,sourceID,sourceInfo)
    for mode,data in pairs(Buffer.Modes) do
        if data.ContainerAlgorithm(container,sourceID,sourceInfo) == true and RemoveContainer(container,mode) == 0 then
           -- sb.logInfo("Removing = " .. sb.print(container));
            for slot,item in ipairs(contents) do
                Buffer.RemoveFromBuffers(item,sourceID,sourceInfo,mode);
            end
        end
    end
end

--Converts the buffer into a table representation
function Buffer.GetBufferList(bufferName)
    bufferName = bufferName or Buffer.GetCurrentBuffer();
    local CurrentBuffer = Buffer.Modes[bufferName];
    if CurrentBuffer.Updated == true then
        if jsize(CurrentBuffer.CurrentlyZero) > 0 then
            for oldVariant in pairs(CurrentBuffer.CurrentlyZero) do
                for index,variant in ipairs(CurrentBuffer.Buffer[oldVariant.name]) do
                    if oldVariant == variant then
                        table.remove(CurrentBuffer.Buffer[oldVariant.name],index);
                        if #CurrentBuffer.Buffer[oldVariant.name] == 0 then
                            CurrentBuffer.Buffer[oldVariant.name] = nil;
                        end
                        break;
                    end
                end
            end
            CurrentBuffer.CurrentlyZero = {};
        end
        local List = {};
        for _,variants in pairs(CurrentBuffer.Buffer) do
            for _,item in ipairs(variants) do
                List[#List + 1] = item;
            end
        end
        table.sort(List,SortingAlgoritm);
        CurrentBuffer.List = List;
        CurrentBuffer.Updated = false;
    end
    return CurrentBuffer.List;
end

--Removes an element to all the sorted tables
--[[function SortMode.RemoveFromBuffers(item)
    for mode,data in pairs(SortMode.Modes) do

    end
end--]]

--Iterates over all the Modes
function Buffer.BufferIter()
    return pairs(Buffer.Modes);
end

--Gets the containers and their contents from the conduit
--Returns false if no changes have occured
--Returns nil if the conduit doesnt have any containers
GetConduitContentsAsync = function(conduit,forced,networkInfo)
    local StringID = tostring(conduit);
    local NetworkInfo;
    if networkInfo ~= nil then
        NetworkInfo = networkInfo;
    else
        NetworkInfo = TerminalUI.GetNetworkInfo();
    end
    --local NetworkInfo = TerminalUI.GetNetworkInfo();
    local ConduitInfo = NetworkInfo[StringID];
    if ConduitInfo == nil then
        return nil;
    end
    local Contents;
    local ID;
    if ConduitContainerUUIDMap[StringID] ~= nil then
        ID = ConduitContainerUUIDMap[StringID].ID;
    end
    local Value;
    local ConduitType;
    if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
        Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",ID,true);
        ConduitType = "Extraction";
    elseif ConduitInfo.ConduitType == "insertion" then
        Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",ID,true);
        ConduitType = "Insertion"; 
    else
        return nil;                   
    end   
    if Value == false then
        return false;
    elseif Value ~= nil then
        if ConduitContainerUUIDMap[StringID] == nil then
            ConduitContainerUUIDMap[StringID] = {ID = Value[2],Contents = Value[1]};
            return Value[1];
        else
            if ConduitContainerUUIDMap[tostring(conduit)].ID ~= Value[2] then
                ConduitContainerUUIDMap[tostring(conduit)].ID = Value[2];
                ConduitContainerUUIDMap[tostring(conduit)].Contents = Value[1];
                return Value[1];
            else
                if forced == true then
                    return ConduitContainerUUIDMap[tostring(conduit)].Contents;
                else
                    return false;
                end
            end
        end
    end
end

--Returns the contents stored in the cache
GetConduitContentsCached = function(conduit)
    if ConduitContainerUUIDMap[tostring(conduit)] ~= nil then
        return ConduitContainerUUIDMap[tostring(conduit)].Contents;
    end
    return nil;
end

--Starts a batch process of getting the conduit contents
StartConduitContentsBatch = function(network,networkInfo)
    network = network or TerminalUI.GetNetwork();
    networkInfo = networkInfo or TerminalUI.GetNetworkInfo();
    ConduitContentsBatched = {};
    for _,conduit in ipairs(network) do
        local StringConduit = tostring(conduit);
        local ConduitInfo = networkInfo[StringConduit];
        if ConduitInfo == nil then
            goto Continue;
        end
        if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
            ConduitContentsBatched[StringConduit] = {Promise = ExecuteScript(conduit,"Extraction.QueryContainers",ID,true)};
            if not Enabled then
                coroutine.yield();
            end
        elseif ConduitInfo.ConduitType == "insertion" then
            ConduitContentsBatched[StringConduit] = {Promise = ExecuteScript(conduit,"Insertion.QueryContainers",ID,true)};
            if not Enabled then
                coroutine.yield();
            end
        else
            goto Continue;            
        end
        

        ::Continue::
    end
end

GetConduitContentsBatch = function(conduit,forced)
    if ConduitContentsBatched[tostring(conduit)] == nil then return nil end;
    local Promise = ConduitContentsBatched[tostring(conduit)].Promise;
    while not Promise:finished() do
        coroutine.yield();
    end
    local Value = Promise:result();
    if Value == false then
        return false;
    elseif Value ~= nil then
        local StringID = tostring(conduit);
        if ConduitContainerUUIDMap[StringID] == nil then
            ConduitContainerUUIDMap[StringID] = {ID = Value[2],Contents = Value[1]};
            return Value[1];
        else
            if ConduitContainerUUIDMap[tostring(conduit)].ID ~= Value[2] then
                ConduitContainerUUIDMap[tostring(conduit)].ID = Value[2];
                ConduitContainerUUIDMap[tostring(conduit)].Contents = Value[1];
                return Value[1];
            else
                if forced == true then
                    return ConduitContainerUUIDMap[tostring(conduit)].Contents;
                else
                    return false;
                end
            end
        end
    end
end

--Sets the contents stored in the cache
EraseConduitContentsCache = function(conduit)
    ConduitContainerUUIDMap[tostring(conduit)] = nil;
end

--Gets what was added and what was removed from the two tables
GetTableChanges = function(A,B)
    local Added = {};
    for x=1,#A do
        for y=1,#B do
            if A[x] == B[y] then
                goto Continue;
            end
        end
        Added[#Added + 1] = A[x];
        ::Continue::
    end
    local Removed = {};
    for x=1,#B do
        for y=1,#A do
            if B[x] == A[y] then
                goto Continue;
            end
        end
        Removed[#Removed + 1] = B[x];
        ::Continue::
    end
    return Added, Removed;
end

--Adds a container to the container Tracker
AddContainer = function(container,bufferName)
    local container = tostring(container);
    local AddedContainers = Buffer.Modes[bufferName].AddedContainers;
    if AddedContainers[container] == nil then
        AddedContainers[container] = 1;
        --sb.logInfo("ADD COUNT = " .. sb.print(1));
        return 1;
    else
        AddedContainers[container] = AddedContainers[container] + 1;
        --sb.logInfo("ADD COUNT = " .. sb.print(AddedContainers[container]));
        return AddedContainers[container];
    end
end

--Removes a container from the Container Tracker
RemoveContainer = function(container,bufferName)
    local container = tostring(container);
    local AddedContainers = Buffer.Modes[bufferName].AddedContainers;
    if AddedContainers[container] == nil then
        --sb.logInfo("REMOVE COUNT = " .. sb.print(0));
        return 0;
    else
        AddedContainers[container] = AddedContainers[container] - 1;
        if AddedContainers[container] == 0 then
            AddedContainers[container] = nil;
           -- sb.logInfo("REMOVE COUNT = " .. sb.print(0));
            return 0;
        else
           -- sb.logInfo("REMOVE COUNT = " .. sb.print(AddedContainers[container]));
            return AddedContainers[container];
        end
    end
end

--If the second parameter is nil, then loop over all the elements
--Otherwise, just return only the index of the second parameter
LoopOrOnce = function(tbl,index,numberTable)
    if index == nil then
        if numberTable == true then
            return ipairs(tbl);
        else
            return pairs(tbl);
        end
    else
        local Returned = false;
        return function()
            if Returned == false then
                Returned = true;
                return index,tbl[index];
            end
        end
    end
end

--Removes any pattern characters from the string
Depatternize = function(str)
   --[[ sb.logInfo("Before = ");
    for word in string.gmatch(str,".") do
        sb.logInfo(word);
    end--]]
    local FinalStr = str;
    for _,char in ipairs(PatternCharacters) do
        --sb.logInfo("CharStr = " .. "%" .. char);
        --sb.logInfo("Char 1 = " .. sb.print(char));
        --sb.logInfo("Char 2 = " .. sb.print("%["));
       -- sb.logInfo("Char 3 = " .. sb.print("%" .. char));
        --[[sb.logInfo("CHAR = ");
        for word in string.gmatch("%" .. char,".") do
            sb.logInfo(word);
        end--]]
        --local Find = string.find(FinalStr,"%" .. char);
        --sb.logInfo("Find = " .. sb.print(Find));
        --error("%%%" .. char);
        --sb.logInfo("Test = " .. sb.print("%%%" .. char));
        FinalStr = string.gsub(FinalStr,"%" .. char,"_");
    end
    --sb.logInfo("After = " .. FinalStr);
    --sb.logInfo("AFTER = " .. FinalStr);
   --[[ for word in string.gmatch(FinalStr,".") do
        sb.logInfo(word);
    end--]]
    return FinalStr;
end