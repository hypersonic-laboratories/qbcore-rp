Crypto = {
    Lower = 500,
    Upper = 5000,
    History = {
        qbit = {},
    },

    Worth = {
        qbit = 1000,
    },

    Labels = {
        qbit = 'Qbit',
    },

    Exchange = {
        coords = Vector(521190, 607561, 4841),
        pedName = 'Crypto Exchange',
        pedHeading = 9,
        targetDistance = 400,
        RebootInfo = {
            state = false,
            percentage = 0,
        },
    },

    Coin = 'qbit',
    RefreshTimer = 10,

    ChanceOfCrashOrLuck = 2,
    Crash = { 20, 80 },
    Luck = { 20, 45 },

    ChanceOfDown = 30,
    ChanceOfUp = 60,
    CasualDown = { 1, 10 },
    CasualUp = { 1, 10 },
}

Ticker = {
    Enabled = false,
    coin = 'BTC',
    currency = 'USD',
    tick_time = 2,
    Api_key = 'put_api_key_here',
    Error_handle = {
        ['fsym is a required param.'] = 'Config error: Invalid / Missing coin name',
        ['tsyms is a required param.'] = 'Config error: Invalid / Missing currency',
        ['cccagg_or_exchange'] = 'Config error: Invalid currency / coin combination',
    },
}
