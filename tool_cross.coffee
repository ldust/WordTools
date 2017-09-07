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
from    = argv.f
timeBegin = 0
language = argv.l
language = "en" unless language
tipsLanguage = 0
switch language
    when "en"
        tipsLanguage = "英语"
    when "de"
        tipsLanguage = "德语"
    else
        tipsLanguage = "未知"
console.log("提示: 正在使用#{tipsLanguage}语言")

LEVEL_RULES_PATH        = "./tables/output_rules_#{language}.csv"
RAW_BIG_WORD_LISH_PATH  = "./tables/big_#{language}.csv"
RAW_WORD_FILE_PATH      = "./tables/words_#{language}.csv"

PUZZLE_FILE_PATH        = "./output/level_#{language}.csv"
GOOGLE_FILE_LEVEL_OUT   = "./tables/level_puzzle_out_#{language}.csv"

mode ?= "word"
CHALLENGE_LISH_PATH     = "./tables/challenge_puzzle_#{mode}.json"

ChallengeTool           = require "./gen_challenge"

Dict                    = {}
Hz                      = {}

backUpLevels              = []

PATTERN_INDEX           = 3
ANS_START_INDEX         = 4
EXTRA_START_INDEX       = 100

isShowLog = false

if isShowLog
    DEBUG = console.log.bind(console)
