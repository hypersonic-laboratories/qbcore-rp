const Keys = {
    ArrowUp: "arrowup",
    ArrowLeft: "arrowleft",
    ArrowDown: "arrowdown",
    ArrowRight: "arrowright",
};

let WrongKeyCount = 0;
let CurrentKey = 0;
let Key = 0;
let KeyPressed = false;
let CanPress = false;

const generateRandomPattern = (length) => {
    const keys = ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"];
    const pattern = [];

    for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(Math.random() * keys.length);
        pattern.push(keys[randomIndex]);
    }

    return pattern;
};

const showMinigame = () => {
    const container = document.querySelector(".keys-container");
    if (container) {
        container.style.transition = "opacity 300ms";
        container.style.opacity = 1;
        container.style.display = "flex";
    }
};

const hideMinigame = () => {
    const container = document.querySelector(".keys-container");
    if (container) {
        container.style.transition = "opacity 300ms";
        container.style.opacity = 0;
        setTimeout(() => {
            container.style.display = "none";
        }, 300);
    }
};

const keysTimer = (ms) => {
    return new Promise((resolve) => setTimeout(resolve, ms));
};

async function startKeygame(amount) {
    const pattern = generateRandomPattern(amount);
    showMinigame();
    await keysTimer(1000);

    for (let i = 0; i < pattern.length; i++) {
        Key = pattern[i];
        CurrentKey = i;

        if (!KeyPressed && CurrentKey !== 0) {
            WrongKeyCount += 1;
        }

        KeyPressed = false;

        let keyElement = document.querySelector(`.keys-container .key[data-key="${Keys[Key]}"]`);
        if (keyElement) {
            keyElement.style.backgroundColor = "orange";
        }

        CanPress = true;

        (function (k) {
            setTimeout(function () {
                let keyElement = document.querySelector(`.keys-container .key[data-key="${Keys[k]}"]`);
                if (keyElement) {
                    keyElement.style.backgroundColor = "white";
                }
                CanPress = false;
            }, 500);
        })(Key);

        if (CurrentKey + 1 === amount) {
            if (keyElement) {
                keyElement.style.backgroundColor = "white";
            }

            hideMinigame();

            await hEvent("keyminigameFinish", { faults: WrongKeyCount });

            WrongKeyCount = 0;
            CurrentKey = 0;
            Key = 0;
            KeyPressed = false;
        }

        await keysTimer(1500);
    }
}

document.addEventListener("keydown", function (event) {
    const keyName = event.key;

    if (keyName === "Escape") {
        hideMinigame();
        hEvent("keyminigameExit", {});
        WrongKeyCount = 0;
        CurrentKey = 0;
        Key = 0;
        KeyPressed = false;
        CanPress = false;
        TotalPresses = 10;
        return;
    }

    const keyDiv = document.querySelector(`.keys-container .key[data-key="${Keys[keyName]}"]`);
    if (!keyDiv) return;

    if (keyName === Key) {
        if (CanPress) {
            keyDiv.style.backgroundColor = "green";
            KeyPressed = true;
            CanPress = false;
        } else {
            if (!KeyPressed) {
                WrongKeyCount++;
                keyDiv.style.backgroundColor = "red";
                KeyPressed = true;
                CanPress = false;
                setTimeout(() => (keyDiv.style.backgroundColor = "white"), 300);
            }
        }
    } else {
        if (!KeyPressed) {
            WrongKeyCount++;
            keyDiv.style.backgroundColor = "red";
            KeyPressed = true;
            CanPress = false;
            setTimeout(() => (keyDiv.style.backgroundColor = "white"), 300);
        }
    }
});

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "startKeygame") {
        startKeygame(data.amount);
    }
});
