local GLOBAL = _G
local BUFF = GLOBAL.SPIDERLEADER.SPIDERLEADER_BUFF
local PROPERTY = GLOBAL.SPIDERLEADER.SPIDERLEADEREPIC_PROPERYT

local assets =
{
    Asset("ANIM", "anim/ds_spider_basic.zip"),
    Asset("ANIM", "anim/spider_leader_build.zip"),
    Asset("ANIM", "anim/ds_spider_boat_jump.zip"),
    Asset("ANIM", "anim/ds_spider_parasite_death.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local prefabs =
{
    "spidergland",
    "monstermeat",
    "silk",
    "spider_mutate_fx",

    "spider_heal_fx",
    "spider_heal_target_fx",
    "spider_heal_ground_fx",

    "spider_leader_buffs"
}

local brain = require "brains/spider_leader_epicbrain"


----------- 函数和依赖 -----------


local function HasFriendlyLeader(inst, target)
    local leader = inst.components.follower.leader
    local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil

    if leader ~= nil and target_leader ~= nil then

        if target_leader.components.inventoryitem then
            target_leader = target_leader.components.inventoryitem:GetGrandOwner()
            -- Don't attack followers if their follow object has no owner
            if target_leader == nil then
                return true
            end
        end

        local PVP_enabled = TheNet:GetPVPEnabled()
        return leader == target or (target_leader ~= nil
                and (target_leader == leader or (target_leader:HasTag("player")
                and not PVP_enabled))) or
                (target.components.domesticatable and target.components.domesticatable:IsDomesticated()
                and not PVP_enabled) or
                (target.components.saltlicker and target.components.saltlicker.salted
                and not PVP_enabled)

    elseif target_leader ~= nil and target_leader.components.inventoryitem then
        -- Don't attack webber's chester
        target_leader = target_leader.components.inventoryitem:GetGrandOwner()
        return target_leader ~= nil and target_leader:HasTag("spiderwhisperer")
    end

    return false
end

local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "spiderwhisperer", "spiderdisguise", "INLIMBO" }
local function FindTarget(inst, radius)
    if not inst.no_targeting then
        return FindEntity(
            inst,
            SpringCombatMod(radius),
            function(guy)
                return (not inst.bedazzled and (not guy:HasTag("monster") or guy:HasTag("player")))
                    and inst.components.combat:CanTarget(guy)
                    and not (inst.components.follower ~= nil and inst.components.follower.leader == guy)
                    and not HasFriendlyLeader(inst, guy)
                    and not (inst.components.follower.leader ~= nil and inst.components.follower.leader:HasTag("player")
                        and guy:HasTag("player") and not TheNet:GetPVPEnabled())
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )
    end
end

local function NormalRetarget(inst)
    return FindTarget(inst, TUNING.SPIDER_TARGET_DIST)
end

local function keeptargetfn(inst, target)
   return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and not (inst.components.follower ~= nil and
                (inst.components.follower.leader == target or inst.components.follower:IsLeaderSame(target)))
end

local function SoundPath(inst, event)
    local creature = "spider"
    if inst:HasTag("spider_healer") then
        return "webber1/creatures/spider_cannonfodder/" .. event
    elseif inst:HasTag("spider_moon") then
        return "turnoftides/creatures/together/spider_moon/" .. event
    elseif inst:HasTag("spider_warrior") then
        creature = "spiderwarrior"
    elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
        creature = "cavespider"
    else
        creature = "spider"
    end
    return "dontstarve/creatures/" .. creature .. "/" .. event
end

local SPIDER_TAGS = { "spider" }
local SPIDER_IGNORE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function GetOtherSpiders(inst, radius, tags)
    tags = tags or SPIDER_TAGS
    local x, y, z = inst.Transform:GetWorldPosition()

    local spiders = TheSim:FindEntities(x, y, z, radius, nil, SPIDER_IGNORE_TAGS, tags)
    local valid_spiders = {}

    for _, spider in ipairs(spiders) do
        if spider:IsValid() and not spider.components.health:IsDead() and not spider:HasTag("playerghost") then
            table.insert(valid_spiders, spider)
        end
    end

    return valid_spiders
end

local function GetFriendlySpiders(inst, radius, tags)
    radius = radius or 10
    tags = tags or {"spider", "spiderqueen"}
    local other_spiders = GetOtherSpiders(inst, radius, tags)
    local leader = inst.components.follower.leader
    
    local targetspiders = {}
    for i, spider in ipairs(other_spiders) do
        local target = inst.components.combat.target

        local targetting_us = target ~= nil and
                             (target == inst or (leader ~= nil and
                             (target == leader or leader.components.leader:IsFollower(target))))

        local targetted_by_us = inst.components.combat.target == spider or (leader ~= nil and
                                (leader.components.combat:TargetIs(spider) or
                                leader.components.leader:IsTargetedByFollowers(spider)))

        if not (targetting_us or targetted_by_us) then
            table.insert(targetspiders,spider)
        end
    end
    return targetspiders
end

local function SpawnHealFx(inst, fx_prefab, scale)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab(fx_prefab)
    fx.Transform:SetNoFaced()
    fx.Transform:SetPosition(x,y,z)

    scale = scale or 1
    fx.Transform:SetScale(scale, scale, scale)
end

local function DoDamageOverTime(inst)
    if not inst:IsValid() or inst.components.health:IsDead() then
            return
    end
    local value = 10 + inst.components.rememberspiders:Countspiders()
    if inst.components.health ~= nil then
        inst.components.health:DoDelta(-value)
    end
    local percent = inst.components.health:GetPercent()
    if percent < 0.4 and percent > 0 then 
        inst.AnimState:SetMultColour(1,percent/0.4,percent/0.4,1)
        inst.components.locomotor.walkspeed = 3.6 * (percent + 0.2)/0.6
        inst.components.locomotor.runspeed = 3.6 * (percent + 0.2)/0.6
    end
end
-----------------------------------

----------- 事件回调函数 -----------
local function Defence(inst)
    if (inst.useskilltime == nil or GetTime() - inst.useskilltime >= 6) then
        inst.sg:GoToState("taunt")
        local radius = BUFF.DEFENCEBUFF_RADIUS
        local scale = radius*1.35 / 8
        inst.SoundEmitter:PlaySound(inst:SoundPath("heal_fartcloud"))
        SpawnHealFx(inst, "spider_heal_ground_fx", scale)
        SpawnHealFx(inst, "spider_heal_fx", scale)

        local player = inst.components.follower:GetLeader()

        local targetspiders = GetFriendlySpiders(inst, radius, {"spider", "spiderqueen", "spiderwhisperer"})
        for _, spider in ipairs(targetspiders) do
            if spider.components.follower ~= nil and spider.components.follower:GetLeader() == player then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider:AddDebuff("spider_leader_buff_defence", "spider_leader_buff_defence")
            elseif spider == player then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider:AddDebuff("spider_leader_buff_defence", "spider_leader_buff_defence")
            end
        end
        inst.useskilltime = GetTime()
    end
end

local function Attack(inst)
    if (inst.useskilltime == nil or GetTime() - inst.useskilltime >= 6) then
        inst.sg:GoToState("taunt")
        local radius = BUFF.ATTACKBUFF_RADIUS
        local scale = radius*1.35 / 8
        inst.SoundEmitter:PlaySound(inst:SoundPath("heal_fartcloud"))
        SpawnHealFx(inst, "spider_heal_ground_fx", scale)
        SpawnHealFx(inst, "spider_heal_fx", scale)

        local player = inst.components.follower:GetLeader()

        local targetspiders = GetFriendlySpiders(inst, radius, {"spider", "spiderqueen", "spiderwhisperer"})
        for _, spider in ipairs(targetspiders) do
            if spider.components.follower ~= nil and spider.components.follower:GetLeader() == player then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider:AddDebuff("spider_leader_buff_attack", "spider_leader_buff_attack")
            elseif spider == player then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider:AddDebuff("spider_leader_buff_attack", "spider_leader_buff_attack")
            end
        end
        inst.useskilltime = GetTime()
    end
end

local function OnAttacked(inst, data)
    if inst.no_targeting then
        return
    end
    if data.attacker == inst.components.follower.leader then
        return
    end
    inst.defensive = false
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
            local should_share = dude:HasTag("spider")
                and not dude.components.health:IsDead()
                and dude.components.follower ~= nil
                and dude.components.follower.leader == inst.components.follower.leader
            if should_share and dude.defensive and not dude.no_targeting then
                dude.defensive = false
            end
            return should_share
        end, 10)
