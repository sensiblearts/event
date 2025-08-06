defmodule EventPlatform.Organizations.Place do
  use Ecto.Schema
  import Ecto.Changeset

  schema "places" do
    field :name, :string
    belongs_to :organization, EventPlatform.Organizations.Organization

    # has_many :events, EventPlatform.Events.Event, preload_order: [asc: :start_datetime]
    has_many :events, EventPlatform.Events.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [:name, :organization_id])
    |> validate_required([:name, :organization_id])
    |> validate_length(:name, min: 2, max: 100)
    |> foreign_key_constraint(:organization_id)
  end
end
