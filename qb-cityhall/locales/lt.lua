local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        not_in_range = 'Per toli nuo savivaldybės'
    },
    success = {
        recived_license = 'Gavote %{value} už 50 $'
    },
    info = {
        new_job_app = 'Jūsų paraiška išsiųsta (%{job}) vadovui',
        bilp_text = 'Miesto paslaugos',
        city_services_menu = '~g~E~w~ - Miesto paslaugų meniu',
        id_card = 'Asmens tapatybės kortelė',
        driver_license = 'Vairuotojo pažymėjimas',
        weaponlicense = 'Ginklų licencija',
        new_job = 'Sveikiname su nauju darbu! (%{job})',
    },
    email = {
        jobAppSender = '%{job}',
        jobAppSub = 'Ačiū, kad kandidatavote į %(job).',
        jobAppMsg = 'Sveiki, %{gender} %{lastname}<br /><br />%{job} gavo jūsų paraišką.<br /><br />Vadovas ją peržiūrės ir artimiausiu metu susisieks dėl pokalbio.<br /><br />Dar kartą dėkojame už jūsų paraišką.',
        mr = 'Ponas',
        mrs = 'Ponia',
        sender = 'Savivaldybė',
        subject = 'Vairavimo pamokų užklausa',
        message = 'Sveiki, %{gender} %{lastname}<br /><br />Gavome žinutę, kad kažkas nori vairavimo pamokų.<br />Jei galite pamokyti, susisiekite:<br />Vardas: <strong>%{firstname} %{lastname}</strong><br />Telefono numeris: <strong>%{phone}</strong><br/><br/>Pagarbiai,<br />Los Santos savivaldybė'
    }
}

Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
