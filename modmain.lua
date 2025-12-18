_G = GLOBAL
GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })

require "components/subfollower"
local tab = require("widgets.tab")

Assets = 
{
    Asset("ANIM", "anim/ds_spider_basic.zip"),
    Asset("ANIM", "anim/spider_build.zip"),
    Asset("ANIM", "anim/ds_spider_boat_jump.zip"),
    Asset("ANIM", "anim/ds_spider_parasite_death.zip"),
    Asset("SOUND", "sound/spider.fsb"),

    Asset("ATLAS", "images/inventoryimages/mutator_spider_leader.xml"),
    Asset("IMAGE", "images/inventoryimages/mutator_spider_leader.tex"),
    Asset("ATLAS", "images/inventoryimages/spider_leader_whistle.xml"),
    Asset("IMAGE", "images/inventoryimages/spider_leader_whistle.tex"),
    Asset("ATLAS", "images/inventoryimages/spider_leader_whistle0.xml"),
    Asset("IMAGE", "images/inventoryimages/spider_leader_whistle0.tex"),
    Asset("ATLAS", "images/inventoryimages/spider_flag.xml"),
    Asset("IMAGE", "images/inventoryimages/spider_flag.tex"),

    Asset("ANIM", "anim/mutator_spider_leader.zip"),
    Asset("ANIM", "anim/spider_flag.zip"),
    Asset("ANIM", "anim/spell_icons_spider.zip"),
    Asset("ANIM", "anim/flowers_fx.zip"),
}

AddMinimapAtlas("images/inventoryimages/spider_flag.xml")

PrefabFiles = {
    "spider_leader",
    "spider_flag",
    "mutator_spider_leader",
    "spider_leader_whistle0",
    "spider_leader_whistle",
    "spider_leader_buffs",
    "spider_leader_epic",
    "flowers_fx",
    "attack_fx",
}



local spider_whistle_useamount = GetModConfigData("spider_whistle_useamount")
local spider_diet = GetModConfigData("spider_diet")

local defencebuffradius = GetModConfigData("defencebuffradius")
local defencebuffabsorption = GetModConfigData("defencebuffabsorption")
local defencebuffduration = GetModConfigData("defencebuffduration")
local defencebuffdecay = GetModConfigData("defencebuffdecay")

local attackbuffradius = GetModConfigData("attackbuffradius")
local attackbuffatkdmgmul = GetModConfigData("attackbuffatkdmgmul")
local attackbuffatkpidmul = GetModConfigData("attackbuffatkpidmul")
local attackbuffduration = GetModConfigData("attackbuffduration")

local frightenradius = GetModConfigData("frightenradius")

local recoverradius = GetModConfigData("recoverradius")
local recovercooldown = GetModConfigData("recovercooldown")

local spiderleaderhealth = GetModConfigData("spiderleaderhealth")
local skillcooldown = GetModConfigData("skillcooldown")
local followdistance = GetModConfigData("followdistance")

GLOBAL.SPIDERLEADER = {
    LANGUAGE = language,
    SPIDERLEADER_BUFF = {
        DEFENCEBUFF_DURATION = defencebuffduration,         --防御buff持续时间
        DEFENCEBUFF_ABSORPTION = defencebuffabsorption,     --防御buff强度
        DEFENCEBUFF_RADIUS = defencebuffradius,             --防御buff半径
        DEFENCEBUFF_DECAY = defencebuffdecay,               --防御buff衰减系数

        ATTACKBUFF_DURATION = attackbuffduration,           --进攻buff持续时间
        ATTACKBUFF_ATKPIDMUL = 1 - attackbuffatkpidmul,     --进攻buff缩减攻击间隔
        ATTACKBUFF_ATKDMGMUL = 1 + attackbuffatkdmgmul,     --进攻buff增加攻击力
        ATTACKBUFF_SPEEDMUL = 1.3,                          --进攻buff加速
        ATTACKBUFF_RADIUS = attackbuffradius,               --进攻buff半径

        FRIGHTENBUFF_RADIUS = frightenradius,               --恐惧半径

        RECOVER_RADIUS = recoverradius,                     --治疗半径

        FINALCOMBAT_RADIUS = 14,                            --搜索半径
    },
    SPIDERLEADER_PROPERTY = {
        MAXHEALTH = spiderleaderhealth,                     --蜘蛛领袖血量
        DEFAULTDMG = 10,                                    --攻击伤害
        ATKPID = 3,                                         --攻击间隔
    },
    SPIDERLEADEREPIC_PROPERYT = {
        DEFAULTDMG = 30,                                    --攻击伤害
        ATKPID = 1.7,                                       --攻击间隔
    },
    SKILLCOOLDOWN = skillcooldown,                          --技能CD
    RECOVERCOOLDOWN = recovercooldown,                      --治疗CD
    FRIGHTENCOOLDOWN = 4.5,                                 --恐惧CD
}
local language = GetModConfigData("language_setting")
if language == "ch" then 
    modimport("language/ch.lua")
    GLOBAL.SPIDERLEADER.SKILLNAME = {
        DEFENCE = "防御",
        ATTACK = "进攻",
        SCARE = "恐惧",
        FINALFIGHT = "背水一战(一次性)",
        RECOVER = "恢复"
    }
