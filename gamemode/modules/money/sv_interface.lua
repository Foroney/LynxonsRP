LynxonsRP.PLAYER.addMoney = LynxonsRP.stub{
    name = "addMoney",
    description = "Give money to a player.",
    parameters = {
        {
            name = "amount",
            description = "The amount of money to give to the player. A negative amount means you're substracting money.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.payDay = LynxonsRP.stub{
    name = "payDay",
    description = "Give a player their salary.",
    parameters = {
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}


LynxonsRP.payPlayer = LynxonsRP.stub{
    name = "payPlayer",
    description = "Make one player give money to the other player.",
    parameters = {
        {
            name = "sender",
            description = "The player who gives the money.",
            type = "Player",
            optional = false
        },
        {
            name = "receiver",
            description = "The player who receives the money.",
            type = "Player",
            optional = false
        },
        {
            name = "amount",
            description = "The amount of money.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.createMoneyBag = LynxonsRP.stub{
    name = "createMoneyBag",
    description = "Create a money bag.",
    parameters = {
        {
            name = "pos",
            description = "The The position where the money bag is to be spawned.",
            type = "Vector",
            optional = false
        },
        {
            name = "amount",
            description = "The amount of money.",
            type = "number",
            optional = false
        }
    },
    returns = {
        {
            name = "moneybag",
            description = "The money bag entity.",
            type = "Entity"
        }
    },
    metatable = LynxonsRP
}
