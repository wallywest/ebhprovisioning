module Virtuozzo
class LicenseSetup
include Virtuozzo
	class << self 
		def run
			Virtuozzo::Log::write('setting panel')
			@params=Virtuozzo.getparams
			@veip=@params["mainip"]
			@panel=@params["panel"].downcase
			@vepass=@params["password"]
			@hostname=@params["domain"]
			@details=@params["clientsdetails"]
			case @panel
				when 'plesk' then @port=8443
				else @port=22
			end
			if !@port.nil?
				@p1=Net::Ping::TCP.new("#{@veip}","#{@port}")
				5.times do |x|
			  		if @p1.ping? 
						self.send(@panel.to_s)
						return 'success'
						#break
					end
				end
				raise 
			end
			#raise "IP IS NOT RESOLVABLE"
		end
		
		#CPANEL LICENSE SETUP
		def cpanel
		
		end
		
		def webmin

		end
	
		def plesk
			puts "sending plesk key info"
			exit
			@AuthInfo=Struct.new("AuthInfo", :login, :password)
                        @ServerAddress=Struct.new("ServerAddress", :ips,:macs)
                        #@CreationParameters=Struct.new("CreationParameters",:hwid)
			@server=XMLRPC::Client.new2('https://ka.parallels.com:7050/',nil,900)
			#self.keycreate
			self.sendreq
	
		end
		
		def keycreate
			@result=@server.call("partner10.createKey",
				@AuthInfo.new("eboundhost","fMg9xSe2Rc7jtyXWmtP00U74z2SlIe16"),
				@ServerAddress.new([],[]),
				'eboundhost.com',
				'PLESK_95_FOR_VZ',
				["#{@params["license_type"]}"]) #set variable here
			@call=@server.call("partner10.retrieveKey",
				@AuthInfo.new("eboundhost","fMg9xSe2Rc7jtyXWmtP00U74z2SlIe16"),
				"#{@result['mainKeyNumber']}"
				)
			@license=Base64.encode64(@call['key'])
		end
		
		def sendreq
			@initial_setup=%Q[
			<packet version="1.4.2.0">
			<server>
			<initial_setup>
			   <admin>
      				<admin_cname>#{@details["companyname"]}</admin_cname>
      				<admin_pname>#{@details["firstname"]} #{@details["lastname"]}</admin_pname>
      				<admin_phone>#{@details["phonenumber"].gsub(/\s/,'')}</admin_phone>
      				<admin_fax></admin_fax>
      				<admin_email>#{@details["email"]}</admin_email>
      				<admin_address>#{@details["address1"]}</admin_address>
      				<admin_city>#{@details["city"]}</admin_city>
      				<admin_state>#{@details["state"]}</admin_state>
      				<admin_pcode>#{@details["postcode"].gsub(/\s/,'')}</admin_pcode>
      				<admin_country>#{@details["country"]}</admin_country>
      				<send_announce>true</send_announce>
   			   </admin>
   			   <password>#{@vepass}</password>
   			   <server_name>#{@hostname}</server_name>
			</initial_setup>
			</server>
			</packet>
			]
			Virtuozzo::Log::write("#{@initial_setup}")
			@lic_install=%Q[
			<packet version="1.4.2.0">
			<server>
			<lic_install>
			<license>#{@license}</license>
			</lic_install>
			</server>
			</packet>
			]
			c=Curl::Easy.new()
			sendsetup(c)
			sendlicense(c)
			Tblcustomfieldsvalues.update_all("value='#{@result["mainKeyNumber"]}'",{:relid=>"#{@params["serviceid"]}",:fieldid => [11,13]})
		end	
		def sendsetup(c)
                        c.url="https://#{@veip}:8443/enterprise/control/agent.php"
                        c.headers={'HTTP_AUTH_LOGIN' => 'admin','HTTP_AUTH_PASSWD' => 'setup','HTTP_PRETTY_PRINT' => 'true', 'Content-Type' => 'text/xml'}
                        c.enable_cookies=true
                        c.ssl_verify_host=false
                        c.ssl_verify_peer=false
                        c.http_post("#{@initial_setup}")
			if c.body_str.include? "<errcode>1002</errcode>"
                                Virtuozzo::Log::write("#{c.body_str}")
                                sleep 2
				sendsetup(c)
			elsif c.body_str.include? "error"
				Virtuozzo::Log::write("#{c.body_str}")
			end
		end
		def sendlicense(c)
			c.headers={'HTTP_AUTH_LOGIN' => 'admin','HTTP_PRETTY_PRINT' => 'true', 'Content-Type' => 'text/xml','HTTP_AUTH_PASSWD' => "#{@vepass}"}
                        c.http_post("#{@lic_install}")
		end
	end
end
end
