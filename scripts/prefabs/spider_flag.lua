local Assets = {
    Asset("ATLAS", "images/spider_flag.xml"),
    Asset("IMAGE", "images/spider_flag.tex"),
    Asset("Assets", "anim/spider_flag.zip"),
    Asset("ATLAS", "images/inventoryimages/spider_flag.xml"),
    Asset("IMAGE", "images/inventoryimages/spider_flag.tex"),
}
local prefabs =
{

    "spider_heal_fx",
    "spider_heal_target_fx",
    "spider_heal_ground_fx",

}


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

local function SpawnHealFx(inst, fx_prefab, scale)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab(fx_prefab)
    fx.Transform:SetNoFaced()
    fx.Transform:SetPosition(x,y,z)

    scale = scale or 1
    fx.Transform:SetScale(scale, scale, scale)
end

local function OnUsedOnSpider(inst, target, user)
    if user ~= nil and target.components.health:IsDead() and target.components.subfollower.subleader ~= inst then
        return false
    end
    target.sg:GoToState("idle")
    if user ~= nil and user:HasTag("spiderwhisperer")
        and target.components.follower:GetLeader() == user
    then
        local spiders = GetOtherSpiders(inst,12)
        for _, spider in pairs(spiders) do
            if
                spider ~= target
                and spider:IsValid()
                and spider.components.subfollower ~= nil
                and spider.components.subfollower:GetSubLeader() == nil
                and spider:HasTag("spider")
                and not spider:HasTag("spiderleader")
                then
                SpawnHealFx(spider, "spider_heal_target_fx")
                spider.components.subfollower.subleader = target
                spider.defensive = true
                spider.bedazzled = true
                spider.ghost_babysitter = true
                if target.components.rememberspiders then target.components.rememberspiders:AddSpider(spider) end
                else
            end
        end
        target.ghost_babysitter = true
        return true
    end
end

local function OnStopUse(inst)
    if inst.components.inventoryitem then
        local spider_leader = inst.components.rememberspiders:GetSingleSpider()
        if  spider_leader ~= nil 
            and spider_leader:IsValid()
            and spider_leader.components.rememberspiders ~= nil 
            then
            local followers = spider_leader.components.rememberspiders:GetSpiders()
            for _, follower in pairs(followers) do
                if follower:IsValid()
                    and not follower:HasTag("spiderleader") then
                    if follower.components.subfollower then
                        SpawnHealFx(follower, "spider_heal_target_fx")
                        follower.components.subfollower:SetSubLeader(nil)
                        spider_leader.components.rememberspiders:Removespider(follower)
                        follower.bedazzled = false
                        follower.ghost_babysitter = false
                    end
                end
            end
        end
        inst.ghost_babysitter = false
    end
    
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spider_flag")
    inst.AnimState:SetBuild("spider_flag")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst,"med", 0.05,{0.65, 0.5, 0.65 })

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("spider_flag.tex")

    inst:AddTag("spider_flag")
    inst:AddTag("irreplaceable")
    inst:AddTag("nonpotatable")
    inst:AddTag("nochild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("follower")
    inst:AddComponent("rememberspiders")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "spider_flag"
    inst.components.inventoryitem.atlasname = "images/spider_flag.xml"
    inst.components.inventoryitem:SetSinks(false)

    inst:AddComponent("useabletargeteditem")
    inst.components.useabletargeteditem:SetTargetPrefab("spider_leader")
    inst.components.useabletargeteditem:SetOnUseFn(OnUsedOnSpider)
    inst.components.useabletargeteditem:SetOnStopUseFn(OnStopUse)
    inst.components.useabletargeteditem:SetInventoryDisable(true)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("spider_flag", fn, Assets)