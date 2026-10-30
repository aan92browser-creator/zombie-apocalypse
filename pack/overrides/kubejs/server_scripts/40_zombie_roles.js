// Role zombie: perlengkapan bertingkat sesuai hari, mutant, dan aturan
// penghancuran blok (pickaxe untuk batu/ore, axe untuk kayu).

const ZA_RAD = 0.017453292519943295
const ZA_PICK_TARGET = /(_ore$|stone|deepslate|andesite|diorite|granite|tuff|basalt|cobble|brick)/
const ZA_AXE_TARGET = /(_log$|_wood$|_planks$|_stem$|_hyphae$|_fence$|_fence_gate$|_door$|_trapdoor$|_sign$)/

global.za.canBreak = function (role, blockId) {
  const id = String(blockId)
  if (role === 'pickaxe') return ZA_PICK_TARGET.test(id)
  if (role === 'axe') return ZA_AXE_TARGET.test(id)
  return false
}

global.za.roleWeights = function (day) {
  const d = global.za.cfg.roleDays
  const list = [['base', 50]]
  if (day >= d.armor) list.push(['armored', 25])
  if (day >= d.tools) {
    list.push(['pickaxe', 12])
    list.push(['axe', 12])
  }
  if (day >= d.ender) list.push(['pearl', 10])
  return list
}

global.za.roleFor = function (day, rng) {
  const list = global.za.roleWeights(day)
  let total = 0
  for (let i = 0; i < list.length; i++) total += list[i][1]
  let r = rng() * total
  for (let i = 0; i < list.length; i++) {
    r -= list[i][1]
    if (r < 0) return list[i][0]
  }
  return 'base'
}

global.za.isMutantRoll = function (day, rng) {
  return rng() < global.za.mutantChance(day)
}

global.za.applyRole = function (entity, role) {
  const d = global.za.cfg.roleDays
  const level = entity.level
  const day = level ? global.za.day(level) : 1
  const tier = day >= d.iron ? 'iron' : day >= d.tools ? 'stone' : 'wooden'
  const armorTier = day >= d.iron ? 'iron' : day >= d.armor ? 'leather' : ''
  if (armorTier !== '') {
    entity.setItemSlot('head', Item.of('minecraft:' + armorTier + '_helmet'))
    entity.setItemSlot('chest', Item.of('minecraft:' + armorTier + '_chestplate'))
    entity.setItemSlot('legs', Item.of('minecraft:' + armorTier + '_leggings'))
    entity.setItemSlot('feet', Item.of('minecraft:' + armorTier + '_boots'))
  }
  if (role === 'pickaxe') entity.setMainHandItem(Item.of('minecraft:' + tier + '_pickaxe'))
  else if (role === 'axe') entity.setMainHandItem(Item.of('minecraft:' + tier + '_axe'))
  else entity.setMainHandItem(Item.of('minecraft:' + tier + '_sword'))
  if (role === 'pearl') {
    entity.setItemSlot('offhand', Item.of('minecraft:ender_pearl', 3))
    entity.persistentData.putInt('zaPearls', 3)
  }
  entity.addTag('za_role_' + role)
  entity.persistentData.putString('zaRole', role)
}

global.za.applyMutant = function (entity) {
  const hp = Math.round(entity.maxHealth * (3 + Math.random()))
  entity.setMaxHealth(hp)
  entity.health = hp
  const dmg = entity.getAttribute('minecraft:generic.attack_damage')
  if (dmg != null) dmg.setBaseValue(6)
  const kb = entity.getAttribute('minecraft:generic.knockback_resistance')
  if (kb != null) kb.setBaseValue(0.8)
  entity.addTag('za_mutant')
  entity.persistentData.putBoolean('zaMutant', true)
  if (Platform.isLoaded('pehkui')) {
    const ScaleTypes = Java.loadClass('virtuoel.pehkui.api.ScaleTypes')
    const sd = ScaleTypes.BASE.getScaleData(entity)
    sd.setBaseScale(1.4)
    sd.setTargetScale(1.4)
  }
}

function zaNearestPlayer(level, entity) {
  const players = level.players
  const n = players.size ? players.size() : players.length
  let best = null
  let bestD = 0
  for (let i = 0; i < n; i++) {
    const p = players.get ? players.get(i) : players[i]
    const dx = p.x - entity.x
    const dy = p.y - entity.y
    const dz = p.z - entity.z
    const d = dx * dx + dy * dy + dz * dz
    if (best === null || d < bestD) {
      best = p
      bestD = d
    }
  }
  return best === null ? null : { player: best, dist: Math.sqrt(bestD) }
}

