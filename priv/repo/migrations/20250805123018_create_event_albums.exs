defmodule EventPlatform.Repo.Migrations.CreateEventAlbums do
  use Ecto.Migration

  def change do
    create table(:event_albums) do
      add :title, :string, null: false
      add :content, :text
      add :image_url, :string
      add :approved, :boolean, default: false, null: false
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_albums, [:event_id])
    create index(:event_albums, [:user_id])
    create index(:event_albums, [:approved])
    create index(:event_albums, [:inserted_at])
  end
end
