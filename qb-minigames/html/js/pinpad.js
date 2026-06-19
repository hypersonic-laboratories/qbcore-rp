const pinContainer = document.querySelector(".pinpad-container"),
    pinBox = document.getElementById("PINbox");

let pinValue = "";
let correctSequence = [];

const openPinpad = (pinNumber) => {
    correctSequence = pinNumber.split("");
    pinBox.value = "";
    pinValue = "";
    pinContainer.style.display = "block";
    setTimeout(() => (pinContainer.style.opacity = 1), 300);
};

const closePinpad = async () => {
    pinContainer.style.opacity = 0;
    setTimeout(async () => {
        pinContainer.style.display = "none";
        await hEvent("pinpadExit", {});
    }, 300);
};

const addNumber = (num) => {
    pinValue += num;
    pinBox.value += "*";

    if (pinValue.length === correctSequence.length) {
        checkSequence();
    }
};

const checkSequence = async () => {
    const isCorrect = pinValue === correctSequence.join("");
    pinValue = "";
    pinBox.value = "";
    await hEvent("pinpadFinish", { correct: isCorrect });
    closePinpad();
};

const clearInput = () => {
    pinValue = "";
    pinBox.value = "";
};

document.addEventListener("DOMContentLoaded", () => {
    const pinButtonsContainer = document.getElementById("PINcode");
    const clearButton = document.getElementById("clearButton");

    pinButtonsContainer.addEventListener("click", (event) => {
        const button = event.target;
        if (button.classList.contains("PINbutton") && button.id !== "clearButton") {
            addNumber(button.value);
        }
    });

    clearButton.addEventListener("click", clearInput);
});

document.addEventListener("keydown", function (event) {
    const keyName = event.key;
    if (keyName === "Escape") {
        closePinpad();
    }
});

window.addEventListener("message", (event) => {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const data = (msg.args && msg.args[0]) || {};
    if (msg.name === "openPinpad") {
        openPinpad(data.numbers.toString());
    }
});
