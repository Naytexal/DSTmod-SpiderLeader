local Assets = {
	Asset("Assets", "anim/flowers_fx.zip"),
}


local function Commonfxfn(animloop ,animbloom, animfade)
    local inst = CreateEntity()
    inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("flowers_fx")
    inst.AnimState:SetBuild("flowers_fx")

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

	anim:PlayAnimation(animbloom)
	anim:PushAnimation(animloop, true)
	inst.Transform:SetScale(0.63,0.63,0.63)
	inst:DoTaskInTime(60 , function ()
    anim:PushAnimation(animfade)
    inst:ListenForEvent("animover", function() inst:Remove() end)
    end)

    inst.persists = false
    return inst
end
local function fn1()
    return Commonfxfn("flowers1_loop","bloom1","fade1")
end
local function fn2()
    return Commonfxfn("flowers2_loop","bloom2","fade2")
end
local function fn3()
    return Commonfxfn("flowers3_loop","bloom3","fade3")
end
local function fn4()
    return Commonfxfn("flowers4_loop","bloom4","fade4")
end
local function fn5()
    return Commonfxfn("flowers5_loop","bloom5","fade5")
end
return Prefab("flowers_fx1", fn1, Assets),
       Prefab("flowers_fx2", fn2, Assets),
       Prefab("flowers_fx3", fn3, Assets),
       Prefab("flowers_fx4", fn4, Assets),
       Prefab("flowers_fx5", fn5, Assets)