require 'json'
module Virtuozzo
class Params
	attr_accessor :params
	def initialize(mode,&block)
		if mode=="sync" then return @params={"mode" => "sync"} end
		@addons={} 
		File.open("data.json") {|f| @params=JSON.parse(f.readline)}
		@params["mode"]="#{mode}"
		@constants={
		:SAMPLE_EID_PRO_PLESK => "ee141f42-b857-c947-80f4-8cfccac5ebe8",
                :SAMPLE_EID_PRO_CPANEL => "61590e3a-0736-9348-a082-b67ccd53da4e",
                :SAMPLE_EID_PRO_WEBMIN => "13a50f4b-e9d5-e544-a942-c1f0b652a90a",
                :SAMPLE_EID_BIZ_PLESK => "28e5a603-a595-df47-a134-e3f866f62bb4",
                :SAMPLE_EID_BIZ_CPANEL => "ee5f2a7f-ad6d-f843-b1d2-d29d3c47380b",
                :SAMPLE_EID_BIZ_WEBMIN => "7bbd5e11-80c0-9c4d-8673-92917d660182",
		:MEMUP_BIZ => "536870912",
		:MEMUP_PRO => "1073741824",
		:IPS_PRO => "3",
		:IPS_BIZ => "2"
		}
		instance_eval(&block)
		self.send(mode)
	end
	def save_replace(k)
		if k.downcase.match('cpanel|plesk') then @addons['panel']=k.upcase else @addons['panel']='WEBMIN' end
        end
	
	def buildparam
		@params.each_pair do |key,value|
                        if value.class==String and (value.empty? or key.match('customfields|type|producttype|moduletype')) then @params.delete(key) end
                        if value.class==Hash
                                value.each_pair do |k,v|
                         	 	if v.empty? or k.match('Backup|Gateway|groupid|status|lastlogin|security|credit|lastlogin|billingcid|currency|password') then @params["#{key}"].delete(k) end
					if k.match("Choose control panel") then self.save_replace(k) end
				end
			@addons.merge!(value)
			@params.delete(key)
			end 
                end
	add(:none) {@addons}
	end
	
	def add(key,*options,&block)
		#if block.call.nil? theni
		#	p key
		#	p block.call
		#	raise "VDSID IS NOT ON THAT NODE" 
		#end
		if block.call.class==String then @params[key.to_s]=block.call
		elsif block.call.class==Hash then @params.merge!(block.call)
		else @params.merge!(block.call.attributes)
		end	
	end
	
	def create
		add("VE id") {Vdspool.next_veid.to_s}
		add("sampleid") { @constants["SAMPLE_EID_#{@params["package"]}_#{@params["panel"]}".to_sym] }
		add("memup") { @constants["MEMUP_#{@params["package"]}".to_sym] }
		@iphash=Virtuozzo::IPool::takeips(@constants["IPS_#{@params["package"]}".to_sym],@params["Extra IP (in addition to included ones)"])
		add("none") { @iphash }
		
	end
	
	def license
		#if @params["panel"]=~/100/ then @params["plesk_license"]="100_DOMAINS_FOR_VZ" else @params["plesk_license"]="10_DOMAINS_FOR_VZ" end
		@license_type=@params["panel"].match(/[0-9]{2,3}/).to_s
		add("plesk_license") {"#{@license_type}_DOMAINS_FOR_VZ"}
	end
	
	def method_missing(method,&block)
		#self.add(:none) { Vdspool.get_veid("#{@params["VE id"]}","#{@params["node"]}") }
		add("none") {Vdspool.get_veid("#{@params["VE id"]}","#{@params["node"]}")}
	end
end
end
