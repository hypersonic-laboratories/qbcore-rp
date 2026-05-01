const PhotosApp = {
    template: `
        <div class="gallery-screen">

            <!-- ── Grid view ── -->
            <template v-if="!selectedPhoto">
                <div class="gallery-header">
                    <button type="button" class="gallery-icon-button" aria-label="Back" @click="onBack">
                        <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                    </button>
                    <div class="phone-app-top-copy">
                        <div class="gallery-eyebrow">Photos</div>
                        <div class="gallery-title">{{ PHOTOS.length }} photo{{ PHOTOS.length !== 1 ? 's' : '' }}</div>
                    </div>
                </div>

                <div v-if="PHOTOS.length" class="gallery-grid">
                    <button
                        v-for="photo in PHOTOS"
                        :key="photo.id"
                        type="button"
                        class="gallery-tile"
                        :style="{ background: photo.gradient }"
                        :aria-label="'Photo taken ' + photo.takenAt"
                        @click="selectedPhoto = photo"
                    ></button>
                </div>

                <div v-else class="phone-empty-state">
                    No photos yet. Open the camera to take one.
                </div>
            </template>

            <!-- ── Detail / lightbox view ── -->
            <template v-else>
                <div class="gallery-detail">
                    <div class="gallery-detail-photo" :style="{ background: selectedPhoto.gradient }">
                        <button type="button" class="gallery-detail-back" aria-label="Back to grid" @click="closeDetail">
                            <i data-lucide="arrow-left" class="gallery-detail-back-icon"></i>
                        </button>
                        <div class="gallery-detail-timestamp">{{ selectedPhoto.takenAt }}</div>
                    </div>

                    <div class="gallery-detail-actions">
                        <button type="button" class="gallery-action-btn gallery-action-share" @click="shareSheetOpen = true">
                            <i data-lucide="send" class="gallery-action-icon"></i>
                            <span>Share</span>
                        </button>
                        <button type="button" class="gallery-action-btn gallery-action-delete" @click="deletePhoto">
                            <i data-lucide="trash-2" class="gallery-action-icon"></i>
                            <span>Delete</span>
                        </button>
                    </div>
                </div>

                <!-- Share sheet -->
                <div v-if="shareSheetOpen" class="gallery-sheet-backdrop" @click.self="shareSheetOpen = false">
                    <div class="gallery-sheet">
                        <div class="gallery-sheet-handle"></div>
                        <div class="gallery-sheet-title">Share with…</div>

                        <div v-if="CONTACTS.length" class="gallery-sheet-list">
                            <button
                                v-for="contact in CONTACTS"
                                :key="contact.number"
                                type="button"
                                class="gallery-sheet-row"
                                @click="shareToContact(contact)"
                            >
                                <div class="gallery-sheet-avatar">{{ contact.name.charAt(0).toUpperCase() }}</div>
                                <div class="gallery-sheet-contact-copy">
                                    <div class="gallery-sheet-contact-name">{{ contact.name }}</div>
                                    <div class="gallery-sheet-contact-number">{{ contact.number }}</div>
                                </div>
                                <i data-lucide="chevron-right" class="gallery-sheet-chevron"></i>
                            </button>
                        </div>

                        <div v-else class="gallery-sheet-empty">
                            Add contacts in the Phone app first.
                        </div>

                        <button type="button" class="gallery-sheet-cancel" @click="shareSheetOpen = false">Cancel</button>
                    </div>
                </div>
            </template>

        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, onMounted } = Vue;
        const { PHOTOS, CONTACTS, CONVERSATIONS, currentConversationId } = window.PhoneStore;

        const selectedPhoto = ref(null);
        const shareSheetOpen = ref(false);

        onMounted(() => hEvent("loadPhotos"));

        function onBack() {
            emit("navigate", "home");
        }

        function closeDetail() {
            selectedPhoto.value = null;
            shareSheetOpen.value = false;
        }

        function deletePhoto() {
            const idx = PHOTOS.findIndex((p) => p.id === selectedPhoto.value.id);
            if (idx === -1) return;
            hEvent("deletePhoto", { photoId: selectedPhoto.value.id });
            PHOTOS.splice(idx, 1);
            closeDetail();
        }

        function shareToContact(contact) {
            shareSheetOpen.value = false;

            let conv = CONVERSATIONS.find((c) => c.number === contact.number);
            if (!conv) {
                conv = { id: Date.now(), name: contact.name, number: contact.number, image: contact.image || "", messages: [] };
                CONVERSATIONS.unshift(conv);
            }
            const photoText = selectedPhoto.value.url || "📷 Photo";
            const timeLabel = new Date().toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true });
            conv.messages.push({ id: Date.now(), sender: "me", text: photoText, time: timeLabel });
            hEvent("sendMessage", { number: contact.number, text: photoText });
            currentConversationId.value = conv.id;

            closeDetail();
            emit("navigate", "messages");
        }

        return {
            PHOTOS,
            CONTACTS,
            selectedPhoto,
            shareSheetOpen,
            onBack,
            closeDetail,
            deletePhoto,
            shareToContact,
        };
    },
};
