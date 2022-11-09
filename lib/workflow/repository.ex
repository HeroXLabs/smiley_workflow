defmodule Workflow.Repository do
  alias Workflow.Dto.{ScenarioDto, NewScenarioDto, NewStepDto}

  defmodule ValidationError do
    defexception [:message]
  end

  @type error :: :not_found | ValidationError.t()

  @callback create_new_scenario(NewScenarioDto.t()) :: {:ok, ScenarioDto.t()} | {:error, any()}
  @callback add_step(Scenario.id(), NewStepDto.t()) :: {:ok, StepDto.t()} | {:error, any()}
  @callback get_scenario(Scenario.id()) :: {:ok, ScenarioDto.t()} | {:error, :not_found}
  @callback get_step(Step.id()) :: {:ok, StepDto.t()} | {:error, :not_found}
  @callback update_step(Step.id(), NewStepDto.t()) :: {:ok, StepDto.t()} | {:error, any()}
  @callback update_step_value(Step.id(), map) :: {:ok, StepDto.t()} | {:error, any()}
end
