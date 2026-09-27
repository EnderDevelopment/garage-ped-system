local ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('garage:getStoredVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    MySQL.Async.fetchAll('SELECT * FROM garage_vehicles WHERE owner = @owner AND stored = 1', {
        ['@owner'] = identifier
    }, function(result)
        cb(result)
    end)
end)

RegisterNetEvent('garage:storeVehicle')
AddEventHandler('garage:storeVehicle', function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    MySQL.Async.execute('UPDATE garage_vehicles SET stored = 1 WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = identifier,
        ['@plate'] = plate
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, 'Vehicle stored successfully')
        else
            TriggerClientEvent('esx:showNotification', source, 'Failed to store vehicle')
        end
    end)
end)

RegisterNetEvent('garage:retrieveVehicle')
AddEventHandler('garage:retrieveVehicle', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier

    MySQL.Async.fetchAll('SELECT * FROM garage_vehicles WHERE owner = @owner AND stored = 1 LIMIT 1', {
        ['@owner'] = identifier
    }, function(result)
        if result[1] then
            local vehicleProps = json.decode(result[1].vehicle)
            TriggerClientEvent('garage:retrieveVehicle', source, vehicleProps)
            MySQL.Async.execute('UPDATE garage_vehicles SET stored = 0 WHERE id = @id', {
                ['@id'] = result[1].id
            })
        else
            TriggerClientEvent('esx:showNotification', source, 'No vehicles stored')
        end
    end)
end)