async   = require 'async'
argv    = require('yargs').argv
fs      = require 'fs'
parse   = require('csv').parse
zim     = require './ZimUtils'
_       = require 'lodash'
genCross = require './gen_cross'
random  = require './ZimConsistentRandom'

cmd     = argv.c
mode    = argv.m

LEVEL_RULES_PATH        = "./tables/output_rules.csv"
RAW_BIG_WORD_LISH_PATH  = "./tables/big.csv"
RAW_WORD_FILE_PATH      = "./tables/words.csv"

mode ?= "word"
CHALLENGE_LISH_PATH     = "./tables/challenge_puzzle_#{mode}.json"

ChallengeTool           = require "./gen_challenge"

Dict                    = {}
Hz                      = {}
PATTERN_INDEX           = 3
ANS_START_INDEX         = 4
EXTRA_START_INDEX       = 100

parseCsv = (path, callback)->
    data = fs.readFileSync path, {encoding: "utf8"}
    parse data, {delimiter: ','}, (error, table)->
        throw new Error(error) if error?
        callback(table)

tool = 
    cmp: (a, b) ->
        sub = b.length - a.length
        return sub unless sub is 0
        return -1 if a < b
        return 1 if a > b
        return 0

    cmpup: (a, b) ->
        sub = a.length - b.length
        return sub unless sub is 0
        return -1 if a < b
        return 1 if a > b
        return 0

    prepareLevel: (callback)->
        console.log "[Prepare Level]"
        parseCsv RAW_WORD_FILE_PATH, (table) ->
            ## Dict = map(wordLen, words) 
            for row, index in table
                continue if index is 0
                for cell in row
                    key = cell.length
                    continue if key > 7 or key <= 0
                    Dict[key] ?= []
                    Dict[key].push cell.toLowerCase()

            for maxLen in [7 .. 2]
                result = []
                console.log "=====> prepareing level of max letter #{maxLen}"
                ignoreIndex = []
                for word, index in Dict[maxLen]
                    continue if index in ignoreIndex
                    ret = []
                    for tryCount in [maxLen .. 2]
                        break unless Dict[String(tryCount)]?
                        for w, i in Dict[String(tryCount)]
                            continue if w is word
                            if zim.contain(word, w)
                                if tryCount is maxLen
                                    ignoreIndex.push i
                                ret.push w

                    if 1 <= ret.length <= 15
                        ret.unshift word
                        result.push ret

                fs.writeFileSync "./tables/_tmp_#{maxLen}-0.json", JSON.stringify result
            callback?()

    moreLevel: (callback)->
        nextCheck = [7]
        for wordLen in [2 .. 7]
            console.log "=====> prepareing more level of max letter #{wordLen}"
            mainCache = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-0.json", {encoding: "utf8"}
            more = []
            for mainPuzzle, mainIndex in mainCache
                wordMain = mainPuzzle[0]
                for tryPuzzle, tryIndex in mainCache
                    continue if tryIndex <= mainIndex
                    wordTry = tryPuzzle[0]
                    continue if wordTry in mainPuzzle
                    diff = zim.diffWordLetter(wordMain, wordTry)
                    if diff.length is 1
                        more.push zim.mergeArray(mainPuzzle.concat(), tryPuzzle.concat()).sort(tool.cmp)


            if wordLen in nextCheck
                for mainPuzzle, mainIndex in mainCache
                    wordMain = mainPuzzle[0]
                    tryCache = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen - 1}-0.json", {encoding: "utf8"}
                    for tryPuzzle in tryCache
                        wordTry = tryPuzzle[0]
                        continue if wordTry in mainPuzzle
                        diff = zim.diffWordLetter(wordMain, wordTry)
                        if diff.length is 1
                            more.push zim.mergeArray(mainPuzzle.concat(), tryPuzzle.concat()).sort(tool.cmp)

            fs.writeFileSync "./tables/_tmp_#{wordLen}-1.json", JSON.stringify more
        callback?()

    removeRepeat: (callback)->
        console.log "[Repeat check]"
        for wordLen in [2 .. 7]
            for i in [0 .. 1]
                console.log "=====> check repeat of #{wordLen}-#{i}"
                cache = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-#{i}.json", {encoding: "utf8"}
                if cache.length > 1
                    for index in [cache.length - 1 .. 0]
                        main = cache[index]
                        repeat = true
                        for cmInd in [0 ... index]
                            cmp = cache[cmInd]
                            continue if cmp.length isnt main.length
                            for w in cmp
                                unless w in main
                                    repeat = false
                                    break
                            break if repeat = false
                        if repeat
                            cache.splice(index, 1)

                fs.writeFileSync "./tables/_tmp_#{wordLen}-#{i}.json", JSON.stringify cache
        callback?()

    findExtraInBigList: (bigMap, words) ->
        chars = tool.allChars(words).sort()
        ret = []
        range = [words[words.length - 1].length, words[0].length]
        for i in [0 .. range[1]]
            big = bigMap[i]
            continue unless big?
            for w in big
                continue unless range[0] <= w.length <= range[1]
                continue if _.includes(words, w)
                continue unless tool._in(chars.join(""), w)
                ret.push w
        ret = _.uniq(ret)
        return ret

    removeNonContinuous : (callback)->
        console.log "[Remove non-continuous]"
        for wordLen in [2 .. 7]
            for p in [0 .. 1]
                console.log("=====> checking #{wordLen}-#{p}")
                cache = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-#{p}.json", {encoding: "utf8"}
                for puzzle, index in cache by -1
                    next = wordLen - 1
                    continuous = true
                    for w in puzzle
                        if w.length is next
                            break
                        else if w.length < next
                            continuous = false
                            break
                    unless continuous
                        cache.splice(index, 1)
                fs.writeFileSync "./tables/_tmp_#{wordLen}-#{p}.json", JSON.stringify cache
        callback?()

    fillExtra: (callback)->
        console.log "[Add extra word]"
        parseCsv RAW_BIG_WORD_LISH_PATH, (table) ->
            big = {}
            for row in table
                word = row[0]
                continue if word.length < 2 or word.length > 8
                key = word.length
                big[key] ?= []
                big[key].push word.toLowerCase()

            for wordLen in [2 .. 7]
                for p in [0..1]
                    console.log("=====> adding extra to word len #{wordLen}-#{p}")
                    cache = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-#{p}.json", {encoding: "utf8"}
                    for puzzle, index in cache
                        extra = tool.findExtraInBigList(big, puzzle)
                        puzzle.extra = extra.sort(tool.cmp)
                        chars = tool.allChars(puzzle)
                        cache[index] = { index, chars, puzzle, extra }
                    fs.writeFileSync "./tables/_tmp_#{wordLen}-#{p}-candidate.json", JSON.stringify cache
            callback?()
        return

    mapWordHZ: (callback)->
        parseCsv "./config/hz.csv", (table) ->
            for row, index in table
                Hz[row[0]] = index
            tool.hz = JSON.parse fs.readFileSync "./config/hz.json", {encoding: "utf8"}
            tool.len = JSON.parse fs.readFileSync "./config/len.json", {encoding: "utf8"}
            callback?()

    createLevels: (callback)->
        cabdidateCache = {}
        for wordLen in [2 .. 7]
            cabdidateCache["#{wordLen}-0"] = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-0-candidate.json", {encoding: "utf8"}
            cabdidateCache["#{wordLen}-1"] = JSON.parse fs.readFileSync "./tables/_tmp_#{wordLen}-1-candidate.json", {encoding: "utf8"}

        parseCsv LEVEL_RULES_PATH, (table) ->
            config = tool._parseConfig(table)
            mapMaxLenToWordCount = {}
            levels = []
            console.log "[Createing Level]"
            for id, cfg of config
                process.stdout.write("=====> create level #{id}\n");
                if cfg.letter_max > cfg.word_length_max + 1 or cfg.letter_max < cfg.word_length_max
                    console.log "[Error]: #{id}: cfg.letter_max error"
                else if cfg.letter_min > cfg.word_length_max + 1 or cfg.letter_max < cfg.word_length_max
                    console.log "[Error]: #{id}: cfg.letter_min error"
                else
                    cache = cabdidateCache["#{cfg.word_length_max}-0"]
                    randFun = random(100).random
                    match = null
                    indexTryed = []
                    for i in [0 ... 500]
                        index = Math.floor(randFun() * cache.length)
                        tryCount = 0
                        while index in indexTryed and tryCount < 100
                            index = Math.floor(randFun() * cache.length)
                            tryCount++
                        indexTryed.push index
                        puzzle = cache[index]
                        ret = tool._createLevelByCfg(puzzle, cfg)
                        if ret
                            difficulty = Math.floor(tool._calcDifficulty(ret.puzzle))
                            ret.difficulty = difficulty
                            if cfg.difficulty_min <= difficulty <= cfg.difficulty_max
                                match = {ret, index, difficulty, success: true}
                                break
                            else
                                if match
                                    if Math.abs(match.difficulty - cfg.difficulty_max) > Math.abs(difficulty - cfg.difficulty_max)
                                        match = {ret, index, difficulty, success: false}
                                else
                                    match = {ret, index, difficulty, success: false}

                    if match
                        match.ret.success = match.success
                        match.ret.id = id
                        levels.push match.ret
                        cache.splice match.index, 1
                        unless match.success
                            console.log "[WARNING] level:#{id} need difficulty:#{cfg.difficulty_max} but use #{match.difficulty}"
                    else
                        console.log "[ERROR] level:#{id} no match level"

            tool._saveLevels(levels)
            callback?()
            return

    _saveLevels: (levels)->
        #====
        fs.writeFileSync "./output/level.json", JSON.stringify levels
        #====
        CONFIGS = 
            id      : 0
            difficulty : 1
            success : 2
            extCount: 3
            size    : 4
            type    : 5
            ans     : 6
            ext     : 15

        COLUMES     = 28

        titles = []
        titles.length = COLUMES
        for name, start of CONFIGS
            titles[start] = name

        wstream = fs.createWriteStream "./output/level.csv"
        wstream.write titles.join(",") + "\n"
        for level, index in levels
            row = []
            row.length = COLUMES
            row[CONFIGS.id] = index + 1
            row[CONFIGS.difficulty] = level.difficulty
            row[CONFIGS.success] = if level.success then 1 else 0
            row[CONFIGS.extCount] = level.add
            row[CONFIGS.size] = level.size
            row[CONFIGS.type] = (level.puzzle.map (word)-> word.length + '').join('')
            for ans, ansI in level.puzzle
                row[CONFIGS.ans + ansI] = ans
            for ext, extI in level.ext
                row[CONFIGS.ext + extI] = ext
            wstream.write row.join(",") + "\n"
        wstream.end()

    _createLevelByCfg: (level, cfg)->
        puzzleOrigin = level.puzzle.concat()
        ## rm word length not match
        puzzleFrequencyUp = []
        for w, i in puzzleOrigin by -1
            if w.length < cfg.word_length_min
                puzzleOrigin.splice(i, 1)
            else if Hz[w] > cfg.word_frequency
                puzzleFrequencyUp.push w
                puzzleOrigin.splice(i, 1)

        if puzzleOrigin.length < cfg.word_num
            return

        puzzle = []
        for n in [cfg.word_length_min .. cfg.word_length_max]
            found = false
            for w, i in puzzleOrigin by -1
                if w.length is n
                    puzzle.push w
                    puzzleOrigin.splice(i, 1)
                    found = true
                    break
            unless found
                return

        randFun = random(1000).random
        while puzzle.length < cfg.word_num and puzzleOrigin.length > 0
            index = Math.floor(randFun() * puzzleOrigin.length)
            puzzle.push puzzleOrigin[index]
            puzzleOrigin.splice(index, 1)

        ext = level.extra.concat(puzzleOrigin, puzzleFrequencyUp)
        chars = tool.allChars(puzzle)
        if chars.length is cfg.word_length_max or chars.length is cfg.word_length_max + 1
            size = cfg.word_length_max + 2
            cross = genCross(puzzle, ext, size, size)
            if cross
                puzzle.sort tool.cmpup
                add = cross.add.length
                ext = cross.add.concat(cross.ext)
                return {chars, puzzle, ext, size, add}
            else 
                null
        else
            null

    _getHzRatio: (word)->
        hz = Hz[word] or 0
        for item in tool.hz
            if hz <= item[0]
                return item[1]
        return item[1]

    _calcDifficulty: (words)->
        score = 0
        for w in words
            score += tool._getHzRatio(w) * tool.len[w.length]
        score

    _parseConfig: (table)->
        keys = []
        level_config = {}
        for row, i in table
            if i is 0
                keys = row
            else if i in [1,2]
                continue
            else
                obj = {}
                for cell, j in row
                    key = keys[j]
                    if key is "name"
                        obj[key] = cell
                    else
                        obj[key] = parseInt(cell)
                level_config[obj.id] = obj
        level_config

    allChars: (words) ->
        charMaps = []
        for word in words
            mp = {}
            for c in word
                mp[c] ?= 0
                mp[c]++
            for c, count of mp
                charMaps[c] ?= 0
                charMaps[c] = Math.max(charMaps[c], count)

        ret = []
        for c, count of charMaps
            for i in [0...count]
                ret.push c
        return ret

    _in: (big, small) ->
        for c in small
            index = big.indexOf(c)
            if index is -1
                return false
            else
                big = big.replace(c, "")
        return true

