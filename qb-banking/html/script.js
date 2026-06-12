const bankingApp = Vue.createApp({
    data() {
        return {
            isBankOpen: false,
            isATMOpen: false,
            showPinPrompt: false,
            notification: null,
            activeView: "home",
            accounts: [],
            statements: {},
            selectedAccountStatement: "checking",
            playerName: "",
            accountNumber: "",
            playerCash: 0,
            selectedMoneyAccount: "",
            selectedMoneyAmount: 0,
            moneyReason: "",
            bankWithdrawAccount: "",
            bankWithdrawAmount: 0,
            bankWithdrawReason: "",
            bankDepositAccount: "",
            bankDepositAmount: 0,
            bankDepositReason: "",
            internalFromAccount: "",
            internalToAccount: "",
            internalTransferAmount: 0,
            internalTransferReason: "",
            externalAccountNumber: "",
            externalFromAccount: "",
            externalTransferAmount: 0,
            externalTransferReason: "",
            debitPin: "",
            enteredPin: "",
            acceptablePins: [],
            tempBankData: null,
            createAccountName: "",
            createAccountAmount: 0,
            editAccount: "",
            editAccountName: "",
            manageAccountName: "",
            manageUserName: "",
            filteredUsers: [],
            showUsersDropdown: false,
            pendingBankAction: null,
        };
    },
    computed: {
        accountStatements() {
            if (this.selectedAccountStatement && this.statements[this.selectedAccountStatement]) {
                return this.statements[this.selectedAccountStatement];
            }
            return [];
        },
    },
    watch: {
        manageAccountName: function () {
            this.filterUsers();
        },
    },
    methods: {
        openBank(bankData) {
            const playerData = bankData.playerData;
            this.playerName = playerData.charinfo.firstname;
            this.accountNumber = playerData.citizenid;
            this.playerCash = playerData.money.cash;
            this.accounts = [];
            bankData.accounts.forEach((account) => {
                this.accounts.push({
                    name: account.account_name,
                    type: account.account_type,
                    balance: account.account_balance,
                    users: account.users,
                    id: account.id,
                });
            });
            this.statements = {};
            Object.keys(bankData.statements).forEach((accountKey) => {
                if (!bankData.statements[accountKey]?.length || bankData.statements[accountKey]?.length <= 0) return;
                this.statements[accountKey] = bankData.statements[accountKey].map((statement) => ({
                    id: statement.id,
                    date: statement.date,
                    reason: statement.reason,
                    amount: statement.amount,
                    type: statement.statement_type,
                    user: statement.citizenid,
                }));
            });
            this.isBankOpen = true;
        },
        openATM(bankData) {
            this.tempBankData = bankData;
            const playerData = bankData.playerData;
            this.playerName = playerData.charinfo.firstname;
            this.accountNumber = playerData.citizenid;
            this.playerCash = playerData.money.cash;
            this.accounts = [];
            bankData.accounts.forEach((account) => {
                this.accounts.push({
                    name: account.account_name,
                    type: account.account_type,
                    balance: account.account_balance,
                    users: account.users,
                    id: account.id,
                });
            });
            this.isATMOpen = true;
        },
        pinPrompt(enteredPin) {
            const bankData = this.tempBankData;
            this.acceptablePins = Array.from(bankData.pinNumbers);
            if (this.acceptablePins.includes(parseInt(enteredPin))) {
                this.showPinPrompt = false;
                this.openATM(bankData);
            }
        },
        withdrawMoney() {
            if (!this.selectedMoneyAccount || this.selectedMoneyAmount <= 0) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "withdrawATM", accountName: this.selectedMoneyAccount, amount: this.selectedMoneyAmount, reason: this.moneyReason };
            hEvent("withdraw", { accountName: this.selectedMoneyAccount, amount: this.selectedMoneyAmount, reason: this.moneyReason });
        },
        depositMoney() {
            if (!this.selectedMoneyAccount || this.selectedMoneyAmount <= 0) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "depositATM", accountName: this.selectedMoneyAccount.name, amount: this.selectedMoneyAmount, reason: this.moneyReason };
            hEvent("deposit", { accountName: this.selectedMoneyAccount.name, amount: this.selectedMoneyAmount, reason: this.moneyReason });
        },
        withdrawMoneyBank() {
            if (!this.bankWithdrawAccount || this.bankWithdrawAmount <= 0) return;
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "withdrawBank", accountName: this.bankWithdrawAccount, amount: this.bankWithdrawAmount, reason: this.bankWithdrawReason };
            hEvent("withdraw", { accountName: this.bankWithdrawAccount, amount: this.bankWithdrawAmount, reason: this.bankWithdrawReason });
        },
        depositMoneyBank() {
            if (!this.bankDepositAccount || this.bankDepositAmount <= 0) return;
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "depositBank", accountName: this.bankDepositAccount, amount: this.bankDepositAmount, reason: this.bankDepositReason };
            hEvent("deposit", { accountName: this.bankDepositAccount, amount: this.bankDepositAmount, reason: this.bankDepositReason });
        },
        internalTransfer() {
            if (!this.internalFromAccount || !this.internalToAccount || this.internalTransferAmount <= 0) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "internalTransfer", fromAccount: this.internalFromAccount, toAccount: this.internalToAccount, amount: this.internalTransferAmount, reason: this.internalTransferReason };
            hEvent("internalTransfer", { fromAccountName: this.internalFromAccount, toAccountName: this.internalToAccount, amount: this.internalTransferAmount, reason: this.internalTransferReason });
        },
        externalTransfer() {
            if (!this.externalFromAccount || !this.externalAccountNumber || this.externalTransferAmount <= 0) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "externalTransfer", fromAccount: this.externalFromAccount, amount: this.externalTransferAmount, reason: this.externalTransferReason };
            hEvent("externalTransfer", { fromAccountName: this.externalFromAccount, toAccountNumber: this.externalAccountNumber, amount: this.externalTransferAmount, reason: this.externalTransferReason });
        },
        orderDebitCard() {
            if (!this.debitPin) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "orderCard" };
            hEvent("orderCard", { pin: this.debitPin });
        },
        openAccount() {
            if (!this.createAccountName || this.createAccountAmount < 0) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "openAccount", accountName: this.createAccountName, amount: this.createAccountAmount };
            hEvent("openAccount", { accountName: this.createAccountName, amount: this.createAccountAmount });
        },
        renameAccount() {
            if (!this.editAccount || !this.editAccountName) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "renameAccount", oldName: this.editAccount, newName: this.editAccountName };
            hEvent("renameAccount", { oldName: this.editAccount, newName: this.editAccountName });
        },
        deleteAccount() {
            if (!this.editAccount) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "deleteAccount", accountName: this.editAccount };
            hEvent("deleteAccount", { accountName: this.editAccount });
        },
        addUserToAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "addUser", accountName: this.manageAccountName, userName: this.manageUserName };
            hEvent("addUser", { accountName: this.manageAccountName, userName: this.manageUserName });
        },
        removeUserFromAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }
            if (this.pendingBankAction) return;
            this.pendingBankAction = { action: "removeUser", accountName: this.manageAccountName, userName: this.manageUserName };
            hEvent("removeUser", { accountName: this.manageAccountName, userName: this.manageUserName });
        },
        processBankActionResult(response) {
            if (!this.pendingBankAction) return;
            const ctx = this.pendingBankAction;
            this.pendingBankAction = null;
            switch (ctx.action) {
                case "withdrawATM":
                    if (response.success) {
                        this.addStatement(this.accountNumber, ctx.accountName, ctx.reason, ctx.amount, "withdraw");
                        this.selectedMoneyAmount = 0;
                        this.moneyReason = "";
                        this.selectedMoneyAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "withdrawBank":
                    if (response.success) {
                        this.addStatement(this.accountNumber, ctx.accountName, ctx.reason, ctx.amount, "withdraw");
                        this.bankWithdrawAmount = 0;
                        this.bankWithdrawReason = "";
                        this.bankWithdrawAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "depositATM":
                    if (response.success) {
                        this.addStatement(this.accountNumber, ctx.accountName, ctx.reason, ctx.amount, "deposit");
                        this.selectedMoneyAmount = 0;
                        this.moneyReason = "";
                        this.selectedMoneyAccount = null;
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "depositBank":
                    if (response.success) {
                        this.addStatement(this.accountNumber, ctx.accountName, ctx.reason, ctx.amount, "deposit");
                        this.bankDepositAmount = 0;
                        this.bankDepositReason = "";
                        this.bankDepositAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "internalTransfer": {
                    if (response.success) {
                        const fromAcc = this.accounts.find((acc) => acc.name === ctx.fromAccount);
                        if (fromAcc) fromAcc.balance -= ctx.amount;
                        const toAcc = this.accounts.find((acc) => acc.name === ctx.toAccount);
                        if (toAcc) toAcc.balance += ctx.amount;
                        this.addStatement(this.accountNumber, ctx.fromAccount, ctx.reason, ctx.amount, "withdraw");
                        this.addStatement(this.accountNumber, ctx.toAccount, ctx.reason, ctx.amount, "deposit");
                        this.internalTransferAmount = 0;
                        this.internalTransferReason = "";
                        this.internalFromAccount = "";
                        this.internalToAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                }
                case "externalTransfer": {
                    if (response.success) {
                        const fromAcc = this.accounts.find((acc) => acc.name === ctx.fromAccount);
                        if (fromAcc) fromAcc.balance -= ctx.amount;
                        this.addStatement(this.accountNumber, ctx.fromAccount, ctx.reason, ctx.amount, "withdraw");
                        this.externalTransferAmount = 0;
                        this.externalTransferReason = "";
                        this.externalFromAccount = "";
                        this.externalAccountNumber = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                }
                case "orderCard":
                    if (response.success) {
                        this.debitPin = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "openAccount":
                    if (response.success) {
                        const checkingAccount = this.accounts.find((acc) => acc.name === "checking");
                        if (checkingAccount) checkingAccount.balance -= ctx.amount;
                        this.accounts.push({ name: ctx.accountName, type: "shared", balance: ctx.amount, users: JSON.stringify([this.playerName]) });
                        this.addStatement(this.accountNumber, "checking", "Initial deposit for " + ctx.accountName, ctx.amount, "withdraw");
                        this.addStatement(this.accountNumber, ctx.accountName, "Initial deposit", ctx.amount, "deposit");
                        this.createAccountName = "";
                        this.createAccountAmount = 0;
                        this.addNotification(response.message, "success");
                    } else {
                        this.createAccountName = "";
                        this.createAccountAmount = 0;
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "renameAccount": {
                    if (response.success) {
                        const account = this.accounts.find((acc) => acc.name === ctx.oldName);
                        if (account) account.name = ctx.newName;
                        this.editAccount = "";
                        this.editAccountName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                }
                case "deleteAccount":
                    if (response.success) {
                        this.accounts = this.accounts.filter((acc) => acc.name !== ctx.accountName);
                        this.editAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                case "addUser": {
                    if (response.success) {
                        const account = this.accounts.find((a) => a.name === ctx.accountName);
                        if (account) {
                            let usersArray = JSON.parse(account.users);
                            usersArray.push(ctx.userName);
                            account.users = JSON.stringify(usersArray);
                        }
                        this.manageUserName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                }
                case "removeUser": {
                    if (response.success) {
                        const account = this.accounts.find((a) => a.name === ctx.accountName);
                        if (account) {
                            let usersArray = JSON.parse(account.users);
                            usersArray = usersArray.filter((user) => user !== ctx.userName);
                            account.users = JSON.stringify(usersArray);
                        }
                        this.manageUserName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                    break;
                }
            }
        },
        addStatement(accountNumber, accountName, reason, amount, type) {
            let newStatement = {
                date: Date.now(),
                user: accountNumber,
                reason: reason,
                amount: amount,
                type: type,
            };

            if (!this.statements[accountName]) {
                this.statements[accountName] = [];
            }

            this.statements[accountName].push(newStatement);
        },
        addNotification(message, type) {
            this.notification = {
                message: message,
                type: type,
            };

            setTimeout(() => {
                this.notification = null;
            }, 3000);
        },
        appendNumber(number) {
            this.enteredPin += number.toString();
        },
        selectAccount(account) {
            this.selectedAccountStatement = account.name;
        },
        setActiveView(view) {
            this.activeView = view;
        },
        formatCurrency(amount) {
            return new Intl.NumberFormat().format(amount);
        },
        filterUsers() {
            const account = this.accounts.find((a) => a.name === this.manageAccountName);
            if (!account || typeof account.users !== "string") {
                this.filteredUsers = [];
                return;
            }
            let usersArray;
            try {
                usersArray = JSON.parse(account.users);
            } catch (e) {
                this.filteredUsers = [];
                return;
            }
            if (this.manageUserName === "") {
                this.filteredUsers = usersArray;
            } else {
                this.filteredUsers = usersArray.filter((user) => user.toLowerCase().includes(this.manageUserName.toLowerCase()));
            }
        },
        selectUser(user) {
            this.manageUserName = user;
            this.showUsersDropdown = false;
        },
        hideDropdown() {
            setTimeout(() => {
                this.showUsersDropdown = false;
            }, 100);
        },
        formatDate(timestamp) {
            const date = new Date(parseInt(timestamp));
            const month = (date.getMonth() + 1).toString().padStart(2, "0");
            const day = date.getDate().toString().padStart(2, "0");
            const year = date.getFullYear();
            return `${month}/${day}/${year}`;
        },
        balanceClass(statementType) {
            return statementType === "deposit" ? "positive-balance" : "negative-balance";
        },
        closeApplication() {
            if (this.isBankOpen) {
                this.isBankOpen = false;
            } else if (this.isATMOpen) {
                this.isATMOpen = false;
            } else if (this.showPinPrompt) {
                this.showPinPrompt = false;
                this.enteredPin = "";
                this.acceptablePins = [];
                this.tempBankData = null;
            }
            hEvent("closeApp", {});
        },
        handleMessage(event) {
            const action = event.data.name;
            if (action === "openBank") {
                this.openBank(event.data.args[0]);
            } else if (action === "openATM") {
                this.tempBankData = event.data.args[0];
                this.showPinPrompt = true;
            } else if (action === "updatePlayerMoney") {
                const { cash, bank } = event.data.args[0];
                this.playerCash = cash;
                const checking = this.accounts.find((acc) => acc.name === "checking");
                if (checking) checking.balance = bank;
            } else if (action === "bankActionResult") {
                this.processBankActionResult(event.data.args[0]);
            }
        },
    },
    mounted() {
        window.addEventListener("message", this.handleMessage);
    },
}).mount("#app");