else
    DEBUG = ->


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
                            for w in cmp
                                unless w in main
                                    repeat = false
                                    break
                            break if repeat = false
                        if repeat and index isnt 0
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
                count = 0
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
                        count++
                        #cache.splice(index, 1)
                console.log("#{wordLen}-#{p}, nonContinuous count:#{count}")
                #fs.writeFileSync "./tables/_tmp_#{wordLen}-#{p}.json", JSON.stringify cache
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
        parseCsv "./config/hz_#{language}.csv", (table) ->
            timeBegin = new Date()
            for row, index in table
                lowerWord = row[0].toLowerCase()
                Hz[lowerWord] = index
            tool.hz = JSON.parse fs.readFileSync "./config/hz_#{language}.json", {encoding: "utf8"}
            tool.len = JSON.parse fs.readFileSync "./config/word_difficult.json", {encoding: "utf8"}
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
                    levelInfo = "#{cfg.word_length_max}-0"
                    match = tool._getMatchFromCache(cache, cfg, true, levels, levelInfo)
                    if match
                        levels.push match
                        cache.splice match.index, 1
                        unless match.success
                            console.log "[WARNING]: #{id} need difficulty:[#{[cfg.difficulty_min, cfg.difficulty_max]}] but use #{match.difficulty}--from file :#{cfg.word_length_max}-0"
                    else
                        cacheMore = cabdidateCache["#{cfg.word_length_max}-1"]
                        levelInfo = "#{cfg.word_length_max}-1"
                        matchMore = tool._getMatchFromCache(cacheMore, cfg, true, levels, levelInfo)
                        if matchMore
                            levels.push matchMore
                            cacheMore.splice matchMore.index, 1
                            if matchMore.success
                                console.log "[WARNING]: #{id} use match from 'more table'--from file :#{cfg.word_length_max}-1"
                            else
                                console.log "[WARNING]: #{id} use match from 'more table' and need difficulty:[#{[cfg.difficulty_min, cfg.difficulty_max]}] but use #{matchMore.difficulty}--from file :#{cfg.word_length_max}-1"
                        else
                            levels.push {}
                            console.log "[error]: #{id} has no match"
            tool._saveLevels(levels)
            tool._saveBackUpLevels()
            nowTime = new Date()
            console.log("cost time:#{(nowTime - timeBegin) / 1000}")
            callback?()
            return

    _getTwoWordsInfo: (puzzle1, puzzle2)->
        sameWords = []
        sameCount = 0
        for word1 in puzzle1
            if word1 in puzzle2
                sameCount++
                sameWords.push word1
        sameFirstLetterNumber = 0
        cmdWords = []
        for word1 in puzzle1
            continue if word1 in sameWords
            for word2 in puzzle2
                continue if word2 in sameWords
                continue if word2 in cmdWords
                if word1[0] is word2[0]
                    cmdWords.push word2
                    sameFirstLetterNumber++
                    break
        disSameWordCount = 0
        for word1 in puzzle1
            unless word1 in puzzle2
                disSameWordCount++
        return [sameCount, sameFirstLetterNumber, disSameWordCount]

    _checkTargetWordsRepeat: (puzzle, levels)->
        isRepeat = false
        for cmpLevel in levels
            cmpPuzzle = cmpLevel.puzzle
            continue unless cmpPuzzle
            continue if cmpPuzzle.length isnt puzzle.length
            sameCount = 0
            for word in puzzle
                continue unless word in cmpPuzzle
                sameCount++
            if sameCount is puzzle.length
                isRepeat = true
        return isRepeat

    _saveBreakLevelInfo: (goodLevel, ruleId, levelId, currentLevels)->
        for currentLevel in currentLevels
            if currentLevel.levelInfo is goodLevel.levelInfo
                return
        goodLevel.breakSameRuleId = ruleId
        goodLevel.levelId = levelId
        currentLevels.push goodLevel

    _checkRepeatOnCreate: (ret, levels, levelId, currentLevels)->
        if levels.length is 0
            @_saveBreakLevelInfo(ret, -1, levelId, currentLevels)
            return
        return true if @_checkTargetWordsRepeat(ret.puzzle, levels)
        curChars = tool.allChars(ret.puzzle)
        wordsLength = ret.puzzle.length
        letterLength = curChars.length
        maxLetterLength = 8
        minLength = if levels.length >= 100 then levels.length - 100 else 0
        levelIndex = 1
        for index in [levels.length - 1..minLength]
            puzzle = levels[index].puzzle
            continue unless puzzle
            targetChars = tool.allChars(puzzle)
            minLetterLength = if letterLength < targetChars.length then letterLength else targetChars.length
            disLetterNum = zim.diffWordLetter(curChars, targetChars).length
            [sameWordsCount, firstLetterSame, disSameWordCount] = @_getTwoWordsInfo(puzzle, ret.puzzle)
            DEBUG("levelIndex:#{levelIndex}, puzzle:#{puzzle},ret.puzzle:#{ret.puzzle}, #{sameWordsCount} #{firstLetterSame} #{disSameWordCount},minLetterLength:#{minLetterLength} ")
            if 1 <= levelIndex <= 5
                if sameWordsCount > 1
                    DEBUG("error id 15 - 1")
                    @_saveBreakLevelInfo(ret, 15, levelId, currentLevels)
                    return true
            if 6 <= levelIndex <= 10
                if 3 <= letterLength <= 4
                    if 3 <= wordsLength <= 4
                        if sameWordsCount > 1
                            DEBUG("error id 14 - 1")
                            @_saveBreakLevelInfo(ret, 14, levelId, currentLevels)
                            return true
                if 5 <= letterLength <= maxLetterLength
                    if 5 <= wordsLength <= 7
                        if sameWordsCount > 1
                            DEBUG("error id 14 - 2")
                            @_saveBreakLevelInfo(ret, 14, levelId, currentLevels)
                            return true
            if 11 <= levelIndex <= 20
                if 3 <= letterLength <= 4
                    if 3 <= wordsLength <= 4
                        if sameWordsCount > 1
                            DEBUG("error id 13 - 1")
                            @_saveBreakLevelInfo(ret, 13, levelId, currentLevels)
                            return true
                if 5 <= letterLength <= maxLetterLength
                    if 5 <= wordsLength <= 7
                        if sameWordsCount > 2
                            DEBUG("error id 13 - 2")
                            @_saveBreakLevelInfo(ret, 13, levelId, currentLevels)
                            return true
            if 21 <= levelIndex <= 40
                switch disLetterNum
                    when 0
                        if 3 <= letterLength <= 4
                            if sameWordsCount isnt 0
                                DEBUG("error id 8-1")
                                @_saveBreakLevelInfo(ret, 8, levelId, currentLevels)
                                return true
                        if 5 <= letterLength <= maxLetterLength
                            if disSameWordCount < 3
                                DEBUG("error id 8-2-1")
                                @_saveBreakLevelInfo(ret, 8, levelId, currentLevels)
                                return true
                            if firstLetterSame > 2
                                DEBUG("error id 8-2-2")
                                @_saveBreakLevelInfo(ret, 8, levelId, currentLevels)
                                return true
                    when 1
                        if 3 <= letterLength <= 4
                            if sameWordsCount > 1
                                DEBUG("error id 9-1")
                                @_saveBreakLevelInfo(ret, 9, levelId, currentLevels)
                                return true
                        if 5 <= letterLength <= maxLetterLength
                            if disSameWordCount < 3
                                DEBUG("error id 9-2-1")
                                @_saveBreakLevelInfo(ret, 9, levelId, currentLevels)
                                return true
                            if firstLetterSame > 2
                                DEBUG("error id 9-2-1")
                                @_saveBreakLevelInfo(ret, 9, levelId, currentLevels)
                                return true
                    when 2
                        if 3 <= letterLength <= 4
                            if disSameWordCount < 2
                                DEBUG("error id 10-1")
                                @_saveBreakLevelInfo(ret, 10, levelId, currentLevels)
                                return true

                        if 5 <= letterLength <= maxLetterLength
                            if disSameWordCount < 3
                                DEBUG("error id 10-2")
                                @_saveBreakLevelInfo(ret, 10, levelId, currentLevels)
                                return true

            if 41 <= levelIndex <= 60
                switch disLetterNum
                    when 0
                        if 3 <= letterLength <= 4
                            if sameWordsCount > 1
                                DEBUG("error id 5-1")
                                @_saveBreakLevelInfo(ret, 5, levelId, currentLevels)
                                return true
                        if 5 <= letterLength <= maxLetterLength
                            if disSameWordCount < 3
                                DEBUG("error id 5-2-1")
                                @_saveBreakLevelInfo(ret, 5, levelId, currentLevels)
                                return true
                            if firstLetterSame > 3
                                DEBUG("error id 5-2-1")
                                @_saveBreakLevelInfo(ret, 5, levelId, currentLevels)
                                return true
                    when 1
                        if 3 <= letterLength <= 4
                            if disSameWordCount < 2
                                DEBUG("error id 6-1")
                                @_saveBreakLevelInfo(ret, 6, levelId, currentLevels)
                                return true
                        if 5 <= letterLength <= maxLetterLength
                            if disSameWordCount < 3
                                DEBUG("error id 6-2-1")
                                @_saveBreakLevelInfo(ret, 6, levelId, currentLevels)
                                return true
            if 61 <= levelIndex <= 80
                if disLetterNum <= 1
                    if 3 <= letterLength <= 4
                        if disSameWordCount < 2
                            DEBUG("error id 3-1-1")
                            @_saveBreakLevelInfo(ret, 3, levelId, currentLevels)
                            return true
                        if firstLetterSame > 2
                            DEBUG("error id 3-1-2")
                            @_saveBreakLevelInfo(ret, 3, levelId, currentLevels)
                            return true
                    if 5 <= letterLength <= maxLetterLength
                        if disSameWordCount < 2
                            DEBUG("error id 3-2-1")
                            @_saveBreakLevelInfo(ret, 3, levelId, currentLevels)
                            return true
                        if firstLetterSame > 4
                            DEBUG("error id 3-2-2")
                            @_saveBreakLevelInfo(ret, 3, levelId, currentLevels)
                            return true
            if 81 <= levelIndex <= 100
                if disLetterNum is 0
                    if disSameWordCount < 2
                        DEBUG("error id 1")
                        @_saveBreakLevelInfo(ret, 1, levelId, currentLevels)
                        return true

            levelIndex++
        @_saveBreakLevelInfo(ret, -1, levelId, currentLevels)
        return false

    _getSameLengthWord: (level1, level2)->
        cmpWord = []
        sameWordLength = 0
        for word1 in level1
            continue if word1 in cmpWord
            for word2 in level2
                continue if word2 in cmpWord
                if word1.length is word2.length
                    cmpWord.push word1
                    cmpWord.push word2
                    sameWordLength++
        return sameWordLength

    _saveBreakLevelWithStructureInfo: (level, ruleId, currentLevels)->
        level.breakStructureId = ruleId
        currentLevels.push level

    _dealLevel: (disCount, currentPuzzleLength, sameLengthWord, limit1, limit2, limit3, limit4, rulesId1, rulesId2)->
        switch disCount
            when 0
                if 2 <= currentPuzzleLength <= 4
                    if sameLengthWord > limit1
                        DEBUG "error structure id #{rulesId1} - 1"
                        return rulesId1
                if 5 <= currentPuzzleLength <= 8
                    if sameLengthWord > limit2
                        DEBUG "error structure id #{rulesId1} - 2"
                        return rulesId1
            when 1
                if 2 <= currentPuzzleLength <= 4
                    if sameLengthWord > limit3
                        DEBUG "error structure id #{rulesId2} - 1"
                        return rulesId2
                if 5 <= currentPuzzleLength <= 8
                    if sameLengthWord > limit4
                        DEBUG "error structure id #{rulesId2} - 2"
                        return rulesId2
        return -1

    _checkStructureOnCreate: (currentLevels, levels)->
        niceLevels = []
        isNullTable = true
        for level in levels
            for obj of level
                isNullTable = false
                break
            break unless isNullTable
        return currentLevels if isNullTable
        minLength = if levels.length >= 10 then levels.length - 10 else 0
        for currentLevel in currentLevels
            currentPuzzle = currentLevel.puzzle
            currentPuzzleLength = currentPuzzle.length
            levelIndex = 1
            isEnd = true
            for index in [levels.length - 1..minLength]
                targetPuzzle = levels[index].puzzle
                unless targetPuzzle?
                    levelIndex++
                    continue
                targetPuzzleLength = targetPuzzle.length
                disCount = Math.abs(currentPuzzleLength - targetPuzzleLength)
                sameLengthWord = @_getSameLengthWord(currentPuzzle, targetPuzzle)
                if 1 <= levelIndex <= 2
                    resultId = @_dealLevel(disCount, currentPuzzleLength, sameLengthWord, 2, 4, 3, 5, 9, 8)
                    if resultId isnt -1
                        @_saveBreakLevelWithStructureInfo(currentLevel, resultId, niceLevels)
                        isEnd = false
                        break
                else if 3 <= levelIndex <= 5
                    resultId = @_dealLevel(disCount, currentPuzzleLength, sameLengthWord, 2, 4, 4, 6, 6, 5)
                    if resultId isnt -1
                        @_saveBreakLevelWithStructureInfo(currentLevel, resultId, niceLevels)
                        isEnd = false
                        break
                else if 6 <= levelIndex <= 10
                    resultId = @_dealLevel(disCount, currentPuzzleLength, sameLengthWord, 3, 5, 4, 6, 3, 2)
                    if resultId isnt -1
                        @_saveBreakLevelWithStructureInfo(currentLevel, resultId, niceLevels)
                        isEnd = false
                        break
                levelIndex++
            @_saveBreakLevelWithStructureInfo(currentLevel, -1, niceLevels) if isEnd
        niceLevels

    _delLevelFromBackUp: (niceLevels)->
        for niceLevel in niceLevels
            for levels in backUpLevels
                for level, index in levels
                    if level.levelInfo is niceLevel.levelInfo
                        levels.splice(index, 1)
                        break
        return

    _getMatchFromCache: (cache, cfg, useNonCon, levels, levelInfo)->
        randFun = random(100).random
        indexTryed = []
        currentLevels = []
        for i in [0 ... cache.length]
