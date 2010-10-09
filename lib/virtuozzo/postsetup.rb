class PostSetup
	class << self
		include Virtuozzo
		def run
			@params=Virtuozzo.getparams
			self.send(@params["mode"].to_s)
		end
		def create
			PanelSetup::run
			#renable rev setup
			RevSetup::run(
				@params["mainip"],
				@params['domain'],
				@params['revpass']
			)
			self.write 
		end
		def suspend
			
		end
		
		def unsuspend
	
		end
		
		def destroy
			Vdspool.destroy(@params["id"])
			Tblhosting.updateips(@params["accountid"],"","")
		end
		
		def write
			Vdspool.create(:vdsid => "#{@params["node"]}", :veid => "#{@params["VE id"]}", :eid =>"#{@params["eid"]}",:ips => "#{@params["mainip"]}\s#{@params["remainingips"]}")
			#Tblcustomfieldsvalues.update_all("value=#{@params["veid"]}",{:relid=>"#{@params["serviceid"]}",:fieldid => "#{@params["packageid"]}"})
			if @params["ippool"] then Tblhosting.updateips(@params['accountid'],@params['mainip'],@params['remainingips']) end
		end
	end
end
