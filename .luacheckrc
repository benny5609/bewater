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
    "lualib/bw/util/bash.lua",
    "lualib/bw/schedule.lua",
    "lualib/bw/protobuf.lua",
    "lualib/bw/util/ip_country.lua",
    "lualib/def/typedef/*",
    "service/sock/README.md",
}

ignore = {
    "i",
    "k",
    "v",
    "bash",
    "SERVICE_NAME",
    "self",
    "423", -- Shadowing a loop variable
    "211", -- Unused local variable
    "212", -- Unused argument
    "212/self", -- ignore self
    "213", -- Unused loop variable
}
