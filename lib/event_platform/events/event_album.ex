defmodule EventPlatform.Events.EventAlbum do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_albums" do
    field :title, :string
    field :content, :string
    field :image_url, :string
    field :image_path, :string
    field :approved, :boolean, default: false
    belongs_to :event, EventPlatform.Events.Event
    belongs_to :user, EventPlatform.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_album, attrs) do
    event_album
    |> cast(attrs, [:title, :content, :image_url, :image_path, :approved, :event_id, :user_id])
    |> validate_required([:title, :event_id, :user_id])
    |> validate_length(:title, min: 2, max: 200)
    |> validate_length(:content, max: 1000)
    |> validate_image_present()
    |> validate_format(:image_url, ~r/\.(jpg|jpeg|png|gif)$/i,
      message: "must be a valid image URL ending in .jpg, .jpeg, .png, or .gif"
    )
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for admin approval/rejection of album posts
  """
  def approval_changeset(event_album, attrs) do
    event_album
    |> cast(attrs, [:approved])
    |> validate_required([:approved])
  end

  defp validate_image_present(changeset) do
    image_url = get_field(changeset, :image_url)
    image_path = get_field(changeset, :image_path)

    if is_nil(image_url) and is_nil(image_path) do
      add_error(changeset, :image_url, "Either image URL or uploaded file is required")
    else
      changeset
    end
  end
end
