local Rememberspiders = Class(function(self, inst)
    self.inst = inst

    self.myspiders = {}
    self.spidernum = 0
    self.singlespider = nil
end)

function Rememberspiders:AddSpider(spider)
    self.myspiders[spider] = true
    self.spidernum = self.spidernum + 1
end
function Rememberspiders:Removespider(spider)
    if spider ~= nil and self.myspiders[spider] then
        self.myspiders[spider] = nil
        self.spidernum = self.spidernum - 1
    end
end
function Rememberspiders:GetSpiders()
    local spiders = {}
    for k, value in pairs(self.myspiders) do
        table.insert(spiders, k)
    end
    return spiders
end
function Rememberspiders:SetSingleSpider(spider)
    self.singlespider = spider
end
function Rememberspiders:RemoveSingleSpider()
    self.singlespider = nil
end
function Rememberspiders:GetSingleSpider()
    return self.singlespider
end

function Rememberspiders:Countspiders()
    return self.spidernum
end

function Rememberspiders:OnRemoveFromEntity()
    self.myspiders = nil
    self.spidernum = nil
    self.spider = nil
end

return Rememberspiders