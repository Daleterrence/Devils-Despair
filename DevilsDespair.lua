_addon.name = 'Devil\'s Despair'
_addon.author = 'DTR'
_addon.version = '1.0'
_addon.desc = 'Removes Halloween Harvest Festival music by replacing it with the original zone music.'
_addon.commands = {'dd'}

require('luau')
require('strings')
local config = require('config')
local res = require('resources')
local packets = require('packets')
local send_command = windower.send_command
local add_to_chat = windower.add_to_chat
local addon_title = ('['):color(36)..('Devil\'s Despair'):color(209)..('] '):color(36)

-- Default settings
local defaults = {
    enabled = true
}

local settings = config.load(defaults)

-- Zone music mapping (zone name -> music ID)
local zone_music = {
    -- San d'Oria
    ['Port San d\'Oria'] = 107,
    ['Northern San d\'Oria'] = 107,
    ['Southern San d\'Oria'] = 107,
    
    -- Bastok
    ['Bastok Markets'] = 152,
    ['Bastok Mines'] = 152,
    ['Port Bastok'] = 152,
    ['Metalworks'] = 154,
    
    -- Windurst
    ['Windurst Waters'] = 151,
    ['Windurst Walls'] = 151,
    ['Port Windurst'] = 151,
    ['Windurst Woods'] = 151,

    --Jeuno
    ['Port Jeuno'] = 110,
    ['Ru\'Lude Gardens'] = 110,
    ['Upper Jeuno'] = 110,
    ['Lower Jeuno'] = 110,

    --Adoulin
    ['Western Adoulin'] = 59,

    --Outdoor zones
    ['Misareaux Coast'] = 230,
    ['Qufim Island'] = 0,

    -- Dungeons
    ['Horlais Peak'] = 0,
    ['Upper Delkfutt\'s Tower'] = 0
}

local current_zone = nil

local function initialize_addon()
    current_zone = windower.ffxi.get_info().zone
    add_to_chat(36, addon_title .. ('Addon started!'):color(36))
    add_to_chat(36, addon_title .. ('Removal of Harvest Festival Music is ' .. (settings.enabled and 'enabled' or 'disabled')))
end

windower.register_event('load', initialize_addon)
windower.register_event('reload', initialize_addon)

windower.register_event('zone change', function(new_id, old_id)
    current_zone = new_id
end)

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if not settings.enabled then return end
    
    if id == 0x00A then
        local packet = packets.parse('incoming', original)
        local day_music = packet['Day Music']
        local night_music = packet['Night Music']
        local modified_packet = false
        
        -- Get current zone info
        local current_zone_id = windower.ffxi.get_info().zone
        local zone_info = res.zones[current_zone_id]
        local correct_music = zone_info and zone_music[zone_info.en]
        
        -- Replaces day and night music with their original, appropriate music
        if (day_music == 29 or night_music == 29) and correct_music then
            if day_music == 29 then
                packet['Day Music'] = correct_music
                modified_packet = true
            end
            
            if night_music == 29 then
                packet['Night Music'] = correct_music
                modified_packet = true
            end
        end
        
        -- Return modified packet if any changes were made
        if modified_packet then
            local new_packet = packets.build(packet)
            return new_packet
        end
    end
end)

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or ''
    local args = {...}
    
    if command == 'on' then
        settings.enabled = true
        settings:save()
        add_to_chat(36, addon_title .. ('Harvest Festival Music: Disabled'))
        add_to_chat(36, addon_title .. ('Please move to another area for changes to take effect.'))
    elseif command == 'off' then
        settings.enabled = false
        settings:save()
        add_to_chat(36, addon_title .. ('Harvest Festival Music: Enabled.'))
        add_to_chat(36, addon_title .. ('Please move to another area for changes to take effect.'))
    elseif command == 'toggle' then
        settings.enabled = not settings.enabled
        settings:save()
        add_to_chat(36, addon_title .. ('Removal of Harvest Festival Music is now: ' .. (settings.enabled and 'enabled' or 'disabled')))
        add_to_chat(36, addon_title .. ('Please move to another area for changes to take effect.'))
    else
        add_to_chat(36, addon_title .. ('Unknown command. Use //dd on/off or toggle.'):color(36))
    end
end)
