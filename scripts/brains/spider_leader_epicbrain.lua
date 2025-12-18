require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/avoidlight"


local BrainCommon = require "brains/braincommon"

local Spider_Leader_EpicBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end
local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end


------------------------------------------------------------------------------------------

function Spider_Leader_EpicBrain:OnStart()

    local pre_nodes = PriorityNode({
		BrainCommon.PanicTrigger(self.inst),
        BrainCommon.ElectricFencePanicTrigger(self.inst),
    })

    local attack_nodes = PriorityNode({
        ChaseAndAttack(self.inst, SpringCombatMod(TUNING.SPIDER_AGGRESSIVE_MAX_CHASE_TIME)),
    })

    local follow_node = PriorityNode({
        Follow(self.inst, function() return self.inst.components.follower.leader end, 
                TUNING.SPIDER_AGGRESSIVE_MIN_FOLLOW, TUNING.SPIDER_AGGRESSIVE_MED_FOLLOW, TUNING.SPIDER_AGGRESSIVE_MAX_FOLLOW),

        IfNode(function() return self.inst.components.follower.leader ~= nil end, "HasLeader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )),
    })

    local root =
        PriorityNode(
        {
            pre_nodes,
            attack_nodes,
            follow_node,
        }, 1)
    self.bt = BT(self.inst, root)
end

return Spider_Leader_EpicBrain