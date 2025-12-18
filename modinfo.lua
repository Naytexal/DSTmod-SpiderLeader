name = "蜘蛛领袖/Spider Leader"

description = [[
    ver 1.1.0_pre-release 预发布版本

    为韦伯添加了一种新的蜘蛛，它可以帮你管理蜘蛛群!

    检查你的角色专属制作栏来了解模组内容！

    笛子会伴随领袖蜘蛛生成，对领袖蜘蛛使用可以让你的蜘蛛跟随它。
    被托管的蜘蛛不会主动传送到玩家附近。
    被托管的蜘蛛在韦伯掉线时也不会主动攻击其它玩家。
    支持多个领袖蜘蛛同时存在，这意味着你可以给蜘蛛群分群。
    吹哨可以让蜘蛛重新跟随领袖蜘蛛。

    为领袖蜘蛛添加了技能，你可以用命令口哨来使用这些技能，请检查你的魔法制作栏！
    合理的规划你的技能，让你的蜘蛛群在面对高压环境下时仍然能有一战之力！

    Bring a new spider for Webber that can help you manage your spiders!

    Check your character crafting tab to learn about the mod content!

    Whistle spawned with Spider_Leader, use which on Spider Leader let him manage your spiders.
    Spiders managed will not try teleport proactively.
    Spiders managed will not attack other players when Webber disconnected.
    Mod supports multiple Spider_Leaders, you can split your spiders into groups.
    Use Webby Whistle to make spiders follow Spider_Leader again.

    Add skills for Webber. You can use skills by Command Whistle. Check your magic crafting menu!
    Use your skills appropriately. 
]]

author = "Neathyxal & LaoBai"

version = "1.1.0 pre-release"

api_version = 10

dont_starve_compatible = true
reign_of_giants_compatible = true
dst_compatible = true

icon_atlas = "spider_leader.xml"
icon = "spider_leader.tex"

all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {"spider_leader","convenience","webber"}

forumthread = ""


local function setTitle(str)
    return {
        label = str,
        name = "",
        hover = "",
        options = {{
            description = "",
            data = false
        }},
        default = false
    }
end

local function setConfig(name, title, options, default, desc)
    local _options = {}
    for i=1,#options  do
        _options[i] = {
            description = options[i][1],
            data = options[i][2],
            hover = options[i][3]
        }
    end
    options = _options

    return {
        name = name,
        label = title,
        hover = desc or "",
        options = options,
        default = default
    }
end
local Num = {{"1",1},{"2",2},{"3",3},{"4",4},{"5",5},{"6",6},{"7",7},{"8",8},{"9",9},{"10",10},{"11",11},{"12",12},{"13",12},{"14",14},{"15",15},{"16",16}}
local Percent = {{"0%",0},{"10%",0.1},{"20%",0.2},{"30%",0.3},{"40%",0.4},{"50%",0.5},{"60%",0.6},{"70%",0.7},{"80%",0.8},{"90%",0.9},{"100%",1}}

configuration_options =
{
    setTitle("语言(language)"),
    setConfig(
        "language_setting",
        "语言language",
        {{"中文", "ch"},{"English", "en"}},
        "ch"
    ),
    setTitle("游戏体验优化/Game Experience Optimization"),
    setConfig(
        "spider_whistle_useamount",
        "韦伯口哨使用次数",
        {{"无限使用/unlimited", true}, {"不改变/vanilla", false}},
        false,
        "韦伯口哨不消耗使用次数/Weber's whistle does not consume a use."
    ),
    setConfig(
        "spider_diet",
        "蜘蛛不吃地上的东西/spider_diet",
        {{"开启", true}, {"关闭", false}},
        false,
        "注意也会使原版蜘蛛兵营失效/Note that this will also invalidate the vanilla spider barracks."
    ),
    setTitle("技能设置/Skills Options"),
    setConfig(
        "defencebuffradius",
        "防御buff半径/Defence buff radius",
        Num,
        11,
        "设置防御技能的有效半径/Radius of Defence skill"
    ),
    setConfig(
        "defencebuffabsorption",
        "防御buff强度/Defense buff strength",
        Percent,
        0.3,
        "设置防御技能减伤水平/Damage absorption of Defence buff"
    ),
    setConfig(
        "defencebuffduration",
        "防御buff持续时间/Defence buff duration",
        Num,
        5,
        "设置持续时间/Duration of Defence buff"
    ),

    setConfig(
        "defencebuffdecay",
        "防御buff衰减系数/Defence buff decay",
        Percent,
        0.2,
        "设置衰减系数/Defence buff decay"
    ),

    setConfig(
        "attackbuffradius",
        "攻击buff半径/Attack buff radius",
        Num,
        11,
        "设置攻击技能的有效半径/Radius of Attack skill"
    ),
    setConfig(
        "attackbuffatkdmgmul",
        "攻击buff效果强度1/Defense buff strength 1",
        Percent,-- 1+...
        0.5,
        "增伤/Damage Increase"
    ),
    setConfig(
        "attackbuffatkpidmul",
        "攻击buff效果强度2/Defense buff strength 2",
        Percent,
        0.5,
        "减少攻击间隔/Reduce Attack Interval"
    ),
    setConfig(
        "attackbuffduration",
        "攻击buff持续时间/Defence buff duration",
        Num,
        5,
        "设置持续时间/Duration of Attack buff"
    ),

    setConfig(
        "frightenradius",
        "恐惧buff半径/Scare buff radius",
        Num,
        12,
        "恐惧作用半径/Radius of Scare buff"
    ),

    setConfig(
        "recoverradius",
        "治疗半径/Scare buff radius",
        Num,
        10,
        "治疗作用半径/Radius of Recover"
    ),
    
    setTitle("属性/Property"),
    setConfig(
        "spiderleaderhealth",
        "蜘蛛领袖的生命值/Health value of spider leader",
        {{"100",100},{"500",500},{"700",700},{"1000",1000},{"1200",1200},{"1800",1800},{"2000",2000},{"3000",3000}},
        1200,
        "设置蜘蛛领袖的生命值/Set spider leader health value"
    ),
    setConfig(
        "skillcooldown",
        "技能冷却时间/skillcooldown",
        {{"1",1},{"1.5",1.5},{"2",2},{"2.5",2.5},{"3",3},{"3.5",3.5},{"4",4},{"4.5",4.5},{"5",5},{"5.5",5.5},{"6",6},{"6.5",6.5},{"7",7},{"7.5",7.5},{"8",8},{"8.5",8.5},{"9",9},{"9.5",9.5},{"10",10}},
        6.5,
        "技能冷却时间/Set skill cool down time"
    ),
    setConfig(
        "recovercooldown",
        "治疗冷却时间/recovercooldown",
        Num,
        12,
        "治疗冷却时间/Set skill cool down time of Recover"
    ),
    setTitle("蜘蛛跟随/Spider Follow Behavious"),
    setConfig(
        "followdistance",
        "蜘蛛跟随距离/Spider follow distance",
        {{"近close（更灵活）",1},{"中mid",2},{"远far（适合大规模）",3}},
        2,
        "调节蜘蛛跟随领袖的距离，根据你蜘蛛群的规模改变这个值！/Adjust the distance at which spiders follow the leader, and change this value according to the size of your spider swarm!"
    )
}