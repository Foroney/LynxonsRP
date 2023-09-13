LynxonsRP.ENTITY.getDoorData = LynxonsRP.stub{
    name = "getDoorData",
    description = "Internal function to get the door/vehicle data.",
    parameters = {
    },
    returns = {
        {
            name = "doordata",
            description = "All the LynxonsRP information on a door or vehicle.",
            type = "table"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isKeysOwnable = LynxonsRP.stub{
    name = "isKeysOwnable",
    description = "Whether this door can be bought.",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether the door can be bought.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isDoor = LynxonsRP.stub{
    name = "isDoor",
    description = "Whether this entity is considered a door in LynxonsRP.",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether it's a door.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isKeysOwned = LynxonsRP.stub{
    name = "isKeysOwned",
    description = "Whether this door is owned by someone.",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether it's owned.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getDoorOwner = LynxonsRP.stub{
    name = "getDoorOwner",
    description = "Get the owner of a door.",
    parameters = {
    },
    returns = {
        {
            name = "owner",
            description = "The owner of the door.",
            type = "Player"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isMasterOwner = LynxonsRP.stub{
    name = "isMasterOwner",
    description = "Whether the player is the main owner of the door (as opposed to a co-owner).",
    parameters = {
        {
            name = "ply",
            description = "The player to query.",
            type = "Player",
            optional = false
        }
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is the master owner.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isKeysOwnedBy = LynxonsRP.stub{
    name = "isKeysOwnedBy",
    description = "Whether this door is owned or co-owned by this player",
    parameters = {
        {
            name = "ply",
            description = "The player to query.",
            type = "Player",
            optional = false
        }
    },
    returns = {
        {
            name = "answer",
            description = "Whether this door is (co-)owned by the player.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.isKeysAllowedToOwn = LynxonsRP.stub{
    name = "isKeysAllowedToOwn",
    description = "Whether this player is allowed to co-own a door, as decided by the master door owner.",
    parameters = {
        {
            name = "ply",
            description = "The player to query.",
            type = "Player",
            optional = false
        }
    },
    returns = {
        {
            name = "answer",
            description = "Whether this door is (co-)ownable by the player.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysNonOwnable = LynxonsRP.stub{
    name = "getKeysNonOwnable",
    description = "Whether ownability of this door/vehicle is disabled.",
    parameters = {
    },
    returns = {
        {
            name = "title",
            description = "The ownability status.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysTitle = LynxonsRP.stub{
    name = "getKeysTitle",
    description = "Get the title of this door or vehicle.",
    parameters = {
    },
    returns = {
        {
            name = "title",
            description = "The title of the door or vehicle.",
            type = "string"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysDoorGroup = LynxonsRP.stub{
    name = "getKeysDoorGroup",
    description = "The door group of a door if it exists.",
    parameters = {
    },
    returns = {
        {
            name = "group",
            description = "The door group.",
            type = "string"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysDoorTeams = LynxonsRP.stub{
    name = "getKeysDoorTeams",
    description = "The teams that are allowed to open this door.",
    parameters = {
    },
    returns = {
        {
            name = "teams",
            description = "The door teams.",
            type = "table"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysAllowedToOwn = LynxonsRP.stub{
    name = "getKeysAllowedToOwn",
    description = "The list of people of which the master door owner has added as allowed to own.",
    parameters = {
    },
    returns = {
        {
            name = "players",
            description = "The list of people allowed to own.",
            type = "table"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.ENTITY.getKeysCoOwners = LynxonsRP.stub{
    name = "getKeysCoOwners",
    description = "The list of people who co-own the door.",
    parameters = {
    },
    returns = {
        {
            name = "players",
            description = "The list of people allowed to own. The keys of this table are UserIDs, the values are booleans.",
            type = "table"
        }
    },
    metatable = LynxonsRP.ENTITY
}

LynxonsRP.PLAYER.canKeysLock = LynxonsRP.stub{
    name = "canKeysLock",
    description = "Whether the player can lock a given door.",
    parameters = {
        {
            name = "door",
            description = "The door",
            optional = false,
            type = "Entity"
        }
    },
    returns = {
        {
            name = "allowed",
            description = "Whether the player is allowed to lock the door.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.canKeysUnlock = LynxonsRP.stub{
    name = "canKeysUnlock",
    description = "Whether the player can unlock a given door.",
    parameters = {
        {
            name = "door",
            description = "The door",
            optional = false,
            type = "Entity"
        }
    },
    returns = {
        {
            name = "allowed",
            description = "Whether the player is allowed to unlock the door.",
            type = "boolean"
        }
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.registerDoorVar = LynxonsRP.stub{
    name = "registerDoorVar",
    description = "Register a door variable by name. You should definitely register door variables. Registering LynxonsRPVars will make networking much more efficient.",
    parameters = {
        {
            name = "name",
            description = "The name of the door var.",
            type = "string",
            optional = false
        },
        {
            name = "writeFn",
            description = "The function that writes a value for this door var. Examples: net.WriteString, function(val) net.WriteUInt(val, 8) end.",
            type = "function",
            optional = false
        },
        {
            name = "readFn",
            description = "The function that reads and returns a value for this door var. Examples: net.ReadString, function() return net.ReadUInt(8) end.",
            type = "function",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.getDoorVars = LynxonsRP.stub{
    name = "getDoorVars",
    description = "Internal function, retrieves all the registered door variables.",
    parameters = {

    },
    returns = {
        {
            name = "doorvars",
            description = "The door variables, indexed by number",
            type = "table"
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.getDoorVarsByName = LynxonsRP.stub{
    name = "getDoorVarsByName",
    description = "Internal function, retrieves all the registered door variables, indeded by their names.",
    parameters = {

    },
    returns = {
        {
            name = "doorvars",
            description = "The door variables, indexed by name",
            type = "table"
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.hookStub{
    name = "canKeysLock",
    description = "Whether the player can lock a given door. This hook is run when ply:canKeysLock is called.",
    parameters = {
        {
            name = "ply",
            description = "The player",
            type = "Player"
        },
        {
            name = "door",
            description = "The door",
            type = "Entity"
        }
    },
    returns = {
        {
            name = "allowed",
            description = "Whether the player is allowed to lock the door.",
            type = "boolean"
        }
    }
}

LynxonsRP.hookStub{
    name = "canKeysUnlock",
    description = "Whether the player can unlock a given door. This hook is run when ply:canKeysUnlock is called.",
    parameters = {
        {
            name = "ply",
            description = "The player",
            type = "Player"
        },
        {
            name = "door",
            description = "The door",
            type = "Entity"
        }
    },
    returns = {
        {
            name = "allowed",
            description = "Whether the player is allowed to unlock the door.",
            type = "boolean"
        }
    }
}
