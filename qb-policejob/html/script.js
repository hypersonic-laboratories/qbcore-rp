const CameraApp = new Vue({
    el: "#camcontainer",

    data: {
        camerasOpen: false,
        cameraLabel: ":)",
        connectLabel: "CONNECTED",
        ipLabel: "192.168.0.1",
        dateLabel: "04/09/1999",
        timeLabel: "16:27:49",
    },

    methods: {
        OpenCameras(label, connected, cameraId, time) {
            var today = new Date();
            var date = today.getDate() + "/" + (today.getMonth() + 1) + "/" + today.getFullYear();
            var formatTime = "00:" + time;

            this.camerasOpen = true;
            this.ipLabel = "145.101.0." + cameraId;
            if (connected) {
                $("#blockscreen").css("display", "none");
                this.cameraLabel = label;
                this.connectLabel = "CONNECTED";
                this.dateLabel = date;
                this.timeLabel = formatTime;

                $("#connectedlabel").removeClass("disconnect");
                $("#connectedlabel").addClass("connect");
            } else {
                $("#blockscreen").css("display", "block");
                this.cameraLabel = "ERROR #400: BAD REQUEST";
                this.connectLabel = "CONNECTION FAILED";
                this.dateLabel = "ERROR";
                this.timeLabel = "ERROR";

                $("#connectedlabel").removeClass("connect");
                $("#connectedlabel").addClass("disconnect");
            }
        },

        CloseCameras() {
            this.camerasOpen = false;
            $("#blockscreen").css("display", "none");
        },

        UpdateCameraLabel(label) {
            this.cameraLabel = label;
        },

        UpdateCameraTime(time) {
            var formatTime = "00:" + time;
            this.timeLabel = formatTime;
        },
    },
});

HeliCam = {};
Databank = {};
Fingerprint = {};

HeliCam.Open = function (data) {
    $("#helicontainer").css("display", "block");
    $(".scanBar").css("height", "0%");
};

HeliCam.UpdateScan = function (data) {
    $(".scanBar").css("height", data.scanvalue + "%");
};

HeliCam.UpdateVehicleInfo = function (data) {
    $(".vehicleinfo").css("display", "block");
    $(".scanBar").css("height", "100%");
    $(".heli-model")
        .find("p")
        .html("MODEL: " + data.model);
    $(".heli-plate")
        .find("p")
        .html("PLATE: " + data.plate);
    $(".heli-street").find("p").html(data.street);
    $(".heli-speed")
        .find("p")
        .html(data.speed + " KM/U");
};

HeliCam.DisableVehicleInfo = function () {
    $(".vehicleinfo").css("display", "none");
};

HeliCam.Close = function () {
    $("#helicontainer").css("display", "none");
    $(".vehicleinfo").css("display", "none");
    $(".scanBar").css("height", "0%");
};

Databank.Open = function () {
    $(".databank-container").css("display", "block").css("user-select", "none");
    $(".databank-container iframe").css("display", "block");
    $(".tablet-frame").css("display", "block").css("user-select", "none");
    $(".databank-bg").css("display", "block");
};

Databank.Close = function () {
    $(".databank-container iframe").css("display", "none");
    $(".databank-container").css("display", "none");
    $(".tablet-frame").css("display", "none");
    $(".databank-bg").css("display", "none");
    hEvent("closeDatabank");
};

Fingerprint.Open = function () {
    $(".fingerprint-container").fadeIn(150);
    $(".fingerprint-id").html("Fingerprint ID<p>No result</p>");
};

Fingerprint.Close = function () {
    $(".fingerprint-container").fadeOut(150);
    hEvent("closeFingerprint");
};

Fingerprint.Update = function (data) {
    $(".fingerprint-id").html("Fingerprint ID<p>" + data.fingerprintId + "</p>");
};

$(document).on("click", ".take-fingerprint", function () {
    hEvent("doFingerScan");
});

document.onreadystatechange = () => {
    if (document.readyState === "complete") {
        window.addEventListener("message", function (event) {
            const eventType = event.data.type || event.data.name;
            const payload = event.data.args && event.data.args.length ? event.data.args[0] : event.data;

            if (eventType == "enablecam") {
                CameraApp.OpenCameras(payload.label, payload.connected, payload.id, payload.time);
            } else if (eventType == "disablecam") {
                CameraApp.CloseCameras();
            } else if (eventType == "updatecam") {
                CameraApp.UpdateCameraLabel(payload.label);
            } else if (eventType == "updatecamtime") {
                CameraApp.UpdateCameraTime(payload.time);
            } else if (eventType == "heliopen") {
                HeliCam.Open(payload);
            } else if (eventType == "heliclose") {
                HeliCam.Close();
            } else if (eventType == "heliscan") {
                HeliCam.UpdateScan(payload);
            } else if (eventType == "heliupdateinfo") {
                HeliCam.UpdateVehicleInfo(payload);
            } else if (eventType == "disablescan") {
                HeliCam.DisableVehicleInfo();
            } else if (eventType == "databank") {
                Databank.Open();
            } else if (eventType == "closedatabank") {
                Databank.Close();
            } else if (eventType == "fingerprintOpen") {
                Fingerprint.Open();
            } else if (eventType == "fingerprintClose") {
                Fingerprint.Close();
            } else if (eventType == "updateFingerprintId") {
                Fingerprint.Update(payload);
            }
        });
    }
};

$(document).on("keydown", function (event) {
    switch (event.keyCode) {
        case 27: // ESC
            Databank.Close();
            Fingerprint.Close();
            break;
    }
});
