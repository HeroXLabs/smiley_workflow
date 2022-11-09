defmodule WorkflowTest do
  use ExUnit.Case

  alias Workflow.{Step, NewScenarioParams, NewStepParams, UpdateStepParams, Dto.ScenarioDto, Dto.StepDto}
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

      {:ok, _scenario} = Workflow.add_step(params, Workflow.Repository.Mock)
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

      {:ok, _scenario} = Workflow.add_step(params, Workflow.Repository.Mock)
    end

    test "add an emply action step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        scenario = build_scenario_dto(step_dto)
        {:ok, scenario}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-schedule-text"
      }

      {:ok, _scenario} = Workflow.add_step(params, Workflow.Repository.Mock)
    end
  end

  describe "#update_step" do
    test "replaces a step" do
      step = build_step_dto(Workflow.new_step_dto("step-filter"), "step-2")

      Workflow.Repository.Mock
      |> expect(:get_step, fn _id ->
        {:ok, step}
      end)
      |> expect(:update_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        step = build_step_dto(step_dto, "step-2")
        {:ok, step}
      end)

      params = %UpdateStepParams{
        step_id: "abc",
        template_step_id: "step-schedule-text"
      }

      {:ok, _scenario} = Workflow.update_step(params, Workflow.Repository.Mock)
    end

    test "update value for a step" do
      step = build_step_dto(Workflow.new_step_dto("step-filter"), "step-2")

      params = %UpdateStepParams{
        step_id: step.id,
        template_step_id: nil,
        value: %{"conditions" => "a:=:1"}
      }

      Workflow.Repository.Mock
      |> expect(:get_step, fn id ->
        assert step.id == id
        {:ok, step}
      end)
      |> expect(:update_step_value, fn step_id, value ->
        assert step.id == step_id
        step = %{ step | value: value }
        {:ok, step}
      end)

      {:ok, %Step{step: %Workflow.Filter{}}} = Workflow.update_step(params, Workflow.Repository.Mock)
    end
  end

  defp build_scenario_dto(new_step_dto \\ nil) do
    steps = [ trigger_step() ]
    steps =
      if is_nil(new_step_dto) do
        steps
      else
        steps ++ [build_step_dto(new_step_dto, "step-2")]
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

  defp trigger_step() do
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
  end

  defp build_step_dto(new_step_dto, id) do
    %StepDto{
      id: id,
      title: new_step_dto.title,
      description: new_step_dto.description,
      type: new_step_dto.type,
      trigger: new_step_dto.trigger,
      action: new_step_dto.action,
      value: new_step_dto.value
    }
  end
end
