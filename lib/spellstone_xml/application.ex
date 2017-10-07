defmodule SpellstoneXML.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children =
      if Application.get_env(:spellstone_xml, :load) do
        [
          # Starts a worker by calling: SpellstoneXML.Worker.start_link(arg)
          CardData
        ]
      else
        []
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpellstoneXML.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