if cmd is "run"
    async.series [ 
        tool.prepareLevel, 
        tool.moreLevel, 
        tool.removeRepeat,
        tool.removeNonContinuous,
        tool.fillExtra,
        tool.mapWordHZ,
        tool.createLevels
    ], (error, result)->
else if cmd is "prepare"
    async.series [ 
        tool.prepareLevel, 
        tool.moreLevel, 
        tool.removeRepeat,
        tool.removeNonContinuous,
        tool.fillExtra
    ], (error, result)->
else if cmd is "level"
    async.series [ 
        tool.mapWordHZ,
        tool.createLevels
    ], (error, result)->
else
    str = """
    ======= tables
    === raw_big_word_list.csv -> 大词库
    === raw_level_words.csv   -> 小词库
    === output_rules.csv      -> 关卡规则
    === hz.csv                -> 词频表

    ======= config
    === hz.json               -> 词频难度配置
    === len.json              -> 词长难度配置

    ======= output
    === level.json            -> json 格式关卡
    === level.csv             -> csv 格式关卡

    coffee tool_cross.coffee -c run
        整体执行生成关卡的逻辑

    coffee tool_cross.coffee -c prepare
        预处理关卡，当大、小词库变化时需要运行

    coffee tool_cross.coffee -c level
        随机关卡，当配置变化时需要运行

    """
    console.log str
