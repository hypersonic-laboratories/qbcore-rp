const CAMERA_ZOOM_LEVELS = [
    { label: "0.6×", value: 0.6 },
    { label: "1×", value: 1 },
    { label: "2×", value: 2 },
    { label: "5×", value: 5 },
];


const CameraApp = {
    template: `
        <div class="camera-screen">

            <!-- flash overlay -->
            <div class="camera-flash" :class="{ flashing: isFlashing }"></div>

            <!-- top bar -->
            <div class="camera-top-bar">
                <button type="button" class="camera-top-btn" aria-label="Back" @click="emit('navigate', 'home')">
                    <i data-lucide="arrow-left" class="camera-top-icon"></i>
                </button>
                <button type="button" class="camera-top-btn" aria-label="Toggle flash" @click="cycleFlash">
                    <i :data-lucide="flashIcon" class="camera-top-icon"></i>
                </button>
            </div>

            <!-- viewfinder -->
            <div class="camera-viewfinder">
                <div class="camera-grid">
                    <div class="camera-grid-cell" v-for="n in 9" :key="n"></div>
                </div>
            </div>

            <!-- bottom panel -->
            <div class="camera-bottom">

                <!-- zoom pills -->
                <div class="camera-zoom-row">
                    <button
                        v-for="z in CAMERA_ZOOM_LEVELS"
                        :key="z.value"
                        type="button"
                        :class="['camera-zoom-btn', activeZoom === z.value ? 'active' : '']"
                        @click="activeZoom = z.value"
                    >{{ z.label }}</button>
                </div>

                <!-- gallery | shutter | flip -->
                <div class="camera-controls-row">
                    <button type="button" class="camera-gallery-thumb" aria-label="Gallery" @click="emit('navigate', 'photos')">
                        <i v-if="!lastPhoto" data-lucide="image" class="camera-gallery-icon"></i>
                        <div v-else class="camera-gallery-captured" :style="{ background: lastPhoto }"></div>
                    </button>

                    <button type="button" :class="['camera-shutter', isCapturing ? 'camera-shutter--busy' : '']" :disabled="isCapturing" aria-label="Take photo" @click="takePhoto">
                        <div class="camera-shutter-inner"></div>
                    </button>

                    <button type="button" class="camera-flip-btn" aria-label="Flip camera" @click="isFront = !isFront">
                        <i data-lucide="switch-camera" class="camera-flip-icon"></i>
                    </button>
                </div>


            </div>
        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, computed, onMounted, onUnmounted, watch } = Vue;
        const { PHOTOS } = window.PhoneStore;

        const activeZoom = ref(1);
        const isFront = ref(false);
        const isFlashing = ref(false);
        const isCapturing = ref(false);
        const flashMode = ref("auto"); // off | auto | on

        const lastPhoto = computed(() => PHOTOS[0]?.gradient ?? null);

        const flashIcon = computed(() => {
            if (flashMode.value === "off") return "zap-off";
            return "zap";
        });

        function cycleFlash() {
            const order = ["auto", "on", "off"];
            const idx = order.indexOf(flashMode.value);
            flashMode.value = order[(idx + 1) % order.length];
        }

        function takePhoto() {
            if (isCapturing.value || isFlashing.value) return;
            isCapturing.value = true;
            hEvent("takePhoto", { facing: isFront.value ? "front" : "rear" });
        }

        function photoUploaded(url) {
            hEvent("photoUploaded", { url: url || "" });
        }

        // Notify Lua when the user flips between front/rear
        watch(isFront, (front) => {
            hEvent("cameraFlipped", { facing: front ? "front" : "rear" });
        });

        watch(activeZoom, (zoom) => {
            hEvent("cameraZoom", { zoom });
        });

        function onMessage(e) {
            const name = e.data?.name;
            if (name === "photoTaken") {
                isCapturing.value = false;
                isFlashing.value = true;
                setTimeout(() => {
                    isFlashing.value = false;
                }, 140);
            } else if (name === "photoFailed") {
                isCapturing.value = false;
            }
        }

        onMounted(() => {
            window.addEventListener("message", onMessage);
            window.photoUploaded = photoUploaded;
            hEvent("cameraOpened", { facing: isFront.value ? "front" : "rear" });
        });

        onUnmounted(() => {
            window.removeEventListener("message", onMessage);
            if (window.photoUploaded === photoUploaded) delete window.photoUploaded;
            hEvent("cameraClosed", {});
        });

        return {
            CAMERA_ZOOM_LEVELS,
            activeZoom,
            isFront,
            isFlashing,
            isCapturing,
            flashMode,
            lastPhoto,
            flashIcon,
            cycleFlash,
            takePhoto,
            emit,
        };
    },
};
