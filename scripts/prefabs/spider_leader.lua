local GLOBAL = _G
local BUFF = GLOBAL.SPIDERLEADER.SPIDERLEADER_BUFF
local PROPERTY = GLOBAL.SPIDERLEADER.SPIDERLEADER_PROPERTY
local COOLDOWNTIME = GLOBAL.SPIDERLEADER.SKILLCOOLDOWN

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

    "spider_leader_buffs",
    "spider_buffs"
}

local brain = require "brains/spider_leaderbrain"


----------- 函数和依赖 -----------
local function ShouldAcceptItem(inst, item, giver)
    if inst.components.health ~= nil and inst.components.health:IsDead() then
        return false, "DEAD"
    end

    return
        (giver:HasTag("spiderwhisperer") and inst.components.eater:CanEat(item)) or
        (item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD)
end

local function CalcSanityAura(inst, observer)
    if observer:HasTag("spiderwhisperer") or inst.bedazzled or
    (inst.components.follower.leader ~= nil and inst.components.follower.leader:HasTag("spiderwhisperer")) then
        return TUNING.SANITYAURA_TINY * 0.3
    end

    return 0
end

local function OnGetItemFromPlayer(inst, giver, item)

    if inst.components.eater:CanEat(item) then
        inst.components.eater:Eat(item)
        inst.sg:GoToState("eat", true)

        local playedfriendsfx = false
        if inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        elseif giver.components.leader ~= nil and
            inst.components.follower ~= nil then
            if giver.components.minigame_participator == nil then
                giver:PushEvent("makefriend")
                giver.components.leader:AddFollower(inst)
                playedfriendsfx = true
            end
        end
    elseif item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("taunt")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function keeptargetfn(inst, target)
   return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and not (inst.components.follower ~= nil and
                (inst.components.follower.leader == target or inst.components.follower:IsLeaderSame(target)))
end

local function BasicWakeCheck(inst)
    return inst.components.combat:HasTarget()
        or (inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome())
        or inst.components.burnable:IsBurning()
        or inst.components.freezable:IsFrozen()
        or inst.components.health.takingfiredamage
        or inst.components.follower:GetLeader() ~= nil
        or inst.summoned
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

local function Getsubleader(inst)
    if inst.components.subfollower.subleader ~= nil
    then
        return inst.components.subfollower:GetSubLeader()
    end
end

local function OnSave(inst, data)
    local subleader = Getsubleader(inst)
    if subleader ~= nil then 
        data.spider_leader_record = subleader:GetSaveRecord()
    end
    data.guid = inst.GUID
    return data
end

local function OnLoad(inst, data)
        
    if data ~= nil and data.spider_leader_record ~= nil then
        local subleader = SpawnSaveRecord(data.spider_leader_record)
        if subleader ~= nil then
            inst.components.subfollower:SetSubLeader(subleader)
            subleader.components.rememberspiders:SetSingleSpider(inst)
        end
    end
    if not data then return end
    inst.GUID = data.guid

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

local function AddOBuff(target, name, prefab)
    if target.components.debuffable == nil then
        target:AddComponent("debuffable")
    end
    local existing_buff = target.components.debuffable:GetDebuff(name)
    if existing_buff ~= nil and existing_buff:IsValid() then
        target.components.debuffable:RemoveDebuff(name)
        target:AddDebuff(name, prefab)
    else
        target:AddDebuff(name, prefab)
    end
end
-----------------------------------

