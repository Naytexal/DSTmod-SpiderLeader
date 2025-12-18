require("stategraphs/commonstates")
------------------------------------------------------------------------------------


----------------------------------------事件----------------------------------------
local events ={
    CommonHandlers.OnHop(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
    CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),

    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
                inst.sg:GoToState("attack", data.target)
        end
    end),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack")
                and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("idle", "walk_pst")
                end
            end
        end
    end),

    EventHandler("death", function(inst) 
        inst.sg:GoToState("death") 
    end),
}

------------------------------------------------------------------------------------

local function SoundPath(inst, event)
    return inst:SoundPath(event)
end

----------------------------------------状态----------------------------------------
local states ={
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()

            if not inst.shadowthrall_parasite_hosted_death or not TheWorld.components.shadowparasitemanager then
                RemovePhysicsColliders(inst)
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.shadowthrall_parasite_hosted_death and TheWorld.components.shadowparasitemanager then
                    TheWorld.components.shadowparasitemanager:ReviveHosted(inst)
                end
            end),
        },
    },--"death":死亡状态    标签["busy"]

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },--"premoving":预移动状态    标签["moving", "canrotate"]

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },--"moving":移动状态    标签["moving", "canrotate"]

    State{
        name = "idle",
        tags = {"idle", "canrotate"},


        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            local animname = "idle"
            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },--"idle":闲置状态    标签["idle", "canrotate"]

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            ShakeAllCameras(CAMERASHAKE.FULL, 1, .015, .3, inst, 30)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },--"taunt":嘲讽状态    标签["busy"]

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            TimeEvent(25*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },--"attack":攻击状态    标签["attack", "busy"]

    State{
        name = "mutate_pst",
		tags = { "busy", "mutating", "noelectrocute" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,
        events=
        {
            EventHandler("animqueueover", function(inst)
            inst.sg:GoToState("taunt") end),
        },
    },--"mutate_pst":变身后状态   标签["busy", "mutating", "noelectrocute"]

}

------------------------------------------------------------------------------------


----------------------------------------通用----------------------------------------

CommonStates.AddSleepStates(states)

CommonStates.AddFrozenStates(states)

CommonStates.AddElectrocuteStates(states)

CommonStates.AddHopStates(states, true, { pre = "boat_jump_pre", loop = "boat_jump", pst = "boat_jump_pst"})

CommonStates.AddSinkAndWashAshoreStates(states)

CommonStates.AddVoidFallStates(states)

------------------------------------------------------------------------------------

return StateGraph("spider_leader_epic", states, events, "idle")