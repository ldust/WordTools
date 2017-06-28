# Created by yaochunhui on 15/2/17.
cc        = require './CocosFuncs'

zim = {}

# utilities from cocos2d-x
zim.each = cc.each
zim.extend = cc.extend
zim.isFunction = cc.isFunction
zim.isNumber = cc.isNumber
zim.isString = cc.isString
zim.isArray = cc.isArray
zim.isUndefined = cc.isUndefined
zim.isObject = cc.isObject
zim.isFunction = cc.isFunction
zim.isBoolean = (x)-> typeof x == "boolean"
zim.path = cc.path
zim.formatStr = cc.formatStr
zim.degreesToRadians = cc.degreesToRadians
zim.radiansToDegrees = cc.radiansToDegrees
zim.lerp = cc.lerp
zim.rand = cc.rand
zim.randomMinua1To1 = cc.randomMinus1To1
zim.random0To1 = cc.random0To1
zim.clamp = cc.clampf


zim.hash = (str) ->
    #copy from https://github.com/darkskyapp/string-hash
    hash = 5381
    i    = str.length
    while i
        hash = (hash * 33) ^ str.charCodeAt(--i)
    return hash >>> 0

zim.pad = (n, width, z) ->
    z ?= '0'
    n = n + ''
    if n.length >= width
        n
    else
        new Array(width - n.length + 1).join(z) + n

zim.mergeBoolean = (a, b) -> return !!a || !!b

zim.mergeArray = (arr1, arr2, equalFunc = ((a, b) -> a is b), sort = false, sortFunc = ((a, b) -> a >= b) ) ->
    if not arr1?
        return arr2 or []
    if not arr2?
        return arr1 or []
    for item1 in arr1
        include = false
        for item2 in arr2
            if equalFunc(item1, item2)
                include = true
                break
        if not include
            arr2.push item1
    if sort
        arr2.sort(sortFunc)
    return arr2


zim.sortBy = (arr, para)->
    sortFunc = (x, y) -> return (x - y)
    if zim.isFunction(para)
        sortFunc = (x, y)->
            return para(x) - para(y)
    else if zim.isString(para)
        sortFunc = (x, y)->
            if x[para]? and y[para]?
                return x[para] - y[para]
            else if x[para]?
                return 1
            else if y[para]?
                return -1
            else
                return 0
    arr.sort sortFunc
    return arr

zim.values = (obj)->
    ret = []
    if !zim.isObject(obj)
        return []
    else
        for key, value of obj
            ret.push value
        return ret

#arr1 = [1, 2, 3], arr2 = [1, 2] ret = true
#arr1 = [1, 2, 3], arr2 = [1, 4] ret = false
zim.arrayInclude = (arr1, arr2)->
    for item2 in arr2
        include = false
        for item1 in arr1
            if zim.isArray(item1) and zim.isArray(item2)
                if zim.arrayInclude(item1, item2)
                    include = true
                    break
            else if not (zim.isArray(item1)) and not (zim.isArray(item2)) and (zim.isObject(item1)) and (zim.isObject(item2))
                if zim.objInclude(item1, item2)
                    include = true
                    break
            else if item1 is item2
                include = true
                break
        if not include
            return false
    return true

zim.arrayEqualNoOrder = (arr1, arr2)->
    return zim.arrayInclude(arr1, arr2) and (arr1.length is arr2.length)

#arr1 = {'x': 1, 'y': 2}, arr2 = {'x' : 1} ret = true
#arr1 = {'x': 1, 'y': 2}, arr2 = {'x' : 1, 'z' : 3} ret = false
zim.objInclude = (obj1, obj2)->
    for key, value of obj2
        if obj1[key]?
            if zim.isArray(obj1[key]) and zim.isArray(obj2[key])
                if not zim.arrayInclude(obj1[key], obj2[key])
                    return false
            else if not (zim.isArray(obj1[key])) and not (zim.isArray(obj2[key])) and zim.isObject(obj1[key]) and zim.isObject(obj2[key])
                if not zim.objInclude(obj1[key], obj2[key])
                    return false
            else if obj1[key] isnt obj2[key]
                return false
        else
            return false
    return true

#arr1 = {'x': 1, 'y': [1, 2, 3]]}, arr2 = {'x' : 1, 'y': [1]} ret = true
#arr1 = {'x': 1, 'y': [1, 2, 3]]}, arr2 = {'x' : 1, 'y': [1, 4]} ret = false
zim.include = (obj1, obj2)->
    if zim.isArray(obj1) and zim.isArray(obj2)
        return zim.arrayInclude(obj1, obj2)
    else if not (zim.isArray(obj1)) and not (zim.isArray(obj2)) and zim.isObject(obj1) and zim.isObject(obj2)
        return zim.objInclude(obj1, obj2)
    else if obj1? and obj2? and obj1 is obj2
        return true
    else    
        return false

