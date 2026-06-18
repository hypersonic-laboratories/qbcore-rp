const { createApp } = Vue;

const HOME_APPS = [
    { label: "Calendar", bgClass: "app-icon-calendar", iconClass: "app-icon-calendar-symbol", icon: "calendar-days" },
    // { label: "Maps",       bgClass: "app-icon-maps",       iconClass: "app-icon-maps-symbol",       icon: "map-pin"       },
    { label: "Settings", bgClass: "app-icon-settings", iconClass: "app-icon-settings-symbol", icon: "settings" },
    { label: "Clock", bgClass: "app-icon-clock", iconClass: "app-icon-clock-symbol", icon: "clock-3" },
    { label: "Photos", bgClass: "app-icon-photos", iconClass: "app-icon-photos-symbol", icon: "image" },
    { label: "Calculator", bgClass: "app-icon-calculator", iconClass: "app-icon-calculator-symbol", icon: "calculator" },
    { label: "Hmail", bgClass: "app-icon-hmail", iconClass: "app-icon-hmail-symbol", icon: "mail" },
];

const DOCK_APPS = [
    { label: "Phone", bgClass: "dock-icon-phone", iconClass: "dock-icon-phone-symbol", icon: "phone" },
    { label: "Messages", bgClass: "dock-icon-messages", iconClass: "dock-icon-messages-symbol", icon: "message-circle" },
    { label: "Camera", bgClass: "dock-icon-camera", iconClass: "dock-icon-camera-symbol", icon: "camera" },
    { label: "H", bgClass: "app-icon-gene", iconClass: "app-icon-gene-symbol", icon: "dna" },
];

