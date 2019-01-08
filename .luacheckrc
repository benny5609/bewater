codes = true
color = true

std = "max"

include_files = {
    "lualib/*",
    "script/*",
    "service/*",
}

exclude_files = {
    "lualib/bw/xml/*",
    "lualib/bw/ws/*",
    "lualib/bw/bash.lua",
    "lualib/bw/schedule.lua",
    "lualib/bw/ip/ip_country.lua",
}

ignore = {
    "i",
    "k",
    "v",
    "bash",
    "SERVICE_NAME",
    "self",
}
