const defaultConfig = {
    position: "top-right",
    maxVisible: 5,
};

const VariantDefinitions = {
    // ── Core ──────────────────────────────────────────────
    success: {
        icon: "check-circle",
        accent: "#00FA7B",
    },
    error: {
        icon: "x-circle",
        accent: "#E5484D",
    },
    primary: {
        icon: "info",
        accent: "#0090ff",
    },
    warning: {
        icon: "triangle-alert",
        accent: "#FA9600",
    },

    // ── Emergency services ────────────────────────────────
    police: {
        icon: "shield-alert",
        accent: "#378ADD",
    },
    ambulance: {
        icon: "truck-medical",
        accent: "#E24B4A",
    },
    fire: {
        icon: "flame",
        accent: "#D85A30",
    },

    // ── Game-specific ─────────────────────────────────────
    quest: {
        icon: "scroll-text",
        accent: "#9F7AEA",
    },
    levelup: {
        icon: "trending-up",
        accent: "#F6C90E",
    },
    loot: {
        icon: "gem",
        accent: "#5DCAA5",
    },
    death: {
        icon: "skull",
        accent: "#888780",
    },
    wanted: {
        icon: "crosshair",
        accent: "#E24B4A",
    },
    achievement: {
        icon: "trophy",
        accent: "#EF9F27",
    },
    arrest: {
        icon: "handcuffs",
        accent: "#378ADD",
    },
    cash: {
        icon: "banknote",
        accent: "#1D9E75",
    },
    bank: {
        icon: "landmark",
        accent: "#9F7AEA",
    },
    vehicle: {
        icon: "car",
        accent: "#5DCAA5",
    },
};

// ── Container ────────────────────────────────────────────

function getContainer() {
    let el = document.getElementById("notif-container");
    if (!el) {
        el = document.createElement("div");
        el.id = "notif-container";
        el.setAttribute("data-position", defaultConfig.position);
        document.body.appendChild(el);
    }
    return el;
}

// ── Icon via Lucide ──────────────────────────────────────

function makeSVG(iconName) {
    // Lucide UMD structure: lucide[PascalName] = [defaultAttrs, children]
    const key = iconName.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase());
    const iconData = lucide[key];

    if (!iconData) return null;

    const svgNS = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(svgNS, "svg");
    svg.setAttribute("xmlns", svgNS);
    svg.setAttribute("width", "18");
    svg.setAttribute("height", "18");
    svg.setAttribute("viewBox", "0 0 24 24");
    svg.setAttribute("fill", "none");
    svg.setAttribute("stroke", "currentColor");
    svg.setAttribute("stroke-width", "2");
    svg.setAttribute("stroke-linecap", "round");
    svg.setAttribute("stroke-linejoin", "round");

    // In the local UMD version, iconData IS the children array
    (iconData || []).forEach(([childTag, childAttrs]) => {
        const child = document.createElementNS(svgNS, childTag);
        Object.entries(childAttrs || {}).forEach(([k, v]) => child.setAttribute(k, v));
        svg.appendChild(child);
    });

    return svg;
}

// ── Show notification ────────────────────────────────────

function showNotif(data) {
    const { text, length = 4000, type = "primary", caption, icon: customIcon } = data;
    const variant = VariantDefinitions[type] ?? VariantDefinitions.primary;
    const iconName = customIcon ?? variant.icon;
    const accent = variant.accent;

    const container = getContainer();

    // Prune oldest if over limit
    const existing = container.querySelectorAll(".notif");
    if (existing.length >= defaultConfig.maxVisible) {
        dismiss(existing[0]);
    }

    const notif = document.createElement("div");
    notif.className = "notif";
    notif.style.setProperty("--accent", accent);
    notif.style.setProperty("--dur", `${length}ms`);

    const iconWrap = document.createElement("div");
    iconWrap.className = "notif-icon";
    const svg = makeSVG(iconName);
    if (svg) iconWrap.appendChild(svg);

    const body = document.createElement("div");
    body.className = "notif-body";

    const title = document.createElement("span");
    title.className = "notif-title";
    title.textContent = text;
    body.appendChild(title);

    if (caption) {
        const cap = document.createElement("span");
        cap.className = "notif-caption";
        cap.textContent = caption;
        body.appendChild(cap);
    }

    const bar = document.createElement("div");
    bar.className = "notif-bar";
    const barFill = document.createElement("div");
    barFill.className = "notif-bar-fill";
    bar.appendChild(barFill);
    body.appendChild(bar);

    notif.appendChild(iconWrap);
    notif.appendChild(body);
    container.appendChild(notif);

    // Trigger enter animation on next frame
    requestAnimationFrame(() => {
        requestAnimationFrame(() => notif.classList.add("visible"));
    });

    setTimeout(() => dismiss(notif), length);
}

function dismiss(notif) {
    if (!notif || notif.classList.contains("leaving")) return;
    notif.classList.add("leaving");
    notif.addEventListener("transitionend", () => notif.remove(), { once: true });
}

// ── Event bridge ─────────────────────────────────────────

window.showNotif = showNotif;

window.addEventListener("message", function (event) {
    switch (event.data.name) {
        case "showNotif":
            showNotif(...event.data.args);
            break;
        case "drawText":
            drawText(...event.data.args);
            break;
        case "hideText":
            hideText();
            break;
        case "changeText":
            changeText(...event.data.args);
            break;
        case "keyPressed":
            keyPressed();
            break;
    }
});
