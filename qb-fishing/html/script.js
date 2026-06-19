document.addEventListener("DOMContentLoaded", () => {
    const cvs = document.getElementById("water");
    const ctx = cvs.getContext("2d");
    cvs.width = 720;
    cvs.height = 180;

    let t = 0,
        phase = "idle",
        caught = 0,
        missed = 0,
        streak = 0;
    let biteTimer, reactionTimer, dotInterval;
    let currentWindow = 1000;
    let lineActive = false,
        bobberX = 0,
        biteAnim = false;
    let ripples = [];
    let dotCount = 0,
        totalDots = 0;

    const exclEl = document.getElementById("exclaim");
    const dotsEl = document.getElementById("dots");
    const statusEl = document.getElementById("status");
    const scEl = document.getElementById("sc");
    const smEl = document.getElementById("sm");
    const ssEl = document.getElementById("ss");

    function drawWater() {
        const W = 720,
            H = 180,
            wy = 72;
        ctx.clearRect(0, 0, W, H);

        ctx.fillStyle = "#b8d8ee";
        ctx.fillRect(0, 0, W, wy);

        [
            [60, 28, 36],
            [200, 18, 26],
            [390, 30, 40],
            [580, 22, 28],
        ].forEach(([cx, cy, r]) => {
            ctx.fillStyle = "#dff0f8";
            ctx.beginPath();
            ctx.ellipse(cx, cy, r, r * 0.5, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.ellipse(cx + r * 0.5, cy + 4, r * 0.6, r * 0.35, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.ellipse(cx - r * 0.4, cy + 5, r * 0.5, r * 0.32, 0, 0, Math.PI * 2);
            ctx.fill();
        });

        ctx.fillStyle = "#4a9fc4";
        ctx.fillRect(0, wy, W, H - wy);
        for (let i = 0; i < 5; i++) {
            let wx = (t * 14 + i * 140) % W;
            ctx.fillStyle = `rgba(255,255,255,${0.07 + i * 0.01})`;
            ctx.fillRect(wx, wy + 2, 55 + i * 10, 2.5);
        }
        ctx.fillStyle = "rgba(20,50,90,0.15)";
        ctx.fillRect(0, wy + 55, W, H - wy - 55);

        ctx.fillStyle = "#2e6a14";
        ctx.fillRect(0, wy - 14, 40, 16);
        [
            [6, wy - 22, 4, 14],
            [16, wy - 26, 3, 11],
            [26, wy - 20, 4, 13],
        ].forEach(([x, y, rw, rh]) => {
            ctx.fillStyle = "#3d8a1c";
            ctx.beginPath();
            ctx.ellipse(x, y, rw, rh, -0.25, 0, Math.PI * 2);
            ctx.fill();
        });

        const tip = [105, wy - 68];
        ctx.strokeStyle = "#6b4c2a";
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(24, wy - 18);
        ctx.lineTo(tip[0], tip[1]);
        ctx.stroke();

        if (lineActive) {
            let by = wy + Math.sin(t * 2.5) * 2.5 + (biteAnim ? Math.sin(t * 13) * 6 : 0);
            ctx.strokeStyle = "rgba(210,210,190,0.7)";
            ctx.lineWidth = 0.8;
            ctx.beginPath();
            ctx.moveTo(tip[0], tip[1]);
            ctx.quadraticCurveTo((tip[0] + bobberX) / 2, wy - 10, bobberX, by);
            ctx.stroke();

            ripples.forEach((r) => {
                ctx.strokeStyle = `rgba(170,210,230,${r.a})`;
                ctx.lineWidth = 0.8;
                ctx.beginPath();
                ctx.ellipse(r.x, wy, r.r, r.r * 0.28, 0, 0, Math.PI * 2);
                ctx.stroke();
            });

            let bobY = wy + Math.sin(t * 2.5) * 2 + (biteAnim ? Math.sin(t * 13) * 5 : 0);
            ctx.fillStyle = "#cc3333";
            ctx.beginPath();
            ctx.ellipse(bobberX, bobY, 5, 10, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.fillStyle = "#f0f0ec";
            ctx.beginPath();
            ctx.ellipse(bobberX, bobY - 4, 5, 6, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.strokeStyle = "rgba(100,160,190,0.35)";
            ctx.lineWidth = 0.5;
            ctx.beginPath();
            ctx.ellipse(bobberX, wy, 10, 3, 0, 0, Math.PI * 2);
            ctx.stroke();
        }

        ripples.forEach((r) => {
            r.r += 0.3;
            r.a -= 0.02;
        });
        ripples = ripples.filter((r) => r.a > 0);
        t += 0.016;
        requestAnimationFrame(drawWater);
    }
    drawWater();

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

    function startWaiting() {
        phase = "waiting";
        lineActive = true;
        biteAnim = false;
        bobberX = 420 + Math.random() * 100;
        ripples.push({ x: bobberX, r: 3, a: 0.6 });
        exclEl.className = "";
        exclEl.style.display = "none";

        // Dynamic difficulty window
        currentWindow = 950 - Math.random() * 400;
        if (streak >= 4) currentWindow *= 0.8;

        totalDots = 3 + Math.floor(Math.random() * 4);
        dotCount = 0;
        buildDots(totalDots, 0);
        setStatus("waiting for a bite…");
        let delay = 1400 + Math.random() * 2600;
        dotInterval = setInterval(() => {
            dotCount = Math.min(dotCount + 1, totalDots);
            buildDots(totalDots, dotCount);
            if (dotCount >= totalDots) clearInterval(dotInterval);
        }, delay / totalDots);
        biteTimer = setTimeout(showBite, delay);
    }

    function showBite() {
        clearInterval(dotInterval);
        buildDots(0, 0);
        biteAnim = true;
        phase = "biting";

        exclEl.style.display = "block";
        exclEl.className = "show";
        setTimeout(() => exclEl.classList.add("pulse"), 220);
        setStatus("something is biting!");
        reactionTimer = setTimeout(() => {
            if (phase === "biting") miss();
        }, currentWindow);
    }

    function reel() {
        if (phase !== "biting") return;
        clearTimeout(reactionTimer);
        phase = "done";
        biteAnim = false;
        caught++;
        streak++;
        scEl.textContent = caught;
        ssEl.textContent = streak;
        exclEl.className = "";
        exclEl.style.display = "none";
        setStatus("Caught!", "ok");
        setTimeout(() => {
            lineActive = false;
            document.body.style.display = "none";
            hEvent("fishingDone", true);
        }, 1500);
    }

    function miss() {
        phase = "done";
        biteAnim = false;
        missed++;
        streak = 0;
        smEl.textContent = missed;
        ssEl.textContent = streak;
        exclEl.className = "";
        exclEl.style.display = "none";
        setStatus("too slow — got away", "miss");
        setTimeout(() => {
            lineActive = false;
            document.body.style.display = "none";
            hEvent("fishingDone", false);
        }, 1500);
    }

    document.addEventListener("mousedown", (e) => {
        if (e.button !== 0) return;

        if (phase === "idle" || phase === "done") {
            startWaiting();
            return;
        }
        if (phase === "biting") {
            e.preventDefault();
            reel();
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
            lineActive = false;
            biteAnim = false;
            clearTimeout(reactionTimer);
            clearTimeout(biteTimer);
            clearInterval(dotInterval);
        }
    });
});
