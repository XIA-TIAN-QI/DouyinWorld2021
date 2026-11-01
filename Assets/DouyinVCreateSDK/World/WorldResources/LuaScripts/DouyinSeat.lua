---@var InteractionType :InteractionType
---@var InteractionRange :number = 1.5
---@var InteractionArea :UnityEngine.Collider
---@var DownButton:     DouyinButton
---@var PlayerEnterLocation :UnityEngine.Transform
---@var PlayerExitLocation :UnityEngine.Transform
---@var SwitchSeatFromSeat :boolean
---@var CustomSittingAnimation :UnityEngine.AnimationClip
---@var StandButton :DouyinButton
---@end

local currentPlayer = nil
local currentPlayerID = nil
local currentPlayerGo = nil
local currentPlayerScale = CS.UnityEngine.Vector3.one
local seatAlignmentVersion = 0
local JoyStickControlMain = nil
local flyButton = nil
local isEnterTrigger = false
local standUpInteractionButton = nil
local interactorButton = nil

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

    standUpInteractionButton = CS.DouyinUIService.GetInteractionButton(CS.UIType.StandUp)
    flyButton = CS.DouyinUIService.GetInteractionButton(CS.UIType.Fly)
    JoyStickControlMain = CS.DouyinUIService.GetJoyStickControl(CS.UIType.MoveJoyStick)

    SetDefaultIcon(DownButton, CS.IconType.Seat)
    DownButton.ButtonText = true

    local standUpImage = CS.DouyinUIService.GetDefaultIcon(CS.IconType.StandUp)
    StandButton.SpriteState =
    {
        normalImage = standUpImage,
    }
    self.autoUpdate = false
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

function OnUIDragMainMoveUI(position)
    local localPlayer = CS.DouyinActorService.GetLocalActor()
    if localPlayer ~= nil then
        if localPlayer.isMasterMode and localPlayer:IsSitting() and currentPlayer == localPlayer then
            localPlayer:StandUp(self.gameObject)
        end
    end
end

local function AlignCurrentPlayerToSeat()
    if currentPlayerGo == nil or currentPlayerID == nil then
        return
    end
    local actor = DouyinActorService.GetActorById(currentPlayerID)
    if actor == nil then
        return
    end

    local parent = self.transform
    if PlayerEnterLocation ~= nil then
        parent = PlayerEnterLocation
    end

    currentPlayerGo.transform.position = parent.position
    currentPlayerGo.transform.rotation = parent.rotation
    SetScale(currentPlayerGo.transform, currentPlayerScale, parent.lossyScale)

    local hipsPosition = actor:GetBonePosition(CS.UnityEngine.HumanBodyBones.Hips)
    local offset = hipsPosition - currentPlayerGo.transform.position
    currentPlayerGo.transform.position = currentPlayerGo.transform.position - offset
end

local function ScheduleSeatAlignment()
    seatAlignmentVersion = seatAlignmentVersion + 1
    local version = seatAlignmentVersion
    AlignCurrentPlayerToSeat()

    local delays = { 100, 300, 600 }
    for i = 1, #delays do
        setTimeout(function()
            if version == seatAlignmentVersion and currentPlayer ~= nil then
                AlignCurrentPlayerToSeat()
            end
        end, delays[i])
    end
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

function SetStandUpButton()
    if standUpInteractionButton == nil or StandButton == nil then
        return
    end
    if currentPlayer == nil or currentPlayer.isBindMode == false then
        return
    end
    standUpInteractionButton.transition = CS.UnityEngine.UI.Selectable.Transition.SpriteSwap
    standUpInteractionButton.image.sprite = StandButton.SpriteState.normalImage
    local spriteState = standUpInteractionButton.spriteState
    spriteState.highlightedSprite = StandButton.SpriteState.normalImage
    spriteState.pressedSprite = StandButton.SpriteState.normalImage
    spriteState.selectedSprite = StandButton.SpriteState.normalImage
    standUpInteractionButton.spriteState = spriteState
    standUpInteractionButton.onClick:AddListener(StandUp)
    ShowStandUpButton(true)
end

function StandUp()
    if currentPlayer ~= nil then
        currentPlayer:StandUp(self.gameObject)
    end
end

function EnableInteraction()
    if self.enabled == false then
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

    isEnterTrigger = true
    if currentPlayerGo == nil then
        EnableInteraction()
    end
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
    isEnterTrigger = false
    DisableInteraction()
end

function OnPlayerLeft(actor)
    if actor == nil or actor.isLocal == false then
        return
    end
    DisableInteraction()
end

function OnDisable()
    seatAlignmentVersion = seatAlignmentVersion + 1
    DisableInteraction()
    UnregisterUIDragEvent()
end

