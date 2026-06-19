const HEX_VALUES = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
const NUM_ROWS = 9;
const NUM_COLS = 18;
const PENALTY = 5000;

let solutions = ["", ""];
let solutionPos = [
    [1, 1],
    [1, 1],
];
let userSolPos = [
    [1, 1],
    [1, 15],
];
let gameStarted = false;
let solved = [false, false];
let endTime = 0;
let thread;
let mistakes = 0;
let lastBeep = 0;
let lastUpdateTime = 0;
let lastBeepTime = 0;
let gameTable = Array.from({ length: NUM_ROWS }, () => []);
let lastReseed = Array.from({ length: NUM_ROWS }, () => []);

const game = document.getElementById("game");
const hackingContainer = document.querySelector(".hacking-container");
const infobox = document.getElementById("infobox");
const screentext = document.getElementById("screentext");
const screen = document.getElementById("screen");

const resetGameState = () => {
    hackingContainer.style.display = "none";
    if (thread) {
        cancelAnimationFrame(thread);
        thread = null;
    }
    solutions = ["", ""];
    solutionPos = [
        [1, 1],
        [1, 1],
    ];
    userSolPos = [
        [1, 1],
        [1, 15],
    ];
    solved = [false, false];
    gameStarted = false;
    mistakes = 0;
    document.querySelectorAll(".sol2").forEach((el) => el.classList.remove("sol2"));
};

const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const wrongSolution = () => {
    mistakes++;
    endTime -= mistakes * PENALTY;
};

const playSound = (snd, vol) => {
    document.getElementById(snd).load();
    document.getElementById(snd).volume = vol;
    document.getElementById(snd).play();
};

const tryFinish = () => {
    if (solved.every((val) => val)) {
        document.getElementById("infobox").textContent = "Success";
        setTimeout(() => {
            playSound("audiofinish", 1);
            hEvent("hackSuccess", {});
            resetGameState();
        }, 2000);
    }
};

const writeSolution = () => {
    for (let i = 0; i < solutions[0].length; i++) {
        const cell1 = document.getElementById(`${solutionPos[0][0]}${solutionPos[0][1] + i}`);
        if (cell1) {
            cell1.textContent = solutions[0].charAt(i);
        }

        const cell2 = document.getElementById(`${solutionPos[1][0]}${solutionPos[1][1] + i}`);
        if (cell2) {
            cell2.textContent = solutions[1].charAt(i);
        }
    }
};

const writeUserSolution = () => {
    document.querySelectorAll(".sol").forEach((el) => el.classList.remove("sol"));
    for (let i = 0; i < solutions[0].length; i++) {
        const el1 = document.getElementById(`${userSolPos[0][0]}${userSolPos[0][1] + i}`);
        if (el1) {
            el1.textContent = solutions[0].charAt(i);
            el1.classList.add("sol");
        }

        const el2 = document.getElementById(`${userSolPos[1][0]}${userSolPos[1][1] + i}`);
        if (el2) {
            el2.textContent = solutions[1].charAt(i);
            el2.classList.add("sol");
        }
    }
};

const writeTime = () => {
    if (!solved.every((val) => val)) {
        document.getElementById("infobox").textContent = `${((endTime - new Date().getTime()) / 1000.0).toFixed(2)}s`;
    }
};

const seedTable = (timestamp) => {
    now = new Date().getTime();
    if (now >= endTime) {
        infobox.textContent = "Failure";
        setTimeout(() => {
            playSound("audiofail", 1);
            hEvent("hackFail", {});
            resetGameState();
        }, 2000);
        return;
    }

    writeTime();

    if (timestamp - lastUpdateTime > 200) {
        for (let i = 0; i < NUM_ROWS; i++) {
            for (let j = 0; j < NUM_COLS; j++) {
                const cellId = `${i + 1}${j + 1}`;
                const cell = document.getElementById(cellId);
                if (cell) {
                    gameTable[i][j] = HEX_VALUES[getRandomInt(0, 15)];
                    cell.textContent = gameTable[i][j];
                }
            }
        }
        writeSolution();
        writeUserSolution();
        lastUpdateTime = timestamp;
    }

    if (timestamp - lastBeepTime > 600) {
        playSound("audiobeep", 0.08);
        lastBeepTime = timestamp;
    }

    thread = requestAnimationFrame(seedTable);
};

const generateSolutions = (s) => {
    solutionPos[0] = [getRandomInt(1, 9), getRandomInt(1, 18 - s)];
    let goodsolution = false;
    while (!goodsolution) {
        solutionPos[1] = [getRandomInt(1, 9), getRandomInt(1, 18 - s)];
        if (solutionPos[0][0] == solutionPos[1][0]) {
            if (solutionPos[0][1] + s < solutionPos[1][1]) {
                goodsolution = true;
            } else if (solutionPos[0][1] > solutionPos[1][1] + s) {
                goodsolution = true;
            }
        } else {
            goodsolution = true;
        }
    }
    for (let i = 0; i < s; i++) {
        solutions[0] = solutions[0] + HEX_VALUES[getRandomInt(0, 15)];
        solutions[1] = solutions[1] + HEX_VALUES[getRandomInt(0, 15)];
    }
    userSolPos = [
        [1, 1],
        [1, 19 - s],
    ];
};

