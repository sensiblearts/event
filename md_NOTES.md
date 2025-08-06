Image upload stuff:

https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#consume_uploaded_entry/3
https://www.thestackcanary.com/phoenix-liveuploads-pdf/

https://medium.com/@michaelmunavu83/uploading-images-in-phoenix-live-view-459b481a8385

See old Townseed logic for signup slots:
https://github.com/sensiblearts/townseed_old/blob/master/lib/townseed_web/live/event_live/show.html.leex
AND slots: https://github.com/sensiblearts/townseed_old/blob/master/lib/townseed/signups/slot.ex

Note: The way the uploads are currently working: If you specify BOTH an external url and an uploaded image, then the external url is ignored.

I asked ChatGPT if I could store uploaded images in Hetzner object storage (cheap): It said yes, with config like this:
config :waffle,
  storage: Waffle.Storage.S3,
  bucket: "your-bucket-name"

config :ex_aws,
  access_key_id: "your-access-key",
  secret_access_key: "your-secret-key",
  region: "eu-central", # Not used by Hetzner, but required by ExAws
  s3: [
    scheme: "https://",
    host: "your-bucket-name.eu-central-1.storage.yandexcloud.net", # Or your Hetzner endpoint
    region: "us-east-1" # Dummy, but required
  ]





Timeslot Stuff:


Probably, I will have to extend the slot schema to include a date, because events can have a start date and end date. Perhaps, when you create a slot with the slot form, you can pick a date within the range start-to-end, OR, you can select "All Dates", which will create multiple slots in the db. And probably, each slot will have_many slot_users (rather than has_one); and you can specify the desired and maximum number of volunteers per signup. (If one person is signing up a group, they should enter the number of people and list the other names in a text box).
(See also: https://github.com/sensiblearts/treeplace/blob/master/lib/treeplace/plantings/planting_volunteer.ex)
ALSO, I will have to allow org admin to specify how many photos each participant can upload.


AND FOLLOW THIS:
https://www.youtube.com/watch?v=WXgZAws7fOw


