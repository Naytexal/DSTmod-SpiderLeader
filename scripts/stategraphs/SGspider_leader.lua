local RIDUS = _G.SPIDERLEADER.SPIDERLEADER_BUFF.FINALCOMBAT_RADIUS

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


    EventHandler("attacked", function(inst, data)
		if not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif not inst.sg:HasAnyStateTag("attack", "electrocute")
			    then
				    inst.sg:GoToState("hit")
			end
		end
	end),

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

local function SpawnHealFx(inst, fx_prefab, scale)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab(fx_prefab)
    fx.Transform:SetNoFaced()
    fx.Transform:SetPosition(x,y,z)

    scale = scale or 1
    fx.Transform:SetScale(scale, scale, scale)
end

local function GetSpiders(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local targetspiders = TheSim:FindEntities(x, y, z, RIDUS, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO" }, {"spider"})
    local spiders = {}
    for _, spider in ipairs(targetspiders) do
        if spider ~= inst
            and spider.components.follower.leader ~= nil and inst.components.follower.leader ~= nil
            and inst.components.follower.leader == spider.components.follower.leader 
            and spider:IsValid() 
            and not spider.components.health:IsDead() 
            and not spider:HasTag("playerghost")
            then
            table.insert(spiders,spider)
        end
    end
    return spiders
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

        ontimeout = function(inst)
            inst.sg:GoToState("taunt")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            local animname = "idle"
            if math.random() < 0.3 then
                inst.sg:SetTimeout(math.random()*2 + 2)
            end
            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },--"idle":闲置状态    标签["idle", "canrotate"]

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst, forced)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.sg.statemem.forced = forced
            inst.SoundEmitter:PlaySound(SoundPath(inst, "eat"), "eating")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local state = (inst:PerformBufferedAction() or inst.sg.statemem.forced) and "eat_loop" or "idle"
                if state == "idle" then
                    inst.SoundEmitter:KillSound("eating")
                end
                inst.sg:GoToState(state)
            end),
        },
    },--"eat":吃状态    标签["busy"]

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1+math.random()*1)
        end,

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },--"eat_loop":不断吃状态    标签["busy"]

    State{
        name = "born",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },--"born":出生状态    标签["busy"]

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
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
        name = "hit",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },--"hit":受击状态    标签[]

    State{
        name = "mutate",
		tags = { "busy", "mutating", "noelectrocute" },

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,

        timeline=
        {
            TimeEvent(14*FRAMES, function (inst)
                inst.components.inventory:DropEverything()
                
                local spider_boss = SpawnPrefab("spider_leader_epic")
                if spider_boss then
                    local spiders = GetSpiders(inst)
                    local x,y,z = inst.Transform:GetWorldPosition()
                    spider_boss.Transform:SetPosition(x,y,z)

                    if inst.components.follower.leader ~= nil then
                        spider_boss.components.follower:SetLeader(inst.components.follower.leader)
                    end

                    if inst.components.combat:HasTarget() then
                        spider_boss.components.combat:SetTarget(inst.components.combat.target)
                    end

                    spider_boss.sg:GoToState("mutate_pst")   --新蜘蛛生成时进入变身后状态
                    for _, spider in ipairs(spiders) do
                        spider_boss.components.rememberspiders:AddSpider(spider)
                        SpawnHealFx(spider, "spider_heal_target_fx")
                        spider.sg:GoToState("idle")
                        spider.AnimState:PlayAnimation("cower")
                        spider.AnimState:PushAnimation("cower_loop")
                    end
                    local fx = SpawnPrefab("spider_mutate_fx")
                    fx.Transform:SetPosition(x,y,z)--生成特效
                    fx.Transform:SetScale(2.5,2.5,2.5)
                    spider_boss:PushEvent("fighttodeath")
                    inst:Remove()
                end
            end)
        },

        events=
        {
        },
    },--"mutate":变身状态   标签["busy", "mutating", "noelectrocute"]

    State{
        name = "mutate_pst",
		tags = { "busy", "mutating", "noelectrocute" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("mutate_pst")
        end,

        events=
        {
            EventHandler("animqueueover", function(inst)
            inst:PushEvent("spider_need_subleader")
            inst.sg:GoToState("idle") end),
        },
    },--"mutate_pst":变身后状态   标签["busy", "mutating", "noelectrocute"]

    State{
        name = "trapped",
		tags = { "busy", "trapped", "noelectrocute" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("cower")
            inst.AnimState:PushAnimation("cower_loop", true)
            inst.sg:SetTimeout(1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },--"trapped":被困住状态   标签["busy", "trapped", "noelectrocute"]
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

return StateGraph("spider_leader", states, events, "idle")