# Only here so drink forms can remove an image: Madmin's file fields remove through this resource
class ActiveStorage::AttachmentResource < Madmin::Resource
  menu false

  attribute :id, form: false
  attribute :name
  attribute :created_at, form: false
end
