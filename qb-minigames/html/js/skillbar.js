const canvas = document.getElementById("skillbar");
const context = canvas.getContext("2d");
const W = canvas.width;
const H = canvas.height;

const config = {
    indicatorColor: "#FF0000",
    backgroundArcColor: "#FFFFFF",
    greenZoneColor: "#FFFFFF",
    validKeys: [],
    backgroundArcWidth: 2,
    greenZoneWidth: 20,
    indicatorLineWidth: 50,
    keyPressColor: "#FFFFFF",
    keyPressFontSize: "100px Arial", // adjust line 130 for centering if you change this
};

const difficultySettings = {
    easy: {
        greenZoneSize: 10, // adjust this in small increments
        speed: 15,
        streaksRequired: 3,
    },
    medium: {
        greenZoneSize: 8,
        speed: 25,
        streaksRequired: 4,
    },
    hard: {
        greenZoneSize: 6,
        speed: 35,
        streaksRequired: 5,
    },
};

let lastTime = 0;
let currentDifficulty;
let needed = 1;
let streak = 0;
let time;
let degrees = 0;
let newDegrees = 0;
let gStart;
let gEnd;
let keyToPress;
let animationFrame;

// Util

const getRandomInteger = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
};

const degreesToRadians = (degrees) => {
    return (degrees * Math.PI) / 180;
};

const radiansToDegrees = (radians) => {
    return radians * (180 / Math.PI);
};

// Main Functions

const startSkillbar = (difficulty, validKeys) => {
    canvas.style.display = "block";
    config.validKeys = validKeys.split("");
    currentDifficulty = difficulty;
    const settings = difficultySettings[currentDifficulty];
    needed = settings.streaksRequired;
    newDegrees = 360;
    keyToPress = config.validKeys[getRandomInteger(0, config.validKeys.length - 1)];
    gStart = getRandomInteger(20, 40) / 10;
    gEnd = gStart + settings.greenZoneSize / 10;
    degrees = 0;
    animateSkillbar();
};

const animateSkillbar = (timestamp) => {
    if (timestamp !== undefined) {
        if (lastTime === 0) {
            lastTime = timestamp;
        }

        const deltaTime = timestamp - lastTime;
        const speedPerSecond = difficultySettings[currentDifficulty].speed;
        const increment = (deltaTime / 1000) * speedPerSecond * 10;

        degrees += increment;

        if (degrees >= newDegrees) {
            handleResult(false);
        } else {
            renderSkillbar();
            lastTime = timestamp;
            animationFrame = requestAnimationFrame(animateSkillbar);
        }
    } else {
        animationFrame = requestAnimationFrame(animateSkillbar);
    }
};

const drawArc = (x, y, radius, startAngle, endAngle, strokeColor, lineWidth) => {
    context.beginPath();
    context.strokeStyle = strokeColor;
    context.lineWidth = lineWidth;
    context.arc(x, y, radius, startAngle, endAngle, false);
    context.stroke();
};

const renderSkillbar = () => {
    context.clearRect(0, 0, W, H);

    // Draw the background arc - would like to move this so it's not redrawn but meh
    drawArc(W / 2, H / 2, 100, 0, Math.PI * 2, config.backgroundArcColor, config.backgroundArcWidth);

    // Draw the green zone
    drawArc(W / 2, H / 2, 100, gStart - Math.PI / 2, gEnd - Math.PI / 2, config.greenZoneColor, config.greenZoneWidth);

    // Draw the moving indicator
    const radians = degreesToRadians(degrees);
    drawArc(W / 2, H / 2, 100 - 10, radians - 0.1 - Math.PI / 2, radians - Math.PI / 2, config.indicatorColor, config.indicatorLineWidth);

    // Display the key to press
    const text = keyToPress.toUpperCase();
    context.fillStyle = config.keyPressColor;
    context.font = config.keyPressFontSize;
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText(text, W / 2, H / 2 + 5);
};

const reanimateSkillbar = () => {
    if (animationFrame) cancelAnimationFrame(animationFrame);
    const settings = difficultySettings[currentDifficulty];
    gStart = getRandomInteger(20, 40) / 10;
    gEnd = gStart + settings.greenZoneSize / 10;
    needed = settings.streaksRequired;
    lastTime = 0;
    degrees = 0;
    newDegrees = 360;
    keyToPress = config.validKeys[getRandomInteger(0, config.validKeys.length - 1)];
    animateSkillbar();
};

// Handlers

const handleResult = (isCorrect) => {
    if (animationFrame) cancelAnimationFrame(animationFrame);
    if (isCorrect) {
        streak++;
        if (streak === needed) {
            endGame(true);
        } else {
            reanimateSkillbar();
        }
    } else {
        endGame(false);
    }
};

const resetSkillbar = () => {
    canvas.style.display = "none";
    cancelAnimationFrame(animationFrame);
    streak = 0;
    needed = 1;
    lastTime = 0;
};

const endGame = (status) => {
    document.removeEventListener("keydown", handleKeyDown);
    hEvent("skillbarFinish", { success: status });
    resetSkillbar();
};

const handleKeyDown = (ev) => {
    const keyPressed = ev.key;
    if (config.validKeys.includes(keyPressed)) {
        const d_start = radiansToDegrees(gStart);
        const d_end = radiansToDegrees(gEnd);

        if (keyPressed === keyToPress && degrees >= d_start && degrees <= d_end) {
            streak += 1;
            if (streak === needed) {
                endGame(true);
            } else {
                reanimateSkillbar();
            }
        } else {
            endGame(false);
        }
    }
};

const handleWindowMessage = (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "openSkillbar") {
        document.addEventListener("keydown", handleKeyDown);
        startSkillbar(data.difficulty, data.validKeys);
    }
};

window.addEventListener("message", handleWindowMessage);
