module Virtuozzo
module IP
module Generator
	       def self.splitips(ipgroup,cclasstouse)
		        puts "SPLITTING IPS"
			b=@avail[cclasstouse].last
		        @q=Iprange.joins(:ippool).where("ipranges.cblock='#{cclasstouse}' AND ippool.ip_group='#{b}'").select("ippool.id,ipranges.id AS cid,ippool.ips").first
			@ips=@q.ips.split("\s")
		        Ippool.create(:iprange_id => "#{@q.cid}", :ips => "#{@ips[0,ipgroup].join(",")}",:ip_group => "#{ipgroup}", :exist => '0')
		        Ippool.create(:iprange_id => "#{@q.cid}", :ips => "#{@ips[ipgroup,b-ipgroup].join(",")}",:ip_group => "#{b-ipgroup}", :exist => '0')
		        Ippool.delete(@q.id)
		end
		def self.buildips(ips_left,*inputcclass)
			$max ||= 0
			$ipsused ||= {}
			@left=ips_left
			@inputcclass=inputcclass
			
			p "RUNNING CHECK"
			#CHECK FOR EMPTY IPPOOL
			check
			if !inputcclass[0].nil? and Iprange.joins(:ippool).where("ipranges.cblock='#{inputcclass[0]}' and ip_group != 0").first.nil? then inputcclass[0]=nil end
			p "RUNNING GAVAIL"
			#CHOOSE BEST CCLASS TO USE
			bestcandidate
			
			## CHECK FOR CASES WHEN WE NEED TO BREAK UP IP GROUPS
			if @avail[@cclasstouse].include?(@left)
                       		 @group=@left
       			else
				if @left < @avail[@cclasstouse].last
                                	splitips(@left,@cclasstouse)
                                	@group=@left
                        	else
                                	@group=@avail[@cclasstouse].last
                        	end
       			 end
			 ## IF REQUESTED VALUE IS GREATHER THEN MAX VALUE THEN TRY TO FIND CONSECUTIVE IPS
       			 #@q=Ippool.find_by_ip_group_and_cclass("#{@group}","#{@cclasstouse}")
			 puts "GRUOP IS #{@group}"
       			 @q=Iprange.joins(:ippool).where("ipranges.cblock='#{@cclasstouse}' AND ippool.ip_group='#{@group}'").select("ippool.id,ipranges.cblock,ipranges.id AS cid,ippool.ips,ippool.ip_group").first
			 if @q.nil? 
				#@q=Ippool.find_by_ip_group("#{@group}") 
			 	@q=Iprange.joins(:ippool).where("ippool.ip_group=#{@group}").select("ippool.id,ipranges.cblock,ipranges.id AS cid,ippool.ips,ippool.ip_group").first
			 end
			 @ipremaining=@left-@group
			 $ipsused[@q.cblock] ||= []
			 
			 @q.ips.split(/\s/).each {|x| $ipsused[@q.cblock] << x}
			 
			 puts "ips remaining #{@ipremaining}"
                         Ippool.update(@q.id, :ip_group => '0')
		  	 if @ipremaining <= 0
				puts "IPS USED"
			 	p $ipsused
				resultparser 
				return @ips
			 end
			 buildips(@ipremaining,@q.cblock)
		end
		def self.check
			puts "CHECK IF WE HAVE IPS"
          		@totalips=0
			1.upto(3) do |x|
        			count=Ippool.where("ip_group=#{x}").count * x
			        @totalips=count+@totalips
			end
			if @totalips < @left.to_i
                		puts "not enough ips for this action, only #{@totalips} ip left"
                		exit
			end
			puts "total ips are #{@totalips}"
		end
		def self.bestcandidate
                                @avail={}
                                @iplist=Iprange.joins(:ippool).where("ippool.ip_group != '0'").select("DISTINCT(ipranges.cblock),ippool.ip_group")
                                @iplist.each do |x|
					@avail[x.cblock] ||= []
                                        @avail[x.cblock] << x.ip_group.to_i
                                        @avail[x.cblock].sort!
                                        if @inputcclass[0].nil?
                                                if @avail[x.cblock].size >= $max
                                                        @cclasstouse=x.cblock
							puts "using cblock #{@cclasstouse}"
                                                        $max=@avail[x.cblock].size
                                                end
                                        end
                                end
		end
		def self.resultparser(&block)
			firstset=false
                        @remainingips=""
			$ipsused.each_pair do |key,value|
				unless firstset 
					@firstip="#{key}.#{value.first}"
					value.delete_at(0)
					firstset=true
				end
				@remainingips=value[0..value.length-1].collect {|x| "#{key}." + x }.join("\s")
			end
			@ips={"mainip" => "#{@firstip}","remainingips" => "#{@remainingips}"}
			Ippool.where("ip_group = '0'").delete_all
		end
		
		attr_reader :ips
end
end
end