end

local function OnDeath(inst)
    local spiders = inst.components.rememberspiders:GetSpiders()
    local N =  SpawnPrefab("spider")
        N.Transform:SetPosition(inst.Transform:GetWorldPosition())
        N.defensive = true
    local anim_list = {"flowers_fx1", "flowers_fx2", "flowers_fx3", "flowers_fx4","flowers_fx5"}
    for _, spider in ipairs(spiders) do
        spider.components.health.invincible = false
        spider:RemoveTag("notarget")
        local x,y,z = spider.Transform:GetWorldPosition()
        local random_anim = anim_list[math.random(#anim_list)]
        local fx = SpawnPrefab(random_anim)
                fx.Transform:SetPosition(x + 3 *(0.5 - math.random()),y + 3 *(0.5 - math.random()),z)
        spider.components.health:Kill()
    end
end

local function OnSpawn(inst)
    local spiders = inst.components.rememberspiders:GetSpiders()
    local healthval = 100
    for _, spider in ipairs(spiders) do
        if spider.components.subfollower ~= nil then
            spider.components.subfollower:SetSubLeader(inst)
        end
        spider.AnimState:SetMultColour(0.9,0.9,0.9,0.7)
        local radius = spider.Physics:GetRadius()
        spider.Physics:SetSphere(radius * 0.5)
        healthval = healthval + spider.components.health.maxhealth
        spider.components.health:SetMaxHealth(1)
        spider.components.health.invincible = true
        spider.persists = false
        spider.components.follower:KeepLeaderOnAttacked()
        spider:AddTag("notarget")
        spider:AddTag("noattack")
    end
    inst.components.health:SetMaxHealth(healthval)
end

-----------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeGiantCharacterPhysics(inst, 600, .5)

    inst.DynamicShadow:SetSize(3, 1)
    inst.Transform:SetScale(2, 2, 2)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("epic")
    inst:AddTag("spiderleaderepic")

    inst.AnimState:SetBank("spider")
    inst.AnimState:SetBuild("spider_leader_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst.persists = true

    -- 移动组件
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("rememberspiders")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)

    inst.components.locomotor.hop_distance = 3
    inst.components.locomotor.walkspeed = 3.6
    inst.components.locomotor.runspeed = 3.6

    -- 可燃性和可冻结
    MakeMediumBurnableCharacter(inst, "body")
    inst.components.burnable.flammability = 3

    MakeMediumFreezableCharacter(inst, "body")
    inst.components.freezable:SetResistance(5)
    inst.components.freezable:SetDefaultWearOffTime(2)
    inst.components.freezable.diminishingreturns = true

    -- 战斗组件
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetDefaultDamage(PROPERTY.DEFAULTDMG)
    inst.components.combat:SetAttackPeriod(PROPERTY.ATKPID)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)

    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    -- 睡眠组件
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetWakeTest(function ()
        return true
    end)
    inst.components.sleeper:SetSleepTest(function(inst)
        return false
    end)

    -- 检查组件
    inst:AddComponent("inspectable")

    -- 精神光环
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_TINY

    MakeHauntablePanic(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGspider_leader_epic")

    inst:DoPeriodicTask(1,DoDamageOverTime)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("spider_need_subleader", OnSpawn)

    inst:ListenForEvent("doDefence", Defence)
    inst:ListenForEvent("doAttack", Attack)

    inst:ListenForEvent("fighttodeath", OnSpawn)
    inst:ListenForEvent("onremove", function()
        if inst.damage_task ~= nil then
            inst.damage_task:Cancel()
            inst.damage_task = nil
        end
    end)
    -- 声音
    inst.SoundPath = SoundPath
    inst.incineratesound = inst:SoundPath("die")

    return inst
end
return Prefab("spider_leader_epic", fn, assets, prefabs)