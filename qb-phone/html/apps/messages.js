const MessagesApp = {
    template: `
        <div style="height: 100%">

            <!-- ── New conversation screen ── -->
            <div v-if="composingNew" class="messages-screen">
                <div class="messages-top">
                    <div class="messages-title-row">
                        <button type="button" aria-label="Cancel" class="messages-nav-button" @click="composingNew = false; newQuery = ''">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="messages-eyebrow">Messages</div>
                            <div class="messages-view-title">New Message</div>
                        </div>
                    </div>
                    <div class="messages-search-wrap">
                        <i data-lucide="user" class="messages-search-icon"></i>
                        <input v-model="newQuery" placeholder="Search name or number" class="messages-search-input" autofocus />
                    </div>
                </div>
                <div class="messages-list">
                    <!-- Direct number entry row -->
                    <div v-if="newQuery.trim()" class="messages-row">
                        <button type="button" class="messages-row-main" @click="startConversation({ name: newQuery.trim(), number: newQuery.trim(), image: '' })">
                            <div class="messages-avatar" style="background: rgb(99 102 241); color: white">
                                <i data-lucide="hash" style="width:1rem;height:1rem"></i>
                            </div>
                            <div class="messages-row-copy">
                                <div class="messages-row-top">
                                    <div class="messages-row-name">{{ newQuery.trim() }}</div>
                                </div>
                                <div class="messages-row-preview">Send to this number</div>
                            </div>
                        </button>
                    </div>
                    <template v-if="contactSuggestions.length">
                        <div v-for="c in contactSuggestions" :key="c.number" class="messages-row">
                            <button type="button" class="messages-row-main" @click="startConversation(c)">
                                <div v-if="c.image" class="messages-avatar messages-avatar-image">
                                    <img :src="c.image" :alt="c.name" class="messages-avatar-image-tag" @error="e => { e.target.style.display='none'; e.target.parentElement.textContent = c.name.charAt(0).toUpperCase(); }" />
                                </div>
                                <div v-else class="messages-avatar">{{ c.name.charAt(0).toUpperCase() }}</div>
                                <div class="messages-row-copy">
                                    <div class="messages-row-top">
                                        <div class="messages-row-name">{{ c.name }}</div>
                                    </div>
                                    <div class="messages-row-preview">{{ c.number }}</div>
                                </div>
                            </button>
                        </div>
                    </template>
                    <div v-else-if="!newQuery.trim()" class="phone-empty-state">No contacts found.</div>
                </div>
            </div>

            <!-- ── Inbox ── -->
            <div v-else-if="currentConversationId === null" class="messages-screen">
                <div class="messages-top">
                    <div class="messages-title-row">
                        <button type="button" aria-label="Back to home" class="messages-nav-button" @click="onBack">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="messages-eyebrow">Messages</div>
                            <div class="messages-view-title">Conversations</div>
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

                <button type="button" class="messages-fab" aria-label="New message" @click="composingNew = true">
                    <i data-lucide="pencil" class="messages-fab-icon"></i>
                </button>
            </div>

            <div v-else-if="currentConversation" class="messages-thread-screen">
                <div class="messages-thread-header">
                    <div class="messages-thread-header-left">
                        <button type="button" aria-label="Back to messages" class="messages-nav-button" @click="backToList">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
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
                        <button type="button" class="messages-header-action" aria-label="Call contact" @click="callContact">
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
                            <img v-if="isImageUrl(msg.text)" :src="msg.text" class="message-bubble-image" @click="viewingImage = msg.text" @error="e => e.target.style.display='none'" />
                            <div v-else-if="isAudioUrl(msg.text)" :class="['voice-player', msg.sender === 'me' ? 'voice-player-me' : 'voice-player-them']">
                                <button type="button" class="voice-play-btn" @click="toggleAudio(msg)">
                                    <svg v-if="playingAudioId === msg.id" viewBox="0 0 16 16" fill="currentColor" style="width:0.875rem;height:0.875rem;display:block">
                                        <rect x="3" y="2" width="4" height="12" rx="1"/>
                                        <rect x="9" y="2" width="4" height="12" rx="1"/>
                                    </svg>
                                    <svg v-else viewBox="0 0 16 16" fill="currentColor" style="width:0.875rem;height:0.875rem;display:block;margin-left:1px">
                                        <polygon points="3,1 14,8 3,15"/>
                                    </svg>
                                </button>
                                <div class="voice-player-waveform" @click="seekAudio(msg, $event)">
                                    <span v-for="(h, i) in getWaveHeights(msg.id)" :key="i"
                                          class="voice-player-bar"
                                          :style="{ height: h + 'px', opacity: getBarProgress(i, 28, msg) }">
                                    </span>
                                </div>
                                <span class="voice-player-time">{{ getAudioTimeDisplay(msg) }}</span>
                            </div>
                            <div v-else-if="isPaymentMessage(msg.text)" class="payment-bubble-card">
                                <span class="payment-bubble-icon">💸</span>
                                <div class="payment-bubble-content">
                                    <div class="payment-bubble-amount">{{ '$' + getPaymentAmount(msg.text).toLocaleString() }}</div>
                                    <div class="payment-bubble-label">{{ msg.sender === 'me' ? 'Sent' : 'Received' }}</div>
                                </div>
                            </div>
                            <div v-else>{{ msg.text }}</div>
                            <div class="message-bubble-time">{{ msg.time }}</div>
                        </div>
                    </div>
                </div>
                <!-- Money picker -->
                <div v-if="showMoneyPicker" class="emoji-picker money-picker">
                    <div class="money-picker-title">Send Money</div>
                    <div class="money-picker-input-wrap">
                        <span class="money-picker-currency">$</span>
                        <input v-model="moneyAmount" type="number" min="1" step="1" placeholder="0" class="money-picker-input" @keyup.enter="sendMoney" />
                    </div>
                    <div v-if="moneyError" class="money-picker-error">{{ moneyError }}</div>
                    <button type="button" class="money-picker-send-btn" :disabled="!moneyAmountValid || sendingMoney" @click="sendMoney">
                        {{ sendingMoney ? 'Sending…' : 'Send' }}
                    </button>
                </div>
                <div v-if="showMoneyPicker" class="emoji-picker-backdrop" @click="showMoneyPicker = false; moneyError = ''"></div>

                <!-- GIF picker -->
                <div v-if="showGifPicker" class="emoji-picker gif-picker">
                    <div class="gif-picker-search-wrap">
                        <i data-lucide="search" class="gif-picker-search-icon"></i>
                        <input v-model="gifQuery" placeholder="Search GIFs…" class="gif-picker-search-input" />
                    </div>
                    <div v-if="gifLoading" class="gallery-picker-empty">Loading…</div>
                    <div v-else-if="gifResults.length" class="gif-picker-grid">
                        <button v-for="gif in gifResults" :key="gif.id" type="button" class="gif-picker-tile" @click="insertGif(gif)">
                            <img :src="gif.images.fixed_width_small.url" class="gif-picker-img" />
                        </button>
                    </div>
                    <div v-else class="gallery-picker-empty">No GIFs found.</div>
                </div>
                <div v-if="showGifPicker" class="emoji-picker-backdrop" @click="showGifPicker = false"></div>

                <!-- Gallery picker -->
                <div v-if="showGalleryPicker" class="emoji-picker gallery-picker">
                    <div v-if="PHOTOS.length" class="gallery-picker-grid">
                        <button v-for="photo in PHOTOS" :key="photo.id" type="button"
                            class="gallery-picker-tile" :style="{ background: photo.gradient }"
                            @click="insertPhoto(photo)">
                        </button>
                    </div>
                    <div v-else class="gallery-picker-empty">No photos yet. Use the camera app to add some.</div>
                </div>
                <div v-if="showGalleryPicker" class="emoji-picker-backdrop" @click="showGalleryPicker = false"></div>

                <!-- Emoji picker -->
                <div v-if="showEmojiPicker" class="emoji-picker">
                    <div class="emoji-picker-tabs">
                        <button v-for="cat in emojiCategories" :key="cat.name"
                            :class="['emoji-tab', activeEmojiTab === cat.name ? 'emoji-tab-active' : '']"
                            @click="activeEmojiTab = cat.name">{{ cat.icon }}</button>
                    </div>
                    <div class="emoji-picker-grid">
                        <button v-for="em in activeEmojiList" :key="em" class="emoji-btn" @click="insertEmoji(em)">{{ em }}</button>
                    </div>
                </div>
                <div v-if="showEmojiPicker" class="emoji-picker-backdrop" @click="showEmojiPicker = false"></div>

                <div v-if="audioError" class="phone-empty-state" style="padding-top: 0.35rem; padding-bottom: 0.35rem; color: #f87171;">
                    {{ audioError }}
                </div>
                <div class="messages-composer">
                    <template v-if="isRecording">
                        <button type="button" class="voice-cancel-btn" aria-label="Cancel recording" @click="cancelRecording">
                            <i data-lucide="trash-2" style="width:1rem;height:1rem"></i>
                        </button>
                        <div class="voice-rec-live">
                            <span class="voice-rec-dot"></span>
                            <span class="voice-rec-label">Recording</span>
                            <span class="voice-rec-timer">{{ recordingDisplay }}</span>
                        </div>
                        <button type="button" class="messages-send-button" :disabled="isUploadingAudio" aria-label="Send voice message" @click="stopRecording">
                            <i v-if="isUploadingAudio" data-lucide="loader-2" class="messages-send-icon messages-send-spin"></i>
                            <i v-else data-lucide="send-horizontal" class="messages-send-icon"></i>
                        </button>
                    </template>
                    <template v-else>
                        <div class="messages-composer-pill">
                            <input v-model="messageDraft" placeholder="Message" class="messages-composer-input" @keyup.enter="sendMessage" />
                            <button type="button" :class="['messages-composer-icon-btn', showEmojiPicker ? 'messages-composer-icon-btn-active' : '']" aria-label="Emoji" @click.stop="showEmojiPicker = !showEmojiPicker">
                                <i data-lucide="smile" style="width:1.25rem;height:1.25rem"></i>
                            </button>
                            <button type="button" :class="['messages-composer-icon-btn messages-composer-gif-btn', showGifPicker ? 'messages-composer-icon-btn-active' : '']" aria-label="GIF" @click.stop="toggleGifPicker">
                                <span class="messages-composer-gif-label">GIF</span>
                            </button>
                            <button type="button" :class="['messages-composer-icon-btn', showGalleryPicker ? 'messages-composer-icon-btn-active' : '']" aria-label="Gallery" @click.stop="showGalleryPicker = !showGalleryPicker">
                                <i data-lucide="image" style="width:1.25rem;height:1.25rem"></i>
                            </button>
                            <button type="button" :class="['messages-composer-icon-btn messages-composer-money-btn', showMoneyPicker ? 'messages-composer-icon-btn-active' : '']" aria-label="Send money" @click.stop="toggleMoneyPicker">
                                <span class="messages-composer-money-label">$</span>
                            </button>
                        </div>
                        <button v-if="messageDraft.trim()" type="button" class="messages-send-button" aria-label="Send message" @click="sendMessage">
                            <i data-lucide="send-horizontal" class="messages-send-icon"></i>
                        </button>
                        <button v-else type="button" class="messages-send-button" aria-label="Record voice message" @click="startRecording">
                            <i data-lucide="mic" class="messages-send-icon"></i>
                        </button>
                    </template>
                </div>
            </div>
        </div>

        <!-- Image lightbox -->
        <div v-if="viewingImage" class="image-lightbox" @click="viewingImage = null">
            <img :src="viewingImage" class="image-lightbox-img" @click.stop />
        </div>
    `,

    emits: ["navigate", "dial"],

    setup(props, { emit }) {
        const { ref, computed } = Vue;
        const { CONVERSATIONS, CONTACTS, PHOTOS, currentConversationId } = window.PhoneStore;

        const messageSearch = ref("");
        const messageDraft = ref("");
        const composingNew = ref(false);
        const newQuery = ref("");
        const viewingImage = ref(null);
        const showEmojiPicker = ref(false);
        const showGalleryPicker = ref(false);
        const isRecording = ref(false);
        const isUploadingAudio = ref(false);
        const audioError = ref("");
        const recordingSeconds = ref(0);
        const recordingDisplay = Vue.computed(() => {
            const s = recordingSeconds.value;
            return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        });
        let _mediaRecorder = null;
        let _audioChunks = [];
        let _recordingTimer = null;

        const playingAudioId = ref(null);
        const audioCurrentTime = ref(0);
        const audioDurations = Vue.reactive({});
        let _playerAudio = null;
        const _waveCache = {};

        async function startRecording() {
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                _audioChunks = [];
                _mediaRecorder = new MediaRecorder(stream);
                _mediaRecorder.ondataavailable = (e) => {
                    if (e.data.size > 0) _audioChunks.push(e.data);
                };
                _mediaRecorder.start();
                isRecording.value = true;
                recordingSeconds.value = 0;
                _recordingTimer = setInterval(() => recordingSeconds.value++, 1000);
            } catch (err) {
                isRecording.value = false;
                const name = err?.name ?? String(err);
                if (name === "NotAllowedError" || name === "PermissionDeniedError") {
                    audioError.value = "Microphone access denied.";
                } else if (name === "NotFoundError" || name === "DevicesNotFoundError") {
                    audioError.value = "No microphone found.";
                } else if (!navigator.mediaDevices) {
                    audioError.value = "Microphone not supported in this context.";
                } else {
                    audioError.value = "Could not start recording (" + name + ").";
                }
                setTimeout(() => {
                    audioError.value = "";
                }, 4000);
            }
        }

        async function stopRecording() {
            if (!_mediaRecorder) return;
            clearInterval(_recordingTimer);
            _recordingTimer = null;
            isRecording.value = false;

            const blob = await new Promise((resolve) => {
                _mediaRecorder.onstop = () => resolve(new Blob(_audioChunks, { type: "audio/ogg" }));
                _mediaRecorder.stop();
                _mediaRecorder.stream.getTracks().forEach((t) => t.stop());
            });
            _mediaRecorder = null;
            _audioChunks = [];

            isUploadingAudio.value = true;
            try {
                const fd = new FormData();
                fd.append("file", blob, "voice_message.ogg");
                const res = await fetch("https://api.fivemanage.com/api/v3/file", {
                    method: "POST",
                    headers: { Authorization: "zvYWd23h2vlgppAbwFalDYJPhM0bCoRk" },
                    body: fd,
                });
                const json = await res.json();
                const url = json?.data?.url;
                if (url) {
                    messageDraft.value = url;
                    sendMessage();
                }
            } catch {
            } finally {
                isUploadingAudio.value = false;
            }
        }

        function cancelRecording() {
            if (_mediaRecorder) {
                clearInterval(_recordingTimer);
                _recordingTimer = null;
                try {
                    _mediaRecorder.ondataavailable = null;
                    _mediaRecorder.stream.getTracks().forEach((t) => t.stop());
                    _mediaRecorder.stop();
                } catch {}
                _mediaRecorder = null;
            }
            _audioChunks = [];
            isRecording.value = false;
            recordingSeconds.value = 0;
        }

        function getWaveHeights(msgId) {
            if (_waveCache[msgId]) return _waveCache[msgId];
            const seed = typeof msgId === "number" ? msgId % 1000 : 0;
            const bars = Array.from({ length: 28 }, (_, i) => {
                const h = Math.abs(
                    Math.sin(i * 0.45 + seed * 0.008) * 9 +
                    Math.sin(i * 0.82 + seed * 0.014) * 5 +
                    Math.sin(i * 1.3 + seed * 0.005) * 3
                ) + 3;
                return Math.min(Math.max(Math.round(h), 3), 18);
            });
            _waveCache[msgId] = bars;
            return bars;
        }

        function getBarProgress(barIndex, total, msg) {
            if (playingAudioId.value !== msg.id) return 1;
            const duration = audioDurations[msg.id];
            if (!duration || !isFinite(duration)) return 1;
            return (barIndex / total) <= (audioCurrentTime.value / duration) ? 1 : 0.3;
        }

        function fmtTime(secs) {
            const s = Math.floor(secs);
            return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        }

        function getAudioTimeDisplay(msg) {
            if (playingAudioId.value === msg.id) return fmtTime(audioCurrentTime.value);
            const dur = audioDurations[msg.id];
            return (dur && isFinite(dur)) ? fmtTime(dur) : "";
        }

        function seekAudio(msg, event) {
            const duration = audioDurations[msg.id];
            if (playingAudioId.value !== msg.id || !duration || !isFinite(duration)) {
                toggleAudio(msg);
                return;
            }
            const rect = event.currentTarget.getBoundingClientRect();
            const ratio = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width));
            _playerAudio.currentTime = ratio * duration;
            audioCurrentTime.value = _playerAudio.currentTime;
        }

        function toggleAudio(msg) {
            if (playingAudioId.value === msg.id) {
                if (_playerAudio) _playerAudio.pause();
                playingAudioId.value = null;
                return;
            }
            if (_playerAudio) {
                _playerAudio.onloadedmetadata = null;
                _playerAudio.ondurationchange = null;
                _playerAudio.onseeked = null;
                _playerAudio.ontimeupdate = null;
                _playerAudio.onended = null;
                _playerAudio.onerror = null;
                _playerAudio.pause();
                _playerAudio.src = "";
            }
            const audio = new Audio(msg.text);
            _playerAudio = audio;

            // MediaRecorder WebM omits the duration header so audio.duration is
            // Infinity until we seek past the end, which forces Chrome to scan the
            // file and fire ondurationchange with the real value.
            //
            // State machine gates onended/ontimeupdate until we're actually ready:
            //   discovering → seeking to 1e10 to resolve duration
            //   resetting   → seeking back to 0 after resolution
            //   ready       → normal playback
            let durState = "discovering";

            audio.onloadedmetadata = () => {
                if (isFinite(audio.duration)) {
                    audioDurations[msg.id] = audio.duration;
                    durState = "ready";
                } else if (isFinite(audioDurations[msg.id])) {
                    // Duration already known from a prior play — skip the scan
                    durState = "ready";
                } else {
                    audio.currentTime = 1e10;
                }
            };

            audio.ondurationchange = () => {
                if (isFinite(audio.duration)) audioDurations[msg.id] = audio.duration;
            };

            audio.onseeked = () => {
                if (durState === "discovering") {
                    durState = "resetting";
                    audio.currentTime = 0;
                } else if (durState === "resetting") {
                    durState = "ready";
                    if (_playerAudio === audio) audio.play().catch(() => {});
                }
            };

            audio.ontimeupdate = () => {
                if (durState === "ready") audioCurrentTime.value = audio.currentTime;
            };

            audio.onended = () => {
                if (durState !== "ready") return;
                playingAudioId.value = null;
                audioCurrentTime.value = 0;
            };

            audio.onerror = () => { playingAudioId.value = null; };
            playingAudioId.value = msg.id;
            audioCurrentTime.value = 0;
            audio.play().catch(() => { playingAudioId.value = null; });
        }

        function isAudioUrl(text) {
            if (!text) return false;
            try {
                const url = new URL(text);
                return /\.(mp3|ogg|wav|webm|m4a|aac)(\?.*)?$/i.test(url.pathname);
            } catch {
                return false;
            }
        }
        const showMoneyPicker = ref(false);
        const moneyAmount = ref('');
        const moneyError = ref('');
        const sendingMoney = ref(false);
        const moneyAmountValid = Vue.computed(() => {
            const n = parseFloat(moneyAmount.value);
            return Number.isFinite(n) && n >= 1;
        });

        const showGifPicker = ref(false);
        const gifQuery = ref("");
        const gifResults = ref([]);
        const gifLoading = ref(false);
        let gifDebounce = null;
        const GIPHY_KEY = "5CPPKIuHNPKyo2ZhPzILZvnASPTyHSFA";

        Vue.watch(gifQuery, (q) => {
            clearTimeout(gifDebounce);
            gifDebounce = setTimeout(() => fetchGifs(q.trim()), 400);
        });

        async function fetchGifs(q) {
            gifLoading.value = true;
            const endpoint = q ? `https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_KEY}&q=${encodeURIComponent(q)}&limit=12&rating=pg13` : `https://api.giphy.com/v1/gifs/trending?api_key=${GIPHY_KEY}&limit=12&rating=pg13`;
            try {
                const res = await fetch(endpoint);
                const json = await res.json();
                gifResults.value = json.data ?? [];
            } catch {
                gifResults.value = [];
            } finally {
                gifLoading.value = false;
            }
        }

        function toggleGifPicker() {
            showGifPicker.value = !showGifPicker.value;
            if (showGifPicker.value && gifResults.value.length === 0) fetchGifs("");
        }

        function insertGif(gif) {
            const url = gif.images.original.url;
            messageDraft.value = url;
            showGifPicker.value = false;
            sendMessage();
        }
        const emojiCategories = window.EMOJI_CATEGORIES;
        const activeEmojiTab = ref(emojiCategories[0].name);
        const activeEmojiList = Vue.computed(() => emojiCategories.find((c) => c.name === activeEmojiTab.value)?.emojis ?? []);

        const contactSuggestions = computed(() => {
            const q = newQuery.value.trim().toLowerCase();
            if (!q) return CONTACTS;
            return CONTACTS.filter((c) => c.name.toLowerCase().includes(q) || c.number.includes(q));
        });

        const filteredConversations = computed(() => {
            const q = messageSearch.value.trim().toLowerCase();
            if (!q) return CONVERSATIONS;
            return CONVERSATIONS.filter((c) => c.name.toLowerCase().includes(q) || c.number.toLowerCase().includes(q) || c.messages.some((m) => m.text.toLowerCase().includes(q)));
        });

        const currentConversation = computed(() => CONVERSATIONS.find((c) => c.id === currentConversationId.value) || null);

        function isImageUrl(text) {
            if (!text) return false;
            try {
                const url = new URL(text);
                return /\.(jpe?g|png|gif|webp|bmp|svg)(\?.*)?$/i.test(url.pathname);
            } catch {
                return false;
            }
        }

        function getConversationPreview(c) {
            const last = c.messages[c.messages.length - 1];
            if (!last) return "No messages yet";
            if (isImageUrl(last.text)) return "[Image]";
            if (isAudioUrl(last.text)) return "[Voice message]";
            if (isPaymentMessage(last.text)) return last.sender === 'me' ? '💸 Sent $' + getPaymentAmount(last.text) : '💸 Received $' + getPaymentAmount(last.text);
            return last.text;
        }

        function getConversationTime(c) {
            const last = c.messages[c.messages.length - 1];
            return last ? last.time : "";
        }

        function openConversation(id) {
            currentConversationId.value = id;
            messageDraft.value = "";
        }

        function backToList() {
            currentConversationId.value = null;
            messageDraft.value = "";
        }

        function callContact() {
            const conv = currentConversation.value;
            if (!conv) return;
            emit("dial", { name: conv.name, number: conv.number });
            hEvent("dial", { number: conv.number });
        }

        function deleteConversation(id) {
            const idx = CONVERSATIONS.findIndex((c) => c.id === id);
            if (idx === -1) return;
            const conv = CONVERSATIONS[idx];
            hEvent("deleteConversation", { number: conv.number });
            CONVERSATIONS.splice(idx, 1);
            if (currentConversationId.value === id) currentConversationId.value = null;
        }

        function startConversation(contact) {
            let conv = CONVERSATIONS.find((c) => c.number === contact.number);
            if (!conv) {
                conv = { id: Date.now(), name: contact.name, number: contact.number, image: contact.image || "", messages: [] };
                CONVERSATIONS.unshift(conv);
            }
            currentConversationId.value = conv.id;
            composingNew.value = false;
            newQuery.value = "";
            messageDraft.value = "";
        }

        function isPaymentMessage(text) {
            return typeof text === 'string' && /^\[PAYMENT:\d+\]$/.test(text);
        }

        function getPaymentAmount(text) {
            const m = text && text.match(/^\[PAYMENT:(\d+)\]$/);
            return m ? parseInt(m[1]) : 0;
        }

        function toggleMoneyPicker() {
            showMoneyPicker.value = !showMoneyPicker.value;
            if (showMoneyPicker.value) {
                showEmojiPicker.value = false;
                showGifPicker.value = false;
                showGalleryPicker.value = false;
                moneyError.value = '';
            }
        }

        function sendMoney() {
            const amount = Math.floor(parseFloat(moneyAmount.value));
            if (!amount || amount <= 0) return;
            const conv = currentConversation.value;
            if (!conv) return;
            sendingMoney.value = true;
            moneyError.value = '';
            hEvent('sendMoney', { number: conv.number, amount });
        }

        const _moneyResultHandler = function(event) {
            const { name, args = [] } = event.data;
            if (name !== 'moneyTransferResult') return;
            const [success, resultData] = args;
            sendingMoney.value = false;
            if (success) {
                const conv = currentConversation.value;
                if (conv) conv.messages.push({ id: Date.now(), sender: 'me', text: '[PAYMENT:' + resultData + ']', time: 'Now' });
                showMoneyPicker.value = false;
                moneyAmount.value = '';
            } else {
                moneyError.value = resultData || 'Transfer failed';
            }
        };
        window.addEventListener('message', _moneyResultHandler);
        Vue.onUnmounted(() => window.removeEventListener('message', _moneyResultHandler));

        function insertEmoji(em) {
            messageDraft.value += em;
        }

        function insertPhoto(photo) {
            messageDraft.value = photo.url;
            showGalleryPicker.value = false;
            sendMessage();
        }

        function sendMessage() {
            const text = messageDraft.value.trim();
            if (!text || currentConversationId.value === null) return;
            const conv = currentConversation.value;
            if (!conv) return;
            conv.messages.push({ id: Date.now(), sender: "me", text, time: "Now" });
            hEvent("sendMessage", { number: conv.number, text });
            messageDraft.value = "";
            showEmojiPicker.value = false;
            showGalleryPicker.value = false;
            showGifPicker.value = false;
            showMoneyPicker.value = false;
        }

        function onBack() {
            currentConversationId.value = null;
            messageSearch.value = "";
            messageDraft.value = "";
            composingNew.value = false;
            newQuery.value = "";
            emit("navigate", "home");
        }

        return {
            currentConversationId,
            messageSearch,
            messageDraft,
            composingNew,
            newQuery,
            contactSuggestions,
            filteredConversations,
            currentConversation,
            viewingImage,
            PHOTOS,
            showEmojiPicker,
            showGalleryPicker,
            isRecording,
            isUploadingAudio,
            audioError,
            recordingDisplay,
            startRecording,
            stopRecording,
            cancelRecording,
            playingAudioId,
            toggleAudio,
            seekAudio,
            getWaveHeights,
            getBarProgress,
            getAudioTimeDisplay,
            isAudioUrl,
            showMoneyPicker,
            moneyAmount,
            moneyError,
            sendingMoney,
            moneyAmountValid,
            toggleMoneyPicker,
            sendMoney,
            isPaymentMessage,
            getPaymentAmount,
            showGifPicker,
            gifQuery,
            gifResults,
            gifLoading,
            toggleGifPicker,
            insertGif,
            insertPhoto,
            emojiCategories,
            activeEmojiTab,
            activeEmojiList,
            insertEmoji,
            isImageUrl,
            getConversationPreview,
            getConversationTime,
            openConversation,
            backToList,
            callContact,
            deleteConversation,
            startConversation,
            sendMessage,
            onBack,
        };
    },
};
