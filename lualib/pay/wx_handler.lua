local M = {}
function M:init(gate)
    self.gate = gate
end

function M:pay()
    print("on pay")
end
return M