zim.findIndex = (dataArray, obj) ->
    return -1 unless zim.isArray(dataArray)
    len = dataArray.length
    for i in [0...len]
        if zim.isObject(dataArray[i]) and zim.isObject(obj)
            if zim.include(dataArray[i], obj)
                return i
        else if !zim.isObject(dataArray[i]) and !zim.isObject(obj)
            if dataArray[i] is obj
                return i
    return -1


#typeof data is map
zim.map = (data, func)->
    ret = []
    return [] unless data? and zim.isFunction(func)
    for key, value of data
        ret.push func(value, key)
    return ret
  
zim.merge = (obj, objExt) ->
    for key, value of objExt
        if typeof value isnt 'object' or not obj[key]?
            obj[key] = value
        else if objExt[key]?
            zim.merge(obj[key], objExt[key])
    return

zim.isValidNumber = (v) ->
    zim.isNumber(v) and !isNaN(v) and isFinite(v)

zim.validInt = (v) ->
    num = parseInt(v)
    return if not isNaN(num) and isFinite(v) then num else null

zim.validBool = (v) ->
    if zim.isBoolean(v) then v else null

zim.randomInt = (min, max)->
    Math.floor(Math.random() * (max - min + 1)) + min

zim.randomRange = (min, max)->
    Math.random() * (max - min) + min

zim.overrideWithSuper = (obj, methodName, func) ->
    oldFunc = obj[methodName];
    obj[methodName] = ->
        if (cc.isFunction(oldFunc))
            oldFunc.apply(obj, arguments)
        func.apply(obj, arguments)

zim.encodeByteArray = (arr) ->
    chars = (
        for byte in arr
            if byte < 16 then "0" + byte.toString(16) else byte.toString(16)
    )
    chars.join("")

zim.decodeByteArray = (str) ->
    arr = new Uint8Array(str.length / 2)
    for i in [0..(str.length / 2)]
        arr[i] = parseInt(str.substring(i * 2, i * 2 + 2), 16)
    return arr

zim.fract = (x)-> if x >= 0 then x - Math.floor(x) else x - Math.ceil(x)

zim.arraySwap = (arr, index1, index2) ->
    if index1 isnt index2
        tmp = arr[index1]
        arr[index1] = arr[index2]
        arr[index2] = tmp

zim.arrayShuffle = (array, randomFunc = Math.random) ->
    m = array.length

    while m isnt 0
        i = Math.floor(randomFunc() * (--m))
        t = array[m]
        array[m] = array[i]
        array[i] = t

    array

zim.arrayChunk = (array, chunkSize) ->
    return array unless array?
    result = []
    result.push(array.slice(i, i + chunkSize)) for i in [0...array.length] by chunkSize
    result

zim.arrayBack = (array) ->
    array[array.length - 1] if array?

zim.flatten = (array) ->
    result = []
    for a in array
        if zim.isArray(a)
            result = result.concat(zim.flatten(a))
        else
            result.push a
#        result = result.concat(a)
    result

zim.randomItem = (array, n) ->
    return unless zim.isArray(array)
    if n? and n isnt 1
        zim.arrayShuffle(array).length = Math.min(n, array.length)
        array
    else
        array[zim.randomInt(0, array.length - 1)]

# bigger is better
zim.selectByPriority = (priorityMap, num, result, reverse) ->
    over = false
    dir = if reverse is true then 1 else -1
    for arr in priorityMap by dir
        continue unless arr?
        break if over is true
        r = zim.randomItem(arr, num)
        if num? and num isnt 1
            for one in r
                result.push(one)
                if result.length >= num
                    over = true
                    break
        else
            result.push(r)
            break if result.length >= num
    result

zim.arrayRemoveDuplicates = (ar) ->
    if ar.length == 0
        return []
    res = {}
    res[ar[key]] = ar[key] for key in [0..ar.length-1]
    value for key, value of res

zim.arrayEqual = (a, b) ->
    a.length is b.length and a.every (elem, i) -> elem is b[i]

zim.isEqual = (a, b) ->
    if zim.isObject(a) and zim.isObject(b)
        for x of a
            return false unless zim.isEqual(a[x], b[x])
        # Simply iterate on b again to cover cases b has more properties than a.
        for x of b
            return false unless zim.isEqual(a[x], b[x])
        return true
    else
        return a == b

zim.error = (msg) -> throw new Error(msg)

zim.makeArray = (val, len) ->
    arr = new Array(len)
    for i in [0...len] then arr[i] = val

zim.randomIndexByProbability = (weights, random) ->
    sum = weights.reduce(
        (x, y)-> x + y
        0
    )
    val = random * sum
    for weight, i in weights
        if (val < weight)
            return i
        val -= weight
    -1

