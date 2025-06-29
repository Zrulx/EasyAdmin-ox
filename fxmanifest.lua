fx_version "cerulean"

games {"rdr3","gta5"}

author 'Blumlaut <blue@furfag.de>, Liam (Modified)'
description 'EasyAdmin - Admin Menu for FiveM & RedM'
version '7.2'


lua54 'yes'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

dependencies {
    'ox_lib',
    'yarn'
}

shared_scripts {
    'shared/util_shared.lua',
    '@ox_lib/init.lua',
    'death_system/sh_config.js'
} 

server_scripts {
    "server/*.lua",
    "plugins/**/*_shared.lua",
    "plugins/**/*_server.lua",
    "clockin/__server.lua",
    "death_system/sv_index.js",
    "liam-jail/server.lua"
}

client_scripts {
    "dependencies/NativeUI.lua",
    "dependencies/NativeUI-rdr3.lua",
    "dependencies/Controls.lua",
    "client/*.lua",
    "plugins/**/*_shared.lua",
    "plugins/**/*_client.lua",
    "death_system/cl_index.js",
    "liam-jail/client.lua"
}

ui_page "dependencies/nui/index.html"

files {
    "dependencies/images/*.png",
    "dependencies/nui/**/*"
}

provide 'EasyAdmin'


convar_category 'EasyAdmin' {
    "Configuration Options",
    {
        { "EasyAdmin language", "$ea_LanguageName", "CV_STRING", "en" },
        { "Default key to open the menu", "$ea_defaultKey", "CV_STRING", "none" },
        { "The Minimum Amount of Identifiers", "$ea_minIdentifierMatches", "CV_INT", "2" },
        { "Display banlist checking progress", "$ea_presentDeferral", "CV_BOOL", "true" },
        { "Moderation Actions Webhook", "$ea_moderationNotification", "CV_STRING", "false" },
        { "Report Notifications Webhook", "$ea_reportNotification", "CV_STRING", "false" },
        { "Detail Notifications Webhook", "$ea_detailNotification", "CV_STRING", "false" },
        { "Set a custom DateTime format", "$ea_dateFormat", "CV_STRING", "%d/%m/%Y     %H:%M:%S" },
        { "Image Uploader", "$ea_screenshoturl", "CV_STRING", "none" },
        { "Screenshot Field Name", "$ea_screenshotfield", "CV_STRING", "files[]" },
        { "JSON String arguments", "$ea_screenshotOptions", "CV_STRING", "{}" },
        { "Screenshot on Report", "$ea_enableReportScreenshots", "CV_BOOL", "true" },
        { "Webhook Identifier", "$ea_logIdentifier", "CV_STRING", "steam" },
        { "Enable calladmin Command", "$ea_enableCallAdminCommand", "CV_BOOL", "true" },
        { "Enable report Command", "$ea_enableReportCommand", "CV_BOOL", "true" },
        { "calladmin Command Name", "$ea_callAdminCommandName", "CV_STRING", "calladmin" },
        { "report Command Name", "$ea_reportCommandName", "CV_STRING", "report" },
        { "calladmin Cooldown (seconds)", "$ea_callAdminCooldown", "CV_INT", "60" },
        { "Minimum Reports to Ban Someone", "$ea_defaultMinReports", "CV_INT", "3" },
        { "Report Ban Time (unix time)", "$ea_ReportBanTime", "CV_INT", "86400" },
        { "Allow Minimum Report Count", "$ea_MinReportModifierEnabled", "CV_BOOL", "true" },
        { "Minimum Amount of Players to enable Report Modifier", "$ea_MinReportPlayers", "CV_INT", "12" },
        { "Divisor of Player Count to get minimum reports needed count", "$ea_MinReportModifier", "CV_BOOL", "true" },
        { "Amount of Warns before Actions", "$ea_maxWarnings", "CV_INT", "3" },
        { "Maximum Warn Action", "$ea_warnAction", "CV_STRING", "kick" },
        { "Maximum Warn Ban Time (unix time)", "$ea_warningBanTime", "CV_INT", "604800" },
        { "Hide IP in the GUI", "$ea_IpPrivacy", "CV_BOOL", "true" },
        { "Banlist Backup Time (hours)", "$ea_backupFrequency", "CV_INT", "72" },
        { "Maximum Backup Count", "$ea_maxBackupCount", "CV_INT", "10" },
        { "Chat Reminder Time (minutes, disabled if 0)", "$ea_chatReminderTime", "CV_INT", "0" },
        { "Time before Cached Player Expires", "$ea_playerCacheExpiryTime", "CV_INT", "900" },
        { "Set Debug Level", "$ea_logLevel", "CV_INT", "1" },
        { "Enable Custom Banlist", "$ea_custombanlist", "CV_BOOL", "false" },
        { "Use Tokens as Identifiers", "$ea_useTokenIdentifiers", "CV_BOOL", "true" },
        { "Enable Ascii Art on Start", "$ea_enableSplash", "CV_BOOL", "true" },
        { "Token for Discord bot", "$ea_botToken", "CV_STRING", "none" },
        { "Channel for Discord bot to log", "$ea_botLogChannel", "CV_STRING", "none" },
        { "Channel for Discord bot to enable live status", "$ea_botStatusChannel", "CV_STRING", "true" },
        { "Enable Allowlist", "$ea_enableAllowlist", "CV_BOOL", "false" },
        { "Disable Shooting Whilst Frozen", "$ea_disableShootingWhileFrozen", "CV_BOOL", "false" },
    }
}
