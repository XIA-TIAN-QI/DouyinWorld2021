---@var InteractionType :InteractionType
---@var InteractionRange :float = 1.5
---@var InteractionArea :UnityEngine.Collider
---@var InteractionMode :Interaction3DType
---@var AdditiveButton :DouyinButton
---@end

local rightAssistInteractionButton = nil
local buttonPosition = CS.InteractiveButtonType.Additive

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
            InteractionArea.radius = InteractionRange
        end
    end
    if InteractionArea ~= nil then
        InteractionArea.isTrigger = true
    end

    rightAssistInteractionButton = CS.DouyinUIService.GetInteractionButton(CS.HandType.Right, CS.UIType.Assist)
    SetDefaultIcon(AdditiveButton,CS.IconType.Interactive)
    AdditiveButton.ButtonText = true
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

    btn.SpriteState = spriteState;
end

function SetInteractionButtonActive(active)
    rightAssistInteractionButton.interactable = active
end

function ShowInteractionButton(btn, descriptor)
    if btn == nil or descriptor == nil then
        return
    end
    btn.gameObject:SetActive(true)
    btn.transition = CS.UnityEngine.UI.Selectable.Transition.SpriteSwap
    btn.image.sprite = descriptor.SpriteState.normalImage
    local spriteState = btn.spriteState;
    spriteState.highlightedSprite = descriptor.SpriteState.normalImage
    spriteState.pressedSprite = descriptor.SpriteState.normalImage
    spriteState.selectedSprite = descriptor.SpriteState.normalImage
    btn.spriteState = spriteState;

    local backgroundTrnas = btn.transform:Find("Background")
    if backgroundTrnas ~= nil then
        local backgroundImage = backgroundTrnas:GetComponent(typeof(CS.UnityEngine.UI.Image))
        if backgroundImage ~= nil then
            local backgroundSprite;
            if descriptor.SpriteState.normalBackgroundImage then
                    backgroundSprite = descriptor.SpriteState.normalBackgroundImage                    
                end
            if backgroundSprite then
                backgroundImage.sprite = backgroundSprite;                
            end
        end
    end

    local txt = btn:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text), true)
    if txt ~= nil then   
        if descriptor.ButtonText == true then        
            txt.gameObject:SetActive(true)
            txt.text = descriptor.Text
            txt.color = descriptor.TextColor
        else
            txt.gameObject:SetActive(false)
        end
    end
end

function HideInteractionButton(btn)
    if btn == nil then
        return
    end
    btn.gameObject:SetActive(false)
end

function EnableInteraction()
    if self.enabled == false then
        print("DouyinInteractiveObject is disabled")
        return
    end
    self:EnableInteraction(buttonPosition)
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

function OnFocus(handType)
    if handType == CS.HandType.Left then
        return
    end
    ShowInteractionButton(rightAssistInteractionButton, AdditiveButton)
    AdditiveButton.onInteractable = function(interactable)
        rightAssistInteractionButton.interactable = interactable
    end
end

function OnLostFocus(handType)
    if handType == CS.HandType.Left then
        return
    end
    HideInteractionButton(rightAssistInteractionButton)
end

function OnUIPointerDown(uiType, handType)
    if InteractionMode ~= CS.Interaction3DType.Press then
        return
    end

    CallMonoMethods()
end

function OnUIPointerClick(uiType, handType)
    if InteractionMode ~= CS.Interaction3DType.Click then
        return
    end

    CallMonoMethods();
end

function OnUIPointerUp(uiType, handType)
    if InteractionMode ~= CS.Interaction3DType.ClickUp then
        return
    end

    CallMonoMethods();
end

function CallMonoMethods()
    local localActor = CS.DouyinActorService.GetLocalActor()
    if localActor ~= nil then
        localActor:Interact(self.gameObject)
    end

    local ButtonActions = AdditiveButton.ButtonActions;
    if ButtonActions.Length > 0 then  
        for i = 0, ButtonActions.Length - 1 do
            local item = ButtonActions[i];
            if item.Data then
                local pfn = item.Data.script[item.methodName];
                if pfn then
                    pfn();
                end
            end
        end    
    end
end