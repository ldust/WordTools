# Created by yaochunhui on 2017/7/
fs              = require 'fs'
parse           = require('csv').parse
utils           = require './ZimUtils'
random          = require './ZimConsistentRandom'

randFun = random(100).random
# DEBUG = console.log.bind(console)
DEBUG = ->

parseCsv = (path, callback)->
    data = fs.readFileSync path, {encoding: "utf8"}
    parse data, {delimiter: ','}, (error, table)->
        throw new Error(error) if error?
        callback(table)

class GenPuzzle
    constructor: (w, h)->
        cells = []
        for y in [0...h] by 1
            line = []
            for x in [0...w] by 1
                line.push(
                    char: null
                    times: 0
                )
            cells.push line
        @cells = cells
        @width = w
        @height = h
            
    clear: ->
        cells = @cells
        for y in [0...@height] by 1
            line = cells[y] 
            for x in [0...@width] by 1
                cell = line[x]
                cell.char = null
                cell.times = 0
        return        

    isEmpty: (x, y) ->
        return true unless @cells[y]
        return true unless @cells[y][x]
        @cells[y][x].char == null

    evaluateWord: (word, x, y, dx, dy)->
        return -1 unless @isEmpty(x - dx, y - dy)
        return -1 unless @isEmpty(x + dx * word.length, y + dy * word.length)
        cells = @cells
        score = 0
        lastIsRepeat = false
        for c, i in word
            cell = cells[y][x]
            if cell.char == null
                return -1 unless @isEmpty(x + dy, y + dx)
                return -1 unless @isEmpty(x - dy, y - dx)
                
                lastIsRepeat = false
            else if cell.char == c
                if lastIsRepeat
                    return -1
                lastIsRepeat = true
                score++
            else
                return -1
            x += dx
            y += dy
        return score
    
    putWord: (word, x, y, dx, dy)->
        cells = @cells
        for c, i in word
            cell = cells[y][x]
            cell.char = c
            cell.times++
            x += dx
            y += dy
        return

    unPutWord: (word, x, y, dx, dy)->
        cells = @cells
        for c, i in word
            cell = cells[y][x]
            cell.times--
            if cell.times is 0
                cell.char = null
            x += dx
            y += dy
        return
        
    tryPutWord: (word)->
        candidatePos = []
        maxScore = 0
        for y in [0..@height - word.length] by 1
            for x in [0...@width] by 1
                score = @evaluateWord(word, x, y, 0, 1)
                #console.log "evaluate result: " + score
                if score > maxScore
                    maxScore = score
                    candidatePos = [
                        {x, y, dx: 0, dy: 1}
                    ]
                else if score == maxScore
                    candidatePos.push {x, y, dx: 0, dy: 1}

        for y in [0...@height] by 1
            for x in [0..@width - word.length] by 1
                score = @evaluateWord(word, x, y, 1, 0)
                #console.log "evaluate result: " + score
                if score > maxScore
                    maxScore = score
                    candidatePos = [
                        {x, y, dx: 1, dy: 0}
                    ]
                else if score == maxScore
                    candidatePos.push {x, y, dx: 1, dy: 0}

        if candidatePos.length == 0
            return false
        utils.arrayShuffle candidatePos, randFun
        pos = candidatePos[0]
        @wordDescList.push {word: word, x: pos.x, y: pos.y, dx: pos.dx, dy: pos.dy}
        @putWord(word, pos.x, pos.y, pos.dx, pos.dy)
        return true

    getWordInfo: (wordDesc) ->
        x = wordDesc.x
        y = wordDesc.y
        cells = @cells
        score = 0
        pattern = ""
        for c, i in wordDesc.word
            times = cells[y][x].times
            score += times - 1
            pattern += if times is 1 then "*" else c
            x += wordDesc.dx
            y += wordDesc.dy
        return {score, pattern}
        
    putWords: (words) ->
        @wordDescList = []
        for word in words
            DEBUG "--------- put word: " + word
            if @tryPutWord(word)
                DEBUG @mapToString()
            else
                DEBUG "ERROR!"
                return false
        for desc in @wordDescList
            {score, pattern} = @getWordInfo(desc)
            desc.pattern = pattern
            #console.log "#{desc.word} = " + score
            if score is 0
                DEBUG "Single word!"
                return false
                
        @clipMap()
        @isConnected = @checkConnected()
        if (@height > @width)
            @rotate()
            
        @wordDescList.sort (a, b) ->
            a.y * 100 + a.x - b.y * 100 - b.x
            
        return true

    getCrossCount: ->
        count = 0
        for line in @cells
            for cell in line
                count++ if cell.times > 1
        count

    mapToString: ->
        @cells.map((line) ->
            line.map((cell) -> if cell.char then cell.char else "." ).join("")
        ).join("\n")

    clipMap: ->
        width = @width
        height = @height
        cells = @cells
        isEmptyLine = (y) ->
            line = cells[y]
            for x in [0...width] by 1
                if line[x].char != null
                    return false
            return true
            
        isEmptyCol = (x) ->
            for y in [0...height] by 1
                if cells[y][x].char != null
                    return false
            return true
            
        y1 = 0
        while y1 < height and isEmptyLine(y1)
            y1++
            
        x1 = 0
        while x1 < width and isEmptyCol(x1)
            x1++
            
        y2 = height - 1
        while y2 >= 0 and isEmptyLine(y2)
            y2--

        x2 = width - 1
        while x2 >= 0 and isEmptyCol(x2)
            x2--
        if x1 > 0 or y1 > 0
            for y in [y1..y2] by 1
                for x in [x1..x2] by 1
                    cells[y - y1][x - x1] = cells[y][x]
        cells.length = y2 - y1 + 1
        for line in cells
            line.length = x2 - x1 + 1
        @width = x2 - x1 + 1
        @height = y2 - y1 + 1

        for desc in @wordDescList
            desc.x -= x1
            desc.y -= y1
        return true

    getResult: ->
        w: @width
        h: @height
        ans:
            wordDesc.word for wordDesc in @wordDescList
        layout:
            for wordDesc in @wordDescList
                [wordDesc.x, wordDesc.y, wordDesc.dx]
    
    rotate: ->
        [@width, @height] = [@height, @width]
        for wordDesc in @wordDescList
            [wordDesc.x, wordDesc.y, wordDesc.dx, wordDesc.dy] = [
                wordDesc.y
                wordDesc.x
                wordDesc.dy
                wordDesc.dx
            ]
        return
    
    isMatchPattern: (word, pattern) ->
        return false unless word.length is pattern.length
        for c, i in word
            return false unless pattern[i] is "*" or c is pattern[i]
        true
        
    filterExtras: (extras) ->
        patterns = @wordDescList.map((desc) -> desc.pattern)
        #console.log JSON.stringify(patterns)
        add = []
        ext = []
        for word in extras
            matchPattern = false
            for pattern in patterns
                if @isMatchPattern(word, pattern)
                    matchPattern = true
                    break
            if matchPattern
                add.push word
            else
                ext.push word
        [add, ext]

    checkConnected: ->
        cells = @cells
        search = (x, y) =>
            return if @isEmpty(x, y)
            cell = cells[y][x]
            return if cell.visited
            cell.visited = true
            search(x - 1, y)
            search(x + 1, y)
            search(x, y - 1)
            search(x, y + 1)
        {x, y} = @wordDescList[0]
        search(x, y)
        for line in cells
            for cell in line
                if cell.char != null and !cell.visited
                    return false
        return true

module.exports = genCross = (words, extraWords, w, h) ->
    words = words.slice()
    randFun = random(1000).random
    genPuzzle = new GenPuzzle(w, h)
    for i in [1..100]
        utils.arrayShuffle(words, randFun)
        if genPuzzle.putWords(words)
            DEBUG "==============="
            DEBUG genPuzzle.mapToString()
            result = genPuzzle.getResult()
            [result.add, result.ext] = genPuzzle.filterExtras(extraWords)
            unless genPuzzle.isConnected
                if w > h
                    w--
                else
                    h--
                genPuzzle = new GenPuzzle(w, h)
            else
                return result
        else
            genPuzzle.clear()
    return null
