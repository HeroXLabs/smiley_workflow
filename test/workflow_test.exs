defmodule WorkflowTest do
  use ExUnit.Case

  alias Workflow.{
    Step,
    NewScenarioParams,
    NewStepParams,
    UpdateStepParams,
    Dto.ScenarioDto,
    Dto.StepDto
  }

  import Mox

  describe "#create_new_scenario" do
    test "creates a new scenario" do
      params = %NewScenarioParams{workspace_id: "abc", template_trigger_id: "step-check-in"}

      expect(Workflow.Repository.Mock, :create_new_scenario, fn dto ->
        Jason.encode!(dto)

        scenario =
          build_scenario_dto([
            Workflow.new_step_dto("step-filter"),
            Workflow.new_step_dto("step-delay"),
            Workflow.new_step_dto("step-schedule-text")
          ])

        {:ok, scenario}
      end)

      {:ok, _scenario} = Workflow.create_new_scenario(params, Workflow.Repository.Mock)
    end
  end

  describe "#compile_scenario" do
    test "returns a compiled scenario" do
      {:ok, filter_1} = Workflow.Filter.new(%{"conditions" => "visits_count:=:1"})
      {:ok, filter_2} = Workflow.Filter.new(%{"conditions" => "tags:=:vip"})

      scenario = %Workflow.Scenario{
        enabled: false,
        id: "123",
        ordered_action_ids: ["step-2", "step-3", "step-4", "step-5", "step-6", "step-7"],
        steps: [
          %Workflow.Step{
            description: "Check in with your team",
            id: "step-1",
            step: %Workflow.Trigger{
              context: %{},
              type: :check_in
            },
            title: "Check In"
          },
          %Workflow.Step{
            description: "Continue only if the condition is met",
            id: "step-2",
            step: filter_1,
            title: "Continue only if"
          },
          %Workflow.Step{
            description: "Delay the workflow for a given amount of time",
            id: "step-3",
            step: %Workflow.Delay{delay_value: 2, delay_unit: :hours},
            title: "Delay for"
          },
          %Workflow.Step{
            description: "Send a text message to a customer",
            id: "step-4",
            step: %Workflow.Action.SendSms{phone_number: "123-456-7890", text: "Hello"},
            title: "Send a text message"
          },
          %Workflow.Step{
            description: "Continue only if the condition is met",
            id: "step-5",
            step: filter_2,
            title: "Continue only if"
          },
          %Workflow.Step{
            description: "Delay the workflow for a given amount of time",
            id: "step-6",
            step: %Workflow.Delay{delay_value: 1, delay_unit: :hours},
            title: "Delay for"
          },
          %Workflow.Step{
            description: "Send a text message to a customer",
            id: "step-7",
            step: %Workflow.Action.SendSms{phone_number: "123-456-7890", text: "Hello again!"},
            title: "Send a text message"
          }
        ],
        title: "New Scenario",
        trigger_id: "step-1",
        workspace_id: "abc"
      }

      expected = %Workflow.RunnableScenario{
        actions: [
          %Workflow.RunnableAction{
            action: %Workflow.Action.SendSms{
              phone_number: "123-456-7890",
              text: "Hello"
            },
            delays: [%Workflow.Delay{delay_unit: :hours, delay_value: 2}],
            filters: [
              %Workflow.Filter{
                conditions: {{:number, "visits_count"}, {{:equal, :number}, 1}}
              }
            ]
          },
          %Workflow.RunnableAction{
            action: %Workflow.Action.SendSms{
              phone_number: "123-456-7890",
              text: "Hello again!"
            },
            delays: [
              %Workflow.Delay{delay_unit: :hours, delay_value: 2},
              %Workflow.Delay{delay_unit: :hours, delay_value: 1}
            ],
            filters: [
              %Workflow.Filter{
                conditions: {{:number, "visits_count"}, {{:equal, :number}, 1}}
              },
              %Workflow.Filter{
                conditions: {{:selection, "tags"}, {{:equal, :string}, "vip"}}
              }
            ]
          }
        ],
        id: "123",
        title: "New Scenario",
        trigger: %Workflow.Trigger{context: %{}, type: :check_in},
        workspace_id: "abc"
      }

      assert Workflow.compile_scenario(scenario) == expected
    end
  end

  describe "#add_step" do
    test "adds an empty filter step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        step = build_step_dto(step_dto, "step-3")
        {:ok, step}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-filter"
      }

      {:ok, _step} = Workflow.add_step(params, Workflow.Repository.Mock)
    end

    test "add an emply delay step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        step = build_step_dto(step_dto, "step-3")
        {:ok, step}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-delay"
      }

      {:ok, _step} = Workflow.add_step(params, Workflow.Repository.Mock)
    end

    test "add an emply action step to a scenario" do
      expect(Workflow.Repository.Mock, :add_step, fn _scenario_id, step_dto ->
        Jason.encode!(step_dto)
        step = build_step_dto(step_dto, "step-3")
        {:ok, step}
      end)

      params = %NewStepParams{
        workspace_id: "abc",
        template_step_id: "step-schedule-text"
      }

      {:ok, _step} = Workflow.add_step(params, Workflow.Repository.Mock)
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
        step = %{step | value: value}
        {:ok, step}
      end)

      {:ok, %Step{step: %Workflow.Filter{}}} =
        Workflow.update_step(params, Workflow.Repository.Mock)
    end
  end

  defp build_scenario_dto(new_step_dtos) do
    steps =
      Enum.reduce(new_step_dtos, [trigger_step()], fn new_step_dto, steps ->
        step_num = Enum.count(steps) + 1
        steps ++ [build_step_dto(new_step_dto, "step-#{step_num}")]
      end)

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
