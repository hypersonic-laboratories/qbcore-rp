(function () {
    "use strict";

    var fingerprintFadeMs = 150;
    var fingerprintFadeTimer = null;

    var dom = {
        camContainer: document.getElementById("camcontainer"),
        cameraLabel: document.getElementById("camlabel"),
        dateLabel: document.getElementById("camdatelabel"),
        timeLabel: document.getElementById("camtimelabel"),
        ipLabel: document.getElementById("iplabel"),
        connectedLabel: document.getElementById("connectedlabel"),
        blockScreen: document.getElementById("blockscreen"),
        heliContainer: document.getElementById("helicontainer"),
        vehicleInfo: document.querySelector(".vehicleinfo"),
        scanBar: document.querySelector(".scanBar"),
        heliModel: document.querySelector(".heli-model p"),
        heliPlate: document.querySelector(".heli-plate p"),
        heliStreet: document.querySelector(".heli-street p"),
        heliSpeed: document.querySelector(".heli-speed p"),
        fingerprintContainer: document.querySelector(".fingerprint-container"),
        fingerprintId: document.querySelector(".fingerprint-id p"),
        takeFingerprint: document.querySelector(".take-fingerprint"),
    };

    function fallback(value, fallbackValue) {
        return value === undefined || value === null ? fallbackValue : value;
    }

    function setDisplay(element, visible, display) {
        if (!element) return;
        element.style.display = visible ? display || "block" : "none";
    }

    function setText(element, value) {
        if (!element) return;
        element.textContent = fallback(value, "");
    }

    function formatCameraDate() {
        var today = new Date();
        return today.getDate() + "/" + (today.getMonth() + 1) + "/" + today.getFullYear();
    }

    function formatCameraTime(time) {
        return "00:" + fallback(time, "00");
    }

    function emitNuiEvent(eventName) {
        if (typeof window.hEvent === "function") {
            window.hEvent(eventName);
        }
    }

    function getMessagePayload(message) {
        if (!message) {
            return {};
        }

        if (Array.isArray(message.args)) {
            return message.args[0] || {};
        }

        return message.args || message;
    }

    var CameraApp = {
        OpenCameras: function (label, connected, cameraId, time) {
            setDisplay(dom.camContainer, true);
            setText(dom.ipLabel, "145.101.0." + cameraId);

            if (connected) {
                setDisplay(dom.blockScreen, false);
                setText(dom.cameraLabel, label);
                setText(dom.connectedLabel, "CONNECTED");
                setText(dom.dateLabel, formatCameraDate());
                setText(dom.timeLabel, formatCameraTime(time));
            } else {
                setDisplay(dom.blockScreen, true);
                setText(dom.cameraLabel, "ERROR #400: BAD REQUEST");
                setText(dom.connectedLabel, "CONNECTION FAILED");
                setText(dom.dateLabel, "ERROR");
                setText(dom.timeLabel, "ERROR");
            }

            dom.connectedLabel.classList.toggle("connected", Boolean(connected));
            dom.connectedLabel.classList.toggle("disconnect", !connected);
        },

        CloseCameras: function () {
            setDisplay(dom.camContainer, false);
            setDisplay(dom.blockScreen, false);
        },

        UpdateCameraLabel: function (label) {
            setText(dom.cameraLabel, label);
        },

        UpdateCameraTime: function (time) {
            setText(dom.timeLabel, formatCameraTime(time));
        },
    };

    var HeliCam = {
        Open: function () {
            setDisplay(dom.heliContainer, true);
            dom.scanBar.style.height = "0%";
        },

        UpdateScan: function (data) {
            data = data || {};
            dom.scanBar.style.height = fallback(data.scanvalue, 0) + "%";
        },

        UpdateVehicleInfo: function (data) {
            data = data || {};
            setDisplay(dom.vehicleInfo, true);
            dom.scanBar.style.height = "100%";
            setText(dom.heliModel, "MODEL: " + fallback(data.model, ""));
            setText(dom.heliPlate, "PLATE: " + fallback(data.plate, ""));
            setText(dom.heliStreet, fallback(data.street, ""));
            setText(dom.heliSpeed, fallback(data.speed, "") + " KM/U");
        },

        DisableVehicleInfo: function () {
            setDisplay(dom.vehicleInfo, false);
        },

        Close: function () {
            setDisplay(dom.heliContainer, false);
            setDisplay(dom.vehicleInfo, false);
            dom.scanBar.style.height = "0%";
        },
    };

    var Fingerprint = {
        Open: function () {
            clearTimeout(fingerprintFadeTimer);
            setText(dom.fingerprintId, "No result");
            setDisplay(dom.fingerprintContainer, true);
            requestAnimationFrame(function () {
                dom.fingerprintContainer.classList.add("is-visible");
            });
        },

        Close: function (shouldNotify) {
            if (shouldNotify === undefined) {
                shouldNotify = true;
            }

            clearTimeout(fingerprintFadeTimer);
            dom.fingerprintContainer.classList.remove("is-visible");
            fingerprintFadeTimer = setTimeout(function () {
                setDisplay(dom.fingerprintContainer, false);
            }, fingerprintFadeMs);
            if (shouldNotify) {
                emitNuiEvent("closeFingerprint");
            }
        },

        Update: function (data) {
            data = data || {};
            setText(dom.fingerprintId, fallback(data.fingerprintId, ""));
        },
    };

    function handleMessage(event) {
        var eventData = event.data || {};
        var eventType = eventData.name || eventData.type;
        var payload = getMessagePayload(eventData);

        switch (eventType) {
            case "enablecam":
                CameraApp.OpenCameras(payload.label, payload.connected, payload.id, payload.time);
                break;
            case "disablecam":
                CameraApp.CloseCameras();
                break;
            case "updatecam":
                CameraApp.UpdateCameraLabel(payload.label);
                break;
            case "updatecamtime":
                CameraApp.UpdateCameraTime(payload.time);
                break;
            case "heliopen":
                HeliCam.Open();
                break;
            case "heliclose":
                HeliCam.Close();
                break;
            case "heliscan":
                HeliCam.UpdateScan(payload);
                break;
            case "heliupdateinfo":
                HeliCam.UpdateVehicleInfo(payload);
                break;
            case "disablescan":
                HeliCam.DisableVehicleInfo();
                break;
            case "fingerprintOpen":
                Fingerprint.Open();
                break;
            case "fingerprintClose":
                Fingerprint.Close(false);
                break;
            case "updateFingerprintId":
                Fingerprint.Update(payload);
                break;
        }
    }

    function handleKeydown(event) {
        if (event.key === "Escape") {
            event.preventDefault();
            Fingerprint.Close();
        }
    }

    function handleUnload() {
        window.removeEventListener("message", handleMessage);
        window.removeEventListener("keydown", handleKeydown);
    }

    if (dom.takeFingerprint) {
        dom.takeFingerprint.addEventListener("click", function () {
            emitNuiEvent("doFingerScan");
        });
    }

    window.addEventListener("message", handleMessage);
    window.addEventListener("keydown", handleKeydown);
    window.addEventListener("unload", handleUnload);

    window.CameraApp = CameraApp;
    window.HeliCam = HeliCam;
    window.Fingerprint = Fingerprint;
})();
