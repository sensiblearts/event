defmodule EventPlatformWeb.SignupsLive do
  use EventPlatformWeb, :live_view
  alias EventPlatform.Repo
  alias EventPlatform.Events.{Event, Signup}
  alias EventPlatform.Organizations.Place
  import Ecto.Query

  def mount(%{"event_id" => event_id}, _session, socket) do
    event =
      Repo.get!(Event, event_id)
      |> Repo.preload([:place, :signups])
      |> Repo.preload(place: :organization)

    # Verify user owns the organization that contains this event
    if event.place.organization.user_id != socket.assigns.current_scope.user.id do
      raise Phoenix.LiveView.Socket.AssignError, "unauthorized"
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventPlatform.PubSub, "signups:#{event_id}")
    end

    signups = list_event_signups(event_id)
    user_signup = get_user_signup(event_id, socket.assigns.current_scope.user.id)

    {:ok,
     socket
     |> assign(:event, event)
     |> assign(:signups, signups)
     |> assign(:user_signup, user_signup)
     |> assign(:show_form, false)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("create_signup", signup_params, socket) do
    attrs =
      signup_params
      |> Map.put("event_id", socket.assigns.event.id)
      |> Map.put("user_id", socket.assigns.current_scope.user.id)

    case create_signup(attrs) do
      {:ok, signup} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "signups:#{socket.assigns.event.id}",
          {:signup_created, signup}
        )

        signups = list_event_signups(socket.assigns.event.id)

        user_signup =
          get_user_signup(socket.assigns.event.id, socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> assign(:signups, signups)
         |> assign(:user_signup, user_signup)
         |> assign(:show_form, false)
         |> assign(:form, to_form(%{}))
         |> put_flash(:info, "Successfully signed up for event!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel_signup", _params, socket) do
    if socket.assigns.user_signup do
      case delete_signup(socket.assigns.user_signup) do
        {:ok, _signup} ->
          Phoenix.PubSub.broadcast(
            EventPlatform.PubSub,
            "signups:#{socket.assigns.event.id}",
            {:signup_cancelled, socket.assigns.user_signup}
          )

          signups = list_event_signups(socket.assigns.event.id)

          {:noreply,
           socket
           |> assign(:signups, signups)
           |> assign(:user_signup, nil)
           |> put_flash(:info, "Signup cancelled successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to cancel signup")}
      end
    else
      {:noreply, socket}
    end
  end

  defp list_event_signups(event_id) do
    from(s in Signup,
      where: s.event_id == ^event_id,
      order_by: [asc: s.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  defp get_user_signup(event_id, user_id) do
    from(s in Signup,
      where: s.event_id == ^event_id and s.user_id == ^user_id
    )
    |> Repo.one()
  end

  defp create_signup(attrs) do
    %Signup{}
    |> Signup.changeset(attrs)
    |> Repo.insert()
  end

  defp delete_signup(signup) do
    Repo.delete(signup)
  end

  # Helper function to determine if event is still accepting signups
  defp accepting_signups?(event) do
    now = NaiveDateTime.utc_now()
    NaiveDateTime.compare(event.start_datetime, now) == :gt
  end

  # Helper to get available time slots for an event
  defp available_time_slots do
    [
      {"Morning Session (9:00 AM - 12:00 PM)", "morning"},
      {"Afternoon Session (1:00 PM - 5:00 PM)", "afternoon"},
      {"Evening Session (6:00 PM - 9:00 PM)", "evening"},
      {"Full Day", "full_day"}
    ]
  end
end
