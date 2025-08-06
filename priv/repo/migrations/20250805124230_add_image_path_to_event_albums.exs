defmodule EventPlatform.Repo.Migrations.AddImagePathToEventAlbums do
  use Ecto.Migration

  def change do
    alter table(:event_albums) do
      add :image_path, :string
    end
  end
end
