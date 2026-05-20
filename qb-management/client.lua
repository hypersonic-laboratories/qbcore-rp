local Lang = require('locales/en')
local PlayerJob = {}
local PlayerGang = {}
local sharedJobs = exports['qb-core']:GetShared('Jobs')
local sharedGangs = exports['qb-core']:GetShared('Gangs')

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    local player_data = exports['qb-core']:GetPlayerData()
    PlayerJob = player_data.job
    PlayerGang = player_data.gang
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterClientEvent('QBCore:Client:OnGangUpdate', function(InfoGang)
    PlayerGang = InfoGang
end)

-- Events

RegisterClientEvent('qb-management:client:openBossMenu', function()
    if not PlayerJob.name or not PlayerJob.isboss then return end

    local bossMenu = {
        {
            header = Lang.t('headers.bsm') .. string.upper(PlayerJob.label),
            icon = 'circle-info',
            isMenuHeader = true,
        },
        {
            header = Lang.t('body.manage'),
            txt = Lang.t('body.managed'),
            icon = 'list',
            params = {
                event = 'qb-management:client:employeelist',
            }
        },
        {
            header = Lang.t('body.hire'),
            txt = Lang.t('body.hired'),
            icon = 'hand-holding',
            params = {
                event = 'qb-management:client:HireMenu',
            }
        },
        {
            header = Lang.t('body.storage'),
            txt = Lang.t('body.storaged'),
            icon = 'box-open',
            params = {
                isServer = true,
                event = 'qb-management:server:jobStash',
            }
        },
        {
            header = Lang.t('body.outfits'),
            txt = Lang.t('body.outfitsd'),
            icon = 'shirt',
            params = {
                event = 'qb-management:client:Wardrobe',
            }
        }
    }

    bossMenu[#bossMenu + 1] = {
        header = Lang.t('body.exit'),
        icon = 'angle-left',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }

    exports['qb-menu']:openMenu(bossMenu)
end)

RegisterClientEvent('qb-management:client:OpenGangMenu', function()
    if not PlayerGang.name then return end
    local gangMenu = {
        {
            header = Lang.t('headersgang.bsm') .. string.upper(PlayerGang.label),
            icon = 'circle-info',
            isMenuHeader = true,
        },
        {
            header = Lang.t('bodygang.manage'),
            txt = Lang.t('bodygang.managed'),
            icon = 'list',
            params = {
                event = 'qb-management:client:ManageGang',
            }
        },
        {
            header = Lang.t('bodygang.hire'),
            txt = Lang.t('bodygang.hired'),
            icon = 'hand-holding',
            params = {
                event = 'qb-management:client:HireMembers',
            }
        },
        {
            header = Lang.t('bodygang.storage'),
            txt = Lang.t('bodygang.storaged'),
            icon = 'box-open',
            params = {
                isServer = true,
                event = 'qb-management:server:gangStash',
            }
        },
        {
            header = Lang.t('bodygang.outfits'),
            txt = Lang.t('bodygang.outfitsd'),
            icon = 'shirt',
            params = {
                event = 'qb-management:client:Warbobe',
            }
        }
    }

    gangMenu[#gangMenu + 1] = {
        header = Lang.t('bodygang.exit'),
        icon = 'angle-left',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }

    exports['qb-menu']:openMenu(gangMenu)
end)

RegisterClientEvent('qb-management:client:employeelist', function()
    local EmployeesMenu = {
        {
            header = Lang.t('body.mempl') .. string.upper(PlayerJob.label),
            isMenuHeader = true,
            icon = 'circle-info',
        },
    }
    TriggerCallback('GetEmployees', function(cb)
        for _, v in pairs(cb) do
            EmployeesMenu[#EmployeesMenu + 1] = {
                header = v.name,
                txt = v.grade.name,
                icon = 'circle-user',
                params = {
                    event = 'qb-management:client:ManageEmployee',
                    args = {
                        player = v,
                        work = PlayerJob
                    }
                }
            }
        end
        EmployeesMenu[#EmployeesMenu + 1] = {
            header = Lang.t('body.return'),
            icon = 'angle-left',
            params = {
                event = 'qb-management:client:openBossMenu',
            }
        }
        exports['qb-menu']:openMenu(EmployeesMenu)
    end, PlayerJob.name)
end)

RegisterClientEvent('qb-management:client:ManageEmployee', function(data)
    local EmployeeMenu = {
        {
            header = Lang.t('body.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerJob.label),
            isMenuHeader = true,
            icon = 'circle-info'
        },
    }
    for k, v in pairs(sharedJobs[data.work.name].grades) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            header = v.name,
            txt = Lang.t('body.grade') .. k,
            params = {
                isServer = true,
                event = 'qb-management:server:GradeUpdate',
                icon = 'file-pen',
                args = {
                    cid = data.player.empSource,
                    grade = tonumber(k),
                    gradename = v.name
                }
            }
        }
    end
    EmployeeMenu[#EmployeeMenu + 1] = {
        header = Lang.t('body.fireemp'),
        icon = 'user-large-slash',
        params = {
            isServer = true,
            event = 'qb-management:server:FireEmployee',
            args = data.player.empSource
        }
    }
    EmployeeMenu[#EmployeeMenu + 1] = {
        header = Lang.t('body.return'),
        icon = 'angle-left',
        params = {
            event = 'qb-management:client:openBossMenu',
        }
    }
    exports['qb-menu']:openMenu(EmployeeMenu)
end)

