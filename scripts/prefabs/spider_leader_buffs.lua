local GLOBAL = _G
local BUFF = GLOBAL.SPIDERLEADER.SPIDERLEADER_BUFF

local function OnExtended(inst, target)
    if inst.decaytimer ~= nil then
        inst.decaytimer:Cancel()
    end

    if inst.extendedfn ~= nil then
        inst.extendedfn(inst, target)
    end

    inst.decaytimer = inst:DoTaskInTime(inst.duration, function() inst.components.debuff:Stop() end)
end

local function OnAttached(inst, target)
    OnExtended(inst, target)
end

local function OnDetached(inst, target)
    if inst.decaytimer ~= nil then
        inst.decaytimer:Cancel()
        inst.decaytimer = nil
    end

    if inst.detachfn ~= nil then
        inst.detachfn(inst, target)
    end

    inst:Remove()
end

local function slowbuff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then

        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst.duration = 5
    inst.extendedfn = function(buff, target)
        target._orig_speed = target._orig_speed or target.components.locomotor.runspeed
        target.components.locomotor.runspeed = target._orig_speed*0.5

        target._fx = SpawnPrefab("forcefieldfx")
        target._fx.entity:SetParent(target.entity)

        if buff.decaytimer then buff.decaytimer:Cancel() end
        buff.decaytimer = inst:DoTaskInTime(inst.duration, function() buff.components.debuff:Stop() end)
    end

    inst.detachfn = function(buff, target)
        if target._fx ~= nil then 
            target._fx:Remove()
        end
        if target ~= nil and target:IsValid() and not target.components.health:IsDead() then
            target.components.locomotor.runspeed = target._orig_speed
        end
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)--添加
    inst.components.debuff:SetDetachedFn(OnDetached)--移除
    inst.components.debuff:SetExtendedFn(OnExtended)--延长

    return inst
end--used for test

local function defencebuff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then

        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst.duration = BUFF.DEFENCEBUFF_DURATION
    inst.extendedfn = function(buff, target)
        if target.components.health ~= nil then 

            target._orig_damage_absorb = target.components.health.absorb or 1
            target.components.health:SetAbsorptionAmount(1)
            target._orig_min_attack_period = target.components.combat.min_attack_period
            target.components.combat:SetAttackPeriod(target._orig_min_attack_period * 0.5)

            target._fx = SpawnPrefab("forcefieldfx")
            target._fx.entity:SetParent(target.entity)

            inst.decay0 = inst:DoTaskInTime(0.1*BUFF.DEFENCEBUFF_DURATION ,function ()

                inst.decay1 = inst:DoPeriodicTask(0.2 ,function ()
                    target.components.health:SetAbsorptionAmount(target.components.health.absorb * (1 - BUFF.DEFENCEBUFF_DECAY) + BUFF.DEFENCEBUFF_ABSORPTION * BUFF.DEFENCEBUFF_DECAY )
                    if target._fx ~= nil then
                        target._fx.AnimState:SetMultColour(1,1,1,target.components.health.absorb)
                    end
                    if target.components.health.absorb - BUFF.DEFENCEBUFF_ABSORPTION <= 0.04 then
                        inst.decay1:Cancel()
                    end
                end)

            end)

            if buff.decaytimer then buff.decaytimer:Cancel() end
            buff.decaytimer = inst:DoTaskInTime(inst.duration, function() buff.components.debuff:Stop() end)
        end
    end

    inst.detachfn = function(buff, target)
        if target._fx ~= nil then
            target._fx:Remove()
        end
        if target ~= nil and target:IsValid() and not target.components.health:IsDead() then
            target.components.health:SetAbsorptionAmount(target._orig_damage_absorb)
        end
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)--添加
    inst.components.debuff:SetDetachedFn(OnDetached)--移除
    inst.components.debuff:SetExtendedFn(OnExtended)--延长

    return inst
end

local function attackbuff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then

        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst.duration = BUFF.ATTACKBUFF_DURATION
    inst.extendedfn = function(buff, target)
        if target.components.health ~= nil then 

            target._orig_min_attack_period = target.components.combat.min_attack_period
            target.components.combat:SetAttackPeriod(target._orig_min_attack_period * BUFF.ATTACKBUFF_ATKPIDMUL)
            target._orig_defaultdamage = target.components.combat.defaultdamage
            target.components.combat:SetDefaultDamage(target._orig_defaultdamage * BUFF.ATTACKBUFF_ATKDMGMUL)
            target._orig_speed = target._orig_speed or target.components.locomotor.runspeed
            target.components.locomotor.runspeed = target._orig_speed * BUFF.ATTACKBUFF_SPEEDMUL

            target._fx = SpawnPrefab("attack_fx")
            target._fx.entity:SetParent(target.entity)

            if buff.decaytimer then buff.decaytimer:Cancel() end
            buff.decaytimer = inst:DoTaskInTime(inst.duration, function() buff.components.debuff:Stop() end)
        end
    end

    inst.detachfn = function(buff, target)
        if target._fx ~= nil then 
            target._fx:Remove()
        end
        if target ~= nil and target:IsValid() and not target.components.health:IsDead() then
            target.components.combat:SetAttackPeriod(target._orig_min_attack_period)
            target.components.combat:SetDefaultDamage(target._orig_defaultdamage)
            target.components.locomotor.runspeed = target._orig_speed
        end
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)--添加
    inst.components.debuff:SetDetachedFn(OnDetached)--移除
    inst.components.debuff:SetExtendedFn(OnExtended)--延长

    return inst
end
return Prefab("spider_leader_buff_slow", slowbuff_fn),
       Prefab("spider_leader_buff_defence", defencebuff_fn),
       Prefab("spider_leader_buff_attack", attackbuff_fn)