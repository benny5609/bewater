codes = true
color = true

std = "max"

include_files = { 
    "lualib/*",
    "service/*",
}

exclude_files = {
    "lualib/xml/*",
    "lualib/ws/*",
    "lualib/bash.lua",
    "lualib/schedule.lua",
    "lualib/ip/ip_country.lua",
}

ignore = {
    "i",
    "k",
    "v",
    "bash",
    "SERVICE_NAME",
    "self",
}
