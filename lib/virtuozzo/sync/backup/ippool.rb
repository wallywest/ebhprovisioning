module Virtuozzo
class IPool
	attr_accessor :cclass
	def initialize()
		@cclass={}
	end
	def self.takeips(packageip,extra)
		@totalips=extra.to_i+packageip.to_i
		Virtuozzo::Log::write("retreiving #{@totalips} from ippool")
		puts @totalips
		puts "running ipgenerator"
		Virtuozzo::IP::Generator::buildips @totalips
	end
	def self.giveips(ips)
		@pool=Virtuozzo::IPool::new
		@insert={}
		ips.split("\s").each do |x|
			ip=IPAddress "#{x}"
			@range="#{ip[0]}.#{ip[1]}.#{ip[2]}"
			@insert[@range] ||= []
			@insert[@range] << ip[3]
		end
		Virtuozzo::Log::write("giving back #{@cclass} to ippool")
		@pool.cclass=@insert
		@pool.buildpool
	end
	def sort(ips)
		ips.split(' ').each do |x|
			ip=IPAddress "#{x.chomp}"
			unless ip[2].to_s.match('115|116|112|113|118|119') then @range="#{ip[0]}.#{ip[1]}.#{ip[2]}" end
			if @cclass[@range].nil?
				if Iprange.where(:cblock => "#{@range}").empty? then Iprange.create(:cblock => "#{@range}") end
				@cclass[@range] =[]
				4.upto 250 do |x|
					 @cclass[@range] << x 
				end
			end
			@cclass[@range].delete("#{ip[3]}".to_i) 
		end
	end
	def getips
		@cclass
	end
	def buildpool(*serverips)
	# add something for exclude config file
	unless serverips.empty?
		serverips[0].each do |x|
			ip=IPAddress "#{x.chomp}"
			@cclass["#{ip[0]}.#{ip[1]}.#{ip[2]}"].delete("#{ip[3]}".to_i)
		end 
	end
	 @cclass.each_pair do |key,value|
		@g=[]
		 # setup blocks for cclass key
		   value.each do |dclass|
			#puts "next value is #{dclass}"
			@g << dclass
			unless @g.length==1
				#puts "differnce is #{dclass}-#{@g[-2]}"
				if dclass-@g[-2] !=1
					#puts "length is #{@g.length}" 
		                        #puts "analyzing #{@g}"
					case @g.length
						when 2 then 
							#"type #{@g.length} storing #{@g.reverse.pop}"
							# puts "value to save is #{@g.reverse.pop}"
							@save=@g.reverse!.pop 
							store(1,key,@save)
							 #p @g
						#when 3 then 
							 #puts "type #{@g.length} storing #{@g.inspect}"
						#	 @save=@g.pop
						#	 puts "saving #{@g}"
						#	 store(2,key,@g)
						#	 @g = [] 
						#	 @g << @save
							
					end
					puts "leftover is #{@g}"
					#@g << dclass
				#elsif dclass-@g[-2] and @g.length==3
			     	#	puts "storing #{@g.inspect}"
				#	store(3,key,@g)
			        #	@g=[]
				#end
				elsif dclass-@g[-1] and @g.length==2
					puts "storing #{@g.inspect}"
					store(2,key,@g)
					@g=[]
				end
	     	   	end
		   end
		  #puts "storing last value #{@g}"
		  unless @g.empty? then store(@g.length,key,@g) end
		  #puts "excited free ip array"
	    end
	end
	def store(type,c,d)
		@ips=""
		@cid=Iprange.where(:cblock => "#{c}").first
		if d.class==Fixnum
			@ips=d.to_s
		else
		        d.each {|x| @ips << x.to_s+"\s"} 
		end
		@ips.sub!(/\s*$/,'')
		@p=Ippool.find_or_create_by_iprange_id_and_ips(:iprange_id => "#{@cid.id}", :ips => "#{@ips}", :ip_group => "#{type}" , :exist => "1")
		Ippool.update(@p.id,:exist => '1')
	end

	def delete
		Ippool.where(:exist => "0").delete_all
		Ippool.update_all(:exist => "0")
	end
end
end
