module Admin
  class MediaVideosController < InternalController
    before_action :require_admin

    def create
      video = MediaVideo.new(
        title:       params[:title],
        youtube_url: params[:youtube_url],
        position:    MediaVideo.next_position,
        published:   false
      )

      if video.save
        redirect_to admin_website_path(tab: 'media'), notice: 'Video added. Click Publish to make it live.'
      else
        redirect_to admin_website_path(tab: 'media'),
                    alert: "Could not add video: #{video.errors.full_messages.to_sentence}"
      end
    end

    def publish
      video = MediaVideo.find(params[:id])
      video.update!(published: true)
      redirect_to admin_website_path(tab: 'media'), notice: 'Video is now live on the site.'
    end

    def destroy
      video = MediaVideo.find(params[:id])
      video.destroy
      redirect_to admin_website_path(tab: 'media'), notice: 'Video removed.'
    end
  end
end
