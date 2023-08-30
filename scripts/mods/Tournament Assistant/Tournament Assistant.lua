local mod = get_mod("Tournament Assistant")

local steam_id = Steam.user_id()
if not steam_id then
    mod:echo("Tournament Assistant could not determine your Steam ID. All functionality disabled")
    return
end
steam_id = tostring(Steam.id_hex_to_dec(steam_id))

local DB = dofile("scripts/mods/Tournament Assistant/DB")


local level_table = {}
DB.read("Levels", "select=id,name", function(error_code, data)
    if error_code or type(data) ~= "table" then
        mod:echo("Tournament Assistant could not retrieve level data, some features will not work")
        return
    end
    
    for _,value in ipairs(data) do
        level_table[value.name] = value.id
    end
end)

local get_level_key = function()
    local game_mode = Managers.state.game_mode
    if not game_mode then
        return nil
    end
    local level_key = game_mode:level_key()
    if not level_key then
        return nil
    end

    if level_key == "arena_belakor" then
        return level_key
    end

    -- Remove Chaos Wastes name modifiers
    level_key = level_key:gsub("_wastes", "")
    level_key = level_key:gsub("_khorne", "")
    level_key = level_key:gsub("_nurgle", "")
    level_key = level_key:gsub("_slaanesh", "")
    level_key = level_key:gsub("_tzeentch", "")
    level_key = level_key:gsub("_belakor", "")
    level_key = level_key:gsub("_path(%d+)", "")
    level_key = level_key:gsub("_%a$", "")

    return level_key
end

-------------------------------------------------
-- HANDLE DEATHS --------------------------------
-------------------------------------------------

local death_POST = function(level_code)
    local body = {
        ["steam_id"] = steam_id,
        ["level"] = level_code,
    }

    DB.insert("Deaths", body, nil)
end

local process_death = function()
    local level_key = get_level_key()
    if (level_key == "inn_level" or level_key == "inn_level_celebrate" or level_key == "inn_level_skulls" or level_key == "inn_level_halloween" or level_key == "inn_level_sonnstill" or level_key == "morris_hub") then
        return
    end
    if level_key and level_table[level_key] then
        death_POST(level_table[level_key])
    end
end

mod:hook_safe(GenericStatusExtension, "set_dead", function (self, dead)
    local player = Managers.player:local_human_player()
    if not player then
        return
    end
    local player_unit = player.player_unit
    if player_unit ~= self.unit then
        return
    end

    if dead then
        process_death()
    end
end)






-------------------------------------------------
-- HANDLE EVENTS --------------------------------
-------------------------------------------------

local map_event_codes =
{
    -- A Quiet Drink
    crawl_floor_fall                           = 1000,
    
    -- Righteous Stand
    military_courtyard_event_01                = 2000,
    military_courtyard_event_02                = 2000,
    military_end_event_survival_start          = 2001,

    -- Convocation of Decay
    catacombs_puzzle_event_start               = 3000,
    catacombs_end_event_pool_challenge         = 3001,

    -- Hunger in the Dark
    mines_end_event_start                      = 4000,

    -- Halescourge
    gz_chaos_boss                              = 5000,

    -- Athel Yenlui
    elven_ruins_end_event                      = 6000,

    -- Screaming Bell
    canyon_bell_event                          = 7000,

    -- Fort Brachsenbrucke
    fort_horde_gate                            = 8000,

    -- Into the Nest
    stronghold_boss                            = 9000,

    -- Against the Grain
    farmlands_rat_ogre                         = 10000,
    farmlands_storm_fiend                      = 10000,
    farmlands_chaos_troll                      = 10000,
    farmlands_chaos_spawn                      = 10000,
    farmlands_prisoner_event_01                = 10001,

    -- Empire in Flames
    ussingen_payload_event_01                  = 11000,
    ussingen_payload_event_02                  = 11000,
    ussingen_payload_event_03                  = 11000,

    -- Festering Ground
    nurgle_end_event_start                     = 12000,

    -- The War Camp
    warcamp_payload                            = 13000,
    warcamp_chaos_boss                         = 13001,

    -- The Skittergate
    skittergate_chaos_boss                     = 14000,
    skittergate_rasknitt_boss                  = 14001,

    -- Old Haunts
    dlc_portals_temple_yard                    = 15000,
    dlc_portals_end_event_guards               = 15001,

    -- Blood in the Darkness
    bastion_gate_event                         = 16000,
    bastion_finale_sorcerer                    = 16001,

    -- The Enchanter's Lair
    castle_chaos_boss                          = 17000,

    -- The Pit
    dlc_bogenhafen_slum_event_start            = 18000,
    dlc_bogenhafen_slum_gauntlet_wall_smash    = 18001,

    -- The Blightreaper
    dlc_bogenhafen_city_sewer_start            = 19000,
    dlc_bogenhafen_city_temple_start           = 19001,

    -- The Horn of Magnus
    magnus_door_event_guards                   = 20000,
    magnus_end_event                           = 20001,

    -- Garden of Morr
    cemetery_plague_brew_event_1_a             = 21000,
    cemetery_plague_brew_event_1_b             = 21000,

    -- Engines of War
    forest_skaven_camp_loop                    = 22000,
    forest_end_event_loop                      = 22001,

    -- Dark Omens
    crater_mid_event                           = 24000,
    crater_end_event_intro_wave                = 24001,
    
    -- Trail of Treachery
    trail_mid_event_01                         = 57000,
    trail_end_event_torch_hunter               = 57001,
    
    -- Tower of Treachery
    wt_library_event                           = 59000,
    wt_dining_sorcerers                        = 59001,
    wt_end_event_constant                      = 59002,
    
}

