defmodule Workflow.RunningScenarioTest do
  use ExUnit.Case, async: true
  import Mox

  alias Workflow.RunningScenario.{
    ScenarioRun,
    TriggerContext,
    InlineAction,
    TriggerContextPayload
  }

  alias Workflow.{Interpolation, Action, Delay, RunnableAction, Filter, RunningScenario}

  setup :verify_on_exit!

  describe ".start_scenario" do
    test "starts a check in scenario run" do
      business = %TriggerContextPayload.Business{
        id: "w123",
        name: "My Business",
        timezone: "America/New_York",
        phone_number: "3216549870",
        sms_provider: :twilio
      }

      customer = %TriggerContextPayload.Customer{
        id: 1,
        first_name: "John",
        phone_number: "1234567890",
        tags: [],
        visits_count: 1,
        last_visit_at: "2020-01-01T00:00:00Z"
      }

      check_in = %TriggerContextPayload.CheckInContextPayload.CheckIn{
        id: "c123",
        services: [1, 2]
      }

      trigger_context = %TriggerContext{
        workspace_id: "w123",
        trigger_type: :check_in,
        context: %TriggerContext.CheckInContext{
          customer_id: 1,
          check_in_id: "c123"
        }
      }

      expect(Workflow.RunningScenario.ScenarioRepository.Mock, :find_runnable_scenario, fn _ ->
        {:ok, runnable_scenario()}
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CheckInContextPayload{
          customer: customer,
          check_in: check_in,
          business: business
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.IdGen.Mock, :generate, fn ->
        "123"
      end)

      expect(Workflow.RunningScenario.Scheduler.Mock, :schedule, fn scenario_run, seconds, _clock ->
        assert scenario_run.current_action
        assert Enum.count(scenario_run.pending_actions) == 1
        assert seconds == 7200

        {:ok, expected} = ScenarioRun.from_json(Jason.decode!(Jason.encode!(scenario_run)))
        assert expected == scenario_run

        RunningScenario.run_action(
          scenario_run,
          Workflow.RunningScenario.ContextPayloadRepository.Mock,
          Workflow.RunningScenario.Clock.Mock,
          Workflow.RunningScenario.Scheduler.Mock,
          Workflow.RunningScenario.SMSSender.Mock,
          Workflow.RunningScenario.CouponSender.Mock
        )
        :ok
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CheckInContextPayload{
          customer: %{ customer | tags: ["vip"] },
          check_in: check_in,
          business: business
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.SMSSender.Mock, :send_sms, fn _to, _text, _context_payload ->
        :ok
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CheckInContextPayload{
          customer: %{ customer | tags: ["vip"] },
          check_in: check_in,
          business: business
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CheckInContextPayload{
          customer: %{ customer | tags: ["vip"] },
          check_in: check_in,
          business: business
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.Scheduler.Mock, :schedule, fn scenario_run, seconds, _clock ->
        assert scenario_run.current_action
        assert scenario_run.pending_actions == []
        assert seconds == 3600

        {:ok, expected} = ScenarioRun.from_json(Jason.decode!(Jason.encode!(scenario_run)))
        assert expected == scenario_run

        {:error, error} = RunningScenario.run_action(
          scenario_run,
          Workflow.RunningScenario.ContextPayloadRepository.Mock,
          Workflow.RunningScenario.Clock.Mock,
          Workflow.RunningScenario.Scheduler.Mock,
          Workflow.RunningScenario.SMSSender.Mock,
          Workflow.RunningScenario.CouponSender.Mock
        )

        assert error == "Failed to pass context filter"

        :ok
      end)

      RunningScenario.start_scenario(
        trigger_context,
        Workflow.RunningScenario.ScenarioRepository.Mock,
        Workflow.RunningScenario.ContextPayloadRepository.Mock,
        Workflow.RunningScenario.IdGen.Mock,
        Workflow.RunningScenario.Clock.Mock,
        Workflow.RunningScenario.Scheduler.Mock
      )
    end

    test "starts a cancel appointment scenario run" do
      business = %TriggerContextPayload.Business{
        id: "w123",
        name: "My Business",
        timezone: "America/New_York",
        phone_number: "3216549870",
        sms_provider: :twilio
      }

      customer = %TriggerContextPayload.Customer{
        id: 1,
        first_name: "John",
        phone_number: "1234567890",
        tags: [],
        visits_count: 1,
        last_visit_at: Calendar.DateTime.from_erl!({{2022, 1, 1}, {10,0,0}}, "America/New_York")
      }

      appointment = %TriggerContextPayload.CancelAppointmentContextPayload.Appointment{
        id: "a123",
        services: ["s1", "s2"],
        start_at: Calendar.DateTime.from_erl!({{2022, 1, 1}, {10,0,0}}, "America/New_York"),
        employees: ["e1", "e2"]
      }

      employee_1 = %TriggerContextPayload.CancelAppointmentContextPayload.Employee{
        id: "e1",
        first_name: "John",
        phone_number: "4567890123"
      }

      trigger_context = %TriggerContext{
        workspace_id: "w123",
        trigger_type: :cancel_appointment,
        context: %TriggerContext.CancelAppointmentContext{
          customer_id: 1,
          appointment_id: "a123"
        }
      }

      expect(Workflow.RunningScenario.ScenarioRepository.Mock, :find_runnable_scenario, fn _ ->
        {:ok, runnable_scenario_2()}
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CancelAppointmentContextPayload{
          customer: customer,
          appointment: appointment,
          business: business,
          employee_1: employee_1
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.IdGen.Mock, :generate, fn ->
        "123"
      end)

      expect(Workflow.RunningScenario.Scheduler.Mock, :schedule, fn scenario_run, seconds, _clock ->
        assert scenario_run.current_action
        assert Enum.count(scenario_run.pending_actions) == 0
        assert seconds == 86400

        {:ok, expected} = ScenarioRun.from_json(Jason.decode!(Jason.encode!(scenario_run)))
        assert expected == scenario_run

        RunningScenario.run_action(
          scenario_run,
          Workflow.RunningScenario.ContextPayloadRepository.Mock,
          Workflow.RunningScenario.Clock.Mock,
          Workflow.RunningScenario.Scheduler.Mock,
          Workflow.RunningScenario.SMSSender.Mock,
          Workflow.RunningScenario.CouponSender.Mock
        )
        :ok
      end)

      expect(Workflow.RunningScenario.ContextPayloadRepository.Mock, :find_context_payload, fn _ ->
        {:ok, %TriggerContextPayload.CancelAppointmentContextPayload{
          customer: customer,
          appointment: appointment,
          business: business,
          employee_1: employee_1
        }}
      end)

      expect(Workflow.RunningScenario.Clock.Mock, :today!, fn _ ->
        Date.from_iso8601!("2020-01-01")
      end)

      expect(Workflow.RunningScenario.SMSSender.Mock, :send_sms, fn _to, _text, _context_payload ->
        :ok
      end)

      RunningScenario.start_scenario(
        trigger_context,
        Workflow.RunningScenario.ScenarioRepository.Mock,
        Workflow.RunningScenario.ContextPayloadRepository.Mock,
        Workflow.RunningScenario.IdGen.Mock,
        Workflow.RunningScenario.Clock.Mock,
        Workflow.RunningScenario.Scheduler.Mock
      )
    end
  end

  test "interpolation" do
    timezone = "America/Los_Angeles"
    datetime = Calendar.DateTime.from_erl!({{2022, 1, 1}, {10,0,0}}, timezone)
    string = "Hello {{person.name}}! Your last visit was {{last_visit_at}}"
    bindings = %{"person" => %{"name" => "Joe"}, "last_visit_at" => datetime}
    assert "Hello Joe! Your last visit was 10:00 AM Saturday, 01 Jan 2022" == Interpolation.interpolate(string, timezone, bindings)
  end

  test "scenario run json encode/decode" do
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
        %InlineAction{
          filters: [filter_1],
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

  defp runnable_scenario() do
    %Workflow.RunnableScenario{
      actions: [
        %Workflow.RunnableAction{
          filters: [
            %Workflow.Filter{
              conditions: {{:number, "visits_count"}, {{:equal, :number}, 1}},
              raw_conditions: "visits_count:=:1"
            }
          ],
          delays: [%Workflow.Delay{delay_unit: :hours, delay_value: 2}],
          inline_filters: [],
          action: %Workflow.Action.SendSms{
            phone_number: "{{phone_number}}",
            text: "Hello"
          }
        },
        %Workflow.RunnableAction{
          filters: [
            %Workflow.Filter{
              conditions: {{:selection, "tags"}, {{:equal, :string}, "vip"}},
              raw_conditions: "tags:=:vip"
            }
          ],
          delays: [
            %Workflow.Delay{delay_unit: :hours, delay_value: 1}
          ],
          inline_filters: [
            %Workflow.Filter{
              conditions: {{:selection, "tags"}, {{:not_equal, :string}, "vip"}},
              raw_conditions: "tags:!=:vip"
            }
          ],
          action: %Workflow.Action.SendSms{
            phone_number: "123-456-7890",
            text: "Hello again!"
          }
        }
      ],
      id: "s123",
      title: "Check In Scenario",
      trigger: %Workflow.Trigger{context: %{}, type: :check_in},
      workspace_id: "w123"
    }
  end

  defp runnable_scenario_2() do
    %Workflow.RunnableScenario{
      actions: [
        %Workflow.RunnableAction{
          filters: [],
          delays: [%Workflow.Delay{delay_unit: :days, delay_value: 1}],
          inline_filters: [],
          action: %Workflow.Action.SendSms{
            phone_number: "{{employee_1.phone_number}}",
            text: "Appointment with {{first_name}} at {{appointment.start_at}} has been cancelled."
          }
        }
      ],
      id: "s123",
      title: "Cancel Appointment Scenario",
      trigger: %Workflow.Trigger{context: %{}, type: :cancel_appointment},
      workspace_id: "w123"
    }
  end
end
