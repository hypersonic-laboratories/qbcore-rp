(function () {
    const { reactive, ref } = Vue;

    window.PhoneStore = {
        CONTACTS: reactive([]),
        CONVERSATIONS: reactive([]),
        CALL_HISTORY: reactive([]),
        currentConversationId: ref(null),

        USERS: reactive({
            Ava: {
                handle: "@ava",
                bio: "Designer & dreamer ✨",
                following: false,
                followers: 142,
                following_count: 38,
            },
            Marcus: {
                handle: "@marcus",
                bio: "Coffee first, code second ☕",
                following: false,
                followers: 89,
                following_count: 61,
            },
        }),

        PHOTOS: reactive([
            { id: 1, gradient: "linear-gradient(135deg,#a78bfa,#60a5fa)", takenAt: "2h ago"  },
            { id: 2, gradient: "linear-gradient(135deg,#fb923c,#fbbf24)", takenAt: "5h ago"  },
            { id: 3, gradient: "linear-gradient(135deg,#34d399,#06b6d4)", takenAt: "1d ago"  },
            { id: 4, gradient: "linear-gradient(135deg,#f472b6,#a78bfa)", takenAt: "2d ago"  },
            { id: 5, gradient: "linear-gradient(135deg,#fbbf24,#f97316)", takenAt: "3d ago"  },
            { id: 6, gradient: "linear-gradient(135deg,#6ee7b7,#93c5fd)", takenAt: "1w ago"  },
        ]),

        POSTS: reactive([
            {
                id: 1,
                author: "Ava",
                handle: "@ava",
                content: "Just moved into my new place 🧬 First night in the new apartment and it already feels like home.",
                image: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80",
                time: "2m ago",
                likes: 3,
                liked: false,
                reposts: 1,
                reposted: false,
                comments: [{ id: 101, author: "Marcus", handle: "@marcus", text: "Congrats! You'll love it.", time: "1m ago" }],
            },
            {
                id: 2,
                author: "Marcus",
                handle: "@marcus",
                content: "Nothing beats a good coffee and a blank canvas on a Monday morning.",
                image: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80",
                time: "14m ago",
                likes: 7,
                liked: false,
                reposts: 2,
                reposted: false,
                comments: [],
            },
            {
                id: 3,
                author: "Ava",
                handle: "@ava",
                content: "Hot take: tabs are better than spaces and I will not be taking questions.",
                image: "",
                time: "1h ago",
                likes: 12,
                liked: false,
                reposts: 5,
                reposted: false,
                comments: [
                    { id: 102, author: "Marcus", handle: "@marcus", text: "Finally someone said it.", time: "58m ago" },
                    { id: 103, author: "You", handle: "@you", text: "Controversial but correct.", time: "45m ago" },
                ],
            },
            {
                id: 4,
                author: "Marcus",
                handle: "@marcus",
                content: "Golden hour hits different when you're out here exploring. 🌅",
                image: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&q=80",
                time: "3h ago",
                likes: 21,
                liked: false,
                reposts: 4,
                reposted: false,
                comments: [],
            },
        ]),
    };
})();
