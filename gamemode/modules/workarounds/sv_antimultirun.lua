local kickMessage = [[You cannot join these server(s) twice with the same account.
If you're a developer, please disable antimultirun in the LynxonsRP config.
]]

local function clearServerEntries()
    MySQLite.query(string.format([[
        DELETE FROM LynxonsRP_serverplayer WHERE serverid = %s
    ]], MySQLite.SQLStr(LynxonsRP.serverId)))
end

local function insertSteamid64(steamid64, userid)
    local query = string.format([[
        INSERT INTO LynxonsRP_serverplayer VALUES(%s, %s)
    ]], steamid64, MySQLite.SQLStr(LynxonsRP.serverId))
    MySQLite.query(
        query,
        -- Ignore result of successful insertion
        function() end,
        -- Attempt to kick the user when insertion fails, as it means that
        -- the row already exists in the database.
        function(err)
            if not string.find(err, "Duplicate entry") then return end

            game.KickID(userid, kickMessage)
            return true
        end
    )
end

local function insertPlayer(ply)
    insertSteamid64(ply:SteamID64(), ply:UserID())
end

local function removePlayer(ply)
    MySQLite.query(string.format([[
        DELETE FROM LynxonsRP_serverplayer WHERE uid = %s AND serverid = %s
    ]], ply:SteamID64(), MySQLite.SQLStr(LynxonsRP.serverId)))
end

local function addHooks()
    hook.Add("PlayerAuthed", "LynxonsRP_antimultirun", function(ply, steamId)
        insertSteamid64(util.SteamIDTo64(steamId), ply:UserID())
    end)

    hook.Add("PlayerDisconnected", "LynxonsRP_antimultirun", removePlayer)
    hook.Add("ShutDown", "LynxonsRP_antimultirun", clearServerEntries)
end

hook.Add("LynxonsRPDBInitialized", "LynxonsRP_antimultirun", function()
    if not GAMEMODE.Config.antimultirun then return end
    if not MySQLite.isMySQL() then return end
    if not game.IsDedicated() then return end

    -- Wait until game.GetIPAddress() returns a sensible value
    -- https://github.com/FPtje/LynxonsRP/issues/2982
    -- https://github.com/Facepunch/garrysmod-issues/issues/3001
    hook.Add("Think", "LynxonsRP_antimultirun", function()
        LynxonsRP.serverId = game.GetIPAddress()
        if string.sub(LynxonsRP.serverId, 0, 8) == "0.0.0.0:" then return end
        hook.Remove("Think", "LynxonsRP_antimultirun")

        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS LynxonsRP_serverplayer(
                uid BIGINT NOT NULL,
                serverid VARCHAR(32) NOT NULL,
                PRIMARY KEY(uid, serverid)
            );
        ]])

        -- Clear this server's entries in case the server wasn't cleanly shut down
        clearServerEntries()

        -- Re-insert players currently in the game
        fn.Map(insertPlayer, player.GetAll())

        addHooks()
    end)
end)