RegisterClientEvent('qb-management:client:ManageGang', function()
    local GangMembersMenu = {
        {
            header = Lang.t('bodygang.mempl') .. string.upper(PlayerGang.label),
            icon = 'circle-info',
            isMenuHeader = true,
        },
    }
    TriggerCallback('GetMembers', function(cb)
        for _, v in pairs(cb) do
            GangMembersMenu[#GangMembersMenu + 1] = {
                header = v.name,
                txt = v.grade.name,
                icon = 'circle-user',
                params = {
                    event = 'qb-management:client:ManageMember',
                    args = {
                        player = v,
                        work = PlayerGang
                    }
                }
            }
        end
        GangMembersMenu[#GangMembersMenu + 1] = {
            header = Lang.t('bodygang.return'),
            icon = 'angle-left',
            params = {
                event = 'qb-management:client:OpenGangMenu',
            }
        }
        exports['qb-menu']:openMenu(GangMembersMenu)
    end, PlayerGang.name)
end)

RegisterClientEvent('qb-management:client:ManageMember', function(data)
    local MemberMenu = {
        {
            header = Lang.t('bodygang.mngpl') .. data.player.name .. ' - ' .. string.upper(PlayerGang.label),
            isMenuHeader = true,
            icon = 'circle-info',
        },
    }
    for k, v in pairs(sharedGangs[data.work.name].grades) do
        MemberMenu[#MemberMenu + 1] = {
            header = v.name,
            txt = Lang.t('bodygang.grade') .. k,
            params = {
                isServer = true,
                event = 'qb-management:server:GradeUpdateGang',
                icon = 'file-pen',
                args = {
                    cid = data.player.empSource,
                    grade = tonumber(k),
                    gradename = v.name
                }
            }
        }
    end
    MemberMenu[#MemberMenu + 1] = {
        header = Lang.t('bodygang.fireemp'),
        icon = 'user-large-slash',
        params = {
            isServer = true,
            event = 'qb-management:server:FireMember',
            args = data.player.empSource
        }
    }
    MemberMenu[#MemberMenu + 1] = {
        header = Lang.t('bodygang.return'),
        icon = 'angle-left',
        params = {
            event = 'qb-management:client:ManageGang',
        }
    }
    exports['qb-menu']:openMenu(MemberMenu)
end)

RegisterClientEvent('qb-management:client:HireMenu', function()
    local HireMenu = {
        {
            header = Lang.t('body.hireemp') .. string.upper(PlayerJob.label),
            isMenuHeader = true,
            icon = 'circle-info',
        },
    }
    TriggerCallback('GetPlayers', function(players)
        for _, v in pairs(players) do
            HireMenu[#HireMenu + 1] = {
                header = v.name,
                txt = Lang.t('body.cid') .. v.citizenid,
                icon = 'user-check',
                params = {
                    isServer = true,
                    event = 'qb-management:server:HireEmployee',
                    args = v.citizenid
                }
            }
        end
        HireMenu[#HireMenu + 1] = {
            header = Lang.t('body.return'),
            icon = 'angle-left',
            params = {
                event = 'qb-management:client:openBossMenu',
            }
        }
        exports['qb-menu']:openMenu(HireMenu)
    end)
end)

RegisterClientEvent('qb-management:client:HireMembers', function()
    local HireMembersMenu = {
        {
            header = Lang.t('bodygang.hireemp') .. string.upper(PlayerGang.label),
            isMenuHeader = true,
            icon = 'circle-info',
        },
    }
    TriggerCallback('GetPlayers', function(players)
        for _, v in pairs(players) do
            HireMembersMenu[#HireMembersMenu + 1] = {
                header = v.name,
                txt = Lang.t('bodygang.cid') .. v.citizenid .. ' - ID: ' .. v.source,
                icon = 'user-check',
                params = {
                    isServer = true,
                    event = 'qb-management:server:HireMember',
                    args = v.source
                }
            }
        end
        HireMembersMenu[#HireMembersMenu + 1] = {
            header = Lang.t('bodygang.return'),
            icon = 'angle-left',
            params = {
                event = 'qb-management:client:OpenGangMenu',
            }
        }
        exports['qb-menu']:openMenu(HireMembersMenu)
    end)
end)

-- Target

Timer.SetTimeout(function()
    for job, zones in pairs(Config.BossMenus) do
        for index, coords in ipairs(zones) do
            local zoneName = job .. '_bossmenu_' .. index
            exports['qb-target']:AddSphereZone(zoneName, coords, 100, {
                debug = true,
                distance = 1000
            }, {
                {
                    icon = 'sign-in-alt',
                    event = 'qb-management:client:openBossMenu',
                    label = Lang.t('target.label'),
                },
            })
        end
    end

    for gang, zones in pairs(Config.GangMenus) do
        for index, coords in ipairs(zones) do
            local zoneName = gang .. '_gangmenu_' .. index
            exports['qb-target']:AddSphereZone(zoneName, coords, 100, {
                debug = true,
                distance = 1000
            }, {
                {
                    icon = 'sign-in-alt',
                    event = 'qb-management:client:OpenGangMenu',
                    label = Lang.t('targetgang.label'),
                },
            })
        end
    end
end, 5000)
