defmodule Dash.Repo do
  use Ecto.Repo,
    otp_app: :dash,
    adapter: Ecto.Adapters.SQLite3
end
