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
            hEvent(
                "withdraw",
                {
                    accountName: this.selectedMoneyAccount,
                    amount: this.selectedMoneyAmount,
                    reason: this.moneyReason,
                },
                (response) => {
                    if (response.success) {
                        this.addStatement(this.accountNumber, this.selectedMoneyAccount, this.moneyReason, this.selectedMoneyAmount, "withdraw");
                        this.selectedMoneyAmount = 0;
                        this.moneyReason = "";
                        this.selectedMoneyAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        depositMoney() {
            if (!this.selectedMoneyAccount || this.selectedMoneyAmount <= 0) {
                return;
            }
            hEvent(
                "deposit",
                {
                    accountName: this.selectedMoneyAccount.name,
                    amount: this.selectedMoneyAmount,
                    reason: this.moneyReason,
                },
                (response) => {
                    if (response.success) {
                        this.addStatement(this.accountNumber, this.selectedMoneyAccount.name, this.moneyReason, this.selectedMoneyAmount, "deposit");
                        this.selectedMoneyAmount = 0;
                        this.moneyReason = "";
                        this.selectedMoneyAccount = null;
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        withdrawMoneyBank() {
            if (!this.bankWithdrawAccount || this.bankWithdrawAmount <= 0) return;
            hEvent("withdraw", { accountName: this.bankWithdrawAccount, amount: this.bankWithdrawAmount, reason: this.bankWithdrawReason }, (response) => {
                if (response.success) {
                    this.addStatement(this.accountNumber, this.bankWithdrawAccount, this.bankWithdrawReason, this.bankWithdrawAmount, "withdraw");
                    this.bankWithdrawAmount = 0;
                    this.bankWithdrawReason = "";
                    this.bankWithdrawAccount = "";
                    this.addNotification(response.message, "success");
                } else {
                    this.addNotification(response.message, "error");
                }
            });
        },
        depositMoneyBank() {
            if (!this.bankDepositAccount || this.bankDepositAmount <= 0) return;
            hEvent("deposit", { accountName: this.bankDepositAccount, amount: this.bankDepositAmount, reason: this.bankDepositReason }, (response) => {
                if (response.success) {
                    this.addStatement(this.accountNumber, this.bankDepositAccount, this.bankDepositReason, this.bankDepositAmount, "deposit");
                    this.bankDepositAmount = 0;
                    this.bankDepositReason = "";
                    this.bankDepositAccount = "";
                    this.addNotification(response.message, "success");
                } else {
                    this.addNotification(response.message, "error");
                }
            });
        },
        internalTransfer() {
            if (!this.internalFromAccount || !this.internalToAccount || this.internalTransferAmount <= 0) {
                return;
            }

            hEvent(
                "internalTransfer",
                {
                    fromAccountName: this.internalFromAccount,
                    toAccountName: this.internalToAccount,
                    amount: this.internalTransferAmount,
                    reason: this.internalTransferReason,
                },
                (response) => {
                    if (response.success) {
                        const fromAccount = this.accounts.find((acc) => acc.name === this.internalFromAccount);
                        if (fromAccount) {
                            fromAccount.balance -= this.internalTransferAmount;
                        }
                        const toAccount = this.accounts.find((acc) => acc.name === this.internalToAccount);
                        if (toAccount) {
                            toAccount.balance += this.internalTransferAmount;
                        }
                        this.addStatement(this.accountNumber, this.internalFromAccount, this.internalTransferReason, this.internalTransferAmount, "withdraw");
                        this.addStatement(this.accountNumber, this.internalToAccount, this.internalTransferReason, this.internalTransferAmount, "deposit");
                        this.internalTransferAmount = 0;
                        this.internalTransferReason = "";
                        this.internalFromAccount = "";
                        this.internalToAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        externalTransfer() {
            if (!this.externalFromAccount || !this.externalAccountNumber || this.externalTransferAmount <= 0) {
                return;
            }

            hEvent(
                "externalTransfer",
                {
                    fromAccountName: this.externalFromAccount,
                    toAccountNumber: this.externalAccountNumber,
                    amount: this.externalTransferAmount,
                    reason: this.externalTransferReason,
                },
                (response) => {
                    if (response.success) {
                        const fromAccount = this.accounts.find((acc) => acc.name === this.externalFromAccount);
                        if (fromAccount) {
                            fromAccount.balance -= this.externalTransferAmount;
                        }
                        this.addStatement(this.accountNumber, this.externalFromAccount, this.externalTransferReason, this.externalTransferAmount, "withdraw");
                        this.externalTransferAmount = 0;
                        this.externalTransferReason = "";
                        this.externalFromAccount = "";
                        this.externalAccountNumber = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        orderDebitCard() {
            if (!this.debitPin) {
                return;
            }

            hEvent("orderCard", { pin: this.debitPin }, (response) => {
                if (response.success) {
                    this.debitPin = "";
                    this.addNotification(response.message, "success");
                } else {
                    this.addNotification(response.message, "error");
                }
            });
        },
        openAccount() {
            if (!this.createAccountName || this.createAccountAmount < 0) {
                return;
            }

            hEvent(
                "openAccount",
                {
                    accountName: this.createAccountName,
                    amount: this.createAccountAmount,
                },
                (response) => {
                    if (response.success) {
                        const checkingAccount = this.accounts.find((acc) => acc.name === "checking");
                        checkingAccount.balance -= this.createAccountAmount;
                        this.accounts.push({
                            name: this.createAccountName,
                            type: "shared",
                            balance: this.createAccountAmount,
                            users: JSON.stringify([this.playerName]),
                        });
                        this.addStatement(this.accountNumber, "checking", "Initial deposit for " + this.createAccountName, this.createAccountAmount, "withdraw");
                        this.addStatement(this.accountNumber, this.createAccountName, "Initial deposit", this.createAccountAmount, "deposit");
                        this.createAccountName = "";
                        this.createAccountAmount = 0;
                        this.addNotification(response.message, "success");
                    } else {
                        this.createAccountName = "";
                        this.createAccountAmount = 0;
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        renameAccount() {
            if (!this.editAccount || !this.editAccountName) {
                return;
            }

            hEvent(
                "renameAccount",
                {
                    oldName: this.editAccount,
                    newName: this.editAccountName,
                },
                (response) => {
                    if (response.success) {
                        const account = this.accounts.find((acc) => acc.name === this.editAccount);
                        if (account) {
                            account.name = this.editAccountName;
                        }
                        this.editAccount = "";
                        this.editAccountName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        deleteAccount() {
            if (!this.editAccount) {
                return;
            }

            hEvent(
                "deleteAccount",
                {
                    accountName: this.editAccount,
                },
                (response) => {
                    if (response.success) {
                        this.accounts = this.accounts.filter((acc) => acc.name !== this.editAccount);
                        this.editAccount = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        addUserToAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }

            hEvent(
                "addUser",
                {
                    accountName: this.manageAccountName,
                    userName: this.manageUserName,
                },
                (response) => {
                    if (response.success) {
                        const account = this.accounts.find((a) => a.name === this.manageAccountName);
                        let usersArray = JSON.parse(account.users);
                        usersArray.push(this.manageUserName);
                        account.users = JSON.stringify(usersArray);
                        this.manageUserName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
        },
        removeUserFromAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }

            hEvent(
                "removeUser",
                {
                    accountName: this.manageAccountName,
                    userName: this.manageUserName,
                },
                (response) => {
                    if (response.success) {
                        const account = this.accounts.find((a) => a.name === this.manageAccountName);
                        let usersArray = JSON.parse(account.users);
                        usersArray = usersArray.filter((user) => user !== this.manageUserName);
                        account.users = JSON.stringify(usersArray);
                        this.manageUserName = "";
                        this.addNotification(response.message, "success");
                    } else {
                        this.addNotification(response.message, "error");
                    }
                }
            );
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
            }
        },
    },
    mounted() {
        window.addEventListener("message", this.handleMessage);
    },
}).mount("#app");
