defmodule Workflow.MonthDate do
  @moduledoc """
  Month-and-day comparisons for a date that repeats every year.

  The year is ignored. Feb 29 is observed on Feb 28 in a non-leap year, so the
  anniversary still falls on a real date. Counting wraps around New Year: a
  Jan 1 date is one day after Dec 31.
  """

  @doc """
  Days from `today` until the next anniversary, including today as 0.
  """
  @spec days_until(Date.t(), Date.t()) :: non_neg_integer()
  def days_until(%Date{} = month_date, %Date{} = today) do
    this_year = observe(month_date, today.year)

    next =
      if Date.compare(this_year, today) == :lt do
        observe(month_date, today.year + 1)
      else
        this_year
      end

    Date.diff(next, today)
  end

  defp observe(%Date{month: 2, day: 29}, year) do
    if Calendar.ISO.leap_year?(year) do
      Date.new!(year, 2, 29)
    else
      Date.new!(year, 2, 28)
    end
  end

  defp observe(%Date{month: month, day: day}, year) do
    Date.new!(year, month, day)
  end
end
