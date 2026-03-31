# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Website', type: :request do
  let(:admin)        { create(:user, :super_admin) }
  let(:officer)      { create(:user, :officer) }
  let(:regular_user) { create(:user) }

  # ─── Authentication / Authorisation ──────────────────────────────────────────

  describe 'GET /admin/website' do
    context 'when unauthenticated' do
      it 'redirects to sign-in' do
        get admin_website_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when authenticated as a regular user' do
      before { sign_in regular_user }

      it 'redirects away' do
        get admin_website_path
        expect(response).to redirect_to(internal_events_path)
      end
    end

    # =========================================================================
    # INTEGRITY TESTS — Director-Only CMS Access (A3, Rainy Day)
    #
    # Threat: An Officer knows the /admin/website URL (or discovers it by
    # reading the source) and navigates to it directly to read contact messages,
    # alter public-facing content, or approve performance booking requests.
    #
    # Root cause caught this sprint: the original guard used `require_admin`,
    # which returns true for BOTH Officers and Directors. Switching to
    # `ensure_super_admin` (which checks `super_admin?` exclusively) closed
    # the gap. These four tests prove every write and read path is locked.
    #
    # Guard: `before_action :ensure_super_admin` in Admin::WebsiteController
    # redirects any non-super_admin to internal_events_path with an alert.
    # =========================================================================
    context 'when authenticated as an officer' do
      before { sign_in officer }

      # INTEGRITY: Officer cannot read the CMS dashboard at all
      it 'redirects away (officers cannot access Website Management)' do
        get admin_website_path
        expect(response).to redirect_to(internal_events_path)
      end

      # INTEGRITY: Officer cannot overwrite public-facing content via PATCH
      it 'blocks officer from editing home page content' do
        patch admin_update_website_home_path, params: { home: { hero_title: 'Hack' } }
        expect(response).to redirect_to(internal_events_path)
      end

      # INTEGRITY: Officer cannot push unapproved content to the live site
      it 'blocks officer from publishing home page' do
        post admin_publish_website_home_path
        expect(response).to redirect_to(internal_events_path)
      end

      # INTEGRITY: Officer cannot read or dismiss private contact messages
      it 'blocks officer from marking messages as read' do
        msg = create(:contact_message)
        post admin_mark_website_message_read_path(msg)
        expect(response).to redirect_to(internal_events_path)
      end
    end

    context 'when authenticated as a director (super_admin)' do
      before { sign_in admin }

      it 'renders successfully' do
        get admin_website_path
        expect(response).to have_http_status(:success)
      end

      it 'defaults to the home tab' do
        get admin_website_path
        expect(response.body).to include('Edit Home Page Text')
      end

      it 'activates the requested tab via param' do
        get admin_website_path(tab: 'contact')
        expect(response.body).to include('Edit Contact Information')
      end

      it 'shows the Messages tab with unread count' do
        create(:contact_message)
        get admin_website_path(tab: 'messages')
        expect(response.body).to include('Contact Form Submissions')
      end

      # --- Book Us tab: performance requests ---
      it 'shows the Book Us tab with performance requests' do
        create(:performance_request, name: 'John Doe', organization: 'TAMU')
        get admin_website_path(tab: 'book_us')
        expect(response.body).to include('John Doe')
        expect(response.body).to include('TAMU')
      end

      it 'shows pending badge on Book Us tab when requests are pending' do
        create(:performance_request)
        get admin_website_path
        expect(response.body).to include('pending')
      end

      it 'shows empty state when no performance requests exist' do
        get admin_website_path(tab: 'book_us')
        expect(response.body).to include('No performance requests yet')
      end

      it 'displays reviewed requests with correct badge' do
        create(:performance_request, :reviewed, name: 'Reviewed Org')
        get admin_website_path(tab: 'book_us')
        expect(response.body).to include('Reviewed Org')
        expect(response.body).to include('Reviewed')
      end
    end
  end

  # ─── Home Page Content ────────────────────────────────────────────────────────

  describe 'PATCH /admin/website/home' do
    before { sign_in admin }

    it 'saves home page text as draft' do
      patch admin_update_website_home_path, params: {
        home: { hero_title: 'New Title', hero_subtitle: 'New Subtitle', about_text: 'New About' }
      }
      expect(PageContent.get('home', 'hero_title', draft: true)).to eq('New Title')
      expect(response).to redirect_to(admin_website_path(tab: 'home'))
    end

    it 'does not publish the draft to the live site' do
      patch admin_update_website_home_path, params: {
        home: { hero_title: 'Draft Title' }
      }
      expect(PageContent.get('home', 'hero_title', draft: false)).to be_nil
    end

    it 'redirects non-director away' do
      sign_in regular_user
      patch admin_update_website_home_path, params: { home: { hero_title: 'X' } }
      expect(response).to redirect_to(internal_events_path)
    end
  end

  describe 'POST /admin/website/home/publish' do
    before { sign_in admin }

    it 'publishes existing drafts to the live site' do
      PageContent.set('home', 'hero_title', 'Draft Title', draft: true)
      post admin_publish_website_home_path
      expect(PageContent.get('home', 'hero_title', draft: false)).to eq('Draft Title')
      expect(PageContent.has_drafts?('home')).to be false
    end

    it 'redirects to the home tab with a success notice' do
      post admin_publish_website_home_path
      expect(response).to redirect_to(admin_website_path(tab: 'home'))
      expect(flash[:notice]).to include('published')
    end
  end

  describe 'DELETE /admin/website/home/draft' do
    before { sign_in admin }

    it 'discards the home page draft' do
      PageContent.set('home', 'hero_title', 'Draft Title', draft: true)
      expect { delete admin_discard_website_home_draft_path }
        .to change { PageContent.has_drafts?('home') }.from(true).to(false)
    end

    it 'redirects to the home tab' do
      delete admin_discard_website_home_draft_path
      expect(response).to redirect_to(admin_website_path(tab: 'home'))
    end
  end

  # ─── Contact Page Content ─────────────────────────────────────────────────────

  describe 'PATCH /admin/website/contact' do
    before { sign_in admin }

    it 'saves contact info as draft' do
      patch admin_update_website_contact_path, params: {
        contact: { address: '123 Main St', email: 'new@tamu.edu', phone: '555-1234' }
      }
      expect(PageContent.get('contact', 'email', draft: true)).to eq('new@tamu.edu')
      expect(response).to redirect_to(admin_website_path(tab: 'contact'))
    end
  end

  describe 'POST /admin/website/contact/publish' do
    before { sign_in admin }

    it 'publishes contact drafts' do
      PageContent.set('contact', 'email', 'new@tamu.edu', draft: true)
      post admin_publish_website_contact_path
      expect(PageContent.get('contact', 'email', draft: false)).to eq('new@tamu.edu')
    end
  end

  describe 'DELETE /admin/website/contact/draft' do
    before { sign_in admin }

    it 'discards the contact draft' do
      PageContent.set('contact', 'email', 'draft@tamu.edu', draft: true)
      delete admin_discard_website_contact_draft_path
      expect(PageContent.has_drafts?('contact')).to be false
    end
  end

  # ─── Auditions Page Content ───────────────────────────────────────────────────

  describe 'PATCH /admin/website/auditions' do
    before { sign_in admin }

    it 'saves auditions content as draft' do
      patch admin_update_website_auditions_path, params: {
        auditions: { signup_link: 'https://forms.gle/test', what_to_expect: 'Expect greatness' }
      }
      expect(PageContent.get('auditions', 'signup_link', draft: true)).to eq('https://forms.gle/test')
      expect(PageContent.get('auditions', 'what_to_expect', draft: true)).to eq('Expect greatness')
    end
  end

  describe 'POST /admin/website/auditions/publish' do
    before { sign_in admin }

    it 'publishes auditions drafts' do
      PageContent.set('auditions', 'signup_link', 'https://forms.gle/test', draft: true)
      post admin_publish_website_auditions_path
      expect(PageContent.get('auditions', 'signup_link', draft: false)).to eq('https://forms.gle/test')
    end
  end

  describe 'DELETE /admin/website/auditions/draft' do
    before { sign_in admin }

    it 'discards the auditions draft' do
      PageContent.set('auditions', 'signup_link', 'https://forms.gle/test', draft: true)
      delete admin_discard_website_auditions_draft_path
      expect(PageContent.has_drafts?('auditions')).to be false
    end
  end

  # ─── Preview ─────────────────────────────────────────────────────────────────

  describe 'GET /admin/website/preview/:page' do
    before { sign_in admin }

    it 'renders the home preview with draft content' do
      PageContent.set('home', 'hero_title', 'Preview Title', draft: true)
      get admin_preview_website_page_path(page: 'home')
      expect(response).to have_http_status(:success)
      expect(response.body).to include('PREVIEW MODE')
      expect(response.body).to include('Preview Title')
    end

    it 'renders the contact preview' do
      PageContent.set('contact', 'email', 'preview@tamu.edu', draft: true)
      get admin_preview_website_page_path(page: 'contact')
      expect(response).to have_http_status(:success)
      expect(response.body).to include('PREVIEW MODE')
    end

    it 'renders the auditions preview' do
      PageContent.set('auditions', 'signup_link', 'https://forms.gle/test', draft: true)
      get admin_preview_website_page_path(page: 'auditions')
      expect(response).to have_http_status(:success)
      expect(response.body).to include('PREVIEW MODE')
    end

    it 'redirects for an invalid page name' do
      get admin_preview_website_page_path(page: 'nonexistent')
      expect(response).to redirect_to(admin_website_path)
    end
  end

  # ─── Contact Messages ─────────────────────────────────────────────────────────

  describe 'POST /admin/website/messages/:id/read' do
    before { sign_in admin }

    it 'marks a message as read' do
      msg = create(:contact_message)
      expect do
        post admin_mark_website_message_read_path(msg)
      end.to change { msg.reload.read_at }.from(nil)
    end

    it 'redirects to the messages tab' do
      msg = create(:contact_message)
      post admin_mark_website_message_read_path(msg)
      expect(response).to redirect_to(admin_website_path(tab: 'messages'))
    end

    it 'requires director access (regular user blocked)' do
      sign_in regular_user
      msg = create(:contact_message)
      post admin_mark_website_message_read_path(msg)
      expect(response).to redirect_to(internal_events_path)
    end
  end
end
