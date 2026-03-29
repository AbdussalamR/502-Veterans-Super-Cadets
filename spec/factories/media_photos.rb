FactoryBot.define do
  factory :media_photo do
    page_name { 'media' }
    caption   { 'Test photo' }
    position  { 1 }
    published { false }

    after(:build) do |photo|
      photo.image.attach(
        io:           StringIO.new('fake image data'),
        filename:     'test.jpg',
        content_type: 'image/jpeg'
      )
    end

    trait :published do
      published { true }
    end

    trait :home do
      page_name { 'home' }
    end
  end
end
