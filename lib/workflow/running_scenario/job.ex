defmodule Workflow.RunningScenario.Job do
  alias Workflow.RunningScenario.ScenarioRun
  alias Workflow.Delay

  # Computes the delay for a job, based on the delay type and the delay value.
  # Calls run_action on the scenario run with the delay.
  @callback schedule_scenario_run(ScenarioRun.t(), [Delay.t()]) :: :ok

  def run_action(_scenario_run_payload) do
    # 1. Build scenario run from the json payload
    # 2. Call run_action on the scenario run with services conjured
  end
end
