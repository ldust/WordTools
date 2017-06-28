argv    = require('yargs').argv
fs      = require 'fs'
parse   = require('csv').parse
zim     = require './ZimUtils'
_       = require 'lodash'

cmd     = argv.c
mode    = argv.m

WORD_FILE_PATH          = "./tables/level_words.csv"
PUZZLE_FILE_PATH        = "./tables/level_puzzle_out.csv"
BIG_WORD_LISH_PATH      = "./tables/big_word_list.csv"
RAW_BIG_WORD_LISH_PATH  = "./tables/raw_big_word_list.csv"
RAW_WORD_FILE_PATH      = "./tables/raw_level_words.csv"

mode ?= "word"
CHALLENGE_LISH_PATH     = "./tables/challenge_puzzle_#{mode}.json"

ChallengeTool           = require "./gen_challenge"

Dict                    = {}
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
        sub = a.length - b.length
        return sub unless sub is 0
        return -1 if a < b
        return 1 if a > b
        return 0

    filterBigTable: ->
        parseCsv RAW_BIG_WORD_LISH_PATH, (table) ->
            wstream = fs.createWriteStream BIG_WORD_LISH_PATH
            for row in table
                word = row[0]
                continue if word.length < 2 or word.length > 8
                wstream.write word.toLowerCase() + "\n"
            wstream.end()
        return

    addWordListContainedByMainWordAndOtherChar: (mainWord, add, max) ->
        ansList = []
        for wordSize in [3..max]
            for word in Dict[wordSize]
                continue if word in ansList
                if zim.contain(mainWord+add, word)
                    ansList.push word
                    return [] if ansList.length > 7
        good = false
        for w in ansList
            if _.includes(w, add)
                good = true
        return [] unless good
        return ansList

    createLevel: ->
        parseCsv WORD_FILE_PATH, (table) ->
            for row, index in table
                continue if index is 0
                for cell in row
                    key = cell.length
                    continue if key > 7
                    Dict[key] ?= []
                    Dict[key].push cell.toLowerCase()
            
            # max = 6
            # for word, index in Dict[max]
            #     for add in alphabet
            #         continue if _.includes(word, add)
            #         ret = tool.addWordListContainedByMainWordAndOtherChar word, add, max
            #         continue if ret.length < 3
            #         console.log ret.join(",")

            for max in [3, 4, 5, 6, 7]
                console.log "#{max}"
                str = []
                for word, index in Dict[max]
                    ret = tool.addWordListContainedByMainWord word, max, 3
                    continue if ret.length < 2 or ret.length > 15
                    ret.push word
                    str.push ret
                fs.writeFileSync "./tables/_tmp_#{max}.json", JSON.stringify str
                # pt = zim.randomItem(ret, zim.randomInt(4, 7))
                # pt.push(word)
                # console.log pt
                # console.log (p.length for p in pt).sort().join("")

            for max in [3, 4, 5]
                console.log "#{max}"
                str = []
                for word, index in Dict[max]
                    ret = tool.addWordListContainedByMainWord word, max, 2
                    continue if ret.length < 2 or ret.length > 15
                    ret.push word
                    str.push ret
                fs.writeFileSync "./tables/_tmp2_#{max}.json", JSON.stringify str

            return

    _createPuzzle: (wstream, tb, c3, v2) ->
        c3 = Number(c3)
        if v2
            data = fs.readFileSync "./tables/_tmp2_#{tb}.json", {encoding: "utf8"}
        else
            data = fs.readFileSync "./tables/_tmp_#{tb}.json", {encoding: "utf8"}
        table = JSON.parse(data)
        i = 0

        ccc = if v2 then 2 else 3
        rccc = if v2 then [2, 8] else [4, 8]

        wstream.write(",\n")
        for row, index in table
            continue if row.length < 4
            full = zim.deepClone row
            pt = zim.randomItem(row, zim.randomInt(rccc[0], rccc[1]))
            diff = _.difference(full, pt)
            pattern = (p.length for p in pt).sort()
            
            count3 = 0
            for w in pattern
                count3++ if w is ccc
            continue if count3 isnt c3

            chars = tool.allChars(pt).sort()

            extra = []
            for w in diff
                if w.length in pattern
                    extra.push(w)
            
            pt.sort(tool.cmp)

            wstream.write "#{pattern.join("")},#{pt.join(",")}"
            for k in [pt.length+2..15]
                wstream.write(",")

            extra.sort(tool.cmp)

            wstream.write "#{extra.join(",")}\n"
            i++
        return i

    createPuzzle: ->
        i = 0
        for tb in [4..7]
            for c3 in [0..3]
                wstream = fs.createWriteStream "./tables/#{tb}个字母#{c3}个3.csv"    
                i += tool._createPuzzle wstream, tb, c3, false
                wstream.end()

        for tb in [3..5]
            for c3 in [0..3]
                wstream = fs.createWriteStream "./tables/#{tb}个字母#{c3}个2.csv"    
                i += tool._createPuzzle wstream, tb, c3, true
                wstream.end()

        console.log "关卡数：" + i
        return

    genDict: ()->
        parseCsv(BIG_WORD_LISH_PATH, ChallengeTool.genWordListBySize(CHALLENGE_LISH_PATH))

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

    findExtraInBigList: (words, extra, rowIndex, pt) ->
        chars = tool.allChars(words).sort()
        ret = []
        for i in [0..chars.length]
            big = tool.big[i]
            continue unless big?
            for w in big
                continue unless w.length in pt
                continue if _.includes(extra, w)
                continue if _.includes(words, w)
                continue unless tool._in(chars.join(""), w)
                ret.push w
        ret = _.uniq(ret)
        console.log rowIndex + "," + ret if ret.length > 0
        return ret

    addExtra: (table) ->
        tool.big = {}
        for row in table
            for cell in row
                key = cell.length
                tool.big[key] ?= []
                tool.big[key].push cell.toLowerCase()

        wstream = fs.createWriteStream PUZZLE_FILE_PATH + ".tmp.csv"
        for row, rowIndex in tool.puzzleTable
            if rowIndex isnt 0
                words = []
                extra = []
                pt = row[PATTERN_INDEX].split("").map((item)-> parseInt(item))
                for cell, col in row
                    cell = cell.toLowerCase()
                    continue if col < ANS_START_INDEX
                    if col >= EXTRA_START_INDEX
                        row = row.slice(0, col)
                        ###
                        if zim.empty(cell)
                            row = row.slice(0, col)
                            break
                        else
                            extra.push cell
                        ###
                    else if not zim.empty(cell)
                        words.push cell
                row = row.concat tool.findExtraInBigList(words, extra, rowIndex, pt)
            wstream.write row.join(",") + "\n"
        wstream.end()

    fillExtra: ->
        # 用巨大词库补充额外词
        parseCsv(PUZZLE_FILE_PATH, (table) ->
            tool.puzzleTable = table
            parseCsv BIG_WORD_LISH_PATH, tool.addExtra
        )

    order: ->
        parseCsv(RAW_WORD_FILE_PATH, (table) ->
            dict = {}
            for row in table
                for w in row
                    continue if zim.empty(w)
                    dict[w.length] ?= []
                    dict[w.length].push w

            wstream = fs.createWriteStream WORD_FILE_PATH
            height = 0
            for l, v of dict
                height = Math.max(height, v.length)
                wstream.write "size#{l},"
            
            wstream.write "\n"

            height++
            i = 0
            
            while i < height
                for l, v of dict
                    value = v[i] ? ""
                    wstream.write value + ","
                wstream.write "\n"
                i++
            wstream.end()
        )
    isArrayIncludeEachOther: (arr1, arr2)->
        for item1 in arr1
            if item1 in arr2
                return true
        return false
    getAllSameLevel: (table)->
        data = @getPuzzleData(table)
        puzzleCount = Object.keys(data).length

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
                #console.log("#{JSON.stringify(sameLevel)}")

        for sameLevel in sameLevelArr
            console.log("#{sameLevel}")
        return sameLevelArr

    getPuzzleData: (table)->
        # dataStr = fs.readFileSync path, {encoding: "utf8"}
        # data = JSON.parse(dataStr)
        data = @handleCsv(table)
        return data

    isSameLevel: (puzzle1, puzzle2)->
        ans1 = puzzle1.ans
        ans2 = puzzle2.ans
        return @isSameArr(ans1, ans2)

    isSameArr: (arr1, arr2)->
        for item in arr1
            if item not in arr2
                return false
        for item in arr2
            if item not in arr1
                return false
        return true

    findSameLevel: ->
        parseCsv(PUZZLE_FILE_PATH, @getAllSameLevel.bind(@))

    printAllChars: ->
        parseCsv PUZZLE_FILE_PATH, (table) ->
            data = tool.getPuzzleData(table)
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

    toUpperCase: (word)->
        wordUpperCase = ""
        for c in word
            wordUpperCase += c if c is "ß"
            wordUpperCase += c.toUpperCase() if c isnt "ß"
        return wordUpperCase

    lab: ->
        chars = "dfnoabrk"
        parseCsv BIG_WORD_LISH_PATH, (table) ->
            for row, column in table
                for item in row
                    succ = true
                    for c in item
                        if not (c in chars)
                            succ = false
                            break
                    if succ
                        console.log "\"#{item}\","
            return

    handleCsv: (table) ->
        outPut = {}
        for row, column in table
            id = row[0]
            continue if id[0] is "#"
            newRow = {}
            outPut[id] = newRow
            pattern = row[3]
            bonus = row[2]
            newRow.bn = parseInt(bonus) or 0
            newRow.tp = pattern
            newRow.ans = []
            newRow.add = []
            for item, index in row
                continue if zim.empty(item)
                item = item.trim()
                if item.match(/\s/img)?
                    throw new Error("Word Contain SpaceChar Error In Row #{column}")
                if 0 <= index - 4 < pattern.length
                    newRow.ans.push @toUpperCase(item)
                else if index - 4 >= pattern.length
                    newRow.add.push @toUpperCase(item)

            newRow.ans.sort(@cmp)
            for item, index in newRow.ans
                if item.length isnt parseInt(pattern[index])
                    throw new Error("item not fix pattern #{id}")

            if newRow.ans.length is 0 or (newRow.ans.length isnt pattern.length)
                throw new Error("Level Table Error In Row #{column}")

            if @isArrayIncludeEachOther(newRow.ans, newRow.add)
                throw new Error("Level Table Error In Row #{column}: Item in Ans is also in Add")
        return outPut     

