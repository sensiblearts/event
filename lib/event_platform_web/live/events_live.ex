defmodule EventPlatformWeb.EventsLive do
  use EventPlatformWeb, :live_view
  alias EventPlatform.Repo
  alias EventPlatform.Organizations.{Organization, Place}
  alias EventPlatform.Events.Event
  import Ecto.Query

  def mount(%{"place_id" => place_id}, _session, socket) do
    place =
      Repo.get!(Place, place_id)
      |> Repo.preload(:organization)

      # |> Repo.preload([:organization, [:events]])
      # |> Repo.preload([:organization, [events: from(e in Event, order_by: [asc: e.inserted_at])]])
      # events are loaded below


    # Verify user owns the organization that contains this place
    if place.organization.user_id != socket.assigns.current_scope.user.id do
      raise Phoenix.LiveView.Socket.AssignError, "unauthorized"
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventPlatform.PubSub, "events:#{place_id}")
    end

    events = list_place_events(place_id)

    {:ok,
     socket
     |> assign(:place, place)
     |> assign(:events, events)
     |> assign(:show_form, false)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("create_event", event_params, socket) do
    attrs = Map.put(event_params, "place_id", socket.assigns.place.id)

    case create_event(attrs) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "events:#{socket.assigns.place.id}",
          {:event_created, event}
        )

        events = list_place_events(socket.assigns.place.id)

        {:noreply,
         socket
         |> assign(:events, events)
         |> assign(:show_form, false)
         |> assign(:form, to_form(%{}))
         |> put_flash(:info, "Event created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp list_place_events(place_id) do
    from(e in Event,
      where: e.place_id == ^place_id,
      order_by: [desc: e.start_datetime]
    )
    |> Repo.all()
  end

  defp create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  # Helper function to determine if event is upcoming (for signup) or past (for album)
  defp event_status(event) do
    now = NaiveDateTime.utc_now()

    cond do
      NaiveDateTime.compare(event.start_datetime, now) == :gt -> :upcoming
      event.end_datetime && NaiveDateTime.compare(event.end_datetime, now) == :gt -> :ongoing
      true -> :past
    end
  end
end
