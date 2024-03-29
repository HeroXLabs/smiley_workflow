defmodule Workflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :workflow,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:calendar, "~> 0.17.2"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "~> 1.2"},
      {:monad, github: "he9lin/monad", ref: "339d2e1"},
      {:ssl_verify_fun, "1.1.7"},
      {:mox, "~> 1.0.2", only: :test}
    ]
  end
end
