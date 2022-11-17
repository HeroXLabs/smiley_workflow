defmodule Workflow.RunningScenario.Scheduler do
  alias Workflow.RunningScenario.ScenarioRun

  @type seconds :: non_neg_integer
  @type clock :: module
  # Computes the delay for a job, based on the delay type and the delay value.
  # Calls run_action on the scenario run with the delay.
  @callback schedule(ScenarioRun.t(), seconds, clock) :: :ok

  def run_action(_scenario_run_payload) do
    # 1. Build scenario run from the json payload
    # 2. Call run_action on the scenario run with services conjured
  end
end
