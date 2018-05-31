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
local Loading = false;
local LoadingCircleRotation;
local LoadingCircleRotationSpeed = 7;
local ConduitContainerUUIDMap = {};
local InternalInventoryItems = {};
local ItemBuffer = {};
local NumericItemTable = {};
local InventoryItems = {};
local SettingInventoryItems = false;
local InternalInventoryItems = {};
local FPS;
local SortingAlgoritm = function(item1,item2) return item1.count < item2.count end;
local SearchKeyword = "";
local SearchAlgorithm = function(Item,keyword) return string.find(string.lower(Item.name),string.lower(keyword)) ~= nil end;
local SearchRoutine;
local SelectedItem;


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
--local AddOnDoneLoadingFunction;

--Initializes the All Items Area
function AllItems.Initialize()
    if Initialized == true then return nil end;
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
    StartUpAllItemsArea();
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
    widget.setVisible("allItemsLoadingCircle",false);
    widget.setVisible("allItemsSettingsArea",false);
    widget.setVisible("allItemsSearchIcon",false);
    widget.setVisible("allItemsSearchBox",false);
    widget.setVisible("allItemsSelectedItemSlot",false);
    widget.setVisible("allItemsSelectedItemBackground",false);
    widget.setVisible("allItemsExtractButton",false);
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
    sb.logInfo("Clicked on slot = " .. sb.print(data));
    SetSelectedItem(InventoryItems.GetItemWithSort(tonumber(data)));
end

--Called when the slot is right clicked
__SlotRightClick__ = function(name,data)
    SetSelectedItem(nil);
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
        sb.logInfo("Short Circuit");
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
    sb.logInfo("InternalInventoryItems = " .. sb.print(InternalInventoryItems));
end

--Gets the item at the slot
function InventoryItems.GetItem(slot)
    return rawget(InternalInventoryItems,slot);
end

--Gets the item with the sorting and searching applied
function InventoryItems.GetItemWithSort(slot)
    return ApplySearch(InternalInventoryItems)[slot];
end

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
function InventoryItems.SetAllSlots(tbl,forceSyncronous)
    if forceSyncronous ~= true and coroutine.running() ~= nil then
        while(SettingInventoryItems == true) do
            coroutine.yield();
        end
    end
    --sb.logInfo("Setting");
    SettingInventoryItems = true;
    InventoryItems.Clear(true);
   -- sb.logInfo("G");
    local SortedTable = ApplySearch(tbl);
    local MaxSlot = #SortedTable;
    local RowNumber = math.ceil(MaxSlot / SlotsPerRow);
    --[[if #SlotRows > RowNumber then
        for i=#SlotRows,RowNumber + 1,-1 do
            widget.removeListItem(AllItemsList,i);
            table.remove(SlotRows,i);
        end
    end--]]
    local SlotAtRow = ((MaxSlot - 1) % SlotsPerRow) + 1;
    for row=1,RowNumber do
        --local Start = os.clock();
        if SlotRows[row] == nil then
            local NewSlot = widget.addListItem(AllItemsList);
            SlotRows[row] = {Name = NewSlot,Full = AllItemsList ..  "." .. NewSlot};
        end
        local Start = os.clock();
        for slot=1,IfNumEqual(row,RowNumber,SlotAtRow,SlotsPerRow) do
            local GlobalSlot = (row - 1) * SlotsPerRow + slot;
            local SlotPath = SlotRows[row].Full .. ".slot" .. slot;
            local Value = SortedTable[GlobalSlot];
            if type(Value) ~= "table" then
                widget.setItemSlotItem(SlotPath,nil);
                widget.setText(SlotPath .. "count","");
            else
                widget.setItemSlotItem(SlotPath,{name = Value.name,count = 1,parameters = Value.parameters});
                --NumberToString(Value.count)
                widget.setText(SlotPath .. "count",NumberToString(Value.count));
            end
            widget.setVisible(SlotPath,true);
            widget.setVisible(SlotPath .. "background",true);
            widget.setData(SlotPath,GlobalSlot);
           -- if coroutine.running() ~= nil and slot == math.floor(SlotsPerRow / 2) then
            --    coroutine.yield();
            --end
            if Enabled == false and 1 / (os.clock() - Start) < 100 and forceSyncronous ~= true and coroutine.running() ~= nil then
               -- sb.logInfo("G = " .. sb.print(row) .. ", " .. sb.print(slot));
                coroutine.yield();
            end
        end
       -- local End = os.clock();
       -- local Delta = End - Start;
       -- if Delta ~= 0 then
        --    sb.logInfo("Speed = " .. sb.print(1 / Delta));
        --end
       -- local Delta = os.clock() - Start;
       -- sb.logInfo("FPS = " .. sb.print(FPS))
        --sb.logInfo("Delta = " .. sb.print(Delta))
        --sb.logInfo("Speed = " .. sb.print(Delta * FPS));
        --sb.logInfo("Running = " .. sb.print(coroutine.running()));
        if forceSyncronous ~= true and coroutine.running() ~= nil then
          --  sb.logInfo("R = " .. sb.print(row));
            coroutine.yield();
        end
    end
    InternalInventoryItems = tbl;
   -- sb.logInfo("Done");
    SettingInventoryItems = false;
   -- sb.logInfo("H");
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
    if SearchKeyword ~= word then
        if SearchRoutine ~= nil then
            UICore.CancelCoroutine(SearchRoutine);
        end
        SearchKeyword = word;
        SearchRoutine = UICore.AddAsyncCoroutine(function()
            --sb.logInfo("Internal Inventory Items = " .. sb.print(InternalInventoryItems));
            InventoryItems.SetAllSlots(InternalInventoryItems);
            UICore.CancelCoroutine(SearchRoutine);
        end,function()
           -- sb.logInfo("Search Canceled");
            SettingInventoryItems = false;
            SearchRoutine = nil;
        end);
    end
