class RevSetup
	class << self
		def run(ip,hostname,revpass)
		@hostname=hostname
		@exist=false
		@ip=IPAddr.new ip
		@reventry=@ip.reverse.sub(/[0-9]+\./,'')
                @dip=@ip.reverse.sub(/\..*/,'')
		Virtuozzo::Log::write("setting rdns at #{@reventry} with #{@dip} and hostname #{@hostname}")
		Net::SSH::start('rev1.eboundhost.com','root',:password => "#{revpass}",:paranoid => false) do |ssh|
                Virtuozzo::Log::write(ssh.logger)
		ssh.exec!("cat /root/rev/#@reventry") do |ch,stream,data|
			data.each_line do |x|
				if x.include?('IN PTR')
					curvalue=x.gsub(/\s/,'').sub(/IN.*/,'')
					if curvalue==@dip
						@exist=true
						ch.do_eof
					else
						if curvalue.to_i > @dip.to_i 
							if @cursave.nil? then @cursave=curvalue.to_i end
					      	end
                                	end
				end
                        end
                        ch.on_eof do |ch|
				if @cursave.nil? and !@exist
					ssh.exec("echo \"#{@dip} IN PTR #{@hostname}.\" >> /root/rev/#{@reventry}")
				else
                                @exist ? ssh.exec("sed -i s/\"#{@dip}\".*/\"#{@dip} IN PTR #{@hostname}.\"/ /root/rev/#@reventry") : ssh.exec("sed -i '/#{@cursave} IN PTR/ i\ #{@dip} IN PTR #{@hostname}.' /root/rev/#@reventry")
                                ch.wait
				end
				
				ch.do_close
                        end
                               ch.on_close do |ch|
                                ssh.open_channel do |ch2|
                                        ch2.exec("/etc/init.d/named reload")
                                end
                                end
                        end
                end
		end
	end
end
