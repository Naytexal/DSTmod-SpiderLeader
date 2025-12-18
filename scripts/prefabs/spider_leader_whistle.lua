local GLOBAL = _G
local COOLDOWNTIME = GLOBAL.SPIDERLEADER.SKILLCOOLDOWN
local FRIGHTENCOOLDOWN = GLOBAL.SPIDERLEADER.FRIGHTENCOOLDOWN
local RECOVERCOOLDOWN = GLOBAL.SPIDERLEADER.RECOVERCOOLDOWN

local assets =
{
    Asset("ANIM", "anim/spider_leader_whistle.zip"),
    Asset("ATLAS", "images/spider_leader_whistle.xml"),
    Asset("IMAGE", "images/spider_leader_whistle.tex"),	

	Asset("ANIM", "anim/spell_icons_spider.zip"),
}

local prefabs = 
{
    "spider_whistle_buff",
    "spider_summoned_buff",
}


local SPIDER_IGNORE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }


local function GetSpiderLeaders(inst, radius)
	radius = radius or 18

	local owner = inst.components.inventoryitem:GetGrandOwner()
	local x, y, z = inst.Transform:GetWorldPosition()

    local spider_leaders = TheSim:FindEntities(x, y, z, radius, {"spiderleader"}, SPIDER_IGNORE_TAGS)

	local valid_spider_leaders = {}

    for _, spider_leader in ipairs(spider_leaders) do
        if spider_leader:IsValid() 
		and not spider_leader.components.health:IsDead() 
		and spider_leader.components.follower:GetLeader() == owner
		then
            table.insert(valid_spider_leaders, spider_leader)
        end
    end
	return valid_spider_leaders
end
local function SpellFrighten(inst, doer)
	if doer.components.spellbookcooldowns ~= nil 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand") 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand_1") then
        return false
	end
	local spider_leaders = GetSpiderLeaders(inst)
	if spider_leaders ~= nil then
		for _, spider_leader in ipairs(spider_leaders) do
			spider_leader:PushEvent("doFrighten")
		end
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand", COOLDOWNTIME)
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand_1", FRIGHTENCOOLDOWN)
		return true
	else
		return false
	end
end
local function SpellDefence(inst, doer)
	if doer.components.spellbookcooldowns ~= nil 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand") then
        return false
	end
	local spider_leaders = GetSpiderLeaders(inst)
	if spider_leaders ~= nil then
		for _, spider_leader in ipairs(spider_leaders) do
			spider_leader:PushEvent("doDefence")
		end
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand", COOLDOWNTIME)
		return true
	else
		return false
	end
end
local function SpellAttack(inst, doer)
	if doer.components.spellbookcooldowns ~= nil 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand") then
        return false
	end
	local spider_leaders = GetSpiderLeaders(inst)
	if spider_leaders ~= nil then
		for _, spider_leader in ipairs(spider_leaders) do
			spider_leader:PushEvent("doAttack")
		end
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand", COOLDOWNTIME)
		return true
	else
		return false
	end
end
local function SpellRecover(inst, doer)
	if doer.components.spellbookcooldowns ~= nil 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand") 
	and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand_2") then
        return false
	end
	local spider_leaders = GetSpiderLeaders(inst)
	if spider_leaders ~= nil then
		for _, spider_leader in ipairs(spider_leaders) do
			spider_leader:PushEvent("doRecover")
			break
		end
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand", COOLDOWNTIME)
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand_2", RECOVERCOOLDOWN)
		return true
	else
		return false
	end
end
local function SpellFinalCombat(inst, doer)
	-- if doer.components.spellbookcooldowns ~= nil 
	-- and doer.components.spellbookcooldowns:IsInCooldown("spiderleadercommand") then
    --     return false
	-- end
	local spider_leaders = GetSpiderLeaders(inst)
	if spider_leaders ~= nil then
		for _, spider_leader in ipairs(spider_leaders) do
			spider_leader:PushEvent("doFinalcombat")
			inst:Remove()
			break
		end
		doer.components.spellbookcooldowns:RestartSpellCooldown("spiderleadercommand", COOLDOWNTIME)
		return true
	else
		return false
	end
