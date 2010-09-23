module Virtuozzo
class PacketGenerator
	include Virtuozzo
	attr_reader :login,:start,:create,:destroy,:stop,:suspend,:userpass,:unsuspend,:list,:info,:disable,:undisable,:description,:setmem,:mem
	def initialize(*opts)
		@nodepass=opts[0]
		@params=Virtuozzo::getparams
		unless @params["mode"]=='sync' 
			puts "setting up params"
 			Virtuozzo::Log::write("#{@params}")
               
			@hostname=@params["domain"] ||=nil
        	        @os=".centos-5-x86"
        	        @password=@params["password"] ||=nil
        	        @veid=@params["VE id"] ||=nil
        	        @sampleid=@params["sampleid"] ||=nil
        	        @mainip=@params["mainip"] ||=nil
        	        @assignedip=@params["remainingips"] ||=nil
               		@name="#{@params['firstname']}"+" #{@params['lastname']}"
               		@smem=@params[:memup] ||=nil
			@nodepass=@params["serverpassword"].chomp ||=nil
			case @params["mode"]
				when 'create'
					setupcreate
				else
					actions @params["eid"]	
			end 
		end
		@login=%!
                        <packet version="4.0.0" id="3"> 
                        <data>
                        <system>
                        <login>
                        <name>cm9vdA==</name>
                        <realm>00000000-0000-0000-0000-000000000000</realm>
                        <password>#{Base64.encode64(@nodepass).chomp}</password>
                        </login>
                        </system>
                        </data>
                        </packet>
                !
                @list=%!
                        <packet version="4.0.0" id="4">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <get_list/>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
	end
	def packet_list
		case @params["mode"]
			when 'create'	
				@socket_list=['login','create','start','userpass','description','end']
		                if @params["Double my RAM!"].to_i==1 then @socket_list.insert(4,'mem') end
			when 'destroy' 
				@socket_list=['login','stop','destroy','end']
			when 'suspend' 
				@socket_list=['login','stop','disable','end']
			#when 'sync'
			#	@socket_list=['list','login']
			else  
				@socket_list=['login','undisable','start','end']
		end
		@socket_list
	end
	def setupcreate
		@create=%!
			<packet version="4.0.0" id="2">
			<target>vzaenvm</target>
			<data>
			<vzaenvm>
			<create>
			<config>
        		<name>vps#{@veid}</name>
        		<hostname>#{@hostname}</hostname>
        		<base_sample_id>#{@sampleid}</base_sample_id>
        		<veid>#{@veid}</veid>
        		<on_boot>true</on_boot>
       			<offline_management>true</offline_management>
        		<os_template>
                	<name>#{@os}</name>
        		</os_template>
        		<net_device>
               		<id>venet0</id>
                	<ip_address>
                        <ip>#{@mainip}</ip>
                	</ip_address>!
			@assignedip.split(/\r\n/).each do |value|
				@t=%!
			<ip_address>
			<ip>#{value}</ip>
               		</ip_address>!
			@create=@create+@t
			end
			@end=%!
			<host_routed/>
        		</net_device>
			</config>
			</create>
			</vzaenvm>
			</data>
			</packet>
			!
			@create=@create+@end

	end
	def info=(value)
 	            @info=%!
                        <packet version="4.0.0" id="2">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <get_info>
                        <eid>#{value}</eid>
                        <config/>
                        </get_info>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
	end
	def actions(eid)
		if @params['eid'].nil? then Virtuozzo::setvalue("eid",eid) end
		@eid=eid
		@start=%!
               		<packet version="4.0.0" id="2">
                	<target>vzaenvm</target>
                	<data>
                	<vzaenvm>
                	<start>
               		<eid>#{@eid}</eid>
                	</start>
                	</vzaenvm>
                	</data>
                	</packet>
                	!
		@destroy=%!
			<packet version="4.0.0" id="2">
  			<target>vzaenvm</target>
		 	<data>
    			<vzaenvm>
      			<destroy>
        		<eid>#{@eid}</eid>
      			</destroy>
    			</vzaenvm>
  			</data>
			</packet>
			!
		@stop=%!
			<packet version="4.0.0" id="2">
  			<target>vzaenvm</target>
 			<data>
    			<vzaenvm>
      			<stop>
        		<eid>#{@eid}</eid>
      			</stop>
    			</vzaenvm>
  			</data>
			</packet>
			!

		@suspend=%!
			<packet version="4.0.0" id="2">
  			<target>vzaenvm</target>
 			<data>
    			<vzaenvm>
      			<suspend>
        		<eid>#{@eid}</eid>
      			</suspend>
    			</vzaenvm>
  			</data>
			</packet>
			!
		@unsuspend=%!
                        <packet version="4.0.0" id="2">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <resume>
                        <eid>#{@eid}</eid>
                        </resume>
                        </vzaenvm>
                        </data>
                        </packet>
                        !

		@userpass=%!
			<packet version="4.0.0" id="2">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <set_user_password>
                        <eid>#{@eid}</eid>
                        <name>root</name>
                        <password>#{Base64.encode64(@password).chomp}</password>
                        </set_user_password>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
		@info=%!
			<packet version="4.0.0" id="2">
			<target>vzaenvm</target>
  			<data>
    			<vzaenvm>
      			<get_info>
        		<eid>#{@eid}</eid>
        		<config/>
      			</get_info>
    			</vzaenvm>
  			</data>
			</packet>
			!
		@disable=%!
			<packet version="4.0.0">
  			<target>vzaenvm</target>
  			<data>
    			<vzaenvm>
      			<set>
        		<eid>#{@eid}</eid>
        		<config>
          		<disabled>yes</disabled>
        		</config>
      			</set>
    			</vzaenvm>
  			</data>
			</packet>
			!
		@undisable=%!
                        <packet version="4.0.0">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <set>
                        <eid>#{@eid}</eid>
                        <config>
                        <disabled></disabled>
                        </config>
                        </set>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
		@description=%!
                        <packet version="4.0.0">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <set>
                        <eid>#{@eid}</eid>
                        <config>
                        <description>#{Base64.encode64(@name).chomp}</description>
                        </config>
                        </set>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
		@mem=%!
                        <packet version="4.0.0">
                        <target>vzaenvm</target>
                        <data>
                        <vzaenvm>
                        <set>
                        <eid>#{@eid}</eid>
                        <config>
			<qos>
			<id>slmmemorylimit</id>
			<soft>#{@smem}</soft>
			<hard>#{@smem}</hard>
			</qos>
			</config>
                        </set>
                        </vzaenvm>
                        </data>
                        </packet>
                        !
	end
end
end
