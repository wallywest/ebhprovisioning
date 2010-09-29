module Virtuozzo
	def self.setup(mode,config)
                @config=config
		Virtuozzo::Log::write("setting params")
		@spec=Virtuozzo::Params::new(mode,@config) do 
	                buildparam
			add("node") {Tblservers.where("id=#{@params["serverid"]}").select("name").first.name}
	                add("package") {Tblproducts.where("id=#{@params["packageid"]}").select("name").first.name.sub(/\-.*/,'').sub(/\s/,'').upcase}
			add("mainip")  {Tblhosting.where("id=#{@params["serviceid"]}").select("dedicatedip").first.dedicatedip}
			add("remainingips") {Tblhosting.where("id=#{@params["serviceid"]}").select("assignedips").first.assignedips}
		end
		self.send(mode)
	end
	def self.method_missing(method,*args,&block)
		Virtuozzo::Socket::setup
	end
	def self.license
		Virtuozzo::LicenseSetup::run	
	end
	def self.sync
		Virtuozzo::Sync::run(@config)
	end
	def self.getparams
		@spec.params
	end
	def self.getvalue(value)
		@spec.params[value.to_s]
	end
	def self.setvalue(key,value)
		@spec.params[key]=value
	end
end
