local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Original = OriginalEnv["table"]

local Table = setmetatable({}, {__index = function(Self, Key)

    return rawget(Self, Key) or Original[Key]

end})

function Table.Find(Array, Item)

    for x = 1, #Array do

        if Array[x] == Item then

            return x

        end

    end

    return false

end

function Table.Reverse(Array)

    local Num = #Array

    for Index = 1, Num / 2 do

        local Opposite = Num - Index
        Array[Index], Array[Opposite] = Array[Opposite], Array[Index]

    end

end

function Table.ShallowClone(Array)

    local Result = {}

    for Key, Value in next, Array do

        Result[Key] = Value

    end

    return Result

end


function Table.PrintTable(Arr, Layer)

    local Layer = Layer or 1
    local Tab = ("    "):rep(Layer)

    if Layer == 1 then

        print("Base Table = " .. tostring(Arr))

    end

    for Key, Value in next, Arr do

        if type(Value) == "table" then

            print(Tab .. Key .. " (Table) = " .. tostring(Value))
            Table.PrintTable(Value, Layer + 1)

        else

            print(Tab .. Key .. " = " .. tostring(Value))

        end

    end

end

function Table.Clone(Array)

    local Result = {}

    for Key, Value in next, Array do

        if type(Value) == "table" then

            Value = Table.Clone(Value)

        end
        Result[Key] = Value

    end

    return Result

end

function Table.GetValueSequence(Arr, Keys)

    for Key = 1, #Keys do

        Arr = Arr[Key]

    end

    return Arr

end

function Table.SetValueSequence(Arr, Keys, Val)

    local Len = #Keys

    for Key = 1, Len - 1 do

        Arr = Arr[Key]

    end

    Arr[Keys[Len]] = Val

end

function Table.CopyAndAppend(Arr, Val)

    local Result = Table.Clone(Arr)
    Result[#Result + 1] = Val

    return Result

end

function Table.MergeKey(Arr1, Arr2)

    for Key, Value in next, Arr2 do

        Arr1[Key] = Value

    end

end

function Table.CopyAndMergeKey(Arr1, Arr2)

    local Result = {}

    for Key, Value in next, Arr1 do

        Result[Key] = Value

    end

    for Key, Value in next, Arr2 do

        Result[Key] = Value

    end

    return Result

end

function Table.MergeNumerical(Arr1, Arr2)

    local Count = #Arr1

    for Iter = 1, #Arr2 do

        Arr1[Count + Iter] = Arr2[Iter]

    end

end

function Table.CopyAndMergeNumerical(Arr1, Arr2)

    local Result = {}
    local Count = #Arr1

    for Iter = 1, Count do

        Result[Iter] = Arr1[Iter]

    end

    for Iter = 1, #Arr2 do

        Result[Count + Iter] = Arr2[Iter]

    end

    return Result

end

function Table.ProtectedForeach(Arr, Func)

    for Key, Value in next, Arr do

        local Success, Result = Sub(Func, Key, Value)

        if not Success then

            print(Result)

        end

    end

end

function Table.ProtectedForeachI(Arr, Func)

    for Index, Value in ipairs(Arr) do

        local Success, Result = Sub(Func, Index, Value)

        if not Success then

            print(Result)

        end

    end

end

Func({
    Client = {table = Table, Table = Table};
    Server = {table = Table, Table = Table};
})

return true