defmodule WorkflowTest do
  use ExUnit.Case

  alias Workflow.{NewScenarioParams, NewStepParams, Dto.ScenarioDto, Dto.StepDto}
  import Mox

  describe "#create_new_scenario" do
    test "creates a new scenario" do
      params = %NewScenarioParams{workspace_id: "abc", template_trigger_id: "step-check-in"}

      expect(Workflow.Repository.Mock, :create_new_scenario, fn dto ->
        Jason.encode!(dto)
        scenario = build_scenario_dto()
        {:ok, scenario}
      end)

      {:ok, _scenario} = Workflow.create_new_scenario(params, Workflow.Repository.Mock)
    end
  end

  describe "#add_step" do
    test "adds an empty filter step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        scenario = build_scenario_dto(step_dto)
        {:ok, scenario}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-filter"
      }

      {:ok, scenario} = Workflow.add_step(params, Workflow.Repository.Mock)
      IO.inspect(scenario)
    end

    test "add an emply delay step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        scenario = build_scenario_dto(step_dto)
        {:ok, scenario}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-delay"
      }

      {:ok, scenario} = Workflow.add_step(params, Workflow.Repository.Mock)
      IO.inspect(scenario)
    end
  end

  defp build_scenario_dto(new_step_dto \\ nil) do
    steps = [
      %StepDto{
        id: "step-1",
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

    steps =
      if is_nil(new_step_dto) do
        steps
      else
        steps ++
          [
            %StepDto{
              id: "step-2",
              title: new_step_dto.title,
              description: new_step_dto.description,
              type: new_step_dto.type,
              trigger: new_step_dto.trigger,
              action: new_step_dto.action,
              value: new_step_dto.value
            }
          ]
      end

    %ScenarioDto{
      id: "123",
      workspace_id: "abc",
      enabled: false,
      title: "New Scenario",
      trigger: "step-check-in",
      ordered_action_ids: [],
      steps: steps
    }
  end
end
