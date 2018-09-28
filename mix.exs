defmodule GenEnum.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_enum,
      version: ("VERSION" |> File.read! |> String.trim),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      # excoveralls
      test_coverage:      [tool: ExCoveralls],
      preferred_cli_env:  [
        coveralls:              :test,
        "coveralls.travis":     :test,
        "coveralls.circle":     :test,
        "coveralls.semaphore":  :test,
        "coveralls.post":       :test,
        "coveralls.detail":     :test,
        "coveralls.html":       :test,
      ],
      # dialyxir
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore",
        plt_add_apps: [
          :mix,
          :ex_unit,
        ]
      ],
      # ex_doc
      name:         "GenEnum",
      source_url:   "https://github.com/coingaming/gen_enum",
      homepage_url: "https://github.com/coingaming/gen_enum",
      docs:         [main: "readme", extras: ["README.md"]],
      # hex.pm stuff
      description:  "Better enumerations support for Elixir and Ecto",
      package: [
        organization: "coingaming",
        licenses: ["Apache 2.0"],
        files: ["lib", "priv", "mix.exs", "README*", "VERSION*"],
        maintainers: ["timCF"],
        links: %{
          "GitHub" => "https://github.com/coingaming/gen_enum",
          "Author's home page" => "https://timcf.github.io/",
        }
      ],
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
      {:aspire, "~> 0.1.0"},
      {:ecto_enum, "~> 1.1.0", organization: "coingaming"},
      # development tools
      {:excoveralls, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5",    only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19",     only: [:dev, :test], runtime: false},
      {:credo, "~> 0.9",       only: [:dev, :test], runtime: false},
      {:boilex, "~> 0.2",      only: [:dev, :test], runtime: false},
    ]
  end

  defp aliases do
    [
      docs: ["docs", "cmd mkdir -p doc/priv/", "cmd cp -R priv/ doc/priv/", "docs"],
    ]
  end
end
