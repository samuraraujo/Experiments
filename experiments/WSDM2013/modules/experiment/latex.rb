def preicsion()
  $current_dir = File.dirname(__FILE__)
  latex = []
  group = []
  limit = ""
  Dir.foreach("#{$current_dir}/../../") {|x|
    next if !File.directory?("#{$current_dir}/../../#{x}")
    next if !File.exist?("#{$current_dir}/../../#{x}/output")
    firstline=true
    group = []

    Dir.foreach("#{$current_dir}/../../#{x}/output/") {|y|
      limit=""
      if y.index("results.txt") != nil &&  (y.index("Jul 29") != nil||y.index("Jul 30") != nil)
        puts x
        puts y
        File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|

          if line.index("RECALL: ") || line.index("PRECISON: ") || line.index("FMEASURE: ")

            puts line
          end
        }
      end

    }
    # group = group[0..3]
    # group.insert(1,group.last)
    # group.delete_at(group.size-1)
    puts group if group.compact.size > 0

  }

end

def latextablelimit()
  $current_dir = File.dirname(__FILE__)
  latex = []
  group = []
  limit = ""
  Dir.foreach("#{$current_dir}/../../") {|x|
    next if !File.directory?("#{$current_dir}/../../#{x}")
    next if !File.exist?("#{$current_dir}/../../#{x}/output")
    firstline=true
    group = []
    Dir.foreach("#{$current_dir}/../../#{x}/output/") {|y|
      limit=""
      if y.index("results.txt") != nil

        File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|
          limit = line.rstrip if line.index("sparqllimit") != nil

          if line.index("& ")
            if firstline
              firstline =false
              group <<  "#{x} "
            line =   line.rstrip
            else
            line =   line.rstrip
            end

            line = limit + line
            # group << line if limit.index("sparqllimit") != nil
            group << line if line.index("SondaA") != nil
          end
        }

      end

    }
    # group = group[0..3]
    # group.insert(1,group.last)
    # group.delete_at(group.size-1)
    puts group if group.compact.size > 0

  }

end

def latextable()
  $current_dir = File.dirname(__FILE__)
  latex = []
  group = []
  limit = ""
  Dir.foreach("#{$current_dir}/../../") {|x|
    next if !File.directory?("#{$current_dir}/../../#{x}")
    next if !File.exist?("#{$current_dir}/../../#{x}/output")
    firstline=true
    group = []
    Dir.foreach("#{$current_dir}/../../#{x}/output/") {|y|
      limit=""
      next if y.index(" Aug 06 ") == nil and y.index(" Aug 07 ") == nil and y.index(" Aug 05 ") == nil
      if y.index("results.txt") != nil
        File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|
          break if line.index("target => http://localhost:8894/sparql?default-graph-uri=http://dbpedia.org") != nil
          next if line.index("sparqllimit") != nil
          limit = line.rstrip if line.index("sparqllimit") != nil

          if line.index("& ")
            if firstline
              firstline =false
              line = "\\multirow{4}{*}{#{x}} " + line.rstrip
            else
            line =   line.rstrip
            end
            if line.index("S-agnostic")
              line +=  " \\hline"

            end
          line = limit + line
          group << line
          end
        }
      end

    }
    # group = group[0..3]
    # group.insert(1,group.last)
    # group.delete_at(group.size-1)
    puts group if group.compact.size > 0

  }

end

def queriesinfor()
  $current_dir = File.dirname(__FILE__)
  latex = []
  hash = Hash.new
  total=0
  Dir.foreach("#{$current_dir}/../../") {|x|
    next if !File.directory?("#{$current_dir}/../../#{x}")
    next if !File.exist?("#{$current_dir}/../../#{x}/output")
    latex << queries(x)
  }
  latex.compact!
  puts latex.map{|x,y| x }.join(" ")
  puts latex.map{|x,y| y[0] }.join(" ")
  puts latex.map{|x,y| y[1] }.join(" ")
  puts latex.map{|x,y| y[2] }.join(" ")
  puts latex.map{|x,y| y[3] }.join(" ")
  puts latex.map{|x,y| y[4] }.join(" ")

end

def queries(x)
  latex = []
  hash = Hash.new
  total=0
  hash[1]=0
  hash[2]=0
  hash[3]=0
  hash[4]=0
  hash[5]=0

  firstline=true
  Dir.foreach("#{$current_dir}/../../#{x}/output/") {|y|
    if y.index("results.txt") != nil
      current = 0
      valid = false
      File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|
        next if line.index("& SondaA")== nil
        valid = true
      }
      if valid
        total=0
        hash = Hash.new
        File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|
          if line.index("[")!= nil
            # puts line
            line = line.split("]").last.split(" ")[1]
            current=line.to_i
            hash[current]=0 if hash[current]==nil
          end
          if line.index("SUCCESS: ")!= nil
            line = line.split(" ")
            if line.last.to_i  > 0
            total+=line.last.to_i
            hash[current]+=line.last.to_i
            end
          end
        }
        return [x,hash.sort.map{|k,v| (v.to_f/total.to_f)}]
      end

    end
  }
end

def qtime()
  $current_dir = File.dirname(__FILE__)
  latex = []
  hash = Hash.new
  total=0

  Dir.foreach("#{$current_dir}/../../") {|x|
    next if !File.directory?("#{$current_dir}/../../#{x}")
    next if !File.exist?("#{$current_dir}/../../#{x}/output")
    latex << queriestime(x)
  }
  latex.compact!

  [1,2,3,4,5].each{|k|
    count = 0
    time=0
    # puts k
    latex.each{|h|
    # puts "#####"
    # puts h.sort

      if h[k] > 0
      # puts h[k]
      count +=1
      time+=h[k]
      end
    }
    puts time.to_f/count.to_f
  }

end

def queriestime(x)
  latex = []
  hash = Hash.new
  total=Hash.new
  hash[1]=0
  hash[2]=0
  hash[3]=0
  hash[4]=0
  hash[5]=0

  total[1]=0
  total[2]=0
  total[3]=0
  total[4]=0
  total[5]=0
  firstline=true
  Dir.foreach("#{$current_dir}/../../#{x}/output/") {|y|
    if y.index("results.txt") != nil
      current = 0
      valid = false
      File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|
        next if line.index("& SondaA")== nil
        valid = true
      }
      if valid

        hash = Hash.new
        valid2=false
        File.open("#{$current_dir}/../../#{x}/output/#{y}", 'r').each { |line|

          if line.index("[")!= nil
            # puts line
            line = line.split("]").last.split(" ")[1]
            current=line.to_i
            hash[current]=0 if hash[current]==nil
            total[current]=0 if total[current]==nil
          end
          if line.index("SUCCESS: ")!= nil
            line = line.split(" ")
          valid2=true #if line.last.to_i > 0

          end
          if valid2 && line.index("Elapse time:")!= nil
            valid2=false
            line = line.split(" ")
          total[current]+=1
          hash[current]+=line.last.to_f
          end
        }

        hash.each{|k,v| hash[k]=((v.to_f)/(total[k].to_f))}
      return hash
      end

    end
  }
end

# preicsion()
# latextablelimit()
latextable()
# queriesinfor()
# qtime()

