const SettingsApp = {
    template: `
        <div class="settings-screen">
            <div class="settings-header">
                <button type="button" aria-label="Back to home" class="calendar-icon-button" @click="onBack">
                    <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                </button>
                <div class="phone-app-top-copy">
                    <div class="calendar-eyebrow">HELIX</div>
                    <div class="calendar-month-title">Settings</div>
                </div>
            </div>

            <div class="settings-body">
                <!-- Profile -->
                <div class="settings-section">
                    <div class="settings-profile-row">
                        <div class="settings-profile-avatar">{{ profileInitial }}</div>
                        <div class="settings-profile-copy">
                            <div class="settings-profile-name">{{ profileName }}</div>
                            <div class="settings-profile-sub">HELIX ID &amp; Account</div>
                        </div>
                        <i data-lucide="chevron-right" class="settings-chevron"></i>
                    </div>
                </div>

                <!-- Notifications -->
                <div class="settings-section">
                    <div class="settings-section-label">Notifications</div>
                    <div class="settings-group">
                        <div v-for="(notif, i) in notifications" :key="notif.key" :class="['settings-row', i > 0 ? 'settings-row-border' : '']">
                            <div class="settings-row-icon-wrap" :style="{ background: notif.color }">
                                <i :data-lucide="notif.icon" class="settings-row-icon-svg"></i>
                            </div>
                            <span class="settings-row-label">{{ notif.label }}</span>
                            <button type="button" :class="['settings-toggle', notif.on ? 'settings-toggle-on' : '']" @click="notif.on = !notif.on" :aria-label="'Toggle ' + notif.label">
                                <span class="settings-toggle-thumb"></span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Display -->
                <div class="settings-section">
                    <div class="settings-section-label">Display &amp; Sound</div>
                    <div class="settings-group">
                        <div class="settings-row">
                            <div class="settings-row-icon-wrap" style="background: rgb(99 102 241)">
                                <i data-lucide="moon" class="settings-row-icon-svg"></i>
                            </div>
                            <span class="settings-row-label">Dark Mode</span>
                            <button type="button" :class="['settings-toggle', darkMode ? 'settings-toggle-on' : '']" @click="darkMode = !darkMode" aria-label="Toggle Dark Mode">
                                <span class="settings-toggle-thumb"></span>
                            </button>
                        </div>
                        <div class="settings-row settings-row-border">
                            <div class="settings-row-icon-wrap" style="background: rgb(249 115 22)">
                                <i data-lucide="bell-off" class="settings-row-icon-svg"></i>
                            </div>
                            <span class="settings-row-label">Do Not Disturb</span>
                            <button type="button" :class="['settings-toggle', dnd ? 'settings-toggle-on' : '']" @click="dnd = !dnd" aria-label="Toggle Do Not Disturb">
                                <span class="settings-toggle-thumb"></span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Privacy -->
                <div class="settings-section">
                    <div class="settings-section-label">Privacy</div>
                    <div class="settings-group">
                        <div class="settings-row">
                            <div class="settings-row-icon-wrap" style="background: rgb(16 185 129)">
                                <i data-lucide="map-pin" class="settings-row-icon-svg"></i>
                            </div>
                            <span class="settings-row-label">Location Services</span>
                            <button type="button" :class="['settings-toggle', locationOn ? 'settings-toggle-on' : '']" @click="locationOn = !locationOn" aria-label="Toggle Location Services">
                                <span class="settings-toggle-thumb"></span>
                            </button>
                        </div>
                        <div class="settings-row settings-row-border">
                            <div class="settings-row-icon-wrap" style="background: rgb(239 68 68)">
                                <i data-lucide="shield" class="settings-row-icon-svg"></i>
                            </div>
                            <span class="settings-row-label">App Permissions</span>
                            <i data-lucide="chevron-right" class="settings-chevron"></i>
                        </div>
                    </div>
                </div>

                <!-- About -->
                <div class="settings-section">
                    <div class="settings-section-label">About</div>
                    <div class="settings-group">
                        <div class="settings-row settings-row-info">
                            <span class="settings-row-label">Device</span>
                            <span class="settings-row-value">HELIX Phone X</span>
                        </div>
                        <div class="settings-row settings-row-border settings-row-info">
                            <span class="settings-row-label">OS Version</span>
                            <span class="settings-row-value">HELIX OS 1.0</span>
                        </div>
                        <div class="settings-row settings-row-border settings-row-info">
                            <span class="settings-row-label">Build</span>
                            <span class="settings-row-value">HELIX-1.0.0</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, reactive, computed } = Vue;

        const profileName = ref("Player");
        const profileInitial = computed(() => profileName.value.charAt(0).toUpperCase());

        const notifications = reactive([
            { key: "messages", label: "Messages", icon: "message-circle", color: "rgb(59 130 246)", on: true },
            { key: "phone", label: "Phone", icon: "phone", color: "rgb(34 197 94)", on: true },
            { key: "hmail", label: "Hmail", icon: "mail", color: "rgb(249 115 22)", on: true },
            { key: "gene", label: "H (Gene)", icon: "dna", color: "rgb(168 85 247)", on: false },
        ]);

        const darkMode = window.PhoneStore.darkMode;
        const dnd = ref(false);
        const locationOn = ref(true);

        function onBack() {
            emit("navigate", "home");
        }

        return { profileName, profileInitial, notifications, darkMode, dnd, locationOn, onBack };
    },
};
