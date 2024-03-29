--[[
Localization tips
1. Enable debugging in game with /sldebug
2. There are often ItemIDs in comments for you to check if the items works correctly in game
3. Use the addon Sniff(http://www.wowinterface.com/downloads/info6259/) to get a link in game from an ItemID, Usage: /item 19316
4. Atlas + AtlasLoot is also a good source of items to check
5. Red colored text output from debug means that line does not have a match
6. Building your own ItemStrings(ex: "item:28484:1503:0:2946:2945:0:0:0"): http://www.wowwiki.com/ItemString
   linkType, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId
7. Getting a visual on your ItemString:
  a. Display the ItemRefTooltip by clicking on a link in chat
  b. /dump StatLogic:SetTip("item:23344:2746")
6. Testing Enchants:
  a. Obtain the enchantId from wowhead.
    EX: Find the enchantId for [Golden Spellthread]:
    Find the spell page for the enchant: http://www.wowhead.com/?spell=31370
    Under Spell Details, look for "Enchant Item Permanent (2746)"
    2746 is the enchantId
  b. We need an item to attach the enchant, I like to use [Scout's Pants] ID:23344. (/item 23344 if you don't have it in your cache)
    ItemString: "item:23344:2746"
  c. /dump StatLogic:GetSum("item:23344:2746")
--]]
--[[
-- Item Stat Scanning Procedure
-- Trim spaces using strtrim(text)
-- Strip color codes
-- 1. Fast Exclude - Exclude obvious lines that do not need to be checked
--    Exclude a string by matching the whole string, these strings are indexed in L.Exclude.
--    Exclude a string by looking at the first X chars, these strings are indexed in L.Exclude.
--    Exclude lines starting with '"'. (Flavor text)
--    Exclude lines that are not white and green and normal (normal for Frozen Wrath bonus)
-- 2. Whole Text Lookup - Mainly used for enchants or stuff without numbers
--    Whole strings are indexed in L.WholeTextLookup
-- 3. Single Plus Stat Check - "+10 Spirit"
--    String is matched with pattern L.SinglePlusStatCheck, 2 captures are returned.
--    If a match is found, the non-number capture is looked up in L.StatIDLookup.
-- 4. Single Equip Stat Check - "Equip: Increases attack power by 81."
--    String is matched with pattern L.SingleEquipStatCheck, 2 captures are returned.
--    If a match is found, the non-number capture is looked up in L.StatIDLookup.
-- 5. Pre Scan - Short list of patterns that will be checked before going into Deep Scan.
-- 6. Deep Scan - When all the above checks fail, we will use the Deep Scan, this is slow but only about 10% of the lines need it.
--    Strip leading "Equip: ", "Socket Bonus: ".
--    Strip trailing ".".
--    Separate the string using L.DeepScanSeparators.
--    Check if the separated strings are found in L.WholeTextLookup.
--    Try to match each separated string to patterns in L.DeepScanPatterns in order, patterns in L.DeepScanPatterns should have less inclusive patterns listed first and more inclusive patterns listed last.
--    If no match then separate the string using L.DeepScanWordSeparators, then check again.
--]]
--[[DEBUG stuff, no need to translate
textTable = {
  "Spell Damage +6 and Spell Hit Rating +5",
  "+3 Stamina, +4 Critical Strike Rating",
  "+26 Healing Spells & 2% Reduced Threat",
  "+3 Stamina/+4 Critical Strike Rating",
  "Socket Bonus: 2 mana per 5 sec.",
  "Equip: Increases damage and healing done by magical spells and effects by up to 150.",
  "Equip: Increases the spell critical strike rating of all party members within 30 yards by 28.",
  "Equip: Increases damage and healing done by magical spells and effects of all party members within 30 yards by up to 33.",
  "Equip: Increases healing done by magical spells and effects of all party members within 30 yards by up to 62.",
  "Equip: Increases your spell damage by up to 120 and your healing by up to 300.",
  "Equip: Restores 11 mana per 5 seconds to all party members within 30 yards.",
  "Equip: Increases healing done by spells and effects by up to 300.",
  "Equip: Increases attack power by 420 in Cat, Bear, Dire Bear, and Moonkin forms only.",
  "+10 Defense Rating/+10 Stamina/+15 Block Value", -- ZG Enchant
  "+26 Attack Power and +14 Critical Strike Rating", -- Swift Windfire Diamond ID:28556
  "+26 Healing Spells & 2% Reduced Threat", -- Bracing Earthstorm Diamond ID:25897
  "+6 Spell Damage, +5 Spell Crit Rating", -- Potent Ornate Topaz ID: 28123
  ----
  "Critical Rating +6 and Dodge Rating +5", -- Assassin's Fire Opal ID:30565
  "Healing +11 and 2 mana per 5 sec.", -- Royal Tanzanite ID: 30603
}
--]]

--- TODO  ----

PatternLocale.ptBR = {
  ["tonumber"] = tonumber,
  -----------------
  -- Armor Types --
  -----------------
  Plate = "Plate",
  Mail = "Mail",
  Leather = "Leather",
  Cloth = "Cloth",
  ------------------
  -- Fast Exclude --
  ------------------
  -- By looking at the first ExcludeLen letters of a line we can exclude a lot of lines
  ["ExcludeLen"] = 5, -- using string.utf8len
  ["Exclude"] = {
    [""] = true,
    [" \n"] = true,
    [ITEM_BIND_ON_EQUIP] = true, -- ITEM_BIND_ON_EQUIP = "Binds when equipped"; -- Item will be bound when equipped
    [ITEM_BIND_ON_PICKUP] = true, -- ITEM_BIND_ON_PICKUP = "Binds when picked up"; -- Item will be bound when picked up
    [ITEM_BIND_ON_USE] = true, -- ITEM_BIND_ON_USE = "Binds when used"; -- Item will be bound when used
    [ITEM_BIND_QUEST] = true, -- ITEM_BIND_QUEST = "Quest Item"; -- Item is a quest item (same logic as ON_PICKUP)
    [ITEM_SOULBOUND] = true, -- ITEM_SOULBOUND = "Soulbound"; -- Item is Soulbound
    [ITEM_STARTS_QUEST] = true, -- ITEM_STARTS_QUEST = "This Item Begins a Quest"; -- Item is a quest giver
    [ITEM_CANT_BE_DESTROYED] = true, -- ITEM_CANT_BE_DESTROYED = "That item cannot be destroyed."; -- Attempted to destroy a NO_DESTROY item
    [ITEM_CONJURED] = true, -- ITEM_CONJURED = "Conjured Item"; -- Item expires
    [ITEM_DISENCHANT_NOT_DISENCHANTABLE] = true, -- ITEM_DISENCHANT_NOT_DISENCHANTABLE = "Cannot be disenchanted"; -- Items which cannot be disenchanted ever
    ["Disen"] = true, -- ITEM_DISENCHANT_ANY_SKILL = "Disenchantable"; -- Items that can be disenchanted at any skill level
    -- ITEM_DISENCHANT_MIN_SKILL = "Disenchanting requires %s (%d)"; -- Minimum enchanting skill needed to disenchant
    ["Durat"] = true, -- ITEM_DURATION_DAYS = "Duration: %d days";
    ["<Made"] = true, -- ITEM_CREATED_BY = "|cff00ff00<Made by %s>|r"; -- %s is the creator of the item
    ["Coold"] = true, -- ITEM_COOLDOWN_TIME_DAYS = "Cooldown remaining: %d day";
    ["Uniqu"] = true, -- Unique (20) -- ITEM_UNIQUE = "Unique"; -- Item is unique -- ITEM_UNIQUE_MULTIPLE = "Unique (%d)"; -- Item is unique
    ["Requi"] = true, -- Requires Level xx -- ITEM_MIN_LEVEL = "Requires Level %d"; -- Required level to use the item
    ["\nRequ"] = true, -- Requires Level xx -- ITEM_MIN_SKILL = "Requires %s (%d)"; -- Required skill rank to use the item
    ["Class"] = true, -- Classes: xx -- ITEM_CLASSES_ALLOWED = "Classes: %s"; -- Lists the classes allowed to use this item
    ["Races"] = true, -- Races: xx (vendor mounts) -- ITEM_RACES_ALLOWED = "Races: %s"; -- Lists the races allowed to use this item
    ["Use: "] = true, -- Use: -- ITEM_SPELL_TRIGGER_ONUSE = "Use:";
    ["Chanc"] = true, -- Chance On Hit: -- ITEM_SPELL_TRIGGER_ONPROC = "Chance on hit:";
    -- Set Bonuses
    -- ITEM_SET_BONUS = "Set: %s";
    -- ITEM_SET_BONUS_GRAY = "(%d) Set: %s";
    -- ITEM_SET_NAME = "%s (%d/%d)"; -- Set name (2/5)
    ["Set: "] = true,
    ["(2) S"] = true,
    ["(3) S"] = true,
    ["(4) S"] = true,
    ["(5) S"] = true,
    ["(6) S"] = true,
    ["(7) S"] = true,
    ["(8) S"] = true,
    -- Equip type
    ["Projectile"] = true, -- Ice Threaded Arrow ID:19316
    [INVTYPE_AMMO] = true,
    [INVTYPE_HEAD] = true,
    [INVTYPE_NECK] = true,
    [INVTYPE_SHOULDER] = true,
    [INVTYPE_BODY] = true,
    [INVTYPE_CHEST] = true,
    [INVTYPE_ROBE] = true,
    [INVTYPE_WAIST] = true,
    [INVTYPE_LEGS] = true,
    [INVTYPE_FEET] = true,
    [INVTYPE_WRIST] = true,
    [INVTYPE_HAND] = true,
    [INVTYPE_FINGER] = true,
    [INVTYPE_TRINKET] = true,
    [INVTYPE_CLOAK] = true,
    [INVTYPE_WEAPON] = true,
    [INVTYPE_SHIELD] = true,
    [INVTYPE_2HWEAPON] = true,
    [INVTYPE_WEAPONMAINHAND] = true,
    [INVTYPE_WEAPONOFFHAND] = true,
    [INVTYPE_HOLDABLE] = true,
    [INVTYPE_RANGED] = true,
    [INVTYPE_THROWN] = true,
    --[INVTYPE_RANGEDRIGHT] = true,
    [INVTYPE_RELIC] = true,
    [INVTYPE_TABARD] = true,
    [INVTYPE_BAG] = true,
  },
  -----------------------
  -- Whole Text Lookup --
  -----------------------
  -- Mainly used for enchants that doesn't have numbers in the text
  -- http://wow.allakhazam.com/db/enchant.html?slot=0&locale=enUS
  ["WholeTextLookup"] = {
    [EMPTY_SOCKET_RED] = {["EMPTY_SOCKET_RED"] = 1}, -- EMPTY_SOCKET_RED = "Red Socket";
    [EMPTY_SOCKET_YELLOW] = {["EMPTY_SOCKET_YELLOW"] = 1}, -- EMPTY_SOCKET_YELLOW = "Yellow Socket";
    [EMPTY_SOCKET_BLUE] = {["EMPTY_SOCKET_BLUE"] = 1}, -- EMPTY_SOCKET_BLUE = "Blue Socket";
    [EMPTY_SOCKET_META] = {["EMPTY_SOCKET_META"] = 1}, -- EMPTY_SOCKET_META = "Meta Socket";

    ["Minor Wizard Oil"] = {["SPELL_DMG"] = 8, ["HEAL"] = 8}, -- ID: 20744
    ["Lesser Wizard Oil"] = {["SPELL_DMG"] = 16, ["HEAL"] = 16}, -- ID: 20746
    ["Wizard Oil"] = {["SPELL_DMG"] = 24, ["HEAL"] = 24}, -- ID: 20750
    ["Brilliant Wizard Oil"] = {["SPELL_DMG"] = 36, ["HEAL"] = 36, ["SPELL_CRIT_RATING"] = 14}, -- ID: 20749
    ["Superior Wizard Oil"] = {["SPELL_DMG"] = 42, ["HEAL"] = 42}, -- ID: 22522
    ["Blessed Wizard Oil"] = {["SPELL_DMG_UNDEAD"] = 60}, -- ID: 23123

    ["Minor Mana Oil"] = {["COMBAT_MANA_REGEN"] = 4}, -- ID: 20745
    ["Lesser Mana Oil"] = {["COMBAT_MANA_REGEN"] = 8}, -- ID: 20747
    ["Brilliant Mana Oil"] = {["COMBAT_MANA_REGEN"] = 12, ["HEAL"] = 25}, -- ID: 20748
    ["Superior Mana Oil"] = {["COMBAT_MANA_REGEN"] = 14}, -- ID: 22521

    --["Eternium Line"] = {["FISHING"] = 5}, -- +5 Fishing
    --["Savagery"] = {["AP"] = 70}, -- +70 Attack Power
    --["Vitality"] = {["COMBAT_MANA_REGEN"] = 4, ["COMBAT_HEALTH_REGEN"] = 4}, -- +4 Mana and Health every 5 sec
    --["Soulfrost"] = {["SHADOW_SPELL_DMG"] = 54, ["FROST_SPELL_DMG"] = 54}, -- Changed to +54 Shadow and Frost Spell Power
    --["Sunfire"] = {["ARCANE_SPELL_DMG"] = 50, ["FIRE_SPELL_DMG"] = 50}, -- Changed to +50 Arcane and Fire Spell Power

    -- ["Mithril Spurs"] = {["MOUNT_SPEED"] = 4}, -- +4% Mount Speed
    -- ["Minor Mount Speed Increase"] = {["MOUNT_SPEED"] = 2}, -- +2% Mount Speed
    ["Equip: Run speed increased slightly."] = {["RUN_SPEED"] = 8}, -- [Highlander's Plate Greaves] ID: 20048
    ["Minor Speed Increase"] = {["RUN_SPEED"] = 8}, -- EnchantID: 911 Enchant Boots - Minor Speed "Minor Speed Increase"
    ["Minor Speed"] = {["RUN_SPEED"] = 8}, -- EnchantID: 2939 Enchant Boots - Cat's Swiftness "Minor Speed and +6 Agility"
    --["Surefooted"] = {["MELEE_HIT_RATING"] = 10, ["SPELL_HIT_RATING"] = 10, ["MELEE_CRIT_RATING"] = 10, ["SPELL_CRIT_RATING"] = 10}, -- EnchantID: 2658 Enchant Boots - Surefooted

    --["Subtlety"] = {["MOD_THREAT"] = -2}, -- EnchantID: 2621 Enchant Cloak - Subtlety
    ["2% Reduced Threat"] = {["MOD_THREAT"] = -2}, -- EnchantID: 2621, 2832, 3296
    ["Equip: Allows underwater breathing."] = false, -- [Band of Icy Depths] ID: 21526
    ["Allows underwater breathing"] = false, --
    ["Equip: Immune to Disarm."] = false, -- [Stronghold Gauntlets] ID: 12639
    ["Immune to Disarm"] = false, --
    ["Crusader"] = false, -- Enchant Crusader
    ["Lifestealing"] = false, -- Enchant Crusader

    --["Tuskar's Vitality"] = {["RUN_SPEED"] = 8, ["STA"] = 15}, -- EnchantID: 3232 +15 Stamina and Minor Speed Increase
    --["Wisdom"] = {["MOD_THREAT"] = -2, ["SPI"] = 10}, -- EnchantID: 3296 +10 Spirit and 2% Reduced Threat
    --["Accuracy"] = {["MELEE_HIT_RATING"] = 25, ["SPELL_HIT_RATING"] = 25, ["MELEE_CRIT_RATING"] = 25, ["SPELL_CRIT_RATING"] = 25}, -- EnchantID: 3788 +25 Hit Rating and +25 Critical Strike Rating
    --["Scourgebane"] = {["AP_UNDEAD"] = 140}, -- EnchantID: 3247 +140 Attack Power versus Undead
    --["Icewalker"] = {["MELEE_HIT_RATING"] = 12, ["SPELL_HIT_RATING"] = 12, ["MELEE_CRIT_RATING"] = 12, ["SPELL_CRIT_RATING"] = 12}, -- EnchantID: 3826 +12 Hit Rating and +12 Critical Strike Rating
    ["Gatherer"] = {["HERBALISM"] = 5, ["MINING"] = 5, ["SKINNING"] = 5}, -- EnchantID: 3296
    --["Greater Vitality"] = {["COMBAT_MANA_REGEN"] = 6, ["COMBAT_HEALTH_REGEN"] = 6}, -- EnchantID: 3244 +7 Health and Mana every 5 sec

    --["+37 Stamina and +20 Defense"] = {["STA"] = 37, ["DEFENSE_RATING"] = 20}, -- EnchantID: 3818 Defense does not equal Defense Rating...
    ["Rune of Swordbreaking"] = {["PARRY"] = 2}, -- EnchantID: 3594
    ["Rune of Swordshattering"] = {["PARRY"] = 4}, -- EnchantID: 3365
    ["Rune of the Stoneskin Gargoyle"] = {["MOD_ARMOR"] = 4, ["MOD_STA"] = 2}, -- EnchantID: 3847
    ["Rune of the Nerubian Carapace"] = {["MOD_ARMOR"] = 2, ["MOD_STA"] = 1}, -- EnchantID: 3883
  },
  ----------------------------
  -- Single Plus Stat Check --
  ----------------------------
  -- depending on locale, it may be
  -- +19 Stamina = "^%+(%d+) (.-)%.?$"
  -- Stamina +19 = "^(.-) %+(%d+)%.?$"
  -- +19 耐力 = "^%+(%d+) (.-)%.?$"
  -- Some have a "." at the end of string like:
  -- Enchant Chest - Restore Mana Prime "+6 mana every 5 sec. "
  ["SinglePlusStatCheck"] = "^([%+%-]%d+) (.-)%.?$",
  -----------------------------
  -- Single Equip Stat Check --
  -----------------------------
  -- stat1, value, stat2 = strfind
  -- stat = stat1..stat2
  -- "^Equip: (.-) by u?p? ?t?o? ?(%d+) ?(.-)%.?$"
  ["SingleEquipStatCheck"] = "^Equip: (.-) by u?p? ?t?o? ?(%d+) ?(.-)%.?$",
  -------------
  -- PreScan --
  -------------
  -- Special cases that need to be dealt with before deep scan
  ["PreScanPatterns"] = {
    --["^Equip: Increases attack power by (%d+) in Cat"] = "FERAL_AP",
    --["^Equip: Increases attack power by (%d+) when fighting Undead"] = "AP_UNDEAD", -- Seal of the Dawn ID:13029
    ["^Increases attack power by (%d+) in Cat, Bear, Dire Bear, and Moonkin forms only%.$"] = "FERAL_AP", -- 3.0.8 FAP change
    ["^(%d+) Block$"] = "BLOCK_VALUE",
    ["^(%d+) Armor$"] = "ARMOR",
    ["Reinforced %(%+(%d+) Armor%)"] = "ARMOR_BONUS",
    ["Mana Regen (%d+) per 5 sec%.$"] = "COMBAT_MANA_REGEN",
    ["^%+?%d+ %- (%d+) .-Damage$"] = "MAX_DAMAGE",
    ["^%(([%d%.]+) damage per second%)$"] = "DPS",
    -- Exclude
    ["^(%d+) Slot"] = false, -- Bags
    ["^[%a '%-]+%((%d+)/%d+%)$"] = false, -- Set Name (0/9)
    ["|cff808080"] = false, -- Gray text "  |cff808080Requires at least 2 Yellow gems|r\n  |cff808080Requires at least 1 Red gem|r"
    -- Procs
    --["[Cc]hance"] = false, -- [Mark of Defiance] ID:27924 -- [Staff of the Qiraji Prophets] ID:21128 -- Commented out because it was blocking [Insightful Earthstorm Diamond]
    ["[Ss]ometimes"] = false, -- [Darkmoon Card: Heroism] ID:19287
    ["[Ww]hen struck in combat"] = false, -- [Essence of the Pure Flame] ID: 18815
  },
  --------------
  -- DeepScan --
  --------------
  -- Strip leading "Equip: ", "Socket Bonus: "
  ["Equip: "] = "Equip: ", -- ITEM_SPELL_TRIGGER_ONEQUIP = "Equip:";
  ["Socket Bonus: "] = "Socket Bonus: ", -- ITEM_SOCKET_BONUS = "Socket Bonus: %s"; -- Tooltip tag for socketed item matched socket bonuses
  -- Strip trailing "."
  ["."] = ".",
  ["DeepScanSeparators"] = {
    "/", -- "+10 Defense Rating/+10 Stamina/+15 Block Value": ZG Enchant
    " & ", -- "+26 Healing Spells & 2% Reduced Threat": Bracing Earthstorm Diamond ID:25897
    ", ", -- "+6 Spell Damage, +5 Spell Crit Rating": Potent Ornate Topaz ID: 28123
    "%. ", -- "Equip: Increases attack power by 81 when fighting Undead. It also allows the acquisition of Scourgestones on behalf of the Argent Dawn.": Seal of the Dawn
  },
  ["DeepScanWordSeparators"] = {
    " and ", -- "Critical Rating +6 and Dodge Rating +5": Assassin's Fire Opal ID:30565
  },
  ["DualStatPatterns"] = { -- all lower case
    ["^%+(%d+) healing and %+(%d+) spell damage$"] = {{"HEAL",}, {"SPELL_DMG",},},
    ["^%+(%d+) healing %+(%d+) spell damage$"] = {{"HEAL",}, {"SPELL_DMG",},},
    ["^increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects$"] = {{"HEAL",}, {"SPELL_DMG",},},
  },
  ["DeepScanPatterns"] = {
    "^(.-) by u?p? ?t?o? ?(%d+) ?(.-)$", -- "xxx by up to 22 xxx" (scan first)
    "^(.-) ?([%+%-]%d+) ?(.-)$", -- "xxx xxx +22" or "+22 xxx xxx" or "xxx +22 xxx" (scan 2ed)
    "^(.-) ?([%d%.]+) ?(.-)$", -- 22.22 xxx xxx (scan last)
  },
  -----------------------
  -- Stat Lookup Table --
  -----------------------
  ["StatIDLookup"] = {
    ["% Threat"] = {"MOD_THREAT"}, -- StatLogic:GetSum("item:23344:2613")
    ["% Intellect"] = {"MOD_INT"}, -- [Ember Skyflare Diamond] ID: 41333
    ["% Shield Block Value"] = {"MOD_BLOCK_VALUE"}, -- [Eternal Earthsiege Diamond] ID: 41396
    ["% Mount Speed"] = {"MOUNT_SPEED"}, -- Mithril Spurs, Minor Mount Speed Increase
    ["Scope (Damage)"] = {"RANGED_DMG"}, -- Khorium Scope EnchantID: 2723
    ["Scope (Critical Strike Rating)"] = {"RANGED_CRIT_RATING"}, -- Stabilized Eternium Scope EnchantID: 2724
    ["Your attacks ignoreof your opponent's armor"] = {"IGNORE_ARMOR"}, -- StatLogic:GetSum("item:33733")
    ["Increases your effective stealth level"] = {"STEALTH_LEVEL"}, -- [Nightscape Boots] ID: 8197
    ["Weapon Damage"] = {"MELEE_DMG"}, -- Enchant
    ["Increases mount speed%"] = {"MOUNT_SPEED"}, -- [Highlander's Plate Greaves] ID: 20048

    ["All Stats"] = {"STR", "AGI", "STA", "INT", "SPI",},
    ["to All Stats"] = {"STR", "AGI", "STA", "INT", "SPI",}, -- [Enchanted Tear] ID: 42702
    ["Strength"] = {"STR",},
    ["Agility"] = {"AGI",},
    ["Stamina"] = {"STA",},
    ["Intellect"] = {"INT",},
    ["Spirit"] = {"SPI",},

    ["Arcane Resistance"] = {"ARCANE_RES",},
    ["Fire Resistance"] = {"FIRE_RES",},
    ["Nature Resistance"] = {"NATURE_RES",},
    ["Frost Resistance"] = {"FROST_RES",},
    ["Shadow Resistance"] = {"SHADOW_RES",},
    ["Arcane Resist"] = {"ARCANE_RES",}, -- Arcane Armor Kit +8 Arcane Resist
    ["Fire Resist"] = {"FIRE_RES",}, -- Flame Armor Kit +8 Fire Resist
    ["Nature Resist"] = {"NATURE_RES",}, -- Frost Armor Kit +8 Frost Resist
    ["Frost Resist"] = {"FROST_RES",}, -- Nature Armor Kit +8 Nature Resist
    ["Shadow Resist"] = {"SHADOW_RES",}, -- Shadow Armor Kit +8 Shadow Resist
    ["Shadow resistance"] = {"SHADOW_RES",}, -- Demons Blood ID: 10779
    ["All Resistances"] = {"ARCANE_RES", "FIRE_RES", "FROST_RES", "NATURE_RES", "SHADOW_RES",},
    ["Resist All"] = {"ARCANE_RES", "FIRE_RES", "FROST_RES", "NATURE_RES", "SHADOW_RES",},

    ["Fishing"] = {"FISHING",}, -- Fishing enchant ID:846
    ["Fishing Skill"] = {"FISHING",}, -- Fishing lure
    ["Increased Fishing"] = {"FISHING",}, -- Equip: Increased Fishing +20.
    ["Mining"] = {"MINING",}, -- Mining enchant ID:844
    ["Herbalism"] = {"HERBALISM",}, -- Heabalism enchant ID:845
    ["Skinning"] = {"SKINNING",}, -- Skinning enchant ID:865

    ["Armor"] = {"ARMOR_BONUS",},
    ["Defense"] = {"DEFENSE",},
    ["Increased Defense"] = {"DEFENSE",},
    ["Block"] = {"BLOCK_VALUE",}, -- +22 Block Value
    ["Block Value"] = {"BLOCK_VALUE",}, -- +22 Block Value
    ["Shield Block Value"] = {"BLOCK_VALUE",}, -- +10% Shield Block Value [Eternal Earthstorm Diamond] http://www.wowhead.com/?item=35501
    ["Increases the block value of your shield"] = {"BLOCK_VALUE",},

    ["Health"] = {"HEALTH",},
    ["HP"] = {"HEALTH",},
    ["Mana"] = {"MANA",},

    ["Attack Power"] = {"AP",},
    ["Increases attack power"] = {"AP",},
    ["Attack Power when fighting Undead"] = {"AP_UNDEAD",},
    ["Attack Power versus Undead"] = {"AP_UNDEAD",}, -- Scourgebane EnchantID: 3247
    -- [Wristwraps of Undead Slaying] ID:23093
    ["Increases attack powerwhen fighting Undead"] = {"AP_UNDEAD",}, -- [Seal of the Dawn] ID:13209
    ["Increases attack powerwhen fighting Undead.  It also allows the acquisition of Scourgestones on behalf of the Argent Dawn"] = {"AP_UNDEAD",}, -- [Seal of the Dawn] ID:13209
    ["Increases attack powerwhen fighting Demons"] = {"AP_DEMON",},
    ["Increases attack powerwhen fighting Undead and Demons"] = {"AP_UNDEAD", "AP_DEMON",}, -- [Mark of the Champion] ID:23206
    ["Attack Power in Cat, Bear, and Dire Bear forms only"] = {"FERAL_AP",},
    ["Increases attack powerin Cat, Bear, Dire Bear, and Moonkin forms only"] = {"FERAL_AP",},
    ["Ranged Attack Power"] = {"RANGED_AP",},
    ["Increases ranged attack power"] = {"RANGED_AP",}, -- [High Warlord's Crossbow] ID: 18837

    ["Health Regen"] = {"COMBAT_MANA_REGEN",},
    ["Health per"] = {"COMBAT_HEALTH_REGEN",},
    ["health per"] = {"COMBAT_HEALTH_REGEN",}, -- Frostwolf Insignia Rank 6 ID:17909
    ["Health every"] = {"COMBAT_MANA_REGEN",},
    ["health every"] = {"COMBAT_HEALTH_REGEN",}, -- [Resurgence Rod] ID:17743
    ["your normal health regeneration"] = {"COMBAT_HEALTH_REGEN",}, -- Demons Blood ID: 10779
    ["Restoreshealth per 5 sec"] = {"COMBAT_HEALTH_REGEN",}, -- [Onyxia Blood Talisman] ID: 18406
    ["Restoreshealth every 5 sec"] = {"COMBAT_HEALTH_REGEN",}, -- [Resurgence Rod] ID:17743
    ["Mana Regen"] = {"COMBAT_MANA_REGEN",}, -- Prophetic Aura +4 Mana Regen/+10 Stamina/+24 Healing Spells http://wow.allakhazam.com/db/spell.html?wspell=24167
    ["Mana per"] = {"COMBAT_MANA_REGEN",},
    ["mana per"] = {"COMBAT_MANA_REGEN",}, -- Resurgence Rod ID:17743 Most common
    ["Mana every"] = {"COMBAT_MANA_REGEN",},
    ["mana every"] = {"COMBAT_MANA_REGEN",},
    ["Mana every 5 seconds"] = {"COMBAT_MANA_REGEN",}, -- [Royal Nightseye] ID: 24057
    ["Mana every 5 Sec"] = {"COMBAT_MANA_REGEN",}, --
    ["mana every 5 sec"] = {"COMBAT_MANA_REGEN",}, -- Enchant Chest - Restore Mana Prime "+6 mana every 5 sec." http://wow.allakhazam.com/db/spell.html?wspell=33991
    ["Mana per 5 Seconds"] = {"COMBAT_MANA_REGEN",}, -- [Royal Shadow Draenite] ID: 23109
    ["Mana Per 5 sec"] = {"COMBAT_MANA_REGEN",}, -- [Royal Shadow Draenite] ID: 23109
    ["Mana per 5 sec"] = {"COMBAT_MANA_REGEN",}, -- [Cyclone Shoulderpads] ID: 29031
    ["mana per 5 sec"] = {"COMBAT_MANA_REGEN",}, -- [Royal Tanzanite] ID: 30603
    ["Restoresmana per 5 sec"] = {"COMBAT_MANA_REGEN",}, -- [Resurgence Rod] ID:17743
    ["Mana restored per 5 seconds"] = {"COMBAT_MANA_REGEN",}, -- Magister's Armor Kit +3 Mana restored per 5 seconds http://wow.allakhazam.com/db/spell.html?wspell=32399
    ["Mana Regenper 5 sec"] = {"COMBAT_MANA_REGEN",}, -- Enchant Bracer - Mana Regeneration "Mana Regen 4 per 5 sec." http://wow.allakhazam.com/db/spell.html?wspell=23801
    ["Mana per 5 Sec"] = {"COMBAT_MANA_REGEN",}, -- Enchant Bracer - Restore Mana Prime "6 Mana per 5 Sec." http://wow.allakhazam.com/db/spell.html?wspell=27913
    ["Health and Mana every 5 sec"] = {"COMBAT_HEALTH_REGEN", "COMBAT_MANA_REGEN",}, -- Greater Vitality EnchantID: 3244

    ["Spell Penetration"] = {"SPELLPEN",}, -- Enchant Cloak - Spell Penetration "+20 Spell Penetration" http://wow.allakhazam.com/db/spell.html?wspell=34003
    ["Increases your spell penetration"] = {"SPELLPEN",},

    ["Healing and Spell Damage"] = {"SPELL_DMG", "HEAL",}, -- Arcanum of Focus +8 Healing and Spell Damage http://wow.allakhazam.com/db/spell.html?wspell=22844
    ["Damage and Healing Spells"] = {"SPELL_DMG", "HEAL",},
    ["Spell Damage and Healing"] = {"SPELL_DMG", "HEAL",},
    ["Spell Damage"] = {"SPELL_DMG", "HEAL",},
    ["Increases damage and healing done by magical spells and effects"] = {"SPELL_DMG", "HEAL"},
    ["Increases damage and healing done by magical spells and effects of all party members within 30 yards"] = {"SPELL_DMG", "HEAL"}, -- Atiesh
    ["Spell Damage and Healing"] = {"SPELL_DMG", "HEAL",}, --StatLogic:GetSum("item:22630")
    ["Damage"] = {"SPELL_DMG",},
    ["Increases your spell damage"] = {"SPELL_DMG",}, -- Atiesh ID:22630, 22631, 22632, 22589
    ["Spell Power"] = {"SPELL_DMG", "HEAL",},
    ["Increases spell power"] = {"SPELL_DMG", "HEAL",}, -- WotLK
    ["Holy Damage"] = {"HOLY_SPELL_DMG",},
    ["Arcane Damage"] = {"ARCANE_SPELL_DMG",},
    ["Fire Damage"] = {"FIRE_SPELL_DMG",},
    ["Nature Damage"] = {"NATURE_SPELL_DMG",},
    ["Frost Damage"] = {"FROST_SPELL_DMG",},
    ["Shadow Damage"] = {"SHADOW_SPELL_DMG",},
    ["Holy Spell Damage"] = {"HOLY_SPELL_DMG",},
    ["Arcane Spell Damage"] = {"ARCANE_SPELL_DMG",},
    ["Fire Spell Damage"] = {"FIRE_SPELL_DMG",},
    ["Nature Spell Damage"] = {"NATURE_SPELL_DMG",},
    ["Frost Spell Damage"] = {"FROST_SPELL_DMG",}, -- Acrobatic Staff of Frozen Wrath ID:3185:0:0:0:0:0:1957
    ["Shadow Spell Damage"] = {"SHADOW_SPELL_DMG",},
    ["Shadow and Frost Spell Power"] = {"SHADOW_SPELL_DMG", "FROST_SPELL_DMG",}, -- Soulfrost
    ["Arcane and Fire Spell Power"] = {"ARCANE_SPELL_DMG", "FIRE_SPELL_DMG",}, -- Sunfire
    ["Increases damage done by Shadow spells and effects"] = {"SHADOW_SPELL_DMG",}, -- Frozen Shadoweave Vest ID:21871
    ["Increases damage done by Frost spells and effects"] = {"FROST_SPELL_DMG",}, -- Frozen Shadoweave Vest ID:21871
    ["Increases damage done by Holy spells and effects"] = {"HOLY_SPELL_DMG",},
    ["Increases damage done by Arcane spells and effects"] = {"ARCANE_SPELL_DMG",},
    ["Increases damage done by Fire spells and effects"] = {"FIRE_SPELL_DMG",},
    ["Increases damage done by Nature spells and effects"] = {"NATURE_SPELL_DMG",},
    ["Increases the damage done by Holy spells and effects"] = {"HOLY_SPELL_DMG",}, -- Drape of the Righteous ID:30642
    ["Increases the damage done by Arcane spells and effects"] = {"ARCANE_SPELL_DMG",}, -- Added just in case
    ["Increases the damage done by Fire spells and effects"] = {"FIRE_SPELL_DMG",}, -- Added just in case
    ["Increases the damage done by Frost spells and effects"] = {"FROST_SPELL_DMG",}, -- Added just in case
    ["Increases the damage done by Nature spells and effects"] = {"NATURE_SPELL_DMG",}, -- Added just in case
    ["Increases the damage done by Shadow spells and effects"] = {"SHADOW_SPELL_DMG",}, -- Added just in case

    ["Increases damage done to Undead by magical spells and effects"] = {"SPELL_DMG_UNDEAD"}, -- [Robe of Undead Cleansing] ID:23085
    ["Increases damage done to Undead by magical spells and effects.  It also allows the acquisition of Scourgestones on behalf of the Argent Dawn"] = {"SPELL_DMG_UNDEAD"}, -- [Rune of the Dawn] ID:19812
    ["Increases damage done to Undead and Demons by magical spells and effects"] = {"SPELL_DMG_UNDEAD", "SPELL_DMG_DEMON"}, -- [Mark of the Champion] ID:23207

    ["Healing Spells"] = {"HEAL",}, -- Enchant Gloves - Major Healing "+35 Healing Spells" http://wow.allakhazam.com/db/spell.html?wspell=33999
    ["Increases Healing"] = {"HEAL",},
    ["Healing"] = {"HEAL",}, -- StatLogic:GetSum("item:23344:206")
    ["healing Spells"] = {"HEAL",},
    ["Damage Spells"] = {"SPELL_DMG",}, -- 2.3.0 StatLogic:GetSum("item:23344:2343")
    ["Healing Spells"] = {"HEAL",}, -- [Royal Nightseye] ID: 24057
    ["Increases healing done"] = {"HEAL",}, -- 2.3.0
    ["damage donefor all magical spells"] = {"SPELL_DMG",}, -- 2.3.0
    ["Increases healing done by spells and effects"] = {"HEAL",},
    ["Increases healing done by magical spells and effects of all party members within 30 yards"] = {"HEAL",}, -- Atiesh
    ["your healing"] = {"HEAL",}, -- Atiesh

    ["damage per second"] = {"DPS",},
    ["Addsdamage per second"] = {"DPS",}, -- [Thorium Shells] ID: 15977

    ["Defense Rating"] = {"DEFENSE_RATING",},
    ["Increases defense rating"] = {"DEFENSE_RATING",},
    ["Dodge Rating"] = {"DODGE_RATING",},
    ["Increases your dodge rating"] = {"DODGE_RATING",},
    ["Parry Rating"] = {"PARRY_RATING",},
    ["Increases your parry rating"] = {"PARRY_RATING",},
    ["Shield Block Rating"] = {"BLOCK_RATING",}, -- Enchant Shield - Lesser Block +10 Shield Block Rating http://wow.allakhazam.com/db/spell.html?wspell=13689
    ["Block Rating"] = {"BLOCK_RATING",},
    ["Increases your block rating"] = {"BLOCK_RATING",},
    ["Increases your shield block rating"] = {"BLOCK_RATING",},

    ["Hit Rating"] = {"MELEE_HIT_RATING", "SPELL_HIT_RATING"},
    ["Improves hit rating"] = {"MELEE_HIT_RATING", "SPELL_HIT_RATING"}, -- ITEM_MOD_HIT_RATING
    ["Increases your hit rating"] = {"MELEE_HIT_RATING", "SPELL_HIT_RATING"},
    ["Improves melee hit rating"] = {"MELEE_HIT_RATING",}, -- ITEM_MOD_HIT_MELEE_RATING
    ["Spell Hit"] = {"SPELL_HIT_RATING",}, -- Presence of Sight +18 Healing and Spell Damage/+8 Spell Hit http://wow.allakhazam.com/db/spell.html?wspell=24164
    ["Spell Hit Rating"] = {"SPELL_HIT_RATING",},
    ["Improves spell hit rating"] = {"SPELL_HIT_RATING",}, -- ITEM_MOD_HIT_SPELL_RATING
    ["Increases your spell hit rating"] = {"SPELL_HIT_RATING",},
    ["Ranged Hit Rating"] = {"RANGED_HIT_RATING",}, -- Biznicks 247x128 Accurascope EnchantID: 2523
    ["Improves ranged hit rating"] = {"RANGED_HIT_RATING",}, -- ITEM_MOD_HIT_RANGED_RATING
    ["Increases your ranged hit rating"] = {"RANGED_HIT_RATING",},

    ["Crit Rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Critical Rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Critical Strike Rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Increases your critical hit rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Increases your critical strike rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Improves critical strike rating"] = {"MELEE_CRIT_RATING", "SPELL_CRIT_RATING"},
    ["Improves melee critical strike rating"] = {"MELEE_CRIT_RATING",}, -- [Cloak of Darkness] ID:33122
    ["Spell Critical Strike Rating"] = {"SPELL_CRIT_RATING",},
    ["Spell Critical strike rating"] = {"SPELL_CRIT_RATING",},
    ["Spell Critical Rating"] = {"SPELL_CRIT_RATING",},
    ["Spell Crit Rating"] = {"SPELL_CRIT_RATING",},
    ["Increases your spell critical strike rating"] = {"SPELL_CRIT_RATING",},
    ["Increases the spell critical strike rating of all party members within 30 yards"] = {"SPELL_CRIT_RATING",},
    ["Improves spell critical strike rating"] = {"SPELL_CRIT_RATING",},
    ["Increases your ranged critical strike rating"] = {"RANGED_CRIT_RATING",}, -- Fletcher's Gloves ID:7348
    ["Ranged Critical Strike"] = {"RANGED_CRIT_RATING",}, -- Heartseeker Scope EnchantID: 3608

    --["Improves hit avoidance rating"] = {"MELEE_HIT_AVOID_RATING"}, -- ITEM_MOD_HIT_TAKEN_RATING
    --["Improves melee hit avoidance rating"] = {"MELEE_HIT_AVOID_RATING"}, -- ITEM_MOD_HIT_TAKEN_MELEE_RATING
    ["Improves ranged hit avoidance rating"] = {"RANGED_HIT_AVOID_RATING"}, -- ITEM_MOD_HIT_TAKEN_RANGED_RATING
    ["Improves spell hit avoidance rating"] = {"SPELL_HIT_AVOID_RATING"}, -- ITEM_MOD_HIT_TAKEN_SPELL_RATING
    ["Resilience"] = {"RESILIENCE_RATING",},
    ["Resilience Rating"] = {"RESILIENCE_RATING",}, -- Enchant Chest - Major Resilience "+15 Resilience Rating" http://wow.allakhazam.com/db/spell.html?wspell=33992
    ["Improves your resilience rating"] = {"RESILIENCE_RATING",},
    ["Improves critical avoidance rating"] = {"MELEE_CRIT_AVOID_RATING",},
    ["Improves melee critical avoidance rating"] = {"MELEE_CRIT_AVOID_RATING",},
    ["Improves ranged critical avoidance rating"] = {"RANGED_CRIT_AVOID_RATING",},
    ["Improves spell critical avoidance rating"] = {"SPELL_CRIT_AVOID_RATING",},

    ["Haste Rating"] = {"MELEE_HASTE_RATING", "SPELL_HASTE_RATING"},
    ["Improves haste rating"] = {"MELEE_HASTE_RATING", "SPELL_HASTE_RATING"},
    ["Improves melee haste rating"] = {"MELEE_HASTE_RATING"},
    ["Spell Haste Rating"] = {"SPELL_HASTE_RATING"},
    ["Improves spell haste rating"] = {"SPELL_HASTE_RATING"},
    ["Ranged Haste Rating"] = {"RANGED_HASTE_RATING"}, -- Micro Stabilizer EnchantID: 3607
    ["Improves ranged haste rating"] = {"RANGED_HASTE_RATING"},

    ["Increases dagger skill rating"] = {"DAGGER_WEAPON_RATING"},
    ["Increases sword skill rating"] = {"SWORD_WEAPON_RATING"}, -- [Warblade of the Hakkari] ID:19865
    ["Increases Two-Handed Swords skill rating"] = {"2H_SWORD_WEAPON_RATING"},
    ["Increases axe skill rating"] = {"AXE_WEAPON_RATING"},
    ["Two-Handed Axe Skill Rating"] = {"2H_AXE_WEAPON_RATING"}, -- [Ethereum Nexus-Reaver] ID:30722
    ["Increases two-handed axes skill rating"] = {"2H_AXE_WEAPON_RATING"},
    ["Increases mace skill rating"] = {"MACE_WEAPON_RATING"},
    ["Increases two-handed maces skill rating"] = {"2H_MACE_WEAPON_RATING"},
    ["Increases gun skill rating"] = {"GUN_WEAPON_RATING"},
    ["Increases Crossbow skill rating"] = {"CROSSBOW_WEAPON_RATING"},
    ["Increases Bow skill rating"] = {"BOW_WEAPON_RATING"},
    ["Increases feral combat skill rating"] = {"FERAL_WEAPON_RATING"},
    ["Increases fist weapons skill rating"] = {"FIST_WEAPON_RATING"}, -- Demonblood Eviscerator
    ["Increases unarmed skill rating"] = {"FIST_WEAPON_RATING"}, -- Demonblood Eviscerator ID:27533
    ["Increases staff skill rating"] = {"STAFF_WEAPON_RATING"}, -- Leggings of the Fang ID:10410

    ["expertise rating"] = {"EXPERTISE_RATING"}, -- gems
    ["Increases your expertise rating"] = {"EXPERTISE_RATING"},
    ["armor penetration rating"] = {"ARMOR_PENETRATION_RATING"}, -- gems
    ["Increases armor penetration rating"] = {"ARMOR_PENETRATION_RATING"},
    ["Increases your armor penetration rating"] = {"ARMOR_PENETRATION_RATING"}, -- ID:43178

    --["mastery rating"] = {"MASTERY_RATING"}, -- gems
    --["Increases your mastery rating"] = {"MASTERY_RATING"},

    -- Exclude
    ["sec"] = false,
    ["to"] = false,
    ["Slot Bag"] = false,
    ["Slot Quiver"] = false,
    ["Slot Ammo Pouch"] = false,
    ["Increases ranged attack speed"] = false, -- AV quiver
  },
}
DisplayLocale.ptBR = {
  ----------------
  -- Stat Names --
  ----------------
  -- Please localize these strings too, global strings were used in the enUS locale just to have minimum
  -- localization effect when a locale is not available for that language, you don't have to use global
  -- strings in your localization.
  ["Stat Multiplier"] = "Stat Multiplier",
  ["Attack Power Multiplier"] = "Attack Power Multiplier",
  ["Reduced Physical Damage Taken"] = "Reduced Physical Damage Taken",
  ["StatIDToName"] = {
    --[StatID] = {FullName, ShortName},
    ---------------------------------------------------------------------------
    -- Tier1 Stats - Stats parsed directly off items
    ["EMPTY_SOCKET_RED"] = {EMPTY_SOCKET_RED, EMPTY_SOCKET_RED}, -- EMPTY_SOCKET_RED = "Red Socket";
    ["EMPTY_SOCKET_YELLOW"] = {EMPTY_SOCKET_YELLOW, EMPTY_SOCKET_YELLOW}, -- EMPTY_SOCKET_YELLOW = "Yellow Socket";
    ["EMPTY_SOCKET_BLUE"] = {EMPTY_SOCKET_BLUE, EMPTY_SOCKET_BLUE}, -- EMPTY_SOCKET_BLUE = "Blue Socket";
    ["EMPTY_SOCKET_META"] = {EMPTY_SOCKET_META, EMPTY_SOCKET_META}, -- EMPTY_SOCKET_META = "Meta Socket";

    ["IGNORE_ARMOR"] = {"Ignore Armor", "Ignore Armor"},
    ["MOD_THREAT"] = {"Threat", "Threat", isPercent = true},
    ["STEALTH_LEVEL"] = {"Stealth Level", "Stealth", isPercent = true},
    ["MELEE_DMG"] = {"Melee Weapon "..DAMAGE, "Wpn Dmg", isPercent = true}, -- DAMAGE = "Damage"
    ["RANGED_DMG"] = {"Ranged Weapon "..DAMAGE, "Ranged Dmg", isPercent = true}, -- DAMAGE = "Damage"
    ["MOUNT_SPEED"] = {"Mount Speed", "Mount Spd", isPercent = true},
    ["RUN_SPEED"] = {"Run Speed", "Run Spd", isPercent = true},

    ["STR"] = {SPELL_STAT1_NAME, "Str"},
    ["AGI"] = {SPELL_STAT2_NAME, "Agi"},
    ["STA"] = {SPELL_STAT3_NAME, "Sta"},
    ["INT"] = {SPELL_STAT4_NAME, "Int"},
    ["SPI"] = {SPELL_STAT5_NAME, "Spi"},
    ["ARMOR"] = {ARMOR, ARMOR},
    ["ARMOR_BONUS"] = {"Bonus "..ARMOR, "Bonus "..ARMOR},

    ["FIRE_RES"] = {RESISTANCE2_NAME, "FR"},
    ["NATURE_RES"] = {RESISTANCE3_NAME, "NR"},
    ["FROST_RES"] = {RESISTANCE4_NAME, "FrR"},
    ["SHADOW_RES"] = {RESISTANCE5_NAME, "SR"},
    ["ARCANE_RES"] = {RESISTANCE6_NAME, "AR"},

    ["FISHING"] = {"Fishing", "Fishing"},
    ["MINING"] = {"Mining", "Mining"},
    ["HERBALISM"] = {"Herbalism", "Herbalism"},
    ["SKINNING"] = {"Skinning", "Skinning"},

    ["BLOCK_VALUE"] = {"Block Value", "Block Value"},

    ["AP"] = {ATTACK_POWER_TOOLTIP, "AP"},
    ["RANGED_AP"] = {RANGED_ATTACK_POWER, "RAP"},
    ["FERAL_AP"] = {"Feral "..ATTACK_POWER_TOOLTIP, "Feral AP"},
    ["AP_UNDEAD"] = {ATTACK_POWER_TOOLTIP.." (Undead)", "AP(Undead)"},
    ["AP_DEMON"] = {ATTACK_POWER_TOOLTIP.." (Demon)", "AP(Demon)"},

    ["HEAL"] = {"Healing", "Heal"},

    ["SPELL_POWER"] = {STAT_SPELLPOWER, STAT_SPELLPOWER},
    ["SPELL_DMG"] = {PLAYERSTAT_SPELL_COMBAT.." "..DAMAGE, PLAYERSTAT_SPELL_COMBAT.." Dmg"},
    ["SPELL_DMG_UNDEAD"] = {PLAYERSTAT_SPELL_COMBAT.." "..DAMAGE.." (Undead)", PLAYERSTAT_SPELL_COMBAT.." Dmg".."(Undead)"},
    ["SPELL_DMG_DEMON"] = {PLAYERSTAT_SPELL_COMBAT.." "..DAMAGE.." (Demon)", PLAYERSTAT_SPELL_COMBAT.." Dmg".."(Demon)"},
    ["HOLY_SPELL_DMG"] = {SPELL_SCHOOL1_CAP.." "..DAMAGE, SPELL_SCHOOL1_CAP.." Dmg"},
    ["FIRE_SPELL_DMG"] = {SPELL_SCHOOL2_CAP.." "..DAMAGE, SPELL_SCHOOL2_CAP.." Dmg"},
    ["NATURE_SPELL_DMG"] = {SPELL_SCHOOL3_CAP.." "..DAMAGE, SPELL_SCHOOL3_CAP.." Dmg"},
    ["FROST_SPELL_DMG"] = {SPELL_SCHOOL4_CAP.." "..DAMAGE, SPELL_SCHOOL4_CAP.." Dmg"},
    ["SHADOW_SPELL_DMG"] = {SPELL_SCHOOL5_CAP.." "..DAMAGE, SPELL_SCHOOL5_CAP.." Dmg"},
    ["ARCANE_SPELL_DMG"] = {SPELL_SCHOOL6_CAP.." "..DAMAGE, SPELL_SCHOOL6_CAP.." Dmg"},

    ["SPELLPEN"] = {PLAYERSTAT_SPELL_COMBAT.." "..SPELL_PENETRATION, SPELL_PENETRATION},

    ["HEALTH"] = {HEALTH, HP},
    ["MANA"] = {MANA, MP},
    ["HEALTH_REGEN"] = {HEALTH.." Regen (Out of combat)", "HP5(OC)"},
    ["MANA_REGEN"] = {MANA.." Regen (Out of casting)", "MP5(OC)"},
    ["COMBAT_HEALTH_REGEN"] = {HEALTH.." Regen", "HP5"},
    ["COMBAT_MANA_REGEN"] = {MANA.." Regen", "MP5"},

    ["MAX_DAMAGE"] = {"Max Damage", "Max Dmg"},
    ["DPS"] = {"Damage Per Second", "DPS"},

    ["DEFENSE_RATING"] = {COMBAT_RATING_NAME2, COMBAT_RATING_NAME2}, -- COMBAT_RATING_NAME2 = "Defense Rating"
    ["DODGE_RATING"] = {COMBAT_RATING_NAME3, COMBAT_RATING_NAME3}, -- COMBAT_RATING_NAME3 = "Dodge Rating"
    ["PARRY_RATING"] = {COMBAT_RATING_NAME4, COMBAT_RATING_NAME4}, -- COMBAT_RATING_NAME4 = "Parry Rating"
    ["BLOCK_RATING"] = {COMBAT_RATING_NAME5, COMBAT_RATING_NAME5}, -- COMBAT_RATING_NAME5 = "Block Rating"
    ["MELEE_HIT_RATING"] = {COMBAT_RATING_NAME6, COMBAT_RATING_NAME6}, -- COMBAT_RATING_NAME6 = "Hit Rating"
    ["RANGED_HIT_RATING"] = {PLAYERSTAT_RANGED_COMBAT.." "..COMBAT_RATING_NAME6, PLAYERSTAT_RANGED_COMBAT.." "..COMBAT_RATING_NAME6}, -- PLAYERSTAT_RANGED_COMBAT = "Ranged"
    ["SPELL_HIT_RATING"] = {PLAYERSTAT_SPELL_COMBAT.." "..COMBAT_RATING_NAME6, PLAYERSTAT_SPELL_COMBAT.." "..COMBAT_RATING_NAME6}, -- PLAYERSTAT_SPELL_COMBAT = "Spell"
    --["MELEE_HIT_AVOID_RATING"] = {"Hit Avoidance "..RATING, "Hit Avoidance "..RATING},
    ["RANGED_HIT_AVOID_RATING"] = {PLAYERSTAT_RANGED_COMBAT.." Hit Avoidance "..RATING, PLAYERSTAT_RANGED_COMBAT.." Hit Avoidance "..RATING},
    ["SPELL_HIT_AVOID_RATING"] = {PLAYERSTAT_SPELL_COMBAT.." Hit Avoidance "..RATING, PLAYERSTAT_SPELL_COMBAT.." Hit Avoidance "..RATING},
    ["MELEE_CRIT_RATING"] = {COMBAT_RATING_NAME9, COMBAT_RATING_NAME9}, -- COMBAT_RATING_NAME9 = "Crit Rating"
    ["RANGED_CRIT_RATING"] = {PLAYERSTAT_RANGED_COMBAT.." "..COMBAT_RATING_NAME9, PLAYERSTAT_RANGED_COMBAT.." "..COMBAT_RATING_NAME9},
    ["SPELL_CRIT_RATING"] = {PLAYERSTAT_SPELL_COMBAT.." "..COMBAT_RATING_NAME9, PLAYERSTAT_SPELL_COMBAT.." "..COMBAT_RATING_NAME9},
    ["MELEE_CRIT_AVOID_RATING"] = {"Crit Avoidance "..RATING, "Crit Avoidance "..RATING},
    ["RANGED_CRIT_AVOID_RATING"] = {PLAYERSTAT_RANGED_COMBAT.." Crit Avoidance "..RATING, PLAYERSTAT_RANGED_COMBAT.." Crit Avoidance "..RATING},
    ["SPELL_CRIT_AVOID_RATING"] = {PLAYERSTAT_SPELL_COMBAT.." Crit Avoidance "..RATING, PLAYERSTAT_SPELL_COMBAT.." Crit Avoidance "..RATING},
    ["RESILIENCE_RATING"] = {COMBAT_RATING_NAME15, COMBAT_RATING_NAME15}, -- COMBAT_RATING_NAME15 = "Resilience"
    ["MELEE_HASTE_RATING"] = {"Haste "..RATING, "Haste "..RATING}, --
    ["RANGED_HASTE_RATING"] = {PLAYERSTAT_RANGED_COMBAT.." Haste "..RATING, PLAYERSTAT_RANGED_COMBAT.." Haste "..RATING},
    ["SPELL_HASTE_RATING"] = {PLAYERSTAT_SPELL_COMBAT.." Haste "..RATING, PLAYERSTAT_SPELL_COMBAT.." Haste "..RATING},
    ["DAGGER_WEAPON_RATING"] = {"Dagger "..SKILL.." "..RATING, "Dagger "..RATING}, -- SKILL = "Skill"
    ["SWORD_WEAPON_RATING"] = {"Sword "..SKILL.." "..RATING, "Sword "..RATING},
    ["2H_SWORD_WEAPON_RATING"] = {"Two-Handed Sword "..SKILL.." "..RATING, "2H Sword "..RATING},
    ["AXE_WEAPON_RATING"] = {"Axe "..SKILL.." "..RATING, "Axe "..RATING},
    ["2H_AXE_WEAPON_RATING"] = {"Two-Handed Axe "..SKILL.." "..RATING, "2H Axe "..RATING},
    ["MACE_WEAPON_RATING"] = {"Mace "..SKILL.." "..RATING, "Mace "..RATING},
    ["2H_MACE_WEAPON_RATING"] = {"Two-Handed Mace "..SKILL.." "..RATING, "2H Mace "..RATING},
    ["GUN_WEAPON_RATING"] = {"Gun "..SKILL.." "..RATING, "Gun "..RATING},
    ["CROSSBOW_WEAPON_RATING"] = {"Crossbow "..SKILL.." "..RATING, "Crossbow "..RATING},
    ["BOW_WEAPON_RATING"] = {"Bow "..SKILL.." "..RATING, "Bow "..RATING},
    ["FERAL_WEAPON_RATING"] = {"Feral "..SKILL.." "..RATING, "Feral "..RATING},
    ["FIST_WEAPON_RATING"] = {"Unarmed "..SKILL.." "..RATING, "Unarmed "..RATING},
    ["STAFF_WEAPON_RATING"] = {"Staff "..SKILL.." "..RATING, "Staff "..RATING}, -- Leggings of the Fang ID:10410
    --["EXPERTISE_RATING"] = {STAT_EXPERTISE.." "..RATING, STAT_EXPERTISE.." "..RATING},
    ["EXPERTISE_RATING"] = {"Expertise "..RATING, "Expertise "..RATING},
    ["ARMOR_PENETRATION_RATING"] = {"Armor Penetration "..RATING, "ArP "..RATING},
    --["MASTERY_RATING"] = {"Mastery "..RATING, "Mastery "..RATING},

    ---------------------------------------------------------------------------
    -- Tier2 Stats - Stats that only show up when broken down from a Tier1 stat
    -- Str -> AP, Block Value
    -- Agi -> AP, Crit, Dodge
    -- Sta -> Health
    -- Int -> Mana, Spell Crit
    -- Spi -> mp5nc, hp5oc
    -- Ratings -> Effect
    ["MELEE_CRIT_DMG_REDUCTION"] = {"Crit Damage Reduction", "Crit Dmg Reduc", isPercent = true},
    ["RANGED_CRIT_DMG_REDUCTION"] = {PLAYERSTAT_RANGED_COMBAT.." Crit Damage Reduction", PLAYERSTAT_RANGED_COMBAT.." Crit Dmg Reduc", isPercent = true},
    ["SPELL_CRIT_DMG_REDUCTION"] = {PLAYERSTAT_SPELL_COMBAT.." Crit Damage Reduction", PLAYERSTAT_SPELL_COMBAT.." Crit Dmg Reduc", isPercent = true},
    ["DEFENSE"] = {DEFENSE, "Def"},
    ["DODGE"] = {DODGE, DODGE, isPercent = true},
    ["PARRY"] = {PARRY, PARRY, isPercent = true},
    ["BLOCK"] = {BLOCK, BLOCK, isPercent = true},
    ["AVOIDANCE"] = {"Avoidance", "Avoidance", isPercent = true},
    ["MELEE_HIT"] = {"Hit Chance", "Hit", isPercent = true},
    ["RANGED_HIT"] = {PLAYERSTAT_RANGED_COMBAT.." Hit Chance", PLAYERSTAT_RANGED_COMBAT.." Hit", isPercent = true},
    ["SPELL_HIT"] = {PLAYERSTAT_SPELL_COMBAT.." Hit Chance", PLAYERSTAT_SPELL_COMBAT.." Hit", isPercent = true},
    ["MELEE_HIT_AVOID"] = {"Hit Avoidance", "Hit Avd", isPercent = true},
    ["RANGED_HIT_AVOID"] = {PLAYERSTAT_RANGED_COMBAT.." Hit Avoidance", PLAYERSTAT_RANGED_COMBAT.." Hit Avd", isPercent = true},
    ["SPELL_HIT_AVOID"] = {PLAYERSTAT_SPELL_COMBAT.." Hit Avoidance", PLAYERSTAT_SPELL_COMBAT.." Hit Avd", isPercent = true},
    ["MELEE_CRIT"] = {MELEE_CRIT_CHANCE, "Crit"}, -- MELEE_CRIT_CHANCE = "Crit Chance"
    ["RANGED_CRIT"] = {PLAYERSTAT_RANGED_COMBAT.." "..MELEE_CRIT_CHANCE, PLAYERSTAT_RANGED_COMBAT.." Crit", isPercent = true},
    ["SPELL_CRIT"] = {PLAYERSTAT_SPELL_COMBAT.." "..MELEE_CRIT_CHANCE, PLAYERSTAT_SPELL_COMBAT.." Crit", isPercent = true},
    ["MELEE_CRIT_AVOID"] = {"Crit Avoidance", "Crit Avd", isPercent = true},
    ["RANGED_CRIT_AVOID"] = {PLAYERSTAT_RANGED_COMBAT.." Crit Avoidance", PLAYERSTAT_RANGED_COMBAT.." Crit Avd", isPercent = true},
    ["SPELL_CRIT_AVOID"] = {PLAYERSTAT_SPELL_COMBAT.." Crit Avoidance", PLAYERSTAT_SPELL_COMBAT.." Crit Avd", isPercent = true},
    ["MELEE_HASTE"] = {"Haste", "Haste"}, --
    ["RANGED_HASTE"] = {PLAYERSTAT_RANGED_COMBAT.." Haste", PLAYERSTAT_RANGED_COMBAT.." Haste", isPercent = true},
    ["SPELL_HASTE"] = {PLAYERSTAT_SPELL_COMBAT.." Haste", PLAYERSTAT_SPELL_COMBAT.." Haste", isPercent = true},
    ["DAGGER_WEAPON"] = {"Dagger "..SKILL, "Dagger"}, -- SKILL = "Skill"
    ["SWORD_WEAPON"] = {"Sword "..SKILL, "Sword"},
    ["2H_SWORD_WEAPON"] = {"Two-Handed Sword "..SKILL, "2H Sword"},
    ["AXE_WEAPON"] = {"Axe "..SKILL, "Axe"},
    ["2H_AXE_WEAPON"] = {"Two-Handed Axe "..SKILL, "2H Axe"},
    ["MACE_WEAPON"] = {"Mace "..SKILL, "Mace"},
    ["2H_MACE_WEAPON"] = {"Two-Handed Mace "..SKILL, "2H Mace"},
    ["GUN_WEAPON"] = {"Gun "..SKILL, "Gun"},
    ["CROSSBOW_WEAPON"] = {"Crossbow "..SKILL, "Crossbow"},
    ["BOW_WEAPON"] = {"Bow "..SKILL, "Bow"},
    ["FERAL_WEAPON"] = {"Feral "..SKILL, "Feral"},
    ["FIST_WEAPON"] = {"Unarmed "..SKILL, "Unarmed"},
    ["STAFF_WEAPON"] = {"Staff "..SKILL, "Staff"}, -- Leggings of the Fang ID:10410
    --["EXPERTISE"] = {STAT_EXPERTISE, STAT_EXPERTISE},
    ["EXPERTISE"] = {"Expertise", "Expertise"},
    ["ARMOR_PENETRATION"] = {"Armor Penetration", "ArP", isPercent = true},
    ["MASTERY"] = {"Mastery", "Mastery"},

    ---------------------------------------------------------------------------
    -- Tier3 Stats - Stats that only show up when broken down from a Tier2 stat
    -- Defense -> Crit Avoidance, Hit Avoidance, Dodge, Parry, Block
    -- Weapon Skill -> Crit, Hit, Dodge Neglect, Parry Neglect, Block Neglect
    -- Expertise -> Dodge Neglect, Parry Neglect
    ["DODGE_NEGLECT"] = {DODGE.." Neglect", DODGE.." Neglect", isPercent = true},
    ["PARRY_NEGLECT"] = {PARRY.." Neglect", PARRY.." Neglect", isPercent = true},
    ["BLOCK_NEGLECT"] = {BLOCK.." Neglect", BLOCK.." Neglect", isPercent = true},

    ---------------------------------------------------------------------------
    -- Talents
    ["MELEE_CRIT_DMG"] = {"Crit Damage", "Crit Dmg", isPercent = true},
    ["RANGED_CRIT_DMG"] = {PLAYERSTAT_RANGED_COMBAT.." Crit Damage", PLAYERSTAT_RANGED_COMBAT.." Crit Dmg", isPercent = true},
    ["SPELL_CRIT_DMG"] = {PLAYERSTAT_SPELL_COMBAT.." Crit Damage", PLAYERSTAT_SPELL_COMBAT.." Crit Dmg", isPercent = true},

    ---------------------------------------------------------------------------
    -- Spell Stats
    -- These values can be prefixed with a @ and spell name, using reverse translation to english from Babble-Spell-2.2
    -- ex: "Heroic Strike@RAGE_COST" for Heroic Strike rage cost
    -- ex: "Heroic Strike@THREAT" for Heroic Strike threat value
    -- Use strsplit("@", text) to seperate the spell name and statid
    ["THREAT"] = {"Threat", "Threat"},
    ["CAST_TIME"] = {"Casting Time", "Cast Time"},
    ["MANA_COST"] = {"Mana Cost", "Mana Cost"},
    ["RAGE_COST"] = {"Rage Cost", "Rage Cost"},
    ["ENERGY_COST"] = {"Energy Cost", "Energy Cost"},
    ["COOLDOWN"] = {"Cooldown", "CD"},

    ---------------------------------------------------------------------------
    -- Stats Mods
    ["MOD_STR"] = {"Mod "..SPELL_STAT1_NAME, "Mod Str", isPercent = true},
    ["MOD_AGI"] = {"Mod "..SPELL_STAT2_NAME, "Mod Agi", isPercent = true},
    ["MOD_STA"] = {"Mod "..SPELL_STAT3_NAME, "Mod Sta", isPercent = true},
    ["MOD_INT"] = {"Mod "..SPELL_STAT4_NAME, "Mod Int", isPercent = true},
    ["MOD_SPI"] = {"Mod "..SPELL_STAT5_NAME, "Mod Spi", isPercent = true},
    ["MOD_HEALTH"] = {"Mod "..HEALTH, "Mod "..HP, isPercent = true},
    ["MOD_MANA"] = {"Mod "..MANA, "Mod "..MP, isPercent = true},
    ["MOD_ARMOR"] = {"Mod "..ARMOR.."from Items", "Mod "..ARMOR.."(Items)", isPercent = true},
    ["MOD_BLOCK_VALUE"] = {"Mod Block Value", "Mod Block Value", isPercent = true},
    ["MOD_DMG"] = {"Mod Damage", "Mod Dmg", isPercent = true},
    ["MOD_DMG_TAKEN"] = {"Mod Damage Taken", "Mod Dmg Taken", isPercent = true},
    ["MOD_CRIT_DAMAGE"] = {"Mod Crit Damage", "Mod Crit Dmg", isPercent = true},
    ["MOD_CRIT_DAMAGE_TAKEN"] = {"Mod Crit Damage Taken", "Mod Crit Dmg Taken", isPercent = true},
    ["MOD_THREAT"] = {"Mod Threat", "Mod Threat", isPercent = true},
    ["MOD_AP"] = {"Mod "..ATTACK_POWER_TOOLTIP, "Mod AP", isPercent = true},
    ["MOD_RANGED_AP"] = {"Mod "..PLAYERSTAT_RANGED_COMBAT.." "..ATTACK_POWER_TOOLTIP, "Mod RAP", isPercent = true},
    ["MOD_SPELL_DMG"] = {"Mod "..PLAYERSTAT_SPELL_COMBAT.." "..DAMAGE, "Mod "..PLAYERSTAT_SPELL_COMBAT.." Dmg", isPercent = true},
    ["MOD_HEAL"] = {"Mod Healing", "Mod Heal", isPercent = true},
    ["MOD_CAST_TIME"] = {"Mod Casting Time", "Mod Cast Time", isPercent = true},
    ["MOD_MANA_COST"] = {"Mod Mana Cost", "Mod Mana Cost", isPercent = true},
    ["MOD_RAGE_COST"] = {"Mod Rage Cost", "Mod Rage Cost", isPercent = true},
    ["MOD_ENERGY_COST"] = {"Mod Energy Cost", "Mod Energy Cost", isPercent = true},
    ["MOD_COOLDOWN"] = {"Mod Cooldown", "Mod CD", isPercent = true},
    ["CRIT_TAKEN"] = {"Chance to be critically hit", "Crit Taken", isPercent = true},
    ["HIT_TAKEN"] = {"Chance to be hit", "Hit Taken", isPercent = true},
    ["CRIT_DAMAGE_TAKEN"] = {"Critical damage taken", "Crit Dmg Taken", isPercent = true},
    ["DMG_TAKEN"] = {"Damage taken", "Dmg Taken", isPercent = true},
    ["CRIT_DAMAGE"] = {"Critical damage", "Crit Dmg", isPercent = true},
    ["DMG"] = {DAMAGE, DAMAGE},
    ["BLOCK_REDUCTION"] = {"Increases the amount your block stops by %1d", "Block Value", isPercent = true},

    ---------------------------------------------------------------------------
    -- Misc Stats
    ["WEAPON_RATING"] = {"Weapon "..SKILL.." "..RATING, "Weapon"..SKILL.." "..RATING},
    ["WEAPON_SKILL"] = {"Weapon "..SKILL, "Weapon"..SKILL},
    ["MAINHAND_WEAPON_RATING"] = {"Main Hand Weapon "..SKILL.." "..RATING, "MH Weapon"..SKILL.." "..RATING},
    ["OFFHAND_WEAPON_RATING"] = {"Off Hand Weapon "..SKILL.." "..RATING, "OH Weapon"..SKILL.." "..RATING},
    ["RANGED_WEAPON_RATING"] = {"Ranged Weapon "..SKILL.." "..RATING, "Ranged Weapon"..SKILL.." "..RATING},
  },
}
 
