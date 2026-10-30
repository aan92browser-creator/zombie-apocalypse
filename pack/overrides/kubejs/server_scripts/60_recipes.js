// Temuan probe Task 10:
// - Cold Sweat 2.4.4 mendukung insulasi data-driven per item:
//   data/<ns>/cold_sweat/item/insulator/<nama>.json dengan bentuk
//   { type: "armor", item.items, entity.equipment, attributes:
//     { "cold_sweat:cold_dampening": [{ name, amount, operation }] } }
//   Item armor custom aman memakai skema ini (tidak perlu fallback tick).
// - TaCZ 1.1.8 memakai tipe resep sendiri `tacz:gun_smith_table_crafting`
//   dan resepnya dibaca dari paket gun di assets/tacz/custom (bukan datapack),
//   jadi amunisi dibuat lewat crafting table KubeJS memakai Item.of + NBT
//   AmmoId, bukan menyuntik tipe resep TaCZ.

global.za.recipeIds = {
  'kubejs:insulated_leather_helmet': 'zombieapoc:insulated_leather_helmet',
  'kubejs:insulated_leather_chestplate': 'zombieapoc:insulated_leather_chestplate',
  'kubejs:insulated_leather_leggings': 'zombieapoc:insulated_leather_leggings',
  'kubejs:insulated_leather_boots': 'zombieapoc:insulated_leather_boots',
  'kubejs:ammo_basic': 'zombieapoc:ammo_basic',
  'kubejs:gunpowder': 'zombieapoc:gunpowder',
  'kubejs:water_bottle': 'zombieapoc:water_bottle',
  'kubejs:backpack': 'zombieapoc:backpack'
}

global.za.recipeCheck = function (server, id) {
  const mapped = global.za.recipeIds[String(id)]
  if (mapped == null) return false
  const parts = String(mapped).split(':')
  const rl = new (Java.loadClass('net.minecraft.resources.ResourceLocation'))(parts[0], parts[1])
  return server.getRecipeManager().byKey(rl).isPresent()
}

ServerEvents.recipes(event => {
  const parts = ['helmet', 'chestplate', 'leggings', 'boots']
  const leather = ['leather_helmet', 'leather_chestplate', 'leather_leggings', 'leather_boots']
  for (let i = 0; i < parts.length; i++) {
    event
      .shapeless('kubejs:insulated_leather_' + parts[i], ['minecraft:' + leather[i], '2x #minecraft:wool'])
      .id('zombieapoc:insulated_leather_' + parts[i])
  }

  event
    .shapeless(Item.of('tacz:ammo', 8, '{AmmoId:"tacz:9mm"}'), [
      'minecraft:gunpowder',
      'minecraft:iron_nugget',
      'minecraft:paper'
    ])
    .id('zombieapoc:ammo_basic')

  event
    .shapeless(Item.of('minecraft:gunpowder', 2), ['minecraft:charcoal', 'minecraft:flint', 'minecraft:sand'])
    .id('zombieapoc:gunpowder')

  event
    .shapeless(Item.of('minecraft:potion', 1, '{Potion:"minecraft:water"}'), [
      '4x minecraft:snowball',
      'minecraft:glass_bottle'
    ])
    .id('zombieapoc:water_bottle')

  event
    .shaped('sophisticatedbackpacks:backpack', ['LLL', 'LWL', 'SWS'], {
      L: 'minecraft:leather',
      W: '#minecraft:wool',
      S: 'minecraft:string'
    })
    .id('zombieapoc:backpack')
})

ServerEvents.commandRegistry(event => {
  const { commands: Commands, arguments: Arguments } = event

  event.register(
    Commands.literal('zombieapoc')
      .then(
        Commands.literal('recipeCheck').then(
          Commands.argument('id', Arguments.RESOURCE_LOCATION.create(event)).executes(ctx => {
            const id = String(Arguments.RESOURCE_LOCATION.getResult(ctx, 'id'))
            const ok = global.za.recipeCheck(ctx.source.server, id)
            ctx.source.sendSystemMessage(Text.string(String(ok)))
            return 1
          })
        )
      )
  )
})