----------- 事件回调函数 -----------
local function Frighten(inst)
        inst.sg:GoToState("taunt")
        local radius = BUFF.FRIGHTENBUFF_RADIUS
        local scale = radius*1.35 / 8
        inst.SoundEmitter:PlaySound(inst:SoundPath("heal_fartcloud"))
        SpawnHealFx(inst, "spider_heal_ground_fx", scale)
        SpawnHealFx(inst, "spider_heal_fx", scale)

        ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .15, inst, 30)

        local x, y, z = inst.Transform:GetWorldPosition()
        local vaildtargets = TheSim:FindEntities(x, y, z, radius, nil, {"INLIMBO"}, { "_combat", "locomotor" })
        for _, target in ipairs(vaildtargets) do
            if target:HasTag("epic") then
                if target.components.combat ~= nil then target.components.combat:SetTarget(nil) end
            elseif target.entity:IsVisible() and not (target.components.health ~= nil and target.components.health:IsDead()) then
                if target:HasTag("spider") then
                    target:PushEvent("epicscare", { scarer = inst, duration = 1.5})
                    if target.defensive ~= nil then
                        AddOBuff(target,"spider_whistle_buff","spider_whistle_buff")
                        target.defensive = true
                    end
                else
                    target:PushEvent("epicscare", { scarer = inst, duration = 3}) 
                end
            end
        end

        -- AddOBuff(inst,"spider_whistle_buff","spider_whistle_buff")
        inst.useskilltime = GetTime()
end

local function Defence(inst)
    if (inst.useskilltime == nil or GetTime() - inst.useskilltime >= COOLDOWNTIME) then
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
                AddOBuff(spider,"spider_leader_buff_defence", "spider_leader_buff_defence")
            elseif spider:HasTag("player") and not TheNet:GetPVPEnabled() then
                SpawnHealFx(spider, "spider_heal_target_fx")
                AddOBuff(spider,"spider_leader_buff_defence", "spider_leader_buff_defence")
            end
        end
        inst.useskilltime = GetTime()
    end
end

local function Attack(inst)
    if (inst.useskilltime == nil or GetTime() - inst.useskilltime >= COOLDOWNTIME) then
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
                AddOBuff(spider,"spider_leader_buff_attack", "spider_leader_buff_attack")
            elseif spider:HasTag("player") and not TheNet:GetPVPEnabled()  then
                SpawnHealFx(spider, "spider_heal_target_fx")
                AddOBuff(spider,"spider_leader_buff_attack", "spider_leader_buff_attack")
            end
        end
        inst.useskilltime = GetTime()
    end
end

local function Recover(inst)
    if (inst.useskilltime == nil or GetTime() - inst.useskilltime >= COOLDOWNTIME) then
        inst.sg:GoToState("taunt")
        local radius = BUFF.RECOVER_RADIUS
        local scale = radius*1.35 / 8
        inst.SoundEmitter:PlaySound(inst:SoundPath("heal_fartcloud"))
        SpawnHealFx(inst, "spider_heal_ground_fx", scale)
        SpawnHealFx(inst, "spider_heal_fx", scale)

        local player = inst.components.follower:GetLeader()

        local targetspiders = GetFriendlySpiders(inst, radius, {"spider", "spiderqueen", "spiderwhisperer"})
        for _, spider in ipairs(targetspiders) do
            if spider.components.follower ~= nil and spider.components.follower:GetLeader() == player and not spider:HasTag("spiderleader") then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider.components.health:DoDelta(600)
            elseif spider:HasTag("player") and not TheNet:GetPVPEnabled() then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider.components.health:DoDelta(24)
            end
        end
        local health = inst.components.health.currenthealth
        inst.components.health:SetCurrentHealth(health * 0.4)
        inst.components.health:DoDelta(-20)
        inst:DoTaskInTime(1.5,function ()
            inst.taska = inst:DoPeriodicTask(0.5, function ()
                SpawnHealFx(inst, "spider_heal_target_fx")
                inst.components.health:DoDelta(health * 0.05)
            end)
        end)
        
        inst:DoTaskInTime(6,function ()
            inst.taska:Cancel()
        end)
        inst.useskilltime = GetTime()
    end
end

local function Finalcombat(inst)
    local radius = BUFF.FINALCOMBAT_RADIUS
    local scale = radius*1.35 / 8
    inst.SoundEmitter:PlaySound(inst:SoundPath("heal_fartcloud"))
    SpawnHealFx(inst, "spider_heal_ground_fx", scale)
    SpawnHealFx(inst, "spider_heal_fx", scale)

    inst.sg:GoToState("mutate")
    inst.useskilltime = GetTime()
