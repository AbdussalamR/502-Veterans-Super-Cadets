FactoryBot.define do
  factory :page_content do
    page_name   { 'home' }
    content_key { 'hero_title' }
    content_value { 'The Singing Cadets' }
    is_draft { false }

    trait :draft do
      is_draft { true }
    end

    trait :home_hero_title do
      page_name   { 'home' }
      content_key { 'hero_title' }
      content_value { 'The Singing Cadets' }
    end

    trait :contact_email do
      page_name   { 'contact' }
      content_key { 'email' }
      content_value { 'choir@tamu.edu' }
    end

    trait :auditions_signup_link do
      page_name   { 'auditions' }
      content_key { 'signup_link' }
      content_value { 'https://forms.gle/example' }
    end
  end
end
