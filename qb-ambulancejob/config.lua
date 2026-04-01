local Lang = require('locales/en')

Config = {
    VehicleSpawn = { coords = Vector(0, 0, 0), heading = 0 },
    HelicopterSpawn = { coords = Vector(0, 0, 0), heading = 0 },
    Locations = {
        ['checking'] = {
            { coords = Vector(0, 0, 0) },
            { coords = Vector(0, 0, 0) }
        },
        ['duty'] = {
            { coords = Vector(0, 0, 0), rotation = Rotator(0, 0, 0) }
        },
        ['vehicle'] = {
            { coords = Vector(0, 0, 0) }
        },
        ['helicopter'] = {
            { coords = Vector(0, 0, 0) }
        },
        ['stash'] = {
            { coords = Vector(0, 0, 0) }
        },
        ['jailbeds'] = {
            { coords = Vector(0, 0, 0), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            { coords = Vector(0, 0, 0), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            { coords = Vector(0, 0, 0), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            { coords = Vector(0, 0, 0), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
        },
        ['hospital'] = {
            {
                ['name'] = Lang:t('info.pb_hospital'),
                ['location'] = Vector(0, 0, 0),
                ['beds'] = {
                    { coords = Vector(0, 0, 0), heading = 0, taken = false },
                    { coords = Vector(0, 0, 0), heading = 0, taken = false },
                    { coords = Vector(0, 0, 0), heading = 0, taken = false },
                    { coords = Vector(0, 0, 0), heading = 0, taken = false },
                    { coords = Vector(0, 0, 0), heading = 0, taken = false },
                },
            },
            -- {
            --     ['name'] = Lang:t('info.paleto_hospital'),
            --     ['location'] = Vector(-254.54, 6331.78, 32.43),
            --     ['beds'] = {
            --         { coords = Vector(-252.43, 6312.25, 32.34, 313.48), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            --         { coords = Vector(-247.04, 6317.95, 32.34, 134.64), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            --         { coords = Vector(-255.98, 6315.67, 32.34, 313.91), taken = false, model = '/Game/QBCore/Meshes/LP_HospitalBed.LP_HospitalBed' },
            --     },
            -- },
        },
        ['stations'] = {
            { label = Lang:t('info.pb_hospital'), coords = Vector(0, 0, 0) }
        }
    },

    AuthorizedVehicles = { -- Grade is key, don't add same vehicle in multiple grades. Higher rank can see lower
        [0] = {
            ['bp_ambulance'] = 'Ambulance'
        }
    },

    AuthorizedHelicopters = { -- Grade is key, don't add same vehicle in multiple grades. Higher rank can see lower
        [0] = {
            ['bp_aheli'] = 'EMS Heli'
        }
    },

    Bones = {
        ['Root'] = 'root',
        ['Hips'] = 'pelvis',
        ['Spine'] = 'spine_01',
        ['Spine1'] = 'spine_02',
        ['Spine2'] = 'spine_03',
        ['Spine3'] = 'spine_04',
        ['Spine4'] = 'spine_05',
        ['Neck'] = 'neck_01',
        ['Neck1'] = 'neck_02',
        ['Head'] = 'head',
        ['LeftShoulder'] = 'clavicle_l',
        ['RightShoulder'] = 'clavicle_r',
        ['LeftArm'] = 'upperarm_l',
        ['RightArm'] = 'upperarm_r',
        ['LeftArmTwist'] = 'upperarm_twist_01_l',
        ['RightArmTwist'] = 'upperarm_twist_01_r',
        ['LeftForeArm'] = 'lowerarm_l',
        ['RightForeArm'] = 'lowerarm_r',
        ['LeftForeArmTwist'] = 'lowerarm_twist_01_l',
        ['RightForeArmTwist'] = 'lowerarm_twist_01_r',
        ['LeftHand'] = 'hand_l',
        ['RightHand'] = 'hand_r',
        ['LeftThigh'] = 'thigh_l',
        ['RightThigh'] = 'thigh_r',
        ['LeftThighTwist'] = 'thigh_twist_01_l',
        ['RightThighTwist'] = 'thigh_twist_01_r',
        ['LeftCalf'] = 'calf_l',
        ['RightCalf'] = 'calf_r',
        ['LeftCalfTwist'] = 'calf_twist_01_l',
        ['RightCalfTwist'] = 'calf_twist_01_r',
        ['LeftFoot'] = 'foot_l',
        ['RightFoot'] = 'foot_r',
        ['LeftToeBase'] = 'ball_l',
        ['RightToeBase'] = 'ball_r',
        ['LeftHandThumb1'] = 'thumb_01_l',
        ['RightHandThumb1'] = 'thumb_01_r',
        ['LeftHandThumb2'] = 'thumb_02_l',
        ['RightHandThumb2'] = 'thumb_02_r',
        ['LeftHandThumb3'] = 'thumb_03_l',
        ['RightHandThumb3'] = 'thumb_03_r',
        ['LeftHandIndex1'] = 'index_01_l',
        ['RightHandIndex1'] = 'index_01_r',
        ['LeftHandIndex2'] = 'index_02_l',
        ['RightHandIndex2'] = 'index_02_r',
        ['LeftHandIndex3'] = 'index_03_l',
        ['RightHandIndex3'] = 'index_03_r',
        ['LeftHandMiddle1'] = 'middle_01_l',
        ['RightHandMiddle1'] = 'middle_01_r',
        ['LeftHandMiddle2'] = 'middle_02_l',
        ['RightHandMiddle2'] = 'middle_02_r',
        ['LeftHandMiddle3'] = 'middle_03_l',
        ['RightHandMiddle3'] = 'middle_03_r',
        ['LeftHandRing1'] = 'ring_01_l',
        ['RightHandRing1'] = 'ring_01_r',
        ['LeftHandRing2'] = 'ring_02_l',
        ['RightHandRing2'] = 'ring_02_r',
        ['LeftHandRing3'] = 'ring_03_l',
        ['RightHandRing3'] = 'ring_03_r',
        ['LeftHandPinky1'] = 'pinky_01_l',
        ['RightHandPinky1'] = 'pinky_01_r',
        ['LeftHandPinky2'] = 'pinky_02_l',
        ['RightHandPinky2'] = 'pinky_02_r',
        ['LeftHandPinky3'] = 'pinky_03_l',
        ['RightHandPinky3'] = 'pinky_03_r',
        ['LeftHandThumbMetacarpal'] = 'thumb_metacarpal_l',
        ['RightHandThumbMetacarpal'] = 'thumb_metacarpal_r',
        ['LeftHandIndexMetacarpal'] = 'index_metacarpal_l',
        ['RightHandIndexMetacarpal'] = 'index_metacarpal_r',
        ['LeftHandMiddleMetacarpal'] = 'middle_metacarpal_l',
        ['RightHandMiddleMetacarpal'] = 'middle_metacarpal_r',
        ['LeftHandRingMetacarpal'] = 'ring_metacarpal_l',
        ['RightHandRingMetacarpal'] = 'ring_metacarpal_r',
        ['LeftHandPinkyMetacarpal'] = 'pinky_metacarpal_l',
        ['RightHandPinkyMetacarpal'] = 'pinky_metacarpal_r',
        ['RightHandWeapon'] = 'weapon_r',
        ['LeftHandWeapon'] = 'weapon_l',
        ['IK_hand_root'] = 'ik_hand_root',
        ['IK_hand_gun'] = 'ik_hand_gun',
        ['IK_hand_l'] = 'ik_hand_l',
        ['IK_hand_r'] = 'ik_hand_r',
        ['IK_foot_root'] = 'ik_foot_root',
        ['IK_foot_l'] = 'ik_foot_l',
        ['IK_foot_r'] = 'ik_foot_r'
    }
}