end

local BASECOMMANDS = {
	{
		label = GLOBAL.SPIDERLEADER.SKILLNAME.FINALFIGHT,
		onselect = function(inst)
            local spellbook = inst.components.spellbook
			spellbook:SetSpellName("COMMAND_FINAL_COMBAT")
			spellbook:SetSpellAction(ACTIONS.LEADER_WHISTLE)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(SpellFinalCombat)
			end
		end,
		execute = function(inst)
            if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_spider",
		build = "spell_icons_spider",
		anims =
		{
			idle = { anim = "finalfight" },
			focus = { anim = "finalfight_focus", loop = true },
			down = { anim = "finalfight_pressed" },
		},
		widget_scale = 0.6,
	},  --决战
	{
		label = GLOBAL.SPIDERLEADER.SKILLNAME.DEFENCE,
		onselect = function(inst)
			local spellbook = inst.components.spellbook
			spellbook:SetSpellName("COMMAND_DEFENCE")
			spellbook:SetSpellAction(ACTIONS.LEADER_WHISTLE)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(SpellDefence)
			end

		end,
		execute = function(inst)
			if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_spider",
		build = "spell_icons_spider",
		anims =
		{
			idle = { anim = "defence" },
			focus = { anim = "defence_focus", loop = true },
			down = { anim = "defence_pressed" },
			disabled = { anim = "defence_disabled" },
			cooldown = { anim = "defence_cooldown" },
		},
		widget_scale = 0.6,
		checkcooldown = function(doer)
			return (doer ~= nil
				and doer.components.spellbookcooldowns
				and doer.components.spellbookcooldowns:GetSpellCooldownPercent("spiderleadercommand"))
				or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	},  --防守
    {
		label = GLOBAL.SPIDERLEADER.SKILLNAME.SCARE,
		onselect = function(inst)
            local spellbook = inst.components.spellbook
			spellbook:SetSpellName("COMMAND_FRIGHTEN")
			spellbook:SetSpellAction(ACTIONS.LEADER_WHISTLE)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(SpellFrighten)
			end
		end,
		execute = function(inst)
            if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_spider",
		build = "spell_icons_spider",
		anims =
		{
			idle = { anim = "frighten" },
			focus = { anim = "frighten_focus", loop = true },
			down = { anim = "frighten_pressed" },
			disabled = { anim = "frighten_disabled" },
			cooldown = { anim = "frighten_cooldown" },
		},
		widget_scale = 0.6,
		checkcooldown = function(doer)
			return (doer ~= nil
				and doer.components.spellbookcooldowns
				and doer.components.spellbookcooldowns:GetSpellCooldownPercent("spiderleadercommand_1"))
				or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	},  --战吼
	{
		label = GLOBAL.SPIDERLEADER.SKILLNAME.RECOVER,
		onselect = function(inst)
            local spellbook = inst.components.spellbook
			spellbook:SetSpellName("COMMAND_RECOVER")
			spellbook:SetSpellAction(ACTIONS.LEADER_WHISTLE)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(SpellRecover)
			end
		end,
		execute = function(inst)
            if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_spider",
		build = "spell_icons_spider",
		anims =
		{
			idle = { anim = "recover" },
			focus = { anim = "recover_focus", loop = true },
			down = { anim = "recover_pressed" },
			disabled = { anim = "recover_disabled" },
			cooldown = { anim = "recover_cooldown" },
		},
		widget_scale = 0.6,
		checkcooldown = function(doer)
			return (doer ~= nil
				and doer.components.spellbookcooldowns
				and doer.components.spellbookcooldowns:GetSpellCooldownPercent("spiderleadercommand")
				or doer.components.spellbookcooldowns:GetSpellCooldownPercent("spiderleadercommand_2"))
				or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	},  --恢复
    {
		label = GLOBAL.SPIDERLEADER.SKILLNAME.ATTACK,
		onselect = function(inst)
            local spellbook = inst.components.spellbook
			spellbook:SetSpellName("COMMAND_ATTACK")
			spellbook:SetSpellAction(ACTIONS.LEADER_WHISTLE)

			if TheWorld.ismastersim then
				inst.components.aoespell:SetSpellFn(nil)
                spellbook:SetSpellFn(SpellAttack)
			end
		end,
		execute = function(inst)
            if ThePlayer.replica.inventory then
				ThePlayer.replica.inventory:CastSpellBookFromInv(inst)
			end
		end,
		bank = "spell_icons_spider",
		build = "spell_icons_spider",
		anims =
		{
			idle = { anim = "attack" },
			focus = { anim = "attack_focus", loop = true },
			down = { anim = "attack_pressed" },
			disabled = { anim = "attack_disabled" },
			cooldown = { anim = "attack_cooldown" },
		},
		widget_scale = 0.6,
		checkcooldown = function(doer)
			return (doer ~= nil
				and doer.components.spellbookcooldowns
				and doer.components.spellbookcooldowns:GetSpellCooldownPercent("spiderleadercommand"))
				or nil
		end,
		cooldowncolor = { 0.65, 0.65, 0.65, 0.75 },
	},  --进攻
}

