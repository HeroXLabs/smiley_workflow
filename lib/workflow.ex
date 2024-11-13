defmodule Workflow do
  alias __MODULE__.{
    Template,
    StepUpdate,
    Step,
    Trigger,
    Scenario,
    RunnableScenario,
    RunnableAction,
    NewTrigger,
    NewScenario
  }

  alias __MODULE__.Dto.{NewScenarioDto, ScenarioDto, NewStepDto, StepDto}

  alias Monad.Error

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
      value: nil,
      context: step_template.context
    }
  end

  @spec compile_scenario(Scenario.t()) :: {:ok, RunnableScenario.t()} | {:error, any}
  def compile_scenario(%Scenario{} = scenario) do
    if Enum.any?(scenario.steps, &Step.is_incomplete_step?/1) do
      {:error, "Scenario is incomplete"}
    else
      {:ok,
       %RunnableScenario{
         id: scenario.id,
         workspace_id: scenario.workspace_id,
         title: scenario.title,
         trigger: compile_trigger(scenario.trigger_id, scenario.steps),
         actions: compile_actions(scenario.ordered_action_ids, scenario.steps)
       }}
    end
  end

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
