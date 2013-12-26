require 'csv'
require_relative 'dns'

csv = CSV($stdin, {:headers => true, :header_converters => :symbol, row_sep: "\r\n"})
csv.each do |row|
  puts DNS::TXT.new(row).dump(:nquads)
  puts
end
