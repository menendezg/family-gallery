class FoldersController < ApplicationController
  before_action :require_admin, only: [ :new, :create, :destroy ]
  before_action :set_folder, only: [ :show, :destroy ]

  def index
    @folders = Folder.order(created_at: :desc)
  end

  def show
    @photos = @folder.photos.with_attached_image.order(created_at: :desc)
  end

  def new
    @folder = Folder.new
  end

  def create
    @folder = Folder.new(folder_params)
    @folder.user = Current.user

    if @folder.save
      redirect_to @folder, notice: "Album created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @folder.destroy
    redirect_to folders_path, notice: "Album deleted."
  end

  private

  def set_folder
    @folder = Folder.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name, :description)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to folders_path, alert: "Not authorized."
    end
  end
end
