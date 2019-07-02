defmodule GenEnum.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_enum,
      version: "VERSION" |> File.read!() |> String.trim(),
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
      # ex_doc
      name: "GenEnum",
      source_url: "https://github.com/coingaming/gen_enum",
      homepage_url: "https://github.com/coingaming/gen_enum",
      docs: [main: "readme", extras: ["README.md"]],
      # hex.pm stuff
      description: "Better enumerations support for Elixir and Ecto",
      package: [
        licenses: ["Apache 2.0"],
        files: ["lib", "priv", "mix.exs", "README*", "VERSION*"],
        maintainers: ["timCF"],
        links: %{
          "GitHub" => "https://github.com/coingaming/gen_enum",
          "Author's home page" => "https://itkach.uk"
        }
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:bench), do: ["lib", "bench/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aspire, "~> 0.1.0"},
      {:ecto_enum, "~> 1.1"},
      {:ecto_sql, "~> 3.0.0"},
      {:uelli, "~> 0.1"},
      # development tools
      {:benchfella, "~> 0.3.0", only: :bench, runtime: false},
      {:excoveralls, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:boilex, "~> 0.2", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      docs: ["docs", "cmd mkdir -p doc/priv/", "cmd cp -R priv/ doc/priv/", "docs"]
    ]
  end
end
