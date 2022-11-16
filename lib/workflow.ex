defmodule Workflow do
  alias __MODULE__.Template
  alias __MODULE__.Dto.{NewScenarioDto, ScenarioDto, NewStepDto, StepDto}
  alias __MODULE__.StepUpdate

  alias Monad.Error

  defmodule Trigger do
    defmodule TriggerType do
      @valid_types [:check_in, :cancel_appointment]
      @type t :: :check_in | :cancel_appointment

      def new(raw_type) do
        type = String.to_atom(raw_type)

        if Enum.member?(@valid_types, type) do
          {:ok, type}
        else
          {:error, "Invalid trigger type: #{raw_type}"}
        end
      end
    end

    @enforce_keys [:type, :context]
    defstruct [:type, :context]

    @type t :: %__MODULE__{type: TriggerType.t(), context: map}

    # Context should be valid as it's from the default templates
    def new(type, context) do
      with {:ok, type} <- TriggerType.new(type) do
        {:ok, %__MODULE__{type: type, context: context}}
      end
    end
  end

  defmodule Filter do
    defmodule Incomplete do
      defstruct []
      @type t :: %__MODULE__{}
    end

    defmodule FilterConditions do
      alias Workflow.{TypedConditions, Template}
      @type t :: TypedConditions.t()

      def new(raw_conditions) do
        with {:ok, conditions} <-
               TypedConditions.parse_conditions(raw_conditions, &Template.conditions_mapping/1) do
          {:ok, conditions}
        end
      end
    end

    @enforce_keys [:conditions, :raw_conditions]
    defstruct [:conditions, :raw_conditions]

    @type t :: %__MODULE__{conditions: FilterConditions.t(), raw_conditions: binary}

    def new(%{"conditions" => raw_conditions}) do
      with {:ok, conditions} <- FilterConditions.new(raw_conditions) do
        {:ok, %__MODULE__{conditions: conditions, raw_conditions: raw_conditions}}
      end
    end

    def new(_) do
      {:ok, %Incomplete{}}
    end

    defimpl Jason.Encoder, for: __MODULE__ do
      def encode(%{raw_conditions: raw_conditions}, opts) do
        Jason.Encode.string(raw_conditions, opts)
      end
    end

    def from_json(raw_conditions) do
      new(%{"conditions" => raw_conditions})
    end
  end

  defmodule Delay do
    defmodule Incomplete do
      defstruct []
      @type t :: %__MODULE__{}
    end

    defmodule DelayUnit do
      @valid_types [:days, :hours, :minutes, :seconds]
      @type t :: :days | :hours | :minutes | :seconds

      def new(value) do
        value = String.to_atom(value)

        if value in @valid_types do
          {:ok, value}
        else
          {:error, "Invalid delay unit"}
        end
      end
    end

    defmodule DelayValue do
      @type t :: non_neg_integer

      def new(value) when is_integer(value) do
        if value >= 0 do
          {:ok, value}
        else
          {:error, "Invalid delay value"}
        end
      end

      def new(value) when is_binary(value) do
        case Integer.parse(value) do
          {value, ""} -> new(value)
          _ -> {:error, "Invalid delay value"}
        end
      end
    end

    @derive Jason.Encoder
    @enforce_keys [:delay_value, :delay_unit]
    defstruct [:delay_value, :delay_unit]

    @type delay_unit :: DelayUnit.t()
    @type t :: %__MODULE__{delay_value: integer, delay_unit: delay_unit}

    def new(%{"delay_value" => delay_value, "delay_unit" => delay_unit}) do
      with {:ok, delay_unit} <- DelayUnit.new(delay_unit),
           {:ok, delay_value} <- DelayValue.new(delay_value) do
        {:ok, %__MODULE__{delay_value: delay_value, delay_unit: delay_unit}}
      end
    end

    def new(_) do
      {:ok, %Incomplete{}}
    end
  end

  defmodule Action do
    defmodule Incomplete do
      @enforce_keys [:action]
      defstruct [:action]

      @type action :: atom
      @type t :: %__MODULE__{action: action}
    end

    defmodule SendSms do
      @enforce_keys [:phone_number, :text]
      defstruct [:phone_number, :text]
      @type t :: %__MODULE__{phone_number: binary, text: binary}

      def new(value) do
        case value do
          %{"phone_number" => phone_number, "text" => text} ->
            {:ok, %__MODULE__{phone_number: phone_number, text: text}}

          _ ->
            {:ok, %Incomplete{action: :send_sms}}
        end
      end
    end

    @type t :: SendSms.t()

    def from_json(%{"action" => action} = json) do
      new(action, json)
    end

    def new("send_sms", value) do
      SendSms.new(value)
    end

    def new(action, _value) do
      {:error, "Invalid action: #{action}"}
    end
  end

  defimpl Jason.Encoder, for: Action.SendSms do
    def encode(struct, opts) do
      Jason.Encode.map(%{
        "action" => "send_sms",
        "phone_number" => struct.phone_number, 
        "text" => struct.text
      }, opts)
    end
  end

  defmodule RunnableAction do
    alias Workflow.JsonUtil

    @derive Jason.Encoder
    @enforce_keys [:filters, :delays, :inline_filters, :action]
    defstruct [:filters, :delays, :inline_filters, :action]

    @type t :: %__MODULE__{
            filters: [Filter.t()],
            delays: [Delay.t()],
            inline_filters: [Filter.t()],
            action: Action.t()
          }

    def from_json(%{"filters" => filters, "delays" => delays, "inline_filters" => inline_filters, "action" => action}) do
      with {:ok, filters} <- JsonUtil.from_json_array(filters, &Filter.from_json/1),
           {:ok, delays} <- JsonUtil.from_json_array(delays, &Delay.new/1),
           {:ok, inline_filters} <- JsonUtil.from_json_array(inline_filters, &Filter.from_json/1),
           {:ok, action} <- Action.from_json(action) do
        {:ok, %__MODULE__{filters: filters, delays: delays, inline_filters: inline_filters, action: action}}
      end
    end
  end

  defmodule Step do
    @enforce_keys [:id, :scenario_id, :title, :description, :step]
    defstruct [:id, :scenario_id, :title, :description, :step]

    @type id :: binary
    @type step :: Trigger.t() | Filter.t() | Delay.t() | Action.t()
    @type t :: %__MODULE__{id: id, title: binary, description: binary, step: step}

    def is_action_step?(%__MODULE__{step: %Action.SendSms{}}), do: true
    def is_action_step?(_), do: false

    def is_trigger_step?(%__MODULE__{step: %Trigger{}}), do: true
    def is_trigger_step?(_), do: false

    def is_delay_step?(%__MODULE__{step: %Delay{}}), do: true
    def is_delay_step?(_), do: false

    def is_filter_step?(%__MODULE__{step: %Filter{}}), do: true
    def is_filter_step?(_), do: false
  end

  defmodule Scenario do
    @enforce_keys [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]
    defstruct [:id, :workspace_id, :enabled, :title, :trigger_id, :ordered_action_ids, :steps]

    @type id :: binary

    @type t :: %__MODULE__{
            id: id,
            workspace_id: binary,
            enabled: boolean,
            title: binary,
            trigger_id: Trigger.TriggerType.t(),
            ordered_action_ids: [Step.id()],
            steps: [Step.t()]
          }
  end

  defmodule RunnableScenario do
    defstruct [:id, :workspace_id, :title, :trigger, :actions]

    @type t :: %__MODULE__{
            id: binary,
            workspace_id: binary,
            title: binary,
            trigger: Trigger.t(),
            actions: [RunnableAction.t()]
          }
  end

  defmodule NewTrigger do
    alias Trigger.TriggerType
    defstruct [:title, :description, :trigger, :context]

    @type t :: %__MODULE__{
            title: binary,
            description: binary,
            trigger: TriggerType.t(),
            context: map
          }

    def new(title, descrption, trigger, context) do
      {:ok, trigger_type} = TriggerType.new(trigger)
      %__MODULE__{title: title, description: descrption, trigger: trigger_type, context: context}
    end
  end

  defmodule NewScenarioParams do
    defstruct [:workspace_id, :template_trigger_id]

    @type t :: %__MODULE__{workspace_id: binary, template_trigger_id: binary}

    def new(%{"workspace_id" => workspace_id, "template_trigger_id" => template_trigger_id}) do
      {:ok, %__MODULE__{workspace_id: workspace_id, template_trigger_id: template_trigger_id}}
    end

    def new(_) do
      {:error, "Invalid params. Requires workspace_id and template_trigger_id"}
    end
  end

  defmodule NewStepParams do
    defstruct [:workflow_id, :template_step_id, :insert_at]

    defmodule InsertAt do
      @type t :: :append | {:insert_at, integer}

      @spec new(any) :: t
      def new(position) when is_integer(position), do: {:insert_at, position}
      def new(nil), do: :append
    end

    @type t :: %__MODULE__{
            workflow_id: binary,
            template_step_id: binary,
            insert_at: InsertAt.t()
          }

    def new(%{"workflow_id" => workflow_id, "template_action_id" => template_step_id} = params) do
      {:ok,
       %__MODULE__{
         workflow_id: workflow_id,
         template_step_id: template_step_id,
         insert_at: InsertAt.new(Map.get(params, "insert_at"))
       }}
    end

    def new(_) do
      {:error, "Invalid params. Requires workflow_id and template_action_id"}
    end
  end

  defmodule UpdateStepParams do
    defstruct [:id, :template_step_id, :value]

    @type t :: %__MODULE__{id: binary, template_step_id: binary, value: map}

    def new(%{"id" => step_id} = params) do
      {:ok,
       %__MODULE__{
         id: step_id,
         template_step_id: Map.get(params, "template_step_id"),
         value: Map.get(params, "value")
       }}
    end
  end

  defmodule NewScenario do
    defstruct [:workspace_id, :title, :trigger]

    @type t :: %__MODULE__{workspace_id: binary, title: binary, trigger: NewTrigger.t()}
  end

  def create_new_scenario(%NewScenarioParams{} = params, repository) do
    params
    |> new_scenario()
    |> NewScenarioDto.from_domain()
    |> repository.create_new_scenario()
    |> Error.bind(&ScenarioDto.to_domain/1)
  end

  def get_scenario(scenario_id, repository) do
    repository.get_scenario(scenario_id)
    |> Error.bind(&ScenarioDto.to_domain/1)
  end

  def list_scenarios(workspace_id, repository) do
    repository.list_scenarios(workspace_id)
    |> Enum.map(&ScenarioDto.to_domain/1)
    |> Error.choose()
  end

  def update_scenario(scenario_id, attrs, repository) do
    scenario_id
    |> repository.update_scenario(attrs)
    |> Error.bind(&ScenarioDto.to_domain/1)
  end

  def disable_scenario(scenario_id, repository) do
    update_scenario(scenario_id, %{enabled: false}, repository)
  end

  def add_step(%NewStepParams{} = params, repository) do
    step_dto = new_step_dto(params.template_step_id)

    with {:ok, scenario} <- disable_scenario(params.workflow_id, repository),
         {:ok, step} <- create_step(params.workflow_id, step_dto, repository),
         new_ordered_action_ids <-
           build_new_order_action_ids(params.insert_at, scenario.ordered_action_ids, step.id),
         {:ok, scenario} <-
           update_scenario(scenario.id, %{ordered_action_ids: new_ordered_action_ids}, repository) do
      {:ok, {scenario, step}}
    end
  end

  defp build_new_order_action_ids(insert_at, ordered_action_ids, step_id) do
    case insert_at do
      :append -> ordered_action_ids ++ [step_id]
      {:insert_at, position} -> List.insert_at(ordered_action_ids, position, step_id)
    end
  end

  def get_step(step_id, repository) do
    repository.get_step(step_id)
    |> Error.bind(&StepDto.to_domain/1)
  end

  def new_scenario(%NewScenarioParams{} = params) do
    trigger_template = Template.find_trigger(params.template_trigger_id)

    if is_nil(trigger_template) do
      raise "Trigger template not found"
    end

    %NewScenario{
      workspace_id: params.workspace_id,
      title: trigger_template.title <> " workflow",
      trigger:
        NewTrigger.new(
          trigger_template.title,
          trigger_template.description,
          trigger_template.trigger,
          trigger_template.context
        )
    }
  end

  def update_step(%UpdateStepParams{} = params, repository) do
    with {:ok, step} <- get_step(params.id, repository),
         {:ok, _scenario} <- disable_scenario(step.scenario_id, repository),
         {:ok, step_update} <- StepUpdate.new(step, params) do
      update_step(step_update, repository)
    end
  end

  def update_step(%StepUpdate.ReplaceStep{} = update, repository) do
    step_dto = new_step_dto(update.template_step_id)

    repository.update_step(update.step.id, step_dto)
    |> Error.bind(&StepDto.to_domain/1)
  end

  def update_step(%StepUpdate.UpdateStep{} = update, repository) do
    repository.update_step_value(update.step.id, update.update.value)
    |> Error.bind(&StepDto.to_domain/1)
  end

  def delete_step(step_id, repository) do
    with {:ok, step} <- get_step(step_id, repository),
         {:ok, scenario} <- disable_scenario(step.scenario_id, repository),
         :ok <- repository.delete_step(step_id),
         new_ordered_action_ids <- List.delete(scenario.ordered_action_ids, step.id),
         {:ok, scenario} <-
           update_scenario(scenario.id, %{ordered_action_ids: new_ordered_action_ids}, repository) do
      {:ok, {scenario, step}}
    end
  end

  def new_step_dto(template_step_id) do
    step_template = Template.find_action(template_step_id)

    if is_nil(step_template) do
      raise "Step template not found"
    end

    %NewStepDto{
      title: step_template.title,
      description: step_template.description,
      type: "action",
      trigger: nil,
      action: step_template.action,
      value: nil
    }
  end

  @spec compile_scenario(Scenario.t()) :: RunnableScenario.t()
  def compile_scenario(%Scenario{} = scenario) do
    %RunnableScenario{
      id: scenario.id,
      workspace_id: scenario.workspace_id,
      title: scenario.title,
      trigger: compile_trigger(scenario.trigger_id, scenario.steps),
      actions: compile_actions(scenario.ordered_action_ids, scenario.steps)
    }
  end

  @spec compile_trigger(Trigger.trigger(), [Step.t()]) :: Trigger.t()
  defp compile_trigger(trigger_id, steps) do
    steps
    |> Enum.find(&(&1.id == trigger_id))
    |> build_trigger_from_step()
  end

  @spec build_trigger_from_step(Step.t()) :: Trigger.t()
  defp build_trigger_from_step(%Step{step: %Trigger{} = trigger}) do
    trigger
  end

  @spec compile_actions([Step.id()], [Step.t()]) :: [RunnableAction.t()]
  defp compile_actions(step_ids, steps) do
    {:ok, runnable_actions} =
      step_ids
      |> Enum.map(&Enum.find(steps, fn step -> &1 == step.id end))
      |> split_by_action_steps()
      |> Enum.map(fn steps ->
        action_step = List.last(steps)

        if Step.is_action_step?(action_step) do
          first_delay_step_index =
            steps
            |> Enum.find_index(&Step.is_delay_step?/1)

          delay_steps =
            steps
            |> Enum.filter(&Step.is_delay_step?/1)

          filter_steps_before_delay =
            if is_nil(first_delay_step_index) do
              steps
            else
              Enum.take(steps, first_delay_step_index)
            end
            |> Enum.filter(&Step.is_filter_step?/1)

          filter_steps_after_delay =
            if is_nil(first_delay_step_index) do
              []
            else
              Enum.drop(steps, first_delay_step_index)
              |> Enum.filter(&Step.is_filter_step?/1)
            end

          {:ok,
           %RunnableAction{
             filters: filter_steps_before_delay |> Enum.map(& &1.step),
             delays: delay_steps |> Enum.map(& &1.step),
             inline_filters: filter_steps_after_delay |> Enum.map(& &1.step),
             action: action_step.step
           }}
        else
          {:error, "Missing action step"}
        end
      end)
      |> Error.choose()

    runnable_actions
  end

  defp create_step(workflow_id, step_dto, repository) do
    repository.create_step(workflow_id, step_dto)
    |> Error.bind(&StepDto.to_domain/1)
  end

  defp split_by_action_steps(_, acc \\ [])

  defp split_by_action_steps([], acc) do
    acc
  end

  defp split_by_action_steps(steps, acc) do
    {l1, l2} = Enum.split_while(steps, fn step -> not Step.is_action_step?(step) end)

    case l2 do
      [] -> acc ++ [l1]
      [action | rest] -> split_by_action_steps(rest, acc ++ [l1 ++ [action]])
    end
  end
end
