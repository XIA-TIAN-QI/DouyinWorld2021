---@var InteractionType :InteractionType
---@var InteractionRange :float = 1.5
---@var InteractionArea :UnityEngine.Collider
---@var InteractionMode :Interaction3DType
---@var ButtonConfigs :DouyinButton[]
---@end

local interactorButtons = nil

function Awake()
    local allTrigger = self.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, allTrigger.Length - 1 do
        if allTrigger[i].isTrigger == true then
            if allTrigger[i] ~= InteractionArea then
                UnityEngine.Object.Destroy(allTrigger[i])
            end
        end
    end
    if InteractionArea == nil then
        InteractionType = CS.InteractionType.Range
    end
    if InteractionRange <= 0 then
        InteractionRange = 1.5
    end
    if InteractionType == CS.InteractionType.Range then
        if InteractionArea == nil then
            InteractionArea = self.gameObject:AddComponent(typeof(CS.UnityEngine.SphereCollider))
            InteractionArea.center = CS.UnityEngine.Vector3.zero
            local scale = self.gameObject.transform.localScale
            local maxScale = math.max(scale.x, scale.y, scale.z)
            if maxScale > 0 then
                InteractionArea.radius = InteractionRange / maxScale
            else
                InteractionArea.radius = InteractionRange
            end
        end
    end
    if InteractionArea ~= nil then
        InteractionArea.isTrigger = true
    end

    for _, buttonConfig in ipairs(ButtonConfigs) do
        SetDefaultIcon(buttonConfig, CS.IconType.Interactive)
        buttonConfig.ButtonText = true
    end
end

function SetDefaultIcon(btn, IconType)
    if btn == nil then
        return
    end

    local defaultIcon = CS.DouyinUIService.GetDefaultIcon(IconType)
    local defaultBackground = CS.DouyinUIService.GetDefaultIcon(CS.IconType.Background)
    local spriteState = btn.SpriteState

    if spriteState.normalImage == nil then
        spriteState.normalImage = defaultIcon
    end

    if spriteState.normalBackgroundImage == nil then
        spriteState.normalBackgroundImage = defaultBackground
    end

    btn.SpriteState = spriteState
end

function ApplyButtonConfig(btn, btnConfig)
    if btn == nil or btnConfig == nil then
        return
    end

    btn.transition = CS.UnityEngine.UI.Selectable.Transition.SpriteSwap
    btn.image.sprite = btnConfig.SpriteState.normalImage
    local spriteState = btn.spriteState
    spriteState.highlightedSprite = btnConfig.SpriteState.normalImage
    spriteState.pressedSprite = btnConfig.SpriteState.normalImage
    spriteState.selectedSprite = btnConfig.SpriteState.normalImage
    btn.spriteState = spriteState

    local backgroundTrnas = btn.transform:Find("Background")
    if backgroundTrnas ~= nil then
        local backgroundImage = backgroundTrnas:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if backgroundImage ~= nil then
            local backgroundSprite
            if btnConfig.SpriteState.normalBackgroundImage then
                    backgroundSprite = btnConfig.SpriteState.normalBackgroundImage
                end
            if backgroundSprite then
                backgroundImage.sprite = backgroundSprite
            end
        end
    end

    local txt = btn:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text), true)
    if txt ~= nil then
        if btnConfig.ButtonText == true then
            txt.gameObject:SetActive(true)
            txt.text = btnConfig.Text
            txt.color = btnConfig.TextColor
        else
            txt.gameObject:SetActive(false)
        end
    end
end

function EnableInteraction()
    if self.enabled == false then
        print("DouyinInteractiveObject is disabled")
        return
    end
    self:EnableInteraction()
end

function DisableInteraction()
    self:DisableInteraction()
end

function OnPlayerTriggerEnter(douyinPlayer)
    if douyinPlayer == nil then
        return
    end
    local actor = douyinPlayer:GetActor()
    if actor == nil then
        return
    end
    if actor.isBindMode == false then
        return
    end
    EnableInteraction()
end

function OnPlayerTriggerExit(douyinPlayer)
    if douyinPlayer == nil then
        return
    end
    local actor = douyinPlayer:GetActor()
    if actor == nil then
        return
    end
    if actor.isBindMode == false then
        return
    end
    DisableInteraction()
end

function OnPlayerLeft(actor)
    if actor == nil or actor.isLocal == false then
        return
    end
    DisableInteraction()
end

function OnDisable()
    DisableInteraction()
end

function OnFocus()
    interactorButtons = {}
    for i, buttonConfig in ipairs(ButtonConfigs) do
        local interactorButton = self:AddInteractorButton()
        ApplyButtonConfig(interactorButton, buttonConfig)
        interactorButtons[i] = interactorButton
    end
end

function OnLostFocus()
    self:RemoveAllInteractorButtons()
    interactorButtons = nil
end

function OnInteractorButtonClick(index)
    CallMonoMethods(index)
end

function CallMonoMethods(index)
    local localActor = CS.DouyinActorService.GetLocalActor()
    if localActor ~= nil then
        localActor:Interact(self.gameObject)
    end

    if ButtonConfigs == nil then
        return
    end

    if index > #ButtonConfigs then
        return
    end

    local ButtonActions = ButtonConfigs[index].ButtonActions
    if ButtonActions.Length > 0 then
        for i = 0, ButtonActions.Length - 1 do
            local item = ButtonActions[i]
            if item.Data then
                local pfn = item.Data.script[item.methodName]
                if pfn then
                    pfn()
                end
            end
        end
    end
end

function GetInteractorButton(index)
    if index == nil then
        index = 1
    end
    if interactorButtons == nil or type(index) ~= "number" or index < 1 or index > #interactorButtons then
        return nil
    end
    return interactorButtons[index]
end