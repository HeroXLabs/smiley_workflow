defmodule Workflow.RunningScenario.StarRewarder do
  alias Workflow.RunningScenario.TriggerContextPayload
  alias Workflow.Action.RewardStar

  @callback reward_star(RewardStar.t(), TriggerContextPayload.t()) :: :ok
end

