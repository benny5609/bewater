local bewater = require "bw.bewater"
return bewater.protect {
    GATE    = 0,
    IS_OPEN = false,

    SERVER  = "",
    ROLE    = "",
    VISITOR = "",

    PROTO   = "",
    PORT    = 0,
    NODELAY = false,
    PRELOAD = 0,
    MAXCLIENT = 0,
}
