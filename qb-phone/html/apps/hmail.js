const HmailApp = {
    template: `
        <div style="height:100%">

            <!-- ── Inbox ── -->
            <div v-if="view === 'inbox'" class="hmail-screen">
                <div class="hmail-top">
                    <div class="hmail-title-row">
                        <button type="button" aria-label="Back to home" class="hmail-nav-button" @click="onBack">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="hmail-eyebrow">Hmail</div>
                            <div class="hmail-header-title">Inbox</div>
                        </div>
                    </div>
                    <div class="hmail-search-wrap">
                        <i data-lucide="search" class="hmail-search-icon"></i>
                        <input v-model="searchQuery" placeholder="Search mail" class="hmail-search-input" />
                    </div>
                </div>

                <div class="hmail-list">
                    <template v-if="filteredEmails.length">
                        <div
                            v-for="email in filteredEmails"
                            :key="email.id"
                            :class="['hmail-row', !email.read ? 'hmail-row-unread' : '']"
                            @click="openEmail(email.id)"
                        >
                            <div class="hmail-avatar" :style="{ background: avatarColor(email.from) }">
                                {{ email.from.charAt(0).toUpperCase() }}
                            </div>
                            <div class="hmail-row-body">
                                <div class="hmail-row-top">
                                    <span class="hmail-row-sender">{{ email.from }}</span>
                                    <span class="hmail-row-time">{{ email.time }}</span>
                                </div>
                                <div class="hmail-row-subject">{{ email.subject }}</div>
                                <div class="hmail-row-snippet">{{ email.snippet }}</div>
                            </div>
                            <div class="hmail-row-aside">
                                <button type="button" class="hmail-star-btn" @click.stop="toggleStar(email)" :aria-label="email.starred ? 'Unstar' : 'Star'">
                                    <i data-lucide="star" :class="['hmail-star-icon', email.starred ? 'hmail-star-on' : '']"></i>
                                </button>
                                <div v-if="!email.read" class="hmail-unread-dot"></div>
                            </div>
                        </div>
                    </template>
                    <div v-else class="phone-empty-state">No emails found.</div>
                </div>

                <button type="button" class="hmail-fab" aria-label="Compose email" @click="openCompose">
                    <i data-lucide="pencil" class="hmail-fab-icon"></i>
                </button>
            </div>

            <!-- ── Thread view ── -->
            <div v-else-if="view === 'thread' && currentEmail" class="hmail-thread-screen">
                <div class="hmail-thread-header">
                    <button type="button" aria-label="Back to inbox" class="hmail-nav-button" @click="view = 'inbox'">
                        <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                    </button>
                    <div class="hmail-thread-actions">
                        <button type="button" class="hmail-icon-btn" aria-label="Delete" @click="deleteEmail">
                            <i data-lucide="trash-2" class="hmail-icon-btn-svg"></i>
                        </button>
                        <button type="button" class="hmail-icon-btn" aria-label="Reply" @click="openReply">
                            <i data-lucide="reply" class="hmail-icon-btn-svg"></i>
                        </button>
                    </div>
                </div>

                <div class="hmail-thread-body">
                    <div class="hmail-thread-subject">{{ currentEmail.subject }}</div>
                    <div class="hmail-thread-meta">
                        <div class="hmail-thread-avatar" :style="{ background: avatarColor(currentEmail.from) }">
                            {{ currentEmail.from.charAt(0).toUpperCase() }}
                        </div>
                        <div class="hmail-thread-meta-copy">
                            <div class="hmail-thread-sender">{{ currentEmail.from }}</div>
                            <div class="hmail-thread-to">To: me &nbsp;·&nbsp; {{ currentEmail.time }}</div>
                        </div>
                    </div>
                    <div class="hmail-thread-content">{{ currentEmail.body }}</div>
                </div>
            </div>

            <!-- ── Compose ── -->
            <div v-else-if="view === 'compose'" class="hmail-compose-screen">
                <div class="hmail-compose-header">
                    <button type="button" class="hmail-nav-button" @click="view = 'inbox'" aria-label="Discard">
                        <i data-lucide="x" style="width:1.25rem;height:1.25rem"></i>
                    </button>
                    <span class="hmail-compose-title">New Message</span>
                    <button type="button" class="hmail-send-btn" @click="sendEmail" aria-label="Send">
                        <i data-lucide="send-horizontal" class="hmail-send-icon"></i>
                    </button>
                </div>

                <div class="hmail-compose-fields">
                    <div class="hmail-compose-field">
                        <span class="hmail-compose-field-label">To</span>
                        <input v-model="composeTo" class="hmail-compose-field-input" placeholder="Recipient phone number" />
                    </div>
                    <div class="hmail-compose-field hmail-compose-field-border">
                        <span class="hmail-compose-field-label">Subject</span>
                        <input v-model="composeSubject" class="hmail-compose-field-input" placeholder="Subject" />
                    </div>
                </div>

                <textarea v-model="composeBody" class="hmail-compose-body" placeholder="Compose email…"></textarea>
            </div>

        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, computed, onMounted, onUnmounted } = Vue;
        const { EMAILS, currentEmailId } = window.PhoneStore;

        const view = ref("inbox");
        const searchQuery = ref("");
        const composeTo = ref("");
        const composeSubject = ref("");
        const composeBody = ref("");

        const AVATAR_COLORS = ["rgb(59 130 246)", "rgb(168 85 247)", "rgb(34 197 94)", "rgb(249 115 22)", "rgb(239 68 68)", "rgb(20 184 166)"];
        function avatarColor(name) {
            let hash = 0;
            for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
            return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
        }

        const filteredEmails = computed(() => {
            const q = searchQuery.value.trim().toLowerCase();
            if (!q) return EMAILS;
            return EMAILS.filter((e) => e.from.toLowerCase().includes(q) || e.subject.toLowerCase().includes(q) || e.body.toLowerCase().includes(q));
        });

        const currentEmail = computed(() => EMAILS.find((e) => e.id === currentEmailId.value) || null);

        function openEmail(id) {
            currentEmailId.value = id;
            const email = EMAILS.find((e) => e.id === id);
            if (email) email.read = true;
            view.value = "thread";
        }

        function openCompose() {
            composeTo.value = "";
            composeSubject.value = "";
            composeBody.value = "";
            view.value = "compose";
        }

        function openReply() {
            if (!currentEmail.value) return;
            composeTo.value = currentEmail.value.fromNumber;
            composeSubject.value = `Re: ${currentEmail.value.subject}`;
            composeBody.value = "";
            view.value = "compose";
        }

        function sendEmail() {
            const toNumber = composeTo.value.trim();
            const subject = composeSubject.value.trim();
            const body = composeBody.value.trim();
            if (!toNumber || !subject) return;
            hEvent("sendEmail", { toNumber, subject, body });
            const timeLabel = new Date().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true });
            EMAILS.unshift({
                id: Date.now(),
                from: window.PhoneStore.playerName.value || "Me",
                fromNumber: "",
                subject,
                snippet: body.substring(0, 80),
                body,
                time: timeLabel,
                read: true,
                starred: false,
            });
            view.value = "inbox";
        }

        function deleteEmail() {
            if (!currentEmail.value) return;
            const idx = EMAILS.findIndex((e) => e.id === currentEmail.value.id);
            if (idx !== -1) EMAILS.splice(idx, 1);
            hEvent("deleteEmail", { emailId: currentEmail.value.id });
            currentEmailId.value = null;
            view.value = "inbox";
        }

        function toggleStar(email) {
            email.starred = !email.starred;
        }

        function onMessage(e) {
            const { name, args = [] } = e.data || {};
            if (name === "emailsLoaded") {
                const incoming = JSON.parse(args[0] || "[]");
                EMAILS.splice(0, EMAILS.length, ...incoming);
            } else if (name === "emailReceived") {
                const email = JSON.parse(args[0] || "{}");
                if (email.id) EMAILS.unshift(email);
            }
        }

        onMounted(() => {
            window.addEventListener("message", onMessage);
            hEvent("loadEmails");
        });
        onUnmounted(() => window.removeEventListener("message", onMessage));

        function onBack() {
            currentEmailId.value = null;
            searchQuery.value = "";
            view.value = "inbox";
            emit("navigate", "home");
        }

        return {
            view,
            searchQuery,
            composeTo,
            composeSubject,
            composeBody,
            filteredEmails,
            currentEmail,
            avatarColor,
            openEmail,
            openCompose,
            openReply,
            sendEmail,
            deleteEmail,
            toggleStar,
            onBack,
        };
    },
};