local function CanHerd(leader)
    if not leader:HasTag("spiderwhisperer") then
        return false, "WEBBERONLY"
    end
    return true
end

local function CLIENT_OnOpenSpellBook(_)
end

local function CLIENT_OnCloseSpellBook(_)
end

local function OnHerd(whistle, leader)
	local x, y, z = leader.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.SPIDER_WHISTLE_RANGE, nil, nil, {"spidercocoon", "spiderden"})

    for _, den in pairs(ents) do
        if den.components.childspawner and den.components.childspawner.childreninside > 0 and den.SummonChildren then
            den:SummonChildren()
        end
    end

    ents = TheSim:FindEntities(x, y, z, TUNING.SPIDER_WHISTLE_RANGE, {"spider"}, {"spiderqueen"})
    for _, spider in pairs(ents) do
        if spider.components.sleeper and spider.components.sleeper:IsAsleep() then
            spider.components.sleeper:WakeUp()
            spider:AddDebuff("spider_summoned_buff", "spider_summoned_buff")
        end
    end

    for follower, v in pairs(leader.components.leader.followers) do
        if follower:HasTag("spider") then
            follower:AddDebuff("spider_whistle_buff", "spider_whistle_buff")
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("spider_leader_whistle")
    inst.AnimState:SetBuild("spider_leader_whistle")
    inst.AnimState:PlayAnimation("idle", true)
    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst:AddTag("spider_leader_whistle")

    local spellbook = inst:AddComponent("spellbook")
    spellbook:SetRequiredTag("spiderwhisperer")
    spellbook:SetRadius(100) --100
    spellbook:SetFocusRadius(100)

    spellbook:SetOnOpenFn(CLIENT_OnOpenSpellBook)
    spellbook:SetOnCloseFn(CLIENT_OnCloseSpellBook)

    inst:AddComponent("aoespell")

	inst.entity:SetPristine()

    inst:AddComponent("followerherder")
    inst.components.followerherder:SetCanHerdFn(CanHerd)
    inst.components.followerherder:SetOnHerdFn(OnHerd)

    inst.components.spellbook:SetItems(BASECOMMANDS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "spider_leader_whistle"
    inst.components.inventoryitem.atlasname = "images/spider_leader_whistle.xml"
    inst:AddComponent("inspectable")


    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)

    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("spider_leader_whistle", fn, assets)