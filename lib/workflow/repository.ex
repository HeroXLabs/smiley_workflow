defmodule Workflow.Repository do
  alias Workflow.Dto.{ScenarioDto, NewScenarioDto, NewStepDto, StepDto}
  alias Workflow.{Scenario, Step}

  @callback create_new_scenario(NewScenarioDto.t()) :: {:ok, ScenarioDto.t()} | {:error, any()}
  @callback create_step(Scenario.id(), NewStepDto.t()) :: {:ok, StepDto.t()} | {:error, any()}
  @callback update_scenario(Scenario.id(), map) :: {:ok, ScenarioDto.t()} | {:error, any()}
  @callback get_scenario(Scenario.id()) :: {:ok, ScenarioDto.t()} | {:error, :not_found}
  @callback list_scenarios(binary) :: [ScenarioDto.t()]
  @callback get_step(Step.id()) :: {:ok, StepDto.t()} | {:error, :not_found}
  @callback update_step(Step.id(), NewStepDto.t()) :: {:ok, StepDto.t()} | {:error, any()}
  @callback update_step_value(Step.id(), map) :: {:ok, StepDto.t()} | {:error, any()}
  @callback delete_step(Step.id()) :: :ok | {:error, any()}
end
