// Inti Zombie Apocalypse: konstanta, hari, horde, kunci tidur, filter spawn.
// Dimuat ulang oleh /reload. Command debug ada di 90_debug.js.
// Catatan: semua helper ditempel ke global.za — fungsi top-level tidak andal
// di-resolve lintas skrip Rhino KubeJS.

global.za = {
  cfg: {
    hordeEveryDays: 10,
    sleepLockTick: 12000,
    waveTicks: [14000, 16000, 18000],
    hordeEndTick: 23000,
    waveBase: 8,
    waveStep: 4,
    waveCap: 40,
    ringMin: 32,
    ringMax: 48,
    mutantFromDay: 30,
    mutantBase: 0.03,
    mutantStep: 0.004,
    mutantCap: 0.3,
    roleDays: { armor: 3, weapon: 3, tools: 7, ender: 12, iron: 20, mutant: 30 },
    breakRate: 60,
    breakRateHorde: 30,
    chaseRadius: 8,
    safeRadius: 16,
  },

  allowedSpawns: ['minecraft:zombie', 'minecraft:husk', 'minecraft:drowned', 'minecraft:zombie_villager'],

  hostileSpawns: [
    'minecraft:creeper', 'minecraft:skeleton', 'minecraft:stray', 'minecraft:spider', 'minecraft:cave_spider',
    'minecraft:witch', 'minecraft:pillager', 'minecraft:vindicator', 'minecraft:evoker', 'minecraft:illusioner',
    'minecraft:ravager', 'minecraft:phantom', 'minecraft:slime', 'minecraft:magma_cube', 'minecraft:silverfish',
    'minecraft:endermite', 'minecraft:guardian', 'minecraft:elder_guardian', 'minecraft:ghast', 'minecraft:blaze',
    'minecraft:wither_skeleton', 'minecraft:zombified_piglin', 'minecraft:hoglin', 'minecraft:zoglin',
    'minecraft:enderman', 'minecraft:shulker', 'minecraft:vex', 'minecraft:warden'
  ],

  dayTicks(level) {
    return level.getDayTime() / 1
  },

  day(level) {
    return Math.floor(global.za.dayTicks(level) / 24000) + 1
  },

  isHordeDay(day) {
    return day % global.za.cfg.hordeEveryDays === 0
  },

  hordeIndex(day) {
    return Math.floor(day / global.za.cfg.hordeEveryDays)
  },

  blockSleep(level) {
    const t = global.za.dayTicks(level)
    return global.za.isHordeDay(global.za.day(level)) && t % 24000 >= global.za.cfg.sleepLockTick
  },

  waveSize(index) {
    return Math.min(global.za.cfg.waveBase + global.za.cfg.waveStep * (index - 1), global.za.cfg.waveCap)
  },

  mutantChance(day) {
    if (day < global.za.cfg.mutantFromDay) return 0
    return Math.min(global.za.cfg.mutantBase + global.za.cfg.mutantStep * (day - global.za.cfg.mutantFromDay), global.za.cfg.mutantCap)
  },

  canSpawnType(type) {
    return global.za.allowedSpawns.indexOf(String(type)) !== -1
  },

  shouldCancelSpawn(type) {
    const id = String(type)
    if (global.za.canSpawnType(id)) return false
    return global.za.hostileSpawns.indexOf(id) !== -1
  },
}
