---@var UseCachedData:boolean
---@end

function Awake()
    _G["DouyinPlayerDataStore"] = script
    script.datas = {}
end

function OnDestroy()
    _G["DouyinPlayerDataStore"] = nil
    script.datas = {}
end

local function GetDataName(storeName, scopeName, dataKey)
    return storeName.."_"..scopeName.."_"..dataKey
end

function GetData(player, storeName, dataKey, callback)
    if player == nil then
        callback(false, "Invalid player", nil)
        return
    end

    local onlinePlayer = DouyinPlayerService.GetPlayerByOpenID(player.playerOpenID) 
    if onlinePlayer == nil then
        callback(false, "Failed to get player", nil)
        return
    end
    
    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePlayer.playerOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            callback(true, "Success", script.datas[cacheKey])
            return
        end
    end

    DouyinDataStoreManager.GetData(storeName, onlinePlayer.playerOpenID, dataKey, callback)
end

function SetData(player, storeName, dataKey, data, callback)
    if player == nil then
        callback(false, "Invalid player", nil)
        return
    end

    local onlinePlayer = DouyinPlayerService.GetPlayerByOpenID(player.playerOpenID) 
    if onlinePlayer == nil then
        callback(false, "Failed to get player", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePlayer.playerOpenID, dataKey)
        script.datas[cacheKey] = data
    end

    DouyinDataStoreManager.SetData(storeName, onlinePlayer.playerOpenID, dataKey, data, callback)
end

function IncrementData(player, storeName, dataKey, value, callback)
    if player == nil then
        callback(false, "Invalid player", nil)
        return
    end

    local onlinePlayer = DouyinPlayerService.GetPlayerByOpenID(player.playerOpenID) 
    if onlinePlayer == nil then
        callback(false, "Failed to get player", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePlayer.playerOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            script.datas[cacheKey] = script.datas[cacheKey] + value
        end
    end

    DouyinDataStoreManager.IncrementData(storeName, onlinePlayer.playerOpenID, dataKey, value, callback)
end

function UpdateData(player, storeName, dataKey, func, callback)
    if player == nil then
        callback(false, "Invalid player", nil)
        return
    end

    local onlinePlayer = DouyinPlayerService.GetPlayerByOpenID(player.playerOpenID) 
    if onlinePlayer == nil then
        callback(false, "Failed to get player", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePlayer.playerOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            script.datas[cacheKey] = func(script.datas[cacheKey])
        end
    end

    DouyinDataStoreManager.UpdateData(storeName, onlinePlayer.playerOpenID, dataKey, func, callback)
end

function RemoveData(player, storeName, dataKey, callback)
    if player == nil then
        callback(false, "Invalid player", nil)
        return
    end

    local onlinePlayer = DouyinPlayerService.GetPlayerByOpenID(player.playerOpenID) 
    if onlinePlayer == nil then
        callback(false, "Failed to get player", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePlayer.playerOpenID, dataKey)
        script.datas[cacheKey] = nil
    end

    DouyinDataStoreManager.RemoveData(storeName, onlinePlayer.playerOpenID, dataKey, callback)
end