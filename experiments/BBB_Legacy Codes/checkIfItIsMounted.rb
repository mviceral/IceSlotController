value = `if grep -qs '/mnt/card' /proc/mounts; then
    echo "It's mounted."
else
    echo "It's not mounted."
fi`

value = value.chomp

puts "value='#{value}'"
