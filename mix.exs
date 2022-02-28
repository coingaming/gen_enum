defmodule GenEnum.MixProject do
  use Mix.Project
  
  @version (case File.read("VERSION") do
    {:ok, version} -> String.trim(version)
    {:error, _} -> "0.0.0-development"
  end)

  def project do
    [
      app: :gen_enum,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      # excoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        bench: :bench,
        coveralls: :test,
        "coveralls.travis": :test,
        "coveralls.circle": :test,
        "coveralls.semaphore": :test,
        "coveralls.post": :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      consolidate_protocols: Mix.env() in [:prod, :bench],
      # dialyxir
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore",
        plt_add_apps: [
          :mix,
          :ex_unit
        ]
      ],
      package: package(),
      # ex_doc
      name: "GenEnum",
      source_url: "https://github.com/coingaming/gen_enum",
      homepage_url: "https://github.com/coingaming/gen_enum/tree/v#{@version}",
      docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
      description: "Better enumerations support for Elixir and Ecto"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      organization: "coingaming",
      licenses: ["UNLICENSED"],
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "VERSION"],
      links: %{
        "GitHub" => "https://github.com/coingaming/bennu/tree/v#{@version}"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:bench), do: ["lib", "bench/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aspire, "~> 0.1"},
      {:ecto_enum, "~> 1.1"},
      {:ecto_sql, "~> 3.1"},
      {:uelli, "~> 0.1"},
      # development tools
      {:benchfella, "~> 0.3", only: :bench, runtime: false},
      {:excoveralls, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:boilex, "~> 0.2", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      docs: ["docs", "cmd mkdir -p doc/priv/", "cmd cp -R priv/ doc/priv/", "docs"]
    ]
  end
end
