// Kit pertama bergabung: armor kulit berinsulasi, pistol + 64 peluru,
// makanan, air, dan obor. Item armor baru ada setelah Task 10; karena itu
// kit disimpan sebagai data dan baru di-resolve saat diberikan.

global.za.kitEntries = function () {
  return [
    { id: 'kubejs:insulated_leather_helmet', count: 1, nbt: '' },
    { id: 'kubejs:insulated_leather_chestplate', count: 1, nbt: '' },
    { id: 'kubejs:insulated_leather_leggings', count: 1, nbt: '' },
    { id: 'kubejs:insulated_leather_boots', count: 1, nbt: '' },
    { id: 'tacz:modern_kinetic_gun', count: 1, nbt: '{GunId:"tacz:glock_17"}' },
    { id: 'tacz:ammo', count: 64, nbt: '{AmmoId:"tacz:9mm"}' },
    { id: 'minecraft:cooked_beef', count: 8, nbt: '' },
    { id: 'minecraft:potion', count: 4, nbt: '{Potion:"minecraft:water",Purity:3}' },
    { id: 'minecraft:torch', count: 8, nbt: '' },
  ]
}

global.za.kitPreview = function () {
  return global.za.kitEntries().map(function (e) {
    return e.count + 'x ' + e.id
  })
}

global.za.giveKit = function (player) {
  global.za.kitEntries().forEach(function (e) {
    const stack = e.nbt !== '' ? Item.of(e.id, e.count, e.nbt) : Item.of(e.id, e.count)
    player.give(stack)
  })
}

PlayerEvents.loggedIn(event => {
  const player = event.player
  if (player.persistentData.getBoolean('zaKit')) return
  global.za.giveKit(player)
  player.persistentData.putBoolean('zaKit', true)
  player.tell(Text.gold('Kit bertahan hidup diterima. Selamat bertahan!'))
  player.tell(Text.gray('Cari reruntuhan untuk loot, dan waspada horde tiap 10 hari.'))
})

ServerEvents.commandRegistry(event => {
  const { commands: Commands } = event

  event.register(
    Commands.literal('zombieapoc').then(
      Commands.literal('kitPreview').executes(ctx => {
        global.za.kitPreview().forEach(function (line) {
          ctx.source.sendSystemMessage(Text.string(line))
        })
        return 1
      })
    )
  )
})
