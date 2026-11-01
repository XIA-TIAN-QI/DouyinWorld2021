---@var videoPlayer         :DouyinVideoPlayer
---@var videoSlider         :UnityEngine.UI.Slider
---@var videoCurrentTime    :UnityEngine.UI.Text
---@var playVideoBtn        :UnityEngine.UI.Button
---@var volumeSlider        :UnityEngine.UI.Slider
---@var playImage           :UnityEngine.Sprite
---@var pauseImage          :UnityEngine.Sprite
---@var volumeBtn           :UnityEngine.UI.Button
---@var volumeOn            :UnityEngine.Sprite
---@var volumeNone          :UnityEngine.Sprite
---@var videoPanelCanvasGroup  :UnityEngine.CanvasGroup 
---@var videoPanelShowHideBtn  :UnityEngine.UI.Button
---@var videoPanelHideTime  :float =5
---@end

local clickBeganOnVideoSlider = false
local clickBeganOnVolumeSlider = false
local panelTargetAlpha = 1
local panelTransitionSpeed = 3
local autoHideTimer = 5
local isPanelVisible = true

local function ResetAutoHideTimer()
    autoHideTimer = videoPanelHideTime
    ShowVideoPanel()
end

local function UpdateVideoTimeDisplay()
    videoCurrentTime.text = CS.DouyinVideoPlayer.TimeToString(videoPlayer.playingTime) .. " / " .. CS.DouyinVideoPlayer.TimeToString(videoPlayer.totalTime)
end

local function UpdatePlayButtonState()
    playVideoBtn.image.sprite = videoPlayer.isPlaying and pauseImage or playImage
end

local function UpdateVolumeButtonState()
    volumeBtn.image.sprite = (videoPlayer.volume == 0) and volumeNone or volumeOn
end

function InitData()
    if videoPlayer ~= nil then
        UpdatePlayButtonState()
        volumeSlider.minValue = 0.0
        volumeSlider.maxValue = 1.0
        UpdateVolumeButtonState()

        videoSlider.minValue = 0.0
        videoSlider.maxValue = videoPlayer.totalTime
        videoSlider.value = videoPlayer.playingTime
        UpdateVideoTimeDisplay()
    end

    HideVideoPanel()
end

function OnNetSpawned()
    InitData()
end

function Update()
    if videoPlayer ~= nil then
        -- videoPlayer:SetVolume(volumeSlider.value)
        if clickBeganOnVideoSlider == false then
            videoSlider.minValue = 0.0
            videoSlider.maxValue = videoPlayer.totalTime
            videoSlider.value = videoPlayer.playingTime
        end

        UpdatePlayButtonState()
        UpdateVideoTimeDisplay()

        UpdateVolumeButtonState()
        if clickBeganOnVolumeSlider == false then
            volumeSlider.value = videoPlayer.volume
        else
            if videoPlayer.volume ~= volumeSlider.value then
                videoPlayer:SetVolume(volumeSlider.value)
            end
        end
        --if videoPlayer:IsReadyToPlay() == true then
        --    videoPlayer:InitPlay();
        --end

        if clickBeganOnVideoSlider or clickBeganOnVolumeSlider then
            ResetAutoHideTimer()
        end

        HandlePanelVisibility()
    end
end

-----------------------------------视频组件主操作------------------------------------

function PlayButtonEvent()
    ResetAutoHideTimer()
    if videoPlayer.isPlaying == true then
        videoPlayer:PauseVideo()
        playVideoBtn.image.sprite = playImage
    else
        videoPlayer:ResumeVideo()
        playVideoBtn.image.sprite = pauseImage
    end
end

function VolumeButtonEvent()
    ResetAutoHideTimer()
    if videoPlayer.volume == 0 then
        videoPlayer:SetVolume(volumeSlider.value)
        volumeBtn.image.sprite = volumeOn
    else
        videoPlayer:SetVolume(0)
        volumeBtn.image.sprite = volumeNone
    end
end

function ReplayButtonEvent()
    ResetAutoHideTimer()
    videoPlayer:Restart()
end

function VideoSliderClick()
    ResetAutoHideTimer()
    videoPlayer:SetTime(videoSlider.value);
    if videoPlayer.isPlaying == false then
        clickBeganOnVideoSlider = false;
        videoPlayer:PlayVideo()
    end
end

function VideoSliderPotentialDrag()
    print("VideoControlPanel.VideoSliderPotentialDrag clickBeganOnVideoSlider = true ")
    ResetAutoHideTimer()
    clickBeganOnVideoSlider = true
end

function VideoSliderEndDrag()
    if clickBeganOnVideoSlider == true then
        clickBeganOnVideoSlider = false
        videoPlayer:SetTime(videoSlider.value)
    end
end

function VolumeSliderClick()
    print("VideoControlPanel.VolumeSliderClick: ", volumeSlider.value)
    ResetAutoHideTimer()
    clickBeganOnVolumeSlider = false;
    videoPlayer:SetVolume(volumeSlider.value)
end

function VolumeSliderPotentialDrag()
    ResetAutoHideTimer()
    clickBeganOnVolumeSlider = true
    print("VideoControlPanel.VolumeSliderPotentialDrag: ", volumeSlider.value)
end

function VolumeSliderEndDrag()
    print("VideoControlPanel.VolumeSliderEndDrag: ", volumeSlider.value)
    if clickBeganOnVolumeSlider == true then
        clickBeganOnVolumeSlider = false
        videoPlayer:SetVolume(volumeSlider.value)
    end
end

------------------------------------辅助函数------------------------------------

function TimeToString(time)
    local minutes = time / 60.0
    local seconds = time % 60.0
    local hours = minutes / 60.0
    minutes = minutes % 60.0
    local strMinutes = ""
    local strSeconds = ""
    local strHours = ""

    strHours = string.format("%02d", math.floor(hours))
    strMinutes = string.format("%02d", math.floor(minutes))
    strSeconds = string.format("%02d", math.floor(seconds))

    if hours == 0 then
        return strMinutes .. ":" .. strSeconds
    end
    return strHours .. ":" .. strMinutes .. ":" .. strSeconds
end

------------------------------------视频进度面板显隐------------------------------------
function HandlePanelVisibility()
    if not isPanelVisible and panelTargetAlpha == 0 then
        videoPanelCanvasGroup.alpha = 0
        return
    end

    if isPanelVisible then
        autoHideTimer = autoHideTimer - CS.UnityEngine.Time.deltaTime
        if autoHideTimer <= 0 then
            HideVideoPanel()
        end
    end

    if math.abs(videoPanelCanvasGroup.alpha - panelTargetAlpha) > 0.01 then
        videoPanelCanvasGroup.alpha = CS.UnityEngine.Mathf.Lerp(
                videoPanelCanvasGroup.alpha,
                panelTargetAlpha,
                panelTransitionSpeed * CS.UnityEngine.Time.deltaTime
        )
    else
        videoPanelCanvasGroup.alpha = panelTargetAlpha
    end
end

function ShowVideoPanel()
    if videoPanelCanvasGroup == nil then
        return
    end
    panelTargetAlpha = 1
    isPanelVisible = true
    autoHideTimer = videoPanelHideTime
end

function HideVideoPanel()
    if videoPanelCanvasGroup == nil then
        return
    end
    panelTargetAlpha = 0
    isPanelVisible = false
end

function OnVideoModelClicked()
    ShowVideoPanel()
end
