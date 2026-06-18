document.addEventListener("DOMContentLoaded", function () {
    const config = {
        StandardEyeIcon: "eye",
        StandardColor: "var(--md-on-surface, white)",
        SuccessColor: "var(--md-success, #386a20)",
    };

    const targetEye = document.getElementById("target-eye");
    const targetLabel = document.getElementById("target-label");
    const TargetEyeStyleObject = targetEye.style;

    // ── Lucide icon helper ────────────────────────────────
    function lucideIcon(name) {
        if (!name || typeof lucide === "undefined") return "";
        const key = name.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase());
        const icon = lucide[key];
        if (!icon) {
            console.warn(`[Target] Lucide icon "${name}" not found`);
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

    function makeSVG(name, extraStyle = "") {
        const paths = lucideIcon(name);
        if (!paths) return "";
        return `<svg width="14" height="14" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="1.75"
            stroke-linecap="round" stroke-linejoin="round"
            style="flex-shrink:0;${extraStyle}">${paths}</svg>`;
    }

    function setEyeIcon(iconName) {
        targetEye.innerHTML = makeSVG(iconName, "width:1em;height:1em;");
    }

    function OpenTarget() {
        targetLabel.textContent = "";
        targetEye.style.display = "block";
        targetEye.classList.remove("target-success");
        setEyeIcon(config.StandardEyeIcon);
        TargetEyeStyleObject.color = config.StandardColor;
    }

    function CloseTarget() {
        targetLabel.textContent = "";
        targetEye.style.display = "none";
    }

    function createTargetOption(index, itemData) {
        if (itemData !== null) {
            index = Number(index) + 1;
            const targetOption = document.createElement("div");
            targetOption.id = `target-option-${index}`;
            targetOption.className = "target-option";

            const targetIcon = document.createElement("span");
            targetIcon.id = `target-icon-${index}`;
            targetIcon.className = "target-option-icon";
            targetIcon.innerHTML = makeSVG(itemData.icon);
            targetOption.appendChild(targetIcon);

            const labelContainer = document.createElement("div");
            labelContainer.className = "target-label-container";

            const mainLabel = document.createElement("div");
            mainLabel.textContent = itemData.label;
            labelContainer.appendChild(mainLabel);

            if (itemData.subLabel) {
                const subLabel = document.createElement("div");
                subLabel.className = "target-sublabel";
                subLabel.textContent = itemData.subLabel;
                labelContainer.appendChild(subLabel);
            }

            targetOption.appendChild(labelContainer);
            targetLabel.appendChild(targetOption);
        }
    }

    function FoundTarget(data) {
        if (!data) return;
        if (data.icon) {
            setEyeIcon(data.icon);
        }
        TargetEyeStyleObject.color = config.SuccessColor;
        targetEye.classList.add("target-success");
        targetLabel.textContent = "";
        for (let [index, itemData] of data.options.entries()) {
            createTargetOption(index, itemData);
        }
    }

    function LeftTarget() {
        targetLabel.textContent = "";
        TargetEyeStyleObject.color = config.StandardColor;
        setEyeIcon(config.StandardEyeIcon);
        targetEye.classList.remove("target-success");
    }

    function handleMouseDown(event) {
        // Left click
        if (event.button === 0) {
            const targetOption = event.target.closest(".target-option");
            if (targetOption && targetOption.id) {
                const split = targetOption.id.split("-");
                if (split[0] === "target" && split[1] !== "eye") {
                    hEvent("selectTarget", split[2]);
                    targetLabel.textContent = "";
                }
            }
        }
    }

    function handleKeydown(event) {
        if (event.key === "Escape") {
            event.preventDefault();
            hEvent("closeTarget");
        }
    }

    window.addEventListener("message", function (event) {
        switch (event.data.name) {
            case "openTarget":
                OpenTarget();
                break;
            case "closeTarget":
                CloseTarget();
                break;
            case "foundTarget":
                FoundTarget(event.data.args[0]);
                break;
            case "leftTarget":
                LeftTarget();
                break;
        }
    });

    window.addEventListener("mousedown", handleMouseDown);
    window.addEventListener("keydown", handleKeydown);

    window.addEventListener("unload", function () {
        window.removeEventListener("mousedown", handleMouseDown);
        window.removeEventListener("keydown", handleKeydown);
    });
});
