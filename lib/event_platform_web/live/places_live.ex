defmodule EventPlatformWeb.PlacesLive do
  use EventPlatformWeb, :live_view
  alias EventPlatform.Repo
  alias EventPlatform.Organizations.{Organization, Place}
  alias EventPlatform.Events.Event
  import Ecto.Query

  def mount(%{"organization_id" => org_id}, _session, socket) do
    organization = Repo.get!(Organization, org_id)

    # Verify user owns this organization
    if organization.user_id != socket.assigns.current_scope.user.id do
      raise Phoenix.LiveView.Socket.AssignError, "unauthorized"
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventPlatform.PubSub, "places:#{org_id}")
    end

    places = list_organization_places(org_id)

    {:ok,
     socket
     |> assign(:organization, organization)
     |> assign(:places, places)
     |> assign(:show_form, false)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("create_place", place_params, socket) do
    attrs = Map.put(place_params, "organization_id", socket.assigns.organization.id)

    case create_place(attrs) do
      {:ok, place} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "places:#{socket.assigns.organization.id}",
          {:place_created, place}
        )

        places = list_organization_places(socket.assigns.organization.id)

        {:noreply,
         socket
         |> assign(:places, places)
         |> assign(:show_form, false)
         |> assign(:form, to_form(%{}))
         |> put_flash(:info, "Place created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp list_organization_places(org_id) do
    from(p in Place,
      where: p.organization_id == ^org_id,
      order_by: [desc: p.inserted_at],
      preload: [:events]
    )
    |> Repo.all()
  end

  defp create_place(attrs) do
    %Place{}
    |> Place.changeset(attrs)
    |> Repo.insert()
  end
end
