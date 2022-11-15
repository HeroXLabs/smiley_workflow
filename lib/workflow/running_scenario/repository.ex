defmodule Workflow.RunningScenario.ContextPayloadRepository do
  alias Workflow.RunningScenario.{TriggerContext}

  @callback find_context_payload(TriggerContext.t()) :: {:ok, TriggerContext.payload()} | {:error, any()}
end

defmodule Workflow.RunningScenario.ScenarioRepository do
  alias Workflow.RunningScenario.{TriggerContext}
  alias Workflow.RunnableScenario

  @callback find_runnable_scenario(TriggerContext.t()) :: {:ok, RunnableScenario.t()} | {:error, any()}
end