end

--Sets the Current Search algorithm
SetSearchAlgorithm = function(func)
    SearchAlgorithm = func;
    InventoryItems.SetAllSlots(InternalInventoryItems,true);
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
allItemsSearchBoxUpdated = function()
    if Loading then
        widget.setText("allItemsSearchBox","");
    else
        SetSearchKeyword(widget.getText("allItemsSearchBox"));
    end
end

--Starts Up the Routine that displays all the items
StartUpAllItemsArea = function()
    MainLoadingRoutine = UICore.AddAsyncCoroutine(function()
        InventoryItems.EnableLoading();
        local AddedContainers = {};
        ItemBuffer = {};
        InventoryItems.Clear();
      --  sb.logInfo("ItemBuffer = " .. sb.print(ItemBuffer));
        local Network = TerminalUI.GetNetwork();
        local Info = TerminalUI.GetNetworkInfo();
        for _,conduit in ipairs(Network) do
            local ConduitInfo = Info[tostring(conduit)];
            local Contents;
                local ID;
                if ConduitContainerUUIDMap[tostring(conduit)] ~= nil then
                    ID = ConduitContainerUUIDMap[tostring(conduit)].ID;
                end
                local Value;
               -- sb.logInfo("X");
                if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
                    Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",ID,true);
                elseif ConduitInfo.ConduitType == "insertion" then
                    Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",ID,true);
                end         
                if Value == false then
                    Contents = ConduitContainerUUIDMap[tostring(conduit)].Contents;                       
                elseif Value ~= nil then
                    ConduitContainerUUIDMap[tostring(conduit)] = {ID = Value[2],Contents = Value[1]};
                    Contents = Value[1];
                end
            --Track Containers to avoid duplicates and to allow taking out of them
            if Contents ~= nil then
                --sb.logInfo("J");
                for stringContainer,ContainerItems in pairs(Contents) do
                    local Container = tonumber(stringContainer);
                   --[[ for i=#AddedContainers,1,-1 do
                        if AddedContainers[i] == Container then
                            goto NextContainer;
                        end
                    end
                    AddedContainers[#AddedContainers + 1] = Container;--]]
                    if AddedContainers[Container] ~= nil then
                        AddedContainers[Container] = AddedContainers[Container] + 1;
                        goto NextContainer;
                    else
                        AddedContainers[Container] = 1;
                    end
                    local AsyncCounter = 0;
                    for slot,item in ipairs(ContainerItems) do
                        if item ~= "" then
                            if ItemBuffer[item.name] ~= nil then
                                local Variants = ItemBuffer[item.name];
                                for _,variant in ipairs(Variants) do
                                    if root.itemDescriptorsMatch(variant,item,true) then
                                        variant.count = variant.count + item.count;
                                        goto FirstContinue;
                                    end
                                end
                                Variants[#Variants + 1] = {name = item.name,count = item.count,parameters = item.parameters};

                            else
                                ItemBuffer[item.name] = {{name = item.name,count = item.count,parameters = item.parameters}};
                            end
                            ::FirstContinue::
                        end
                    end
                    ::NextContainer::
                end
                --sb.logInfo("K");
            end
            ::Continue::
        end
        --Display the item buffer
        --table.sort(ItemBuffer,function(a,b) return a.Item.count > b.Item.count end);
       --[[ for i=1,#ItemBuffer do
           -- sb.logInfo("DISPLAYING ITEM = " .. sb.print(ItemBuffer[i].Item));
            InventoryItems[i] = ItemBuffer[i].Item;
        end--]]
        NumericItemTable = {};
        for _,variants in pairs(ItemBuffer) do
            for _,item in ipairs(variants) do
                NumericItemTable[#NumericItemTable + 1] = item;
                item.ControllerSlot = #NumericItemTable;
            end
        end
        table.sort(NumericItemTable,function(a,b) return a.count > b.count end);
        --for i=1,#NumericItemTable do
            --InventoryItems.SetItem(NumericItemTable[i]);
            --InventoryItems[i] = NumericItemTable[i];
       -- end
       --table.sort()
       InventoryItems.SetAllSlots(NumericItemTable);
       InventoryItems.DisableLoading();
       --Go Into passive mode, where you make sure the inventory items stay up to date
       --local Value;
      -- sb.logInfo("X");
       --[[if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
           Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",ID,true);
       elseif ConduitInfo.ConduitType == "insertion" then
           Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",ID,true);
       end         
       if Value == false then
           Contents = ConduitContainerUUIDMap[tostring(conduit)].Contents;                       
       elseif Value ~= nil then
           ConduitContainerUUIDMap[tostring(conduit)] = {ID = Value[2],Contents = Value[1]};
           Contents = Value[1];
       end--]]
       while (true) do

        local CurrentlyZero = {};
        local NeedsSorting = false;
        local NeedsRefreshing = false;
        local NewNetwork = TerminalUI.GetNetwork();
        if NewNetwork ~= Network then
            --sb.logInfo("J");
            --A New network is in place
            local NewInfo = TerminalUI.GetNetworkInfo();
            local RemovedConduits = {};
            for x=1,#Network do
                for y=1,#NewNetwork do
                    if Network[x] == NewNetwork[y] then
                        goto Next;
                    end
                end
                RemovedConduits[#RemovedConduits + 1] = Network[x];
                ::Next::
            end
            sb.logInfo("Removed Conduits = " .. sb.print(RemovedConduits));
            for i=1,#RemovedConduits do
                local StringConduit = tostring(RemovedConduits[i]);
                if ConduitContainerUUIDMap[StringConduit] ~= nil then
                    for stringContainer,containerContents in pairs(ConduitContainerUUIDMap[StringConduit].Contents) do
                        local Container = tonumber(stringContainer);
                       --[[ for x=1,#AddedContainers do
                            if AddedContainers[x] == Container then
                                table.remove(AddedContainers,x);
                                break;
                            end
                        end--]]
                        if AddedContainers[Container] ~= nil then
                            AddedContainers[Container] = AddedContainers[Container] - 1;
                            if AddedContainers[Container] == 0 then
                                sb.logInfo("Removing");
                                AddedContainers[Container] = nil;
                            else
                                sb.logInfo("Skipping");
                                goto SkipItemRemoval;
                            end
                        end
                        for i=1,#containerContents do
                            if containerContents[i] ~= "" then
                                local Item = containerContents[i];
                                for _,variant in ipairs(ItemBuffer[Item.name]) do
                                    if root.itemDescriptorsMatch(variant,Item,true) then
                                        variant.count = variant.count - Item.count;
                                        if variant.count == 0 then
                                            CurrentlyZero[variant] = true;
                                        end
                                        NeedsRefreshing = true;
                                        break;
                                    end
                                end
                            end
                        end
                        ::SkipItemRemoval::
                    end
                    ConduitContainerUUIDMap[StringConduit] = nil;
                end
            end
            local AddedConduits = {};
            for x=1,#NewNetwork do
                for y=1,#Network do
                    if NewNetwork[x] == Network[y] then
                        goto Next;
                    end
                end
                AddedConduits[#AddedConduits + 1] = NewNetwork[x];
                ::Next::
            end
            sb.logInfo("Added Conduits = " .. sb.print(AddedConduits));
            for i=1,#AddedConduits do
                local conduit = AddedConduits[i];
                local StringConduit = tostring(conduit);
                local ConduitInfo = NewInfo[StringConduit];
                local Value;
                if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
                    Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",nil,true);
                elseif ConduitInfo.ConduitType == "insertion" then
                    Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",nil,true);
                else
                    goto NextConduit;
                end
                if Value ~= false and Value ~= nil and (ConduitContainerUUIDMap[StringConduit] == nil or ConduitContainerUUIDMap[StringConduit].ID ~= Value[2]) then
                    local ID,CurrentContents = Value[2],Value[1];
                    for stringContainer,containerContents in pairs(CurrentContents) do
                        local Container = tonumber(stringContainer);
                       --[[ for x=1,#AddedContainers do
                            if AddedContainers[x] == Container then
                                goto NextContainer;
                            end
                        end--]]
                        sb.logInfo("Added Containers = " .. sb.print(AddedContainers));
                        if AddedContainers[Container] ~= nil then
                            AddedContainers[Container] = AddedContainers[Container] + 1;
                            sb.logInfo("Added Reference");
                            goto NextContainer;
                        else
                            sb.logInfo("New Container");
                            AddedContainers[Container] = 1;
                        end
                        for i=1,#containerContents do
                            if containerContents[i] ~= "" then
                                local Item = containerContents[i];
                                --sb.logInfo("Item = " .. sb.print(Item));
                                if ItemBuffer[Item.name] == nil then
                                    sb.logInfo("Added Item = " .. sb.print(Item));
                                    local NewBufferItem = {name = Item.name,count = Item.count,parameters = Item.parameters}
                                    ItemBuffer[Item.name] = {NewBufferItem};
                                    NumericItemTable[#NumericItemTable + 1] = NewBufferItem;
                                    InventoryItems.SetItem(NewBufferItem,#NumericItemTable);
                                    --sb.logInfo("NewBufferItem 1 = " .. sb.print(NewBufferItem)); 
                                    NeedsRefreshing = true;                                   
                                    NeedsSorting = true;
                                else
                                    for _,variant in ipairs(ItemBuffer[Item.name]) do
                                        if root.itemDescriptorsMatch(variant,Item,true) then
                                            variant.count = variant.count + Item.count;
                                            if CurrentlyZero[variant] == true then
                                                CurrentlyZero[variant] = nil;
                                            end
                                            NeedsRefreshing = true;
                                            goto FoundMatch;
                                        end
                                    end
                                    local NewBufferItem = {name = Item.name,count = Item.count,parameters = Item.parameters};
                                    --sb.logInfo("NewBufferItem 2 = " .. sb.print(NewBufferItem));
                                    local Variants = ItemBuffer[Item.name];
                                    Variants[#Variants + 1] = NewBufferItem;
                                    NumericItemTable[#NumericItemTable + 1] = NewBufferItem;
                                    InventoryItems.SetItem(NewBufferItem,#NumericItemTable);
                                    NeedsSorting = true;
                                    NeedsRefreshing = true;
                                    ::FoundMatch::
                                end
                            end
                        end
                        --AddedContainers[#AddedContainers + 1] = Container;
                        ::NextContainer::
                    end
                    if ConduitContainerUUIDMap[StringConduit] == nil then
                        ConduitContainerUUIDMap[StringConduit] = {Contents = CurrentContents,ID = Value[2]};
                    else
                        ConduitContainerUUIDMap[StringConduit].Contents = CurrentContents;
                        ConduitContainerUUIDMap[StringConduit].ID = Value[2];
                    end
                    --ConduitContainerUUIDMap[StringConduit].Contents = CurrentContents;
                    --ConduitContainerUUIDMap[StringConduit].ID = ID;
                end
                coroutine.yield();
                ::NextConduit::
            end
            Network = NewNetwork;
            Info = NewInfo;
            --sb.logInfo("K");
        end
        for _,conduit in ipairs(Network) do
            local StringConduit = tostring(conduit);
            local ConduitInfo = Info[StringConduit];
            local Value;
            local ID;
            if ConduitContainerUUIDMap[StringConduit] ~= nil then
                ID = ConduitContainerUUIDMap[StringConduit].ID;
            end
           -- sb.logInfo("ID = " .. sb.print(ID));
           -- sb.logInfo("V");
            if ConduitInfo.ConduitType == "extraction" or ConduitInfo.ConduitType == "io" then
                Value = ExecuteScriptAsync(conduit,"Extraction.QueryContainers",ID,true);
            elseif ConduitInfo.ConduitType == "insertion" then
                Value = ExecuteScriptAsync(conduit,"Insertion.QueryContainers",ID,true);
            else
                goto NextConduit;
            end
           -- sb.logInfo("W");
            --sb.logInfo("Test");
            --Check if container has changed
            if Value ~= false and Value ~= nil and (ConduitContainerUUIDMap[StringConduit] == nil or Value[2] ~= ConduitContainerUUIDMap[StringConduit].ID) then
                sb.logInfo("OldID for " .. sb.print(StringConduit) .. " = " .. sb.print(ConduitContainerUUIDMap[StringConduit].ID));
                sb.logInfo("New ID for " .. sb.print(StringConduit) .. " = " .. sb.print(Value[2]));
               -- sb.logInfo("Contents Updated");
              -- sb.logInfo("UI CONTENTS Updated");
               -- sb.logInfo("Value = " .. sb.print(Value));
              -- sb.logInfo("L");
               local CurrentContents = Value[1];
                if ConduitContainerUUIDMap[StringConduit] ~= nil then
                    local PreviousContents = ConduitContainerUUIDMap[StringConduit].Contents;
                    local CurrentContents = Value[1];
                    -- sb.logInfo("PreviousContents = " .. sb.print(PreviousContents));
                    -- sb.logInfo("CurrentContents = " .. sb.print(CurrentContents));
                    for _,containerContents in pairs(PreviousContents) do
                        for i=1,#containerContents do
                            if containerContents[i] ~= "" then
                                local Item = containerContents[i];
                                for _,variant in ipairs(ItemBuffer[Item.name]) do
                                    if root.itemDescriptorsMatch(variant,Item,true) then
                                        variant.count = variant.count - Item.count;
                                        if variant.count == 0 then
                                            CurrentlyZero[variant] = true;
                                        end
                                        NeedsRefreshing = true;
                                        break;
                                    end
                                end
                            end
                        end
                    end
                end
               -- sb.logInfo("M");
                for _,containerContents in pairs(CurrentContents) do
                    for i=1,#containerContents do
                        if containerContents[i] ~= "" then
                            local Item = containerContents[i];
                            --sb.logInfo("Item = " .. sb.print(Item));
                            if ItemBuffer[Item.name] == nil then
                                local NewBufferItem = {name = Item.name,count = Item.count,parameters = Item.parameters}
                                ItemBuffer[Item.name] = {NewBufferItem};
                                NumericItemTable[#NumericItemTable + 1] = NewBufferItem;
                                InventoryItems.SetItem(NewBufferItem,#NumericItemTable);
                                --sb.logInfo("NewBufferItem 1 = " .. sb.print(NewBufferItem)); 
                                NeedsRefreshing = true;                                   
                                NeedsSorting = true;
                            else
                                for _,variant in ipairs(ItemBuffer[Item.name]) do
                                    if root.itemDescriptorsMatch(variant,Item,true) then
                                        variant.count = variant.count + Item.count;
                                        if CurrentlyZero[variant] == true then
                                            CurrentlyZero[variant] = nil;
                                        end
                                        NeedsRefreshing = true;
                                        goto FoundMatch;
                                    end
                                end
                                local NewBufferItem = {name = Item.name,count = Item.count,parameters = Item.parameters};
                                --sb.logInfo("NewBufferItem 2 = " .. sb.print(NewBufferItem));
                                local Variants = ItemBuffer[Item.name];
                                Variants[#Variants + 1] = NewBufferItem;
                                NumericItemTable[#NumericItemTable + 1] = NewBufferItem;
                                InventoryItems.SetItem(NewBufferItem,#NumericItemTable);
                                NeedsSorting = true;
                                NeedsRefreshing = true;
                                ::FoundMatch::
                            end
                        end
                    end
                end
               -- sb.logInfo("N");
                if ConduitContainerUUIDMap[StringConduit] == nil then
                    ConduitContainerUUIDMap[StringConduit] = {Contents = CurrentContents,ID = Value[2]};
                else
                    ConduitContainerUUIDMap[StringConduit].Contents = CurrentContents;
                    ConduitContainerUUIDMap[StringConduit].ID = Value[2];
                end
            end
            coroutine.yield();
            ::NextConduit::
        end
        --sb.logInfo("End 1");
       -- sb.logInfo("o");
        for variant,_ in pairs(CurrentlyZero) do
            for i,bufferVariant in ipairs(ItemBuffer[variant.name]) do
                if bufferVariant == variant then
                    table.remove(ItemBuffer[variant.name],i);
                    if #ItemBuffer[variant.name] == 0 then
                        ItemBuffer[variant.name] = nil;
                    end
                    for i=1,#NumericItemTable do
                        if NumericItemTable[i] == variant then
                            table.remove(NumericItemTable,i);
                            NeedsSorting = true;
                        end
                    end
                    break;
                end
            end
        end
        --sb.logInfo("P");
        --sb.logInfo("Needs Sorting = " .. sb.print(NeedsSorting));
        if NeedsSorting then
            table.sort(NumericItemTable,function(a,b) return a.count > b.count end);
       -- else
            --InventoryItems.SetAllSlots(NumericItemTable);
        end
        if NeedsRefreshing then
            --sb.logInfo("Refreshing");
            InventoryItems.Refresh();
        end
        coroutine.yield();
    end
    end);
end

--Called when the arrow is clicked
function allItemsArrowClicked()
    --TODO
    AllItems.Enable(not Enabled);
end

--Called when the extract button in the all items pane is clicked
function AllItemsExtract()
    --TODO Extract the selected Item
    local Item = widget.itemSlotItem("allItemsSelectedItemSlot");
    if Item == nil or ItemBuffer[Item.name] == nil then
        return nil;
    end
    sb.logInfo("Item = " .. sb.print(Item));
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
        if result == nil then
            sb.logInfo("result = nil");
        else
            sb.logInfo("result = " .. sb.printJson(result,1));
        end
        if result ~= nil and result.Amount > 0 then
            for _,conduit in ipairs(result.DirectConduits) do
                local StringConduit = tostring(conduit.ID);
                if ConduitContainerUUIDMap[StringConduit] == nil then
                    sb.logInfo("Replacing = nil for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit] = {Contents = conduit.ContainerContents,ID = conduit.UUID};
                else
                    sb.logInfo("Replacing = " .. sb.print(ConduitContainerUUIDMap[StringConduit].ID) .. " for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit].Contents = conduit.ContainerContents;
                    ConduitContainerUUIDMap[StringConduit].ID = conduit.UUID;
                end
            end
            for _,conduit in ipairs(result.SideConduits) do
                local StringConduit = tostring(conduit.ID);
                if ConduitContainerUUIDMap[StringConduit] == nil then
                    sb.logInfo("Replacing = nil for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit] = {Contents = conduit.Contents,ID = conduit.UUID};
                else
                    sb.logInfo("Replacing = " .. sb.print(ConduitContainerUUIDMap[StringConduit].ID) .. " for " .. sb.print(StringConduit) .. " with = " .. sb.print(conduit.UUID));
                    ConduitContainerUUIDMap[StringConduit].Contents = conduit.Contents;
                    ConduitContainerUUIDMap[StringConduit].ID = conduit.UUID;
                end
            end
            --for stringConduit,data in pairs(ConduitContainerUUIDMap) do
            --    for stringContainer,_ in pairs(result.)
            --end
            for index,variant in ipairs(ItemBuffer[Item.name]) do
                if root.itemDescriptorsMatch(variant,Item,true) then
                    variant.count = variant.count - result.Amount;
                    if variant.count == 0 then
                        table.remove(variant,index);
                        for i=1,#NumericItemTable do
                            if NumericItemTable[i] == variant then
                                table.remove(NumericItemTable,i);
                                InventoryItems.SetAllSlots(NumericItemTable,true);
                                --InventoryItems.SetItem(nil,i,);
                                break;
                            end
                        end
                    else
                        InventoryItems.Refresh();
                    end
                    break;
                end
            end
        end
    end,Item,Count,true);
end