function OnFocus()
    local bindActor = CS.DouyinActorService.GetBindActor()
    if bindActor ~= nil then
        bindActor.onFlyStart:AddListener(HideAllSeatButtons)
        bindActor.onFlyStop:AddListener(ShowSitDownButton)
        if bindActor:IsSitting() == false and bindActor:IsFlying() == false then
            SetSitDownButtonEnable(true)
        end
    end
end

function OnLostFocus()    
    SetSitDownButtonEnable(false)
    local bindActor = CS.DouyinActorService.GetBindActor()
    if bindActor ~= nil then
        bindActor.onFlyStart:RemoveListener(HideAllSeatButtons)
        bindActor.onFlyStop:RemoveListener(ShowSitDownButton)
    end
end

function OnSeatEntered(actor)
    local parent = self.transform
    if PlayerEnterLocation ~= nil then
        parent = PlayerEnterLocation
    end

    currentPlayer = actor
    currentPlayerGo = actor.gameObject
    currentPlayerID = actor.actorID
    currentPlayerScale = currentPlayerGo.transform.lossyScale
    currentPlayerGo.transform:SetParent(parent)
    currentPlayerGo.transform.localPosition = CS.UnityEngine.Vector3.zero
    currentPlayerGo.transform.localRotation = CS.UnityEngine.Quaternion.identity
    SetScale(currentPlayerGo.transform, currentPlayerScale, parent.lossyScale)
    DisableInteraction()
    SetStandUpButton()
    if CustomSittingAnimation ~= nil then
        currentPlayer:PlayAnimation(CustomSittingAnimation)
    end
    ScheduleSeatAlignment()
    SetFlyButtonEnable(currentPlayer,false)

    RegisterUIDragEvent()
end

function OnSeatExited(actor)
    if currentPlayer == actor then
        local go = actor.gameObject
        go.transform:SetParent(nil)
        go.transform.localScale = currentPlayerScale
        if PlayerExitLocation ~= nil then
            actor.position = PlayerExitLocation.position
            actor.rotation = PlayerExitLocation.rotation
        end
        if CustomSittingAnimation ~= nil then
            actor:StopAnimation()
        end
        self.autoUpdate = false
        seatAlignmentVersion = seatAlignmentVersion + 1
        currentPlayer = nil
        currentPlayerGo = nil
        currentPlayerID = nil
    end
    if actor.isBindMode then
          HideAllSeatButtons()
    end
    SetFlyButtonEnable(actor,true)
    if isEnterTrigger then
        EnableInteraction()
    end

    UnregisterUIDragEvent()
end

function SetFlyButtonEnable(actor,state)
    if actor == nil then
        return
    end
    if actor.isBindMode then
        if state then
            actor:EnableFly();  -- state为true时，启用飞行
        else
            actor:DisableFly(true); -- state为false时，禁用飞行
        end
    end
end

function HideAllSeatButtons()
    SetSitDownButtonEnable(false)
    SetStandUpButtonEnable(false)
end

function ShowSitDownButton()
    SetSitDownButtonEnable(true)
    SetStandUpButtonEnable(false)
end

function ShowStandUpButton()
    SetSitDownButtonEnable(false)
    SetStandUpButtonEnable(true)
end

function SetStandUpButtonEnable(enable)
    standUpInteractionButton.gameObject:SetActive(enable)
end

function SetSitDownButtonEnable(enable)
    if enable then
        if interactorButton == nil then
            interactorButton = self:AddInteractorButton()        
        end        
        ApplyButtonConfig(interactorButton, DownButton)
    else
        if interactorButton ~= nil then
            self:RemoveInteractorButton(interactorButton)
            interactorButton = nil            
        end
    end
end

function SetScale(transform, s1, s2)
    local x = s1.x
    if s2.x ~= 0 then
        x = x / s2.x
    end
    local y = s1.y
    if s2.y ~= 0 then
        y = y / s2.y
    end
    local z = s1.z
    if s2.z ~= 0 then
        z = z / s2.z
    end
    transform.localScale = CS.UnityEngine.Vector3(x, y, z)
end

function OnInteractorButtonClick()
    local localActor = CS.DouyinActorService.GetLocalActor()
    if localActor ~= nil then
        localActor:SitDown(self.gameObject, SwitchSeatFromSeat)
    end
end

function GetInteractorButton()
    return interactorButton
end

function RegisterUIDragEvent()
    if JoyStickControlMain ~= nil then
        JoyStickControlMain:OnUIDrag(OnUIDragMainMoveUI)
    end
end

function UnregisterUIDragEvent()
    if JoyStickControlMain ~= nil then
        JoyStickControlMain:OffUIDrag(OnUIDragMainMoveUI)
    end
end
