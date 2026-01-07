document.addEventListener("DOMContentLoaded", function () {
    const config = {
        StandardEyeIcon: "fas fa-eye",
        StandardColor: "var(--md-on-surface, white)",
        SuccessColor: "var(--md-success, #386a20)",
    };

    const targetEye = document.getElementById("target-eye");
    const targetLabel = document.getElementById("target-label");
    const TargetEyeStyleObject = targetEye.style;

    function OpenTarget() {
        targetLabel.textContent = "";
        targetEye.style.display = "block";
        targetEye.className = config.StandardEyeIcon;
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
            const icon = document.createElement("i");
            icon.className = itemData.icon;
            targetIcon.appendChild(icon);
            targetIcon.appendChild(document.createTextNode(" "));
            targetOption.appendChild(targetIcon);
            
            const labelContainer = document.createElement("div");
            labelContainer.className = "target-label-container";
            const mainLabel = document.createElement("div")
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
            targetEye.className = data.icon;
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
        targetEye.className = config.StandardEyeIcon;
        targetEye.classList.remove("target-success");
    }

    function handleMouseDown(event) {
        // Left click
        if (event.button === 0) {
            const targetOption = event.target.closest('.target-option');
            if (targetOption && targetOption.id) {
                const split = targetOption.id.split("-");
                if (split[0] === "target" && split[1] !== "eye") {
                    hEvent("selectTarget", split[2]);
                    targetLabel.textContent = "";
                }
            }
        }

        // Right click
        if (event.button === 2) {
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

    window.addEventListener("unload", function () {
        window.removeEventListener("mousedown", handleMouseDown);
    });
});