local already_activated_events = {}

local event_POST = function(event_code)
    local body = {
        ["steam_id"] = steam_id,
        ["event"] = event_code,
    }

    DB.insert("EventStarts", body, nil)
end

local already_activated_events = {}

mod:hook_safe(TerrorEventMixer, "start_event", function(event_name, data)
    if not Managers.player.is_server or not event_name then
        return
    end

    if map_event_codes[event_name] and not already_activated_events[event_name] then
        already_activated_events[event_name] = true
        event_POST(map_event_codes[event_name])
    end
end)






-------------------------------------------------
-- HANDLE MONSTERS ------------------------------
-------------------------------------------------

local monster_codes = {
    ["units/beings/enemies/skaven_rat_ogre/chr_skaven_rat_ogre"] = 1,
    ["units/beings/enemies/skaven_stormfiend/chr_skaven_stormfiend"] = 2,
    ["units/beings/enemies/chaos_troll/chr_chaos_troll"] = 3,
    ["units/beings/enemies/chaos_spawn/chr_chaos_spawn"] = 4,
    ["units/beings/enemies/beastmen_minotaur/chr_beastmen_minotaur"] = 5,
}
local monster_POST = function(monster_code, level_code, num_monsters)
    local body = {
        ["steam_id"] = steam_id,
        ["monster"] = monster_code,
        ["num_monsters"] = num_monsters,
        ["level"] = level_code,
    }

    DB.insert("MonsterSpawns", body, nil)
end

mod:hook_safe(UnitSpawner, "spawn_local_unit_with_extensions", function(self, unit_name, unit_template_name, extension_init_data, position, rotation, material)
    if not Managers.player or not Managers.player.is_server or not unit_name then
        return
    end

    local monster_code = monster_codes[unit_name]

    if not monster_code then
        return
    end
    
    local level_key = get_level_key()
    if (level_key == "inn_level" or level_key == "inn_level_celebrate" or level_key == "inn_level_skulls" or level_key == "inn_level_halloween" or level_key == "inn_level_sonnstill" or level_key == "morris_hub") then
        return
    end
    if not level_table[level_key] then
        return
    end
    
    -- TODO report the current number of monsters

    monster_POST(monster_code, level_table[level_key], nil)
end)



------------------------------------------------
-- MISCELLANEOUS -------------------------------
------------------------------------------------

local sent_player_name = false
mod:hook_safe(BulldozerPlayer, "spawn", function (self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade, ability_cooldown_percent_int, additional_items, initial_buff_names)
    if sent_player_name then
        return
    end
    
    local player = Managers.player:local_human_player()
    if player and player:name() then
        local body = {
            ["steam_id"] = steam_id,
            ["name"] = player:name(),
        }
        DB.upsert("PlayerNames", body, function(error_code, data)
            if error_code == nil then
                sent_player_name = true
            end
        end)
    end
end)

mod.on_game_state_changed = function(status, state_name)
    already_activated_events = {}
    
    if state_name == "StateIngame" and level_key == "inn_level" then
        player_name_POST(player_name)
    end
end



