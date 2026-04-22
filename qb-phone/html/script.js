const { createApp } = Vue;

const HOME_APPS = [
    { label: "Calendar",   bgClass: "app-icon-calendar",   iconClass: "app-icon-calendar-symbol",   icon: "calendar-days" },
    { label: "Camera",     bgClass: "app-icon-camera",     iconClass: "app-icon-camera-symbol",     icon: "camera"        },
    { label: "Maps",       bgClass: "app-icon-maps",       iconClass: "app-icon-maps-symbol",       icon: "map-pin"       },
    { label: "Settings",   bgClass: "app-icon-settings",   iconClass: "app-icon-settings-symbol",   icon: "settings"      },
    { label: "Clock",      bgClass: "app-icon-clock",      iconClass: "app-icon-clock-symbol",      icon: "clock-3"       },
    { label: "Photos",     bgClass: "app-icon-photos",     iconClass: "app-icon-photos-symbol",     icon: "image"         },
    { label: "Calculator", bgClass: "app-icon-calculator", iconClass: "app-icon-calculator-symbol", icon: "calculator"    },
    { label: "Hmail",      bgClass: "app-icon-hmail",      iconClass: "app-icon-hmail-symbol",      icon: "mail"          },
];

const DOCK_APPS = [
    { label: "Phone",    bgClass: "dock-icon-phone",    iconClass: "dock-icon-phone-symbol",    icon: "phone"         },
    { label: "Messages", bgClass: "dock-icon-messages", iconClass: "dock-icon-messages-symbol", icon: "message-circle"},
    { label: "Browser",  bgClass: "dock-icon-browser",  iconClass: "dock-icon-browser-symbol",  icon: "compass"       },
    { label: "H",        bgClass: "app-icon-gene",      iconClass: "app-icon-gene-symbol",      icon: "dna"           },
];

createApp({
    components: {
        CalendarApp,
        PhoneApp,
        MessagesApp,
        GeneApp,
        CalculatorApp,
    },

    setup() {
        const { ref } = Vue;

        const phoneVisible = ref(false);
        const locked       = ref(true);
        const activeScreen = ref("home");

        const incomingCall = ref(null);
        const outgoingCall = ref(null);
        const activeCall   = ref(null);
        const callDuration = ref(0);
        let callTimer      = null;

        function navigateTo(screen) {
            activeScreen.value = screen;
        }

        function onDial(callInfo) {
            outgoingCall.value = callInfo;
        }

        function formatCallDuration(secs) {
            const m = String(Math.floor(secs / 60)).padStart(2, "0");
            const s = String(secs % 60).padStart(2, "0");
            return `${m}:${s}`;
        }

        function acceptCall() {
            hEvent("acceptCall", {});
        }

        function hangup() {
            hEvent("hangup", {});
            incomingCall.value = null;
            outgoingCall.value = null;
            activeCall.value   = null;
            callDuration.value = 0;
            if (callTimer) { clearInterval(callTimer); callTimer = null; }
        }

        window.addEventListener("message", (event) => {
            const { name, args = [] } = event.data;
            if (name === "open")  { phoneVisible.value = true;  return; }
            if (name === "close") { phoneVisible.value = false; return; }
            if (name === "incomingCall") {
                if (!phoneVisible.value) phoneVisible.value = true;
                incomingCall.value = { name: args[0], number: args[1] };
                return;
            }
            if (name === "callRinging") {
                outgoingCall.value = { name: args[0], number: args[1] };
                return;
            }
            if (name === "callStarted") {
                activeCall.value   = { ...(outgoingCall.value ?? incomingCall.value), channel: args[0] };
                outgoingCall.value = null;
                incomingCall.value = null;
                callDuration.value = 0;
                callTimer = setInterval(() => callDuration.value++, 1000);
                return;
            }
            if (name === "callEnded" || name === "callFailed") {
                incomingCall.value = null;
                outgoingCall.value = null;
                activeCall.value   = null;
                callDuration.value = 0;
                if (callTimer) { clearInterval(callTimer); callTimer = null; }
            }
        });

        function getFormattedTime()        { return "9:41";        }
        function getFormattedDate()        { return "Tue, Mar 27"; }
        function getWeatherTemperature()   { return "68°";         }

        const OPENABLE = new Set(["calendar", "phone", "messages", "h", "calculator"]);

        function openApp(label) {
            const key = label.toLowerCase();
            if (OPENABLE.has(key)) activeScreen.value = key;
        }

        return {
            HOME_APPS, DOCK_APPS,
            phoneVisible, locked, activeScreen,
            incomingCall, outgoingCall, activeCall, callDuration,
            formatCallDuration, acceptCall, hangup,
            navigateTo, onDial,
            getFormattedTime, getFormattedDate, getWeatherTemperature,
            openApp,
        };
    },
}).mount("#app");

// ── Lucide icon refresh ───────────────────────────────────────────────────────

(function () {
    let scheduled = false;

    const observer = new MutationObserver(() => {
        if (scheduled) return;
        scheduled = true;
        requestAnimationFrame(() => {
            lucide.createIcons();
            scheduled = false;
        });
    });

    observer.observe(document.getElementById("app"), {
        childList: true,
        subtree:   true,
    });

    lucide.createIcons();
})();
