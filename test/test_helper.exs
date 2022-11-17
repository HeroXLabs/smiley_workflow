Mox.defmock(Workflow.Repository.Mock, for: Workflow.Repository)
Mox.defmock(Workflow.RunningScenario.ScenarioRepository.Mock, for: Workflow.RunningScenario.ScenarioRepository)
Mox.defmock(Workflow.RunningScenario.ContextPayloadRepository.Mock, for: Workflow.RunningScenario.ContextPayloadRepository)
Mox.defmock(Workflow.RunningScenario.IdGen.Mock, for: Workflow.RunningScenario.IdGen)
Mox.defmock(Workflow.RunningScenario.Clock.Mock, for: Workflow.RunningScenario.Clock)
Mox.defmock(Workflow.RunningScenario.Scheduler.Mock, for: Workflow.RunningScenario.Scheduler)
Mox.defmock(Workflow.RunningScenario.SMSSender.Mock, for: Workflow.RunningScenario.SMSSender)

ExUnit.start()
