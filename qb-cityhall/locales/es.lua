local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        not_in_range = 'Estás demasiado lejos del ayuntamiento.'
    },
    success = {
        recived_license = '¡Has recibido tu %{value} por 50$!'
    },
    info = {
        new_job_app = 'Tu solicitud fue enviada al jefe de (%{job})',
        bilp_text = 'Servicios Municipales',
        city_services_menu = '~g~E~w~ - Menú Servicios Municipales',
        id_card = 'Tarjeta de Identificación (ID)',
        driver_license = 'Licencia de Conducir',
        weaponlicense = 'Licencia de Armas de Fuego',
        new_job = '¡Enhorabuena por tu nuevo trabajo! (%{job})',
    },
    email = {
        jobAppSender = '%{job}',
        jobAppSub = '¡Gracias por presentar su solicitud a %(job)!',
        jobAppMsg = 'Hola, %{gender} %{lastname}<br /><br />%{job} ha recibido su solicitud.<br /><br />Estamos estudiando tú solicitud y nos pondremos en contacto con usted para concertar una entrevista lo antes posible.<br /><br />Una vez más, gracias por su solicitud.',
        mr = 'Sr.',
        mrs = 'Sra.',
        sender = 'Municipio',
        subject = 'Solicitud de clases de conducir',
        message = 'Hola, %{gender} %{lastname}<br /><br />Acabamos de recibir un mensaje de alguien que quiere recibir clases de conducir.<br />Si estás dispuesto a dar clases, ponte en contacto con nosotros:<br />Name: <strong>%{firstname} %{lastname}</strong><br />Número de teléfono: <strong>%{phone}</strong><br/><br/>Atentamente,<br />Municipio de Los Santos'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang