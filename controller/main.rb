class MainController < Ramaze::Controller
  layout '/layout'
  map '/'
  
  def index
  end

  def connect
    # Gather credentials required for connecting and re-connecting
    creds = {}
    keys = [ :host_name, :user, :password, :port ]
    request[ *keys ].each_with_index do |value, index|
      key = keys[ index ]
      creds[key] = value
    end

    # Connect and init shell
    session[:connection] = Net::SSH.start(nil, nil, creds)
    session[:shell] = session[:connection].shell

    execute_pwd # Set pwd for first prompt display

    creds.delete(:password) # Do not store password along with the credentials
    session[:credentials] = creds

    redirect Rs(:ssh)
  rescue Exception => e
    flash[:error] = e.message
    redirect_referer
  end

  def disconnect
    session.clear
    redirect Rs()
  end
  
  def ssh
  end

  deny_layout :command
  def command
    # request[:command] is not escaped so that this executes: `echo "Test"`
    exit_status, result = execute_cmd( request[:command] )
    execute_pwd # Set pwd again in case it has changed after running the command

    return { :result => result, :pwd => session[:pwd] }.to_json
  rescue Exception => e
    puts e
    return { :result => "Something wrong happened, please connect again." }.to_json
  end

  private

  # Helper method that sets session[:pwd]. Runs session[:shell].exec!("pwd")
  # and prepare the output for the web.
  def execute_pwd
    session[:pwd] = session[:shell].exec!("pwd").last.gsub("\r\n", "")
  end

  # Helper method to run a command on session[:shell] with #exec! and sanitize it for the web.
  def execute_cmd(cmd)
    exit_status, result = session[:shell].exec!( cmd )

    # Prepare the output to be displayed on the web.
    result = h(result)
    result.gsub!("\r\n", "<br/>")
    result.gsub!("\t", "        ")
    result.gsub!(" ", "&nbsp;")

    return exit_status, result
  end

end
