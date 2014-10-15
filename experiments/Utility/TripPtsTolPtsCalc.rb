ARGV.each do|a|
  a = a.to_f
  tripMin = 0.9*a
  tripMax = 1.1*a
  tolMin = 0.95*a
  tolMax = 1.05*a
  puts "#{a},#{tripMin},#{tripMax},#{tolMin},#{tolMax}"
end 
