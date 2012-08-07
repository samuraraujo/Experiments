 a = []
 b =[]
 File.open("mappings.txt", 'r').each { |line|
 a << line.rstrip  
}
File.open("reference.txt", 'r').each { |line|
 b << line.rstrip
   
}
puts b - a