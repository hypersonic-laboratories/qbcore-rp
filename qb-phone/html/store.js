(function () {
    const { reactive, ref } = Vue;
    const DARK_MODE_STORAGE_KEY = "helix-phone:dark-mode";
    const WALLPAPER_STORAGE_KEY = "helix-phone:wallpaper";
    const CASE_COLOR_STORAGE_KEY = "helix-phone:case-color";
    const NOTIF_SETTINGS_STORE_KEY = "helix-phone:notif-settings";
    const DND_STORE_KEY = "helix-phone:dnd";

    window.CASE_COLORS = [
        { id: "black", label: "Space Black", main: "rgb(24 24 27)", light: "rgb(63 63 70)" },
        { id: "silver", label: "Silver", main: "rgb(168 168 175)", light: "rgb(205 205 212)" },
        { id: "purple", label: "Deep Purple", main: "rgb(55 35 85)", light: "rgb(90 65 120)" },
        { id: "blue", label: "Midnight", main: "rgb(15 28 62)", light: "rgb(35 55 105)" },
        { id: "red", label: "Product Red", main: "rgb(155 22 12)", light: "rgb(200 42 28)" },
        { id: "gold", label: "Gold", main: "rgb(155 125 68)", light: "rgb(195 165 108)" },
    ];

    function loadStoredDarkMode() {
        try {
            return window.localStorage.getItem(DARK_MODE_STORAGE_KEY) === "true";
        } catch (_) {
            return false;
        }
    }

    function saveStoredDarkMode(enabled) {
        try {
            window.localStorage.setItem(DARK_MODE_STORAGE_KEY, enabled ? "true" : "false");
        } catch (_) {
            // localStorage can be unavailable in some embedded contexts.
        }
    }

    function loadStoredWallpaper() {
        try {
            return window.localStorage.getItem(WALLPAPER_STORAGE_KEY) || "";
        } catch (_) {
            return "";
        }
    }

    function saveStoredWallpaper(url) {
        try {
            if (url) {
                window.localStorage.setItem(WALLPAPER_STORAGE_KEY, url);
            } else {
                window.localStorage.removeItem(WALLPAPER_STORAGE_KEY);
            }
        } catch (_) {}
    }

    function loadStoredCaseColor() {
        try {
            return window.localStorage.getItem(CASE_COLOR_STORAGE_KEY) || "black";
        } catch (_) {
            return "black";
        }
    }

    function saveStoredCaseColor(id) {
        try {
            window.localStorage.setItem(CASE_COLOR_STORAGE_KEY, id);
        } catch (_) {}
    }

    const DEFAULT_NOTIF_SETTINGS = { messages: true, phone: true, hmail: true, gene: false };

    function loadNotifSettings() {
        try {
            const raw = window.localStorage.getItem(NOTIF_SETTINGS_STORE_KEY);
            if (!raw) return { ...DEFAULT_NOTIF_SETTINGS };
            return Object.assign({ ...DEFAULT_NOTIF_SETTINGS }, JSON.parse(raw));
        } catch (_) {
            return { ...DEFAULT_NOTIF_SETTINGS };
        }
    }

    function saveNotifSettings(settings) {
        try {
            window.localStorage.setItem(NOTIF_SETTINGS_STORE_KEY, JSON.stringify(settings));
        } catch (_) {}
    }

    function loadDnd() {
        try {
            return window.localStorage.getItem(DND_STORE_KEY) === "true";
        } catch (_) {
            return false;
        }
    }

    function saveDnd(val) {
        try {
            window.localStorage.setItem(DND_STORE_KEY, val ? "true" : "false");
        } catch (_) {}
    }

    window.PhoneStore = {
        darkMode: ref(loadStoredDarkMode()),
        saveDarkMode: saveStoredDarkMode,
        wallpaperUrl: ref(loadStoredWallpaper()),
        saveWallpaper: saveStoredWallpaper,
        caseColorId: ref(loadStoredCaseColor()),
        saveCaseColor: saveStoredCaseColor,
        notifSettings: reactive(loadNotifSettings()),
        saveNotifSettings: saveNotifSettings,
        dnd: ref(loadDnd()),
        saveDnd: saveDnd,
        playerName: ref(""),
        playerPhone: ref(""),
        playerCitizenId: ref(""),
        playerAccount: ref(""),

        CONTACTS: reactive([]),
        CONVERSATIONS: reactive([]),
        CALL_HISTORY: reactive([]),
        currentConversationId: ref(null),

        USERS: reactive({}),

        CALENDAR_EVENTS: reactive({}),

        currentEmailId: ref(null),

        EMAILS: reactive([
            {
                id: 1,
                from: "Ava Martinez",
                fromNumber: "5550101",
                subject: "Welcome to HELIX!",
                snippet: "Hey! Just wanted to reach out and say welcome to the city. If you need anything...",
                body: "Hey!\n\nJust wanted to reach out and say welcome to the city. It can be a bit overwhelming at first but you'll find your feet quick.\n\nIf you need anything at all, don't hesitate to reach out.\n\n— Ava",
                time: "2m ago",
                read: false,
                starred: true,
            },
            {
                id: 2,
                from: "Marcus Webb",
                fromNumber: "5550102",
                subject: "Re: Meeting up?",
                snippet: "Yeah, sounds good. I'll be at the usual spot around 7. Don't be late this time lol...",
                body: "Yeah, sounds good. I'll be at the usual spot around 7. Don't be late this time lol.\n\nAlso — did you hear about what happened downtown? Wild stuff.\n\nMarcus",
                time: "14m ago",
                read: false,
                starred: false,
            },
            {
                id: 3,
                from: "HELIX Bank",
                fromNumber: "",
                subject: "Your account statement is ready",
                snippet: "Your monthly account statement is now available. Log in to view your balance and recent...",
                body: "Your monthly account statement is now available.\n\nLog in to HELIX Bank Online to view your balance, recent transactions, and download your statement.\n\nHELIX Bank Support Team",
                time: "1h ago",
                read: true,
                starred: false,
            },
            {
                id: 4,
                from: "Ava Martinez",
                fromNumber: "5550101",
                subject: "The photos from last night",
                snippet: "OMG these came out so good. I'll send over the full album later but here's a preview...",
                body: "OMG these came out so good.\n\nI'll send over the full album later but here's a preview of a couple. Let me know which ones you want me to post.\n\n— Ava 📸",
                time: "3h ago",
                read: true,
                starred: true,
            },
        ]),

        PHOTOS: reactive([]),

        POSTS: reactive([]),
    };
})();
