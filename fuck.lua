script_key="";

getgenv().pvbConfig = {
    AUTO_UPDATE_RESTART = false,
    MAX_FPS = 2,  -- This will override setfpscap()
    LOW_CPU = true,
    MAX_REBIRTH = 99,  -- Stop rebirth at set amount
    FORCE_REBIRTH_IGNORE_KEEP_BRAINROT = true,  -- Ignore KEEP_BRAINROT related config until max rebirth
    FROST_GRENADE_TARGET_MAX_HP = 100000,  -- Use frost grenade 100k+ hp brainrot
    
    OPEN_LUCKY_EGG = {"Godly Lucky Egg", "Secret Lucky Egg", "Meme Lucky Egg"},
    FUSE_PLANT = {"Mr Carrot", "Pumpkin", "Sunflower", "Dragon Fruit", "Eggplant", "Watermelon"},  -- Auto keep & fuse required plant + brainrot

    BUY_SEED_SHOP = {["Cactus"] = 5, ["Strawberry"] = 5, ["Pumpkin"] = 5, ["Sunflower"] = 5, ["Dragon Fruit"] = 5, ["Eggplant"] = 5, ["Watermelon"] = 5, "Cocotank", "Carnivorous Plant", "Mr Carrot", "Tomatrio", "Shroombino", "Mango"},
    BUY_GEAR_SHOP = {"Frost Grenade", "Frost Blower"},
    KEEP_SEED = {},
    KEEP_PLANT_RARITY = {"Secret", "Limited"},
    KEEP_BRAINROT_MONEY_PER_SECOND = 20000,  -- Number
    KEEP_BRAINROT_RARITY = { "Secret", "Limited" },

    SELL_BRAINROT_DELAY = 30,
    SELL_PLANT_DELAY = 30,

    -- Webhook
    BRAINROT_WEBHOOK_URL = "https://discord.com/api/webhooks/1281359782900535377/tttxxQpzTZcaV58yU3Af7CXQOu96gEznKsg3ei_vaxmi_jQ_aDjCcFiNpr8HUNVxu24j",
    DISCORD_ID = "",
    NOTIFY_RARITY = { "Secret", "Limited" },
    NOTIFY_MONEY_PER_SECOND = 20000,
    WEBHOOK_NOTE = "cuto",
    SHOW_PUBLIC_DISCORD_ID = true,
    SHOW_WEBHOOK_USERNAME = true,
    SHOW_WEBHOOK_JOBID = true,
}

loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/1955a9eeb0a6b663051651121e75f7f7.lua"))()
