const ClockApp = {
    template: `
        <div class="clock-screen">
            <div class="clock-header">
                <button type="button" aria-label="Back to home" class="clock-icon-button" @click="onBack">
                    <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                </button>
                <div class="phone-app-top-copy">
                    <div class="clock-eyebrow">HELIX</div>
                    <div class="clock-title">Clock</div>
                </div>
            </div>

            <div class="clock-face-wrap">
                <div class="clock-time-display">
                    <span class="clock-digits">{{ timeStr }}</span>
                    <span class="clock-ampm">{{ ampm }}</span>
                </div>
                <div class="clock-date-label">{{ dateStr }}</div>
            </div>

            <div class="clock-world-section">
                <div class="clock-section-label">World Clocks</div>
                <div v-for="wc in worldClocks" :key="wc.city" class="clock-world-row">
                    <div class="clock-world-left">
                        <div class="clock-world-city">{{ wc.city }}</div>
                        <div class="clock-world-tz">{{ wc.tz }}</div>
                    </div>
                    <div class="clock-world-time">{{ wc.time }}</div>
                </div>
            </div>
        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, computed, onMounted, onUnmounted } = Vue;

        const now = ref(new Date());

        let timer, alignTimer;
        onMounted(() => {
            now.value = new Date();
            alignTimer = setTimeout(() => {
                now.value = new Date();
                timer = setInterval(() => { now.value = new Date(); }, 1000);
            }, 1000 - new Date().getMilliseconds());
        });
        onUnmounted(() => { clearTimeout(alignTimer); clearInterval(timer); });

        const timeStr = computed(() => {
            const d = now.value;
            const h = d.getHours() % 12 || 12;
            const m = String(d.getMinutes()).padStart(2, "0");
            const s = String(d.getSeconds()).padStart(2, "0");
            return `${h}:${m}:${s}`;
        });

        const ampm = computed(() => (now.value.getHours() >= 12 ? "PM" : "AM"));

        const dateStr = computed(() => {
            const d = now.value;
            const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
            const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
            return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
        });

        const WORLD_CLOCK_DEFS = [
            { city: "Los Angeles", ianaZone: "America/Los_Angeles" },
            { city: "New York",    ianaZone: "America/New_York" },
            { city: "London",      ianaZone: "Europe/London" },
            { city: "Tokyo",       ianaZone: "Asia/Tokyo" },
        ];

        const worldClocks = computed(() =>
            WORLD_CLOCK_DEFS.map((wc) => {
                const parts = new Intl.DateTimeFormat("en-US", {
                    timeZone: wc.ianaZone,
                    hour: "numeric",
                    minute: "2-digit",
                    hour12: true,
                    timeZoneName: "short",
                }).formatToParts(now.value);
                const get = (type) => parts.find((p) => p.type === type)?.value ?? "";
                return {
                    city: wc.city,
                    tz: get("timeZoneName"),
                    time: `${get("hour")}:${get("minute")} ${get("dayPeriod")}`,
                };
            }),
        );

        function onBack() {
            emit("navigate", "home");
        }

        return { timeStr, ampm, dateStr, worldClocks, onBack };
    },
};
