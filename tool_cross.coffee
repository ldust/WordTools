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
PUZZLE_FILE_PATH        = "./output/level.csv"

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

    cmpRepeat: (a, b) ->
        sub = a.length - b.length
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
                lowerWord = row[0].toLowerCase()
                Hz[lowerWord] = index
            tool.hz = JSON.parse fs.readFileSync "./config/hz.json", {encoding: "utf8"}
            tool.len = JSON.parse fs.readFileSync "./config/len.json", {encoding: "utf8"}
            callback?()

    _controlLevels: (match, levels, cache, id)->
        if zim.isArray(match)
            for m in match
                m.ret.levelId = id
                levels.push m.ret
            return true
        else
            match.ret.levelId = id
            levels.push match.ret
            cache.splice match.index, 1
            return match.success

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
                if cfg.letter_max > cfg.word_length_max + 1
                    console.log "[Error]: #{id}: letter_max(#{cfg.letter_max}) can't bigger than cfg.word_length_max(#{cfg.word_length_max}) + 1"
                else if cfg.letter_max < cfg.word_length_max
                    console.log "[Error]: #{id}: letter_max(#{cfg.letter_max}) can't smaller than cfg.word_length_max(#{cfg.word_length_max})"
                else
                    cache = cabdidateCache["#{cfg.word_length_max}-0"]
                    match = tool._getMatchFromCache(cache, cfg)
                    if match
                        success = tool._controlLevels(match, levels, cache, id)
                        unless success
                            console.log "[WARNING]: #{id} need difficulty:#{cfg.difficulty_max} but use #{match.difficulty}"
                    else
                        cacheMore = cabdidateCache["#{cfg.word_length_max}-1"]
                        matchMore = tool._getMatchFromCache(cacheMore, cfg)
                        if matchMore
                            success = tool._controlLevels(matchMore, levels, cacheMore, id)
                            if success
                                console.log "[WARNING]: #{id} use match from 'more table'"
                            else
                                console.log "[WARNING]: #{id} use match from 'more table' and need difficulty:#{cfg.difficulty_max} but use #{matchMore.difficulty}"
                        else
                            console.log "[WARNING]: #{id}  use non continuous func"
                            cache = cabdidateCache["#{cfg.word_length_max}-0"]
                            match = tool._getMatchFromCache(cache, cfg, true)
                            if match
                                success = tool._controlLevels(match, levels, cache, id)
                                unless success
                                    console.log "[WARNING]: #{id} use non continuous need difficulty:#{cfg.difficulty_max} but use #{match.difficulty}"
                            else
                                cacheMore = cabdidateCache["#{cfg.word_length_max}-1"]
                                matchMore = tool._getMatchFromCache(cacheMore, cfg, true)
                                if matchMore
                                    success = tool._controlLevels(matchMore, levels, cacheMore, id)
                                    if success
                                        console.log "[WARNING]: #{id} use non continuous match from 'more table'"
                                    else
                                        console.log "[WARNING]: #{id} use non continuous match from 'more table' and need difficulty:#{cfg.difficulty_max} but use #{matchMore.difficulty}"
                                else
                                    console.log "[error]: #{id} has no match"
            tool._saveLevels(levels)
            callback?()
            return

    _getMatchFromCache: (cache, cfg, useNonCon)->
        randFun = random(100).random
        match = null
        indexTryed = []
        findCount = 0
        matchTable = []
        for i in [0 ... cache.length]
            index = Math.floor(randFun() * cache.length)
            tryCount = 0
            while index in indexTryed and tryCount < 100
                index = Math.floor(randFun() * cache.length)
                tryCount++
            indexTryed.push index
            puzzle = cache[index]
            ret = tool._createLevelByCfg(puzzle, cfg, useNonCon)
            if ret
                difficulty = Math.floor(tool._calcDifficulty(ret.puzzle))
                ret.difficulty = difficulty
                if cfg.difficulty_min <= difficulty <= cfg.difficulty_max
                    match = {ret, index, difficulty, success: true}
                    cache.splice(index, 1)
                    matchTable.push match
                    match = null
                    findCount++
                    if findCount > 5
                        break
                    else
                        continue
                else
                    if match
                        if Math.abs(match.difficulty - cfg.difficulty_max) > Math.abs(difficulty - cfg.difficulty_max)
                            match = {ret, index, difficulty, success: false}
                    else
                        match = {ret, index, difficulty, success: false}
        if match
            match.ret.success = match.success
            match.ret.id = cfg.id
            return match
        else if  matchTable.length isnt 0
            for match in matchTable
                match.ret.sucess = match.sucess
                match.ret.id = cfg.id
            return matchTable
        else
            null

    _saveLevels: (levels)->
        outputPath = "./output"
        unless fs.existsSync(outputPath)
            fs.mkdirSync(outputPath)

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
            if level
                row[CONFIGS.id] = level.levelId
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

    _filterExtWordWithLength: (ext, min, max)->
        for word, index in ext
            if word.length < min or word.length > max
                ext[index] = 0
        newExt = []
        for word in ext
            if word isnt 0
                newExt.push word
        return newExt

    _createLevelByCfg: (level, cfg, useNonCon)->
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
            # if cfg.id is 10
            #     console.log "11111 #{puzzleOrigin.length} #{cfg.word_num}"
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
                if useNonCon
                    return if n is cfg.word_length_max
                    return if n is cfg.word_length_min
                    targetN = n - 1
                    reFound = false
                    while targetN >= cfg.word_length_min
                        for w1, i1 in puzzleOrigin by -1
                            if w1.length is targetN
                                puzzle.push w1
                                puzzleOrigin.splice(i1, 1)
                                reFound = true
                                break
                        if reFound
                            break
                        else
                            targetN--
                    unless reFound
                        return
                else
                    return

        randFun = random(1000).random
        while puzzle.length < cfg.word_num and puzzleOrigin.length > 0
            index = Math.floor(randFun() * puzzleOrigin.length)
            puzzle.push puzzleOrigin[index]
            puzzleOrigin.splice(index, 1)

        ext = level.extra.concat(puzzleOrigin, puzzleFrequencyUp)
        ext = tool._filterExtWordWithLength(ext, cfg.word_length_min, cfg.word_length_max)
        chars = tool.allChars(puzzle)
        if chars.length is cfg.word_length_max or chars.length is cfg.word_length_max + 1
            size = cfg.word_length_max + 2
            puzzle.sort tool.cmpup
            cross = genCross(puzzle, ext, size, size)
            if cross
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

    _isArrayIncludeEachOther: (arr1, arr2)->
        for item1 in arr1
            if item1 in arr2
                return true
        return false

    _toUpperCase: (word)->
        wordUpperCase = ""
        for c in word
            wordUpperCase += c if c is "ß"
            wordUpperCase += c.toUpperCase() if c isnt "ß"
        return wordUpperCase

    _handleCsv: (table) ->
        outPut = {}
        for row, column in table
            id = row[0]
            continue if id[0] is "#"
            continue if column is 0
            newRow = {}
            outPut[id] = newRow
            pattern = row[5]
            bonus = 0
            newRow.bn = parseInt(bonus) or 0
            newRow.tp = pattern
            newRow.ans = []
            newRow.add = []
            for item, index in row
                continue if zim.empty(item)
                item = item.trim()
                if item.match(/\s/img)?
                    throw new Error("Word Contain SpaceChar Error In Row #{column}")
                if 0 <= index - 6 < pattern.length
                    newRow.ans.push @_toUpperCase(item)
                else if index - 6 >= pattern.length
                    newRow.add.push @_toUpperCase(item)
            newRow.ans.sort(@cmpRepeat)
            for item, index in newRow.ans
                if item.length isnt parseInt(pattern[index])
                    throw new Error("item not fix pattern #{id}")

            if newRow.ans.length is 0 or (newRow.ans.length isnt pattern.length)
                throw new Error("Level Table Error In Row #{column}")

            if @_isArrayIncludeEachOther(newRow.ans, newRow.add)
                throw new Error("Level Table Error In Row #{column}: Item in Ans is also in Add")

        return outPut

    _getPuzzleData: (table)->
        data = @_handleCsv(table)
        return data

    isSameArr: (arr1, arr2)->
        for item in arr1
            if item not in arr2
                return false
        for item in arr2
            if item not in arr1
                return false
        return true

    isSameLevel: (puzzle1, puzzle2)->
        ans1 = puzzle1.ans
        ans2 = puzzle2.ans
        return @isSameArr(ans1, ans2)

    getAllSameLevel: (table)->
        console.log("check repeat")
        data = @_getPuzzleData(table)
        sameLevelArr = []

        hasFoundArr = []

        for level, puzzle of data
            sameLevel = []
            hasFoundArr.push level
            sameLevel.push level

            for levelCmp ,puzzleCmp of data
                continue if levelCmp in hasFoundArr
                if not (data[levelCmp]? and puzzle?)
                    console.log(data[levelCmp], puzzle)
                if @isSameLevel(data[levelCmp], puzzle)
                    hasFoundArr.push levelCmp
                    sameLevel.push levelCmp
            if sameLevel.length > 1
                sameLevelArr.push(sameLevel)

        for sameLevel in sameLevelArr
            console.log("#{sameLevel}")
        return sameLevelArr

    findSameLevel: ->
        parseCsv(PUZZLE_FILE_PATH, @getAllSameLevel.bind(@))

    printAllChars: ->
        parseCsv PUZZLE_FILE_PATH, (table) ->
            data = tool._getPuzzleData(table)
            wstream = fs.createWriteStream PUZZLE_FILE_PATH + ".info.csv", { encoding: 'utf8' }
            wstream.write '\ufeff'
            lvmap = {}
            for level, puzzle of data
                chars = tool.allChars(puzzle.ans).sort()
                charsStr = chars.join("")
                wstream.write level + "," + charsStr + "\n"
                lvmap[charsStr] ?= { count:0, lv: [] }
                lvmap[charsStr].count++
                lvmap[charsStr].lv.push level
            for key, value of lvmap
                continue unless value.count > 1
                console.log "#{key} : #{JSON.stringify value.lv}"
            wstream.end()
        return

    showRepeat: ->
        parseCsv PUZZLE_FILE_PATH, (table) ->
            data = tool._getPuzzleData(table)
            puzzleCount = Object.keys(data).length

            #example:["UP"] = {[2,9,16], [9,19] }
            wordGroup = {}

            for level, puzzle of data
                wordMap = {}
                for word in puzzle.ans
                    wordMap[word] = [level]

                for num in [1..14]
                    nextLevelNum = Number(level) + Number(num)
                    nextLevel = nextLevelNum.toString()
                    if nextLevelNum >= puzzleCount
                        break

                    nextPuzzle = data[nextLevel]
                    for nextWord in nextPuzzle.ans
                        if wordMap[nextWord]
                            wordMap[nextWord].push(nextLevel)

                for word, levels of wordMap
                    if levels.length < 2
                        break
                    if !wordGroup[word]
                        wordGroup[word] = [ levels]
                    else
                        wordGroup[word].push(levels)

            for word, groups of wordGroup
                str = "#{word}: "
                for levels in groups
                    levelStr = ""
                    for level in levels
                        levelStr += level + "|"
                    str += levelStr + ","

                console.log(str)

    showSpecial: ->
        parseCsv PUZZLE_FILE_PATH, (table) ->
            data = tool._getPuzzleData(table)
            for level, puzzle of data
                sizeMap = {}
                for word in puzzle.ans
                    wordSize = word.length
                    if wordSize < 6
                        continue

                    if !sizeMap[wordSize]
                        sizeMap[wordSize] = 1
                    else
                        sizeMap[wordSize] = sizeMap[wordSize] + 1

                str = ""
                for size, count of sizeMap
                    if count > 1
                        if str != ""
                            str += ", "
                        str += "#{size}-#{count}"

                if str != ""
                    console.log("#{level}: #{str}")

    showRepeatWord: ->
        parseCsv PUZZLE_FILE_PATH, (table) ->
            data = tool._getPuzzleData(table)
            puzzleCount = Object.keys(data).length

            for level, puzzle of data
                wordMap = {}
                for word in puzzle.ans
                    wordMap[word] = [level]

                for num in [1...puzzleCount - level]
                    nextLevelNum = Number(level) + Number(num)
                    nextLevel = nextLevelNum.toString()
                    if nextLevelNum >= puzzleCount
                        break

                    nextPuzzle = data[nextLevel]
                    count = 0
                    repeatWord = []
                    for nextWord in nextPuzzle.ans
                        if wordMap[nextWord]
                            repeatWord.push nextWord
                            count++
                    if Math.abs(puzzle.ans.length - nextPuzzle.ans.length) <= 1
                        if puzzle.ans.length < nextPuzzle.ans.length
                            min = puzzle.ans.length
                        else
                            min = nextPuzzle.ans.length
                        if count >= min - 1 and count >= 3
                            console.log("level:#{level}, nextLevel:#{nextLevel}, repeatWord:#{repeatWord}")

if cmd is "run"
    async.series [ 
        tool.prepareLevel, 
        tool.moreLevel, 
        tool.removeRepeat,
        #tool.removeNonContinuous,
        tool.fillExtra,
        tool.mapWordHZ,
        tool.createLevels
    ], (error, result)->
else if cmd is "prepare"
    async.series [ 
        tool.prepareLevel, 
        tool.moreLevel, 
        tool.removeRepeat,
        #tool.removeNonContinuous,
        tool.fillExtra
    ], (error, result)->
else if cmd is "level"
    async.series [ 
        tool.mapWordHZ,
        tool.createLevels
    ], (error, result)->
else if cmd is "info"
    tool.findSameLevel()
    tool.printAllChars()
else if cmd is "repeat"
    tool.showRepeat()
else if cmd is "special"
    tool.showSpecial()
else if cmd is "find"
    tool.showRepeatWord()
else
    str = """
    ======= tables
    === big.csv -> 大词库
    === words.csv   -> 小词库
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

    coffee tool_cross.coffee -c repeat
        显示n关内完全相同的单词

    coffee tool_cross.coffee -c find
        显示关卡间重复单词数大于等于3的行数和单词

    """
    console.log str
