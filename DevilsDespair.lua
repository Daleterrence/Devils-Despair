--[[

Copyright © 2026, DTR
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of this addon nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

_addon.name = 'DevilsDespair'
_addon.author = 'DTR'
_addon.version = '1.1'
_addon.desc = 'Removes Halloween Harvest Festival music by replacing it with the original zone music.'
_addon.commands = {'dd'}

require('luau')
require('strings')
local config = require('config')
local res = require('resources')
local packets = require('packets')
local send_command = windower.send_command
local add_to_chat = windower.add_to_chat
local addon_title = ('['):color(36)..('DevilsDespair'):color(209)..('] '):color(36)

-- Default settings
local defaults = {
    enabled = true
}

local settings = config.load(defaults)

-- Zone music mapping (zone ID -> music ID)
local zone_music = require('zone_music')

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
        local correct_music = zone_music[current_zone_id]
        
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

