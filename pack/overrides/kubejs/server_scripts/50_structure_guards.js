// Penjaga struktur: kontainer hasil generate (punya LootTable) dijaga
// 2-4 zombie saat pertama kali dibuka. Posisi dicatat di persistentData
// agar tidak berulang, maksimal 500 posisi.

function zaGuardKey(pos) {
  return Math.floor(pos.x) + ',' + Math.floor(pos.y) + ',' + Math.floor(pos.z)
}

global.za.guardAt = function (level, pos, day) {
  const pd = level.server.persistentData
  const raw = pd.contains('zaGuardKeys') ? String(pd.getString('zaGuardKeys')) : ''
  const keys = raw === '' ? [] : raw.split(';')
  const key = zaGuardKey(pos)
  if (keys.indexOf(key) >= 0) return 0
  if (keys.length >= 500) return 0
  keys.push(key)
  pd.putString('zaGuardKeys', keys.join(';'))

  const n = 2 + Math.floor(Math.random() * 3)
  const Types = Java.loadClass('net.minecraft.world.level.levelgen.Heightmap$Types')
  const server = level.server
  for (let i = 0; i < n; i++) {
    const a = Math.random() * 6.283185307179586
    const d = 2 + Math.random() * 2
    const x = Math.floor(pos.x + Math.cos(a) * d) + 0.5
    const z = Math.floor(pos.z + Math.sin(a) * d) + 0.5
    const y = level.getHeight(Types.MOTION_BLOCKING, Math.floor(x), Math.floor(z))
    server.runCommandSilent(
      'summon minecraft:zombie ' + x + ' ' + y + ' ' + z +
      ' {Tags:["za_guard"],PersistenceRequired:1b}'
    )
  }
  return n
}

BlockEvents.rightClicked(event => {
  const block = event.block
  if (block == null) return
  const id = String(block.id)
  if (id !== 'minecraft:chest' && id !== 'minecraft:trapped_chest' && id !== 'minecraft:barrel') return
  const ed = block.entityData
  if (ed == null || !ed.contains('LootTable')) return
  const n = global.za.guardAt(event.level, block.pos, global.za.day(event.level))
  if (n > 0) event.player.tell(Text.gold('Zombie penjaga bangkit!'))
})

ServerEvents.commandRegistry(event => {
  const { commands: Commands, arguments: Arguments } = event

  event.register(
    Commands.literal('zombieapoc')
      .then(
        Commands.literal('guardTest')
          .then(
            Commands.argument('x', Arguments.INTEGER.create(event))
              .then(
                Commands.argument('y', Arguments.INTEGER.create(event))
                  .then(
                    Commands.argument('z', Arguments.INTEGER.create(event)).executes(ctx => {
                      const x = Arguments.INTEGER.getResult(ctx, 'x')
                      const y = Arguments.INTEGER.getResult(ctx, 'y')
                      const z = Arguments.INTEGER.getResult(ctx, 'z')
                      const level = ctx.source.level
                      const n = global.za.guardAt(level, { x: x, y: y, z: z }, global.za.day(level))
                      ctx.source.sendSystemMessage(Text.string(n > 0 ? 'guarded ' + n : 'already guarded'))
                      return n > 0 ? 1 : 0
                    })
                  )
              )
          )
      )
      .then(
        Commands.literal('guardReset').executes(ctx => {
          ctx.source.server.persistentData.putString('zaGuardKeys', '')
          ctx.source.sendSystemMessage(Text.string('guards reset'))
          return 1
        })
      )
  )
})
