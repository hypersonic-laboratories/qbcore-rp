let UIVisible = false;

function setVisible(visible) {
    const container = document.querySelector(".container");
    if (!container) return;

    container.style.display = visible ? "block" : "none";
    UIVisible = visible;
}

function getMaxStock(stock, level) {
    if (!stock.Max) return 0;
    return stock.Max[level - 1] || stock.Max[level] || 0;
}

function updateStock(data) {
    Object.keys(data.Stock || {}).forEach((key) => {
        const stock = data.Stock[key];
        const parent = document.querySelector(`.hotdogs-stocks [data-stock="${key}"]`);
        const span = parent && parent.querySelector(".stock-amount");
        if (!span) return;

        span.textContent = `${stock.Current} / ${getMaxStock(stock, data.Level.lvl)}`;
    });

    const level = document.querySelector("#my-level");
    if (level) {
        level.textContent = `LEVEL ${data.Level.lvl} : ${data.Level.rep || 0}xp`;
    }
}

function UpdateUI(data) {
    if (!data || !data.Stock || !data.Level) return;

    if (data.IsActive) {
        if (!UIVisible) {
            setVisible(true);
        }
        updateStock(data);
    } else {
        setVisible(false);
    }
}

document.addEventListener("DOMContentLoaded", function () {
    window.addEventListener("message", function (event) {
        const data = event.data || {};
        const args = data.args && data.args[0] ? data.args[0] : data;

        if (data.name === "UpdateUI" || data.action === "UpdateUI") {
            UpdateUI(args);
        }
    });
});
