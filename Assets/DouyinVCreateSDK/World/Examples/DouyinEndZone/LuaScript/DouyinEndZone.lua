---@require(DouyinObjectSync)
---@var particleRoot: UnityEngine.GameObject
---@varSync passedUserSet: Dictionary<string,bool>
---@end

if _G.DOUYIN_END_ZONE_FINISHED_PLAYERS == nil then
    _G.DOUYIN_END_ZONE_FINISHED_PLAYERS = {}
end
local finishedPlayers = _G.DOUYIN_END_ZONE_FINISHED_PLAYERS


function Start()
    -- 将passedUserSet引用添加到DOUYIN_END_ZONE_FINISHED_PLAYERS数组中
    table.insert(_G.DOUYIN_END_ZONE_FINISHED_PLAYERS, passedUserSet)
    
    if particleRoot == nil then
        return
    end
    InitParticle()
end

function OnDestroy()
    for i, userSet in ipairs(_G.DOUYIN_END_ZONE_FINISHED_PLAYERS) do
        if userSet == passedUserSet then
            table.remove(_G.DOUYIN_END_ZONE_FINISHED_PLAYERS, i)
            break
        end
    end
end

function OnPlayerTriggerEnter(douyinPlayer)
    if douyinPlayer == nil then
        return
    end
   
    local actor = douyinPlayer:GetActor()
    if actor == nil then
        return
    end
    if actor.isLocal ~= true then
        return
    end

    local playerFound = false
    for _, userSet in ipairs(_G.DOUYIN_END_ZONE_FINISHED_PLAYERS) do
        if userSet:ContainsKey(douyinPlayer.playerOpenID) and userSet:GetValue(douyinPlayer.playerOpenID) then
            playerFound = true
            break
        end
    end
    
    if playerFound then
        return
    end
    
    OnUserPass(douyinPlayer.playerOpenID)
    
    PlayParticle()
    if DouyinApplication.isSimulator then
        print("DouyinEndZone.OnPlayerTriggerEnter isSimulator ")
        DouyinUtility.Toast("抖音虚拟调试器暂不支持通关组件完成任务")
        return
    end
    CS.DouyinTaskService.SendEvent(CS.DouyinTaskEvent.Terminal)
    DouyinUtility.Toast("恭喜你，通关啦！")
end

function InitParticle()
    if particleRoot == nil then
        return
    end
    local pss = particleRoot:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem))
    if pss == nil then
        return
    end
    for i=0,pss.Length-1 do
        local ps = pss[i]
        local main = ps.main
        main.loop = false
        ps:Pause()
        ps:Clear()
    end
end

function PlayParticle()
    if particleRoot == nil then
        return
    end
    local pss = particleRoot:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem))
    if pss == nil then
        return
    end
    for i=0,pss.Length-1 do
        local ps = pss[i]
        if ps.isPlaying then
            ps:Pause()
            ps:Clear()
        end
        ps:Play()
    end
end

function StopParticle()
    if particleRoot == nil then
        return
    end
    local pss = particleRoot:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem))
    if pss == nil then
        return
    end
    for i=0,pss.Length-1 do
        local ps = pss[i]
        ps:Pause()
        ps:Clear()
    end
end


function OnUserPass(userOpenId)
    if self:HasOwnership() then
        print("passedUserSet SetValue: ", userOpenId)
        passedUserSet:SetValue(userOpenId, true)
    else
        print("SendMessageToOwner: OnUserPass, userOpenId = ", userOpenId)
        self:SendMessageToOwner("OnUserPass", userOpenId)
    end
end