createApp({
    components: {
        CalendarApp,
        PhoneApp,
        MessagesApp,
        GeneApp,
        CalculatorApp,
        CameraApp,
        PhotosApp,
        ClockApp,
        SettingsApp,
        HmailApp,
    },

    setup() {
        const { ref, computed, watch, onMounted, onBeforeUnmount } = Vue;

        const phoneVisible = ref(false);
        const locked = ref(true);
        const activeScreen = ref("home");
        const darkMode = window.PhoneStore.darkMode;
        watch(darkMode, (enabled) => window.PhoneStore.saveDarkMode(enabled));
        const wallpaperUrl = window.PhoneStore.wallpaperUrl;
        watch(wallpaperUrl, (url) => window.PhoneStore.saveWallpaper(url));
        const caseColorId = window.PhoneStore.caseColorId;
        watch(caseColorId, (id) => window.PhoneStore.saveCaseColor(id));
        const activeCaseColor = computed(() => window.CASE_COLORS.find((c) => c.id === caseColorId.value) ?? window.CASE_COLORS[0]);

        const incomingCall = ref(null);
        const outgoingCall = ref(null);
        const activeCall = ref(null);
        const callDuration = ref(0);
        let callTimer = null;
        const notification = ref(null);
        let notifTimer = null;
        let captureWasVisible = false;

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

        function showNotif(appKey, data) {
            const { dnd, notifSettings } = window.PhoneStore;
            if (dnd.value) return;
            if (!notifSettings[appKey]) return;
            notification.value = data;
            if (notifTimer) clearTimeout(notifTimer);
            notifTimer = setTimeout(() => {
                notification.value = null;
                notifTimer = null;
            }, 5000);
        }

        function clearNotification() {
            notification.value = null;
            if (notifTimer) {
                clearTimeout(notifTimer);
                notifTimer = null;
            }
        }

        function hidePhone() {
            phoneVisible.value = false;
            captureWasVisible = false;
            clearNotification();
        }

        function acceptCall() {
            hEvent("acceptCall", {});
        }

        function hangup() {
            hEvent("hangup", {});
            incomingCall.value = null;
            outgoingCall.value = null;
            activeCall.value = null;
            callDuration.value = 0;
            if (callTimer) {
                clearInterval(callTimer);
                callTimer = null;
            }
        }

        function parsePayload(raw, fallback) {
            if (raw && typeof raw === "object") return raw;
            if (typeof raw !== "string") return fallback;
            try {
                return JSON.parse(raw || "");
            } catch (_) {
                return fallback;
            }
        }

        function replaceCalendarEvents(raw) {
            const incoming = parsePayload(raw, {});
            const { CALENDAR_EVENTS } = window.PhoneStore;

            Object.keys(CALENDAR_EVENTS).forEach((k) => {
                delete CALENDAR_EVENTS[k];
            });

            Object.entries(incoming || {}).forEach(([yearStr, months]) => {
                const year = Number(yearStr);
                CALENDAR_EVENTS[year] = {};
                Object.entries(months || {}).forEach(([mIdxStr, days]) => {
                    const mIdx = Number(mIdxStr);
                    CALENDAR_EVENTS[year][mIdx] = {};
                    Object.entries(days || {}).forEach(([dIdxStr, events]) => {
                        CALENDAR_EVENTS[year][mIdx][Number(dIdxStr)] = Array.isArray(events) ? events : [];
                    });
                });
            });
        }

        window.addEventListener("message", (event) => {
            const { name, args = [] } = event.data;
            if (name === "open") {
                phoneVisible.value = true;
                if (activeScreen.value === "calendar") hEvent("loadCalendar", {});
                return;
            }
            if (name === "closePhone") {
                closePhone();
                return;
            }
            // ── Camera capture lifecycle ──────────────────────────────────────
            if (name === "hideForCapture") {
                captureWasVisible = phoneVisible.value;
                phoneVisible.value = false;
                return;
            }
            if (name === "showAfterCapture") {
                phoneVisible.value = captureWasVisible;
                return;
            }
            if (name === "photoTaken") {
                const url = args[0];
                if (url) {
                    window.PhoneStore.PHOTOS.unshift({
                        id: Date.now(),
                        gradient: `url(${url}) center/cover no-repeat`,
                        takenAt: "Just now",
                    });
                }
                return;
            }
            if (name === "incomingCall") {
                const { dnd, notifSettings } = window.PhoneStore;
                if (!dnd.value && notifSettings.phone && !phoneVisible.value) phoneVisible.value = true;
                incomingCall.value = { name: args[0], number: args[1] };
                return;
            }
            if (name === "callRinging") {
                outgoingCall.value = { name: args[0], number: args[1] };
                return;
            }
            if (name === "callStarted") {
                activeCall.value = { ...(outgoingCall.value ?? incomingCall.value), channel: args[0] };
                outgoingCall.value = null;
                incomingCall.value = null;
                callDuration.value = 0;
                callTimer = setInterval(() => callDuration.value++, 1000);
                return;
            }
            if (name === "messageReceived") {
                const [senderName, senderNumber, text, time] = args;
                const { CONVERSATIONS } = window.PhoneStore;
                let conv = CONVERSATIONS.find((c) => c.number === senderNumber);
                if (!conv) {
                    conv = { id: Date.now(), name: senderName, number: senderNumber, image: "", messages: [] };
                    CONVERSATIONS.unshift(conv);
                }
                conv.messages.push({ id: Date.now(), sender: "them", text, time });
                if (!phoneVisible.value || activeScreen.value !== "messages") {
                    showNotif("messages", {
                        appLabel: "Messages",
                        icon: "message-circle",
                        iconBg: "rgb(147 197 253)",
                        iconColor: "rgb(30 64 175)",
                        title: senderName,
                        body: text,
                    });
                }
                return;
            }
            if (name === "emailReceived") {
                const email =
                    args[0] && typeof args[0] === "object"
                        ? args[0]
                        : (() => {
                              try {
                                  return JSON.parse(args[0] || "null");
                              } catch (_) {
                                  return null;
                              }
                          })();
                if (email) window.PhoneStore.EMAILS.unshift(email);
                showNotif("hmail", {
                    appLabel: "Hmail",
                    icon: "mail",
                    iconBg: "rgb(252 165 165)",
                    iconColor: "rgb(127 29 29)",
                    title: email ? email.from : "New Email",
                    body: email ? email.subject : "",
                });
                return;
            }
            if (name === "newFollower") {
                showNotif("gene", {
                    appLabel: "H",
                    icon: "dna",
                    iconBg: "rgb(10 10 10)",
                    iconColor: "rgb(231 231 231)",
                    title: args[0] || "Someone",
                    body: "started following you",
                });
                return;
            }
            if (name === "profileLoaded") {
                const profile = args[0] && typeof args[0] === "object" ? args[0] : { name: args[0], phone: args[1], citizenid: args[2], account: args[3] };
                window.PhoneStore.playerName.value = profile.name || "";
                window.PhoneStore.playerPhone.value = profile.phone || "";
                window.PhoneStore.playerCitizenId.value = profile.citizenid || profile.helixId || "";
                window.PhoneStore.playerAccount.value = profile.account || profile.accountNumber || "";
                return;
            }
            if (name === "contactsLoaded") {
                const parsed = JSON.parse(args[0] || "[]");
                const contacts = Array.isArray(parsed) ? parsed : [];
                const { CONTACTS } = window.PhoneStore;
                CONTACTS.splice(0, CONTACTS.length, ...contacts);
                return;
            }
            if (name === "conversationsLoaded") {
                const parsed = JSON.parse(args[0] || "[]");
                const convs = Array.isArray(parsed) ? parsed : [];
                const { CONVERSATIONS } = window.PhoneStore;
                CONVERSATIONS.splice(0, CONVERSATIONS.length, ...convs);
                return;
            }
            if (name === "callHistoryLoaded") {
                const parsed = JSON.parse(args[0] || "[]");
                const history = Array.isArray(parsed) ? parsed : [];
                const { CALL_HISTORY } = window.PhoneStore;
                CALL_HISTORY.splice(0, CALL_HISTORY.length, ...history);
                return;
            }
            if (name === "callLogged") {
                window.PhoneStore.CALL_HISTORY.unshift({
                    name: args[0],
                    number: args[1],
                    type: args[2],
                    time: args[3],
                    missed: args[4],
                });
                return;
            }
            if (name === "feedLoaded") {
                const parsed = JSON.parse(args[0] || "[]");
                const posts = Array.isArray(parsed) ? parsed : [];
                const { POSTS } = window.PhoneStore;
                POSTS.splice(0, POSTS.length, ...posts);
                return;
            }
            if (name === "usersLoaded") {
                const users = JSON.parse(args[0] || "{}");
                const { USERS } = window.PhoneStore;
                for (const k in USERS) delete USERS[k];
                Object.assign(USERS, users);
                return;
            }
            if (name === "postReceived") {
                const post = JSON.parse(args[0] || "null");
                if (post) window.PhoneStore.POSTS.unshift(post);
                return;
            }
            if (name === "photosLoaded") {
                const parsed = JSON.parse(args[0] || "[]");
                const photos = Array.isArray(parsed) ? parsed : [];
                const { PHOTOS } = window.PhoneStore;
                PHOTOS.splice(0, PHOTOS.length, ...photos);
                return;
            }
            if (name === "calendarEventsLoaded") {
                replaceCalendarEvents(args[0]);
                return;
            }
            if (name === "postDeleted") {
                const { POSTS } = window.PhoneStore;
                const idx = POSTS.findIndex((p) => p.id === args[0]);
                if (idx !== -1) POSTS.splice(idx, 1);
                return;
            }
            if (name === "postLikeUpdated") {
                const post = window.PhoneStore.POSTS.find((p) => p.id === args[0]);
                if (post) post.likes = args[1];
                return;
            }
            if (name === "postRepostUpdated") {
                const post = window.PhoneStore.POSTS.find((p) => p.id === args[0]);
                if (post) post.reposts = args[1];
                return;
            }
            if (name === "commentAdded") {
                const post = window.PhoneStore.POSTS.find((p) => p.id === args[0]);
                const comment = JSON.parse(args[1] || "null");
                if (post && comment) post.comments.push(comment);
                return;
            }
            if (name === "callEnded" || name === "callFailed") {
                incomingCall.value = null;
                outgoingCall.value = null;
                activeCall.value = null;
                callDuration.value = 0;
                if (callTimer) {
                    clearInterval(callTimer);
                    callTimer = null;
                }
            }
        });

        function getFormattedTime() {
            return "9:41";
        }
        function getFormattedDate() {
            return "Tue, Mar 27";
        }
        function getWeatherTemperature() {
            return "68°";
        }

        const OPENABLE = new Set(["calendar", "phone", "messages", "h", "calculator", "camera", "photos", "clock", "settings", "hmail"]);

        function openApp(label) {
            const key = label.toLowerCase();
            if (OPENABLE.has(key)) {
                activeScreen.value = key;
                if (key === "calendar") hEvent("loadCalendar", {});
            }
        }

        function closePhone() {
            hidePhone();
            hEvent("ClosePhone", {});
        }

        function handleKeydown(event) {
            if (event.key === "Escape" && phoneVisible.value) {
                event.preventDefault();
                closePhone();
            }
        }

        onMounted(() => {
            window.addEventListener("keydown", handleKeydown);
        });

        onBeforeUnmount(() => {
            window.removeEventListener("keydown", handleKeydown);
        });

        return {
            HOME_APPS,
            DOCK_APPS,
            phoneVisible,
            locked,
            activeScreen,
            darkMode,
            wallpaperUrl,
            activeCaseColor,
            incomingCall,
            outgoingCall,
            activeCall,
            callDuration,
            formatCallDuration,
            acceptCall,
            hangup,
            navigateTo,
            onDial,
            getFormattedTime,
            getFormattedDate,
            getWeatherTemperature,
            openApp,
            closePhone,
            notification,
        };
    },
}).mount("#app");

// ── Right-click look mode ─────────────────────────────────────────────────────

document.addEventListener("contextmenu", (e) => e.preventDefault());
document.addEventListener("mousedown", (e) => {
    if (e.button === 2) hEvent("rightMouseDown", {});
});

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
        subtree: true,
    });

    lucide.createIcons();
})();
