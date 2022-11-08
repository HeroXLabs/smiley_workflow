defmodule WorkflowTest do
  use ExUnit.Case

  alias Workflow.{NewScenarioParams, Dto.ScenarioDto, Dto.StepDto}
  import Mox

  describe "#create_new_scenario" do
    test "creates a new scenario" do
      params = %NewScenarioParams{workspace_id: "abc", template_trigger_id: "step-check-in"}

      expect(Workflow.Repository.Mock, :create_new_scenario, fn dto ->
        Jason.encode!(dto)

        scenario = %ScenarioDto{
          id: "123",
          workspace_id: "abc",
          enabled: false,
          title: "New Scenario",
          trigger: "step-check-in",
          ordered_action_ids: [],
          steps: [
            %StepDto{
              id: "step-check-in",
              title: "Check In",
              description: "Check in with your team",
              type: "trigger",
              trigger: "check_in",
              action: nil,
              value: %{
                "channel" => "C123",
                "text" => "How are you doing today?"
              }
            }
          ]
        }

        {:ok, scenario}
      end)

      {:ok, _scenario} = Workflow.create_new_scenario(params, Workflow.Repository.Mock)
    end
  end
end
