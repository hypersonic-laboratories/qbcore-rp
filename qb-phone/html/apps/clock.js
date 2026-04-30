const ClockApp = {
    template: `
        <div class="clock-screen">
            <div class="clock-header">
                <button type="button" aria-label="Back to home" class="calendar-icon-button" @click="onBack">
                    <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                </button>
                <div class="phone-app-top-copy">
                    <div class="calendar-eyebrow">HELIX</div>
                    <div class="calendar-month-title">Clock</div>
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

    emits: ['navigate'],

    setup(props, { emit }) {
        const { ref, computed, onMounted, onUnmounted } = Vue;

        const now = ref(new Date());

        let timer;
        onMounted(() => { now.value = new Date(); timer = setInterval(() => { now.value = new Date(); }, 1000); });
        onUnmounted(() => clearInterval(timer));

        const timeStr = computed(() => {
            const d = now.value;
            const h = d.getHours() % 12 || 12;
            const m = String(d.getMinutes()).padStart(2, '0');
            const s = String(d.getSeconds()).padStart(2, '0');
            return `${h}:${m}:${s}`;
        });

        const ampm = computed(() => now.value.getHours() >= 12 ? 'PM' : 'AM');

        const dateStr = computed(() => {
            const d = now.value;
            const days    = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
            const months  = ['January','February','March','April','May','June','July','August','September','October','November','December'];
            return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
        });

        const WORLD_CLOCK_DEFS = [
            { city: 'Los Angeles', tz: 'PST',  offset: -8 },
            { city: 'New York',    tz: 'EST',  offset: -5 },
            { city: 'London',      tz: 'GMT',  offset:  0 },
            { city: 'Tokyo',       tz: 'JST',  offset:  9 },
        ];

        const worldClocks = computed(() =>
            WORLD_CLOCK_DEFS.map(wc => {
                const d      = now.value;
                const utcMs  = d.getTime() + d.getTimezoneOffset() * 60000;
                const local  = new Date(utcMs + wc.offset * 3600000);
                const h      = local.getHours() % 12 || 12;
                const m      = String(local.getMinutes()).padStart(2, '0');
                const suffix = local.getHours() >= 12 ? 'PM' : 'AM';
                return { ...wc, time: `${h}:${m} ${suffix}` };
            })
        );

        function onBack() { emit('navigate', 'home'); }

        return { timeStr, ampm, dateStr, worldClocks, onBack };
    },
};
