const PHONE_TABS = ["history", "keypad", "contacts"];
const KEYPAD_KEYS = [
    { value: "1", letters: "" },
    { value: "2", letters: "ABC" },
    { value: "3", letters: "DEF" },
    { value: "4", letters: "GHI" },
    { value: "5", letters: "JKL" },
    { value: "6", letters: "MNO" },
    { value: "7", letters: "PQRS" },
    { value: "8", letters: "TUV" },
    { value: "9", letters: "WXYZ" },
    { value: "*", letters: "" },
    { value: "0", letters: "+" },
    { value: "#", letters: "" },
];

const PhoneApp = {
    template: `
        <div class="phone-app-screen">
            <div class="phone-app-top">
                <div class="phone-app-top-row">
                    <button type="button" aria-label="Back to home" class="phone-nav-button" @click="onBack">
                        <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                    </button>
                    <div class="phone-app-top-copy">
                        <div class="phone-nav-eyebrow">Phone</div>
                        <div class="phone-nav-title">{{ getPhoneTabLabel(currentPhoneTab) }}</div>
                    </div>
                </div>
            </div>

            <div class="phone-app-body">
                <template v-if="currentPhoneTab === 'history'">
                    <div v-if="CALL_HISTORY.length" class="phone-list">
                        <div v-for="entry in CALL_HISTORY" :key="entry.number + entry.time" class="phone-list-row">
                            <div class="phone-list-avatar">{{ entry.name.charAt(0).toUpperCase() }}</div>
                            <div class="phone-list-copy">
                                <div :class="['phone-list-title', entry.missed ? 'phone-list-title-missed' : '']">{{ entry.name }}</div>
                                <div class="phone-list-subtitle">
                                    <i :data-lucide="getCallTypeIcon(entry.type)" :class="getCallTypeClass(entry.type, entry.missed)"></i>
                                    <span>{{ entry.number }}</span>
                                </div>
                            </div>
                            <div class="phone-list-meta">{{ entry.time }}</div>
                        </div>
                    </div>
                    <div v-else class="phone-empty-state">No calls yet. Use the keypad or a contact to place one.</div>
                </template>

                <template v-else-if="currentPhoneTab === 'keypad'">
                    <div class="phone-keypad-screen">
                        <div class="phone-dial-display-wrap">
                            <div class="phone-dial-label">Enter number</div>
                            <div class="phone-dial-display">{{ dialedNumber || '—' }}</div>
                        </div>
                        <div class="phone-keypad-grid">
                            <button v-for="key in KEYPAD_KEYS" :key="key.value" type="button" class="phone-key" @click="pressKey(key.value)">
                                <span class="phone-key-value">{{ key.value }}</span>
                                <span class="phone-key-letters">{{ key.letters }}</span>
                            </button>
                        </div>
                        <div class="phone-keypad-actions">
                            <button type="button" class="phone-secondary-action" @click="clearKey">
                                <i data-lucide="delete" class="phone-secondary-action-icon"></i>
                            </button>
                            <button type="button" class="phone-call-button" @click="placeCall">
                                <i data-lucide="phone" class="phone-call-button-icon"></i>
                            </button>
                        </div>
                    </div>
                </template>

                <template v-else>
                    <div class="phone-contacts-screen">
                        <div class="phone-contacts-header">
                            <div class="phone-contacts-copy">
                                <div class="phone-contacts-title">Contacts</div>
                                <div class="phone-contacts-subtitle">{{ CONTACTS.length ? CONTACTS.length + ' saved' : 'No contacts yet' }}</div>
                            </div>
                            <button type="button" aria-label="Add contact" class="phone-add-contact-button" @click="openNewContactForm">
                                <i data-lucide="plus" class="phone-add-contact-icon"></i>
                            </button>
                        </div>

                        <div v-if="showContactForm" class="phone-form-card">
                            <div class="phone-form-title">{{ getContactFormTitle() }}</div>
                            <input v-model="contactForm.name" placeholder="Contact name" class="phone-input" />
                            <input v-model="contactForm.number" placeholder="Phone number" class="phone-input" />
                            <input v-model="contactForm.image" placeholder="Picture URL (optional)" class="phone-input" />
                            <div class="phone-form-actions">
                                <button type="button" class="phone-form-button phone-form-button-secondary" @click="cancelContactForm">Cancel</button>
                                <button type="button" class="phone-form-button phone-form-button-primary" @click="saveContact">Save</button>
                            </div>
                        </div>

                        <div v-if="CONTACTS.length" class="phone-list">
                            <div v-for="(contact, index) in CONTACTS" :key="contact.number" class="phone-list-row">
                                <div v-if="contact.image" class="phone-list-avatar phone-list-avatar-image">
                                    <img :src="contact.image" :alt="contact.name" class="phone-avatar-image" @error="e => { e.target.style.display='none'; e.target.parentElement.textContent = contact.name.charAt(0).toUpperCase(); }" />
                                </div>
                                <div v-else class="phone-list-avatar">{{ contact.name.charAt(0).toUpperCase() }}</div>
                                <div class="phone-list-copy">
                                    <div class="phone-list-title">{{ contact.name }}</div>
                                    <div class="phone-list-subtitle phone-list-subtitle-plain">{{ contact.number }}</div>
                                </div>
                                <div class="phone-contact-actions">
                                    <button type="button" class="phone-contact-action phone-contact-message-action" :aria-label="'Message ' + contact.name" @click="openConversationFromContact(contact)">
                                        <i data-lucide="message-circle" class="phone-contact-action-icon"></i>
                                    </button>
                                    <button type="button" class="phone-contact-action" :aria-label="'Call ' + contact.name" @click="callContact(index)">
                                        <i data-lucide="phone" class="phone-contact-action-icon"></i>
                                    </button>
                                    <button type="button" class="phone-contact-action phone-contact-edit-action" :aria-label="'Edit ' + contact.name" @click="openEditContactForm(index)">
                                        <i data-lucide="pencil" class="phone-contact-action-icon"></i>
                                    </button>
                                    <button type="button" class="phone-contact-action phone-contact-delete-action" :aria-label="'Delete ' + contact.name" @click="deleteContact(index)">
                                        <i data-lucide="trash-2" class="phone-contact-action-icon"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div v-else-if="!showContactForm" class="phone-empty-state">No contacts yet. Tap the plus button to add one.</div>
                    </div>
                </template>
            </div>

            <div class="phone-tab-bar">
                <button v-for="tab in PHONE_TABS" :key="tab" type="button" :class="['phone-tab-button', currentPhoneTab === tab ? 'phone-tab-button-active' : '']" @click="switchPhoneTab(tab)">
                    <i :data-lucide="getPhoneTabIcon(tab)" class="phone-tab-icon"></i>
                    <span>{{ getPhoneTabLabel(tab) }}</span>
                </button>
            </div>
        </div>
    `,

    emits: ["navigate", "dial"],

    setup(props, { emit }) {
        const { ref, reactive } = Vue;
        const { CONTACTS, CALL_HISTORY, CONVERSATIONS, currentConversationId } = window.PhoneStore;

        const currentPhoneTab = ref("history");
        const dialedNumber = ref("");
        const showContactForm = ref(false);
        const editingContactIndex = ref(null);
        const contactForm = reactive({ name: "", number: "", image: "" });

        function getPhoneTabLabel(tab) {
            if (tab === "history") return "Recents";
            if (tab === "keypad") return "Keypad";
            return "Contacts";
        }

        function getPhoneTabIcon(tab) {
            if (tab === "history") return "history";
            if (tab === "keypad") return "grid-3x3";
            return "users";
        }

        function getCallTypeIcon(type) {
            if (type === "incoming") return "phone-incoming";
            if (type === "outgoing") return "phone-outgoing";
            return "phone-missed";
        }

        function getCallTypeClass(type, missed) {
            return missed || type === "missed" ? "phone-call-type phone-call-type-missed" : "phone-call-type";
        }

        function getContactFormTitle() {
            return editingContactIndex.value === null ? "New contact" : "Edit contact";
        }

        function pressKey(key) {
            dialedNumber.value += key;
        }
        function clearKey() {
            dialedNumber.value = dialedNumber.value.slice(0, -1);
        }

        function placeCall() {
            if (!dialedNumber.value) return;
            const contact = CONTACTS.find((c) => c.number === dialedNumber.value);
            emit("dial", { name: contact ? contact.name : dialedNumber.value, number: dialedNumber.value });
            hEvent("dial", { number: dialedNumber.value });
            dialedNumber.value = "";
        }

        function callContact(index) {
            const contact = CONTACTS[index];
            if (!contact) return;
            emit("dial", { name: contact.name, number: contact.number });
            hEvent("dial", { number: contact.number });
        }

        function openConversationFromContact(contact) {
            if (!contact?.name || !contact?.number) return;
            let conv = CONVERSATIONS.find((c) => c.number === contact.number);
            if (!conv) {
                conv = { id: Date.now(), name: contact.name, number: contact.number, image: contact.image || "", messages: [] };
                CONVERSATIONS.unshift(conv);
            } else {
                conv.name = contact.name;
                conv.image = contact.image || "";
            }
            currentConversationId.value = conv.id;
            emit("navigate", "messages");
        }

        function switchPhoneTab(tab) {
            currentPhoneTab.value = tab;
            showContactForm.value = false;
            resetContactForm();
        }

        function resetContactForm() {
            contactForm.name = "";
            contactForm.number = "";
            contactForm.image = "";
            editingContactIndex.value = null;
        }

        function cancelContactForm() {
            resetContactForm();
            showContactForm.value = false;
        }

        function openNewContactForm() {
            resetContactForm();
            showContactForm.value = true;
        }

        function openEditContactForm(index) {
            const contact = CONTACTS[index];
            if (!contact) return;
            contactForm.name = contact.name || "";
            contactForm.number = contact.number || "";
            contactForm.image = contact.image || "";
            editingContactIndex.value = index;
            showContactForm.value = true;
        }

        function saveContact() {
            if (!contactForm.name.trim() || !contactForm.number.trim()) return;
            const next = { name: contactForm.name.trim(), number: contactForm.number.trim(), image: contactForm.image.trim() };
            if (editingContactIndex.value === null) {
                CONTACTS.unshift(next);
            } else {
                CONTACTS[editingContactIndex.value] = next;
            }
            hEvent("saveContact", next);
            resetContactForm();
            showContactForm.value = false;
        }

        function deleteContact(index) {
            const contact = CONTACTS[index];
            if (!contact) return;
            hEvent("deleteContact", { number: contact.number });
            CONTACTS.splice(index, 1);
        }

        function onBack() {
            cancelContactForm();
            emit("navigate", "home");
        }

        return {
            CONTACTS,
            CALL_HISTORY,
            PHONE_TABS,
            KEYPAD_KEYS,
            currentPhoneTab,
            dialedNumber,
            showContactForm,
            contactForm,
            getPhoneTabLabel,
            getPhoneTabIcon,
            getCallTypeIcon,
            getCallTypeClass,
            getContactFormTitle,
            pressKey,
            clearKey,
            placeCall,
            callContact,
            switchPhoneTab,
            openNewContactForm,
            openEditContactForm,
            cancelContactForm,
            saveContact,
            deleteContact,
            openConversationFromContact,
            onBack,
        };
    },
};
