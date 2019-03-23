--[[
    The purpose of this library is to implement a scalable
    shared table which is replicated between the client and
    the server. When a new item is created, only the relevant
    sequential path information and a value will be sent to
    the client. If this new value is a table, then this too is
    wrapped.
]]

shared()

local Replication                   = {Binds = {}, Access = {}}
local ReplicatedData                = {} -- Data replicated between client and server
local SharedData                    = {} -- Data replicated between scripts on the same device
local SWrapReplicatedData           = nil
local CWrapReplicatedData           = nil

local function GetNewIndexHandler(IsServer)

    return function(self, Key, Value)

        local WrapFunc = (
            IsServer == true and SWrapReplicatedData or CWrapReplicatedData
        )

        -- Allow __newindex to fire again
        rawset(self, Key, nil)
        local KeyList = rawget(self, "KeyList")
        local Vars = rawget(self, "Vars")
        local Send = Value
        local NewKeys = {}
        local Count = #KeyList

        for Index = 1, Count do
            NewKeys[Index] = KeyList[Index]
        end

        NewKeys[Count + 1] = Key

        if (type(Value) == "table") then
            if (Value.Object == nil) then
                WrapFunc(NewKeys, Value)
                Send = Replication.StripReplicatedData(Value)
            end
        end

        Vars[Key] = Value

        if IsServer then
            Broadcast("ReplicateData", NewKeys, Send)
        end

        Replication.CallBinds(unpack(NewKeys))
    end
end

local function IndexHandler(self, Key)
    return rawget(self, Key) or rawget(self, "Vars")[Key]
end

local function GetWrapReplicatedData(Metatable)

    local function SelfFunc(KeyList, Data)

        Data.Vars = {}
        Data.KeyList = KeyList

        for Key, Value in next, Data do -- Iterate through each data item, wrap if table
            if (Key ~= "Vars" and Key ~= "KeyList") then
                if (type(Value) == "table") then
                    if (Value.Object == nil) then -- Check for wrapped instances
                        --[[
                            Append new key (from iteration) onto end of previous list, but copy (important)
                            Call self for sub-tables
                        ]]
                        SelfFunc(Table.CopyAndAppend(KeyList, Key), Value)
                    end
                end
                Data.Vars[Key] = Value
                Data[Key] = nil
            end
        end
        setmetatable(Data, Metatable)
    end

    return SelfFunc
end

Replication.ServerMetatable     = {
    __index                     = IndexHandler;
    __newindex                  = GetNewIndexHandler(true);
}

Replication.ClientMetatable     = {
    __index                     = IndexHandler;
    __newindex                  = GetNewIndexHandler(false);
}

SWrapReplicatedData = GetWrapReplicatedData(Replication.ServerMetatable)
CWrapReplicatedData = GetWrapReplicatedData(Replication.ClientMetatable)

function Replication.StripReplicatedData(Data)

    local Result = {}

    for Key, Value in next, Data.Vars do
        if (type(Value) == "table") then
            if (Value.Object == nil) then -- Don't iterate through wrapped instances
                Value = Replication.StripReplicatedData(Value)
            end
        end
        Result[Key] = Value
    end

    return Result
end

function Replication.BindOnChange(Func, ...)

    local Args = {...}
    local Previous = Replication.Binds
    local ArgCount = #Args
    local Final = Args[ArgCount]
    Args[ArgCount] = nil

    for Index = 1, ArgCount - 1 do

        local Key = Args[Index]
        local Value = Previous[Key]

        if (Value == nil) then
            Previous[Key] = {}
        end

        Previous = Previous[Key]
    end

    local FinalValue = Previous[Final]

    if (FinalValue == nil) then
        Previous[Final] = {Bind = Func}
    else
        FinalValue.Bind = Func
    end
end

function Replication.CallBinds(...)

    local PreviousBind = Replication.Binds
    local PreviousReplicated = ReplicatedData
    local Args = {...}
    local ArgCount = #Args

    for Index = 1, ArgCount do

        local Value = Args[Index]
        local Temp = PreviousReplicated[Value]
        local TempBind = PreviousBind[Value]

        if (Temp ~= nil and TempBind ~= nil) then

            if (TempBind.Bind ~= nil) then
                Sub(TempBind.Bind, Temp)
            end

            PreviousReplicated = Temp
            PreviousBind = TempBind
        end
    end
end

local function ServerInit()

    -- Wrap top level of replicated data table; the rest will be recursive
    SWrapReplicatedData({}, ReplicatedData)
    ReplicatedData.TransferCheck = true

    BindRemoteEvent("GetReplicatedData", function(Player)
        FireRemoteEvent("GetReplicatedData", Player, Replication.StripReplicatedData(ReplicatedData))
    end)
end

function Replication.Wait(Item)

    Item = Item or "TransferCheck"
    local Result = ReplicatedData[Item]

    while (Result == nil) do
        wait()
        Result = ReplicatedData[Item]
    end

    return Result
end

local function ClientInit()

    CWrapReplicatedData({}, ReplicatedData)

    -- Client downloads all data when they join
    BindRemoteEvent("GetReplicatedData", function(Data)
        for Key, Value in next, Data do
            ReplicatedData[Key] = Value
        end
    end)

    -- Client requests data download
    FireRemoteEvent("GetReplicatedData")

    BindRemoteEvent("ReplicateData", function(Keys, Value)

        Replication.Wait()

        if type(Keys) == "table" then

            local FinalKey = Keys[#Keys]
            local PreviousTable = ReplicatedData
            Keys[#Keys] = nil

            for Key = 1, #Keys do -- Index along until the table we want
                PreviousTable = PreviousTable[Keys[Key]]
            end

            PreviousTable[FinalKey] = Value -- This should be wrapped as __newindex wraps new tables
        else
            ReplicatedData[Keys] = Value
        end
    end)
end

function SharedData.Wait(Item)

    local Result = SharedData[Item]

    while (Result == nil) do
        wait()
    end

    return Result
end

function SharedData.Append(Elements)
    if type(Elements) == "table" then
        for Key, Value in next, Elements do
            SharedData[Key] = Value
        end
    end
end

return {
    ReplicatedData = ReplicatedData;
    SharedData = SharedData;
    Replication = Replication;
    Init = ClientInit;
}