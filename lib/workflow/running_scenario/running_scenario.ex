defmodule Workflow.RunningScenario do
  alias Workflow.{Trigger, Action, Filter, TypedConditions, Interpolation}

  defmodule TriggerContext do
    defmodule CheckInContext do
      @derive Jason.Encoder
      @enforce_keys [:customer_id, :check_in_id]
      defstruct [:customer_id, :check_in_id]

      @type t :: %__MODULE__{
              customer_id: integer,
              check_in_id: term
            }
    end

    defmodule CancelAppointmentContext do
      @derive Jason.Encoder
      @enforce_keys [:customer_id, :appointment_id]
      defstruct [:customer_id, :appointment_id]

      @type t :: %__MODULE__{
              customer_id: integer,
              appointment_id: term
            }
    end

    @derive Jason.Encoder
    @enforce_keys [:workspace_id, :trigger_type, :context]
    defstruct [:workspace_id, :trigger_type, :context]

    @type t :: %__MODULE__{
            workspace_id: binary,
            trigger_type: Trigger.TriggerType.t(),
            context: CheckInContext.t() | CancelAppointmentContext.t()
          }
  end

  defmodule TriggerContextPayload do
    defmodule Business do
      @derive Jason.Encoder
      @enforce_keys [:id, :name, :timezone, :phone_number]
      defstruct [:id, :name, :timezone, :phone_number]

      @type t :: %__MODULE__{
              id: String.t(),
              name: String.t(),
              timezone: String.t(),
              phone_number: String.t()
            }
    end

    defmodule Customer do
      @derive Jason.Encoder
      @enforce_keys [:id, :first_name, :phone_number, :tags, :visits_count, :last_visit_at]
      defstruct [:id, :first_name, :phone_number, :tags, :visits_count, :last_visit_at]

      @type t :: %__MODULE__{
              id: integer,
              first_name: String.t(),
              phone_number: String.t(),
              tags: list(String.t()),
              visits_count: integer,
              last_visit_at: DateTime.t()
            }
    end

    defmodule CheckInContextPayload do
      defmodule CheckIn do
        @derive Jason.Encoder
        @enforce_keys [:id, :services]
        defstruct [:id, :services]

        @type t :: %__MODULE__{
                id: String.t(),
                services: list(String.t())
              }
      end

      @derive Jason.Encoder
      @enforce_keys [:business, :customer, :check_in]
      defstruct [:business, :customer, :check_in]

      @type t :: %__MODULE__{
              business: Business.t(),
              customer: Customer.t(),
              check_in: CheckIn.t()
            }
    end

    defmodule CancelAppointmentContextPayload do
      defmodule Employee do
        @derive Jason.Encoder
        @enforce_keys [:id, :first_name, :phone_number]
        defstruct [:id, :first_name, :phone_number]

        @type t :: %__MODULE__{
                id: integer,
                first_name: String.t(),
                phone_number: String.t()
              }
      end

      defmodule Appointment do
        @derive Jason.Encoder
        @enforce_keys [:id, :services, :employee_1]
        defstruct [:id, :services, :employee_1]

        @type t :: %__MODULE__{
                id: String.t(),
                services: list(String.t()),
                employee_1: Employee.t()
              }
      end

      @derive Jason.Encoder
      @enforce_keys [:business, :customer, :appointment]
      defstruct [:business, :customer, :appointment]

      @type t :: %__MODULE__{
              business: Business.t(),
              customer: Customer.t(),
              appointment: Appointment.t()
            }
    end

    @type t :: CheckInContextPayload.t() | CancelAppointmentContextPayload.t()
  end

  defprotocol ConditionsPayload do
    @spec to_conditions_payload(TriggerContextPayload.t()) :: map
    def to_conditions_payload(any)
  end

  defimpl ConditionsPayload, for: TriggerContextPayload.CheckInContextPayload do
    def to_conditions_payload(%TriggerContextPayload.CheckInContextPayload{
          business: business,
          customer: customer,
          check_in: check_in
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => customer.last_visit_at,
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "check_in" => %{
          "services" => check_in.services
        }
      }
    end
  end

  defimpl ConditionsPayload, for: TriggerContextPayload.CancelAppointmentContextPayload do
    def to_conditions_payload(%TriggerContextPayload.CancelAppointmentContextPayload{
          business: business,
          customer: customer,
          appointment: appointment
        }) do
      %{
        "first_name" => customer.first_name,
        "phone_number" => customer.phone_number,
        "tags" => customer.tags,
        "visits_count" => customer.visits_count,
        "last_visit_at" => customer.last_visit_at,
        "business" => %{
          "id" => business.id,
          "name" => business.name,
          "timezone" => business.timezone
        },
        "appointment" => %{
          "services" => appointment.services,
          "employee_1" => %{
            "id" => appointment.employee_1.id,
            "first_name" => appointment.employee_1.first_name,
            "phone_number" => appointment.employee_1.phone_number
          }
        }
      }
    end
  end

  defmodule NewScenarioRun do
    @derive Jason.Encoder
    @enforce_keys [
      :scenario_id,
      :workspace_id,
      :trigger_context,
      :context_payload,
      :actions
    ]
    defstruct [
      :scenario_id,
      :workspace_id,
      :trigger_context,
      :context_payload,
      :actions
    ]

    @type t :: %__MODULE__{
            scenario_id: binary,
            workspace_id: binary,
            trigger_context: TriggerContext.t(),
            context_payload: map,
            actions: [RunnableAction.t()]
          }
  end

  defmodule InlineAction do
    @derive Jason.Encoder
    @enforce_keys [:filters, :action]
    defstruct [:filters, :action]

    @type t :: %__MODULE__{
            filters: [Filter.t()],
            action: Action.t()
          }
  end

  defmodule ScheduledActionRun do
    defmodule Schedule do
      @derive Jason.Encoder
      @enforce_keys [:job_id, :scheduled_at]
      defstruct [:job_id, :scheduled_at]

      @type t :: %__MODULE__{
              job_id: binary,
              scheduled_at: DateTime.t()
            }
    end

    @derive Jason.Encoder
    @enforce_keys [:action, :scheduled]
    defstruct [:action, :scheduled]

    @type t :: %__MODULE__{
            action: ScheduledAction.t(),
            scheduled: Schedule.t()
          }
  end

  defmodule ScenarioRun do
    @derive Jason.Encoder
    @enforce_keys [
      :id,
      :scenario_id,
      :workspace_id,
      :trigger_context,
      :current_action,
      :pending_actions,
      :done_actions
    ]
    defstruct [
      :id,
      :scenario_id,
      :workspace_id,
      :trigger_context,
      :current_action,
      :pending_actions,
      :done_actions
    ]

    @type t :: %__MODULE__{
            id: term,
            scenario_id: binary,
            workspace_id: binary,
            trigger_context: TriggerContext.t(),
            current_action: InlineAction.t(),
            pending_actions: [RunnableAction.t()],
            done_actions: [RunnableAction.t()]
          }
  end

  @spec start_scenario(TriggerContext.t(), term, term, term) ::
          {:ok, ScenarioRun.t()} | {:error, any}
  def start_scenario(trigger_context, scenario_repository, context_repository, scheduler) do
    with {:ok, runnable_scenario} <- scenario_repository.find_runnable_scenario(trigger_context),
         {:ok, context_payload} <- context_repository.find_context_payload(trigger_context) do
      scenario_run = %NewScenarioRun{
        scenario_id: runnable_scenario.id,
        workspace_id: trigger_context.workspace_id,
        trigger_context: trigger_context,
        context_payload: context_payload,
        actions: runnable_scenario.actions
      }

      run_new_scenario(scenario_run, scheduler)
    end
  end

  def run_new_scenario(%NewScenarioRun{} = new_run, scheduler) do
    [next_action | rest_actions] = new_run.actions

    current_action = %InlineAction{
      filters: next_action.inline_filters,
      action: next_action.action
    }

    if run_context_filter(next_action.filters, new_run.context_payload) do
      scenario_run = %ScenarioRun{
        id: to_string(:rand.uniform()),
        scenario_id: new_run.scenario_id,
        workspace_id: new_run.workspace_id,
        trigger_context: new_run.trigger_context,
        pending_actions: rest_actions,
        current_action: current_action,
        done_actions: []
      }

      scheduler.schedule(scenario_run, next_action.delays)
    else
      {:error, "Failed to pass context filter"}
    end
  end

  def run_scenario(%ScenarioRun{} = scenario_run, scheduler, context_repository) do
    with {:ok, context_payload} <-
           context_repository.find_context_payload(scenario_run.trigger_context) do
      case scenario_run.pending_actions do
        [next_action | rest_actions] ->
          current_action = %InlineAction{
            filters: next_action.inline_filters,
            action: next_action.action
          }

          if run_context_filter(next_action.filters, context_payload) do
            updated_scenario_run = %ScenarioRun{
              scenario_run
              | pending_actions: rest_actions,
                current_action: current_action
            }

            # Schedule run_action
            scheduler.schedule(updated_scenario_run, next_action.delays)
          else
            {:error, "Failed to pass context filter"}
          end

        _ ->
          {:error, "No more actions to run"}
      end
    end
  end

  def run_action(
        %ScenarioRun{current_action: %InlineAction{} = inline_action} = scenario_run,
        scheduler,
        context_repository,
        sms_sender
      ) do
    with {:ok, context_payload} <-
           context_repository.find_context_payload(scenario_run.trigger_context),
         {:ok, _} <- run_action(inline_action, context_payload, sms_sender) do
      scenario_run = %ScenarioRun{
        scenario_run
        | done_actions: [scenario_run.current_action | scenario_run.done_actions],
          current_action: nil
      }

      run_scenario(scenario_run, scheduler, context_repository)
    end
  end

  def run_action(
        %InlineAction{filters: filters, action: action} = inline_action,
        context_payload,
        sms_sender
      ) do
    conditions_payload = ConditionsPayload.to_conditions_payload(context_payload)

    if run_context_filter(filters, conditions_payload) do
      case action do
        %Action.SendSms{phone_number: to_phone, text: text} ->
          from_phone = context_payload.business.phone_number
          msg = Interpolation.interpolate(text, conditions_payload)
          sms_sender.send_sms(from_phone, to_phone, msg)

          {:ok, inline_action}

        _ ->
          {:error, "Unsupported action"}
      end
    else
      {:error, "Failed to pass context filter"}
    end
  end

  defp run_context_filter(filters, context_payload) do
    conditions_payload = ConditionsPayload.to_conditions_payload(context_payload)
    timezone = context_payload.business.timezone
    date = Calendar.Date.today!(timezone)

    filters
    |> Enum.all?(fn %Filter{conditions: conditions} ->
      TypedConditions.run_conditions(conditions, conditions_payload, timezone, date)
    end)
  end

  def build_context_payload(
        %TriggerContext.CheckInContext{} = context,
        repository
      ) do
    with {:ok,
          %TriggerContextPayload.CheckInContextPayload{customer: customer, check_in: check_in}} <-
           repository.get_context_payload(context) do
      %{
        "customer" => %{
          "id" => context.customer_id,
          "phone_number" => customer.phone_number,
          "first_name" => customer.first_name,
          "tags" => customer.tags,
          "visits_count" => customer.visits_count,
          "last_visit_at" => customer.last_visit_at
        },
        "check_in" => %{
          "id" => check_in.id,
          "services" => check_in.services
        }
      }
    end
  end
end
