module Ebhpool
module Build
	def self.pool(iplist)
		@cclass={}
		iplist.split(' ').each do |x|
                        ip=IPAddress "#{x.chomp}"
                        unless ip[2].to_s.match('115|116|112|113|118|119') then @range="#{ip[0]}.#{ip[1]}.#{ip[2]}" end
                        if @cclass[@range].nil?
                                @cclass[@range] =[]
                                4.upto 250 do |x|
                                         @cclass[@range] << x
                                end
                        end
                        @cclass[@range].delete("#{ip[3]}".to_i)
                end
		yield @cclass
	end
end
end
