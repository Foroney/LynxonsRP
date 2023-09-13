--[[LynxonsRP.createShipment("Pump shotgun", {
    model = "models/weapons/w_shot_m3super90.mdl",
    entity = "weapon_pumpshotgun2",
    price = 1750,
    amount = 10,
    separate = false,
    pricesep = nil,
    noship = false,
    allowed = {TEAM_GUN},
    category = "Shotguns",
})]]



--[[==================================================================
=========================== Категории еды ============================
======================================================================]]
LynxonsRP.createCategory {
    name = "Молочные продукты",
    categorises = "shipments",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 1,
}

--[[==================================================================
=========================== Категории оружий ==========================
======================================================================]]
LynxonsRP.createCategory {
    name = "Винтовки",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 1,
}
LynxonsRP.createCategory {
    name = "Карабины",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 2,
}
LynxonsRP.createCategory {
    name = "Автоматы",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 3,
}
LynxonsRP.createCategory {
    name = "Пистолеты",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 4,
}
LynxonsRP.createCategory {
    name = "Револьверы",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 5,
}
LynxonsRP.createCategory {
    name = "Ружья",
    categorises = "weapons",
    startExpanded = false,
    color = Color(114, 107, 255),
    canSee = fp{fn.Id, true},
    sortOrder = 6,
}

--[[==================================================================
=========================== Машины ===================================
======================================================================]]



--[[==================================================================
=========================== Категории машин ==========================
======================================================================]]
LynxonsRP.createCategory {
    name = "Бюджетные автомобили",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 1,
}
LynxonsRP.createCategory {
    name = "Демократичные автомобили",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 2,
}
LynxonsRP.createCategory {
    name = "Премиальные бизнес-класса",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 3,
}
LynxonsRP.createCategory {
    name = "Люксовые автомобили",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 4,
}
LynxonsRP.createCategory {
    name = "Кроссоверы автомобили",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 5,
}
LynxonsRP.createCategory {
    name = "Профессиональные внедорожники",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 6,
}
LynxonsRP.createCategory {
    name = "Универсальные внедорожники",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(114, 107, 255),
    sortOrder = 7,
}
