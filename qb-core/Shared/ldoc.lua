---@class QBCore.CharInfo
---@field public firstname string the character's first name
---@field public lastname string the character's last name
---@field public birthdate string the character's birthdate in the format "DD-MM-YYYY"
---@field public gender number the character's gender (0 for male?)
---@field public nationality string the character's nationality
---@field public phone string the character's phone number
---@field public account string the character's bank account number

---@class QBCore.JobInfo
---@field public name string the job's name/identifier
---@field public label string the job's label/display name
---@field public payment number the job's payment amount
---@field public type string the job's type/category (default: 'none')
---@field public onduty boolean whether the player is on duty for this job
---@field public isboss boolean whether the player is the boss of this job
---@field public grade QBCore.Grade the job grade information

---@class QBCore.Grade
---@field public name string the grade's name/label
---@field public level number the grade's level

---@class QBCore.GangInfo
---@field public name string the gang's name/identifier
---@field public label string the gang's label/display name
---@field public isboss boolean whether the player is the boss of this gang
---@field public grade QBCore.Grade the gang grade information

---@class QBCore.PlayerData
---@field public netId number the player's network ID
---@field public license string the player's helix license identifier
---@field public name string the player's helix name (this is NOT the character name)
---@field public source HPlayer the HPlayer object of the player (see HELIX documentation for more info)
---@field public citizenid string the player's citizen ID
---@field public cid number (set to 1 by default) *no idea what this actually represents*
---@field public money table<string, number> a table containing the player's money amounts for each money type (see QBCore.Config.Money.MoneyTypes)
---@field public optin boolean (set to true by default) *no idea what this actually represents*
---@field public charinfo QBCore.CharInfo the character information of the player
---@field public job QBCore.JobInfo the job information of the player
---@field public gang QBCore.GangInfo the gang information of the player

---@class QBCore.CriminalRecord
---@field public hasRecord boolean whether the player has a criminal record
---@field public date string? the date of the record (when it was created)

---@class QBCore.Inside
---@field public house string? the house identifier if the player is inside a house
---@field public apartment QBCore.Inside.Apartment the apartment information. This is always present, but the fields inside may be nil if not applicable.

---@class QBCore.Inside.Apartment
---@field public apartmentType string the type of apartment
---@field public apartmentId string the unique identifier of the apartment

---@class QBCore.PhoneData
---@field public SerialNumber string the phone's serial number
---@field public InstalledApps table the apps installed on the phone (I guess the format is table<string, boolean> or table<string> but not sure)

---@class QBCore.Metadata
---@field public hunger number the player's hunger level
---@field public thirst number the player's thirst level
---@field public stress number the player's stress level
---@field public isdead boolean whether the player is dead
---@field public inlaststand boolean whether the player is in last stand (downed, but can be revived)
---@field public armor number the player's armor level
---@field public ishandcuffed boolean whether the player is handcuffed
---@field public tracker boolean whether the player's tracker is active
---@field public injail boolean whether the player is in jail
---@field public jailitems table<string, any> the players items in jail (not sure about this format)
---@field public status table not sure what this is or if the format is correct, but it is a table
---@field public phone table not sure what this is or if the format is correct, but it is a table
---@field public rep table not sure what this is or if the format is correct, but it is a table
---@field public currentapartment string? the apartment the player is currently in, if any? not sure about this description
---@field public callsign string the player's callsign (default: 'NO CALLSIGN')
---@field public bloodtype string the player's blood type (see QBCore.Config.Bloodtypes)
---@field public fingerprint string the player's fingerprint identifier
---@field public walletid string the player's wallet ID (not sure what exactly this is...)
---@field public criminalrecord QBCore.CriminalRecord the player's criminal record information
---@field public licences table<string, boolean> a table containing the player's licences and whether they have them (default: driver = true, business = false, weapon = false)
---@field public inside QBCore.Inside the information about whether the player is inside a house or apartment
---@field public phonedata QBCore.PhoneData the player's phone data
---@field public position Vector the players position as a vector (see HELIX documentation for more information)
---@field public items table probably table<string, number> but not sure, the player's items