global.za.roleTick = function (server) {
  const level = server.getOverworld()
  const list = level.entities
  const size = list.size ? list.size() : list.length
  const now = global.za.dayTicks(level)
  const horde = server.persistentData.getInt('zaHordeDay') > 0
  const sp = level.sharedSpawnPos
  for (let i = 0; i < size; i++) {
    const e = list.get ? list.get(i) : list[i]
    const type = String(e.type)
    if (type !== 'minecraft:zombie' && type !== 'minecraft:husk' && type !== 'minecraft:drowned') continue
    const pd = e.persistentData
    const role = String(pd.getString('zaRole'))
    if (role === '' || role === 'base' || role === 'armored') continue
    if (now < pd.getInt('zaCd')) continue
    const near = zaNearestPlayer(level, e)
    if (near === null) continue
    if (role === 'pearl') {
      if (near.dist > 32 || pd.getInt('zaPearls') <= 0) continue
      if (Math.random() >= 0.15) continue
      const yaw = near.player.yaw * ZA_RAD
      const lx = -Math.sin(yaw)
      const lz = Math.cos(yaw)
      const back = 3 + Math.random() * 2
      const tx = near.player.x - lx * back
      const tz = near.player.z - lz * back
      const Types = Java.loadClass('net.minecraft.world.level.levelgen.Heightmap$Types')
      const ty = level.getHeight(Types.MOTION_BLOCKING, Math.floor(tx), Math.floor(tz))
      e.teleportTo(tx, ty, tz)
      pd.putInt('zaPearls', pd.getInt('zaPearls') - 1)
      pd.putInt('zaCd', now + 160)
      server.runCommandSilent('playsound minecraft:entity.enderman.teleport hostile @a ' + Math.floor(tx) + ' ' + ty + ' ' + Math.floor(tz) + ' 1 1')
      continue
    }
    if (near.dist > global.za.cfg.chaseRadius) continue
    if (!horde) {
      const sdx = e.x - sp.x
      const sdz = e.z - sp.z
      if (sdx * sdx + sdz * sdz < global.za.cfg.safeRadius * global.za.cfg.safeRadius) continue
    }
    const yaw = e.yaw * ZA_RAD
    const lx = -Math.sin(yaw)
    const lz = Math.cos(yaw)
    const bx = Math.floor(e.x + lx * 1.5)
    const by = Math.floor(e.y + 0.5)
    const bz = Math.floor(e.z + lz * 1.5)
    const block = level.getBlock(bx, by, bz)
    if (block != null && global.za.canBreak(role, block.id)) {
      server.runCommandSilent('setblock ' + bx + ' ' + by + ' ' + bz + ' minecraft:air')
      pd.putInt('zaCd', now + (horde ? global.za.cfg.breakRateHorde : global.za.cfg.breakRate))
    } else {
      pd.putInt('zaCd', now + 20)
    }
  }
}

EntityEvents.spawned(event => {
  const e = event.entity
  const type = String(e.type)
  if (type !== 'minecraft:zombie' && type !== 'minecraft:husk' && type !== 'minecraft:drowned') return
  const pd = e.persistentData
  if (pd.getBoolean('zaRoleSet')) return
  const day = global.za.day(e.level)
  global.za.applyRole(e, global.za.roleFor(day, Math.random))
  if (global.za.isMutantRoll(day, Math.random)) global.za.applyMutant(e)
  pd.putBoolean('zaRoleSet', true)
})

ServerEvents.tick(event => {
  if (event.server.tickCount % 10 !== 0) return
  global.za.roleTick(event.server)
})

ServerEvents.commandRegistry(event => {
  const { commands: Commands, arguments: Arguments } = event

  event.register(
    Commands.literal('zombieapoc')
      .then(
        Commands.literal('canBreak').then(
          Commands.argument('role', Arguments.STRING.create(event)).then(
            Commands.argument('block', Arguments.RESOURCE_LOCATION.create(event)).executes(ctx => {
              const role = String(Arguments.STRING.getResult(ctx, 'role'))
              const block = String(Arguments.RESOURCE_LOCATION.getResult(ctx, 'block'))
              ctx.source.sendSystemMessage(Text.string(String(global.za.canBreak(role, block))))
              return 1
            })
          )
        )
      )
      .then(
        Commands.literal('mutantChance').then(
          Commands.argument('day', Arguments.INTEGER.create(event)).executes(ctx => {
            const day = Arguments.INTEGER.getResult(ctx, 'day')
            ctx.source.sendSystemMessage(Text.string(global.za.mutantChance(day).toFixed(2)))
            return 1
          })
        )
      )
      .then(
        Commands.literal('weights').then(
          Commands.argument('day', Arguments.INTEGER.create(event)).executes(ctx => {
            const day = Arguments.INTEGER.getResult(ctx, 'day')
            const list = global.za.roleWeights(day)
            let out = 'day=' + day
            for (let i = 0; i < list.length; i++) out += ' ' + list[i][0] + '=' + list[i][1]
            ctx.source.sendSystemMessage(Text.string(out))
            return 1
          })
        )
      )
      .then(
        Commands.literal('spawnRole').then(
          Commands.argument('role', Arguments.STRING.create(event)).executes(ctx => {
            const role = String(Arguments.STRING.getResult(ctx, 'role'))
            const level = ctx.source.level
            const sp = level.sharedSpawnPos
            const Types = Java.loadClass('net.minecraft.world.level.levelgen.Heightmap$Types')
            const x = sp.x + 3.5
            const z = sp.z + 0.5
            const y = level.getHeight(Types.MOTION_BLOCKING, Math.floor(x), Math.floor(z))
            const e = level.createEntity('minecraft:zombie')
            e.setPos(x, y, z)
            e.persistentData.putBoolean('zaRoleSet', true)
            e.spawn()
            global.za.applyRole(e, role)
            ctx.source.sendSystemMessage(Text.string('spawned za_role_' + role))
            return 1
          })
        )
      )
  )
})
