document.addEventListener("DOMContentLoaded", function () {
    let buttonParams = [];
    let images = [];
    let isMenuOpen = false;

    // ── Lucide icon helper ────────────────────────────────
    // Same pattern as qb-hud: converts kebab-case icon name
    // to inline SVG children using the Lucide UMD bundle.
    function lucideIcon(name) {
        if (!name || typeof lucide === "undefined") return "";
        const key = name.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase());
        const icon = lucide[key];
        if (!icon) {
            console.warn(`[QB Menu] Lucide icon "${name}" not found`);
            return "";
        }
        return (icon || [])
            .map(
                ([tag, attrs]) =>
                    `<${tag} ${Object.entries(attrs)
                        .map(([k, v]) => `${k}="${v}"`)
                        .join(" ")}/>`,
            )
            .join("");
    }

    function renderIcon(icon) {
        if (!icon) return "";

        // URL / image path — render as <img>
        if (icon.startsWith("http") || icon.includes("/") || icon.includes(".")) {
            return `<img src="${icon}" width="20px" onerror="this.onerror=null; this.remove();">`;
        }

        // Lucide icon name (kebab-case, e.g. "shield", "map-pin")
        const paths = lucideIcon(icon);
        if (paths) {
            return `<svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" stroke-width="1.75"
                stroke-linecap="round" stroke-linejoin="round"
                style="flex-shrink:0;">${paths}</svg>`;
        }

        return "";
    }

    function openMenu(buttons) {
        isMenuOpen = true;
        let html = "";
        buttons.forEach((item, index) => {
            if (!item.hidden) {
                let header = item.header;
                let message = item.txt || item.text;
                let isMenuHeader = item.isMenuHeader;
                let isDisabled = item.disabled;
                let icon = item.icon;
                images[index] = item;
                html += getButtonRender(header, message, index, isMenuHeader, isDisabled, icon);
                if (item.params) buttonParams[index] = item.params;
            }
        });
        $("#buttons").html(html);
        $(".button").click(function () {
            const target = $(this);
            if (!target.hasClass("title") && !target.hasClass("disabled")) {
                postData(target.attr("id"));
            }
        });
    }

    function getButtonRender(header, message = null, id, isMenuHeader, isDisabled, icon) {
        return `
            <div class="${isMenuHeader ? "title" : "button"} ${isDisabled ? "disabled" : ""}" id="${id}">
                <div class="icon">${renderIcon(icon)}</div>
                <div class="column">
                    <div class="header">${header}</div>
                    ${message ? `<div class="text">${message}</div>` : ""}
                </div>
            </div>
        `;
    }

    function closeMenu() {
        $("#buttons").html(" ");
        $("#imageHover").css("display", "none");
        buttonParams = [];
        images = [];
        isMenuOpen = false;
    }

    function postData(id) {
        hEvent("clickedButton", JSON.stringify(parseInt(id) + 1));
        return closeMenu();
    }

    function cancelMenu() {
        hEvent("closeMenu");
        return closeMenu();
    }

    window.addEventListener("message", (event) => {
        const data = event.data;
        switch (data.name) {
            case "openMenu":
                return openMenu(data.args[0]);
            case "closeMenu":
                return closeMenu();
            default:
                return;
        }
    });

    function handleKeydown(event) {
        if (event.key === "Escape") {
            if (isMenuOpen) {
                event.preventDefault();
                cancelMenu();
            }
        }
    }

    window.addEventListener("keydown", handleKeydown);

    window.addEventListener("unload", function () {
        window.removeEventListener("keydown", handleKeydown);
    });
});
