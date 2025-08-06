defmodule EventPlatform.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    belongs_to :user, EventPlatform.Accounts.User

    has_many :places, EventPlatform.Organizations.Place

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 2, max: 100)
    |> foreign_key_constraint(:user_id)
  end
end
