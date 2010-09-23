require 'curb'
require 'digest/md5'
module Virtuozzo
module Sync
 	class Servers
	include Virtuozzo
		def self.list(value,&block)
			@config=value
			@pass=Digest::MD5.hexdigest("#{@config['whmcspass'][0]}")
			@query=Tblservers.find(:all, :conditions => "type='virtuozzo'", :select => "name,password,ipaddress")
			@server={}
			@query.each do |x|
        		# CHANGE this TO LOCAL PATH
        			c=Curl::Easy.http_post("http://localhost/whmcs/includes/api.php",Curl::PostField.content('username',"#{@config['whmcsuser'][0]}"),Curl::PostField.content('password',"#{@pass}"),Curl::PostField.content('action','decryptpassword'),Curl::PostField.content('password2',"#{x.password}"))
        			if c.response_code==200
                 		@server[x.name]=[x.ipaddress,c.body_str.split(';')[1].gsub(/password=/,"").chomp]
        			yield(x.name,@server[x.name])
				end
			end
		end
	end
end
end
