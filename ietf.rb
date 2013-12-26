require 'rdf'
require 'ipaddr'

class IETF < RDF::Vocabulary
  def self.__prefix__
    :ietf
  end
    
  def self.to_uri
    RDF::URI.new("http://purl.org/ietf#")
  end
    
  def self.to_s
    to_uri.to_s
  end
    
  def self.IPv4Address
    IETF["IPv4Address"]
  end
  
  def self.IPv6Address
    IETF["IPv6Address"]
  end
  
  def self.to_ipv4_uri(s)
    RDF::URI("uri:ipv4:" + s)
  end

  def self.to_ipv6_uri(s)
    RDF::URI("uri:ipv6:" + IPAddr.new(s).to_string())
  end
end

