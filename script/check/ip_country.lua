local skynet = require "skynet"
local ip_country = require "ip.ip_country"
return function()
    local cn = '113.111.109.39'
    local us = '95.163.203.38'
    local c = assert(ip_country.get_country(cn))
    local i = 0
    while c == "unknown" do
        skynet.error("waiting www.ip.cn")
        skynet.sleep(20)
        c = ip_country.get_country(cn)
        i = i + 1
        assert(i<100)
    end
    assert(c == "China", c)
    assert(ip_country.is_china(cn))
    c = assert(ip_country.get_country(us))
    i = 0
    while c == "unknown" do
        skynet.error("waiting www.ip.cn")
        skynet.sleep(10)
        c = ip_country.get_country(us)
        i = i + 1
        assert(i<100)
    end
    assert(c == "United States", c)
    assert(not ip_country.is_china(us))
    return true
end
