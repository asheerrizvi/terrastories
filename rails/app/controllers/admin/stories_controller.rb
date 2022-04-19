module Admin
  class StoriesController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Story.
    #     page(params[:page]).
    #     per(10)
    # end

    Rails.logger.debug("My object: #{StoriesController.inspect}")

    def new
      # ensures that story is built for the current community (so scopes in administrate dashboards work)
      resource = current_community.stories.new
      authorize_resource(resource)
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource),
      }
    end

    def create
      resource = resource_class.new(resource_params)
      # ensures story is created within the current community
      resource.community = current_community
      authorize_resource(resource)

      if resource.save
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success"),
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }
      end
    end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Story.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def import_csv
      if params[:file].nil?
        redirect_back(fallback_location: root_path)
        flash[:error] = "No file was attached!"
      else
        filepath = params[:file].read
        errors = Story.import_csv(filepath, current_community)
        errors.empty? ? flash[:notice] = "Stories were imported successfully! View them #{view_context.link_to 'here', admin_stories_path}." : flash[:error] = errors
        redirect_back(fallback_location: root_path)
      end
    end

    def export_sample_csv
      send_data Story.export_sample_csv, filename: "sample_stories.csv"
    end

    def import_page
      render "import_page"
    end

    def delete
      remove_attachment
    end

    private

    def remove_attachment
      photo = ActiveStorage::Attachment.find(params[:attachment_id])
      photo.purge
      redirect_back(fallback_location: "/")
    end

    def destroy_pdf_attachment
      return unless current_user.admin?

      destroyPdf = Story.find(params[:record_id])
      destroyPdf.pdf_attachment.purge

      redirect_back(fallback_location: "/")
    end    
  end
end
