module Virtuozzo
module IP
module Generator
	       def self.split(ipgroup,cclasstouse)
		        b=@avail[cclasstouse].last
	        	@q=Ippool.find_by_ip_group_and_cclass("#{b}","#{cclasstouse}")
		        @ips=@q.ips.split(",")
		        Ippool.create(:cclass => "#{@q.cclass}", :ips => "#{@ips[0,ipgroup].join(",")}",:ip_group => "#{ipgroup}", :exist => '0')
		        Ippool.create(:cclass => "#{@q.cclass}", :ips => "#{@ips[ipgroup,b-ipgroup].join(",")}",:ip_group => "#{b-ipgroup}", :exist => '0')
		        Ippool.delete(@q.id)
		end
		def self.buildips(ips_left,*inputcclass)
			@left=ips_left
			@inputcclass=inputcclass
			p "RUNNING CHECK"
			check()
			if !inputcclass[0].nil? and Ippool.find(:first,:conditions => "cclass='#{inputcclass[0]}' and ip_group != '0'").nil? then inputcclass[0]=nil end
			p "RUNNING GAVAIL"
			gavail()
			
			if @avail[@cclasstouse].include?(@left)
                       		 @group=@left
       			else
				if @left < @avail[@cclasstouse].last
                                	split(@left,@cclasstouse)
                                	@group=@left
                        	else
                                	@group=@avail[@cclasstouse].last
                        	end
       			 end
       			 @q=Ippool.find_by_ip_group_and_cclass("#{@group}","#{@cclasstouse}")
       			 if @q.nil? then @q=Ippool.find_by_ip_group("#{@group}") end
			 
			 @ipremaining=@left-@group
			 $ipsused[@q.cclass] ||= []
			 
			 @q.ips.split(/,/).each do |x|
                		p @q.ip_group
				$ipsused[@q.cclass] << x.to_i
				$ipsused[@q.cclass].sort!
        		 end
			 
			 puts "ips remaining #{@ipremaining}"
			 p $ipsused
			 if @ipremaining <= 0 then return end
			 buildips(@ipremaining,@q.cclass)
		end
		def self.check
		        @fin=Ippool.find(:all,:conditions=>"ip_group != 0")
		        if @fin.empty?
                		puts "no more ips"
               	      		exit
       		        else
           		count=0
          			@fin.each do |x|
                		count=x.ip_group+count
         			end
          			if count < @left
                			puts "not enough ips for this action, only #{x.ip_group} ip left"
                			exit
           			end
        		end
		end
		def self.gavail
			@avail={}
			@cclass=Ippool.find(:all, :select => "DISTINCT(cclass)", :conditions => "ip_group != 0")
			        @cclass.each do |x|
                			@thr=Ippool.find_all_by_ip_group_and_cclass('3',"#{x.cclass}")
               				@two=Ippool.find_all_by_ip_group_and_cclass('2',"#{x.cclass}")
               				@one=Ippool.find_all_by_ip_group_and_cclass('1',"#{x.cclass}")
					a=1
                			#Eliminate that group which are not
                			[@one,@two,@thr].each do |y|
                        			if !y.empty?
                              				@avail[x.cclass] ||= []
                                			@avail[x.cclass] << a
                        			end
                			a+=1
                			end
               				if @inputcclass[0].nil?
                        			if @avail[x.cclass].size >= $max
                                		@cclasstouse=x.cclass
                                		$max=@avail[x.cclass].size
                       				end
                			end
        			end

		end
		def self.resultparser
			$ipsused.each_pair do |key,value|
				value.each_index do |x|
					if @firstip.nil?
						@firstip="216.14.#{key}.#{value[0]}"
						@remainingips=''
					end
					if x > 0
						@remainingips=@remainingips+"216.14.#{key}.#{value[x]}\n"
					end
				end
			end
		end
		attr_reader :firstip, :remainingips
end
end
end
