defmodule EventPlatformWeb.EventAlbumsLive do
  use EventPlatformWeb, :live_view
  alias EventPlatform.Repo
  alias EventPlatform.Events.{Event, EventAlbum}
  alias EventPlatform.Organizations.Place
  import Ecto.Query

  def mount(%{"event_id" => event_id}, _session, socket) do
    event =
      Repo.get!(Event, event_id)
      |> Repo.preload([:place])
      |> Repo.preload(place: :organization)

    # Verify user owns the organization that contains this event
    if event.place.organization.user_id != socket.assigns.current_scope.user.id do
      raise Phoenix.LiveView.Socket.AssignError, "unauthorized"
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventPlatform.PubSub, "event_albums:#{event_id}")
    end

    albums = list_event_albums(event_id)

    {:ok,
     socket
     |> assign(:event, event)
     |> assign(:albums, albums)
     |> assign(:show_form, false)
     |> assign(:form, to_form(%{}))
     |> assign(:uploaded_file, nil)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .gif),
      #  max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("create_album_post", params, socket) do
    # Extract form data - handle both nested and flat parameter formats

    IO.inspect params, label: "HANDLE EVENT PARAMS"
    # album_params =
    #   case params do
    #     %{"event_album" => nested_params} -> nested_params
    #     flat_params -> flat_params
    #   end

    # Handle file upload if present
    {image_path, final_image_url} =
      case socket.assigns.uploads.image.entries do
      # case uploaded_entries(socket, :image) do
        [entry] ->
          # Save uploaded file
          uploaded_file =
            consume_uploaded_entry(socket, entry, fn %{path: path} ->
              filename = "#{System.unique_integer([:positive])}_#{entry.client_name}"
              dest = Path.join([:code.priv_dir(:event_platform), "static", "uploads", filename])

              # Ensure uploads directory exists
              File.mkdir_p!(Path.dirname(dest))

              # Copy file to destination
              File.cp!(path, dest)

              {:ok, ~p"/uploads/#{filename}"}
            end)  # returns just the file path

          if "" == uploaded_file or is_nil(uploaded_file) do
            IO.puts "NOT OK"
            IO.inspect params["image_url"]
            {nil, params["image_url"]}
          else
            IO.puts "OK"
            IO.inspect uploaded_file
            {uploaded_file, nil}

          end

        [] ->
          IO.puts "NO FILE UPLOADED"
          # No file uploaded, use image_url
          {nil, params["image_url"]}
      end

    attrs =
      params
      |> Map.put("image_url", final_image_url)
      |> Map.put("image_path", image_path)
      |> Map.put("event_id", socket.assigns.event.id)
      |> Map.put("user_id", socket.assigns.current_scope.user.id)


  IO.inspect attrs, label: "album params"

    case create_album_post(attrs) do
      {:ok, album_post} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "event_albums:#{socket.assigns.event.id}",
          {:album_post_created, album_post}
        )

        albums = list_event_albums(socket.assigns.event.id)

        {:noreply,
         socket
         |> assign(:albums, albums)
         |> assign(:show_form, false)
         |> assign(:form, to_form(%{}))
         |> put_flash(:info, "Album post created and pending approval")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("approve_post", %{"id" => post_id}, socket) do
    post = Repo.get!(EventAlbum, post_id)

    case approve_album_post(post) do
      {:ok, _updated_post} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "event_albums:#{socket.assigns.event.id}",
          {:album_post_approved, post}
        )

        albums = list_event_albums(socket.assigns.event.id)

        {:noreply,
         socket
         |> assign(:albums, albums)
         |> put_flash(:info, "Post approved successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to approve post")}
    end
  end

  def handle_event("reject_post", %{"id" => post_id}, socket) do
    post = Repo.get!(EventAlbum, post_id)

    case delete_album_post(post) do
      {:ok, _deleted_post} ->
        Phoenix.PubSub.broadcast(
          EventPlatform.PubSub,
          "event_albums:#{socket.assigns.event.id}",
          {:album_post_rejected, post}
        )

        albums = list_event_albums(socket.assigns.event.id)

        {:noreply,
         socket
         |> assign(:albums, albums)
         |> put_flash(:info, "Post rejected and removed")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject post")}
    end
  end

  defp list_event_albums(event_id) do
    from(a in EventAlbum,
      where: a.event_id == ^event_id,
      order_by: [desc: a.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  defp create_album_post(attrs) do
    %EventAlbum{}
    |> EventAlbum.changeset(attrs)
    |> Repo.insert()
  end

  defp approve_album_post(album_post) do
    album_post
    |> EventAlbum.approval_changeset(%{"approved" => true})
    |> Repo.update()
  end

  defp delete_album_post(album_post) do
    Repo.delete(album_post)
  end

  # Helper function to check if user is the organization owner (can moderate)
  defp can_moderate?(event, current_user) do
    event.place.organization.user_id == current_user.id
  end

  # Helper function to determine if event allows album posts (past events only)
  defp allows_album_posts?(event) do
    now = NaiveDateTime.utc_now()
    NaiveDateTime.compare(event.start_datetime, now) == :lt
  end

    defp error_to_string(:too_large), do: "File is too large."
    defp error_to_string(:not_accepted), do: "This file type is not allowed."
    defp error_to_string(:too_many_files), do: "You have selected too many files."

    defp class_for_upload_form(show_form) do
      if show_form, do: "", else: "hidden"
    end
end
