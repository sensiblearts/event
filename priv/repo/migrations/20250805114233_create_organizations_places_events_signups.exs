defmodule EventPlatform.Repo.Migrations.CreateOrganizationsPlacesEventsSignups do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:organizations, [:user_id])

    create table(:places) do
      add :name, :string, null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:places, [:organization_id])

    create table(:events) do
      add :name, :string, null: false
      add :description, :text
      add :start_datetime, :naive_datetime, null: false
      add :end_datetime, :naive_datetime
      add :place_id, references(:places, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:place_id])
    create index(:events, [:start_datetime])

    create table(:signups) do
      add :time_slot, :string
      add :comment, :text
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:signups, [:event_id])
    create index(:signups, [:user_id])
    create unique_index(:signups, [:event_id, :user_id, :time_slot])
  end
end
