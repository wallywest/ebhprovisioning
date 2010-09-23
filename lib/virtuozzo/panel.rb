module Virtuozzo
class PanelSetup
include Virtuozzo
	class << self 
		def run
			Virtuozzo::Log::write('setting panel')
			@params=Virtuozzo.getparams
			@port=22
			tcp=Net::Ping::TCP.new("#{@params["mainip"]}","#{@port}")
			5.times do |x|
				if tcp.ping then break end
				if x==5 then raise "container not resolvable" end
			end
			self.send(@params["panel"].downcase.to_s)
                        return 'success'
		end
		def cpanel
			Net::SSH.start("#{@params["mainip"]}", 'root', :password =>"#{@params["password"]}", :paranoid => false) do |ssh|
                                ssh.sftp.connect do |sftp|
                                        sftp.upload!("#{File.dirname(__FILE__)}/scripts/cpanelinstall",'/root/cpanelinstall')
                                end
                                ssh.exec("sh cpanelinstall >/dev/null 2>&1 &")
                        end
		end
		
		def plesk
			return 'success'	
		end
		
		def webmin
			return 'success'
		end
		
	end
end
end
