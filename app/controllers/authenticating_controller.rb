module AuthenticatingController
  private

  def heroku_app
    if Rails.env.development?
      dev_app = ENV['DEVELOPMENT_APP']
      unless dev_app
        raise 'Set DEVELOPMENT_APP to app to check auth against in dev'
      end
      dev_app
    else
      ENV.fetch("HEROKU_APP_NAME")
    end
  end

  def authenticate_user!
    session = cookies.encrypted[:_session_id]
    if session && session['token'] && session['email']
      heroku_api = PlatformAPI.connect_oauth(session['token'])

      heroku_api.app.info(heroku_app)

      session['email']
    end
  end

  def authenticate_user
    begin
      authenticate_user!
    rescue Excon::Error::Forbidden
      false
    rescue Excon::Error::Unauthorized
      false
    rescue Excon::Error::NotFound
      false
    end
  end

  def authenticate_user_action!
    begin
      unless authenticate_user!
        respond_to do |format|
          format.html { redirect_to login_path }
          format.json { render json: {'error' => 'not_logged_in'}, status: :unauthorized}
        end
      end
    rescue Excon::Error::Unauthorized
      respond_to do |format|
        format.html { redirect_to login_path }
        format.json { render json: {'error' => 'unauthorized'}, status: :unauthorized}
      end
    rescue Excon::Error::Forbidden
      respond_to do |format|
        format.html { render html: "Forbidden", status: :forbidden }
        format.json { render json: {'error' => 'forbidden'}, status: :forbidden }
      end
    rescue Excon::Error::NotFound => error
      respond_to do |format|
        format.html { render html: "Not Found: #{error}", status: :not_found}
        format.json { render json: {'error' => 'not_found'}, status: :not_found}
      end
    end
  end
end
