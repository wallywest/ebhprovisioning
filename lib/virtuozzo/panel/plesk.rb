require 'curb'
class Plesk
	def self.run (*opts)
		@params=opts[0][:params]
		self.send(opts[0][:mode])
	end
	def self.sendsetup(pass)
		 @c=Curl::Easy.new		 
		 @c.url="https://#{@params["mainip"]}:8443/enterprise/control/agent.php"
                 @c.headers={'HTTP_AUTH_LOGIN' => 'admin','HTTP_AUTH_PASSWD' => "#{pass}",'HTTP_PRETTY_PRINT' => 'true', 'Content-Type' => 'text/xml'}
                 @c.enable_cookies=true
                 @c.ssl_verify_host=false
                 @c.ssl_verify_peer=false
                 @c.http_post("#{@post_packet}")
                 if @c.body_str.include? "<errcode>1002</errcode>"
                        Virtuozzo::Log::write("#{@c.body_str}")
                        sleep 2
                        sendsetup('setup')
                 elsif @c.body_str.include? "error"
                        Virtuozzo::Log::write("#{@c.body_str}")
                 end
	end
	def self.setup
		@post_packet=%Q[
                        <packet version="1.4.2.0">
                        <server>
                        <initial_setup>
                           <admin>
                                <admin_cname>#{@params["companyname"]}</admin_cname>
                                <admin_pname>#{@params["firstname"]} #{@params["lastname"]}</admin_pname>
                                <admin_phone>#{@params["phonenumber"].gsub(/\s/,'')}</admin_phone>
                                <admin_fax></admin_fax>
                                <admin_email>#{@params["email"]}</admin_email>
                                <admin_address>#{@params["address1"]}</admin_address>
                                <admin_city>#{@params["city"]}</admin_city>
                                <admin_state>#{@params["state"]}</admin_state>
                                <admin_pcode>#{@params["postcode"].gsub(/\s/,'')}</admin_pcode>
                                <admin_country>#{@params["country"]}</admin_country>
                                <send_announce>true</send_announce>
                           </admin>
                           <password>#{@params["password"]}</password>
                           <server_name>#{@params["domain"]}</server_name>
                        </initial_setup>
                        </server>
                        </packet>
                 ]
		sendsetup('setup')
	end
	def self.license
		@AuthInfo=Struct.new("AuthInfo", :login, :password)
                @ServerAddress=Struct.new("ServerAddress", :ips,:macs)
                #@CreationParameters=Struct.new("CreationParameters",:hwid)
                @server=XMLRPC::Client.new2('https://ka.parallels.com:7050/',nil,900)
		@result=@server.call("partner10.createKey",
                                @AuthInfo.new("eboundhost","fMg9xSe2Rc7jtyXWmtP00U74z2SlIe16"),
                                @ServerAddress.new([],[]),
                                'eboundhost.com',
                                'PLESK_95_FOR_VZ',
                                ["#{@params["plesk_license"]}"]) #set variable here
	        @call=@server.call("partner10.retrieveKey",
                                @AuthInfo.new("eboundhost","fMg9xSe2Rc7jtyXWmtP00U74z2SlIe16"),
                                "#{@result['mainKeyNumber']}"
                	       )
		@license=Base64.encode64(@call['key'])
		@post_packet=%Q[
                        <packet version="1.4.2.0">
                        <server>
                        <lic_install>
                        <license>#{@license}</license>
                        </lic_install>
                        </server>
                        </packet>
                ]        
		sendsetup("#{@params['password']}")
                Virtuozzo.setvalue("plesk_key","#{@result["mainKeyNumber"]}")
        end
end