end

local function OnAttacked(inst, data)
    if inst.no_targeting then
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
    if inst.components.rememberspiders then
        local spiders = inst.components.rememberspiders:GetSpiders()
        if spiders ~= nil then
            for _, spider in pairs(spiders) do
                if spider.components.subfollower then
                    spider.components.subfollower:SetSubLeader(nil)
                    spider.ghost_babysitter = false
                end
            end
        end
    end
    if inst.taska ~= nil then
        inst.taska:Cancel()
    end
end

local function OnSpawn(inst)
    if inst.components.subfollower and inst.components.subfollower.subleader == nil then
        local subleader = SpawnPrefab("spider_flag")
        if not subleader or not subleader:IsValid() then return end
        
        subleader.Transform:SetPosition(inst.Transform:GetWorldPosition())
        subleader.components.inventoryitem:OnDropped(true, .5)

        inst.components.subfollower:SetSubLeader(subleader)
        subleader.components.rememberspiders:SetSingleSpider(inst)
    end
end
-----------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, 0.5)

    inst.DynamicShadow:SetSize(2.1, 0.7)
    inst.Transform:SetScale(1.2, 1.2, 1.2)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("spider")
    inst:AddTag("drop_inventory_onmurder")
    inst:AddTag("spiderleader")
    inst:AddTag("smallcreature")
    inst:AddTag("trader")

    inst.AnimState:SetBank("spider")
    inst.AnimState:SetBuild("spider_leader_build")--
    inst.AnimState:PlayAnimation("idle", true)

    MakeFeedableSmallLivestockPristine(inst)

    inst.scrapbook_deps = {"silk","spidergland","monstermeat"}

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    -- 管理跟随的组件
    inst:AddComponent("subfollower")
    inst:AddComponent("rememberspiders")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.Getsubleader = Getsubleader
    inst.persists = true


    -- 移动组件
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }

    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst.components.locomotor.hop_distance = 3
    inst.components.locomotor.walkspeed = TUNING.SPIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_RUN_SPEED

    -- 掉落物组件
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
    inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper:AddRandomLoot("spidergland", .5)
    inst.components.lootdropper:AddRandomHauntedLoot("spidergland", 1)
    inst.components.lootdropper.numrandomloot = 1

    -- 可燃性和可冻结
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.freezable:SetResistance(3)
    inst.components.freezable:SetDefaultWearOffTime(3)

    -- 生命值组件
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(PROPERTY.MAXHEALTH)
    
    -- 战斗组件
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetDefaultDamage(PROPERTY.DEFAULTDMG)
    inst.components.combat:SetAttackPeriod(PROPERTY.ATKPID)

    inst:AddComponent("follower")

    -- 睡眠组件
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetWakeTest(BasicWakeCheck)
    inst.components.sleeper:SetSleepTest(function(inst)
        return false
    end)

    -- 进食组件
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true)
    inst.components.eater:SetCanEatRawMeat(true)

    -- 检查组件
    inst:AddComponent("inspectable")

    -- 仓库组件
    inst:AddComponent("inventory")

    -- 交易组件
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetAbleToAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    -- 精神光环
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    MakeHauntablePanic(inst)



    inst:SetBrain(brain)
    inst:SetStateGraph("SGspider_leader")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("spider_need_subleader", OnSpawn)

    inst:ListenForEvent("doFrighten", Frighten)
    inst:ListenForEvent("doDefence", Defence)
    inst:ListenForEvent("doAttack", Attack)
    inst:ListenForEvent("doFinalcombat", Finalcombat)
    inst:ListenForEvent("doRecover", Recover)

    function inst:GetFriendlySpiders(inst)
        GetFriendlySpiders(inst)
    end

    -- 声音
    inst.SoundPath = SoundPath
    inst.incineratesound = inst:SoundPath("die")

    return inst
end
return Prefab("spider_leader", fn, assets, prefabs)