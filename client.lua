local ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    for _, garage in ipairs(Config.Garages) do
        RequestModel(GetHashKey(garage.pedModel))
        while not HasModelLoaded(GetHashKey(garage.pedModel)) do
            Citizen.Wait(1)
        end

        local ped = CreatePed(4, GetHashKey(garage.pedModel), garage.pedCoords.x, garage.pedCoords.y, garage.pedCoords.z, garage.pedHeading, false, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        local blip = AddBlipForCoord(garage.pedCoords.x, garage.pedCoords.y, garage.pedCoords.z)
        SetBlipSprite(blip, garage.blip.sprite)
        SetBlipColour(blip, garage.blip.color)
        SetBlipScale(blip, garage.blip.scale)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(garage.name)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent('garage:storeVehicle')
AddEventHandler('garage:storeVehicle', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('garage:storeVehicle', plate)
    else
        ESX.ShowNotification('You are not in a vehicle')
    end
end)

RegisterNetEvent('garage:retrieveVehicle')
AddEventHandler('garage:retrieveVehicle', function(vehicleProps)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = CreateVehicle(vehicleProps.model, coords.x, coords.y, coords.z, vehicleProps.heading, true, false)
    ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, garage in ipairs(Config.Garages) do
            local distance = #(coords - garage.pedCoords)
            if distance < 2.0 then
                ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to access the garage')
                if IsControlJustReleased(0, 38) then
                    OpenGarageMenu(garage)
                end
            end
        end
    end
end)

function OpenGarageMenu(garage)
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'garage_menu', {
        title = garage.name,
        align = 'top-left',
        elements = {
            {label = 'Store Vehicle', value = 'store'},
            {label = 'Retrieve Vehicle', value = 'retrieve'}
        }
    }, function(data, menu)
        if data.current.value == 'store' then
            TriggerEvent('garage:storeVehicle')
        elseif data.current.value == 'retrieve' then
            TriggerServerEvent('garage:retrieveVehicle')
        end
    end, function(data, menu)
        menu.close()
    end)
end