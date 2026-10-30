// Horde terjadwal tiap hari kelipatan 10, tiga gelombang, cap 40 zombie,
// plus kunci tidur di malam horde.

global.za.hordeAlive = function (level) {
  return Number(level.server.runCommandSilent('execute if entity @e[tag=za_horde]'))
}

global.za.startHorde = function (level, hordeIndex) {
  const server = level.server
  const day = global.za.day(level)
  server.runCommandSilent('kill @e[tag=za_horde]')
  server.persistentData.putInt('zaHordeDay', day)
  server.persistentData.putInt('zaHordeIndex', hordeIndex)
  server.persistentData.putInt('zaWave', 0)
  server.persistentData.putInt('zaHordeSpawned', 0)
  server.runCommandSilent('tellraw @a {"text":"Horde dimulai! Index ' + hordeIndex + ', hari ' + day + '","color":"red"}')
}

global.za.spawnWave = function (level, waveIndex, hordeIndex) {
  const server = level.server
  const want = global.za.waveSize(hordeIndex)
  const room = global.za.cfg.waveCap - server.persistentData.getInt('zaHordeSpawned')
  const count = Math.max(0, Math.min(want, room))
  const players = level.players
  const psize = players.size ? players.size() : players.length
  let cx = 0
  let cz = 0
  if (psize > 0) {
    const p = players.get ? players.get(0) : players[0]
    cx = p.x
    cz = p.z
  } else {
    const sp = level.sharedSpawnPos
    cx = sp.x
    cz = sp.z
  }
  const Types = Java.loadClass('net.minecraft.world.level.levelgen.Heightmap$Types')
  for (let i = 0; i < count; i++) {
    const a = Math.random() * 6.283185307179586
    const r = global.za.cfg.ringMin + Math.random() * (global.za.cfg.ringMax - global.za.cfg.ringMin)
    const x = (cx + Math.cos(a) * r).toFixed(2)
    const z = (cz + Math.sin(a) * r).toFixed(2)
    const y = level.getHeight(Types.MOTION_BLOCKING, Math.floor(x), Math.floor(z))
    server.runCommandSilent('summon minecraft:zombie ' + x + ' ' + y + ' ' + z + ' {Tags:["za_horde"],PersistenceRequired:1b}')
  }
  server.persistentData.putInt('zaHordeSpawned', server.persistentData.getInt('zaHordeSpawned') + count)
  server.runCommandSilent('tellraw @a {"text":"Gelombang ' + (waveIndex + 1) + '!","color":"yellow"}')
  return count
}

global.za.endHorde = function (level) {
  const server = level.server
  server.runCommandSilent('kill @e[tag=za_horde]')
  server.persistentData.putInt('zaHordeDay', 0)
  server.persistentData.putInt('zaHordeIndex', 0)
  server.persistentData.putInt('zaWave', 0)
  server.persistentData.putInt('zaHordeSpawned', 0)
  server.runCommandSilent('tellraw @a {"text":"Horde berakhir.","color":"green"}')
}

global.za.hordeStatus = function (level) {
  const pd = level.server.persistentData
  const activeDay = pd.getInt('zaHordeDay')
  if (activeDay <= 0) return 'idle'
  return 'active index=' + pd.getInt('zaHordeIndex') + ' day=' + activeDay + ' count=' + global.za.hordeAlive(level)
}

global.za.hordeTick = function (server) {
  const level = server.getOverworld()
  const day = global.za.day(level)
  const tod = global.za.dayTicks(level) % 24000
  const pd = server.persistentData
  const activeDay = pd.getInt('zaHordeDay')

  if (activeDay <= 0) {
    if (global.za.isHordeDay(day) && tod >= 13000 && tod < global.za.cfg.hordeEndTick) {
      global.za.startHorde(level, global.za.hordeIndex(day))
    }
    return
  }

  if (day !== activeDay || tod >= global.za.cfg.hordeEndTick) {
    global.za.endHorde(level)
    return
  }

  const wave = pd.getInt('zaWave')
  if (wave < 3 && tod >= global.za.cfg.waveTicks[wave]) {
    global.za.spawnWave(level, wave, pd.getInt('zaHordeIndex'))
    pd.putInt('zaWave', wave + 1)
  }
}

ServerEvents.tick(event => {
  if (event.server.tickCount % 20 !== 0) return
  global.za.hordeTick(event.server)
})

BlockEvents.rightClicked('#minecraft:beds', event => {
  if (global.za.blockSleep(event.level)) {
    event.cancel()
    event.player.setStatusMessage(Text.red('Tidak bisa tidur saat horde!'))
  }
})

ServerEvents.commandRegistry(event => {
  const { commands: Commands, arguments: Arguments } = event

  event.register(
    Commands.literal('zombieapoc')
      .then(
        Commands.literal('hordeStatus').executes(ctx => {
          ctx.source.sendSystemMessage(Text.string(global.za.hordeStatus(ctx.source.level)))
          return 1
        })
      )
      .then(
        Commands.literal('sethorde').then(
          Commands.argument('n', Arguments.INTEGER.create(event)).executes(ctx => {
            const n = Arguments.INTEGER.getResult(ctx, 'n')
            if (n <= 0) {
              global.za.endHorde(ctx.source.level)
            } else {
              global.za.startHorde(ctx.source.level, n)
            }
            ctx.source.sendSystemMessage(Text.string(global.za.hordeStatus(ctx.source.level)))
            return 1
          })
        )
      )
  )
})
