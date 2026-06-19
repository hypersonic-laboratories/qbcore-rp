local webui = WebUI('qb-minigames', 'qb-minigames/html/index.html')

-- HACKING

local hacking

webui:RegisterEventHandler('hackSuccess', function(_, cb)
    if cb then
        cb('ok')
    end
    if not hacking then
        return
    end
    webui:SetInputMode(0)
    hacking:resolve(true)
    hacking = nil
end)

webui:RegisterEventHandler('hackFail', function(_, cb)
    if cb then
        cb('ok')
    end
    if not hacking then
        return
    end
    webui:SetInputMode(0)
    hacking:resolve(false)
    hacking = nil
end)

webui:RegisterEventHandler('hackClosed', function(_, cb)
    if cb then
        cb('ok')
    end
    if not hacking then
        return
    end
    webui:SetInputMode(0)
    hacking:resolve(false)
    hacking = nil
end)

local function Hacking(solutionsize, timeout)
    hacking = promise.new()
    webui:SendEvent('startHack', { solutionsize = solutionsize, timeout = timeout })
    webui:BringToFront()
    webui:SetInputMode(1)
    return hacking:await()
end
exports('qb-minigames', 'Hacking', Hacking)

-- KEY MINIGAME

local keyminigame

webui:RegisterEventHandler('keyminigameExit', function(_, cb)
    if cb then
        cb('ok')
    end
    if not keyminigame then
        return
    end
    webui:SetInputMode(0)
    keyminigame:resolve({ quit = true, faults = 0 })
    keyminigame = nil
end)

webui:RegisterEventHandler('keyminigameFinish', function(data, cb)
    if cb then
        cb('ok')
    end
    if not keyminigame then
        return
    end
    webui:SetInputMode(0)
    keyminigame:resolve({ quit = false, faults = data.faults })
    keyminigame = nil
end)

local function KeyMinigame(amount)
    keyminigame = promise.new()
    webui:SendEvent('startKeygame', { amount = amount })
    webui:BringToFront()
    webui:SetInputMode(1)
    return keyminigame:await()
end
exports('qb-minigames', 'KeyMinigame', KeyMinigame)

-- LOCKPICK

local lockpick

webui:RegisterEventHandler('lockpickExit', function(_, cb)
    if cb then
        cb('ok')
    end
    if not lockpick then
        return
    end
    webui:SetInputMode(0)
    lockpick:resolve(false)
    lockpick = nil
end)

webui:RegisterEventHandler('lockpickFinish', function(data, cb)
    if cb then
        cb('ok')
    end
    if not lockpick then
        return
    end
    webui:SetInputMode(0)
    lockpick:resolve(data.success)
    lockpick = nil
end)

local function Lockpick(pins)
    lockpick = promise.new()
    webui:SendEvent('startLockpick', { pins = pins })
    webui:BringToFront()
    webui:SetInputMode(1)
    return lockpick:await()
end
exports('qb-minigames', 'Lockpick', Lockpick)

-- PINPAD

local pinpadPromise

webui:RegisterEventHandler('pinpadExit', function(_, cb)
    if cb then
        cb('ok')
    end
    if not pinpadPromise then
        return
    end
    webui:SetInputMode(0)
    pinpadPromise:resolve({ quit = true })
    pinpadPromise = nil
end)

webui:RegisterEventHandler('pinpadFinish', function(data, cb)
    if cb then
        cb('ok')
    end
    if not pinpadPromise then
        return
    end
    webui:SetInputMode(0)
    pinpadPromise:resolve({ quit = false, correct = data.correct })
    pinpadPromise = nil
end)

local function StartPinpad(numbers)
    pinpadPromise = promise.new()
    webui:SendEvent('openPinpad', { numbers = numbers })
    webui:BringToFront()
    webui:SetInputMode(1)
    return pinpadPromise:await()
end
exports('qb-minigames', 'StartPinpad', StartPinpad)

-- QUIZ

local quiz
local required = 0

webui:RegisterEventHandler('exitQuiz', function(_, cb)
    if cb then
        cb('ok')
    end
    if not quiz then
        return
    end
    webui:SetInputMode(0)
    quiz:resolve(false)
    quiz = nil
    required = 0
end)

