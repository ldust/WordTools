
WORD_DICT_PATH          = "./tables/word_dict.json"
Dict                    = {}
ALL_PATTERN             = "234567"
AnsDict                 = {}
Puzzles                 = {}
Seed                    = 0
fs                      = require 'fs'
zim                     = require './ZimUtils'
daily_challenge_stage   = null
game_config             = null

tool = 
    genWordListBySize: (file)->
        (table)->
            for row, rowIndex in table
                continue if rowIndex is 0
                for word, index in row
                    continue if word.length is 0 
                    Dict[word.length] ?= []
                    Dict[word.length].push word.toUpperCase()
            tool.genAnsDict()
            tool.genChallengePuzzle(file)
            return

    addWordListContainedByMainWord: (mainWord, max, min)->
        ansList = []
        for wordSize in [min..max]
            if Dict[String(wordSize)]?
                for word in Dict[String(wordSize)]
                    continue if word in ansList
                    if zim.contain(mainWord, word)
                        ansList.push word
        return ansList

    genAnsDict: ->
        pattern = ALL_PATTERN
        patternIntArr = pattern.split("").map((item)-> parseInt(item))
        for wordSize in patternIntArr by -1
            console.log "WordSize: #{wordSize}"
            continue if zim.empty(pattern)
            for mainWord, indexT in Dict[wordSize]
                ansList = tool.addWordListContainedByMainWord(mainWord, parseInt(wordSize) or 0, 2)
                AnsDict[mainWord] = ansList
            pattern = pattern.slice(0, -1)
        fs.writeFileSync WORD_DICT_PATH, JSON.stringify(AnsDict, null, 2)
        return

    genChallengePuzzle: (file)->
        daily_challenge_stage   = require "./tables/0/daily_challenge_stage.json"
        game_config             = require "./tables/0/game_config.json"
        Puzzles = JSON.parse(fs.readFileSync(WORD_DICT_PATH, {encoding: "utf8"}))
        tool.createPuzzleByTwoYear(file)

    createPuzzleByTwoYear: (file)->
        years = [2017, 2018]
        allPuzzles = {}
        for year in years
            for month in [tool.getMonthStartOfYear(year)..11]
                console.log("year: #{year} month: #{month + 1}")
                days = tool.getDaysOfMonth(year, month)
                for day in [1..days]
                    date = new Date(year, month, day)
                    puzzles = tool.createPuzzles(date)
                    allPuzzles[tool.getYMDString(date)] = puzzles
        fs.writeFileSync(file, JSON.stringify(allPuzzles))
        return

    getMonthStartOfYear: (year)->
        if year is 2017
            return 3
        else
            return 0

    getDaysOfMonth: (year, month)->
        switch month
            when 0 then return 31
            when 2 then return 31
            when 3 then return 30
            when 4 then return 31
            when 5 then return 30
            when 6 then return 31
            when 7 then return 31
            when 8 then return 30
            when 9 then return 31
            when 10 then return 30
            when 11 then return 31
        return 29 if year %% 400 is 0 or (year %% 4 is 0 and year %% 100 isnt 0)
        28

    createPuzzles: (date)->
        Seed = tool.createSeed(date)
        retPuzzleList = []
        puzzleNum = 4
        dailyChallengeAllPuzzle = []
        indexT = 0
        for obj, id in daily_challenge_stage
            dailyChallengeOnePuzzle = tool.createOnePuzzle(obj, id)
            return dailyChallengeAllPuzzle unless dailyChallengeOnePuzzle?
            dailyChallengeAllPuzzle.push dailyChallengeOnePuzzle
        return dailyChallengeAllPuzzle

    random: ->
        para = Math.sin(Seed) * 10000
        para = para - Math.floor(para)
        Seed += 20
        return para

    createSeed: (date)->
        month = String(date.getMonth())
        year = String(date.getYear())
        day = String(date.getDate())
        if month.length < 2 then month = "0" + month
        if day.length < 2 then day = "0" + day
        seedret = parseInt(year[year.length - 1] + month + day)
        return seedret

    getYMDString: (date) ->
        year = String(date.getFullYear())
        month = String(date.getMonth() + 1)
        day = String(date.getDate())
        if month.length < 2 then month = "0#{month}"
        if day.length < 2 then day = "0#{day}"
        "#{year}/#{month}/#{day}"

    decoratePuzzleArr: (puzzleArr)->
        bn: 0
        ans: puzzleArr
        add: []

    createOnePuzzle: (dailyChallengeStage, lv)->
        rewardCoin = dailyChallengeStage.reward_coin_ratio
        targetScore = dailyChallengeStage.target_points
        validMainWordList = tool.findAllValidPuzzle(dailyChallengeStage, lv)
        return if validMainWordList.length is 0
        index = Math.floor(tool.random() * (validMainWordList.length - 1))

        puzzleWordList = Puzzles[validMainWordList[index]]
        puzzleWordList.push validMainWordList[index]
        wordArr = puzzleWordList.map((item)->item.toUpperCase())
        shortestLen = dailyChallengeStage.clear_short_word_num
        wordArr = wordArr.filter((item)->item.length >= shortestLen)

        wordArr = tool.removeRepeat(wordArr)

        challengePuzzle = 
            puzzle: tool.decoratePuzzleArr(wordArr)
            targetScore: targetScore
            rewardCoin: rewardCoin
        return challengePuzzle

    removeRepeat: (arr)->
        newArr = []
        for item in arr
            if item not in newArr
                newArr.push item
        return newArr

    calTotalScore: (mainWord, lv)->
        totalScore = 0
        for word in Puzzles[mainWord]
            wordLen = word.length
            score = game_config[0]["daily_challenge_points_#{wordLen}"]
            continue if score <= 0
            shortestLen = daily_challenge_stage[lv].clear_short_word_num
            continue if wordLen < shortestLen
            totalScore += score
        return totalScore

    findAllValidPuzzle: (dailyChallengeStage, lv)->
        charNum = dailyChallengeStage.base_num
        targetScore = dailyChallengeStage.target_points
        difficultyRatio = dailyChallengeStage.difficulty_radio
        mainWordList = Object.keys(Puzzles).filter((word)->word.length is charNum)
        validMainWordList = []

        for mainWord in mainWordList
            continue if tool.calTotalScore(mainWord, lv) < targetScore * difficultyRatio
            validMainWordList.push mainWord
        return validMainWordList


module.exports = tool