defmodule Workflow.Repository do
  alias Workflow.{Scenario, NewScenarioDto, NewStepDto}

  defmodule ValidationError do
    defexception [:message]
  end

  @type error :: :not_found | ValidationError.t()

  @callback create_new_scenario(NewScenarioDto.t()) :: {:ok, Scenario.t()} | {:error, any()}
  @callback add_step(Scenario.id(), NewStepDto.t()) :: {:ok, Scenario.t()} | {:error, any()}
  @callback find_scenario(Scenario.id()) :: {:ok, Scenario.t()} | {:error, :not_found}
end
