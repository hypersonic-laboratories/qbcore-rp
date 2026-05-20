local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        to_far_from_door = 'Estás demasiado lejos del timbre',
        nobody_home = 'No hay nadie en casa...',
        nobody_at_door = 'No hay nadie en la puerta...'
    },
    success = {
        receive_apart = '¡Has recibido un apartamento!',
        changed_apart = '¡Te has mudado de apartamento!',
    },
    info = {
        at_the_door = '¡Hay alguien en la puerta!',
    },
    text = {
        options = '[E] Opciones del Apartamento',
        enter = 'Entrar al Apartamento',
        ring_doorbell = 'Tocar el Timbre',
        logout = 'Cerrar Sesión del Personaje',
        change_outfit = 'Cambiar Atuendo',
        open_stash = 'Abrir Almacén',
        move_here = 'Mudarte Aquí',
        open_door = 'Abrir Puerta',
        leave = 'Salir del Apartamento',
        close_menu = '⬅ Cerrar Menú',
        tennants = 'Inquilinos',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang