# frozen_string_literal: true

class UsersController < ApplicationController
  respond_to :html, :json
  skip_before_action :api_check
  before_action :logged_in_only, only: %i[edit upload_limit update]

  def index
    if params[:name].present?
      @user = User.find_by!(name: params[:name])
      redirect_to(user_path(@user, n: params[:n]))
    else
      @users = User.search(search_params(User)).paginate(params[:page], limit: params[:limit], search_count: params[:search])
      respond_with(@users) do |format|
        format.json do
          render(json: @users.to_json)
          expires_in(params[:expiry].to_i.days) if params[:expiry]
        end
      end
    end
  end

  def show
    @user = User.find(User.name_or_id_to_id_forced(params[:id]))
    @presenter = UserPresenter.new(@user)
    respond_with(@user, methods: @user.full_attributes)
  end

  def new
    raise(User::PrivilegeError, "Already signed in") unless CurrentUser.is_anonymous?
    return access_denied("Signups are disabled") unless FemboyFans.config.enable_signups?
    @user = User.new
    respond_with(@user)
  end

  def edit
    @user = User.find(CurrentUser.id)
    raise(User::PrivilegeError, "Must verify account email") unless @user.is_verified?
    respond_with(@user)
  end

  def home
    @user = CurrentUser.user
  end

  def search
  end

  def upload_limit
    authorize(User)
    @presenter = UserPresenter.new(CurrentUser.user)
    pieces = CurrentUser.upload_limit_pieces
    @approved_count = pieces[:approved]
    @deleted_count = pieces[:deleted]
    @pending_count = pieces[:pending]
  end

  def me
    @user = authorize(CurrentUser.user)
    respond_with(@user, methods: @user.full_attributes)
  end

  def create
    raise(User::PrivilegeError, "Already signed in") unless CurrentUser.is_anonymous?
    raise(User::PrivilegeError, "Signups are disabled") unless FemboyFans.config.enable_signups?
    User.transaction do
      @user = User.new(permitted_attributes(User).merge({ last_ip_addr: request.remote_ip }))
      @user.validate_email_format = true
      @user.email_verification_key = "1" if FemboyFans.config.enable_email_verification?
      if !FemboyFans.config.enable_recaptcha? || verify_recaptcha(model: @user)
        @user.save
        if @user.errors.empty?
          session[:user_id] = @user.id
          session[:ph] = @user.password_token
          if FemboyFans.config.enable_email_verification?
            Users::EmailConfirmationMailer.confirmation(@user).deliver_now
          end
        else
          flash[:notice] = "Sign up failed: #{@user.errors.full_messages.join('; ')}"
        end
        set_current_user
      else
        flash[:notice] = "Sign up failed"
      end
      respond_with(@user)
    end
  rescue ::Mailgun::CommunicationError
    session[:user_id] = nil
    @user.errors.add(:email, "There was a problem with your email that prevented sign up")
    @user.id = nil
    flash[:notice] = "There was a problem with your email that prevented sign up"
    respond_with(@user)
  end

  def update
    @user = User.find(CurrentUser.id)
    @user.validate_email_format = true
    raise(User::PrivilegeError, "Must verify account email") unless @user.is_verified?
    @user.update(permitted_attributes(@user))
    if @user.errors.any?
      flash[:notice] = @user.errors.full_messages.join("; ")
    else
      flash[:notice] = "Settings updated"
    end
    respond_with(@user) do |format|
      format.html { redirect_back(fallback_location: edit_users_path) }
    end
  end

  def custom_style
    authorize(User)
    @css = CustomCss.parse(CurrentUser.user.custom_style)
    expires_in(10.years)
  end
end
