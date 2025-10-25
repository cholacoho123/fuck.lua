setfpscap(7)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players
repeat task.wait() until game.Players.LocalPlayer
UserSettings():GetService("UserGameSettings").MasterVolume = 0
UserSettings():GetService("UserGameSettings").SavedQualityLevel = 1
workspace.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
game:GetService("Lighting").GlobalShadows = false
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
settings().Rendering.GraphicsMode = 9

script_key = "dXsdXifNZatlviBDZjqfBvnJGexHrcpQ";
getgenv().GGFX_MODE = 1
getgenv().GDO_HALLOWEEN_WORLD = true
getgenv().GHALLOWEEN_WORLD_BUY_FROM_SPECIFIC_HOUSE = 3
getgenv().GHALLOWEEN_WORLD_BUY_FROM_HOUSES_BELOW = true
getgenv().GALLOW_HOPPING = true
getgenv().GZONE_TO = 1
getgenv().GEVENT_UPGRADES = {
  "HalloweenCandyMultiplier",
  "HalloweenEggLuck",
  "HalloweenTrickOrTreatLuck",
  "HalloweenMoreDiamonds",
  "HalloweenMoreWitchHats",
  "HalloweenHugeLuck",
  "HalloweenTitanicLuck"
}
getgenv().GWEBHOOK_USERID = ""
getgenv().GWEBHOOK_LINK = ""
getgenv().GHUGE_COUNT = 0 -- amount of huges to keep/not mail
getgenv().GMAIL_RECEIVERS = {"OKkMma_b"} 
getgenv().GMAX_MAIL_COST = "2m" 
getgenv().GMAIL_ITEMS = {
["All Huges"] = {Class = "Pet", Id = "All Huges", MinAmount = 1},
["Send Diamonds"] = {Class = "Currency", Id = "Diamonds", KeepAmount = "5m", MinAmount = "30m"}, -- mail diamonds, to enable lower MinAmount..
["Hype Egg 2"] = {Class = "Lootbox", Id = "Hype Egg 2", MinAmount = 1},
["Daycare egg 5"] = {Class = "Egg", Id = "Huge Machine Egg 5", MinAmount = 1},
["Secret pet1"] = {Class = "Pet", Id = "Rainbow Swirl", MinAmount = 1, AllVariants = true},
["Secret pet2"] = {Class = "Pet", Id = "Banana", MinAmount = 1, AllVariants = true},
["Secret pet3"] = {Class = "Pet", Id = "Coin", MinAmount = 1, AllVariants = true},
["Secret pet4"] = {Class = "Pet", Id = "Yellow Lucky Block", MinAmount = 1, AllVariants = true},
}
loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/ba2dcad2127dcfc04301dfe52ce6c61c.lua"))()
