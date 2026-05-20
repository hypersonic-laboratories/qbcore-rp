QBCore.Shared = QBCore.Shared or {}
QBCore.Shared.Weapons = {
    --[[ weapon_acm = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_ACM',
        damage = 30,
        spread = 30,
        recoil = 0.45,
        cadence = 0.2,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        right_hand_offset = Vector(1, 1, 1),
        left_hand_bone = 'b_gun_lefthand',
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_ACM_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_ACM_Fire_RecoilRifleA',
            reload = 'helix::A_ACM_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_ACM_Mag', relative_location = Vector(15, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_ACM_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_austro = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Austro',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.75, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Austro_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_Austro_Fire_RecoilRifleB',
            reload = 'helix::A_Austro_ReloadRifleB',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleB',
            character_reload = 'helix::AM_Player_ReloadRifleB',
            character_holster = 'helix::AM_Player_HolsteringRifleB',
            character_equip = 'helix::AM_Player_EquipRifleB'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Austro_Mag', relative_location = Vector(-14, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_banshee = {
        ammo_type = 'pistol_ammo',
        asset_name = 'helix::SK_Banshee',
        damage = 45,
        spread = 70,
        recoil = 2,
        cadence = 0.225,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 400, damage_multiplier = 0.8 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(2, 1, 0.25),
        sight_fov_multiplier = 0.6,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_45ap' },
        sounds = {
            dry = 'helix::A_Pistol_Dry',
            load = 'helix::A_Pistol_Load',
            unload = 'helix::A_Pistol_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Banshee_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Banshee_Fire_RecoilPistol',
            reload = 'helix::A_Banshee_ReloadPistol',
            character_fire = 'helix::AM_Player_Fire_RecoilPistol',
            character_reload = 'helix::AM_Player_ReloadPistol',
            character_holster = 'helix::AM_Player_HolsteringPistol',
            character_equip = 'helix::AM_Player_EquipPistol'
        },
        magazine_mesh = 'helix::SM_DesertEagle_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Tee',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Banshee_Mag', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_bison = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Bison',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Bison_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Bison_Mag', relative_location = Vector(15, 0, 8.2), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Bison_RearGrip', relative_location = Vector(0, 0, 5), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Bison_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_condor = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Condor',
        damage = 33,
        spread = 30,
        recoil = 0.21,
        cadence = 0.11,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1.5, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Condor_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_Condor_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Condor_MagFull', relative_location = Vector(15, 0, 8), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Condor_IronSight', relative_location = Vector(0, 0, 13), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Condor_RearGrip', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_convert = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Convert',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 1000, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(1.25, 1, 0.25),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Convert_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Convert_Mag', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        },
    },
    weapon_cs446 = {
        ammo_type = 'snp_ammo',
        asset_name = 'helix::SK_CS-446',
        damage = 90,
        spread = 10,
        recoil = 3,
        cadence = 2,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(2.25, 1, 0),
        sight_fov_multiplier = 0.1,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_CS-446_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::446_Fire_RecoilSniperA',
            reload = 'helix::446_ReloadSniperA',
            character_fire = 'helix::AM_Player_Fire_RecoilSniperA',
            character_reload = 'helix::AM_Player_ReloadSniperA',
            character_holster = 'helix::AM_Player_HolsteringSniperA',
            character_equip = 'helix::AM_Player_EquipSniperA'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_CS-446_Mag', relative_location = Vector(20, 0, 5), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_db12 = {
        ammo_type = 'shotgun_ammo',
        asset_name = 'helix::SK_DB-12',
        damage = 30,
        spread = 70,
        recoil = 3,
        cadence = 0.9,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 6, bullet_max_distance = 10000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 100, damage_multiplier = 0.25 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(3.5, 1, 5.75),
        sight_fov_multiplier = 0.75,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_12Gauge' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_DB-12_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 1
            }
        },
        animations = {
            fire = 'helix::A_Moss500_Fire',
            reload = 'helix::A_DB-12_ReloadShotgunB_DB-12',
            character_fire = 'helix::AM_Player_Fire_RecoilShotgunB',
            character_reload = 'helix::AM_Player_ReloadShotgunB_DB-12',
            character_holster = 'helix::AM_Player_HolsteringShotgunB',
            character_equip = 'helix::AM_Player_EquipShotgunB'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Shotgun'
    },
    weapon_dmc68 = {
        ammo_type = 'snp_ammo',
        asset_name = 'helix::SK_DMC-68',
        damage = 90,
        spread = 10,
        recoil = 3,
        cadence = 2,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0),
        sight_fov_multiplier = 0.1,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_DMC-68_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_DMC-68_Fire_RecoilSniperB',
            reload = 'helix::A_DMC-68_ReloadSniperB',
            character_fire = 'helix::AM_Player_Fire_RecoilSniperB',
            character_reload = 'helix::AM_Player_ReloadSniperB',
            character_holster = 'helix::AM_Player_HolsteringSniperB',
            character_equip = 'helix::AM_Player_EquipSniperB'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_DMC-68_Mag', relative_location = Vector(16, 0, 4), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_fang = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Fang',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 0, 0.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Fang_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Fang_Mag', relative_location = Vector(15, 0, -4), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Fang_RearGrip', relative_location = Vector(4, 0, 11), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Fang_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_fierro = {
        ammo_type = 'pistol_ammo',
        asset_name = 'helix::SK_Fierro',
        damage = 45,
        spread = 70,
        recoil = 2,
        cadence = 0.225,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 400, damage_multiplier = 0.8 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(2.75, 1, 0),
        sight_fov_multiplier = 0.6,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_45ap' },
        sounds = {
            dry = 'helix::A_Pistol_Dry',
            load = 'helix::A_Pistol_Load',
            unload = 'helix::A_Pistol_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Fierro_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Fierro_Fire_Recoil_Fierro',
            reload = 'helix::A_Fierro_ReloadPistol',
            character_fire = 'helix::AM_Player_Fire_Recoil_Fierro',
            character_reload = 'helix::AM_Player_ReloadPistol_Fierro',
            character_holster = 'helix::AM_Player_HolsteringPistol',
            character_equip = 'helix::AM_Player_EquipPistol'
        },
        magazine_mesh = 'helix::SM_DesertEagle_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Tee'
    },
    weapon_finisher = {
        ammo_type = 'shotgun_ammo',
        asset_name = 'helix::SK_Finisher',
        damage = 30,
        spread = 70,
        recoil = 3,
        cadence = 0.9,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 6, bullet_max_distance = 10000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 100, damage_multiplier = 0.25 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(0, 1, 0),
        sight_fov_multiplier = 0.75,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_12Gauge' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Finisher_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 1
            }
        },
        animations = {
            fire = 'helix::A_Finisher_Fire_RecoilShotgunA',
            reload = 'helix::A_Finisher_ReloadShotgunA',
            character_fire = 'helix::AM_Player_Fire_RecoilShotgunA',
            character_reload = 'helix::AM_Player_ReloadShotgunA',
            character_holster = 'helix::AM_Player_HolsteringShotgunA',
            character_equip = 'helix::AM_Player_EquipShotgunA'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Shotgun'
    },
    weapon_freq = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Freq',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0.25),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Freq_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Freq_Mag', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Freq_IronSight', relative_location = Vector(10, 0, 12), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_gaston = {
        ammo_type = 'pistol_ammo',
        asset_name = 'helix::SK_Gaston',
        damage = 45,
        spread = 70,
        recoil = 2,
        cadence = 0.225,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 400, damage_multiplier = 0.8 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(2, 1, 0.75),
        sight_fov_multiplier = 0.6,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_45ap' },
        sounds = {
            dry = 'helix::A_Pistol_Dry',
            load = 'helix::A_Pistol_Load',
            unload = 'helix::A_Pistol_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Gaston_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Gaston_Fire_RecoilPistol',
            reload = 'helix::A_Gaston_ReloadPistol',
            character_fire = 'helix::AM_Player_Fire_RecoilPistol',
            character_reload = 'helix::AM_Player_ReloadPistol',
            character_holster = 'helix::AM_Player_HolsteringPistol',
            character_equip = 'helix::AM_Player_EquipPistol'
        },
        magazine_mesh = 'helix::SM_DesertEagle_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Tee',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Gaston_Mag', relative_location = Vector(-0.5, 0, -5), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_kal = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_KAL',
        damage = 30,
        spread = 27,
        recoil = 0.30,
        cadence = 0.19,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(0.5, 1, 1.25),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_KAL_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_KAL_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_KAL_Mag', relative_location = Vector(17, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_KAL_RearGrip', relative_location = Vector(0, 0, 2), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_KAL_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) }
        }
    },
    weapon_kfs = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_KFS',
        damage = 25,
        spread = 10,
        recoil = 0.25,
        cadence = 0.175,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.6 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1.5, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_556x45' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_Semi_Load',
            unload = 'helix::A_MMG_Reload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_KFS_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 8
            }
        },
        animations = {
            fire = 'helix::A_KFS_Fire_RecoilLMG',
            reload = 'helix::A_KFS_ReloadLMG',
            character_fire = 'helix::AM_Player_Fire_RecoilLMG',
            character_reload = 'helix::AM_Player_ReloadLMG',
            character_holster = 'helix::AM_Player_HolsteringLMG',
            character_equip = 'helix::AM_Player_EquipLMG'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular_X',
        default_attachments = {
            mag = { asset_name = 'helix::SM_KFS_Mag', relative_location = Vector(17, 0, 9), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_KFS_RearGrip', relative_location = Vector(0, 0, 8), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_KFS_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_KFS_IronSight', relative_location = Vector(60, 0, 11), relative_rotation = Rotator(0, 0, 0) },
            muzzle = { asset_name = 'helix::SM_KFS_Muzzle', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_ktk = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_KTK',
        damage = 30,
        spread = 70,
        recoil = 3,
        cadence = 0.9,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 6, bullet_max_distance = 10000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 100, damage_multiplier = 0.25 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(0, 1, 0),
        sight_fov_multiplier = 0.75,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_12Gauge' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_KTK_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 1
            }
        },
        animations = {
            fire = 'helix::A_Moss500_Fire',
            reload = 'helix::A_KTK_ReloadShotgunA_KTK',
            character_fire = 'helix::AM_Player_Fire_RecoilShotgunA',
            character_reload = 'helix::AM_Player_ReloadShotgunA_KTK',
            character_holster = 'helix::AM_Player_HolsteringShotgunA',
            character_equip = 'helix::AM_Player_EquipShotgunA'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Shotgun'
    },
    weapon_krink = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Krink',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Krink_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_Krink_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Krink_Mag', relative_location = Vector(17, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Krink_IronSight', relative_location = Vector(15, 0, 11), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Krink_RearGrip', relative_location = Vector(1.5, 0, 7), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Krink_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_lws32 = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_LWS-32',
        damage = 25,
        spread = 10,
        recoil = 0.25,
        cadence = 0.175,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.6 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1, -0.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_556x45' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_Semi_Load',
            unload = 'helix::A_MMG_Reload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_LWS-32_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 8
            }
        },
        animations = {
            fire = 'helix::A_Lewis_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Player_Fire_RecoilLMG',
            character_reload = 'helix::AM_Player_ReloadLMG',
            character_holster = 'helix::AM_Player_HolsteringLMG',
            character_equip = 'helix::AM_Player_EquipLMG'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular_X',
        default_attachments = {
            mag = { asset_name = 'helix::SM_LWS-32_Mag', relative_location = Vector(16, 0, 3), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_LWS-32_IronSight', relative_location = Vector(43, 0, 15), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_LWS-32_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_m77 = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_M77',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(2.5, 0.5, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_M77_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_M77_Mag_X', relative_location = Vector(2, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_M77_IronSight', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_M77_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            belt = { asset_name = 'helix::SM_M77_Belt', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_mirage = {
        ammo_type = 'pistol_ammo',
        asset_name = 'helix::SK_Mirage',
        damage = 45,
        spread = 70,
        recoil = 2,
        cadence = 0.225,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 400, damage_multiplier = 0.8 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(3, 1, 0),
        sight_fov_multiplier = 0.6,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_45ap' },
        sounds = {
            dry = 'helix::A_Pistol_Dry',
            load = 'helix::A_Pistol_Load',
            unload = 'helix::A_Pistol_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Mirage_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Mirage_Fire_RecoilPistol',
            reload = 'helix::A_Mirage_ReloadPistol',
            character_fire = 'helix::AM_Player_Fire_RecoilPistol',
            character_reload = 'helix::AM_Player_ReloadPistol',
            character_holster = 'helix::AM_Player_HolsteringPistol',
            character_equip = 'helix::AM_Player_EquipPistol'
        },
        magazine_mesh = 'helix::SM_DesertEagle_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Tee',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Mirage_Mag', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_mk4 = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_MK4',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(2, 1.5, 0.25),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_ACM_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_MK4_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_MK4_Mag', relative_location = Vector(14, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_MK4_IronSight', relative_location = Vector(14, 0, 13), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_MK4_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_mouflan = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Mouflan',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Mouflan_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Mouflan_Mag', relative_location = Vector(28.5, 0, 3), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Mouflan_IronSight', relative_location = Vector(10, 0, 13), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Mouflan_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_orion = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Orion',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_LightMachine_Shot',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Orion_Mag', relative_location = Vector(12, 0, 8), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Orion_IronSight', relative_location = Vector(9, 0, 13), relative_rotation = Rotator(0, 0, 0) },
            muzzle = { asset_name = 'helix::SM_Orion_Muzzle', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Orion_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stockSocket = { asset_name = 'helix::SM_Orion_StockSocket', relative_location = Vector(-4, 0, 10), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_patriot = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Patriot',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, -0.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_003',
            unload = 'helix::A_Rifle_RemoveMag_003',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Patriot_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_Patriot_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Patriot_Mag', relative_location = Vector(15, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Patriot_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Patriot_RearGrip', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) }
        }
    },
    weapon_pitviper = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Pit_Viper',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1, 1),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_PitViper_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_Pit_Viper_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Pit_Viper_Mag', relative_location = Vector(16.5, 0, 3.5), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_Pit_Viper_IronSight', relative_location = Vector(10, 0, 12), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Pit_Viper_RearGrip', relative_location = Vector(0, 0, 5), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Pit_Viper_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_pm99 = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_PM-99',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1.5, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_PM-99_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_PM-99_Mag', relative_location = Vector(12, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_PM-99_IronSight', relative_location = Vector(-3, 0, 13), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_PM-99_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_ppy = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_PP-Y',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(1.5, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_PP-Y_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            sight = { asset_name = 'helix::SM_PP-Y_IronSight', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            mag = { asset_name = 'helix::SM_PP-Y_Mag', relative_location = Vector(12, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_PP-Y_RearGrip', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_PP-Y_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_queen80 = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Queen-80',
        damage = 25,
        spread = 33,
        recoil = 0.29,
        cadence = 0.15,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(6, 1.25, -1.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_003',
            unload = 'helix::A_Rifle_RemoveMag_003',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Queen-80_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_Queen-80_ReloadRifleB',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleB',
            character_reload = 'helix::AM_Player_ReloadRifleB',
            character_holster = 'helix::AM_Player_HolsteringRifleB',
            character_equip = 'helix::AM_Player_EquipRifleB'
        },
        magazine_mesh = 'helix::SM_Queen-80_MagEmpty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Queen-80_Mag', relative_location = Vector(-4, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Queen-80_RearGrip', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) }
        }
    },
    weapon_remi = {
        ammo_type = 'shotgun_ammo',
        asset_name = 'helix::SK_Remi',
        damage = 30,
        spread = 70,
        recoil = 3,
        cadence = 0.9,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 6, bullet_max_distance = 10000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 100, damage_multiplier = 0.25 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(0, 1, 0),
        sight_fov_multiplier = 0.75,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_12Gauge' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Remi_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 1
            }
        },
        animations = {
            fire = 'helix::A_Remi_Fire_RecoilShotgunB',
            reload = 'helix::A_Remi_ReloadShotgunB',
            character_fire = 'helix::AM_Player_Fire_RecoilShotgunB',
            character_reload = 'helix::AM_Player_ReloadShotgunB',
            character_holster = 'helix::AM_Player_HolsteringShotgunB',
            character_equip = 'helix::AM_Player_EquipShotgunB'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Shotgun'
    },
    weapon_roger = {
        ammo_type = 'pistol_ammo',
        asset_name = 'helix::SK_Roger',
        damage = 45,
        spread = 70,
        recoil = 2,
        cadence = 0.225,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 400, damage_multiplier = 0.8 },
        handlingMode = HandlingMode.SingleHandedWeapon,
        right_hand_offset = Vector(1.5, 1, 0.5),
        sight_fov_multiplier = 0.6,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_45ap' },
        sounds = {
            dry = 'helix::A_Pistol_Dry',
            load = 'helix::A_Pistol_Load',
            unload = 'helix::A_Pistol_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Roger_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Roger_Fire_RecoilPistol',
            reload = 'helix::A_Roger_ReloadPistol',
            character_fire = 'helix::AM_Player_Fire_RecoilPistol',
            character_reload = 'helix::AM_Player_ReloadPistol',
            character_holster = 'helix::AM_Player_HolsteringPistol',
            character_equip = 'helix::AM_Player_EquipPistol'
        },
        magazine_mesh = 'helix::SM_DesertEagle_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Tee',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Roger_Mag', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_ronin777 = {
        ammo_type = 'snp_ammo',
        asset_name = 'helix::SK_Ronin-777',
        damage = 90,
        spread = 10,
        recoil = 3,
        cadence = 2,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(-0.5, 2.5, 0),
        sight_fov_multiplier = 0.1,
        usage_settings = { useable = false, unique = false },
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Ronin-777_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 2
            }
        },
        animations = {
            fire = 'helix::A_Ronin-777_Fire_RecoilSniperA',
            reload = 'helix::A_Ronin-777_ReloadSniperA',
            character_fire = 'helix::AM_Player_Fire_RecoilSniperA',
            character_reload = 'helix::AM_Player_ReloadSniperA',
            character_holster = 'helix::AM_Player_HolsteringSniperA',
            character_equip = 'helix::AM_Player_EquipSniperA'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Ronin-777_Mag', relative_location = Vector(13.5, 0, 2), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_roma12 = {
        ammo_type = 'shotgun_ammo',
        asset_name = 'helix::SK_Roma-12',
        damage = 30,
        spread = 70,
        recoil = 3,
        cadence = 0.9,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 6, bullet_max_distance = 10000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 100, damage_multiplier = 0.25 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(0.5, 1, -1.5),
        sight_fov_multiplier = 0.75,
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_12Gauge' },
        sounds = {
            dry = 'helix::A_Shotgun_Dry',
            load = 'helix::A_Shotgun_Load_Bullet',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Roma-12_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 1
            }
        },
        animations = {
            fire = 'helix::A_Moss500_Fire',
            reload = 'helix::A_Roma-12_ReloadShotgunA_Roma-12',
            character_fire = 'helix::AM_Player_Fire_RecoilShotgunA',
            character_reload = 'helix::AM_Player_ReloadShotgunA_Roma-12',
            character_holster = 'helix::AM_Player_HolsteringShotgunA',
            character_equip = 'helix::AM_Player_EquipShotgunA'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Shotgun',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Roma-12_Mag', relative_location = Vector(17.5, 0, 5.5), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_sabra = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_Sabra',
        damage = 25,
        spread = 10,
        recoil = 0.25,
        cadence = 0.175,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.6 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1.5, 1, 0),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_556x45' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_Semi_Load',
            unload = 'helix::A_MMG_Reload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Sabra_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 8
            }
        },
        animations = {
            fire = 'helix::A_Lewis_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Player_Fire_RecoilLMG',
            character_reload = 'helix::AM_Player_ReloadLMG',
            character_holster = 'helix::AM_Player_HolsteringLMG',
            character_equip = 'helix::AM_Player_EquipLMG'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular_X',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Sabra_Mag', relative_location = Vector(14, 0, 9), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_Sabra_RearGrip', relative_location = Vector(0, 0, 7), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Sabra_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_sovwhisper = {
        ammo_type = 'rifle_ammo',
        asset_name = 'helix::SK_SovWhisper',
        damage = 30,
        spread = 30,
        recoil = 0.25,
        cadence = 0.1,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.75 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1, -0.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_762x39' },
        sounds = {
            dry = 'helix::A_Rifle_Dry',
            load = 'helix::A_Rifle_InsertMag_002',
            unload = 'helix::A_Rifle_RemoveMag_002',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Suppressor_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AK47_Fire',
            reload = 'helix::A_SovWhisper_ReloadRifleA',
            character_fire = 'helix::AM_Player_Fire_RecoilRifleA',
            character_reload = 'helix::AM_Player_ReloadRifleA',
            character_holster = 'helix::AM_Player_HolsteringRifleA',
            character_equip = 'helix::AM_Player_EquipRifleA'
        },
        magazine_mesh = 'helix::SM_AK47_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Regular',
        default_attachments = {
            mag = { asset_name = 'helix::SM_SovWhisper_Mag', relative_location = Vector(16, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            sight = { asset_name = 'helix::SM_SovWhisper_IronSight', relative_location = Vector(61, 0, 10), relative_rotation = Rotator(0, 0, 0) },
            reargrip = { asset_name = 'helix::SM_SovWhisper_RearGrip', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_SovWhisper_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    },
    weapon_vulcan = {
        ammo_type = 'smg_ammo',
        asset_name = 'helix::SK_Vulcan',
        damage = 15,
        spread = 75,
        recoil = 0.25,
        cadence = 0.075,
        auto_reload = false,
        ammo_settings = { ammo_clip = 30, ammo_bag = 100, ammo_to_reload = 0, clip_capacity = 30 },
        bullet_settings = { bullet_count = 1, bullet_max_distance = 30000, bullet_velocity = 30000, bullet_color = Color(100, 58, 0) },
        wallbang_settings = { max_distance = 200, damage_multiplier = 0.5 },
        handlingMode = HandlingMode.LongWeapon,
        left_hand_bone = 'b_gun_lefthand',
        right_hand_offset = Vector(1, 1, 0.5),
        particles = { bullet_trail = 'helix::P_Bullet_Trail', barrel = 'helix::P_Weapon_BarrelSmoke', shells = 'helix::P_Weapon_Shells_9x18' },
        sounds = {
            dry = 'helix::A_SMG_Dry',
            load = 'helix::A_SMG_Load',
            unload = 'helix::A_SMG_Unload',
            zooming = 'helix::A_AimZoom',
            aim = 'helix::A_Rattle',
            fire = 'helix::A_Vulcan_Shot_001',
            last_bullets = {
                asset_path = 'helix::A_SMG_Dry',
                bullet_count = 6
            }
        },
        animations = {
            fire = 'helix::A_AP5_Fire',
            reload = 'helix::',
            character_fire = 'helix::AM_Mannequin_Sight_Fire',
            character_reload = 'helix::AM_Mannequin_Reload_Rifle',
            character_holster = 'helix::',
            character_equip = 'helix::'
        },
        magazine_mesh = 'helix::SM_AP5_Mag_Empty',
        crosshair_material = 'helix::MI_Crosshair_Submachine',
        default_attachments = {
            mag = { asset_name = 'helix::SM_Vulcan_Mag', relative_location = Vector(17, 0, -7), relative_rotation = Rotator(0, 0, 0) },
            stock = { asset_name = 'helix::SM_Vulcan_Stock', relative_location = Vector(0, 0, 0), relative_rotation = Rotator(0, 0, 0) },
        }
    } ]]
}
