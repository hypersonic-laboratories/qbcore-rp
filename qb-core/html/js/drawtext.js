let direction = null;

const sleep = (ms) => {
    return new Promise((resolve) => setTimeout(resolve, ms));
};

const removeClass = (element, name) => {
    if (element.classList.contains(name)) {
        element.classList.remove(name);
    }
};

const addClass = (element, name) => {
    if (!element.classList.contains(name)) {
        element.classList.add(name);
    }
};

const drawText = async (text, position) => {
    const textElement = document.getElementById("text");
    switch (position) {
        case "left":
            addClass(textElement, position);
            direction = "left";
            break;
        case "top":
            addClass(textElement, position);
            direction = "top";
            break;
        case "right":
            addClass(textElement, position);
            direction = "right";
            break;
        default:
            addClass(textElement, "left");
            direction = "left";
            break;
    }

    textElement.innerHTML = text;
    document.getElementById("drawtext-container").style.display = "block";
    await sleep(100);
    addClass(textElement, "show");
};

const changeText = async (text, position) => {
    const textElement = document.getElementById("text");
    removeClass(textElement, "show");
    addClass(textElement, "pressed");
    addClass(textElement, "hide");
    await sleep(500);
    removeClass(textElement, "left");
    removeClass(textElement, "right");
    removeClass(textElement, "top");
    removeClass(textElement, "bottom");
    removeClass(textElement, "hide");
    removeClass(textElement, "pressed");

    switch (position) {
        case "left":
            addClass(textElement, position);
            direction = "left";
            break;
        case "top":
            addClass(textElement, position);
            direction = "top";
            break;
        case "right":
            addClass(textElement, position);
            direction = "right";
            break;
        default:
            addClass(textElement, "left");
            direction = "left";
            break;
    }
    textElement.innerHTML = text;
    await sleep(100);
    textElement.classList.add("show");
};

const hideText = async () => {
    const textElement = document.getElementById("text");
    removeClass(textElement, "show");
    addClass(textElement, "hide");
    setTimeout(() => {
        removeClass(textElement, "left");
        removeClass(textElement, "right");
        removeClass(textElement, "top");
        removeClass(textElement, "bottom");
        removeClass(textElement, "hide");
        removeClass(textElement, "pressed");
        document.getElementById("drawtext-container").style.display = "none";
    }, 1000);
};

const keyPressed = () => {
    const textElement = document.getElementById("text");
    addClass(textElement, "pressed");
};
