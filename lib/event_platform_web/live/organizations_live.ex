defmodule EventPlatformWeb.OrganizationsLive do
  use EventPlatformWeb, :live_view
  alias EventPlatform.Repo
  alias EventPlatform.Organizations.Organization
  alias EventPlatform.Organizations.Place
  alias EventPlatform.Events.Event
  import Ecto.Query

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventPlatform.PubSub, "organizations")
    end

    organizations = list_user_organizations(socket.assigns.current_scope.user.id)
    recent_events = list_recent_events(socket.assigns.current_scope.user.id)

    {:ok,
     socket
     |> assign(:organizations, organizations)
     |> assign(:recent_events, recent_events)
     |> assign(:show_form, false)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  # def handle_event("create_organization", %{"organization" => org_params}, socket) do
  def handle_event("create_organization", org_params, socket) do
    attrs = Map.put(org_params, "user_id", socket.assigns.current_scope.user.id)

    case create_organization(attrs) do
      {:ok, organization} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "organizations",
          {:organization_created, organization}
        )

        organizations = list_user_organizations(socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> assign(:organizations, organizations)
         |> assign(:show_form, false)
         |> assign(:form, to_form(%{}))
         |> put_flash(:info, "Organization created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp list_user_organizations(user_id) do
    from(o in Organization, where: o.user_id == ^user_id, order_by: [desc: o.inserted_at])
    |> Repo.all()
  end

  defp list_recent_events(user_id) do
    from(e in Event,
      join: p in Place,
      on: e.place_id == p.id,
      join: o in Organization,
      on: p.organization_id == o.id,
      where: o.user_id == ^user_id,
      order_by: [desc: e.start_datetime],
      limit: 5,
      preload: [place: :organization]
    )
    |> Repo.all()
  end

  defp create_organization(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end
end
