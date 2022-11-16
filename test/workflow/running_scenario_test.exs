defmodule Workflow.RunningScenarioTest do
  use ExUnit.Case, async: true

  alias Workflow.RunningScenario.{ScenarioRun, TriggerContext, InlineAction}
  alias Workflow.{Interpolation, Action, Delay, RunnableAction, Filter}

  test "interpolation" do
    string = "Hello {{person.name}}!"
    bindings = %{"person" => %{"name" => "World"}}
    assert "Hello World!" == Interpolation.interpolate(string, bindings)
  end

  test "scenario run" do
    {:ok, filter_1} = Filter.new(%{"conditions" => "visits_count:=:1"})
    {:ok, filter_2} = Filter.new(%{"conditions" => "tags:=:vip"})

    scenario_run = %ScenarioRun{
      id: "123",
      scenario_id: "s123",
      workspace_id: "w123",
      trigger_context: %TriggerContext{
        workspace_id: "w123",
        trigger_type: :check_in,
        context: %TriggerContext.CheckInContext{
          customer_id: 1,
          check_in_id: "c123"
        }
      },
      current_action: %InlineAction{
        filters: [filter_1],
        action: %Action.SendSms{
          phone_number: "{{customer.phone_number}}",
          text: "Hello {{customer.name}}!"
        }
      },
      pending_actions: [
        %RunnableAction{
          filters: [filter_1],
          inline_filters: [filter_2],
          delays: [%Delay{delay_unit: :minutes, delay_value: 5}],
          action: %Action.SendSms{
            phone_number: "{{customer.phone_number}}",
            text: "Hello 2 {{customer.name}}!"
          }
        }
      ],
      done_actions: [
        %RunnableAction{
          filters: [filter_2],
          inline_filters: [filter_1],
          delays: [%Delay{delay_unit: :minutes, delay_value: 10}],
          action: %Action.SendSms{
            phone_number: "{{customer.phone_number}}",
            text: "Hello 3 {{customer.name}}!"
          }
        }
      ]
    }

    {:ok, decoded} = ScenarioRun.from_json(Jason.decode!(Jason.encode!(scenario_run)))
    assert decoded == scenario_run
  end
end
