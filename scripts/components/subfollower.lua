local SubFollower = Class(function(self, inst)
    self.inst = inst

    self.subleader = nil

    self.OnSubLeaderRemoved = function()
        self:SetSubLeader(nil)
    end
end)

function SubFollower:GetSubLeader()
    return self.subleader
end

function SubFollower:SetSubLeader(new_subleader)
	local prev_subleader = self.subleader
	local changed_subleader = prev_subleader ~= new_subleader

    if prev_subleader and changed_subleader then
        self.subleader = nil
        self.inst:RemoveEventCallback("onsubremove", self.OnSubLeaderRemoved, prev_subleader)
    end

    if new_subleader and self.subleader ~= new_subleader then
        self.subleader = new_subleader
        self.inst:ListenForEvent("onsubremove", self.OnSubLeaderRemoved, new_subleader)
    end
end

function SubFollower:OnSave()
    -- if self.inst:HasTag("player") then
    --     return
    -- end

    -- local subleader = {}

    -- for k in pairs(self.subleader) do
    --     table.insert(subleader, k.GUID)
    -- end

    -- if #subleader > 0 then
    --     return { followers = subleader }, subleader
    -- end
end

function SubFollower:LoadPostPass(newents, savedata)
    -- if savedata ~= nil and savedata.subleader ~= nil then
    --     for k,v in pairs(savedata.subleader) do
    --         local targ = newents[v]
    --         if targ ~= nil and targ.entity.components.subfollower ~= nil then
    --             self:SetSubLeader(targ.entity)
    --         end
    --     end
    -- end
end
function SubFollower:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    if self.cached_player_leader_task then
        self.cached_player_leader_task:Cancel()
        self.cached_player_leader_task = nil
    end
    if self.leader ~= nil then
        self.inst:RemoveEventCallback("onsubremove", self.OnSubLeaderRemoved, self.leader)
    end
end

return SubFollower