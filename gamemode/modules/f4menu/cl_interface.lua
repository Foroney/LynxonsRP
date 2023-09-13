LynxonsRP.openF4Menu = LynxonsRP.stub{
    name = "openF4Menu",
    description = "Open the F4 menu.",
    parameters = {
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.closeF4Menu = LynxonsRP.stub{
    name = "closeF4Menu",
    description = "Close the F4 menu if it's open.",
    parameters = {
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.toggleF4Menu = LynxonsRP.stub{
    name = "toggleF4Menu",
    description = "Toggle the state of the F4 menu (open or closed).",
    parameters = {
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.getF4MenuPanel = LynxonsRP.stub{
    name = "getF4MenuPanel",
    description = "Get the F4 menu panel.",
    parameters = {
    },
    returns = {
        {
            name = "panel",
            description = "The F4 menu panel. It will be invalid until the F4 menu has been opened.",
            type = "Panel",
            optional = false
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.addF4MenuTab = LynxonsRP.stub{
    name = "addF4MenuTab",
    description = "Add a tab to the F4 menu.",
    parameters = {
        {
            name = "name",
            description = "The title of the tab.",
            type = "string",
            optional = false
        },
        {
            name = "panel",
            description = "The panel of the tab.",
            type = "Panel",
            optional = false
        }
    },
    returns = {
        {
            name = "index",
            description = "The index of the tab in the menu. This is the number you use for the tab in LynxonsRP.switchTabOrder.",
            type = "number"
        },
        {
            name = "sheet",
            description = "The tab sheet.",
            type = "Panel"
        }
    },
    metatable = LynxonsRP
}

LynxonsRP.removeF4MenuTab = LynxonsRP.stub{
    name = "removeF4MenuTab",
    description = "Remove a tab from the F4 menu by name.",
    parameters = {
        {
            name = "name",
            description = "The name of the tab it should remove.",
            type = "string",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.switchTabOrder = LynxonsRP.stub{
    name = "switchTabOrder",
    description = "Switch the order of two tabs.",
    parameters = {
        {
            name = "firstTab",
            description = "The number of the first tab (if it's the second tab, then this number is 2).",
            type = "number",
            optional = false
        },
        {
            name = "secondTab",
            description = "The number of the second tab.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = LynxonsRP
}

LynxonsRP.hookStub{
    name = "F4MenuTabs",
    description = "Called when tabs are generated. Add and remove tabs in this hook.",
    parameters = {
    },
    returns = {
    }
}
