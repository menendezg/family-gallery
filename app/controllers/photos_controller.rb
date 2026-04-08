class PhotosController < ApplicationController
  before_action :require_admin, only: [ :new, :create, :destroy ]
  before_action :set_photo, only: [ :show, :destroy ]

  def index
    @photos = Photo.with_attached_image.order(created_at: :desc)
  end

  def show
  end

  def new
    @photo = Photo.new
  end

  def create
    @photo = Current.user.photos.build(photo_params)

    if @photo.save
      redirect_to photos_path, notice: "Photo uploaded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @photo.destroy
    redirect_to photos_path, notice: "Photo deleted."
  end

  private

  def set_photo
    @photo = Photo.find(params[:id])
  end

  def photo_params
    params.require(:photo).permit(:title, :description, :image)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to photos_path, alert: "Not authorized."
    end
  end
end
