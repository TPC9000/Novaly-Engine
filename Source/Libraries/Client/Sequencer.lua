local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")
local Modules = Novarine:Get("Modules")
local RunService = Novarine:Get("RunService")
local TimeSpring = Novarine:Get("TimeSpring")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Sequencer = {
    Sequences       = {};
    EasingStyles    = require(Modules.TweeningStyles);
    PresetEasing    = {
        ["LowElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.1;
        };
        ["MidElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.3;
        };
        ["HighElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.6;
        };
    };
};

function Sequencer:Register(Target)
    self.Sequences[Target] = true
end

function Sequencer:Deregister(Target)
    self.Sequences[Target] = nil
end

function Sequencer:PreRender(Target)
   -- Todo
end

function Sequencer:AddEasingStyle(Name, Spring)
    self.EasingStyles[Name] = function(CurrentTime)
        return Spring:UpdateAt(CurrentTime).Current
    end
end

function Sequencer.Init()

    -- Main update event
    Async.Timer(1/60, function(Step)
        local SequenceCount = 0
        local ActiveSequenceCount = 0

        for Subject in pairs(Sequencer.Sequences) do
            if (Subject.Play) then
                Subject:Step(Step)
                ActiveSequenceCount = ActiveSequenceCount + 1
            end

            SequenceCount = SequenceCount + 1
        end

        Sequencer.SequenceCount = SequenceCount
        Sequencer.ActiveSequenceCount = ActiveSequenceCount
    end, "SequenceBatch")

    for Name, Properties in pairs(Sequencer.PresetEasing) do
        Sequencer:AddEasingStyle(Name, TimeSpring.New(Properties))
    end
end

return Sequencer