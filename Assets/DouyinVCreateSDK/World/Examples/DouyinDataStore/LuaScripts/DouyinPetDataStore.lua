---@var UseCachedData:boolean
---@end

function Awake()
    _G["DouyinPetDataStore"] = script
    script.datas = {}
end

function OnDestroy()
    _G["DouyinPetDataStore"] = nil
    script.datas = {}
end

local function GetDataName(storeName, scopeName, dataKey)
    return storeName.."_"..scopeName.."_"..dataKey
end

function GetData(pet, storeName, dataKey, callback)
    if pet == nil then
        callback(false, "Invalid pet", nil)
        return
    end

    local onlinePet = DouyinPetService.GetPet(pet.petID) 
    if onlinePet == nil then
        callback(false, "Failed to get pet", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePet.petOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            callback(true, "Success", script.datas[cacheKey])
            return
        end
    end

    DouyinDataStoreManager.GetData(storeName, onlinePet.petOpenID, dataKey, callback)
end

function SetData(pet, storeName, dataKey, data, callback)
    if pet == nil then
        callback(false, "Invalid pet", nil)
        return
    end

    local onlinePet = DouyinPetService.GetPet(pet.petID) 
    if onlinePet == nil then
        callback(false, "Failed to get pet", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePet.petOpenID, dataKey)
        script.datas[cacheKey] = data
    end

    DouyinDataStoreManager.SetData(storeName, onlinePet.petOpenID, dataKey, data, callback)
end

function IncrementData(pet, storeName, dataKey, value, callback)
    if pet == nil then
        callback(false, "Invalid pet", nil)
        return
    end

    local onlinePet = DouyinPetService.GetPet(pet.petID) 
    if onlinePet == nil then
        callback(false, "Failed to get pet", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePet.petOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            script.datas[cacheKey] = script.datas[cacheKey] + value
        end
    end

    DouyinDataStoreManager.IncrementData(storeName, onlinePet.petOpenID, dataKey, value, callback)
end

function UpdateData(pet, storeName, dataKey, func, callback)
    if pet == nil then
        callback(false, "Invalid pet", nil)
        return
    end

    local onlinePet = DouyinPetService.GetPet(pet.petID) 
    if onlinePet == nil then
        callback(false, "Failed to get pet", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePet.petOpenID, dataKey)
        if script.datas[cacheKey] ~= nil then
            script.datas[cacheKey] = func(script.datas[cacheKey])
        end
    end

    DouyinDataStoreManager.UpdateData(storeName, onlinePet.petOpenID, dataKey, func, callback)
end

function RemoveData(pet, storeName, dataKey, callback)
    if pet == nil then
        callback(false, "Invalid pet", nil)
        return
    end

    local onlinePet = DouyinPetService.GetPet(pet.petID) 
    if onlinePet == nil then
        callback(false, "Failed to get pet", nil)
        return
    end

    if UseCachedData then
        local cacheKey = GetDataName(storeName, onlinePet.petOpenID, dataKey)
        script.datas[cacheKey] = nil
    end

    DouyinDataStoreManager.RemoveData(storeName, onlinePet.petOpenID, dataKey, callback)
end