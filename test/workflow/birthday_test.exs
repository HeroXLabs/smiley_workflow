defmodule Workflow.BirthdayTest do
  use ExUnit.Case, async: true

  alias Workflow.Birthday

  test "days until the anniversary is 0 on the birthday" do
    assert Birthday.days_until(~D[1990-10-26], ~D[2026-10-26]) == 0
  end

  test "days until wraps from December into January" do
    assert Birthday.days_until(~D[1980-01-01], ~D[2026-12-31]) == 1
  end

  test "observes Feb 29 on Feb 28 in a non-leap year" do
    assert Birthday.days_until(~D[2000-02-29], ~D[2023-02-28]) == 0
  end

  test "keeps Feb 29 in a leap year" do
    assert Birthday.days_until(~D[2000-02-29], ~D[2024-02-28]) == 1
  end
end
