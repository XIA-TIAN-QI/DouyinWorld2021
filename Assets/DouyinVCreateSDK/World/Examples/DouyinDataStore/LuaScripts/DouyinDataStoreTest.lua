---@var BtnGetData : UnityEngine.UI.Button
---@var BtnSetData : UnityEngine.UI.Button
---@var BtnUpdateData : UnityEngine.UI.Button
---@var BtnRemoveData : UnityEngine.UI.Button
---@var BtnIncrementData : UnityEngine.UI.Button
---@var BtnGetPlayerData : UnityEngine.UI.Button
---@var BtnSetPlayerData : UnityEngine.UI.Button
---@var BtnUpdatePlayerData : UnityEngine.UI.Button
---@var BtnRemovePlayerData : UnityEngine.UI.Button
---@var BtnIncrementPlayerData : UnityEngine.UI.Button
---@var BtnGetPetData : UnityEngine.UI.Button
---@var BtnSetPetData : UnityEngine.UI.Button
---@var BtnUpdatePetData : UnityEngine.UI.Button
---@var BtnRemovePetData : UnityEngine.UI.Button
---@var BtnIncrementPetData : UnityEngine.UI.Button
---@end

local playerData = nil
local petData = nil

-- Start is called before the first frame update
function Start()
    BtnGetData.onClick:AddListener(function()
        print("GetData")
        DouyinDataStoreManager.GetData("backpack", "items", "item", function(code, message, data)
            print("GetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnSetData.onClick:AddListener(function()
        print("SetData")
        DouyinDataStoreManager.SetData("backpack", "items", "item", 1, function(code, message, data)
            print("SetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnUpdateData.onClick:AddListener(function()
        print("UpdateData")
        DouyinDataStoreManager.UpdateData("backpack", "items", "item", function(curValue, info)
            print("UpdateData "..tostring(curValue))
            return curValue + 1
        end, function(code, message, data)
            print("UpdateData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnRemoveData.onClick:AddListener(function()        
        print("RemoveData")
        DouyinDataStoreManager.RemoveData("backpack", "items", "item", function(code, message, data)
            print("RemoveData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnIncrementData.onClick:AddListener(function()
        print("IncrementData")
        DouyinDataStoreManager.IncrementData("backpack", "items", "item", 1, function(code, message, data)
            print("IncrementData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    
    BtnGetPlayerData.onClick:AddListener(function()
        print("GetPlayerData")
        local player = DouyinPlayerService.GetLocalPlayer()
        if player == nil then
            print("local player is nil")
            return
        end
        DouyinPlayerDataStore.GetData(player, "backpack", "items", function(code, message, data)
            print("GetPlayerData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnSetPlayerData.onClick:AddListener(function()
        print("SetPlayerData")
        local player = DouyinPlayerService.GetLocalPlayer()
        if player == nil then
            print("local player is nil")
            return
        end
        DouyinPlayerDataStore.SetData(player, "backpack", "items", 1, function(code, message, data)
            print("SetPlayerData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnUpdatePlayerData.onClick:AddListener(function()
        print("UpdatePlayerData")
        local player = DouyinPlayerService.GetLocalPlayer()
        if player == nil then
            print("local player is nil")
            return
        end
        DouyinPlayerDataStore.UpdateData(player, "backpack", "items", function(curValue, info)
            print("UpdatePlayerData "..tostring(curValue))
            return curValue + 1
        end, function(code, message, data)
            print("UpdatePlayerData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnRemovePlayerData.onClick:AddListener(function()
        print("RemovePlayerData")
        local player = DouyinPlayerService.GetLocalPlayer()
        if player == nil then
            print("local player is nil")
            return
        end
        DouyinPlayerDataStore.RemoveData(player, "backpack", "items", function(code, message, data)
            print("RemovePlayerData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnIncrementPlayerData.onClick:AddListener(function()
        print("IncrementPlayerData")
        local player = DouyinPlayerService.GetLocalPlayer()
        if player == nil then
            print("local player is nil")
            return
        end
        DouyinPlayerDataStore.IncrementData(player, "backpack", "items", 1, function(code, message, data)
            print("IncrementPlayerData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnGetPetData.onClick:AddListener(function()
        print("GetPetData")
        local pet = DouyinPetService.GetLocalPet()
        if pet == nil then
            print("local pet is nil")
            return
        end
        DouyinPetDataStore.GetData(pet, "backpack", "items", function(code, message, data)
            print("GetPetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnSetPetData.onClick:AddListener(function()
        print("SetPetData")
        local pet = DouyinPetService.GetLocalPet()
        if pet == nil then
            print("local pet is nil")
            return
        end
        DouyinPetDataStore.SetData(pet, "backpack", "items", 1, function(code, message, data)
            print("SetPetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnUpdatePetData.onClick:AddListener(function()
        print("UpdatePetData")
        local pet = DouyinPetService.GetLocalPet()
        if pet == nil then
            print("local pet is nil")
            return
        end
        DouyinPetDataStore.UpdateData(pet, "backpack", "items", function(curValue, info)
            return curValue + 1
        end, function(code, message, data)
            print("UpdatePetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnRemovePetData.onClick:AddListener(function()
        print("RemovePetData")
        local pet = DouyinPetService.GetLocalPet()
        if pet == nil then
            print("local pet is nil")
            return
        end
        DouyinPetDataStore.RemoveData(pet, "backpack", "items", function(code, message, data)
            print("RemovePetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
    BtnIncrementPetData.onClick:AddListener(function()
        print("IncrementPetData")
        local pet = DouyinPetService.GetLocalPet()
        if pet == nil then
            print("local pet is nil")
            return
        end
        DouyinPetDataStore.IncrementData(pet, "backpack", "items", 1, function(code, message, data)
            print("IncrementPetData " .. tostring(code) .. " " .. message .. " " .. (data == nil and "nil" or data == "" and "nil" or tostring(data)))
        end)
    end)
end

function OnPlayerJoin(player)
    print("OnPlayerJoin")

    DouyinPlayerDataStore.GetData(player, "backpack", "items", function(code, message, data)
        if code then
            playerData = data
        end
    end)
end

function OnActorSpawn(actor)
    print("OnActorSpawn")

    DouyinPetDataStore.GetData(actor.douyinPet, "backpack", "items", function(code, message, data)
        if code then
            petData = data
        end
    end)
end

