module Virtuozzo
class Socket
	class << self
		include Virtuozzo
		def setup
			@params=Virtuozzo.getparams
			@nodeip=@params["serverip"]
			@packet=Virtuozzo::PacketGenerator::new
			ctx=OpenSSL::SSL::SSLContext.new(:TLSv1)
			ctx.ciphers= [['ADH-AES256-SHA','TLSv1','256','256']]
			ctx.setup
			sock=TCPSocket.new(@nodeip,4434)
			@socket=OpenSSL::SSL::SSLSocket.new(sock,ctx)
			@socket.sync=true
			@socket.connect
			run
		end
		def run
			@packet.packet_list.each do |p|
				if p=='end'
				send(p.to_s)
				Virtuozzo::Log::write("module finished")
				return 'success'
				else
					response
					#puts "sending packet #{p}"
					Virtuozzo::Log::write("sending packet #{p}")
					sendpacket(@packet.send(p.to_s))
				end
			end
		end
		def response
			while str=@socket.gets
				if str=~/<ns1:message>/
					Virtuozzo::Log::error("#{str}")
					raise str
				end	
				if str.chomp=='</packet>'
					return
				end
				if str.chomp=~/<ns4:eid>/
					@eid=str.sub(/<\/.*>/,'').sub(/<.*>/,'').chomp
                                	p @eid
					@packet.actions @eid
				end
			end
		end

		def sendpacket(p)
			@socket.write("\0")
			@socket.write(p)
			@socket.write("\0")
		end
		def end
			@socket.close
			Virtuozzo::Log::write('postsetup is running')
			PostSetup::run
			return 'success'
		end
	end
end
end
