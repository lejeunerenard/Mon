require 'pp'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/json'
require 'json'
require 'bcrypt'
require 'serialport'

set :database, "sqlite3:///open_sesame.db"
set :xbee_wireless, 0;

class User < ActiveRecord::Base
  attr_accessible :password_hash, :user
  include BCrypt

  validates_uniqueness_of :user
  validates_presence_of :user, :password_hash
  validates_format_of :user, :with => /^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$/i

  def password
    @password ||= Password.new(self.password_hash)
  end

  def password=(new_password)
    @password_hash = Password.create(new_password)
    self.password_hash = @password_hash
  end

  def self.authenticate(name, password)
    @user = find_by_user(name)
    if @user and @user.approved and @user.password == password
      true
    else
      false
    end
  end

end

enable :sessions

set :port, 4560

get '/' do
  if session[:user_id]
    halt erb(:login) unless session[:user_id] == User.find(session[:user_id]).id
  else
    halt erb(:login)
  end 
  erb :door
end

get '/hack' do
  session[:user_id] = 9283
  redirect '/'
end

post '/login' do
  if User.authenticate(params[:user], params[:password])
    @user = User.find_by_user(params[:user]);
    session[:user_id] = @user.id;
    redirect '/'
  else
    session[:user_id] = nil
    "fail"
  end
end

post '/door' do
  if session[:user_id] or User.authenticate(params[:name], params[:password])
    if settings.xbee_wireless.zero?
      s = SerialPort.open("/dev/ttyAMA0", 9600)
      cmd_on = [0x7E,0x00,0x10,0x17,0x01,0x00,0x13,0xA2,0x00,0x40,0x89,0xDE,0xEE,0xFF,0xFF,0x02,0x44,0x33, 0x05, 0x21].pack('C*')
      cmd_off = [0x7E,0x00,0x10,0x17,0x01,0x00,0x13,0xA2,0x00,0x40,0x89,0xDE,0xEE,0xFF,0xFF,0x02,0x44,0x33, 0x04, 0x22].pack('C*')
      s.write(cmd_on)
      s.write(cmd_off)
      s.close
    else
      system("gpio mode 0 out")
      system("gpio write 0 1")
      system("gpio write 0 0")
      "Door Opened"
    end
  else
    "fail"
  end
end

get '/logout' do
  session[:user_id] = nil
  session.clear
  redirect '/'
end

delete '/users/:id' do
end

post '/users' do
  @user = User.new(:user => params[:user])
  @user.password = params[:password]
  @user.save!
  if @user.valid?
    erb :user_success
  else
    content_type :json
    response = Hash.new()
    error_hash = Hash.new()
    @user.errors.each{ |a|
      error_hash[a.to_s] = @user.errors[a]
    }
    if error_hash.length
      response['errors'] = error_hash
    end
    json response
    #json @user.errors
  end
end

# "Views"
get '/users/add' do
  erb :user_add
end

get '/users/edit' do
  erb :user_add
end

get '/users/:id' do
  if params[:id]
    @user = User.find(params[:id])
    erb :user
  else
    redirect '/'
  end
end

__END__

@@ layout
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>
		Open Sesame
        </title>
        <link rel="stylesheet" href="https://ajax.aspnetcdn.com/ajax/jquery.mobile/1.2.0/jquery.mobile-1.2.0.min.css" />
        <style>
            /* App custom styles */
        </style>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js">
        </script>
        <script src="https://ajax.aspnetcdn.com/ajax/jquery.mobile/1.2.0/jquery.mobile-1.2.0.min.js">
        </script>
	<script type="text/javascript">
		function reset_labels (form) {
		    form.find('label').each(function(i) {
		       $(this).text($(this).attr('for').charAt(0).toUpperCase() + $(this).attr('for').slice(1));
		    });
		};

		function parse_response(form, data) {
			if (data['errors']) {
			       for ( var key in data['errors'] ) {
				  form.find('label[for="'+key+'"]').text(key.charAt(0).toUpperCase() + key.slice(1) + ' ' + data['errors'][key]);
			       }
                        } else {
				$('#msgs').html('<p>Success. User created. <a href="/">Login</a></p>');
			}
		};
	</script>
    </head>
    <body>
        <!-- Home -->
        <div data-role="page" id="page1">
            <div data-role="content">
		<%= yield %>
            </div>
        </div>
        <script>
            //App custom javascript
        </script>
    </body>
</html>

@@ login
		<pre id='msg'></pre>

		<script>
		  // writing
		  $("form").live("submit", function(e) {
		    $.post('/login', {user: $('#user').val(), password: $('#password').val() }, function(data) {
		      if (data == 'fail') {
			$('#msg').html('Login Fail');
		      } else {
			$('#msg').html('Door Open');
			window.location = '/';
		      }
		    });
		    e.preventDefault();
		  });
		</script>
		<h2>Open Sesame</h2>
                <form action="/login" method="POST" data-ajax="false">
			<label for="user">
			    Username
			</label>
			<input name="user" id="user" placeholder="" value="" type="text" />
			<label for="password">
			    Password
			</label>
			<input name="password" id="password" placeholder="" value="" type="password" />
			<input type="submit" data-theme="a" value="Login" />
                </form>
		<p>Don't have a User? <a data-ajax="false" href="/users/add">Register Here</a>.

@@ door
<pre id='msg'></pre>

<script>
  // writing
  $("form").live("submit", function(e) {
    $.post('/door', function(data) {
      if (data == 'fail') {
        $('#msg').html('Login Fail');
      } else {
        $('#msg').html('Door Open');
      }
    });
    e.preventDefault();
  });
</script>

<form method="POST" data-ajax="false">
  <input type="submit" data-inline="true" data-theme="a" value="Open Door"/>
  <a href="/logout" data-ajax="false">Logout</a>
</form>

@@ user
		<h2>User Profile</h2>
                <div id="msgs"></div>
		<p>Username: <%= @user.user %></p>

@@ user_add
		<script>
		  // writing
		  $("form#user_form").live("submit", function(e) {
	            var form = $('form#user_form');
		    reset_labels(form);
		    $.post('/users', {user: $('#user').val(), password: $('#password').val() }, function(data) {
			parse_response(form, data);
		    });
		    e.preventDefault();
		  });
		</script>
		<h2>Sign Up</h2>
                <div id="msgs"></div>
                <form id="user_form" action="/users" method="POST" data-ajax="false">
			<label for="user">
			    Email
			</label>
			<input name="user" id="user" placeholder="" value="" type="text" />
			<label for="password">
			    Password
			</label>
			<input name="password" id="password" placeholder="" value="" type="password" />
			<input type="submit" data-theme="a" value="Go" />
			<p>Back to <a data-ajax="false" href="/">Login</a>.
                </form>

@@ user_success
		<h2>User created.</h2>
		<h2>#boom</h2>
		<p>Now go <a href="/">login</a></p>

