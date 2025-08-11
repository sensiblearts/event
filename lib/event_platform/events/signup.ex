defmodule EventPlatform.Events.Signup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "signups" do
    field :time_slot, :string
    field :comment, :string
    belongs_to :event, EventPlatform.Events.Event
    belongs_to :user, EventPlatform.Accounts.User

    timestamps(type: :utc_datetime)
  end


  @doc false
  def changeset(signup, attrs) do
    signup
    |> cast(attrs, [:time_slot, :comment, :event_id, :user_id])
    |> validate_required([:event_id, :user_id])
    |> validate_length(:comment, max: 500)
    |> validate_length(:time_slot, max: 100)
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:event_id, :user_id, :time_slot],
      message: "User already signed up for this time slot"
    )
  end
end
