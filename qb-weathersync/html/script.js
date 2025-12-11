document.addEventListener("DOMContentLoaded", () => {
    const timeSlider = document.getElementById("timeSlider");
    const timeDisplay = document.getElementById("timeDisplay");
    const weatherBtns = document.querySelectorAll(".weather-btn");
    const auroraToggle = document.getElementById("auroraToggle");

    let auroraEnabled = false;

    /* ---- Time ---- */

    function updateTimeLabel() {
        const hour = parseInt(timeSlider.value, 10) || 0;
        const hStr = hour.toString().padStart(2, "0");
        timeDisplay.textContent = `${hStr}:00`;
    }

    timeSlider.addEventListener("input", () => {
        updateTimeLabel();

        hEvent("setTime", {
            hour: (parseInt(timeSlider.value, 10) || 0) * 100,
        });
    });

    /* ---- Weather ---- */

    weatherBtns.forEach((btn) => {
        btn.addEventListener("click", () => {
            weatherBtns.forEach((b) => b.classList.remove("active"));
            btn.classList.add("active");

            const weatherType = btn.dataset.weather;

            hEvent("setWeather", {
                weather: weatherType,
            });
        });
    });

    /* ---- Aurora toggle ---- */

    function sendAuroraState() {
        hEvent("toggleAurora", {
            enabled: auroraEnabled,
        });
    }

    auroraToggle.addEventListener("click", () => {
        auroraEnabled = !auroraEnabled;
        auroraToggle.classList.toggle("active", auroraEnabled);
        sendAuroraState();
    });

    /* ---- NUI show/hide from client.lua ---- */

    window.addEventListener("message", function (event) {
        const data = event.data;
        if (data && data.name === "toggle") {
            document.body.style.display = document.body.style.display === "none" ? "block" : "none";
        }
    });

    // Initial label based on default slider value
    updateTimeLabel();
});
