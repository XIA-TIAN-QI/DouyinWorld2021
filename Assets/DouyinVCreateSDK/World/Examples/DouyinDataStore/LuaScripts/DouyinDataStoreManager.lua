function Awake()
    script.stores = {}
    -- script.datas = {}
    _G["DouyinDataStoreManager"] = script
end

function OnDestroy()
    script.stores = {}
    -- script.datas = {}
    _G["DouyinDataStoreManager"] = nil
end

local function CheckDataStoreName(storeName)
    if not storeName or type(storeName) ~= "string" or storeName == "" then
        return false
    end
    return true
end

local function CheckScopeName(scopeName)
    if not scopeName or type(scopeName) ~= "string" or scopeName == "" then
        return false
    end
    return true
end

local function CheckKeyName(datakey)
    if not datakey or type(datakey) ~= "string" or datakey == "" then
        return false
    end
    return true
end

local function CheckCallback(callback, code, message, value)
    if not callback or type(callback) ~= "function" then
        return false
    end
    return true
end

local function GetDataName(storeName, scopeName, dataKey)
    return storeName.."_"..scopeName.."_"..dataKey
end

local function ConvertData(value)
    if type(value) == "table" then
        local jsonData = dkjson.encode(value)
        return true, jsonData
    else
        return true, value
    end
    return false, nil
end

local function GetDataStore(storeName, scopeName)
    if script.stores[scopeName] == nil then
        local ok, store = DouyinDataService.GetDataStore(storeName, scopeName, false)
        if ok == 0 then
            script.stores[scopeName] = store
        end
    end
    return script.stores[scopeName]
end

function GetData(storeName, scopeName, dataKey, callback)
    if not CheckDataStoreName(storeName) or not CheckScopeName(scopeName) or not CheckKeyName(dataKey) then
        callback(false, "Invalid parameter", nil)
        return
    end

    DATASTORE(function()
        local store = GetDataStore(storeName, scopeName)
        if store == nil then
            callback(false, "Failed to get data store", nil)
            return
        end

        local ok, value, info = store:GetData(dataKey)
        if ok ~= 0 then
            if ok == -10001 then
                -- 新数据
                callback(true, "New Data", {})
                -- script.datas[GetDataName(storeName, scopeName, dataKey)] = {}
            else
                -- 其他错误，返回失败
                callback(false, "Failed to get data " .. ok, nil)
            end
        else
            -- 读取成功
            if (type(value) == "string") then
                if value:match("^{.*}$") then
                    local jsonData = dkjson.decode(value)
                    -- script.datas[GetDataName(storeName, scopeName, dataKey)] = jsonData
                    callback(true, "Success", jsonData)
                else
                    callback(true, "Success", value)
                end
            else 
                -- script.datas[GetDataName(storeName, scopeName, dataKey)] = value
                callback(true, "Success", value)
            end
        end
    end)
end

function SetData(storeName, scopeName, dataKey, dataValue, callback)
    if not CheckDataStoreName(storeName) or not CheckScopeName(scopeName) or not CheckKeyName(dataKey) then
        callback(false, "Invalid parameter", nil)
        return
    end

    local ret, jsonData = ConvertData(dataValue)
    if not ret then
        callback(false, "Invalid data", nil)
        return
    end

    DATASTORE(function()
        local store = GetDataStore(storeName, scopeName)
        if store == nil then
            callback(false, "Failed to get data store", nil)
            return
        end
        
        local ok, value, info = store:SetData(dataKey, jsonData)
        if ok ~= 0 then
            callback(false, ok, value)
            return
        end
        
        -- 写入成功，更新缓存
        -- script.datas[GetDataName(storeName, scopeName, dataKey)] = dataValue
        callback(true, "Success", value)
    end)
end

function IncrementData(storeName, scopeName, dataKey, amount, callback)
    if not CheckDataStoreName(storeName) or not CheckScopeName(scopeName) or not CheckKeyName(dataKey) then
        callback(false, "Invalid parameter", nil)
        return
    end

    DATASTORE(function()
        local store = GetDataStore(storeName, scopeName)
        if store == nil then
            callback(false, "Failed to get data store", nil)
            return
        end

        local ok, value, info = store:IncrementData(dataKey, amount)
        if ok ~= 0 then
            callback(false, ok, value)
            return
        end
        
        -- 增加成功，更新缓存
        -- script.datas[GetDataName(storeName, scopeName, dataKey)] = value
        callback(true, "Success", value)
    end)
end

function RemoveData(storeName, scopeName, dataKey, callback)
    if not CheckDataStoreName(storeName) or not CheckScopeName(scopeName) or not CheckKeyName(dataKey) then
        callback(false, "Invalid parameter", nil)
        return
    end

    DATASTORE(function()
        local store = GetDataStore(storeName, scopeName)
        if store == nil then
            callback(false, "Failed to get data store", nil)
            return
        end

        local ok, value, info = store:RemoveData(dataKey)
        if ok ~= 0 then
            callback(false, ok, value)
            return
        end
        
        -- 删除成功，更新缓存
        -- script.datas[GetDataName(storeName, scopeName, dataKey)] = nil
        callback(true, "Success", nil)
    end)
end

function UpdateData(storeName, scopeName, dataKey, func, callback)
    if not CheckDataStoreName(storeName) or not CheckScopeName(scopeName) or not CheckKeyName(dataKey) then
        callback(false, "Invalid parameter", nil)
        return
    end

    DATASTORE(function()
        local store = GetDataStore(storeName, scopeName)
        if store == nil then
            callback(false, "Failed to get data store", nil)
            return
        end

        local ok, value, info = store:UpdateData(dataKey, function(curVal, info)
            new_val, new_option = func(curVal, info)
            local ret, jsonData = ConvertData(new_val)
            if not ret then
                return new_val, new_option
            end
            return jsonData, new_option
        end)
        if ok ~= 0 then
            callback(false, ok, value)
            return
        end
        
        -- 更新成功，更新缓存
        -- script.datas[GetDataName(storeName, scopeName, dataKey)] = value
        callback(true, "Success", value)
    end)
end