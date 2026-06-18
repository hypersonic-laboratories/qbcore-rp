const { createApp } = Vue;
const VueSelectComponent = window["vue-select"] && (window["vue-select"].VueSelect || window["vue-select"]);

const app = createApp({
    components: {
        "v-select": VueSelectComponent,
    },

    data() {
        return {
            isVisible: false,
            currentPage: "dashboard",
            pages: ["dashboard", "reports", "players", "chat", "logs", "environment", "developer", "items", "vehicles", "jobs", "gangs", "leaderboard"],

            // Dashboard
            stats: [],
            dashboardConfig: {
                quickActions: [
                    { id: "noclip", label: "Noclip" },
                    { id: "god-mode", label: "God Mode" },
                    { id: "invisibility", label: "Invisibility" },
                    { id: "admin-duty", label: "Admin Duty" },
                    { id: "overhead-names", label: "Overhead Names" },
                    { id: "self-heal", label: "Self Heal" },
                    { id: "self-revive", label: "Self Revive" },
                ],
            },
            announcementText: "",
            disciplinaryFeed: [],
            reports: [],
            chatMessages: [],
            logsHistory: [],
            leaderboardPlayers: [],
            leaderboardSearchQuery: "",
            leaderboardMetric: "wealth",
            chatDraft: "",
            nextChatMessageId: 1,

            // Catalog pages
            itemsCatalog: [],
            vehiclesCatalog: [],
            jobsCatalog: [],
            gangsCatalog: [],

            // Players
            players: [],
            playerSearchQuery: "",
            selectedPlayer: null,
            activeContextPlayer: null,
            contextMenuVisible: false,
            contextMenuX: 0,
            contextMenuY: 0,
            contextActions: ["spectate", "quick-kick", "bring", "freeze", "heal"],
            disciplinaryActionOptions: [{ name: "Warn" }, { name: "Kick" }, { name: "Ban" }],
            disciplinaryDurationOptions: [{ name: "1 Hour" }, { name: "1 Day" }, { name: "7 Days" }, { name: "Permanent" }],
            selectedDisciplinaryAction: { name: "Warn" },
            selectedDisciplinaryDuration: { name: "1 Hour" },

            // Developer
            teleportLocationOptions: [],
            selectedTeleportLocation: null,
            spawnVehicleOptions: [],
            selectedSpawnVehicle: null,
            spawnObjectOptions: [],
            selectedSpawnObject: null,
            teleportCoordinatesInput: "",
            developerConsoleCommand: "",
            currentCoordinates: { x: 0.0, y: 0.0, z: 0.0 },
            currentRotation: { x: 0.0, y: 0.0, z: 0.0 },
            currentHeading: 0.0,

            // Environment
            environmentWeatherOptions: [
                { label: "Clear", value: "ClearSkies", icon: "sun" },
                { label: "Cloudy", value: "Cloudy", icon: "cloud" },
                { label: "Foggy", value: "Foggy", icon: "cloud-fog" },
                { label: "Overcast", value: "Overcast", icon: "clouds" },
                { label: "Partly Cloudy", value: "PartlyCloudy", icon: "cloud-sun" },
                { label: "Rain", value: "Rain", icon: "cloud-rain" },
                { label: "Light Rain", value: "RainLight", icon: "cloud-drizzle" },
                { label: "Thunderstorm", value: "RainThunderstorm", icon: "cloud-lightning" },
                { label: "Dust (Calm)", value: "SandDustCalm", icon: "wind" },
                { label: "Dust Storm", value: "SandDustStorm", icon: "wind" },
                { label: "Snow", value: "Snow", icon: "cloud-snow" },
                { label: "Blizzard", value: "SnowBlizzard", icon: "snowflake" },
                { label: "Light Snow", value: "SnowLight", icon: "cloud-snow" },
            ],
            currentWeather: "ClearSkies",
            environmentToggles: {
                freezeWeather: false,
                freezeTime: false,
                blackout: false,
                disableTraffic: false,
                disableAmbientPeds: false,
            },
            timeValue: 12,
            itemQuantityValue: 1,

            // Player management
            jobOptions: [],
            selectedJobOption: null,
            selectedJobGrade: 0,
            gangOptions: [],
            selectedGangOption: null,
            selectedGangGrade: 0,
            selectedMoneyAmount: 0,
            moneyReason: "",
            itemOptions: [],
            selectedItemOption: null,

            // Reports/Kanban
            tickets: {},
            draggedTicket: null,
            dragOverColumn: null,
            pendingResolutionTicketId: null,
            pendingResolutionColumn: null,
            activeInvestigationTicketId: null,
            activeInvestigationPlayerId: null,

            // Modal state
            openModals: {
                "report-detail-modal": false,
                "active-investigation-modal": false,
                "resolution-modal": false,
            },
            detailModalMeta: "",
            detailModalText: "",
            investigationMeta: "",
            investigationChat: "",
            resolutionMeta: "",
            resolutionNote: "",
            onWindowMessage: null,
            onWindowKeydown: null,
            onDocumentClick: null,
            onWindowResize: null,

            // Constants
            currentAdminName: "",
        };
    },

    computed: {
        activeDashboardReports() {
            return this.reports.filter((report) => !report.resolved);
        },

        filteredPlayers() {
            if (!this.playerSearchQuery.trim()) {
                return this.players;
            }
            const query = this.playerSearchQuery.toLowerCase();
            return this.players.filter((p) => {
                const text = `${p.id} ${p.character}`.toLowerCase();
                return text.includes(query);
            });
        },

        selectedPlayerLabel() {
            if (!this.selectedPlayer) {
                return "No player selected";
            }
            return `#${this.selectedPlayer.id} ${this.selectedPlayer.character}`;
        },

        selectedPlayerJobLabel() {
            if (!this.selectedPlayer || !this.selectedPlayer.currentJob) {
                return "Unemployed";
            }

            const { name, grade } = this.selectedPlayer.currentJob;
            if (name === "Unemployed") {
                return "Unemployed";
            }

            return `${name} (Grade ${grade})`;
        },

        requiresDisciplinaryDuration() {
            return this.selectedDisciplinaryAction?.name === "Ban";
        },

        filteredLeaderboardPlayers() {
            const query = this.leaderboardSearchQuery.trim().toLowerCase();
            const withWealth = this.leaderboardPlayers.map((p) => ({
                ...p,
                wealth: (Number(p.cash) || 0) + (Number(p.bank) || 0) + (Number(p.crypto) || 0),
            }));

            const filtered = query ? withWealth.filter((p) => p.name.toLowerCase().includes(query)) : withWealth;
            const metric = this.leaderboardMetric;

            const sorted = [...filtered].sort((a, b) => {
                if (metric === "cash") {
                    return b.cash - a.cash;
                }
                if (metric === "bank") {
                    return b.bank - a.bank;
                }
                if (metric === "crypto") {
                    return b.crypto - a.crypto;
                }
                return b.wealth - a.wealth;
            });

            return sorted.map((entry, index) => ({
                ...entry,
                rank: index + 1,
            }));
        },

        leaderboardStats() {
            const entries = this.filteredLeaderboardPlayers;
            if (!entries.length) {
                return {
                    avgCash: 0,
                    avgBank: 0,
                    avgCrypto: 0,
                    totalCash: 0,
                    totalBank: 0,
                    totalCrypto: 0,
                    avgWealth: 0,
                    totalWealth: 0,
                };
            }

            const totalCash = entries.reduce((sum, p) => sum + (Number(p.cash) || 0), 0);
            const totalBank = entries.reduce((sum, p) => sum + (Number(p.bank) || 0), 0);
            const totalCrypto = entries.reduce((sum, p) => sum + (Number(p.crypto) || 0), 0);
            const totalWealth = entries.reduce((sum, p) => sum + (Number(p.wealth) || 0), 0);
            const count = entries.length;

            return {
                avgCash: Math.round(totalCash / count),
                avgBank: Math.round(totalBank / count),
                avgCrypto: Math.round(totalCrypto / count),
                totalCash,
                totalBank,
                totalCrypto,
                avgWealth: Math.round(totalWealth / count),
                totalWealth,
            };
        },
    },

    methods: {
        // Page navigation
        setActivePage(pageName) {
            this.currentPage = pageName;
            this.closeContextMenu();
            this.refreshLucideIcons();
        },

        setPanelVisibility(nextVisible, context) {
            this.isVisible = Boolean(nextVisible);

            if (!this.isVisible) {
                this.closeContextMenu();
                return;
            }

            if (context && typeof context.page === "string" && this.pages.includes(context.page)) {
                this.currentPage = context.page;
            }

            this.$nextTick(() => {
                this.refreshLucideIcons();
            });
        },

        hydrateFromContext(context) {
            if (!context || typeof context !== "object") {
                return;
            }

            const arrayKeys = ["stats", "disciplinaryFeed", "reports", "players", "chatMessages", "logsHistory", "leaderboardPlayers", "itemsCatalog", "vehiclesCatalog", "jobsCatalog", "gangsCatalog", "jobOptions", "gangOptions", "itemOptions", "teleportLocationOptions", "spawnVehicleOptions", "spawnObjectOptions"];

            arrayKeys.forEach((key) => {
                if (Array.isArray(context[key])) {
                    this[key] = context[key];
                }
            });

            if (context.tickets && typeof context.tickets === "object" && !Array.isArray(context.tickets)) {
                this.tickets = { ...context.tickets };
            }

            if (context.environmentToggles && typeof context.environmentToggles === "object" && !Array.isArray(context.environmentToggles)) {
                this.environmentToggles = {
                    ...this.environmentToggles,
                    ...context.environmentToggles,
                };
            }

            if (typeof context.currentAdminName === "string") {
                this.currentAdminName = context.currentAdminName;
            }

            if (typeof context.currentWeather === "string") {
                this.currentWeather = context.currentWeather;
            }

            if (typeof context.timeValue === "number") {
                this.timeValue = context.timeValue;
            }

            if (typeof context.leaderboardMetric === "string") {
                this.leaderboardMetric = context.leaderboardMetric;
            }

            if (typeof context.nextChatMessageId === "number") {
                this.nextChatMessageId = context.nextChatMessageId;
            }

            if (context.currentCoordinates && typeof context.currentCoordinates === "object") {
                this.currentCoordinates = {
                    ...this.currentCoordinates,
                    ...context.currentCoordinates,
                };
            }

            if (context.currentRotation && typeof context.currentRotation === "object") {
                this.currentRotation = {
                    ...this.currentRotation,
                    ...context.currentRotation,
                };
            }

            if (typeof context.currentHeading === "number") {
                this.currentHeading = context.currentHeading;
            }

            if (typeof context.selectedPlayerId !== "undefined" && context.selectedPlayerId !== null) {
                this.selectedPlayer = this.players.find((player) => String(player.id) === String(context.selectedPlayerId)) || null;
            } else {
                this.selectedPlayer = this.players.length > 0 ? this.players[0] : null;
            }

            this.selectedJobOption = this.jobOptions.length > 0 ? this.jobOptions[0] : null;
            this.selectedGangOption = this.gangOptions.length > 0 ? this.gangOptions[0] : null;
            this.selectedItemOption = this.itemOptions.length > 0 ? this.itemOptions[0] : null;

            this.syncDashboardReportsFromTickets();
        },

        closePanel(reason) {
            if (!this.isVisible) {
                return;
            }

            this.setPanelVisibility(false);
            this.sendServerCallback("ui:close", {
                reason: reason || "ui",
            });
        },

        refreshLucideIcons() {
            if (!window.lucide || typeof window.lucide.createIcons !== "function") {
                return;
            }

            this.$nextTick(() => {
                window.lucide.createIcons();
            });
        },

        formatPageName(name) {
            return name
                .split("-")
                .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
                .join(" ");
        },

        getPageIcon(page) {
            const icons = {
                dashboard: "layout-dashboard",
                players: "users-round",
                leaderboard: "trophy",
                items: "package-search",
                vehicles: "car",
                jobs: "briefcase",
                gangs: "shield-alert",
                logs: "history",
                developer: "wrench",
                environment: "cloud",
                reports: "clipboard-list",
                chat: "messages-square",
            };

            return icons[page] || "circle";
        },

        // Developer
        teleportToSelectedLocation() {
            if (!this.selectedTeleportLocation) {
                this.appendDisciplinaryLog("Select a teleport location first.");
                return;
            }

            const { key, x, y, z, name } = this.selectedTeleportLocation;
            this.sendServerCallback("developer:teleportToLocation", {
                key: key || name,
                x,
                y,
                z,
                name,
            });
            this.appendDisciplinaryLog(`Teleported to ${name} (${x}, ${y}, ${z}).`);
        },

        teleportToCoordinates() {
            const parts = this.teleportCoordinatesInput
                .split(",")
                .map((part) => Number(part.trim()))
                .filter((value) => !Number.isNaN(value));

            if (parts.length !== 3) {
                this.appendDisciplinaryLog("Coordinates must be in format: x, y, z");
                return;
            }

            const [x, y, z] = parts;
            this.sendServerCallback("developer:teleportToCoordinates", { x, y, z });
            this.appendDisciplinaryLog(`Teleported to coordinates (${x}, ${y}, ${z}).`);
        },

        spawnSelectedVehicle() {
            if (!this.selectedSpawnVehicle) {
                this.appendDisciplinaryLog("Select a vehicle first.");
                return;
            }

            const { model, name } = this.selectedSpawnVehicle;
            this.sendServerCallback("developer:spawnVehicle", { model });
            this.appendDisciplinaryLog(`Spawned vehicle ${name} (${model}).`);
        },

        spawnSelectedObject() {
            if (!this.selectedSpawnObject) {
                this.appendDisciplinaryLog("Select an object first.");
                return;
            }

            const { model, name } = this.selectedSpawnObject;
            this.sendServerCallback("developer:spawnObject", { model });
            this.appendDisciplinaryLog(`Spawned object ${name} (${model}).`);
        },

        copyCurrentCoordinates() {
            this.sendServerCallback("developer:copyCoords", {});
        },

        copyCurrentRotation() {
            this.sendServerCallback("developer:copyRotation", {});
        },

        copyCurrentHeading() {
            this.sendServerCallback("developer:copyHeading", {});
        },

        runDeveloperConsoleCommand() {
            const command = this.developerConsoleCommand.trim();
            if (!command) {
                this.appendDisciplinaryLog("Console command cannot be empty.");
                return;
            }

            this.sendServerCallback("developer:runConsoleCommand", { command });
            this.appendDisciplinaryLog(`Executed console command: ${command}`);
            this.developerConsoleCommand = "";
        },

        // Players
        setActivePlayer(player) {
            this.selectedPlayer = player;
            this.closeContextMenu();
        },

        openContextMenu(event, player) {
            const menuWidth = 170;
            const menuHeight = 210;
            const maxLeft = window.innerWidth - menuWidth - 10;
            const maxTop = window.innerHeight - menuHeight - 10;

            this.contextMenuX = Math.max(8, Math.min(event.clientX, maxLeft));
            this.contextMenuY = Math.max(8, Math.min(event.clientY, maxTop));
            this.contextMenuVisible = true;
            this.activeContextPlayer = player;
        },

        closeContextMenu() {
            this.contextMenuVisible = false;
            this.activeContextPlayer = null;
        },

        handleContextAction(action) {
            const player = this.activeContextPlayer || this.selectedPlayer;
            if (!player) {
                return;
            }

            this.appendDisciplinaryLog(`Admin You performed ${action} on #${player.id} ${player.character}`);
            this.closeContextMenu();
            this.sendServerCallback("players:context-action", { action, playerId: player.id });
        },

        formatActionName(action) {
            return action
                .split("-")
                .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
                .join(" ");
        },

        findTicketForDashboardReport(report) {
            if (!report) {
                return null;
            }

            return Object.values(this.tickets).find((ticket) => {
                if (ticket.column === "resolved") {
                    return false;
                }

                if (ticket.reportId && report.id) {
                    return String(ticket.reportId) === String(report.id);
                }

                return String(ticket.playerId) === String(report.playerId);
            });
        },

        findDashboardReportForTicket(ticket) {
            if (!ticket) {
                return null;
            }

            if (ticket.reportId) {
                const reportById = this.reports.find((report) => String(report.id) === String(ticket.reportId));
                if (reportById) {
                    return reportById;
                }
            }

            return this.reports.find((report) => String(report.playerId) === String(ticket.playerId));
        },

        syncDashboardReportFromTicket(ticket) {
            const report = this.findDashboardReportForTicket(ticket);
            if (!report) {
                return;
            }

            report.claimed = ticket.column === "in-progress";
            report.resolved = ticket.column === "resolved";
        },

        syncDashboardReportsFromTickets() {
            this.reports.forEach((report) => {
                const ticket = this.findTicketForDashboardReport(report);
                report.claimed = Boolean(ticket && ticket.column === "in-progress");
                report.resolved = !ticket;
            });
        },

        toggleReportClaimed(report) {
            report.claimed = !report.claimed;
            const verb = report.claimed ? "claimed" : "released";
            this.appendDisciplinaryLog(`Admin You ${verb} report ${report.id} and teleported to #${report.playerId}`);

            const ticket = this.findTicketForDashboardReport(report);
            if (ticket) {
                const targetColumn = report.claimed ? "in-progress" : "incoming";
                this.moveTicket(ticket.id, targetColumn);
            }
        },

        handleVehicleAction(actionType) {
            if (!this.selectedPlayer) {
                return;
            }

            if (actionType === "delete") {
                this.selectedPlayer.currentVehicle = null;
            }

            this.sendServerCallback("players:vehicleAction", {
                action: actionType,
                playerId: this.selectedPlayer.id,
            });
            this.appendDisciplinaryLog(`Admin You used vehicle action '${actionType}' on #${this.selectedPlayer.id} ${this.selectedPlayer.character}.`);
        },

        handleGangQuickAction(actionType) {
            if (!this.selectedPlayer) {
                return;
            }

            if (actionType === "remove") {
                this.selectedPlayer.currentGang = { name: "None", grade: 0 };
                this.sendServerCallback("players:gangAction", {
                    action: "remove",
                    playerId: this.selectedPlayer.id,
                });
                this.appendDisciplinaryLog(`Admin You removed #${this.selectedPlayer.id} ${this.selectedPlayer.character} from their gang.`);
                return;
            }

            const nextGang = this.selectedGangOption?.name || "None";
            const nextGrade = Number(this.selectedGangGrade) || 0;
            this.selectedPlayer.currentGang = { name: nextGang, grade: nextGrade };
            this.sendServerCallback("players:gangAction", {
                action: "change",
                playerId: this.selectedPlayer.id,
                gang: nextGang,
                grade: nextGrade,
            });
            this.appendDisciplinaryLog(`Admin You set #${this.selectedPlayer.id} ${this.selectedPlayer.character} to ${nextGang} (Grade ${nextGrade}).`);
        },

        handleJobQuickAction(actionType) {
            if (!this.selectedPlayer) {
                return;
            }

            if (actionType === "fire") {
                this.selectedPlayer.currentJob = { name: "Unemployed", grade: 0 };
                this.sendServerCallback("players:jobAction", {
                    action: "fire",
                    playerId: this.selectedPlayer.id,
                });
                this.appendDisciplinaryLog(`Admin You fired #${this.selectedPlayer.id} ${this.selectedPlayer.character} from their job.`);
                return;
            }

            const nextJob = this.selectedJobOption?.name || "Unemployed";
            const nextGrade = Number(this.selectedJobGrade) || 0;
            this.selectedPlayer.currentJob = { name: nextJob, grade: nextGrade };
            this.sendServerCallback("players:jobAction", {
                action: "change",
                playerId: this.selectedPlayer.id,
                job: nextJob,
                grade: nextGrade,
            });
            this.appendDisciplinaryLog(`Admin You changed #${this.selectedPlayer.id} ${this.selectedPlayer.character} to ${nextJob} (Grade ${nextGrade}).`);
        },

        handlePlayerControlAction(actionType) {
            if (!this.selectedPlayer) {
                return;
            }

            this.sendServerCallback("players:quickControl", {
                action: actionType,
                playerId: this.selectedPlayer.id,
            });
            this.appendDisciplinaryLog(`Admin You used ${actionType} on #${this.selectedPlayer.id} ${this.selectedPlayer.character}.`);
        },

        replenishVital(vitalKey) {
            if (!this.selectedPlayer || !this.selectedPlayer.vitals || !(vitalKey in this.selectedPlayer.vitals)) {
                return;
            }

            this.selectedPlayer.vitals[vitalKey] = 100;

            this.sendServerCallback("players:replenishVital", {
                playerId: this.selectedPlayer.id,
                vital: vitalKey,
            });
            this.appendDisciplinaryLog(`Admin You replenished ${vitalKey} for #${this.selectedPlayer.id} ${this.selectedPlayer.character}.`);
        },

        adjustPlayerCurrency(currencyKey, delta) {
            if (!this.selectedPlayer || !this.selectedPlayer.financials || !(currencyKey in this.selectedPlayer.financials)) {
                return;
            }

            const currentValue = Number(this.selectedPlayer.financials[currencyKey]) || 0;
            const nextValue = Math.max(0, currentValue + delta);
            this.selectedPlayer.financials[currencyKey] = nextValue;

            this.sendServerCallback("players:currencyAdjust", {
                playerId: this.selectedPlayer.id,
                currency: currencyKey,
                delta,
                value: nextValue,
            });
        },

        formatMoney(amount) {
            return `$${(Number(amount) || 0).toLocaleString()}`;
        },

        getJobMinPay(job) {
            if (!job || !Array.isArray(job.grades) || !job.grades.length) {
                return 0;
            }

            return job.grades.reduce((minPay, grade) => Math.min(minPay, Number(grade.payment) || 0), Number.POSITIVE_INFINITY);
        },

        getJobMaxPay(job) {
            if (!job || !Array.isArray(job.grades) || !job.grades.length) {
                return 0;
            }

            return job.grades.reduce((maxPay, grade) => Math.max(maxPay, Number(grade.payment) || 0), 0);
        },

        handleQuickAction(action) {
            const selectedPlayerId = this.selectedPlayer?.id || null;
            this.sendServerCallback("dashboard:quickAction", {
                action: action.id,
                targetPlayerId: selectedPlayerId,
            });
            this.appendDisciplinaryLog(`Quick action executed: ${action.label}`);
        },

        sendChatMessage() {
            const message = this.chatDraft.trim();
            if (!message) {
                return;
            }

            this.sendServerCallback("chat:send", {
                message,
            });
            this.chatDraft = "";
        },

        handleIncomingChatMessage(entry) {
            if (!entry || typeof entry !== "object") {
                return;
            }

            const messageText = typeof entry.message === "string" ? entry.message.trim() : "";
            if (!messageText) {
                return;
            }

            const normalizedEntry = {
                id: Number(entry.id) || this.nextChatMessageId,
                author: typeof entry.author === "string" && entry.author ? entry.author : "Admin",
                message: messageText,
                time: typeof entry.time === "string" && entry.time ? entry.time : "",
            };

            this.chatMessages.push(normalizedEntry);
            this.nextChatMessageId = Math.max(this.nextChatMessageId, normalizedEntry.id + 1);
        },

        handleIncomingReportFiled(payload) {
            if (!payload || typeof payload !== "object") {
                return;
            }

            const incomingReport = payload.report;
            const incomingTicket = payload.ticket;

            if (incomingReport && typeof incomingReport === "object") {
                const reportId = String(incomingReport.id || "").trim();
                if (reportId) {
                    const reportIndex = this.reports.findIndex((report) => String(report.id) === reportId);
                    if (reportIndex >= 0) {
                        this.reports[reportIndex] = {
                            ...this.reports[reportIndex],
                            ...incomingReport,
                        };
                    } else {
                        this.reports.unshift(incomingReport);
                    }
                }
            }

            if (incomingTicket && typeof incomingTicket === "object") {
                const ticketId = String(incomingTicket.id || "").trim();
                if (ticketId) {
                    this.tickets[ticketId] = {
                        ...(this.tickets[ticketId] || {}),
                        ...incomingTicket,
                    };
                }
            }

            this.syncDashboardReportsFromTickets();
        },

        handleIncomingReportStateUpdate(payload) {
            if (!payload || typeof payload !== "object") {
                return;
            }

            const ticketId = String(payload.id || "").trim();
            if (!ticketId) {
                return;
            }

            this.tickets[ticketId] = {
                ...(this.tickets[ticketId] || { id: ticketId }),
                ...payload,
            };

            this.syncDashboardReportFromTicket(this.tickets[ticketId]);
        },

        handleIncomingReportResolved(payload) {
            if (!payload || typeof payload !== "object") {
                return;
            }

            this.handleIncomingReportStateUpdate({
                ...payload,
                column: "resolved",
            });
        },

        handleIncomingReportsClearedResolved(payload) {
            if (!payload || typeof payload !== "object" || !Array.isArray(payload.ids)) {
                return;
            }

            payload.ids.forEach((id) => {
                const ticketId = String(id || "").trim();
                if (ticketId && this.tickets[ticketId]) {
                    delete this.tickets[ticketId];
                }
            });

            this.syncDashboardReportsFromTickets();
        },

        // Environment
        sendAnnouncement() {
            const message = this.announcementText.trim();
            if (!message) {
                this.appendDisciplinaryLog("Announcement text is required.");
                return;
            }

            this.sendServerCallback("dashboard:announce", { message });
            this.appendDisciplinaryLog(`Announcement sent: ${message}`);
            this.announcementText = "";
        },

        setWeatherPreset(weather) {
            this.currentWeather = weather;
        },

        formatHourLabel(hour) {
            const timeValue = Number(hour);
            if (!Number.isFinite(timeValue)) {
                return "00:00";
            }

            let displayHour = 0;
            let displayMinute = 0;

            if (timeValue > 24) {
                displayHour = Math.floor(timeValue / 100);
                displayMinute = Math.round(timeValue - displayHour * 100);
            } else {
                displayHour = Math.floor(timeValue);
                displayMinute = Math.round((timeValue - displayHour) * 60);
            }

            if (displayMinute >= 60) {
                displayHour += Math.floor(displayMinute / 60);
                displayMinute %= 60;
            }

            displayHour = ((displayHour % 24) + 24) % 24;
            return `${String(displayHour).padStart(2, "0")}:${String(displayMinute).padStart(2, "0")}`;
        },

        changeWeather() {
            this.sendServerCallback("environment:changeWeather", {
                weather: this.currentWeather,
            });
            this.appendDisciplinaryLog(`Weather changed to ${this.currentWeather}.`);
        },

        changeTime() {
            this.sendServerCallback("environment:changeTime", {
                hour: this.timeValue,
            });
            this.appendDisciplinaryLog(`Time changed to ${this.formatHourLabel(this.timeValue)}.`);
        },

        runCleanupAction(action) {
            const actionLabels = {
                "vehicles-50m": "Cleared vehicles in 50m.",
                "peds-50m": "Cleared peds in 50m.",
                "objects-50m": "Cleared objects in 50m.",
                "everything-100m": "Cleared everything in 100m.",
            };

            this.sendServerCallback("environment:cleanup", { action });
            this.appendDisciplinaryLog(actionLabels[action] || `Environment cleanup action: ${action}`);
        },

        // Kanban/Reports
        getTicketsByColumn(column) {
            return Object.values(this.tickets).filter((t) => t.column === column);
        },

        getColumnCount(column) {
            return this.getTicketsByColumn(column).length;
        },

        isTicketLocked(ticket) {
            return ticket.column === "in-progress" && ticket.owner && ticket.owner !== this.currentAdminName;
        },

        handleDragStart(ticket) {
            if (this.isTicketLocked(ticket)) {
                return;
            }
            this.draggedTicket = ticket;
        },

        handleDropTicket(event, targetColumn) {
            if (!this.draggedTicket) {
                return;
            }

            const ticket = this.draggedTicket;
            this.dragOverColumn = null;

            if (ticket.column === targetColumn) {
                return;
            }

            if (this.isTicketLocked(ticket)) {
                this.appendDisciplinaryLog(`Ticket ${ticket.id} is locked by ${ticket.owner}.`);
                return;
            }

            if (targetColumn === "resolved") {
                this.pendingResolutionTicketId = ticket.id;
                this.pendingResolutionColumn = targetColumn;
                this.resolutionMeta = `Report ${ticket.reportId || ticket.id} | Player #${ticket.playerId}`;
                this.openModal("resolution-modal");
                this.draggedTicket = null;
                return;
            }

            this.moveTicket(ticket.id, targetColumn);
            this.draggedTicket = null;
        },

        handleTicketClick(ticket) {
            if (ticket.column === "in-progress") {
                if (this.isTicketLocked(ticket)) {
                    this.appendDisciplinaryLog(`Ticket ${ticket.id} is owned by ${ticket.owner}.`);
                    return;
                }

                this.activeInvestigationTicketId = ticket.id;
                this.activeInvestigationPlayerId = ticket.playerId;
                this.investigationMeta = `Ticket ${ticket.id} | Player #${ticket.playerId} | Category ${ticket.category}`;
                this.openModal("active-investigation-modal");
                return;
            }

            this.detailModalMeta = `Report ${ticket.reportId || ticket.id} | Player #${ticket.playerId} | Category ${ticket.category}`;
            const resolutionText = ticket.column === "resolved" && ticket.resolution ? `\n\nResolution Note:\n${ticket.resolution}` : "";
            this.detailModalText = `${ticket.fullText}${resolutionText}`;
            this.openModal("report-detail-modal");
        },

        moveTicket(ticketId, targetColumn) {
            const ticket = this.tickets[ticketId];
            if (!ticket) {
                return;
            }

            if (targetColumn === "in-progress") {
                ticket.owner = this.currentAdminName;
            }

            if (targetColumn === "incoming") {
                ticket.owner = "";
            }

            if (targetColumn === "resolved") {
                ticket.resolution = this.resolutionNote || "Resolved by admin.";
            }

            ticket.column = targetColumn;
            this.syncDashboardReportFromTicket(ticket);
            this.appendDisciplinaryLog(`Report ${ticket.id} moved to ${targetColumn}.`);
            this.sendServerCallback("reports:updateState", {
                id: ticket.id,
                column: targetColumn,
                owner: ticket.owner,
                resolution: ticket.resolution || "",
            });
        },

        submitResolution() {
            const note = this.resolutionNote.trim();
            if (!note) {
                this.appendDisciplinaryLog("Resolution note is required before resolving a ticket.");
                return;
            }

            if (this.pendingResolutionTicketId && this.pendingResolutionColumn) {
                this.moveTicket(this.pendingResolutionTicketId, this.pendingResolutionColumn);
                this.sendServerCallback("reports:resolved", {
                    id: this.pendingResolutionTicketId,
                    resolution: note,
                });
            }

            this.resolutionNote = "";
            this.pendingResolutionTicketId = null;
            this.pendingResolutionColumn = null;
            this.closeModal("resolution-modal");
        },

        handleInvestigationAction(action) {
            const ticketId = this.activeInvestigationTicketId;
            let playerId = this.activeInvestigationPlayerId;

            if (!playerId && ticketId && this.tickets[ticketId]) {
                playerId = this.tickets[ticketId].playerId;
            }

            if (!playerId) {
                this.appendDisciplinaryLog("No investigation target selected.");
                return;
            }

            this.appendDisciplinaryLog(`Investigation action used: ${action}`);
            this.sendServerCallback("reports:investigationAction", {
                action,
                ticketId,
                playerId,
            });
        },

        clearResolvedTickets() {
            const resolvedTicketIds = Object.values(this.tickets)
                .filter((ticket) => ticket.column === "resolved")
                .map((ticket) => ticket.id);

            if (!resolvedTicketIds.length) {
                return;
            }

            resolvedTicketIds.forEach((ticketId) => {
                delete this.tickets[ticketId];
            });

            this.sendServerCallback("reports:clearResolved", {
                ids: resolvedTicketIds,
            });
            this.appendDisciplinaryLog(`Cleared ${resolvedTicketIds.length} resolved report(s) from the board.`);
        },

        // Modal management
        openModal(modalId) {
            this.openModals[modalId] = true;
        },

        closeModal(modalId) {
            this.openModals[modalId] = false;

            if (modalId === "active-investigation-modal") {
                this.activeInvestigationTicketId = null;
                this.activeInvestigationPlayerId = null;
                this.investigationMeta = "";
                this.investigationChat = "";
            }
        },

        // Utilities
        appendDisciplinaryLog(entry) {
            this.disciplinaryFeed.unshift(entry);
            if (this.disciplinaryFeed.length > 8) {
                this.disciplinaryFeed.pop();
            }
        },

        sendServerCallback(eventName, payload, callback) {
            if (typeof hEvent === "function") {
                hEvent(eventName, payload, callback);
                return;
            }
            if (callback) {
                callback({
                    success: true,
                    message: `Mock response for ${eventName}`,
                });
            }
        },

        initializeReportsBoard() {
            this.syncDashboardReportsFromTickets();
        },

        // Click outside listener for context menu
        handleDocumentClick(event) {
            const contextMenu = document.getElementById("player-context-menu");
            if (contextMenu && !contextMenu.contains(event.target) && this.contextMenuVisible) {
                this.closeContextMenu();
            }
        },

        handleWindowResize() {
            if (this.contextMenuVisible) {
                this.closeContextMenu();
            }
        },

        handleKeydown(event) {
            if (event.key === "Escape" && this.isVisible) {
                event.preventDefault();
                this.closePanel("escape");
            }
        },

        handleMessage(event) {
            const payload = event && event.data ? event.data : {};
            const action = payload.name || payload.action;
            const context = (Array.isArray(payload.args) && payload.args[0]) || payload;

            if (action === "qb-admin:open" || action === "openAdmin" || action === "open") {
                this.hydrateFromContext(context);
                this.setPanelVisibility(true, context);
                return;
            }

            if (action === "qb-admin:close" || action === "closeAdmin" || action === "close") {
                this.setPanelVisibility(false);
                return;
            }

            if (action === "qb-admin:chatMessage" || action === "chatMessage") {
                this.handleIncomingChatMessage(context);
                return;
            }

            if (action === "qb-admin:reportFiled" || action === "reportFiled") {
                this.handleIncomingReportFiled(context);
                return;
            }

            if (action === "qb-admin:reportsUpdateState" || action === "reportsUpdateState" || action === "qb-admin:reports:updateState" || action === "reports:updateState") {
                this.handleIncomingReportStateUpdate(context);
                return;
            }

            if (action === "qb-admin:reportResolved" || action === "reportResolved" || action === "qb-admin:reports:resolved" || action === "reports:resolved") {
                this.handleIncomingReportResolved(context);
                return;
            }

            if (action === "qb-admin:reportsClearedResolved" || action === "reportsClearedResolved" || action === "qb-admin:reports:clearResolved" || action === "reports:clearResolved") {
                this.handleIncomingReportsClearedResolved(context);
                return;
            }
        },
    },

    mounted() {
        this.onWindowMessage = this.handleMessage.bind(this);
        this.onWindowKeydown = this.handleKeydown.bind(this);
        window.addEventListener("message", this.onWindowMessage);
        window.addEventListener("keydown", this.onWindowKeydown);

        // Initialize reports board
        this.initializeReportsBoard();

        // Global event listeners
        this.onDocumentClick = this.handleDocumentClick.bind(this);
        this.onWindowResize = this.handleWindowResize.bind(this);
        document.addEventListener("click", this.onDocumentClick);
        window.addEventListener("resize", this.onWindowResize);

        // Initial icon render
        this.refreshLucideIcons();
    },

    updated() {
        this.refreshLucideIcons();
    },

    beforeUnmount() {
        if (this.onWindowMessage) {
            window.removeEventListener("message", this.onWindowMessage);
        }
        if (this.onWindowKeydown) {
            window.removeEventListener("keydown", this.onWindowKeydown);
        }
        if (this.onDocumentClick) {
            document.removeEventListener("click", this.onDocumentClick);
        }
        if (this.onWindowResize) {
            window.removeEventListener("resize", this.onWindowResize);
        }
    },
});

app.mount("#app");
