defmodule Workflow.RunningScenario do
  alias Workflow.{Action, Filter, TypedConditions, Delay}
  alias __MODULE__.{TriggerContext, ScenarioRun, NewScenarioRun, InlineAction, ConditionsPayload}
  require Logger

  @spec start_scenario(TriggerContext.t(), term, term, term, term, term) ::
          {:ok, ScenarioRun.t()} | {:error, any}
  def start_scenario(
        trigger_context,
        scenario_repository,
        context_repository,
        id_gen,
        clock,
        scheduler
      ) do
    with {:ok, runnable_scenarios} <-
           scenario_repository.find_runnable_scenarios(trigger_context),
         {:ok, context_payload} <- context_repository.find_context_payload(trigger_context) do
      runnable_scenarios
      |> Enum.each(fn runnable_scenario ->
        try do
          run = %NewScenarioRun{
            scenario_id: runnable_scenario.id,
            workspace_id: trigger_context.workspace_id,
            trigger_context: trigger_context,
            context_payload: context_payload,
            actions: runnable_scenario.actions
          }

          run_new_scenario(run, id_gen, clock, scheduler)
        rescue
          err ->
            Logger.error(
              "Failed to run scenario with trigger_context #{inspect(trigger_context)}: #{inspect(err)}"
            )
        end
      end)
    end
  end

  def run_new_scenario(%NewScenarioRun{} = new_run, id_gen, clock, scheduler) do
    [next_action | rest_actions] = new_run.actions

    current_action = %InlineAction{
      filters: next_action.inline_filters,
      action: next_action.action
    }

    if run_context_filter(next_action.filters, new_run.context_payload, clock) do
      scenario_run = %ScenarioRun{
        id: id_gen.generate(),
        scenario_id: new_run.scenario_id,
        workspace_id: new_run.workspace_id,
        trigger_context: new_run.trigger_context,
        pending_actions: rest_actions,
        current_action: current_action,
        done_actions: []
      }

      delays_in_seconds =
        next_action.delays
        |> Enum.map(&Delay.in_seconds/1)
        |> Enum.sum()

      # Schedule run_action
      scheduler.schedule(scenario_run, delays_in_seconds, clock)

      {:ok, scenario_run}
    else
      {:error, "Failed to pass context filter"}
    end
  end

  def run_scenario(%ScenarioRun{pending_actions: []}, _context_repository, _clock, _scheduler) do
    {:error, "No more actions to run"}
  end

  def run_scenario(
        %ScenarioRun{pending_actions: pending_actions} = scenario_run,
        context_repository,
        clock,
        scheduler
      ) do
    with {:ok, context_payload} <-
           context_repository.find_context_payload(scenario_run.trigger_context) do
      [next_action | rest_actions] = pending_actions

      current_action = %InlineAction{
        filters: next_action.inline_filters,
        action: next_action.action
      }

      if run_context_filter(next_action.filters, context_payload, clock) do
        updated_scenario_run = %ScenarioRun{
          scenario_run
          | pending_actions: rest_actions,
            current_action: current_action
        }

        delays_in_seconds =
          next_action.delays
          |> Enum.map(&Delay.in_seconds/1)
          |> Enum.sum()

        # Schedule run_action
        scheduler.schedule(updated_scenario_run, delays_in_seconds, clock)

        {:ok, updated_scenario_run}
      else
        {:error, "Failed to pass context filter"}
      end
    end
  end

  def run_action(
        %ScenarioRun{current_action: %InlineAction{} = inline_action} = scenario_run,
        context_repository,
        clock,
        scheduler,
        sms_sender,
        coupon_sender
      ) do
    with {:ok, context_payload} <-
           context_repository.find_context_payload(scenario_run.trigger_context),
         {:ok, _} <- run_action(inline_action, context_payload, clock, sms_sender, coupon_sender) do
      scenario_run = %ScenarioRun{
        scenario_run
        | done_actions: [scenario_run.current_action | scenario_run.done_actions],
          current_action: nil
      }

      run_scenario(scenario_run, context_repository, clock, scheduler)
    end
  end

  def run_action(
        %InlineAction{filters: filters, action: action} = inline_action,
        context_payload,
        clock,
        sms_sender,
        coupon_sender
      ) do
    if run_context_filter(filters, context_payload, clock) do
      case action do
        %Action.SendSms{phone_number: to_phone, text: text} ->
          sms_sender.send_sms(to_phone, text, context_payload)

          {:ok, inline_action}

        %Action.SendCoupon{} = coupon_action ->
          # Coupon sender will create the coupon, update the context payload
          # and send the SMS with text interpoldated with coupon info, namely
          # title, link, and expire_date
          coupon_sender.send_coupon(
            coupon_action,
            context_payload
          )

          {:ok, inline_action}

        _ ->
          {:error, "Unsupported action"}
      end
    else
      {:error, "Failed to pass context filter"}
    end
  end

  defp run_context_filter(filters, context_payload, clock) do
    conditions_payload = ConditionsPayload.to_conditions_payload(context_payload)
    timezone = context_payload.business.timezone
    date = clock.today!(timezone)

    filters
    |> Enum.all?(fn %Filter{conditions: conditions} ->
      TypedConditions.run_conditions(conditions, conditions_payload, timezone, date)
    end)
  end
end
