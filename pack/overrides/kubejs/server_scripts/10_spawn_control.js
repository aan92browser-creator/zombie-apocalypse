// Kontrol spawn (hanya keluarga zombie), kunci Nether/End.
// Id entity dibaca dari entity, bukan dari event.type. Hewan pasif dibiarkan
// (wol untuk armor, makanan).

// Di Forge 47.3.0 event checkSpawn hanya terpicu dari spawner blok (KubeJS
// memetakannya ke MobSpawnEvent.FinalizeSpawn), jadi spawn alami lolos.
// spawned memakai EntityJoinLevelEvent sehingga menangkap semua jalur spawn.
EntityEvents.spawned(event => {
  if (global.za.shouldCancelSpawn(event.entity.type)) {
    event.cancel()
  }
})

// Portal Nether tidak bisa dinyalakan.
BlockEvents.rightClicked('minecraft:obsidian', event => {
  if (event.item.id === 'minecraft:flint_and_steel') {
    event.cancel()
  }
})

// Mata ender tidak bisa dipasang di frame portal End.
ItemEvents.rightClicked('minecraft:ender_eye', event => {
  if (event.block.id === 'minecraft:end_portal_frame') {
    event.cancel()
  }
})

// Siapa pun yang sampai ke Nether/End dikembalikan ke spawn overworld.
PlayerEvents.tick(event => {
  const player = event.player
  if (player.server.tickCount % 100 !== 0) return
  const dim = String(player.level.dimension)
  if (dim !== 'minecraft:the_nether' && dim !== 'minecraft:the_end') return
  const spawn = player.server.getOverworld().sharedSpawnPos
  player.teleportTo('minecraft:overworld', spawn.x + 0.5, spawn.y, spawn.z + 0.5, 0, 0)
})