else
    modimport("language/en.lua")
    GLOBAL.SPIDERLEADER.SKILLNAME = {
        DEFENCE = "Defence",
        ATTACK = "Attack",
        SCARE = "Scare",
        FINALFIGHT = "Fight to Death(single-use)",
        RECOVER = "Recover"
    }
end
AddRecipe2(
    "mutator_spider_leader",
    {
        Ingredient("monstermeat", 5),
        Ingredient("silk", 3),
        Ingredient("spiderhat", 1),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/mutator_spider_leader.xml",
        image = "mutator_spider_leader.tex",
        builder_tag = "spiderwhisperer",
    },
    {"CHARACTER"}
)
AddRecipe2(
    "spider_leader_whistle0",
    {
        Ingredient("spider_whistle", 1),
        Ingredient("livinglog", 1),
        Ingredient("nightmarefuel", 2),
    },
    TECH.MAGIC_TWO,
    {
        atlas = "images/inventoryimages/spider_leader_whistle0.xml",
        image = "spider_leader_whistle0.tex",
        builder_tag = "spiderwhisperer",
    },
    {"CHARACTER", "MAGIC" }
)
AddRecipe2(
    "spider_leader_whistle",
    {
        Ingredient("spider_leader_whistle0", 1, 'images/inventoryimages/spider_leader_whistle0.xml'),
        Ingredient("hivehat", 1),
    },
    TECH.MAGIC_THREE,
    {
        atlas = "images/inventoryimages/spider_leader_whistle.xml",
        image = "spider_leader_whistle.tex",
        builder_tag = "spiderwhisperer",
    },
    {"CHARACTER", "MAGIC" }
)


local spider_prefabs = {
    "spider",
    "spider_warrior",
    "spider_hider",
    "spider_spitter",
    "spider_dropper",
    "spider_moon",
    "spider_healer",
    "spider_water"
}

for _, prefab in ipairs(spider_prefabs) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end
            inst:AddComponent("subfollower")
    end)
end

local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "spiderwhisperer", "spiderdisguise", "INLIMBO" }

local function HasFriendlyLeader(inst, target)
    local leader = inst.components.follower.leader
    local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil

    if leader ~= nil and target_leader ~= nil then

        if target_leader.components.inventoryitem then
            target_leader = target_leader.components.inventoryitem:GetGrandOwner()
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


AddPrefabPostInit("spider", function (inst)
    if not TheWorld.ismastersim then
        return
    end

    local old_FindTarget = inst.FindTarget
    function inst:FindTarget(inst, radius)
        if not inst.no_targeting then
        return FindEntity(
            inst,
            SpringCombatMod(radius),
            function(guy)
                return (not inst.bedazzled and (not guy:HasTag("monster") or guy:HasTag("player")))
                    and inst.components.combat:CanTarget(guy)
                    and not (inst.components.follower ~= nil and inst.components.follower.leader == guy)
                    and not HasFriendlyLeader(inst, guy)
                    and not (inst.components.subfollower.leader ~= nil)
                    and not (inst.components.follower.leader ~= nil and inst.components.follower.leader:HasTag("player")
                        and guy:HasTag("player") and not TheNet:GetPVPEnabled())
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )
    end
    end
end)

