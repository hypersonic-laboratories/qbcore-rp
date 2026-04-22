const MessagesApp = {
    template: `
        <div style="height: 100%">
            <div v-if="currentConversationId === null" class="messages-screen">
                <div class="messages-top">
                    <div class="messages-title-row">
                        <button type="button" aria-label="Back to home" class="calendar-icon-button" @click="onBack">
                            <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="calendar-eyebrow">Messages</div>
                            <div class="calendar-month-title">Conversations</div>
                        </div>
                    </div>
                    <div class="messages-search-wrap">
                        <i data-lucide="search" class="messages-search-icon"></i>
                        <input v-model="messageSearch" placeholder="Search messages" class="messages-search-input" />
                    </div>
                </div>
                <div class="messages-list">
                    <template v-if="filteredConversations.length">
                        <div v-for="conv in filteredConversations" :key="conv.id" class="messages-row">
                            <button type="button" class="messages-row-main" @click="openConversation(conv.id)">
                                <div v-if="conv.image" class="messages-avatar messages-avatar-image">
                                    <img :src="conv.image" :alt="conv.name" class="messages-avatar-image-tag" @error="e => { e.target.style.display='none'; e.target.parentElement.textContent = conv.name.charAt(0).toUpperCase(); }" />
                                </div>
                                <div v-else class="messages-avatar">{{ conv.name.charAt(0).toUpperCase() }}</div>
                                <div class="messages-row-copy">
                                    <div class="messages-row-top">
                                        <div class="messages-row-name">{{ conv.name }}</div>
                                        <div class="messages-row-time">{{ getConversationTime(conv) }}</div>
                                    </div>
                                    <div class="messages-row-preview">{{ getConversationPreview(conv) }}</div>
                                </div>
                            </button>
                            <button type="button" class="messages-delete-button" :aria-label="'Delete ' + conv.name" @click="deleteConversation(conv.id)">
                                <i data-lucide="trash-2" class="messages-delete-icon"></i>
                            </button>
                        </div>
                    </template>
                    <div v-else class="phone-empty-state">No conversations found.</div>
                </div>
            </div>

            <div v-else-if="currentConversation" class="messages-thread-screen">
                <div class="messages-thread-header">
                    <div class="messages-thread-header-left">
                        <button type="button" aria-label="Back to messages" class="calendar-icon-button" @click="backToList">
                            <i data-lucide="arrow-left" class="calendar-nav-icon"></i>
                        </button>
                        <div v-if="currentConversation.image" class="messages-avatar messages-avatar-image">
                            <img :src="currentConversation.image" :alt="currentConversation.name" class="messages-avatar-image-tag" @error="e => { e.target.style.display='none'; e.target.parentElement.textContent = currentConversation.name.charAt(0).toUpperCase(); }" />
                        </div>
                        <div v-else class="messages-avatar">{{ currentConversation.name.charAt(0).toUpperCase() }}</div>
                        <div class="messages-thread-contact-copy">
                            <div class="messages-thread-contact-name">{{ currentConversation.name }}</div>
                        </div>
                    </div>
                    <div class="messages-thread-actions">
                        <button type="button" class="messages-header-action" aria-label="Call contact">
                            <i data-lucide="phone" class="messages-header-action-icon"></i>
                        </button>
                        <button type="button" class="messages-header-action" aria-label="More options">
                            <i data-lucide="more-vertical" class="messages-header-action-icon"></i>
                        </button>
                    </div>
                </div>
                <div class="messages-thread-body">
                    <div v-for="msg in currentConversation.messages" :key="msg.id" :class="['message-bubble-row', msg.sender === 'me' ? 'message-bubble-row-me' : '']">
                        <div :class="['message-bubble', msg.sender === 'me' ? 'message-bubble-me' : 'message-bubble-them']">
                            <div>{{ msg.text }}</div>
                            <div class="message-bubble-time">{{ msg.time }}</div>
                        </div>
                    </div>
                </div>
                <div class="messages-composer">
                    <input v-model="messageDraft" placeholder="Message" class="messages-composer-input" @keyup.enter="sendMessage" />
                    <button type="button" class="messages-send-button" aria-label="Send message" @click="sendMessage">
                        <i data-lucide="send-horizontal" class="messages-send-icon"></i>
                    </button>
                </div>
            </div>
        </div>
    `,

    emits: ['navigate'],

    setup(props, { emit }) {
        const { ref, computed } = Vue;
        const { CONVERSATIONS, currentConversationId } = window.PhoneStore;

        const messageSearch = ref('');
        const messageDraft  = ref('');

        const filteredConversations = computed(() => {
            const q = messageSearch.value.trim().toLowerCase();
            if (!q) return CONVERSATIONS;
            return CONVERSATIONS.filter(c =>
                c.name.toLowerCase().includes(q) ||
                c.number.toLowerCase().includes(q) ||
                c.messages.some(m => m.text.toLowerCase().includes(q))
            );
        });

        const currentConversation = computed(() =>
            CONVERSATIONS.find(c => c.id === currentConversationId.value) || null
        );

        function getConversationPreview(c) {
            const last = c.messages[c.messages.length - 1];
            return last ? last.text : 'No messages yet';
        }

        function getConversationTime(c) {
            const last = c.messages[c.messages.length - 1];
            return last ? last.time : '';
        }

        function openConversation(id) {
            currentConversationId.value = id;
            messageDraft.value = '';
        }

        function backToList() {
            currentConversationId.value = null;
            messageDraft.value = '';
        }

        function deleteConversation(id) {
            const idx = CONVERSATIONS.findIndex(c => c.id === id);
            if (idx === -1) return;
            if (!confirm(`Delete conversation with ${CONVERSATIONS[idx].name}?`)) return;
            CONVERSATIONS.splice(idx, 1);
            if (currentConversationId.value === id) currentConversationId.value = null;
        }

        function sendMessage() {
            const text = messageDraft.value.trim();
            if (!text || currentConversationId.value === null) return;
            const conv = currentConversation.value;
            if (!conv) return;
            conv.messages.push({ id: Date.now(), sender: 'me', text, time: 'Now' });
            hEvent('sendMessage', { number: conv.number, text });
            messageDraft.value = '';
        }

        function onBack() {
            currentConversationId.value = null;
            messageSearch.value = '';
            messageDraft.value = '';
            emit('navigate', 'home');
        }

        return {
            currentConversationId, messageSearch, messageDraft,
            filteredConversations, currentConversation,
            getConversationPreview, getConversationTime,
            openConversation, backToList, deleteConversation, sendMessage, onBack,
        };
    },
};
