local assets =
{
   Asset("ANIM", "anim/attack_fx.zip"),
}

local function kill_fx(inst)
    inst:DoTaskInTime(.6, inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("attack_fx")
    inst.AnimState:SetBuild("attack_fx")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.kill_fx = kill_fx

    return inst
end

return Prefab("attack_fx", fn, assets)