if cmd is "extra"
    tool.fillExtra()
else if cmd is "prepare_extra"
    tool.filterBigTable()
else if cmd is "prepare_level"
    tool.createLevel()
else if cmd is "prepare_word"
    tool.order()
else if cmd is "create_puzzle"
    tool.createPuzzle()
else if cmd is "info"
    tool.findSameLevel()
    tool.printAllChars()
else if cmd is "lab"
    tool.lab()
else if cmd is "gen_challenge"
    tool.genDict()
else
    str = """
    raw_big_word_list.csv -> 大词库
    raw_level_words.csv   -> 小词库
    以上是一列的表格
    level_words.csv       -> 按字母数分类过的小词库
    level_puzzle_out.csv  -> 关卡表


    coffee tool.coffee -c prepare_word
        把raw_level_words.csv转化成level_words.csv，level_words.csv是分组过的单词表

    coffee tool.coffee -c prepare_level
        用level_words.csv生成临时文件，每次小词库更新要重新生成(这个操作很慢，耐心等待)

    coffee tool.coffee -c create_puzzle
        生成关卡

    coffee tool.coffee -c prepare_extra
        用raw_big_word_list.csv生成big_word_list.csv，big_word_list.csv是符合字母规定（2-8个字母）的单词

    coffee tool.coffee -c extra
        用big_word_list.csv给level_puzzle_out.csv填充额外词

    coffee tool.coffee -c info
        使用关卡文件level_puzzle_out.csv，检测文件中重复的关卡，输出信息中每行代表同一组重复关卡号，同时输出每关用的字母

    coffee tool.coffee -c gen_challenge -m word4
        把big_word_list.csv转化成用于生成每日挑战关卡的表，然后根据此表生成每日挑战关卡表challenge_puzzle_word4.csv
        运行时间比较长，大约40-50分钟
        -m参数对应具体的版本, 比如word4

    """
    console.log str
