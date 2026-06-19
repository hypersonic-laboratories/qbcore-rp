const inputs = document.querySelector(".inputs"),
    hintTag = document.querySelector(".guess-hint span"),
    guessLeft = document.querySelector(".guess-left span"),
    wrongLetter = document.querySelector(".wrong-letter span"),
    typingInput = document.querySelector(".typing-input"),
    guessContainer = document.querySelector(".guess-container");

let word,
    maxGuesses,
    incorrectLetters = [],
    correctLetters = [];

const setupWordGuessGame = (receivedWord, receivedHint, maxAllowedGuesses) => {
    word = receivedWord.toLowerCase();
    maxGuesses = maxAllowedGuesses;
    correctLetters = Array(word.length).fill("");
    incorrectLetters = [];

    hintTag.textContent = receivedHint;
    guessLeft.textContent = maxGuesses;
    wrongLetter.textContent = incorrectLetters.join(", ");

    let html = "";
    for (let i = 0; i < word.length; i++) {
        html += `<input type="text" disabled>`;
    }
    inputs.innerHTML = html;
    guessContainer.style.display = "flex";
};

const initGuessGame = (key) => {
    if (!key.match(/^[A-Za-z]$/) || incorrectLetters.includes(key) || correctLetters.includes(key)) {
        return;
    }

    if (word.includes(key)) {
        word.split("").forEach((char, index) => {
            if (char === key) {
                correctLetters[index] = key;
                inputs.querySelectorAll("input")[index].value = key;
            }
        });
    } else {
        maxGuesses--;
        incorrectLetters.push(key);
    }

    guessLeft.textContent = maxGuesses;
    wrongLetter.textContent = incorrectLetters.join(", ");
    checkGameStatus();
    typingInput.value = "";
};

const checkGameStatus = () => {
    if (!correctLetters.includes("")) {
        hEvent("wordGuessedCorrectly", {});
    } else if (maxGuesses <= 0) {
        hEvent("tooManyGuesses", {});
        revealWord();
    }
};

const revealWord = () => {
    word.split("").forEach((char, index) => {
        inputs.querySelectorAll("input")[index].value = char;
    });
};

const resetGuessGame = () => {
    setupWordGuessGame("", "", 0);
    typingInput.value = "";
    guessContainer.style.display = "none";
};

document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        hEvent("closeWordGuess", {});
        resetGuessGame();
    }
});

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "wordGuess") {
        setupWordGuessGame(data.word, data.hint, data.maxGuesses);
    } else if (msg.name === "closeWordGuess") {
        resetGuessGame();
    }
});

typingInput.addEventListener("input", (e) => initGuessGame(e.target.value.toLowerCase()));
inputs.addEventListener("click", () => typingInput.focus());
