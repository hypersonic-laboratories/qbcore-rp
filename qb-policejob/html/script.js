const openFingerprint = function () {
    document.querySelector(".fingerprint-container").style.display = "block";
    document.querySelector(".fingerprint-id").innerHTML = "Fingerprint ID<p>No result</p>";
};

const closeFingerprint = function () {
    document.querySelector(".fingerprint-container").style.display = "none";
};

const updateFingerprint = function (data) {
    document.querySelector(".fingerprint-id").innerHTML = "Fingerprint ID<p>" + data.fingerprintId + "</p>";
};

window.addEventListener('message', (event) => {
    const eventName = event.data.name;
    const eventArgs = event.data.args;
    switch (eventName) {
        case "openFingerprint":
            openFingerprint();
            break;
        case "closeFingerprint":
            closeFingerprint();
            break;
        case "updateFingerprint":
            updateFingerprint(eventArgs[0]);
            break;
    }
})

window.addEventListener('DOMContentLoaded', () => {
    document.querySelector(".take-fingerprint").addEventListener("click", function () {
        hEvent("scanFinger");
    })

    document.addEventListener('mousedown', (event) => {
        if (event.button === 2)
            hEvent('closeFingerprint');
    })
})