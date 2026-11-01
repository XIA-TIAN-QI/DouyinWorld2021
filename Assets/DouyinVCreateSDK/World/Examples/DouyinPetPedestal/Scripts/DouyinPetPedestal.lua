---@var PetId :string
---@var CoverMesh :UnityEngine.MeshRenderer
---@var ModelPos :UnityEngine.Transform
---@end
local isInit = false
local isOwn = true
local isOnlyUseInWorld = true
local interacterScript;
local IsValid = true
local isSelf = false

--[[
    TryOn,TryChange：!!!! 内部接口（Internal API）
    该方法依赖组件内部逻辑，仅在本组件内调用是安全的。
    该接口不支持在其他位置调用，可能会引发状态异常或未知问题。
]]

function Awake()
    local interacter = self:GetDouyinScript("DouyinPetPedestalInteractor")
    if interacter ~= nil then
        interacter.script.SetInteractorButtonValid(SetInteractIsValid)
        interacter.script.SetOnFocusCallBack(OnEnterFocus)
    end
    interacterScript = interacter
end

function Start()

end


function TryUse()
    local localActor = CS.DouyinActorService.GetLocalActor()
    if localActor ~= nil then
        localActor:TryChange(PetId, function(code)

        end)
    end
end

function TryOn()
    local localActor = CS.DouyinActorService.GetLocalActor()
    if localActor ~= nil then
        localActor:TryOn(PetId, function(code)

        end)
    else
        error("PetPedestal    TryOn localActor is nil")
    end
end

function OnEnterFocus()
    print("DouyinInteractiveObject    OnFocus")
    CS.DouyinUtility.RefreshPetPedestalStatus(PetId, function(isHave, _isSelf)
        isOwn = isHave
        isSelf = _isSelf
        interacterScript.script._OnFocus()
    end)
end

function SetInteractIsValid(index)
    print("PetPedestal    SetInteractIsValid", index, IsValid, isOwn, isOnlyUseInWorld)
    if not IsValid then
        return  false
    end

    if index == 1 then   -- 是否显示使用按钮
        return  isOwn
    end

    if index == 2 then   -- 是否显示免费兑换
        return isOnlyUseInWorld and not isSelf
    end

    if index == 3 then   -- 是否显示兑换
        return not isOnlyUseInWorld and not isSelf
    end
    return false
end


function OnActorOperationChanged(actor)
    if actor == nil then
        return
    end
    if not isInit and  actor.isBindMode then
        CS.DouyinUtility.SetPetCover(PetId, CoverMesh, ModelPos, function(_IsValid, isOwner, isUseInWorld)
            print("---------------------", _IsValid, isOwner, isUseInWorld)
            IsValid = _IsValid
            isOwn = isOwner
            isOnlyUseInWorld = isUseInWorld
        end)
        isInit = true
    end
end

function OnActorSpawned(actor)
    if not isInit and  actor.isBindMode then
        CS.DouyinUtility.SetPetCover(PetId, CoverMesh, ModelPos, function(_IsValid, isOwner, isUseInWorld)
            print("---------------------", _IsValid, isOwner, isUseInWorld)
            IsValid = _IsValid
            isOwn = isOwner
            isOnlyUseInWorld = isUseInWorld
        end)
        isInit = true
    end
end

