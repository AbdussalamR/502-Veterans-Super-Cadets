module Admin
  class MediaPhotosController < InternalController
    before_action :require_admin

    def create
      page = params[:page_name].presence_in(MediaPhoto::PAGES) || 'media'

      # Home page is single-photo: replace any existing photo
      if page == 'home'
        MediaPhoto.for_page('home').each do |old|
          old.image.purge_later if old.image.attached?
          old.destroy
        end
      end

      photo = MediaPhoto.new(
        page_name: page,
        caption:   params[:caption],
        position:  MediaPhoto.next_position(page),
        published: false
      )
      photo.image = params[:image] if params[:image].present?

      if photo.save
        redirect_to admin_website_path(tab: page_to_tab(page)), notice: 'Photo uploaded. Click Publish to make it live.'
      else
        redirect_to admin_website_path(tab: page_to_tab(page)),
                    alert: "Could not upload photo: #{photo.errors.full_messages.to_sentence}"
      end
    end

    def publish
      photo = MediaPhoto.find(params[:id])
      photo.update!(published: true)
      redirect_to admin_website_path(tab: page_to_tab(photo.page_name)), notice: 'Photo is now live on the site.'
    end

    def destroy
      photo = MediaPhoto.find(params[:id])
      tab   = page_to_tab(photo.page_name)
      photo.image.purge_later if photo.image.attached?
      photo.destroy
      redirect_to admin_website_path(tab: tab), notice: 'Photo removed.'
    end

    private

    def page_to_tab(page_name)
      page_name == 'home' ? 'home' : 'media'
    end
  end
end
