# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     EventPlatform.Repo.insert!(%EventPlatform.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias EventPlatform.Repo
alias EventPlatform.Accounts
alias EventPlatform.Organizations.{Organization, Place}
alias EventPlatform.Events.{Event, Signup}

# Get or create a sample user for testing
user =
  case Repo.get_by(EventPlatform.Accounts.User, email: "admin@example.com") do
    nil ->
      {:ok, user} =
        Accounts.register_user(%{email: "admin@example.com", password: "password123456"})

      {:ok, user, _expired_tokens} =
        Accounts.update_user_password(user, %{password: "password123456"})

      user

    existing_user ->
      existing_user
  end

# Get or create sample organizations
org1 =
  case Repo.get_by(Organization, name: "Community Garden Club") do
    nil ->
      Repo.insert!(%Organization{
        name: "Community Garden Club",
        user_id: user.id
      })

    existing_org ->
      existing_org
  end

org2 =
  case Repo.get_by(Organization, name: "Neighborhood Watch") do
    nil ->
      Repo.insert!(%Organization{
        name: "Neighborhood Watch",
        user_id: user.id
      })

    existing_org ->
      existing_org
  end

# Get or create sample places
place1 =
  case Repo.get_by(Place, name: "Main Garden") do
    nil ->
      Repo.insert!(%Place{
        name: "Main Garden",
        organization_id: org1.id
      })

    existing_place ->
      existing_place
  end

place2 =
  case Repo.get_by(Place, name: "Community Center") do
    nil ->
      Repo.insert!(%Place{
        name: "Community Center",
        organization_id: org2.id
      })

    existing_place ->
      existing_place
  end

# Add events if they don't exist
unless Repo.get_by(Event, name: "Spring Cleanup Day") do
  Repo.insert!(%Event{
    name: "Spring Cleanup Day",
    description:
      "Join us for our annual spring garden cleanup and preparation for the growing season.",
    start_datetime: ~N[2024-03-15 09:00:00],
    end_datetime: ~N[2024-03-15 15:00:00],
    place_id: place1.id
  })
end

unless Repo.get_by(Event, name: "Summer Plant Sale") do
  Repo.insert!(%Event{
    name: "Summer Plant Sale",
    description: "Annual plant sale with workshops and local vendors",
    start_datetime: ~N[2024-08-15 10:00:00],
    end_datetime: ~N[2024-08-15 16:00:00],
    place_id: place1.id
  })
end

unless Repo.get_by(Event, name: "Winter Workshop") do
  Repo.insert!(%Event{
    name: "Winter Workshop",
    description: "Winter gardening workshop and seed planning session",
    start_datetime: ~N[2025-12-15 14:00:00],
    end_datetime: ~N[2025-12-15 17:00:00],
    place_id: place1.id
  })
end

IO.puts("Sample data updated successfully!")
IO.puts("Login with: admin@example.com / password123456")
