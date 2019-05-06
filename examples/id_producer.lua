local bewater       = require "bw.bewater"
local mongo         = require "bw.db.mongo_helper"
local id_producer   = require "bw.share.id_producer"

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
