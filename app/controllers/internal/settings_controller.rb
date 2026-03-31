# frozen_string_literal: true

module Internal
  class SettingsController < InternalController
    before_action :require_super_admin!

    def edit
      @setting = ApplicationSetting.instance
    end

    def update
      @setting = ApplicationSetting.instance
      if @setting.update(setting_params)
        flash[:success] = 'Notification settings saved.'
        redirect_to edit_internal_settings_path
      else
        flash.now[:alert] = @setting.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      params.expect(application_setting: [:reminder_hours_before])
    end

    def require_super_admin!
      redirect_to internal_events_path, alert: 'Not authorized.' unless current_user&.super_admin?
    end
  end
end
