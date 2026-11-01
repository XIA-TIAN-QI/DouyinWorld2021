---@var avatarIcon: UnityEngine.Renderer
---@var name:UnityEngine.UI.Text
---@var fansNum:UnityEngine.UI.Text
---@var buttonIcon : UnityEngine.Sprite
---@var successTip: UnityEngine.RectTransform
---@end

local creatorInfo = nil
local followButton = nil
local timer_temp = nil

-- Start is called before the first frame update
function Start()
    DouyinCreatorService.GetCreatorInfo(RefreshCreatorInfo)
end

-- 刷新创作者信息
function RefreshCreatorInfo(info) 
    if info == nil then
        return
    end
    print("DouyinFollowPlane.RefreshCreatorInfo info.secUID = " .. info.secUID)
    creatorInfo = info
    name.text = creatorInfo.name
    RefreshNumberOfFans()
    DouyinImageService.DownloadImage(creatorInfo.portrait, function(texture2D) 
        if texture2D ~= nil and avatarIcon ~= nil then
            local material = UnityEngine.Material(avatarIcon.material)
            material.mainTexture = texture2D
            material:SetTexture("_BaseTex", texture2D)
            avatarIcon.material = material
        end
    end)
end

function RefreshNumberOfFans()
    fansNum.text = creatorInfo.fans
end

-- 关注创作者
function Follow() 
    if DouyinApplication.isSimulator then
        print("DouyinFollowPlane.Follow isSimulator ")
        DouyinUtility.Toast("抖音虚拟调试器暂不支持测试关注功能")
        return
    end
    if creatorInfo == nil then 
        return
    end
    print("DouyinFollowPlane.Follow creatorInfo.secUID = " .. creatorInfo.secUID)
    DouyinCreatorService.Follow(creatorInfo.secUID, function(ret)
        print("DouyinFollowPlane.Follow ret = " .. tostring(ret))
        if ret then
            creatorInfo.isFollowing = true
            ShowTips()
            RefreshNumberOfFans()

            -- 移除关注按钮
            if followButton ~= nil then
                self:RemoveInteractorButton(followButton)
                followButton = nil
            end
        end
    end)
end

-- 打开创造者信息面板
function OpenCreatorInformation()
    if DouyinApplication.isSimulator then
        DouyinUtility.Toast("抖音虚拟调试器暂不支持测试关注功能")
        return
    end
    if creatorInfo == nil then 
        return
    end
    print("DouyinFollowPlane.OpenCreatorInformation creatorInfo.secUID = " .. creatorInfo.secUID)
    DouyinCreatorService.OpenCreatorInformation(creatorInfo.secUID)
end


function OnFocus()
    if creatorInfo == nil then
        return
    end
    local isCreator = DouyinCreatorService.IsCreator(creatorInfo.secUID)
    print("DouyinFollowPlane.OnFocus creatorInfo.secUID = ", creatorInfo.secUID, tostring(creatorInfo.isFollowing), tostring(isCreator))
    if creatorInfo.isFollowing == false and isCreator == false then
        followButton = self:AddInteractorButton()
        ApplyButtonConfig(followButton, buttonIcon, "关注")
    end
end

function OnLostFocus()
    if creatorInfo == nil then
        return
    end
    print("DouyinFollowPlane.OnLostFocus creatorInfo.secUID = " .. creatorInfo.secUID)
    if followButton ~= nil then
        self:RemoveInteractorButton(followButton)
        followButton = nil
    end
end

function ApplyButtonConfig(btn, sprite, text)
    if btn == nil or sprite == nil then
        return
    end

    btn.transition = CS.UnityEngine.UI.Selectable.Transition.SpriteSwap
    btn.image.sprite = sprite
    local spriteState = btn.spriteState
    spriteState.highlightedSprite = sprite
    spriteState.pressedSprite = sprite
    spriteState.selectedSprite = sprite
    btn.spriteState = spriteState

    local txt = btn:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text), true)
    if txt ~= nil then
        txt.gameObject:SetActive(true)
        txt.text = text
    end
end

function OnInteractorButtonClick(index)
    print("DouyinFollowPlane.OnInteractorButtonClick index = " .. index)
    if index == 2 then
        Follow()
    end
end

function ShowTips()
    if timer_temp ~= nil then
        return
    end
    print("DouyinFollowPlane.ShowTips")
    successTip.gameObject:SetActive(true)
    timer_temp = setTimeout(function()
        print("DouyinFollowPlane.HideTips")
        successTip.gameObject:SetActive(false)
        clearTimeout(timer_temp)
        timer_temp = nil
    end, 3000)
end