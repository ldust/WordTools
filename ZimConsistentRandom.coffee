# Created by yaochunhui on 15/4/15.
module.exports = (seed) ->
    # [0, 1)
    random : ->
        x = Math.sin(seed++) * 10000
        x - Math.floor(x)

    getSeed : -> seed
    setSeed : (s) -> seed = s
