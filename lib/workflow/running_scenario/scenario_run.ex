defmodule Workflow.RunningScenario.ScenarioRun do
  alias Workflow.{JsonUtil, RunnableAction}
  alias Workflow.RunningScenario.{InlineAction, TriggerContext}

  @derive Jason.Encoder
  @enforce_keys [
    :id,
    :scenario_id,
    :workspace_id,
    :trigger_context,
    :current_action,
    :pending_actions,
    :done_actions
  ]
  defstruct [
    :id,
    :scenario_id,
    :workspace_id,
    :trigger_context,
    :current_action,
    :pending_actions,
    :done_actions
  ]

  @type t :: %__MODULE__{
          id: term,
          scenario_id: binary,
          workspace_id: binary,
          trigger_context: TriggerContext.t(),
          current_action: InlineAction.t(),
          pending_actions: [RunnableAction.t()],
          done_actions: [RunnableAction.t()]
        }

  def from_json(%{
        "id" => id,
        "scenario_id" => scenario_id,
        "workspace_id" => workspace_id,
        "trigger_context" => trigger_context_json,
        "current_action" => current_action_json,
        "pending_actions" => pending_actions_json,
        "done_actions" => done_actions_json
      }) do
    with {:ok, trigger_context} <- TriggerContext.from_json(trigger_context_json),
         {:ok, current_action} <- InlineAction.from_json(current_action_json),
         {:ok, pending_actions} <-
           JsonUtil.from_json_array(pending_actions_json, &RunnableAction.from_json/1),
         {:ok, done_actions} <-
           JsonUtil.from_json_array(done_actions_json, &InlineAction.from_json/1) do
      {:ok,
       %__MODULE__{
         id: id,
         scenario_id: scenario_id,
         workspace_id: workspace_id,
         trigger_context: trigger_context,
         current_action: current_action,
         pending_actions: pending_actions,
         done_actions: done_actions
       }}
    end
  end
end
