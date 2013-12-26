require 'rdf'
require 'rdf/nquads'
require 'ipaddr'
require_relative 'ietf'

module DNS
  class DNS < RDF::Vocabulary
    def self.__prefix__
      :dns
    end
    def self.to_uri
      RDF::URI.new("http://purl.org/dns#")
    end
    def self.to_s
      to_uri.to_s
    end
    def self.Domain
      DNS["Domain"]
    end
    def self.FQDN
      DNS["FQDN"]
    end
    def self.A
      DNS["A"]
    end
    def self.AAAA
      DNS["AAAA"]
    end
    def self.CNAME
      DNS["CNAME"]
    end
    def self.DNAME
      DNS["DNAME"]
    end
    def self.Probe
      DNS["Probe"]    
    end
    def self.Nameserver
      DNS["Nameserver"]
    end
    def self.hasNameserver
      DNS["hasNameserver"]
    end
    def self.EmailExchange
      DNS["EmailExchange"]
    end
    def self.hasSOANameserver
      DNS["hasSOANameserver"]
    end
    def self.hasSOARName
      DNS["hasSOARName"]
    end
    def self.hasSOASerial
      DNS["hasSOASerial"]
    end
    def self.hasSOARefresh
      DNS["hasSOARefresh"]
    end
    def self.hasSOARetry
      DNS["hasSOARetry"]
    end
    def self.hasExchange
      DNS["hasExchange"]
    end
    def self.hasMXRecord
      DNS["hasMXRecord"]
    end
    def self.MXRecord
      DNS["MXRecord"]
    end
    def self.hasMXPreference
      DNS["hasMXPreference"]
    end
    def self.hasTXTRecord
      DNS["hasTXTRecord"]
    end
    def self.TXTRecord
      DNS["TXTRecord"]
    end
    def self.to_domain_uri(s)
      RDF::URI("uri:domain:" + s)
    end

  end
  
  class X
    def initialize(rec)
      @graph = RDF::Repository.new
      @name = DNS.to_domain_uri(rec[:name])
      d = DateTime.parse(rec[:isotime])
      @gid = make_gid(d)
    end
    
    def register_domain(uri, label)
      fact(uri, RDF.type, DNS.Domain)
      fact(uri, RDF::RDFS.label, label)
    end
    
    def register_fqdn(uri, label)
      fact(uri, RDF.type, DNS.FQDN)
      fact(uri, RDF::RDFS.label, label)
    end
    
    def register_probe_date(scandate)
      fact(@gid, RDF::DC11.created, RDF::Literal.new(scandate, :datatype => RDF::XSD.dateTime))
      fact(@gid, RDF.type, DNS.Probe)
    end
    
    def make_gid(d)
      @gid = RDF::URI("https://dnscensus2013.neocities.org/probe-" + URI.escape(d.iso8601) )
    end
    
    def fact(s, p, o)
      @graph << RDF::Statement.new(s, p, o)
    end
    
    def probe_fact(s, p, o)
      @graph << RDF::Statement.new(s, p, o, context: @gid)
    end
    
    def dump(type)
      @graph.dump(type)
    end
  end
  
  class A < X
    def initialize(rec)
      super(rec)
      target = IETF.to_ipv4_uri(rec[:ip4address])
      register_fqdn(@name, rec[:name])
      probe_fact(@name, DNS.A, target)
      fact(target, RDF.type, IETF.IPv4Address)
      fact(target, RDF::RDFS.label, rec[:ip4address])
      register_probe_date(rec[:isotime])
    end    
  end

  class AAAA < X
    def initialize(rec)
      super(rec)
      target = IETF.to_ipv6_uri(rec[:ip6address])
      register_fqdn(@name, rec[:name])
      probe_fact(@name, DNS.AAAA, target)
      fact(target, RDF.type, IETF.IPv6Address)
      fact(target, RDF::RDFS.label, rec[:ip6address])
      register_probe_date(rec[:isotime])
    end
  end

  # A CNAME record is an abbreviation for Canonical Name record and is a
  # type of resource record in the Domain Name System (DNS) used to
  # specify that a domain name uses the IP addresses of another domain,
  # the "canonical" domain.
  class CNAME < X
    def initialize(rec)
      super(rec)
      target = DNS.to_domain_uri(rec[:target])
      register_fqdn(@name, rec[:name])
      probe_fact(@name, DNS.CNAME, target)
      register_fqdn(target, rec[:target])
      register_probe_date(rec[:isotime])
    end    
  end

  # DNAME records don't necessarily take a FQDN or deliver a FQDN.
  # A DNAME record or Delegation Name record is defined by RFC 6672 
  # (original RFC 2672 is now obsolete). A DNAME record creates an 
  # alias for an entire subtree of the domain name tree. In contrast,
  #  the CNAME record creates an alias for a single name and not its
  #  subdomains. Like the CNAME record, the DNS lookup will continue
  #  by retrying the lookup with the new name.
  class DNAME < X
    def initialize(rec)
      super(rec)
      target = DNS.to_domain_uri(rec[:target])
      register_domain(@name, rec[:name])
      probe_fact(@name, DNS.DNAME, target)
      register_probe_date(rec[:isotime])
    end    
  end
  
  class MX < X
    def initialize(rec)
      super(rec)
      register_fqdn(@name, rec[:name])
      bnode = RDF::Node.new
      target = DNS.to_domain_uri(rec[:exchange])
      register_fqdn(target, rec[:exchange])
      fact(bnode, DNS.hasExchange, rec[:target])
      fact(bnode, DNS.hasMXPreference, RDF::Literal(rec[:preference]))
      fact(bnode, RDF.type, DNS.MXRecord)
      register_fqdn(target, rec[:exchange])
      fact(@name, RDF.type, DNS.EmailExchange)
      probe_fact(@name, DNS.hasMXRecord, bnode)
      register_probe_date(rec[:isotime])
    end  
  end

  class NS < X
    def initialize(rec)
      super(rec)
      register_domain(@name, rec[:name])
      t = DNS.to_domain_uri(rec[:nameserver])
      register_fqdn(t, rec[:nameserver])
      fact(t, RDF.type, DNS.Nameserver)
      probe_fact(@name, DNS.hasNameserver, t)
      register_probe_date(rec[:isotime])
    end
  end
  # name,     isotime,            mname,              rname,                  serial,     refresh,  retry,expire, minimum
  # 0--8.com, 2012-10-18T20:07:36,f1g1ns1.dnspod.net, freednsadmin.dnspod.com,1316028282, 3600,     180,  1209600,180
  class SOA < X
    def initialize(rec)
      #name,isotime,mname,rname,serial,refresh,retry,expire,minimum
      super(rec)
      register_domain(@name, rec[:name])
      probe_fact(@name, DNS.hasSOANameserver, DNS.to_domain_uri(rec[:mname]))
      register_domain(DNS.to_domain_uri(rec[:mname]), rec[:mname])
      probe_fact(@name, DNS.hasSOARName, DNS.to_domain_uri(rec[:rname]))
      register_domain(DNS.to_domain_uri(rec[:rname]), rec[:rname])
      probe_fact(@name, DNS.hasSOASerial, RDF::Literal(rec[:serial], :datatype => RDF::XSD.nonNegativeInteger))
      probe_fact(@name, DNS.hasSOARefresh, RDF::Literal(rec[:refresh], :datatype => RDF::XSD.nonNegativeInteger))
      probe_fact(@name, DNS.hasSOARetry, RDF::Literal(rec[:retry], :datatype => RDF::XSD.nonNegativeInteger))
      register_probe_date(rec[:isotime])
    end    
  end
  
  class TXT < X
    def initialize(rec)
      super(rec[:isotime], rec[:name])
      probe_fact(@name, DNS.hasTXTRecord, rec[:text])
      probe_fact(@name, RDF.type, DNS.TXTRecord)
      #key, value = rec[:text].split('=')
      puts rec[:text]
      if rec[:text]
        i = rec[:text].index(/[^`](=)/)
        if i
          puts i
          key = rec[:text][0..i]
          value = rec[:text][i+2..-1]
          puts key, value
          probe_fact(@name, DNS['hasTXTAttribute_'+URI.escape(key)], value)
        end
      end
      register_probe_date(rec[:isotime])
    end
  end
end
