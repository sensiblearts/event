defmodule EventPlatformWeb.PageController do
  use EventPlatformWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
