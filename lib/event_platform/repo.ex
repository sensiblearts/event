defmodule EventPlatform.Repo do
  use Ecto.Repo,
    otp_app: :event_platform,
    adapter: Ecto.Adapters.SQLite3
end
