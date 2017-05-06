class Admin::Booking::ChatsController < ApplicationController
  before_action :set_admin_booking_chat, only: [:show, :edit, :update, :destroy]

  # GET /admin/booking/chats
  def index
    @admin_booking_chats = Admin::Booking::Chat.all
  end

  # GET /admin/booking/chats/1
  def show
  end

  # GET /admin/booking/chats/new
  def new
    @admin_booking_chat = Admin::Booking::Chat.new
  end

  # GET /admin/booking/chats/1/edit
  def edit
  end

  # POST /admin/booking/chats
  def create
    @admin_booking_chat = Admin::Booking::Chat.new(admin_booking_chat_params)

    if @admin_booking_chat.save
      redirect_to @admin_booking_chat, notice: 'Chat was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /admin/booking/chats/1
  def update
    if @admin_booking_chat.update(admin_booking_chat_params)
      redirect_to @admin_booking_chat, notice: 'Chat was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /admin/booking/chats/1
  def destroy
    @admin_booking_chat.destroy
    redirect_to admin_booking_chats_url, notice: 'Chat was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_booking_chat
      @admin_booking_chat = Admin::Booking::Chat.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def admin_booking_chat_params
      params.require(:admin_booking_chat).permit(:name)
    end
end
