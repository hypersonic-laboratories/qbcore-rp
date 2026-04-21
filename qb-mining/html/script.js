document.addEventListener("DOMContentLoaded", () => {
    const cvs = document.getElementById("scene-canvas");
    const ctx = cvs.getContext("2d");
    cvs.width = 720;
    cvs.height = 180;

    let t = 0,
        phase = "idle",
        mined = 0,
        missed = 0,
        streak = 0;
    let biteTimer, reactionTimer, dotInterval;
    let currentWindow = 1000;
    let dotCount = 0,
        totalDots = 0;
    let swingT = -1,
        shakeT = 0,
        chips = [];
    let strikeFlash = 0;
    let glintT = 0,
        glintActive = false;

    const exclEl = document.getElementById("exclaim");
    const dotsEl = document.getElementById("dots");
    const statusEl = document.getElementById("status");
    const scEl = document.getElementById("sc");
    const smEl = document.getElementById("sm");
    const ssEl = document.getElementById("ss");

    function drawScene() {
        const W = 720,
            H = 180;
        ctx.clearRect(0, 0, W, H);

        ctx.fillStyle = "#2a2420";
        ctx.fillRect(0, 0, W, H);

        const patches = [
            [80, 40, 55, 30],
            [200, 20, 40, 25],
            [350, 50, 60, 28],
            [520, 30, 45, 22],
            [640, 55, 50, 30],
            [150, 120, 70, 35],
            [400, 130, 55, 28],
            [580, 115, 65, 32],
        ];
        patches.forEach(([px, py, pw, ph]) => {
            ctx.fillStyle = "rgba(255,255,255,0.03)";
            ctx.beginPath();
            ctx.ellipse(px, py, pw, ph, 0, 0, Math.PI * 2);
            ctx.fill();
        });

        ctx.fillStyle = "#3a322c";
        ctx.fillRect(0, H * 0.72, W, H - H * 0.72);

        ctx.strokeStyle = "rgba(0,0,0,0.4)";
        ctx.lineWidth = 1;
        [
            [100, H * 0.72, 130, H * 0.82],
            [300, H * 0.72, 280, H * 0.85],
            [500, H * 0.72, 520, H * 0.8],
        ].forEach(([x1, y1, x2, y2]) => {
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.stroke();
        });

        ctx.fillStyle = "rgba(200,120,30,0.07)";
        ctx.beginPath();
        ctx.ellipse(0, H * 0.5, 80, 80, 0, 0, Math.PI * 2);
        ctx.fill();

        const rx = 360,
            ry = H * 0.62,
            rockColor = "#8a8070";
        let shakeOff = shakeT > 0 ? Math.sin(shakeT * 40) * 3 * (shakeT / 0.25) : 0;
        shakeT = Math.max(0, shakeT - 0.016);

        ctx.save();
        ctx.translate(rx + shakeOff, ry);

        ctx.fillStyle = "rgba(0,0,0,0.3)";
        ctx.beginPath();
        ctx.ellipse(0, 32, 52, 10, 0, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = rockColor;
        ctx.beginPath();
        ctx.moveTo(-48, 12);
        ctx.bezierCurveTo(-55, -10, -40, -38, -10, -42);
        ctx.bezierCurveTo(10, -48, 35, -40, 48, -18);
        ctx.bezierCurveTo(58, 2, 50, 22, 32, 30);
        ctx.bezierCurveTo(10, 38, -30, 36, -48, 12);
        ctx.closePath();
        ctx.fill();

        ctx.fillStyle = "rgba(255,255,255,0.08)";
        ctx.beginPath();
        ctx.moveTo(-30, -20);
        ctx.bezierCurveTo(-28, -35, -5, -40, 10, -35);
        ctx.bezierCurveTo(20, -30, 22, -18, 14, -15);
        ctx.bezierCurveTo(0, -10, -28, -8, -30, -20);
        ctx.closePath();
        ctx.fill();

        ctx.strokeStyle = "rgba(0,0,0,0.25)";
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(-10, -10);
        ctx.lineTo(5, 8);
        ctx.lineTo(20, 2);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(-25, 5);
        ctx.lineTo(-15, 18);
        ctx.stroke();

        if (phase !== "idle") {
            ctx.fillStyle = "#c47a3a";
            ctx.globalAlpha = 0.75;
            ctx.beginPath();
            ctx.ellipse(8, -5, 14, 8, -0.4, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.ellipse(-18, 10, 8, 5, 0.3, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 1;

            if (glintActive) {
                let g = Math.abs(Math.sin(glintT * 6));
                ctx.fillStyle = `rgba(255,255,255,${g * 0.7})`;
                ctx.beginPath();
                ctx.ellipse(8, -5, 5, 3, -0.4, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        ctx.restore();

        if (strikeFlash > 0) {
            ctx.fillStyle = `rgba(255,240,180,${strikeFlash * 0.18})`;
            ctx.fillRect(0, 0, W, H);
            strikeFlash -= 0.08;
        }

        chips.forEach((c) => {
            let p = 1 - c.life;
            ctx.fillStyle = c.color;
            ctx.globalAlpha = c.life;
            ctx.beginPath();
            ctx.ellipse(c.x + c.vx * p * 30, c.y + c.vy * p * 30 + p * p * 20, c.r * c.life, c.r * c.life, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 1;
            c.life -= 0.035;
        });
        chips = chips.filter((c) => c.life > 0);

        const pivX = 200,
            pivY = H * 0.3;
        let angle = -0.6;
        if (swingT >= 0) {
            let p = swingT / 0.35;
            angle = -0.6 + Math.sin(p * Math.PI) * 1.6;
            swingT -= 0.016;
            if (swingT < 0) swingT = -1;
        }

        ctx.save();
        ctx.translate(pivX, pivY);
        ctx.rotate(angle);

        ctx.strokeStyle = "#8B6330";
        ctx.lineWidth = 7;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(110, 60);
        ctx.stroke();
        ctx.strokeStyle = "#a07840";
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(110, 60);
        ctx.stroke();

        ctx.fillStyle = "#888";
        ctx.beginPath();
        ctx.moveTo(105, 55);
        ctx.lineTo(130, 38);
        ctx.lineTo(138, 48);
        ctx.lineTo(118, 72);
        ctx.closePath();
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(105, 55);
        ctx.lineTo(82, 72);
        ctx.lineTo(75, 62);
        ctx.lineTo(98, 46);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = "#aaa";
        ctx.beginPath();
        ctx.moveTo(108, 52);
        ctx.lineTo(128, 40);
        ctx.lineTo(132, 46);
        ctx.lineTo(112, 58);
        ctx.closePath();
        ctx.fill();

        ctx.restore();

        glintT += 0.016;
        t += 0.016;
        requestAnimationFrame(drawScene);
    }
    drawScene();

    function spawnChips(x, y, color) {
        for (let i = 0; i < 7; i++) {
            chips.push({
                x,
                y,
                vx: (Math.random() - 0.5) * 2,
                vy: -Math.random() * 1.5 - 0.5,
                r: 2 + Math.random() * 3,
                color,
                life: 0.8 + Math.random() * 0.2,
            });
        }
    }

    function buildDots(n, lit) {
        dotsEl.innerHTML = "";
        for (let i = 0; i < n; i++) {
            let d = document.createElement("div");
            d.className = "dot" + (i < lit ? " lit" : "");
            dotsEl.appendChild(d);
        }
    }

    function setStatus(txt, cls = "") {
        statusEl.textContent = txt;
        statusEl.className = cls;
    }

    function startMining() {
        phase = "mining";
        glintActive = false;
        exclEl.className = "";
        exclEl.style.display = "none";

        currentWindow = 950 - Math.random() * 400;
        if (streak >= 4) currentWindow *= 0.8;

        totalDots = 3 + Math.floor(Math.random() * 4);
        dotCount = 0;
        buildDots(totalDots, 0);
        setStatus("chipping away…");

        let delay = 1400 + Math.random() * 2400;
        let swingInterval = delay / totalDots;

        dotInterval = setInterval(() => {
            swingT = 0.35;
            shakeT = 0.15;
            spawnChips(360 + (Math.random() - 0.5) * 40, cvs.height * 0.62 - 5, "#b0a090");
            dotCount = Math.min(dotCount + 1, totalDots);
            buildDots(totalDots, dotCount);
            if (dotCount >= totalDots) clearInterval(dotInterval);
        }, swingInterval);

        biteTimer = setTimeout(showStrike, delay);
    }

    function showStrike() {
        clearInterval(dotInterval);
        buildDots(0, 0);
        glintActive = true;
        glintT = 0;
        phase = "striking";
        exclEl.style.display = "block";
        exclEl.className = "show";
        setTimeout(() => exclEl.classList.add("pulse"), 220);
        setStatus("ore exposed — strike now!");
        reactionTimer = setTimeout(() => {
            if (phase === "striking") crumble();
        }, currentWindow);
    }

    function strike() {
        if (phase !== "striking") return;
        clearTimeout(reactionTimer);
        phase = "done";
        glintActive = false;
        mined++;
        streak++;
        scEl.textContent = mined;
        ssEl.textContent = streak;
        swingT = 0.35;
        shakeT = 0.25;
        strikeFlash = 1;
        spawnChips(360, cvs.height * 0.62 - 5, "#e8a060");
        spawnChips(360, cvs.height * 0.62 - 5, "#e0d0b0");
        exclEl.className = "";
        exclEl.style.display = "none";
        setStatus("Collected!", "ok");
        setTimeout(() => {
            document.body.style.display = "none";
            hEvent("miningDone", true);
        }, 1500);
    }

    function crumble() {
        phase = "done";
        glintActive = false;
        missed++;
        streak = 0;
        smEl.textContent = missed;
        ssEl.textContent = streak;
        exclEl.className = "";
        exclEl.style.display = "none";
        setStatus("ore crumbled — too slow", "miss");
        setTimeout(() => {
            document.body.style.display = "none";
            hEvent("miningDone", false);
        }, 1500);
    }

    document.addEventListener("mousedown", (e) => {
        if (e.button !== 0) return;

        if (phase === "idle" || phase === "done") {
            startMining();
            return;
        }
        if (phase === "striking") {
            e.preventDefault();
            strike();
            return;
        }
    });

    window.addEventListener("message", function (event) {
        if (event.data.name === "openUI") {
            document.body.style.display = "flex";
            phase = "idle";
            exclEl.style.display = "none";
            dotsEl.innerHTML = "";
            setStatus("click anywhere to begin");
            glintActive = false;
            clearTimeout(reactionTimer);
            clearTimeout(biteTimer);
            clearInterval(dotInterval);
        }
    });
});

