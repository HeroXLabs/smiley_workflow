defmodule Workflow.BirthdayFilterTest do
  use ExUnit.Case, async: true

  alias Workflow.{Filter, TypedConditions}

  @today ~D[2026-10-26]
  @timezone "America/Los_Angeles"

  test "birthday within 1 day matches only a birthday today" do
    {:ok, filter} = Filter.new(%{"conditions" => "birthday:<>:1"})

    assert run(filter, ~D[1990-10-26])
    refute run(filter, ~D[1990-10-27])
    refute run(filter, ~D[1990-10-25])
    refute run(filter, nil)
  end

  test "birthday within 7 days matches today through 6 days ahead" do
    {:ok, filter} = Filter.new(%{"conditions" => "birthday:<>:7"})

    assert run(filter, ~D[1990-10-26])
    assert run(filter, ~D[1990-11-01])
    refute run(filter, ~D[1990-11-02])
  end

  test "birthday within days wraps the new year" do
    {:ok, filter} = Filter.new(%{"conditions" => "birthday:<>:2"})

    assert run(filter, ~D[1980-01-01], ~D[2026-12-31])
    refute run(filter, ~D[1980-01-02], ~D[2026-12-31])
  end

  test "rejects a non-positive or non-numeric day count" do
    assert {:error, _} = Filter.new(%{"conditions" => "birthday:<>:0"})
    assert {:error, _} = Filter.new(%{"conditions" => "birthday:<>:-3"})
    assert {:error, _} = Filter.new(%{"conditions" => "birthday:<>:abc"})
  end

  test "a birthday filter combines with another condition" do
    {:ok, filter} = Filter.new(%{"conditions" => "birthday:<>:1&visits_count:=:3"})

    assert TypedConditions.run_conditions(
             filter.conditions,
             %{"birthday" => ~D[1990-10-26], "visits_count" => 3},
             @timezone,
             @today
           )

    refute TypedConditions.run_conditions(
             filter.conditions,
             %{"birthday" => ~D[1990-10-26], "visits_count" => 2},
             @timezone,
             @today
           )
  end

  defp run(filter, birthday, today \\ @today) do
    TypedConditions.run_conditions(
      filter.conditions,
      %{"birthday" => birthday},
      @timezone,
      today
    )
  end
end
