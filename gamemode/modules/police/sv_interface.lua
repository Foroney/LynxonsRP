LynxonsRP.lockdown = LynxonsRP.stub{
    name = "lockdown",
    description = "Start a lockdown.",
    parameters = {
        {
            name = "ply",
            description = "The player who initiated the lockdown.",
            type = "Player",
            optional = false
        }
    },
    returns = {
        {
            name = "str",
            description = "Empty string (since it's a called in a chat command)",
            type = "string"
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.unLockdown = LynxonsRP.stub{
    name = "unLockdown",
    description = "Stop the lockdown.",
    parameters = {
        {
            name = "ply",
            description = "The player who stopped the lockdown.",
            type = "Player",
            optional = false
        }
    },
    returns = {
        {
            name = "str",
            description = "Empty string (since it's a called in a chat command)",
            type = "string"
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.PLAYER.requestWarrant = LynxonsRP.stub{
    name = "requestWarrant",
    description = "File a request for a search warrant.",
    parameters = {
        {
            name = "suspect",
            description = "The player who is suspected.",
            type = "Player",
            optional = false
        },
        {
            name = "actor",
            description = "The player who wants the warrant.",
            type = "Player",
            optional = false
        },
        {
            name = "reason",
            description = "The reason for the warrant.",
            type = "string",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.warrant = LynxonsRP.stub{
    name = "warrant",
    description = "Get a search warrant for this person.",
    parameters = {
        {
            name = "warranter",
            description = "The player who set the warrant.",
            type = "Player",
            optional = false
        },
        {
            name = "reason",
            description = "The reason for the warrant.",
            type = "string",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.unWarrant = LynxonsRP.stub{
    name = "unWarrant",
    description = "Remove the search warrant for this person.",
    parameters = {
        {
            name = "unwarranter",
            description = "The player who removed the warrant.",
            type = "Player",
            optional = true
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.wanted = LynxonsRP.stub{
    name = "wanted",
    description = "Make this person wanted by the police.",
    parameters = {
        {
            name = "actor",
            description = "The player who made the other person wanted.",
            type = "Player",
            optional = false
        },
        {
            name = "reason",
            description = "The reason for the wanted status.",
            type = "string",
            optional = false
        },
        {
            name = "time",
            description = "The time in seconds for which the player should be wanted.",
            type = "number",
            optional = true
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.unWanted = LynxonsRP.stub{
    name = "unWanted",
    description = "Clear the wanted status for this person.",
    parameters = {
        {
            name = "actor",
            description = "The player who cleared the wanted status.",
            type = "Player",
            optional = true
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.arrest = LynxonsRP.stub{
    name = "arrest",
    description = "Arrest a player.",
    parameters = {
        {
            name = "time",
            description = "For how long the player is arrested.",
            type = "number",
            optional = true
        },
        {
            name = "Arrester",
            description = "The player who arrested the target.",
            type = "Player",
            optional = true
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.PLAYER.unArrest = LynxonsRP.stub{
    name = "unArrest",
    description = "Unarrest a player.",
    parameters = {
        {
            name = "Unarrester",
            description = "The player who unarrested the target.",
            type = "Player",
            optional = true
        }
    },
    returns = {
    },
    metatable = LynxonsRP.PLAYER
}

LynxonsRP.hookStub{
    name = "playerArrested",
    description = "When a player is arrested.",
    parameters = {
        {
            name = "criminal",
            description = "The arrested criminal.",
            type = "Player"
        },
        {
            name = "time",
            description = "The jail time.",
            type = "number"
        },
        {
            name = "actor",
            description = "The person who arrested the criminal.",
            type = "Player"
        }
    },
    returns = {
    }
}

LynxonsRP.hookStub{
    name = "playerUnArrested",
    description = "When a player is unarrested.",
    parameters = {
        {
            name = "criminal",
            description = "The unarrested criminal.",
            type = "Player"
        },
        {
            name = "actor",
            description = "The person who unarrested the criminal.",
            type = "Player"
        }
    },
    returns = {
    }
}

LynxonsRP.hookStub{
    name = "playerWarranted",
    description = "When a player is warranted.",
    parameters = {
        {
            name = "criminal",
            description = "The potential criminal.",
            type = "Player"
        },
        {
            name = "actor",
            description = "The person who wanted the potential criminal.",
            type = "Player"
        },
        {
            name = "reason",
            description = "The reason for wanting this person.",
            type = "string"
        }
    },
    returns = {
        {
            name = "suppressMsg",
            description = "Return true to make the warrant silent.",
            type = "boolean"
        }
    }
}

LynxonsRP.hookStub{
    name = "playerUnWarranted",
    description = "When a player is unwarranted.",
    parameters = {
        {
            name = "excriminal",
            description = "The potential criminal.",
            type = "Player"
        },
        {
            name = "actor",
            description = "The person who unwarranted the potential criminal",
            type = "Player"
        }
    },
    returns = {
        {
            name = "suppressMsg",
            description = "Return true to make the unwarrant silent.",
            type = "boolean"
        }
    }
}

LynxonsRP.hookStub{
    name = "playerWanted",
    description = "When a player is wanted.",
    parameters = {
        {
            name = "criminal",
            description = "The criminal.",
            type = "Player"
        },
        {
            name = "actor",
            description = "The person who wanted the criminal.",
            type = "Player"
        },
        {
            name = "reason",
            description = "The reason for wanting this person.",
            type = "string"
        }
    },
    returns = {
        {
            name = "suppressMsg",
            description = "Return true to make the wanted silent.",
            type = "boolean"
        }
    }
}

LynxonsRP.hookStub{
    name = "playerUnWanted",
    description = "When a player is unwanted.",
    parameters = {
        {
            name = "excriminal",
            description = "The ex criminal.",
            type = "Player"
        },
        {
            name = "actor",
            description = "The person who unwanted the ex criminal.",
            type = "Player"
        }
    },
    returns = {
        {
            name = "suppressMsg",
            description = "Return true to make the unwanted silent.",
            type = "boolean"
        }
    }
}

LynxonsRP.hookStub{
    name = "agendaUpdated",
    description = "When the agenda is updated.",
    parameters = {
        {
            name = "ply",
            description = "The player who changed the agenda. Warning: can be nil!",
            type = "Player"
        },
        {
            name = "agenda",
            description = "Agenda table (also holds the previous text).",
            type = "table"
        },
        {
            name = "text",
            description = "The text the player wants to set the agenda to.",
            type = "string"
        }
    },
    returns = {
        {
            name = "text",
            description = "An override for the text.",
            type = "string"
        }
    }
}

LynxonsRP.hookStub{
        name = "playerEnteredLottery",
        description = "When a player has entered the lottery.",
        parameters = {
                {
                        name = "ply",
                        description = "The player.",
                        type = "Player"
                }
        },
        returns = {
        }
}

LynxonsRP.hookStub{
        name = "lotteryEnded",
        description = "When a lottery has ended.",
        parameters = {
                {
                        name = "participants",
                        description = "The participants of the lottery. An empty table when no one entered the lottery.",
                        type = "table"
                },
                {
                        name = "chosen",
                        description = "The winner of the lottery.",
                        type = "Player"
                },
                {
                        name = "amount",
                        description = "The amount won by the winner.",
                        type = "number"
                }
        },
        returns = {
        }
}


LynxonsRP.hookStub{
        name = "lotteryStarted",
        description = "When a lottery has started.",
        parameters = {
                {
                        name = "ply",
                        description = "The player who started the lottery.",
                        type = "Player"
                },
                {
                        name = "price",
                        description = "The amount of money people have to pay to enter.",
                        type = "number"
                }
        },
        returns = {
        }
}


LynxonsRP.hookStub{
    name = "canGiveLicense",
    description = "Whether a player is allowed to give another player a license.",
    parameters = {
            {
                    name = "ply",
                    description = "The player who tries to give the license.",
                    type = "Player"
            },
            {
                    name = "target",
                    description = "The player who should receive the license.",
                    type = "Player"
            }
    },
    returns = {
        {
            name = "canGiveLicense",
            description = "Whether the player is allowed to give the target a license.",
            type = "boolean"
        },
        {
            name = "cantGiveReason",
            description = "Why the target is not allowed to receive a license from the player.",
            type = "string"
        },
    }
}
