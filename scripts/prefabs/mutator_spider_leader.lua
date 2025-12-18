local Assets = {
    Asset("ATLAS", "images/mutator_spider_leader.xml"),
    Asset("IMAGE", "images/mutator_spider_leader.tex"),

    Asset("Assets", "anim/mutator_spider_leader.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mutator_spider_leader")
    inst.AnimState:SetBuild("mutator_spider_leader")
    inst.AnimState:PlayAnimation("idle")
    inst.scrapbook_deps = "spider_leader"

    MakeInventoryFloatable(inst,"med", 0.05,{0.65, 0.5, 0.65 })

    inst:AddTag("swich_leader") 
    inst:AddTag("nonpotatable")
    inst:AddTag("nochild")
    inst:AddTag("spidermutator")
    inst:AddTag("monstermeat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --检查组件
    inst:AddComponent("inspectable")
    --物品栏组件
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "mutator_spider_leader"
    inst.components.inventoryitem.atlasname = "images/mutator_spider_leader.xml"
    inst.components.inventoryitem:SetSinks(false)


    inst:AddComponent("edible")
    inst.components.edible.hungervalue = 75
    inst.components.edible.healthvalue = 0
    inst.components.edible.sanityvalue = -10
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.secondaryfoodtype = FOODTYPE.MONSTER

    inst:AddComponent("spidermutator")
    inst.components.spidermutator:SetMutationTarget("spider_leader")

    MakeHauntableLaunch(inst)
    
    return inst
end
return Prefab("mutator_spider_leader", fn, Assets)