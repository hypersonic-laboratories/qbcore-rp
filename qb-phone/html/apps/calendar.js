const MONTH_NAMES = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const WEEK_DAYS = ["S", "M", "T", "W", "T", "F", "S"];

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
                    <div v-for="(d, i) in WEEK_DAYS" :key="i">{{ d }}</div>
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

                <div class="calendar-scroll-area">
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
                            <div class="calendar-event-accent"></div>
                            <div class="calendar-event-body">
                                <div class="calendar-event-time">{{ event.time }}</div>
                                <div class="calendar-event-title">{{ event.title }}</div>
                                <div class="calendar-event-detail">{{ event.detail }}</div>
                            </div>
                            <button type="button" class="calendar-icon-button calendar-event-delete" @click="deleteCalendarEvent(event.id)" aria-label="Delete event">
                                <i data-lucide="trash-2" class="calendar-switcher-icon"></i>
                            </button>
                        </div>
                    </template>
                    <div v-else class="calendar-empty-state">Nothing scheduled. Tap the plus button to add an event for this date.</div>
                </div>
                </div>
            </div>
        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, reactive, computed, onMounted } = Vue;

        const _now = new Date();
        const todayYear = _now.getFullYear();
        const todayMonthIndex = _now.getMonth();
        const todayDay = _now.getDate();

        const currentYear = ref(todayYear);
        const currentMonthIndex = ref(todayMonthIndex);
        const selectedDay = ref(todayDay);
        const showAddForm = ref(false);
        const newEvent = reactive({ title: "", time: "12:00 PM", detail: "" });
        const eventsByMonth = window.PhoneStore.CALENDAR_EVENTS;

        const monthLabel = computed(() => `${MONTH_NAMES[currentMonthIndex.value]} ${currentYear.value}`);

        const monthEvents = computed(() => (eventsByMonth[currentYear.value] || {})[currentMonthIndex.value] || {});

        const selectedEvents = computed(() => monthEvents.value[selectedDay.value] || []);

        const eventCountLabel = computed(() => {
            const n = selectedEvents.value.length;
            return n ? `${n} event${n === 1 ? "" : "s"}` : "No events yet";
        });

        const calendarDays = computed(() => {
            const year = currentYear.value;
            const daysInMonth = new Date(year, currentMonthIndex.value + 1, 0).getDate();
            const startOffset = new Date(year, currentMonthIndex.value, 1).getDay();
            const days = [];

            for (let i = 0; i < startOffset; i++) days.push(null);

            for (let day = 1; day <= daysInMonth; day++) {
                const isToday = currentYear.value === todayYear && currentMonthIndex.value === todayMonthIndex && day === todayDay;
                const isSelected = day === selectedDay.value;
                const hasEvents = (monthEvents.value[day] || []).length > 0;

                let cls = "calendar-day ";
                if (isSelected) cls += "calendar-day-selected";
                else if (isToday) cls += "calendar-day-today";
                else if (hasEvents) cls += "calendar-day-has-events";
                else cls += "calendar-day-default";

                days.push({ day, cls, hasEvents, isSelected });
            }

            return days;
        });

        function prevMonth() {
            if (currentMonthIndex.value === 0) {
                currentMonthIndex.value = 11;
                currentYear.value -= 1;
            } else {
                currentMonthIndex.value -= 1;
            }
            selectedDay.value = 1;
            showAddForm.value = false;
        }

        function nextMonth() {
            if (currentMonthIndex.value === 11) {
                currentMonthIndex.value = 0;
                currentYear.value += 1;
            } else {
                currentMonthIndex.value += 1;
            }
            selectedDay.value = 1;
            showAddForm.value = false;
        }

        function selectDay(day) {
            selectedDay.value = day;
        }

        function saveCalendarEvent() {
            if (!newEvent.title.trim()) return;
            const year = currentYear.value;
            const mIdx = currentMonthIndex.value;
            const dIdx = selectedDay.value;
            const time = newEvent.time.trim() || "12:00 PM";
            const detail = newEvent.detail.trim() || "No details";

            if (!eventsByMonth[year]) eventsByMonth[year] = {};
            if (!eventsByMonth[year][mIdx]) eventsByMonth[year][mIdx] = {};
            if (!eventsByMonth[year][mIdx][dIdx]) eventsByMonth[year][mIdx][dIdx] = [];

            const event = {
                id: `${year}-${mIdx}-${dIdx}-${Date.now()}`,
                time,
                title: newEvent.title.trim(),
                detail,
            };
            eventsByMonth[year][mIdx][dIdx].push(event);
            hEvent("saveCalendarEvent", { year, month: mIdx, day: dIdx, title: event.title, time: event.time, detail: event.detail });

            newEvent.title = "";
            newEvent.time = "12:00 PM";
            newEvent.detail = "";
            showAddForm.value = false;
        }

        function deleteCalendarEvent(eventId) {
            const year = currentYear.value;
            const mIdx = currentMonthIndex.value;
            const dIdx = selectedDay.value;
            if (!eventsByMonth[year]?.[mIdx]?.[dIdx]) return;
            eventsByMonth[year][mIdx][dIdx] = eventsByMonth[year][mIdx][dIdx].filter(e => e.id !== eventId);
            hEvent("deleteCalendarEvent", { eventId });
        }

        onMounted(() => {
            hEvent("loadCalendar");
        });

        function onBack() {
            showAddForm.value = false;
            emit("navigate", "home");
        }

        return {
            WEEK_DAYS,
            MONTH_NAMES,
            currentYear,
            currentMonthIndex,
            selectedDay,
            showAddForm,
            newEvent,
            monthLabel,
            selectedEvents,
            eventCountLabel,
            calendarDays,
            prevMonth,
            nextMonth,
            selectDay,
            saveCalendarEvent,
            deleteCalendarEvent,
            onBack,
        };
    },
};
