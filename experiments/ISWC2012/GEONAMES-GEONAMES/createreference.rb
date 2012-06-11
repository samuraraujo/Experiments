dir_contents = Dir.entries("./output/")
out  = File.open("./reference/reference.txt","a")

dir_contents.each {|line|
  if line.index("subjects") != nil
    file  = File.open("./output/"+line,"r")
    file.each {|x|
    x=x.rstrip
      out.write(x + "=" + x + "\n")

    }
  end

}