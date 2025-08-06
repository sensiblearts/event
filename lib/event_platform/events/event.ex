defmodule EventPlatform.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :name, :string
    field :description, :string
    field :start_datetime, :naive_datetime
    field :end_datetime, :naive_datetime
    belongs_to :place, EventPlatform.Organizations.Place

    has_many :signups, EventPlatform.Events.Signup

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :description, :start_datetime, :end_datetime, :place_id])
    |> validate_required([:name, :start_datetime, :place_id])
    |> validate_length(:name, min: 2, max: 200)
    |> validate_length(:description, max: 1000)
    |> validate_end_datetime_after_start()
    |> foreign_key_constraint(:place_id)
  end

  defp validate_end_datetime_after_start(changeset) do
    start_datetime = get_field(changeset, :start_datetime)
    end_datetime = get_field(changeset, :end_datetime)

    if start_datetime && end_datetime &&
         NaiveDateTime.compare(end_datetime, start_datetime) == :lt do
      add_error(changeset, :end_datetime, "must be after start datetime")
    else
      changeset
    end
  end
end
