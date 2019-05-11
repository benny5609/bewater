local bewater       = require "bw.bewater"
local id_producer   = require "bw.server.id_producer"
local mongo         = require "db.mongo"

bewater.start(id_producer, function()
    id_producer.start({
        load_id = function()
            return mongo.get("autoid")
        end,
        save_id = function(id)
            return mongo.set("autoid", id)
        end,
    })
end)
