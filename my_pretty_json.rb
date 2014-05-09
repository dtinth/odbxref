
def my_pretty_json(obj, ttl=nil, indent=0)

  return obj.to_json if ttl == 0

  nttl = ttl == nil ? nil : ttl - 1
  nl = "\n" + '  ' * [0, indent].max
  nnl = "\n" + '  ' * [0, 1 + indent].max

  case obj
  when Hash
    out = "{ "
    out << obj.sort.map { |k, v|
      "" << k.to_s.to_json << ": " << my_pretty_json(v, nttl, indent+1)
    }.join(",#{nnl}")
    out << "#{nl}}"
  when Array
    out = "[#{nnl}"
    out << obj.map { |v|
      "" << my_pretty_json(v, nttl, indent+1)
    }.join(", #{nnl}")
    out << "#{nl}]"
  else
    obj.to_json
  end

end
