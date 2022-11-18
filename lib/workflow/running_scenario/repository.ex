defmodule Workflow.RunningScenario.ContextPayloadRepository do
  alias Workflow.RunningScenario.{TriggerContext,TriggerContextPayload}

  @callback find_context_payload(TriggerContext.t()) :: {:ok, TriggerContextPayload.t()} | {:error, any()}
end

defmodule Workflow.RunningScenario.ScenarioRepository do
  alias Workflow.RunningScenario.{TriggerContext}
  alias Workflow.RunnableScenario

  @callback find_runnable_scenario(TriggerContext.t()) :: {:ok, RunnableScenario.t()} | {:error, any()}
end
