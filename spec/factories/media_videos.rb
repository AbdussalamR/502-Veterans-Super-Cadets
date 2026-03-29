FactoryBot.define do
  factory :media_video do
    title       { 'Test Video' }
    youtube_url { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    youtube_id  { 'dQw4w9WgXcQ' }
    position    { 1 }
    published   { false }

    trait :published do
      published { true }
    end
  end
end
