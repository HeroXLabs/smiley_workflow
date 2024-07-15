defmodule Workflow.RunningScenario.StarRewarder do
  alias Workflow.RunningScenario.ConditionsPayload
  alias Workflow.Action.RewardStar

  @callback reward_star(RewardStar.t(), ConditionsPayload.t()) :: :ok
end