webui:RegisterEventHandler('closeQuiz', function(_, cb)
    if cb then
        cb('ok')
    end
    if not quiz then
        return
    end
    webui:SetInputMode(0)
    quiz:resolve(false)
    quiz = nil
    required = 0
end)

webui:RegisterEventHandler('quitQuiz', function(data, cb)
    if cb then
        cb('ok')
    end
    if not quiz then
        return
    end
    if data.score >= required then
        quiz:resolve(true)
    else
        quiz:resolve(false)
    end
    webui:SetInputMode(0)
    quiz = nil
    required = 0
end)

local function Quiz(questions, correctRequired, timer)
    for i, question in ipairs(questions) do
        question.numb = i
    end
    required = correctRequired
    quiz = promise.new()
    webui:SendEvent('startQuiz', { questions = questions, timer = timer })
    webui:BringToFront()
    webui:SetInputMode(1)
    return quiz:await()
end
exports('qb-minigames', 'Quiz', Quiz)

-- SKILLBAR

local skillbar

webui:RegisterEventHandler('skillbarFinish', function(data, cb)
    if cb then
        cb('ok')
    end
    if not skillbar then
        return
    end
    webui:SetInputMode(0)
    skillbar:resolve(data.success)
    skillbar = nil
end)

local function Skillbar(difficulty, validKeys)
    skillbar = promise.new()
    webui:SendEvent('openSkillbar', { difficulty = difficulty or 'easy', validKeys = validKeys or '1234' })
    webui:BringToFront()
    webui:SetInputMode(1)
    return skillbar:await()
end
exports('qb-minigames', 'Skillbar', Skillbar)

-- WORD GUESS

local wordGuess

webui:RegisterEventHandler('wordGuessedCorrectly', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordGuess then
        return
    end
    webui:SetInputMode(0)
    wordGuess:resolve(true)
    wordGuess = nil
    webui:SendEvent('closeWordGuess', {})
end)

webui:RegisterEventHandler('tooManyGuesses', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordGuess then
        return
    end
    webui:SetInputMode(0)
    wordGuess:resolve(false)
    wordGuess = nil
    webui:SendEvent('closeWordGuess', {})
end)

webui:RegisterEventHandler('closeWordGuess', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordGuess then
        return
    end
    webui:SetInputMode(0)
    wordGuess:resolve(false)
    wordGuess = nil
end)

local function WordGuess(word, hint, guesses)
    wordGuess = promise.new()
    webui:SendEvent('wordGuess', { word = word, hint = hint, maxGuesses = guesses })
    webui:BringToFront()
    webui:SetInputMode(1)
    return wordGuess:await()
end
exports('qb-minigames', 'WordGuess', WordGuess)

-- WORD SCRAMBLE

local wordScramble

webui:RegisterEventHandler('scrambleIncorrect', function(_, cb)
    if cb then
        cb('ok')
    end
    exports['qb-core']:Notify('Incorrect word', 'error', 2500)
end)

webui:RegisterEventHandler('scrambleCorrect', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordScramble then
        return
    end
    exports['qb-core']:Notify('Guessed correctly!', 'success', 2500)
    webui:SetInputMode(0)
    wordScramble:resolve(true)
    wordScramble = nil
    webui:SendEvent('close', {})
end)

webui:RegisterEventHandler('scrambleTimeOut', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordScramble then
        return
    end
    webui:SetInputMode(0)
    wordScramble:resolve(false)
    wordScramble = nil
    webui:SendEvent('close', {})
end)

webui:RegisterEventHandler('closeScramble', function(_, cb)
    if cb then
        cb('ok')
    end
    if not wordScramble then
        return
    end
    webui:SetInputMode(0)
    wordScramble:resolve(false)
    wordScramble = nil
    webui:SendEvent('close', {})
end)

local function WordScramble(word, hint, timer)
    wordScramble = promise.new()
    webui:SendEvent('wordScramble', { word = word, hint = hint, time = timer })
    webui:BringToFront()
    webui:SetInputMode(1)
    return wordScramble:await()
end
exports('qb-minigames', 'WordScramble', WordScramble)
