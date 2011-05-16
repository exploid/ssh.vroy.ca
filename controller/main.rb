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

    # Connect
    session[:connection] = Net::SSH.start(nil, nil, creds)
    session[:shell] = session[:connection].shell

    # Get pwd for first prompt display
    session[:pwd] = session[:shell].exec!("pwd").last.gsub("\r\n", "")

    # Do not store password along with the credentials
    creds.delete(:password)
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
    command = h(request[:command])
    
    exit_status, result = session[:shell].exec!( command )
    session[:pwd] = session[:shell].exec!("pwd").last

    result = h(result) # sanitize the output

    result.gsub!("\r\n", "<br/>")
    result.gsub!("\t", "        ")
    result.gsub!(" ", "&nbsp;")
    session[:pwd].gsub!("\r\n", "")
    
    return { :result => result, :pwd => session[:pwd] }.to_json
  rescue Exception => e
    puts e
    return { :result => "Something wrong happened, please connect again." }.to_json
  end

end
