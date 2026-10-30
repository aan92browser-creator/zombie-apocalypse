// Armor kulit berinsulasi wool. Tier kulit (= armor kulit vanilla) plus
// insulasi Cold Sweat dari datapack: data/zombie_apocalypse/cold_sweat/item/insulator.
StartupEvents.registry('item', event => {
  const parts = ['helmet', 'chestplate', 'leggings', 'boots']
  for (let i = 0; i < parts.length; i++) {
    event.create('insulated_leather_' + parts[i], parts[i]).tier('leather')
  }
})
