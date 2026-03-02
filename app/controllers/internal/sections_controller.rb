module Internal
  class SectionsController < InternalController
    before_action :ensure_super_admin

    def index
      @sections = Section.all
      @section = Section.new
    end

    def create
      @section = Section.new(section_params)
      if @section.save
        redirect_to internal_sections_path, notice: "Section '#{@section.name}' created."
      else
        @sections = Section.all
        render :index
      end
    end

    def destroy
      @section = Section.find(params[:id])
      @section.destroy
      redirect_to internal_sections_path, notice: "Section removed."
    end

    private

    def section_params
      params.require(:section).permit(:name)
    end
  end
end