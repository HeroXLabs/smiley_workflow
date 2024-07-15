defmodule Workflow.Action.RewardStar do
  alias Workflow.Action.Incomplete

  @enforce_keys [:points]
  defstruct [:points]

  @type t :: %__MODULE__{
          points: non_neg_integer()
        }

  def new(value) do
    case value do
      %{"points" => points} ->
        {:ok, %__MODULE__{points: points}}

      _ ->
        {:ok, %Incomplete{action: :reward_star}}
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      Jason.Encode.map(%{
        "action" => "reward_star",
        "points" => struct.points
      }, opts)
    end
  end
end
