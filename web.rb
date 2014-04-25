require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'json'
require 'net-ldap'
require 'date'
require 'haml'
 
ldap = Net::LDAP.new
ldap.host = 'IP Address'
ldap.port = 389
ldap.auth "Admin", "Password"

treebase = "ou=************, dc=***********, dc=local"

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/in_out.db")
class Staff
  include DataMapper::Resource
  property :id, Serial
  property :fname, Text, :required => true
  property :lname, Text, :required => true
  property :email, Text, :required => true
  property :phone, Text
  property :location, Text
  property :department, Text
  property :title, Text
  property :status, Boolean, :required => true, :default => false
  property :comments, Text
  property :created, DateTime
end
DataMapper.finalize.auto_upgrade!

get '/?' do
  protected!
  @staff = Staff.all(:order => :fname)
  @windows_user = ENV['USERNAME']
  redirect '/new' if @staff.empty?
  haml :index
end

get '/new/?' do
  @title = "Add Staff"
  erb :new
end

post '/new/?' do
  Staff.create(:fname => params[:fname], :lname => params[:lname], :email => params[:email], :created => Time.now)
  redirect '/'
end

post '/status/?' do
  staff = Staff.first(:id => params[:id])
  staff.status = !staff.status
  staff.save
  content_type 'application/json'
  value = staff.status ? 'Out' : 'In'
  { :id => params[:id], :status => value }.to_json
end

get '/delete/:id/?' do
  @staff = Staff.first(:id => params[:id])
  erb :delete
end

post '/delete/:id/?' do
  if params.has_key?("ok")
    staff = Staff.first(:id => params[:id])
    staff.destroy
    redirect '/'
  else
    redirect '/'
  end
end  

get '/adusers' do 
  @staff = Staff.all(:fields => [:id, :email])
  filter = Net::LDAP::Filter.eq("mail", "*")
  @b = Hash.new
  ldap.search(:base => treebase, :filter => filter) do |entry|    
    if entry.respond_to?("l")
      email = ""
      if entry.respond_to?("mail")
        email = entry.mail
      end      
      name = ""
      if entry.respond_to?("cn")
        name = entry.cn
      end     
      @b[name] = {:name => name, :email => email} 
    end
  end
  haml :add_user_from_ad
end

  
get '/email/:id' do 
  filter = Net::LDAP::Filter.eq("mail", params[:id])
  @b = Hash.new
  ldap.search(:base => treebase, :filter => filter) do |entry|    
    if entry.respond_to?("l")
  
      title = ""
      if entry.respond_to?("title")
        title = entry.title
      end
      
      logon_name = ""
      if entry.respond_to?("sAMAccountName")
        logon_name = entry.sAMAccountName
      end
 
      email = ""
      if entry.respond_to?("mail")
        email = entry.mail
      end
    
      telephonenumber = ""
      if entry.respond_to?("telephonenumber")
        telephonenumber = entry.telephonenumber
      end
 
      location = ""
      if entry.respond_to?("l")
        location = entry.l
      end
    
      department = ""
      if entry.respond_to?("department")
        department = entry.department
      end
      
      manager = ""
      if entry.respond_to?("manager")
        manager = entry.manager
      end
      
      name = ""
      if entry.respond_to?("cn")
        name = entry.cn
      end
      
      @b[name] = {:name => name, :email => email, :phone => telephonenumber, :location => location, :department => department, :title => title, :logon_name => logon_name}
      @manager = {:manager => manager}
 
    end
  end
  haml :detail
end
  