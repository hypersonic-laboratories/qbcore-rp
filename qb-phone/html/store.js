(function () {
    const { reactive, ref } = Vue;

    window.PhoneStore = {
        darkMode: ref(false),

        CONTACTS: reactive([]),
        CONVERSATIONS: reactive([]),
        CALL_HISTORY: reactive([]),
        currentConversationId: ref(null),

        USERS: reactive({}),

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

        PHOTOS: reactive([
            { id: 1, gradient: "linear-gradient(135deg,#a78bfa,#60a5fa)", takenAt: "2h ago" },
            { id: 2, gradient: "linear-gradient(135deg,#fb923c,#fbbf24)", takenAt: "5h ago" },
            { id: 3, gradient: "linear-gradient(135deg,#34d399,#06b6d4)", takenAt: "1d ago" },
            { id: 4, gradient: "linear-gradient(135deg,#f472b6,#a78bfa)", takenAt: "2d ago" },
            { id: 5, gradient: "linear-gradient(135deg,#fbbf24,#f97316)", takenAt: "3d ago" },
            { id: 6, gradient: "linear-gradient(135deg,#6ee7b7,#93c5fd)", takenAt: "1w ago" },
        ]),

        POSTS: reactive([]),
    };
})();
