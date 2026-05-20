local Locale = exports['qb-core']:GetLocale()

local Translations = {
    notifications = {
        ['char_deleted'] = 'Personažas ištrintas!',
        ['deleted_other_char'] = 'Sėkmingai ištrynėte personažą, kurio citizen id %{citizenid}.',
        ['forgot_citizenid'] = 'Pamiršote įvesti piliečio ID!',
    },

    commands = {
        -- /deletechar
        ['deletechar_description'] = 'Ištrina kito žaidėjo personažą',
        ['citizenid'] = 'Piliečio ID',
        ['citizenid_help'] = 'Personažo, kurį norite ištrinti, piliečio ID',

        -- /logout
        ['logout_description'] = 'Atsijungti nuo personažo (tik administratoriams)',

        -- /closeNUI
        ['closeNUI_description'] = 'Uždaryti Multi NUI'
    },

    misc = {
        ['droppedplayer'] = 'Atsijungėte nuo QBCore'
    },

    ui = {
        -- Main
        characters_header = 'Mano personažai',
        emptyslot = 'Laisva vieta',
        play_button = 'Žaisti',
        create_button = 'Sukurti personažą',
        delete_button = 'Ištrinti personažą',

        -- Character Information
        charinfo_header = 'Personažo informacija',
        charinfo_description = 'Pasirinkite vietą, kad pamatytumėte visą personažo informaciją.',
        name = 'Vardas',
        male = 'Vyras',
        female = 'Moteris',
        firstname = 'Vardas',
        lastname = 'Pavardė',
        nationality = 'Tautybė',
        gender = 'Lytis',
        birthdate = 'Gimimo data',
        job = 'Darbas',
        jobgrade = 'Pareigos',
        cash = 'Grynieji',
        bank = 'Bankas',
        phonenumber = 'Telefono numeris',
        accountnumber = 'Sąskaitos numeris',

        chardel_header = 'Personažo registracija',

        -- Delete character
        deletechar_header = 'Ištrinti personažą',
        deletechar_description = 'Ar tikrai norite ištrinti savo personažą?',

        -- Buttons
        cancel = 'Atšaukti',
        confirm = 'Patvirtinti',

        -- Loading Text
        retrieving_playerdata = 'Gaunami žaidėjo duomenys',
        validating_playerdata = 'Tikrinami žaidėjo duomenys',
        retrieving_characters = 'Gaunami personažai',
        validating_characters = 'Tikrinami personažai',

        -- Notifications
        ran_into_issue = 'Iškilo problema',
        profanity = 'Atrodo, bandote naudoti necenzūrinius / draudžiamus žodžius savo varde ar tautybėje!',
        forgotten_field = 'Panašu, kad nepateikėte vieno ar kelių laukų!'
    }
}

Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
