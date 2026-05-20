local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        testdrive_alreadyin = 'Jau dalyvaujate bandomajame važiavime',
        testdrive_return = 'Tai ne jūsų bandomasis automobilis',
        Invalid_ID = 'Nurodytas neteisingas žaidėjo ID',
        playertoofar = 'Šis žaidėjas per toli',
        notenoughmoney = 'Nepakanka pinigų',
        minimumallowed = 'Mažiausia galima įmoka yra $',
        overpaid = 'Sumokėjote per daug',
        alreadypaid = 'Transporto priemonė jau išmokėta',
        notworth = 'Ši transporto priemonė tiek nekainuoja',
        downtoosmall = 'Per maža pradinė įmoka',
        exceededmax = 'Viršyta maksimali įmoka',
        repossessed = 'Jūsų transporto priemonė su numeriais %{plate} buvo susigrąžinta',
        buyerinfo = 'Nepavyko gauti pirkėjo informacijos',
        notinveh = 'Turite sėdėti transporto priemonėje, kurią norite perleisti',
        vehinfo = 'Nepavyko gauti transporto priemonės informacijos',
        notown = 'Ši transporto priemonė jums nepriklauso',
        buyertoopoor = 'Pirkėjas neturi pakankamai pinigų',
        nofinanced = 'Šioje vietoje neturite lizinguojamų transporto priemonių',
        financed = 'Ši transporto priemonė yra lizinguojama',
    },
    success = {
        purchased = 'Sveikiname su pirkiniu!',
        earned_commission = 'Uždirbote $ %{amount} komisinį',
        gifted = 'Padovanojote savo transporto priemonę',
        received_gift = 'Gavote dovanotą transporto priemonę',
        soldfor = 'Pardavėte savo transporto priemonę už $',
        boughtfor = 'Nusipirkote transporto priemonę už $',
    },
    menus = {
        vehHeader_header = 'Transporto priemonės parinktys',
        vehHeader_txt = 'Sąveikauti su pasirinkta transporto priemone',
        financed_header = 'Lizinguojamos transporto priemonės',
        finance_txt = 'Peržiūrėkite savo transporto priemones',
        returnTestDrive_header = 'Baigti bandomąjį važiavimą',
        goback_header = 'Grįžti',
        veh_price = 'Kaina: $',
        veh_platetxt = 'Numeriai: ',
        veh_finance = 'Transporto priemonės įmokos',
        veh_finance_balance = 'Likusi suma',
        veh_finance_currency = '$',
        veh_finance_total = 'Likusių įmokų skaičius',
        veh_finance_reccuring = 'Periodinės įmokos suma',
        veh_finance_pay = 'Sumokėti įmoką',
        veh_finance_payoff = 'Atsiskaityti pilnai',
        veh_finance_payment = 'Įmokos suma ($)',
        submit_text = 'Patvirtinti',
        test_header = 'Bandomasis važiavimas',
        finance_header = 'Lizinguoti transporto priemonę',
        swap_header = 'Pakeisti transporto priemonę',
        swap_txt = 'Pakeisti pasirinktą transporto priemonę',
        financesubmit_downpayment = 'Pradinė įmoka - min ',
        financesubmit_totalpayment = 'Iš viso įmokų - maks ',
        --Free Use
        freeuse_test_txt = 'Išbandyti pasirinktą transporto priemonę',
        freeuse_buy_header = 'Pirkti transporto priemonę',
        freeuse_buy_txt = 'Įsigyti pasirinktą transporto priemonę',
        freeuse_finance_txt = 'Lizinguoti pasirinktą transporto priemonę',
        --Managed
        managed_test_txt = 'Leisti žaidėjui bandomąjį važiavimą',
        managed_sell_header = 'Parduoti transporto priemonę',
        managed_sell_txt = 'Parduoti transporto priemonę žaidėjui',
        managed_finance_txt = 'Lizinguoti transporto priemonę žaidėjui',
        submit_ID = 'Serverio ID (#)',
    },
    general = {
        testdrive_timer = 'Bandomojo važiavimo laikas:',
        vehinteraction = 'Transporto priemonės sąveika',
        testdrive_timenoti = 'Likę %{testdrivetime} min.',
        testdrive_complete = 'Bandomasis važiavimas baigtas',
        paymentduein = 'Įmoka turi būti sumokėta per %{time} min.',
        command_transfervehicle = 'Padovanoti arba parduoti savo transporto priemonę',
        command_transfervehicle_help = 'Pirkėjo ID',
        command_transfervehicle_amount = 'Pardavimo suma (pasirinktinai)',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
