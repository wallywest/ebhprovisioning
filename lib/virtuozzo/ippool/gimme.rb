module Ebhpool
def self.bestcase
     @listids=@redis.zrange "ippool","0","-1"
     @cclass=@listids.last.sub(/:.*/,'')
     if (@redis.smembers "#{@cclass}").length >= @iprequestnum.to_i 
		@listids.map {|x| if !x.match(/#{@cclass}/) then @listids.delete("#{x}") end}
     end
     ipchoice do |ips|
	yield ips
     end
end
def self.ipchoice
                idlist=[]
		left=@ipcount
		ip={}
                @listids.reverse.each do |id|
			cclass=id.sub(/:.*/,'')
			ip["#{cclass}"] ||= []
			idlist << "#{id}"
			maxidips=@redis.llen "#{id}"
			if maxidips < @ipcount then left=maxidips end
			left.times do
                        	iptoadd=@redis.rpop "#{id}"
				p iptoadd
                        	ip["#{cclass}"] << iptoadd
                        	@redis.srem "#{cclass}", "#{iptoadd}"
				@ipcount-=1
                	end
                	@redis.zadd "ippool", "#{maxidips-left}", "#{id}"
			if (@redis.zscore "ippool","#{id}").to_i==0
			    @redis.zrem "ippool","#{id}"
			    @redis.del "#{id}"
	                    @redis.srem "#{cclass}:ids", "#{id}"
                	end
			if @ipcount==0 then break end
                end
		yield ip
end
def self.gimme(iprequestnum)
	@redis=Redis.new
	@ipcount=iprequestnum
	@ip={"mainip"=>"","remainingips"=>""}
        if @ipcount > (@redis.get "ipcount").to_i then raise "not enough ips for request" end
        bestcase do |ips|
                ips.each_pair do |key,value|
                        value.collect {|x| "#{key}.#{x}"}.each do |x|
                                if @ip["mainip"].empty?
                                        @ip["mainip"]="#{x}"
                                else
                                        @ip["remainingips"] << "#{x}\s"
                                end
                        end
                        @ip["remainingips"].strip!
                end
        end
	@redis.decrby "ipcount","#{iprequestnum}"	
	return @ip
end	
end