const startGame = (solutionsize, timeout) => {
    initializeGameTable();
    for (let i = 0; i < NUM_ROWS; i++) {
        for (let j = 0; j < NUM_COLS; j++) {
            lastReseed[i][j] = 0;
        }
    }
    generateSolutions(solutionsize);
    gameStarted = true;
    endTime = new Date().getTime() + timeout * 1000;
    if (thread) {
        cancelAnimationFrame(thread);
    }
    thread = requestAnimationFrame(seedTable);
};

const initializeGameTable = () => {
    const existingTable = document.getElementById("gametable");
    if (existingTable) {
        existingTable.remove();
    }
    const gametable = document.createElement("table");
    gametable.id = "gametable";

    for (let i = 0; i < 9; i++) {
        const row = document.createElement("tr");
        row.setAttribute("id", `row${i + 1}`);
        gametable.appendChild(row);

        for (let j = 0; j < 18; j++) {
            const cell = document.createElement("td");
            cell.setAttribute("id", `${i + 1}${j + 1}`);
            cell.innerHTML = "&nbsp;";
            row.appendChild(cell);
        }
    }
    const game = document.getElementById("game");
    game.appendChild(gametable);
};

document.addEventListener("keydown", (event) => {
    if (!gameStarted) return;

    const key = event.key;

    if (gameStarted && key === "Escape") {
        gameStarted = false;
        hEvent("hackClosed", { userCancelled: true });
        resetGameState();
        return;
    }

    if (!solved[0]) {
        switch (key) {
            case "w":
                if (userSolPos[0][0] > 1) userSolPos[0][0]--;
                break;
            case "a":
                if (userSolPos[0][1] > 1) userSolPos[0][1]--;
                break;
            case "s":
                if (userSolPos[0][0] < NUM_ROWS) userSolPos[0][0]++;
                break;
            case "d":
                if (userSolPos[0][1] < NUM_COLS) userSolPos[0][1]++;
                break;
        }
    }

    if (!solved[1]) {
        switch (key) {
            case "ArrowUp":
                if (userSolPos[1][0] > 1) userSolPos[1][0]--;
                break;
            case "ArrowLeft":
                if (userSolPos[1][1] > 1) userSolPos[1][1]--;
                break;
            case "ArrowDown":
                if (userSolPos[1][0] < NUM_ROWS) userSolPos[1][0]++;
                break;
            case "ArrowRight":
                if (userSolPos[1][1] < NUM_COLS - solutions[1].length + 1) userSolPos[1][1]++;
                break;
        }
    }

    if (!solved[0] && key === " ") {
        if (userSolPos[0][0] === solutionPos[0][0] && userSolPos[0][1] === solutionPos[0][1]) {
            solved[0] = true;
            for (let i = 0; i < solutions[0].length; i++) {
                const cellId = userSolPos[0][0] + "" + (userSolPos[0][1] + i);
                const cell = document.getElementById(cellId);
                cell.classList.add("sol2");
            }
            const sol2Elements = document.querySelectorAll(".sol2");
            sol2Elements.forEach((el) => {
                el.style.transition = "opacity 0.5s";
                el.style.opacity = "0";
                setTimeout(() => (el.style.opacity = "1"), 500);
            });
            playSound("audiocorrect", 1);
            tryFinish();
        } else {
            playSound("audiowrong", 1);
            wrongSolution();
        }
    }

    if (!solved[1] && key === "Enter") {
        if (userSolPos[1][0] === solutionPos[1][0] && userSolPos[1][1] === solutionPos[1][1]) {
            solved[1] = true;
            for (let i = 0; i < solutions[1].length; i++) {
                const cellId = userSolPos[1][0] + "" + (userSolPos[1][1] + i);
                const cell = document.getElementById(cellId);
                cell.classList.add("sol2");
            }
            const sol2Elements = document.querySelectorAll(".sol2");
            sol2Elements.forEach((el) => {
                el.style.transition = "opacity 0.5s";
                el.style.opacity = "0";
                setTimeout(() => (el.style.opacity = "1"), 500);
            });
            playSound("audiocorrect", 1);
            tryFinish();
        } else {
            playSound("audiowrong", 1);
            wrongSolution();
        }
    }
});

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "startHack") {
        if (!gameStarted) {
            hackingContainer.style.display = "flex";
            startGame(data.solutionsize, data.timeout);
        }
    }
});