#            if i isnt 0 and i %1000 is 0
#                console.log("try count:#{i} --------------->total:#{cache.length}")
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
                #console.log(cfg.difficulty_min, difficulty, cfg.difficulty_max)
                if cfg.difficulty_min <= difficulty <= cfg.difficulty_max
                    ret.index  = index
                    ret.difficulty = difficulty
                    ret.success = true
                    ret.levelInfo = "#{levelInfo}_#{puzzle.index}"
                    @_checkRepeatOnCreate(ret, levels, cfg.id, currentLevels)
        if currentLevels.length is 0
            console.log("WARNING: level:#{cfg.id} difficult not match")
        niceLevels = @_checkStructureOnCreate(currentLevels, levels)

        goodLevel = undefined
        minNum = 100
        goodIndex = 0
        for level, index in niceLevels
            level.breakStructureId ?= -1
            if level.breakSameRuleId >= level.breakStructureId
                if level.breakSameRuleId <= minNum
                    minNum = level.breakSameRuleId
                    goodLevel = level
                    goodIndex = index
            else
                if level.breakStructureId <= minNum
                    minNum = level.breakStructureId
                    goodLevel = level
                    goodIndex = index
        niceLevels.splice(goodIndex, 1)
        @_delLevelFromBackUp(niceLevels)
        backUpLevels.push niceLevels

        return goodLevel

    _saveBackUpLevels: ->
        CONFIGS =
            id      : 0
            breakId1 : 1
            breakId2 : 2
            difficulty: 3
            extCount: 4
            type    : 5
            ans     : 6
            ext     : 15

        COLUMES     = 38

        titles = []
        titles.length = COLUMES
        for name, start of CONFIGS
            titles[start] = name

        wstream = fs.createWriteStream "./output/level_#{language}_backup.csv"
        wstream.write titles.join(",") + "\n"
        count = 1
        for table in backUpLevels
            for level in table
                row = []
                row.length = COLUMES
                count++

                if level
                    row[CONFIGS.id] = level.levelId
                    row[CONFIGS.breakId1] = level.breakSameRuleId
                    row[CONFIGS.breakId2] = level.breakStructureId
                    row[CONFIGS.difficulty] = level.difficulty
                    row[CONFIGS.extCount] = level.add
                    row[CONFIGS.type] = (level.puzzle.map (word)-> word.length + '').join('')
                    for ans, ansI in level.puzzle
                        row[CONFIGS.ans + ansI] = ans
                    for ext, extI in level.ext
                        row[CONFIGS.ext + extI] = ext
                wstream.write row.join(",") + "\n"
        console.log("*** backup count :#{count}")
        wstream.end()

    _saveLevels: (levels)->
        outputPath = "./output"
        unless fs.existsSync(outputPath)
            fs.mkdirSync(outputPath)

        #====
        fs.writeFileSync "./output/level.json", JSON.stringify levels
        #====
        CONFIGS = 
            id      : 0
            breakId1:1
            breakId2:2
            difficulty : 3
            extCount: 4
            type    : 5
            ans     : 6
            ext     : 15

        COLUMES     = 38

        titles = []
        titles.length = COLUMES
        for name, start of CONFIGS
            titles[start] = name

        wstream = fs.createWriteStream "./output/level_#{language}.csv"
        wstream.write titles.join(",") + "\n"
        count = 1
        for level, index in levels
            row = []
            row.length = COLUMES
            if level
                row[CONFIGS.id] = level.levelId
                unless level.difficulty
                    wstream.write row.join(",") + "\n"
                    continue
                count++
                row[CONFIGS.difficulty] = level.difficulty
                row[CONFIGS.success] = if level.success then 1 else 0
                row[CONFIGS.extCount] = level.add
                row[CONFIGS.breakId1] = level.breakSameRuleId
                row[CONFIGS.breakId2] = level.breakStructureId
                row[CONFIGS.type] = (level.puzzle.map (word)-> word.length + '').join('')
                for ans, ansI in level.puzzle
                    row[CONFIGS.ans + ansI] = ans
                for ext, extI in level.ext
                    row[CONFIGS.ext + extI] = ext
            wstream.write row.join(",") + "\n"
        console.log("*** ok count :#{count}")
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
                        DEBUG("reFound error")
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
            puzzle.sort tool.cmpup
            disLength = puzzle.length - cfg.word_num
            if puzzle.length > cfg.word_num
                newPuzzle = zim.deepClone(puzzle)
                newPuzzle.splice(1, disLength)
                puzzle = newPuzzle
            add = ext.length
            return {chars, puzzle, ext, add}
        else
            console.log("error chars length not match")
            null

    _getHzRatio: (word)->
        hz = Hz[word] or 0
        targetRatio = 0
        for item in tool.hz
            if hz >= item[0]
                targetRatio = item[1]
        return targetRatio

    _getLenDifficulty: (charsLength, word)->
        targetObj = undefined
        for own id, content of tool.len
            if content.target_letter is word.length
                targetObj = content
        unless targetObj
            console.log("ERROR, char len not match")
            return 0
        allCharLengthStr = "ratio#{charsLength}"
        for own key, value of targetObj
            if key is allCharLengthStr
                return value
        console.log("ERROR, word len not match")
        return 0

    _calcDifficulty: (words)->
        score = 0
        allCharsLength = @allChars(words).length
        for w in words
            score += tool._getHzRatio(w) * @_getLenDifficulty(allCharsLength, w)
        score

    _parseConfig: (table)->
        keys = []
        level_config = {}
        for row, i in table
            break if row[0] is ""
            if i is 0
                keys = row
            else if i in [1,2]
                continue
            else
                obj = {}
                for cell, j in row
                    continue if cell is ""
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
            if from is "google"
                pattern = row[4]
            else
                pattern = row[5]
                size = row[4]
            bonus = 0
            newRow.bn = parseInt(bonus) or 0
            newRow.tp = pattern
            newRow.ans = []
            newRow.add = []
            newRow.size = size
            if from is "google"
                wordBeginIndex = 5
            else
                wordBeginIndex = 6
            for item, index in row
                continue if zim.empty(item)
                item = item.trim()
                if item.match(/\s/img)?
                    throw new Error("Word Contain SpaceChar Error In Row #{column}")
                if 0 <= index - wordBeginIndex < pattern.length
                    newRow.ans.push @_toUpperCase(item)
                else if index - wordBeginIndex >= pattern.length
                    newRow.add.push @_toUpperCase(item)
            newRow.ans.sort(@cmpRepeat)
            for item, index in newRow.ans
                if item.length isnt parseInt(pattern[index])
                    console.log("newRow:#{JSON.stringify newRow}, column:#{column}")
                    throw new Error("item not fix pattern #{id}")

            if newRow.ans.length is 0 or (newRow.ans.length isnt pattern.length)
                console.log("newRow:#{JSON.stringify newRow}, column:#{column}")
                throw new Error("Level Table Error In Row #{column}")

            if @_isArrayIncludeEachOther(newRow.ans, newRow.add)
                console.log("newRow:#{JSON.stringify newRow}, column:#{column}")
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
        fileName = 0
        if from is "google"
            fileName = GOOGLE_FILE_LEVEL_OUT
        else 
            fileName = PUZZLE_FILE_PATH
        parseCsv(fileName, @getAllSameLevel.bind(@))

    printAllChars: ->
        if from is "google"
            fileName = GOOGLE_FILE_LEVEL_OUT
        else
            fileName = PUZZLE_FILE_PATH
        parseCsv fileName, (table) ->
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
        if from is "google"
            fileName = GOOGLE_FILE_LEVEL_OUT
        else
            fileName = PUZZLE_FILE_PATH
        parseCsv fileName, (table) ->
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
        if from is "google"
            fileName = GOOGLE_FILE_LEVEL_OUT
        else
            fileName = PUZZLE_FILE_PATH
        parseCsv fileName, (table) ->
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
                    continue unless nextPuzzle
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

    addCrossCount: ->
        if from is "google"
            fileName = GOOGLE_FILE_LEVEL_OUT
        else
            fileName = PUZZLE_FILE_PATH
        parseCsv fileName, (table) ->
            data = tool._getPuzzleData(table)
            wstream = fs.createWriteStream "./output/level_cross_count_#{language}.csv"
            wstream.write ["id", "cross_count"] + "\n"

            for level, puzzle of data
                puzzle.ans.sort tool.cmpup
                result = genCross(puzzle.ans, puzzle.add, puzzle.size, puzzle.size)
                wstream.write [level, result.bn] + "\n"
            wstream.end()
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
else if cmd is "add_cross_count"
    tool.addCrossCount()
