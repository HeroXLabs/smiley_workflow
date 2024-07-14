defmodule Workflow.RunningScenario.NewScenarioRun do
  alias Workflow.RunnableAction
  alias Workflow.RunningScenario.TriggerContext

  @derive Jason.Encoder
  @enforce_keys [
    :scenario_id,
    :workspace_id,
    :trigger_context,
    :context_payload,
    :actions
  ]
  defstruct [
    :scenario_id,
    :workspace_id,
    :trigger_context,
    :context_payload,
    :actions
  ]

  @type t :: %__MODULE__{
          scenario_id: binary,
          workspace_id: binary,
          trigger_context: TriggerContext.t(),
          context_payload: map,
          actions: [RunnableAction.t()]
        }
end