if spider_whistle_useamount then
    AddPrefabPostInit("spider_whistle", function (inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst.components.followerherder:SetUseAmount(0)
    end)
end

local followmin = 3
local followtag = 5
local followmax = 7

local function GetSubFaceTargetFn(inst)
    return inst.components.subfollower.subleader
end

local function KeepSubFaceTargetFn(inst, target)
    return inst.components.subfollower.subleader == target
end

if followdistance == 1 then
    followmin = 2 ;followtag = 4 ;followmax = 5
end
if followdistance == 2 then
    followmin = 3 ;followtag = 5 ;followmax = 7
end
if followdistance == 3 then
    followmin = 3 ;followtag = 6 ;followmax = 9
end

AddBrainPostInit("spiderbrain", function(self)
    local SubfollowNode = 
        GLOBAL.IfNode(function() return self.inst.defensive
            and self.inst.components.subfollower
            and self.inst.components.subfollower.subleader ~= nil end, 
            "DefensiveFollowLeader",
           GLOBAL.Follow(self.inst, function() return self.inst.components.subfollower.subleader end,followmin,followtag,followmax)
        )
    local olddefensive_follow = 
        GLOBAL.IfNode(function () return self.inst.defensive
        and self.inst.components.subfollower.subleader == nil end,
        "oldDefensiveFllow",
        GLOBAL.Follow(self.inst, function ()return self.inst.components.follower.leader end,
            TUNING.SPIDER_DEFENSIVE_MIN_FOLLOW, TUNING.SPIDER_DEFENSIVE_MED_FOLLOW, TUNING.SPIDER_DEFENSIVE_MAX_FOLLOW)
        )
    local noleaderbutfollow = 
        GLOBAL.IfNode(function () return self.inst.components.follower.leader == nil
        and self.inst.components.subfollower.subleader ~= nil end,
        "noleaderbutfollow",
        GLOBAL.Follow(self.inst, function ()return self.inst.components.subfollower.subleader end,
            TUNING.SPIDER_DEFENSIVE_MIN_FOLLOW, TUNING.SPIDER_DEFENSIVE_MED_FOLLOW, TUNING.SPIDER_DEFENSIVE_MAX_FOLLOW)
        )
    local aggressive_follow = 
        GLOBAL.IfNode(function () return not self.inst.defensive end
        ,"aggressive_follow",
        GLOBAL.Follow(self.inst, function() return self.inst.components.follower.leader end, 
                TUNING.SPIDER_AGGRESSIVE_MIN_FOLLOW, TUNING.SPIDER_AGGRESSIVE_MED_FOLLOW, TUNING.SPIDER_AGGRESSIVE_MAX_FOLLOW)
        )
    local facesubleader = 
        GLOBAL.IfNode(function () return self.inst.components.follower.leader == nil and self.inst.components.subfollower.subleader ~= nil end
        ,"HasSubLeader",
        GLOBAL.FaceEntity(self.inst, GetSubFaceTargetFn, KeepSubFaceTargetFn )
        )
    --SPIDER_DEFENSIVE_MIN_FOLLOW = 2; SPIDER_DEFENSIVE_MED_FOLLOW = 2; SPIDER_DEFENSIVE_MAX_FOLLOW = 4; 
    --SPIDER_AGGRESSIVE_MIN_FOLLOW = 2;SPIDER_AGGRESSIVE_MED_FOLLOW = 3; SPIDER_AGGRESSIVE_MAX_FOLLOW = 8
    if self.bt.root.children and self.bt.root.children[4] 
        and self.bt.root.children[4].children 
        and self.bt.root.children[4].children[1] then
        table.remove(self.bt.root.children[4].children,1)
        table.insert(self.bt.root.children[4].children,1,olddefensive_follow)
        table.insert(self.bt.root.children[4].children,1,SubfollowNode)
        table.insert(self.bt.root.children[4].children,3,noleaderbutfollow)
        table.insert(self.bt.root.children[4].children,6,facesubleader)
        if spider_diet then
            table.remove(self.bt.root.children[4].children,4)
            table.insert(self.bt.root.children[4].children,4,aggressive_follow)
        end
        else
    end
end)

AddComponentPostInit("spidermutator", function(SpiderMutator)
    local oldMutate = SpiderMutator.Mutate
    function SpiderMutator:Mutate(spider, skip_event, giver)
        if self.mutation_target == "spider_leader" then
            if spider.components.inventoryitem and spider.components.inventoryitem.owner ~= nil then

                local owner = spider.components.inventoryitem.owner
                local spider_flag = SpawnPrefab("spider_flag")
                local new_spider = SpawnPrefab(self.mutation_target)
                local component_name = owner.components.inventory ~= nil and "inventory" or "container"
                -- local slot = owner.components[component_name]:GetItemSlot(spider)
                local x,y,z = owner.Transform:GetWorldPosition()
                new_spider.Transform:SetPosition(x,y,z)
            
                owner.components[component_name]:RemoveItem(spider)
                spider:Remove()

                spider_flag.Transform:SetPosition(owner.Transform:GetWorldPosition())
                new_spider.components.follower:SetLeader(giver)
                new_spider.components.subfollower:SetSubLeader(spider_flag)
            else	
                spider.mutation_target = self.mutation_target
                spider.mutator_giver = giver
                if not skip_event then
                    spider:PushEvent("mutate")
                end
            end


            if self.inst.components.stackable then
                self.inst.components.stackable:Get():Remove()
            else
                self.inst:Remove()
            end
        else
            oldMutate(self, spider, skip_event, giver)
        end
    end
end)

local leaderwhistle = GLOBAL.Action({mount_valid = true })
leaderwhistle.id = "LEADER_WHISTLE"
leaderwhistle.fn = function(act)
    if act.invobject then
		if act.doer.components.inventory then
			act.doer.components.inventory:ReturnActiveActionItem(act.invobject)
		end
		if act.invobject.components.inventoryitem and
			act.invobject.components.inventoryitem:GetGrandOwner() == act.doer and
			act.invobject.components.spellbook
		then
			return act.invobject.components.spellbook:CastSpell(act.doer)
		end
	elseif act.target == act.doer and act.target.components.spellbook then
		return act.target.components.spellbook:CastSpell(act.doer)
	end
end
AddAction(leaderwhistle)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.LEADER_WHISTLE, "herd_followers"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.LEADER_WHISTLE, "herd_followers"))