---@var FollowTarget :          UnityEngine.Transform
---@var Offset:                 Vector3
---@var NameText:               UnityEngine.UI.Text 
---@var Name:                   string  
---@var Duration:               float 5
---@var MaxCount:               int 2
---@var MsgBubble:              UnityEngine.GameObject
---@var Messages:               List<string>
---@end 

local uiRoot;
local uiRootCanvas;
local bubbles = {}
local usedBubbles = {}
local MessageList = {}
function Awake()
    if Duration <=0 then
        Duration = 5
    end

    if MaxCount <=0 then
        MaxCount = 2
    end
    
    uiRoot = self.gameObject.transform:Find("UIRoot")
    uiRootCanvas = self.gameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
    if Offset == nil then
        Offset = UnityEngine.Vector3(0, 0, 0)
    end
    MsgBubble:SetActive(false)
    for i = 1, MaxCount do
        local bubble = UnityEngine.GameObject.Instantiate(MsgBubble)
        bubble.transform:SetParent(MsgBubble.transform.parent, false)
        bubble.transform.localScale = UnityEngine.Vector3.one
        bubble.name = "bubble"
        bubble:SetActive(true)
        bubble:SetActive(false)
        local script = InitBubble(bubble)
        table.insert(bubbles, script)
    end
    SetName(Name)
    if Messages ~= nil then
        for i = Messages.Count -1, 0,-1 do
            AddMessage(Messages[i])
        end
    end
end


function InitBubble(bubble)
    local bubbleScript = {}
    bubbleScript.gameObject = bubble
    bubbleScript.content = bubble:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))
    bubbleScript.SetMessage = function(msg, duration)
         bubbleScript.content.text = msg
         bubbleScript.lifeTime = UnityEngine.Time.time + duration
    end 
    
    bubbleScript.IsShowEnd = function()
        return UnityEngine.Time.time > bubbleScript.lifeTime
    end   
    return bubbleScript
end


function LateUpdate()
    if uiRoot ~= nil and  FollowTarget ~= nil then
        UpdatePosition()
    end
end


function UpdatePosition()
    local camera = UnityEngine.Camera.main
    if camera ~= nil then
        local pos = FollowTarget.position + Offset
        local screenPosition = camera:WorldToScreenPoint(pos)
        if screenPosition.z < 0 then
            uiRoot.transform.position = UnityEngine.Vector3(-2000, -2000, -2000)
        else
            uiRoot.transform.position =  screenPosition
        end

        local  distance = UnityEngine.Vector3.Distance(camera.transform.position, pos);
        local distanceRatio = UnityEngine.Mathf.InverseLerp(4, 15, distance);
        uiRootCanvas.sortingOrder = - UnityEngine.Mathf.RoundToInt(10000 * distanceRatio);
    end
end

function Update()
    for i = #usedBubbles, 1, -1 do
        local bubble  = usedBubbles[i]
        if bubble.IsShowEnd() then
            bubble.gameObject:SetActive(false)
            table.remove(usedBubbles, i)
            table.insert(bubbles, bubble)
            return;
        end
    end
    -- 有消息待显示
    if #MessageList > 0 then
        for i = #MessageList, 1, -1 do
            local bubble  = GetBubble()
            if bubble == nil then
                break
            end
            bubble.SetMessage(MessageList[i], Duration)
            table.remove(MessageList, i)
            bubble.gameObject.transform:SetAsLastSibling()
            bubble.gameObject:SetActive(true)
            bubble.gameObject.transform.localScale = UnityEngine.Vector3.zero
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(bubble.content.transform.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)));
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(bubble.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)));
            bubble.gameObject.transform:DOScale(UnityEngine.Vector3.one, 0.5):SetEase(CS.DG.Tweening.Ease.OutBack);
            table.insert(usedBubbles, bubble)
            break;
        end
    end
end

function GetBubble()
    local count = #bubbles
    if count > 0 then
        local bubble = bubbles[count]
        table.remove(bubbles, count)
        return  bubble
    end
    return nil
end

-- 添加头顶气泡消息
function AddMessage(msg)
   table.insert(MessageList, msg)
end

-- 设置名字版名字
function SetName(nameTxt)
    NameText.text = nameTxt
end



