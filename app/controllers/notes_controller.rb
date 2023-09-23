class NotesController < ApplicationController
    before_action :set_note, only: %i[show edit update destroy add_note_img]
    def new
        @note = Note.new
    end

    def create
        @note = Note.new(note_params)
        @note.user_id = current_user.id
        if @note.save
            flash[:alert] = 'Nota guardada con éxito' # TODO: Fish flash alert not showing on redirect
            redirect_to edit_note_path(@note), status: :see_other
        else
            flash[:alert] = 'Hubo un error al intentar guardar la nota'
            render action: :new, status: :unprocessable_entity
        end
    end

    def index
        @notes = current_user.notes
    end

    def get_notes
        render json: current_user.notes
    end

    def show
        render json: @note
    end

    def edit
    end

    def update
        if @note.update(note_params)
            destroy_image_attrs
            redirect_to edit_note_path(@note), flash: { notice: 'Nota guardada con éxito' }
        else
            redirect_to action: :edit, status: :unprocessable_entity, alert: 'Hubo un error al intentar actualizar la nota'
        end
    end

    def destroy
        unless @note.destroy
            flash.now[:alert] = 'Hubo un error al intentar borrar la nota'
            return render @note
        end
        redirect_to notes_path, notice: 'Se eliminó la nota correctamente'
    end

    def graph_index
    end

    def add_note_img
        uploaded_file = params[:new_image]
        @image_id = @note.generate_file_id uploaded_file.to_io
    end

    private

    def set_note
        @note = Note.find(params[:id])
    end

    def note_params
        attributes = [:title, :body, images: [], pointers_attributes: [:id, :target_id, :_destroy]]
        permitted_attributes = params.require(:note).permit(attributes)
        map_target_notes permitted_attributes[:pointers_attributes]
        permitted_attributes
    end

    def destroy_image_attrs
        destroyable = params.require(:note).permit([destroy_images: []])[:destroy_images]
        return unless destroyable

        destroyable.each do |checksum|
            target_img = @note.images.find { |image| "#{@note.id}-#{image.checksum}" === checksum }
            target_img.purge if target_img
        end
    end

    def map_target_notes(permit_pointer_attrs)
        permit_pointer_attrs.to_h.each do |idx, edge|
            target_id = edge[:target_id]
            permit_pointer_attrs[idx][:target] = Note.find(target_id) # CREATES A [:target] PARAMETER
        end                                                           # TO FILL IN EDGE FROM ASSOCIATION
    end                                                               # AS IT DOESNT RECEIVE TARGET_IDS BY DEFAULT
end
