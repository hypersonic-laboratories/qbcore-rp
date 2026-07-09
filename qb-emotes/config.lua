Config = {}
Config.OpenKey = 'F1' -- key that opens the emote menu
Config.PairedRequestDistance = 250.0 -- max distance to the nearest player for a paired emote request
Config.PairedRequestTimeout = 15000 -- ms before a pending paired request expires

local BASE = '/HelixAnimation/Unified/Animations/'

-- Emote entries:
--   id        unique key within its category
--   label     shown in the menu
--   anim      full asset path
--   upperBody plays on the UpperBody slot so the player can keep walking
-- Emotes loop indefinitely until toggled off or another emote is started,
-- except in categories marked oneShot = true, where they play once and end
-- on their own.
Config.Categories = {
    {
        name = 'gestures',
        label = 'Gestures',
        icon = 'hand',
        oneShot = true,
        emotes = {
            { id = 'wave', label = 'Wave', anim = BASE .. 'Actions/A_Action_Wave.A_Action_Wave', upperBody = true },
            { id = 'nod', label = 'Nod', anim = BASE .. 'Actions/A_Action_Nod.A_Action_Nod', upperBody = true },
            { id = 'salute', label = 'Salute', anim = BASE .. 'Actions/A_Action_Salute.A_Action_Salute', upperBody = true },
            { id = 'shrug', label = 'Shrug', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Shrug_1.A_Shrug_1', upperBody = true },
            { id = 'shhh', label = 'Shhh', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Shhh_Long_RHand.A_Shhh_Long_RHand', upperBody = true },
            { id = 'question', label = 'Ask a Question', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Ask_Question.A_Ask_Question', upperBody = true },
            { id = 'apologize', label = 'Apologize', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Apologise.A_Apologise', upperBody = true },
            { id = 'noway', label = 'No Way', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Definitely_Not.A_Definitely_Not', upperBody = true },
            { id = 'notlistening', label = 'Not Listening', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Nope_Not_Listening.A_Nope_Not_Listening', upperBody = true },
            { id = 'kidding', label = 'Just Kidding', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Just_Kidding_Two_Hands.A_Just_Kidding_Two_Hands', upperBody = true },
            { id = 'youorme', label = 'You or Me?', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Me_or_You_RHand.A_Me_or_You_RHand', upperBody = true },
            { id = 'fingerguns', label = 'Finger Guns', anim = BASE .. 'Emote/MF_Emote_FingerGuns_Emote_MW.MF_Emote_FingerGuns_Emote_MW', upperBody = true },
            { id = 'chat', label = 'Chat', anim = BASE .. 'AwesomeDogMocap_Conversation/A_General_Chatting_LOOPED.A_General_Chatting_LOOPED', upperBody = true },
            { id = 'explain', label = 'Explain Impatiently', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Impatient_Explaining.A_Impatient_Explaining', upperBody = true },
        },
    },
    {
        name = 'reactions',
        label = 'Reactions',
        icon = 'zap',
        emotes = {
            { id = 'amazed', label = 'Amazed', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Amazed_Dramatic.A_Amazed_Dramatic' },
            { id = 'angry', label = 'Angry', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Angry.A_Angry' },
            { id = 'stomp', label = 'Stomp Around', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Angry_Stomping.A_Angry_Stomping' },
            { id = 'gasp', label = 'Gasp', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Gasp.A_Gasp', upperBody = true },
            { id = 'shocked', label = 'Shocked', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Shock_Step_Back.A_Shock_Step_Back' },
            { id = 'disbelief', label = 'Disbelief', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Disbelief.A_Disbelief', upperBody = true },
            { id = 'wow', label = 'Wow', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Wow.A_Wow' },
            { id = 'yuck', label = 'Yuck', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Yuck.A_Yuck', upperBody = true },
            { id = 'sigh', label = 'Big Sigh', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Big_Sigh.A_Big_Sigh', upperBody = true },
            { id = 'whyohwhy', label = 'Why Oh Why', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Why_Oh_Why.A_Why_Oh_Why' },
            { id = 'ponder', label = 'Ponder', anim = BASE .. 'AwesomeDogMocap_Conversation/A_Pondering.A_Pondering', upperBody = true },
            { id = 'eureka', label = 'Eureka!', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Urika_Moment.A_Urika_Moment' },
        },
    },
    {
        name = 'emotions',
        label = 'Emotions',
        icon = 'smile',
        emotes = {
            { id = 'cry', label = 'Cry', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Crying.A_Crying' },
            { id = 'sob', label = 'Sob Quietly', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Crying_Contained.A_Crying_Contained', upperBody = true },
            { id = 'laugh', label = 'Laugh', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Hysterical_Laugh_LOOP.A_Hysterical_Laugh_LOOP' },
            { id = 'giggle', label = 'Giggle', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Giggle_Stand.A_Giggle_Stand', upperBody = true },
            { id = 'happy', label = 'Happy Bounce', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Bouncy_Happy_Stand.A_Bouncy_Happy_Stand' },
            { id = 'joy', label = 'Jump for Joy', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Jumps_For_Joy.A_Jumps_For_Joy' },
            { id = 'excited', label = 'Excited', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Jump_About_Excited.A_Jump_About_Excited' },
            { id = 'depressed', label = 'Depressed', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Depressed.A_Depressed' },
            { id = 'ashamed', label = 'Ashamed', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Ashamed.A_Ashamed' },
            { id = 'bored', label = 'Bored', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Bored_Stand.A_Bored_Stand' },
            { id = 'confused', label = 'Confused', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Confused.A_Confused' },
            { id = 'worried', label = 'Worried', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Worried.A_Worried' },
            { id = 'handheart', label = 'Hand Heart', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Hand_Heart_1_EXTENDED.A_Hand_Heart_1_EXTENDED', upperBody = true },
            { id = 'fingerscrossed', label = 'Cross Fingers', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Cross_Fingers.A_Cross_Fingers', upperBody = true },
            { id = 'cool', label = 'Check Me Out', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Check_Me_Out_Im_Cool_.A_Check_Me_Out_Im_Cool_' },
            { id = 'thinking', label = 'Thinking', anim = BASE .. 'AwesomeDogMocap_EmotionGestures/A_Thinking.A_Thinking', upperBody = true },
        },
    },
    {
        name = 'dances',
        label = 'Dances',
        icon = 'music',
        emotes = {
            { id = 'club1', label = 'Club Dance 1', anim = BASE .. 'Club_Dance/A_ClubDance_01.A_ClubDance_01' },
            { id = 'club2', label = 'Club Dance 2', anim = BASE .. 'Club_Dance/A_ClubDance_02.A_ClubDance_02' },
            { id = 'club3', label = 'Club Dance 3', anim = BASE .. 'Club_Dance/A_ClubDance_03.A_ClubDance_03' },
            { id = 'club4', label = 'Club Dance 4', anim = BASE .. 'Club_Dance/A_ClubDance_04.A_ClubDance_04' },
            { id = 'casual1', label = 'Casual Dance 1', anim = BASE .. 'GenericNPCPack/A_Dance_1.A_Dance_1' },
            { id = 'casual2', label = 'Casual Dance 2', anim = BASE .. 'GenericNPCPack/A_Dance_2.A_Dance_2' },
            { id = 'dab', label = 'The Dab', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_The_Dab_Subtle.A_The_Dab_Subtle' },
            { id = 'dougie', label = 'The Dougie', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_The_Dougie.A_The_Dougie' },
            { id = 'runningman', label = 'Running Man', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Running_Man.A_Running_Man' },
            { id = 'twerk', label = 'Twerk', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Twerk.A_Twerk' },
            { id = 'makeitrain', label = 'Make It Rain', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Make_It_Rain.A_Make_It_Rain' },
            { id = 'shootdance', label = 'Shoot Dance', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Shoot_Dance.A_Shoot_Dance' },
            { id = 'stankyleg', label = 'Stanky Legg', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Stanky_Legg.A_Stanky_Legg' },
            { id = 'catdaddy', label = 'Cat Daddy', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Cat_Daddy.A_Cat_Daddy' },
            { id = 'sprinkler', label = 'The Sprinkler', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Hip_Hop_Sprinkler.A_Hip_Hop_Sprinkler' },
            { id = 'whipnaenae', label = 'Whip Nae Nae', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_WhipNaeNae1.A_WhipNaeNae1' },
            { id = 'drunkdance', label = 'Drunk Dance', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Drunk_Dance_1.A_Drunk_Dance_1' },
            { id = 'breakfail', label = 'Breakdance Fail', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Breakdance_Fail.A_Breakdance_Fail' },
            { id = 'smurf', label = 'Smurf Dance', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Smurf_Dance.A_Smurf_Dance' },
            { id = 'poplock', label = 'Pop Lock & Drop', anim = BASE .. 'AwesomeDogMocap_DancesSet1/A_Pop_Lock_And_Drop.A_Pop_Lock_And_Drop' },
        },
    },
    {
        name = 'poses',
        label = 'Poses & Idles',
        icon = 'user',
        emotes = {
            { id = 'handsonwaist', label = 'Hands on Waist', anim = BASE .. 'GenericNPCPack/A_Idle_Hands_On_Waist.A_Idle_Hands_On_Waist' },
            { id = 'armscrossed', label = 'Arms Crossed', anim = BASE .. 'GenericNPCPack/A_Idle_Hands_Crossed.A_Idle_Hands_Crossed' },
            { id = 'leanwall', label = 'Lean Against Wall', anim = BASE .. 'GenericNPCPack/A_Idle_Wall_1.A_Idle_Wall_1' },
            { id = 'leanforward', label = 'Lean on Railing', anim = BASE .. 'GenericNPCPack/A_Idle_Lean_Forward_1.A_Idle_Lean_Forward_1' },
            { id = 'checkphone', label = 'Check Phone', anim = BASE .. 'GenericNPCPack/A_Check_Cellphone.A_Check_Cellphone', upperBody = true },
            { id = 'phonecall', label = 'Phone Call', anim = BASE .. 'GenericNPCPack/A_Talking_On_The_Phone_Loop.A_Talking_On_The_Phone_Loop', upperBody = true },
            { id = 'takepicture', label = 'Take a Picture', anim = BASE .. 'GenericNPCPack/A_Taking_Picture.A_Taking_Picture', upperBody = true },
            { id = 'phonemusic', label = 'Play Music From Phone', anim = BASE .. 'GenericNPCPack/A_Music_From_Phone.A_Music_From_Phone' },
            { id = 'makeup', label = 'Do Makeup', anim = BASE .. 'GenericNPCPack/A_Female_Makeup.A_Female_Makeup', upperBody = true },
            { id = 'hailtaxi', label = 'Hail a Taxi', anim = BASE .. 'GenericNPCPack/A_Call_Taxi_1.A_Call_Taxi_1', upperBody = true },
        },
    },
    {
        name = 'sitting',
        label = 'Sitting & Sleeping',
        icon = 'armchair',
        emotes = {
            { id = 'sitchair', label = 'Sit on Chair', anim = BASE .. 'Actions/Sitting/A_Sitting_OnChair_Loop.A_Sitting_OnChair_Loop' },
            { id = 'sitground', label = 'Sit on Ground', anim = BASE .. 'Actions/Sitting/A_Sitting_OnFloor_Loop.A_Sitting_OnFloor_Loop' },
            { id = 'sitfloor', label = 'Sit Casually', anim = BASE .. 'GenericNPCPack/A_Sit_Floor_1.A_Sit_Floor_1' },
            { id = 'sitcrossed', label = 'Sit Cross-Legged', anim = BASE .. 'GenericNPCPack/A_Sit_LegsCrossed.A_Sit_LegsCrossed' },
            { id = 'sitsad', label = 'Sit Sad', anim = BASE .. 'GenericNPCPack/A_Sit_Sad.A_Sit_Sad' },
            { id = 'sitphone', label = 'Sit & Use Phone', anim = BASE .. 'GenericNPCPack/A_Sit_Use_Phone.A_Sit_Use_Phone' },
            { id = 'liedown', label = 'Lie Down', anim = BASE .. 'GenericNPCPack/A_Sit_Laydown.A_Sit_Laydown' },
            { id = 'sleepfloor', label = 'Sleep on Floor', anim = BASE .. 'GenericNPCPack/A_Sleep_Floor_1.A_Sleep_Floor_1' },
            { id = 'sleepside', label = 'Sleep on Side', anim = BASE .. 'SleepAnimPack/Sleep_Floor/A_Sleep_FloorBed_RightSide_SleepLoop.A_Sleep_FloorBed_RightSide_SleepLoop' },
        },
    },
    {
        name = 'scenarios',
        label = 'Scenarios',
        icon = 'drama',
        emotes = {
            { id = 'handsup', label = 'Hands Up', anim = BASE .. 'FearFrights/A_Hostage.A_Hostage' },
            { id = 'handsbehindhead', label = 'Hands Behind Head', anim = BASE .. 'FearFrights/A_Hostage2.A_Hostage2' },
            { id = 'beg', label = 'Beg', anim = BASE .. 'FearFrights/A_Supplication.A_Supplication' },
            { id = 'plead', label = 'Plead', anim = BASE .. 'FearFrights/A_DontDoThis.A_DontDoThis' },
            { id = 'scared', label = 'Scared', anim = BASE .. 'FearFrights/A_LightFright.A_LightFright' },
            { id = 'hidefear', label = 'Hide in Fear', anim = BASE .. 'FearFrights/A_StealthilyAfraid.A_StealthilyAfraid' },
            { id = 'bound', label = 'Bound Hostage', anim = BASE .. 'FearFrights/A_BoundHostage.A_BoundHostage' },
            { id = 'playcards', label = 'Play Cards', anim = BASE .. 'CasinoAnimations/A_PlayingCards.A_PlayingCards' },
            { id = 'dealcards', label = 'Deal Cards', anim = BASE .. 'CasinoAnimations/A_DealingCards.A_DealingCards' },
            { id = 'guard', label = 'Stand Guard', anim = BASE .. 'CasinoAnimations/A_Security.A_Security' },
            { id = 'drink', label = 'Drink Bottle', anim = BASE .. 'Actions/Consumables/A_Drinking_Bottle.A_Drinking_Bottle', upperBody = true },
            { id = 'stuffmoney', label = 'Stuff Money', anim = BASE .. 'Actions/Stealing/A_StuffMoney_01.A_StuffMoney_01', upperBody = true },
        },
    },
}

-- Paired emotes send a request to the nearest player. When accepted, the
-- server positions the target relative to the requester and plays both
-- sides of the animation.
--   att / vic  { start = <one-shot intro>, loop = <looping anim> } — loop is
--              optional; when omitted the emote plays once and cleans up
--              after `duration` ms.
--   distance   forward offset (units) from the requester where the target is placed
--   right      sideways offset from the requester
--   vicYaw     heading offset applied to the target relative to the requester
--              (180 = face each other, 0 = face the same way)
local PAIRED = BASE .. 'Couples_Anim_Pack/'

Config.PairedEmotes = {
    {
        id = 'hug',
        label = 'Hug',
        icon = 'heart',
        att = { start = PAIRED .. 'A_Paired_Couple_Hug_Start_Att.A_Paired_Couple_Hug_Start_Att', loop = PAIRED .. 'A_Paired_Couple_Hug_Loop_Att.A_Paired_Couple_Hug_Loop_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_Hug_Start_Vic.A_Paired_Couple_Hug_Start_Vic', loop = PAIRED .. 'A_Paired_Couple_Hug_Loop_Vic.A_Paired_Couple_Hug_Loop_Vic' },
        distance = 80,
        vicYaw = 180,
    },
    {
        id = 'hugkiss',
        label = 'Hug & Kiss',
        icon = 'heart-handshake',
        att = { start = PAIRED .. 'A_Paired_Couple_HugNKiss_Start_Att.A_Paired_Couple_HugNKiss_Start_Att', loop = PAIRED .. 'A_Paired_Couple_HugNKiss_Loop_Att.A_Paired_Couple_HugNKiss_Loop_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_HugNKiss_Start_Vic.A_Paired_Couple_HugNKiss_Start_Vic', loop = PAIRED .. 'A_Paired_Couple_HugNKiss_Loop_Vic.A_Paired_Couple_HugNKiss_Loop_Vic' },
        distance = 80,
        vicYaw = 180,
    },
    {
        id = 'backhug',
        label = 'Back Hug',
        icon = 'heart',
        att = { start = PAIRED .. 'A_Paired_Couple_BackHug_Start_Att.A_Paired_Couple_BackHug_Start_Att', loop = PAIRED .. 'A_Paired_Couple_BackHug_Loop_Att.A_Paired_Couple_BackHug_Loop_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_BackHug_Start_Vic.A_Paired_Couple_BackHug_Start_Vic', loop = PAIRED .. 'A_Paired_Couple_BackHug_Loop_Vic.A_Paired_Couple_BackHug_Loop_Vic' },
        distance = 45,
        vicYaw = 0,
    },
    {
        id = 'armaround',
        label = 'Arm Around Shoulder',
        icon = 'users',
        att = { start = PAIRED .. 'A_Paired_Couple_ArmsAroundShoulder_Start_Att.A_Paired_Couple_ArmsAroundShoulder_Start_Att', loop = PAIRED .. 'A_Paired_Couple_ArmsAroundShoulder_Loop_Att.A_Paired_Couple_ArmsAroundShoulder_Loop_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_ArmsAroundShoulder_Start_Vic.A_Paired_Couple_ArmsAroundShoulder_Start_Vic', loop = PAIRED .. 'A_Paired_Couple_ArmsAroundShoulder_Loop_Vic.A_Paired_Couple_ArmsAroundShoulder_Loop_Vic' },
        distance = 0,
        right = 55,
        vicYaw = 0,
    },
    {
        id = 'kisscheek',
        label = 'Kiss on Cheek',
        icon = 'heart',
        att = { start = PAIRED .. 'A_Paired_Couple_KissOnCheek01_Att.A_Paired_Couple_KissOnCheek01_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_KissOnCheek01_Vic.A_Paired_Couple_KissOnCheek01_Vic' },
        distance = 70,
        vicYaw = 180,
        duration = 6000,
    },
    {
        id = 'smooch',
        label = 'Quick Smooch',
        icon = 'heart',
        att = { start = PAIRED .. 'A_Paired_Couple_QuickSmooch_01_Att.A_Paired_Couple_QuickSmooch_01_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_QuickSmooch_01_Vic.A_Paired_Couple_QuickSmooch_01_Vic' },
        distance = 70,
        vicYaw = 180,
        duration = 6000,
    },
    {
        id = 'proposal',
        label = 'Proposal',
        icon = 'gem',
        att = { start = PAIRED .. 'A_Paired_Couple_Proposal_Start_Att.A_Paired_Couple_Proposal_Start_Att', loop = PAIRED .. 'A_Paired_Couple_Proposal_Loop_Att.A_Paired_Couple_Proposal_Loop_Att' },
        vic = { start = PAIRED .. 'A_Paired_Couple_Proposal_Start_Vic.A_Paired_Couple_Proposal_Start_Vic', loop = PAIRED .. 'A_Paired_Couple_Proposal_Loop_Vic.A_Paired_Couple_Proposal_Loop_Vic' },
        distance = 110,
        vicYaw = 180,
    },
}
