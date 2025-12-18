require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/avoidlight"


local BrainCommon = require "brains/braincommon"

local Spider_LeaderBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end
local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function GetSubFaceTargetFn(inst)
    return inst.components.subfollower.subleader
end

local function KeepSubFaceTargetFn(inst, target)
    return inst.components.subfollower.subleader == target
end

local function GetSubLeaderTarget(inst)
    local subleader = inst.components.subfollower:GetSubLeader()
    if subleader and subleader:IsValid() then
        return subleader
    else
        return nil
    end
end

------------------------------------------------------------------------------------------

function Spider_LeaderBrain:OnStart()

    local pre_nodes = PriorityNode({
        BrainCommon.PanicWhenScared(self.inst),
		BrainCommon.PanicTrigger(self.inst),
        BrainCommon.ElectricFencePanicTrigger(self.inst),
    })


    local attack_nodes = PriorityNode({
        ChaseAndAttack(self.inst, SpringCombatMod(TUNING.SPIDER_AGGRESSIVE_MAX_CHASE_TIME)),
    })


    local follow_subleader = PriorityNode({
        Follow(self.inst, function() return GetSubLeaderTarget(self.inst) end, 2, 2, 4),
    })

    local follow_leader = PriorityNode({
        Follow(self.inst, function() return self.inst.components.follower.leader end, 
                TUNING.SPIDER_DEFENSIVE_MIN_FOLLOW, TUNING.SPIDER_DEFENSIVE_MED_FOLLOW, TUNING.SPIDER_DEFENSIVE_MAX_FOLLOW),
    })

    local follow_nodes = PriorityNode({
        IfNode(function() return GetSubLeaderTarget(self.inst) ~= nil end, "FollowSubleader",
            follow_subleader),
        
        IfNode(function() return GetSubLeaderTarget(self.inst) == nil 
            and self.inst.components.follower:GetLeader() ~= nil end, "Followleader",
            follow_leader),
        
        IfNode(function() return self.inst.components.follower.leader ~= nil end, "HasLeader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )),

        IfNode(function() return self.inst.components.follower.leader == nil and GetSubLeaderTarget(self.inst) ~= nil end , "HasSubLeader",
            FaceEntity(self.inst, GetSubFaceTargetFn, KeepSubFaceTargetFn)),
    })

    local root =
        PriorityNode(
        {
            pre_nodes,
            attack_nodes,
            follow_nodes,
        }, 1)
    self.bt = BT(self.inst, root)
end

return Spider_LeaderBrain