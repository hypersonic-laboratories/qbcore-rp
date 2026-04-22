const MONTH_NAMES      = ["January","February","March","April","May","June","July","August","September","October","November","December"];
const WEEK_DAYS        = ["S","M","T","W","T","F","S"];
const TODAY_MONTH_INDEX = 2;
const TODAY_DAY         = 27;

const CalendarApp = {
    template: `
        <div class="calendar-screen">
            <div class="calendar-top">
                <div class="calendar-top-row">
                    <button type="button" aria-label="Back to home" class="calendar-icon-button" @click="onBack">
                        <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                    </button>
                    <div class="calendar-top-copy">
                        <div class="calendar-eyebrow">Calendar</div>
                        <div class="calendar-month-title">{{ monthLabel }}</div>
                    </div>
                </div>
                <div class="calendar-month-switcher">
                    <button type="button" aria-label="Previous month" class="calendar-icon-button calendar-switcher-button" @click="prevMonth">
                        <i data-lucide="chevron-left" class="calendar-switcher-icon"></i>
                    </button>
                    <div class="calendar-switcher-label">Month view</div>
                    <button type="button" aria-label="Next month" class="calendar-icon-button calendar-switcher-button" @click="nextMonth">
                        <i data-lucide="chevron-right" class="calendar-switcher-icon"></i>
                    </button>
                </div>
            </div>

            <div class="calendar-grid-wrap">
                <div class="calendar-week-header">
                    <div v-for="d in WEEK_DAYS" :key="d">{{ d }}</div>
                </div>
                <div class="calendar-days-grid">
                    <template v-for="(item, i) in calendarDays" :key="i">
                        <div v-if="item === null"></div>
                        <button v-else type="button" :class="item.cls" @click="selectDay(item.day)">
                            <span>{{ item.day }}</span>
                            <span v-if="item.hasEvents && !item.isSelected" class="calendar-day-dot"></span>
                        </button>
                    </template>
                </div>
            </div>

            <div class="calendar-main">
                <div class="calendar-section-header">
                    <div>
                        <div class="calendar-section-title">{{ MONTH_NAMES[currentMonthIndex] }} {{ selectedDay }}</div>
                        <div class="calendar-section-subtitle">{{ eventCountLabel }}</div>
                    </div>
                    <button type="button" aria-label="Add event" class="calendar-add-button" @click="showAddForm = !showAddForm">
                        <i data-lucide="plus" class="calendar-add-icon"></i>
                    </button>
                </div>

                <div v-if="showAddForm" class="calendar-form-card">
                    <input v-model="newEvent.title" placeholder="Event title" class="calendar-input" />
                    <input v-model="newEvent.time" placeholder="Time" class="calendar-input" />
                    <input v-model="newEvent.detail" placeholder="Details" class="calendar-input" />
                    <div class="calendar-form-actions">
                        <button type="button" class="calendar-button calendar-button-secondary" @click="showAddForm = false">Cancel</button>
                        <button type="button" class="calendar-button calendar-button-primary" @click="saveCalendarEvent">Save</button>
                    </div>
                </div>

                <div class="calendar-events-list">
                    <template v-if="selectedEvents.length">
                        <div v-for="event in selectedEvents" :key="event.id" class="calendar-event-card">
                            <div :class="['calendar-event-accent', event.accent]"></div>
                            <div>
                                <div class="calendar-event-time">{{ event.time }}</div>
                                <div class="calendar-event-title">{{ event.title }}</div>
                                <div class="calendar-event-detail">{{ event.detail }}</div>
                            </div>
                        </div>
                    </template>
                    <div v-else class="calendar-empty-state">Nothing scheduled. Tap the plus button to add an event for this date.</div>
                </div>
            </div>
        </div>
    `,

    emits: ['navigate'],

    setup(props, { emit }) {
        const { ref, reactive, computed, onMounted, onUnmounted } = Vue;

        const currentMonthIndex = ref(TODAY_MONTH_INDEX);
        const selectedDay       = ref(TODAY_DAY);
        const showAddForm       = ref(false);
        const newEvent          = reactive({ title: '', time: '12:00 PM', detail: '' });
        const eventsByMonth     = reactive({});

        const monthLabel = computed(() => `${MONTH_NAMES[currentMonthIndex.value]} 2026`);

        const monthEvents = computed(() => eventsByMonth[currentMonthIndex.value] || {});

        const selectedEvents = computed(() => monthEvents.value[selectedDay.value] || []);

        const eventCountLabel = computed(() => {
            const n = selectedEvents.value.length;
            return n ? `${n} event${n === 1 ? '' : 's'}` : 'No events yet';
        });

        const calendarDays = computed(() => {
            const year        = 2026;
            const daysInMonth = new Date(year, currentMonthIndex.value + 1, 0).getDate();
            const startOffset = new Date(year, currentMonthIndex.value, 1).getDay();
            const days        = [];

            for (let i = 0; i < startOffset; i++) days.push(null);

            for (let day = 1; day <= daysInMonth; day++) {
                const isToday    = currentMonthIndex.value === TODAY_MONTH_INDEX && day === TODAY_DAY;
                const isSelected = day === selectedDay.value;
                const hasEvents  = (monthEvents.value[day] || []).length > 0;

                let cls = 'calendar-day ';
                if      (isSelected) cls += 'calendar-day-selected';
                else if (isToday)    cls += 'calendar-day-today';
                else if (hasEvents)  cls += 'calendar-day-has-events';
                else                 cls += 'calendar-day-default';

                days.push({ day, cls, hasEvents, isSelected });
            }

            return days;
        });

        function prevMonth() {
            currentMonthIndex.value = (currentMonthIndex.value + 11) % 12;
            selectedDay.value       = 1;
            showAddForm.value       = false;
        }

        function nextMonth() {
            currentMonthIndex.value = (currentMonthIndex.value + 1) % 12;
            selectedDay.value       = 1;
            showAddForm.value       = false;
        }

        function selectDay(day) {
            selectedDay.value = day;
        }

        function saveCalendarEvent() {
            if (!newEvent.title.trim()) return;
            const mIdx   = currentMonthIndex.value;
            const dIdx   = selectedDay.value;
            const time   = newEvent.time.trim()   || '12:00 PM';
            const detail = newEvent.detail.trim() || 'No details';

            if (!eventsByMonth[mIdx])       eventsByMonth[mIdx]       = {};
            if (!eventsByMonth[mIdx][dIdx]) eventsByMonth[mIdx][dIdx] = [];

            const event = {
                id:     `${mIdx}-${dIdx}-${Date.now()}`,
                time,
                title:  newEvent.title.trim(),
                detail,
                accent: 'bg-rose-500',
            };
            eventsByMonth[mIdx][dIdx].push(event);
            hEvent('saveCalendarEvent', { month: mIdx, day: dIdx, title: event.title, time: event.time, detail: event.detail });

            newEvent.title  = '';
            newEvent.time   = '12:00 PM';
            newEvent.detail = '';
            showAddForm.value = false;
        }

        function onMessage(e) {
            if (e.data?.name !== 'calendarEventsLoaded') return;
            const incoming = JSON.parse(e.data.args?.[0] || '{}');
            Object.entries(incoming).forEach(([mIdx, days]) => {
                eventsByMonth[mIdx] = days;
            });
        }

        onMounted(()   => window.addEventListener('message', onMessage));
        onUnmounted(() => window.removeEventListener('message', onMessage));

        function onBack() {
            showAddForm.value = false;
            emit('navigate', 'home');
        }

        return {
            WEEK_DAYS, MONTH_NAMES,
            currentMonthIndex, selectedDay, showAddForm, newEvent,
            monthLabel, selectedEvents, eventCountLabel, calendarDays,
            prevMonth, nextMonth, selectDay, saveCalendarEvent, onBack,
        };
    },
};