zim.selectByProbability = (items, weights, random = Math.random()) ->
    len = items.length
    weightLen = weights.length
    weights =
        if (len < weightLen)
            weights.slice(0, len)
        else if (len > weightLen)
            weights.concat(zim.makeArray(1, len - weightLen))
        else
            weights
    index = zim.randomIndexByProbability weights, random
    items[index]

zim.loopUntil = (func, limitTimes = 100)->
    val = func()
    times = 1
    while (!val && times < limitTimes)
        val = func()
        times++
    if times == limitTimes then zlog "timeout"
    val

if (typeof String.prototype.startsWith != 'function')
    String.prototype.startsWith = (str) ->
        return this.slice(0, str.length) == str

if (typeof String.prototype.endsWith != 'function')
    String.prototype.endsWith = (str) ->
        return this.slice(-str.length) == str;

if (1000).toLocaleString() == "1'000"
    oldLocaleString = Number.prototype.toLocaleString
    Number.prototype.toLocaleString = ->
        str = oldLocaleString.call(@)
        str.replace(/'/g, ',')

zim.diffHour = (a, b) ->
    Math.abs(a - b) / 3600000

###
    仅用于复制数据
    不能存在循环引用（否则会死循环）
    最好不要有函数、正则表达式等特殊对象
###
zim.deepClone = (source) ->
    if zim.isArray source
        cloned = new Array(source.length)
        cloned[i] = arguments.callee(value) for value, i in source
    else if zim.isObject source
        cloned = {}
        cloned[key] = arguments.callee(value) for own key, value of source
    else
        cloned = source
    cloned

zim.sortByKey = (collection, key) ->

    compareFunc = (item1, item2) ->
        value1 = item1[key]
        value2 = item2[key]
        if value1 > value2 then 1 else if value1 < value2 then -1 else 0

    collection.sort(compareFunc)

zim.timeStampToString = (timeStamp) ->
    date = new Date(timeStamp*1000)
    hour = date.getHours()
    minute = date.getMinutes()
    second = date.getSeconds()
    year = date.getFullYear()
    month = date.getMonth() + 1
    day = date.getDate()
    isAm = true
    if hour >= 12
        isAm = false
        if hour > 12
            hour -= 12

    timestr = month + "/" + (if day<10 then "0" else "") + day + "/" + year + " " + hour + ":" + (if minute<10 then "0" else "") + minute
    if isAm then timestr += "AM" else timestr += "PM"
    timestr

zim.toThousands = (num) ->
    neg = num < 0
    num = Math.abs(num)
    num = (num or 0).toString()
    result = ''
    while (num.length > 3)
        result = ',' + num.slice(-3) + result
        num = num.slice(0, num.length - 3)
    result = num + result
    if neg then return "-" + result else return result
    
#  like: 20151001 -> 1443628800
zim.dateValueToStamp = (dateValue) ->
    day = dateValue % 100
    dateValue = dateValue // 100
    month = dateValue % 100 - 1
    year = dateValue // 100
    date = new Date(year, month, day)
    date.getTime() // 1000

zim.zTextObject = (obj) ->
    newObj = zim.deepClone obj
    for own key, value of newObj
        continue unless zim.isString value
        continue unless value.substring(0, 3) is "TID"
        newObj[key] = zText value, value
    newObj

zim.getYMDString = (date) ->
    year = String(date.getFullYear())
    month = String(date.getMonth() + 1)
    day = String(date.getDate())
    if month.length < 2 then month = "0#{month}"
    if day.length < 2 then day = "0#{day}"
    "#{year}/#{month}/#{day}"

zim.getYMString = (date) ->
    year = String(date.getFullYear())
    month = String(date.getMonth() + 1)
    if month.length < 2 then month = "0#{month}"
    "#{year}/#{month}"

zim.isNewDay = (time1, time2) ->
    if time1 is 0 or time2 is 0
        return true
    time1Obj = new Date(time1)
    time2Obj = new Date(time2)
    day1 = time1Obj.getDate()
    day2 = time2Obj.getDate()
    month1 = time1Obj.getMonth()
    month2 = time2Obj.getMonth()
    year1 = time1Obj.getFullYear()
    year2 = time2Obj.getFullYear()
    if year1 is year2 and month1 is month2 and day1 is day2
        return false
    else
        return true

zim.contain = (wordA, wordB)->
    return false if wordA is wordB
    countByC = {}
    for c in wordA
        countByC[c] ?= 0
        countByC[c] += 1
    for c in wordB
        countByC[c] ?= 0
        return false if countByC[c] < 1
        countByC[c] -= 1
    return true

zim.equalWord = (w1, w2)->
    arr1 = w1.split("")
    arr2 = w2.split("")
    for c in arr1
        if c in arr2
            index = arr2.indexOf(c)
            arr2.splice(index, 1)
        else
            return false
    return false if arr2.length isnt 0
    return true

zim.empty = (s)-> "\t\r\n ".indexOf(s) isnt -1

module.exports = zim
