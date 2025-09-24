# prix_scrapyard

**prix_scrapyard** is a FiveM resource that allows players to scrap vehicles and receive metal scrap.  

For full documentation, see: [docs](https://prix.gitbook.io/resources/res/scrapyard)

---

## Dependencies
- [prix_core](https://freeroam.gitbook.io/main/framework/core) (required)  
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- **Prix Framework (or ESX Framework)**

---

## Inventory Item
Add the following to `ox_inventory/data/items.lua`:

```lua
['scrapmetal'] = {
    label = "Metal Scrap",
    weight = 100,         -- weight in grams
    stack = true,         -- allows stacking
    close = true,         -- closes inventory menu after use
    description = "Pieces of metal obtained from scrapping vehicles."
},
```

This item must exist in your ox_inventory for the script to work properly.
