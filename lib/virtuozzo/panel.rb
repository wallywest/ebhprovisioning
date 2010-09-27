module Virtuozzo
class PanelSetup
include Virtuozzo
	class << self 
		def run
			Virtuozzo::Log::write('setting panel')
			@params=Virtuozzo.getparams
			@port=22
			tcp=Net::Ping::TCP.new("#{@params["mainip"]}","#{@port}")
			20_000.times do |x|
				if tcp.ping? then break end
				if x==20_000 then raise "container not resolvable" end
			end
			self.send(@params["panel"].downcase.to_s)
                        return 'success'
		end
		def cpanel
			Net::SSH.start("#{@params["mainip"]}", 'root', :password =>"#{@params["password"]}", :paranoid => false) do |ssh|
                                ssh.sftp.connect do |sftp|
                                        sftp.upload!("#{File.expand_path("virtuozzo/scripts")}/cpanelinstall","/root/cpanelinstall")
                                end
                                ssh.exec("sh cpanelinstall >/dev/null 2>&1 &")
                        end
		end
		
		def plesk
			Plesk::run(
			    :mode => "setup",
			    :params => @params
			)
		end
		
		def webmin
		end
		
	end
end
end