else if cmd is "tool_json"
    parseCsv "tables/word_difficult.csv", (table) ->
        config = tool._parseConfig(table, true)
        fs.writeFileSync "./config/word_difficult.json", JSON.stringify config

    parseCsv "tables/structure_detect.csv", (table) ->
        config = tool._parseConfig(table)
        fs.writeFileSync "./config/structure_detect.json", JSON.stringify config
    console.log("JSON转换完成!")

else if cmd is "test"
    puzzle1 = ["abcd", "abcc", "abc", "ab", "ab", "aa"]
    puzzle2 = ["abdc", "adb", "ac", "ad"]
    tool._getSameLengthWord(puzzle1, puzzle2)
else
    str = """
    <=========================================================>
    重要提示: 下面的??,用当前语言的简写替换,英语 en,德语 de
    ======= tables
    === big_??.csv -> 大词库
    === words_??.csv   -> 小词库
    === output_rules_??.csv      -> 关卡规则
    === hz_??.csv                -> 词频表

    ======= config
    === hz_??.json               -> 词频难度配置
    === len_??.json              -> 词长难度配置

    ======= output
    === level_??.json            -> json 格式关卡
    === level_??.csv             -> csv 格式关卡

    导表: ./download.sh ??

    coffee tool_cross.coffee -c run -l ??
        整体执行生成关卡的逻辑

    coffee tool_cross.coffee -c prepare -l ??
        预处理关卡，当大、小词库变化时需要运行

    coffee tool_cross.coffee -c level -l ??
        随机关卡，当配置变化时需要运行

    coffee tool_cross.coffee -c repeat -l ??
        显示n关内完全相同的单词

    coffee tool_cross.coffee -c find -l ??
        显示关卡间重复单词数大于等于3的行数和单词

    coffee tool_cross.coffee -c info -l ??
        使用关卡文件level_puzzle_out.csv，检测文件中重复的关卡，输出信息中每行代表同一组重复关卡号，同时输出每关用的字母

    coffee tool_cross.coffee -c add_cross_count -l ??
        输出已经生成好的level文件中单词交叉数,存在output/level_cross_count_??.csv文件中

    注意: 如果要使用google 上面的文件 ,
        第一步: 将文件放在 /tables/level_puzzle_out_??.csv"
        第二步: 执行命令时加 -f google
    <=========================================================>
    """

    console.log str
