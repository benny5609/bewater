local skynet        = require "skynet"
local ip_country    = require "bw.ip.ip_country"
return function()
    local cn = '113.111.109.39'
    local c = ip_country.get_country(cn)
    assert(c == "China", c)
    assert(ip_country.is_china(cn))

    local us = '95.163.203.38'
    c = ip_country.get_country(us)
    assert(c == "United States", c)
    assert(not ip_country.is_china(us))

    c = ip_country.get_country('127.0.0.1')
    assert(c == "local", c)
    assert(ip_country.is_china('127.0.0.1'))
    
    c = ip_country.get_country('localhost')
    assert(c == "local", c)
    assert(ip_country.is_china('localhost'))

    return true
end
