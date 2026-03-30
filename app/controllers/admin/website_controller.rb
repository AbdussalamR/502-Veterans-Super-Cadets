module Admin
  class WebsiteController < InternalController
    before_action :ensure_super_admin

    HOME_KEYS      = %w[hero_title hero_subtitle about_text].freeze
    CONTACT_KEYS   = %w[address email phone].freeze
    AUDITIONS_KEYS = %w[signup_link what_to_expect].freeze

    # GET /admin/website
    def index
      @active_tab = params[:tab] || 'home'
      load_all_data
    end

    # PATCH /admin/website/home
    def update_home
      permitted = params.require(:home).permit(*HOME_KEYS)
      permitted.each { |key, val| PageContent.set('home', key, val, draft: true) }
      redirect_to admin_website_path(tab: 'home'),
                  notice: 'Home page draft saved. Preview your changes, then publish when ready.'
    end

    # POST /admin/website/home/publish
    def publish_home
      PageContent.publish_page!('home')
      redirect_to admin_website_path(tab: 'home'), notice: 'Home page content published to the live site!'
    end

    # DELETE /admin/website/home/draft
    def discard_home_draft
      PageContent.discard_drafts!('home')
      redirect_to admin_website_path(tab: 'home'), notice: 'Home page draft discarded.'
    end

    # PATCH /admin/website/auditions
    def update_auditions
      permitted = params.require(:auditions).permit(*AUDITIONS_KEYS)
      permitted.each { |key, val| PageContent.set('auditions', key, val, draft: true) }
      redirect_to admin_website_path(tab: 'auditions'),
                  notice: 'Auditions page draft saved. Publish when ready.'
    end

    # POST /admin/website/auditions/publish
    def publish_auditions
      PageContent.publish_page!('auditions')
      redirect_to admin_website_path(tab: 'auditions'), notice: 'Auditions page content published!'
    end

    # DELETE /admin/website/auditions/draft
    def discard_auditions_draft
      PageContent.discard_drafts!('auditions')
      redirect_to admin_website_path(tab: 'auditions'), notice: 'Auditions draft discarded.'
    end

    # PATCH /admin/website/contact
    def update_contact
      permitted = params.require(:contact).permit(*CONTACT_KEYS)
      permitted.each { |key, val| PageContent.set('contact', key, val, draft: true) }
      redirect_to admin_website_path(tab: 'contact'),
                  notice: 'Contact page draft saved. Preview your changes, then publish when ready.'
    end

    # POST /admin/website/contact/publish
    def publish_contact
      PageContent.publish_page!('contact')
      redirect_to admin_website_path(tab: 'contact'), notice: 'Contact page content published to the live site!'
    end

    # DELETE /admin/website/contact/draft
    def discard_contact_draft
      PageContent.discard_drafts!('contact')
      redirect_to admin_website_path(tab: 'contact'), notice: 'Contact page draft discarded.'
    end

    # POST /admin/website/messages/:id/read
    def mark_message_read
      msg = ContactMessage.find(params[:id])
      msg.read!
      redirect_to admin_website_path(tab: 'messages'), notice: 'Message marked as read.'
    end

    # GET /admin/website/preview/:page
    def preview
      @preview_page = params[:page]
      @preview_mode = true

      case @preview_page
      when 'home'
        @preview_home_contents = draft_or_published_hash('home')
        @home_photos = MediaPhoto.for_page('home').published_only.ordered
      when 'contact'
        @preview_contact_contents = draft_or_published_hash('contact')
      when 'auditions'
        @preview_auditions_contents = draft_or_published_hash('auditions')
        now = Time.current
        @current_auditions = AuditionSession.where('start_datetime <= ? AND end_datetime >= ?', now, now).chronological
        @future_auditions  = AuditionSession.where('start_datetime > ?', now).chronological
        @past_auditions    = AuditionSession.where('end_datetime < ?', now).chronological
      else
        redirect_to admin_website_path, alert: 'Invalid preview page.'
        return
      end

      render "admin/website/preview_#{@preview_page}", layout: 'public'
    end

    private

    def load_all_data
      # Home tab
      @home_published = contents_hash('home', draft: false)
      @home_draft     = contents_hash('home', draft: true)
      @home_has_draft = PageContent.has_drafts?('home')
      @home_form_vals = @home_has_draft ? @home_draft.merge(@home_published) { |_, d, _| d } : @home_published
      @home_photos    = MediaPhoto.for_page('home').ordered

      # Media tab
      @media_photos = MediaPhoto.for_page('media').ordered
      @media_videos = MediaVideo.ordered

      # Auditions tab
      now = Time.current
      @audition_sessions    = AuditionSession.chronological
      @current_auditions    = AuditionSession.where('start_datetime <= ? AND end_datetime >= ?', now, now).chronological
      @future_auditions     = AuditionSession.where('start_datetime > ?', now).chronological
      @past_auditions       = AuditionSession.where('end_datetime < ?', now).chronological
      @new_audition_session = AuditionSession.new

      @auditions_published = contents_hash('auditions', draft: false)
      @auditions_draft     = contents_hash('auditions', draft: true)
      @auditions_has_draft = PageContent.has_drafts?('auditions')
      @auditions_form_vals = @auditions_has_draft ? @auditions_draft.merge(@auditions_published) { |_, d, _| d } : @auditions_published

      # Contact tab
      @contact_published = contents_hash('contact', draft: false)
      @contact_draft     = contents_hash('contact', draft: true)
      @contact_has_draft = PageContent.has_drafts?('contact')
      @contact_form_vals = @contact_has_draft ? @contact_draft.merge(@contact_published) { |_, d, _| d } : @contact_published

      # Book Us tab
      @performance_requests      = PerformanceRequest.newest
      @pending_requests_count    = PerformanceRequest.pending.count

      # Messages tab
      @contact_messages       = ContactMessage.recent
      @unread_messages_count  = ContactMessage.unread.count
    end

    def contents_hash(page, draft:)
      PageContent.where(page_name: page, is_draft: draft)
                 .each_with_object({}) { |r, h| h[r.content_key] = r.content_value }
    end

    # Merges draft over published so drafts take priority
    def draft_or_published_hash(page)
      contents_hash(page, draft: true).merge(contents_hash(page, draft: false)) { |_, d, _| d }
    end
  end
end
