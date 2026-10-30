// Command debug /zombieapoc ... — dipakai harness server + verifikasi task.
// Subcommand lain didaftarkan task yang memilikinya (task-8 menambah role/break dsb).

ServerEvents.commandRegistry(event => {
  const { commands: Commands, arguments: Arguments } = event

  function out(ctx, msg) {
    ctx.source.sendSystemMessage(Text.string(String(msg)))
    return 1
  }

  event.register(
    Commands.literal('zombieapoc')
      .then(Commands.literal('ping').executes(ctx => out(ctx, 'pong')))
      .then(Commands.literal('day').executes(ctx => out(ctx, global.za.day(ctx.source.level))))
      .then(
        Commands.literal('isHordeDay').then(
          Commands.argument('day', Arguments.INTEGER.create(event)).executes(ctx =>
            out(ctx, global.za.isHordeDay(Arguments.INTEGER.getResult(ctx, 'day')))
          )
        )
      )
      .then(
        Commands.literal('blockSleep').executes(ctx => out(ctx, global.za.blockSleep(ctx.source.level)))
      )
      .then(
        Commands.literal('canSpawn').then(
          Commands.argument('id', Arguments.RESOURCE_LOCATION.create(event)).executes(ctx =>
            out(ctx, global.za.canSpawnType(String(Arguments.RESOURCE_LOCATION.getResult(ctx, 'id'))))
          )
        )
      )
      .then(
        Commands.literal('addDays').then(
          Commands.argument('n', Arguments.INTEGER.create(event)).executes(ctx => {
            const n = Arguments.INTEGER.getResult(ctx, 'n')
            ctx.source.server.runCommandSilent('time add ' + n * 24000)
            return out(ctx, 'added days: ' + n)
          })
        )
      )
  )
})
