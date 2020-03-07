--[[ 
    @ Title : NodeQuery Agent
    @ Desc : A NodeQuery Agent Lua Script For NodeQuery.com Running On HammerSpoon.
    @ Copyright : IcedMango @ GitHub
    @ ModifyDate: 2020-03-06 21:11:37
    @ All Right Reserved.
--]] -- Your API Goes Here, Get On -> https://nodequery.com/settings/api
local token = {'token1', 'token2'}
local loadAll;
local menubar = hs.menubar.new()
local menuData = {}
local config = {
    -- load percent mode, shows percentage only
    loadPercent = true,
    -- ram percent mode, shows percentage only
    ramPercent = true,
    -- disk percent mode, shows percentage only
    diskPercent = true
}

-- validate token
function validateToken(p)
    httpStatus, body, header = hs.http.doRequest(
                                   "https://nodequery.com/api/servers?api_key=" ..
                                       p, "GET", nil, nil)
    if httpStatus == 200 then
        data = hs.json.decode(body)
        if data.status == "OK" then loadServer(p) end
    end
end

-- load basic server info
function loadServer(p)
    httpStatus, body, header = hs.http.doRequest(
                                   "https://nodequery.com/api/servers?api_key=" ..
                                       p, "GET", nil, nil)
    if httpStatus ~= 200 then
        print('Api Server Error!' .. code)
        return
    end
    data = hs.json.decode(body)
    for k, v in pairs(data.data) do
        if type(v) == "table" then
            for index, value in pairs(v) do insertMenuItem(value) end
        end
    end
end

function insertMenuItem(value)
    local str = ""

    -- handle online status
    local online = ""
    if value.status == "active" then
        online = "✅"
    else
        online = "❌"
    end

    -- handle load 
    local load = ""
    if (config.loadPercent) then
        load = string.format("%s%%", value.load_percent)
    else
        load = string.format("%s", value.load_average)
    end

    -- handle ram
    local ram = ""
    if (config.ramPercent) then
        ram = string.format("%0.2f%%(%0.2fM)",
                            value.ram_usage / value.ram_total * 100,
                            value.ram_usage / 1024 / 1024)
    else
        ram = string.format("%0.2fM / %0.2fM", value.ram_usage / 1024 / 1024,
                            value.ram_total / 1024 / 1024)
    end

    -- handle disk
    local disk = ""
    if (config.diskPercent) then
        disk = string.format("%0.2f%%(%0.2fG)",
                             value.disk_usage / value.disk_total * 100,
                             value.disk_usage / 1024 / 1024 / 1024)
    else
        disk = string.format("%0.2fG / %0.2fG",
                             value.disk_usage / 1024 / 1024 / 1024,
                             value.disk_total / 1024 / 1024 / 1024)
    end

    -- handle network  
    -- if network bandwith is less than 100KB/s use KB/s
    -- if network bandwith is more than 1KB/s use MB/s
    local networkIn = ""
    if (value.current_rx / 1024 / 1024 < 100) then
        networkIn = string.format("%0.2f KB/s", value.current_rx / 1024 / 1024)
    else
        networkIn = string.format("%0.2f MB/s",
                                  value.current_tx / 1024 / 1024 / 1024)
    end

    local networkOut = ""
    if (value.current_tx / 1024 / 1024 < 100) then
        networkOut = string.format("%0.2f KB/s", value.current_tx / 1024 / 1024)
    else
        networkOut = string.format("%0.2f MB/s",
                                   value.current_tx / 1024 / 1024 / 1024)
    end

    str = string.format("%s|%s | ⚓%s | 🕹️%s | 💾 %s | ↓ %s | ↑ %s",
                        online, value.name, load, ram, disk, networkIn,
                        networkOut)

    item = {title = str}
    table.insert(menuData, item)
    menubar:setMenu(menuData)
end

loadAll = function()
    menubar:setTitle('⌛Loading')
    menuData = {
        {
            title = "Reload [Update Time:" .. os.date("%Y-%m-%d %H:%M:%S") ..
                "]",
            fn = function() loadAll() end
        }, {title = "-"}
    }
    hs.timer.doAfter(0.2, function()
        for k, v in ipairs(token) do
            if (v ~= nil) then validateToken(v) end
        end

        menubar:setTitle("☋ NodeQuery")
    end)

end

loadAll()
timer = hs.timer.doEvery(180, loadAll)
timer:start()
