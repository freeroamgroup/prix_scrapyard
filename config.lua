Config = {}

Config.ScrapyItem = "scrapmetal"

Config.Cooldown = 15 * 60 -- 15 minut

Config.ScrapReward = { min = 20, max = 35 }

Config.MaxScrapDistance = 4.0

Config.AllowedClasses = {0,1,2,3,4,5,6,7,8,9,10,11,12}

Config.TotalScrapTime = 30000 -- 30s

-- 1) ihned - kapota (0)
-- 2) +5s - kufr (5000)
-- 3) +3s - přední dveře (3000)
-- 4) +3s - zadní dveře (3000)
-- 5) +4s - vnitřek (4000)
-- 6) +7s - motor (7000)
-- 7) +8s - karoserie (8000)
Config.StageDurations = {0, 5000, 3000, 3000, 4000, 7000, 8000}

Config.StageLocaleKeys = {
    "scrap_stage_hood",
    "scrap_stage_trunk",
    "scrap_stage_front_doors",
    "scrap_stage_rear_doors",
    "scrap_stage_interior",
    "scrap_stage_engine",
    "scrap_stage_body"
}

Config.Scrapyards = {
    {
        coords = vec3(2342.5, 3128.7, 48.2),
        radius = 6.0,
        blip = {
            enabled = true,
            sprite = 527,
            color = 0,
            scale = 0.5,
            label = "Scrapyard"
        }
    },
    {
        coords = vec3(-490.2, -1722.3, 18.9),
        radius = 6.0,
        blip = {
            enabled = true,
            sprite = 527,
            color = 0,
            scale = 0.5,
            label = "Scrapyard"
        }
    }
}

Config.ProgressLabelKey = "progress_label"

Config.UseOxInventory = true

Config.Debug = false
