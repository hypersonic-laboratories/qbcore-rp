const SettingsApp = {
    template: `
        <div class="settings-screen">
            <div class="settings-header">
                <button type="button" aria-label="Back to home" class="settings-icon-button" @click="onBack">
                    <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                </button>
                <div class="phone-app-top-copy">
                    <div class="settings-eyebrow">HELIX</div>
                    <div class="settings-title">Settings</div>
                </div>
            </div>

            <div class="settings-body">
                <!-- Profile -->
                <div class="settings-section">
                    <div class="settings-profile-row">
                        <div class="settings-profile-avatar">{{ profileInitial }}</div>
                        <div class="settings-profile-copy">
                            <div class="settings-profile-name">{{ profileDisplayName }}</div>
                            <div class="settings-profile-sub">{{ profilePhoneDisplay }}</div>
                        </div>
                        <button type="button" class="settings-profile-copy-button" :disabled="!playerPhone" aria-label="Copy phone number" @click="copyPhoneNumber">
                            <i data-lucide="copy" class="settings-profile-copy-icon"></i>
                        </button>
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
        const { ref, reactive, computed, onMounted } = Vue;
        const store = window.PhoneStore;

        const profileDisplayName = computed(() => store.playerName.value || "Loading profile");
        const profileInitial = computed(() => store.playerName.value ? store.playerName.value.charAt(0).toUpperCase() : "H");
        const playerPhone = computed(() => store.playerPhone.value || "");
        const profilePhoneDisplay = computed(() => playerPhone.value || "Loading phone number");

        function applyProfile(profile) {
            if (!profile || typeof profile !== "object") return;
            store.playerName.value = profile.name || profile.playerName || "";
            store.playerPhone.value = profile.phone || profile.phoneNumber || "";
            store.playerCitizenId.value = profile.citizenid || profile.helixId || "";
            store.playerAccount.value = profile.account || profile.accountNumber || "";
        }

        function requestProfile() {
            if (typeof hEvent !== "function") return;
            hEvent("loadProfile", {}, applyProfile);
        }

        function copyPhoneNumber() {
            if (!playerPhone.value || typeof hEvent !== "function") return;
            hEvent("copyToClipboard", { text: playerPhone.value });
        }

        onMounted(() => {
            requestProfile();
            setTimeout(() => {
                if (!store.playerName.value) requestProfile();
            }, 750);
        });

        const notifications = reactive([
            { key: "messages", label: "Messages", icon: "message-circle", color: "rgb(59 130 246)", on: true },
            { key: "phone", label: "Phone", icon: "phone", color: "rgb(34 197 94)", on: true },
            { key: "hmail", label: "Hmail", icon: "mail", color: "rgb(249 115 22)", on: true },
            { key: "gene", label: "H (Gene)", icon: "dna", color: "rgb(168 85 247)", on: false },
        ]);

        const darkMode = window.PhoneStore.darkMode;
        const dnd = ref(false);

        function onBack() {
            emit("navigate", "home");
        }

        return { profileDisplayName, profilePhoneDisplay, playerPhone, profileInitial, notifications, darkMode, dnd, copyPhoneNumber, onBack };
    },
};
