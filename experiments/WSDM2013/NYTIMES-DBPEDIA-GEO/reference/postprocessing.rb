def init_dic()
  $dic = Hash.new if $dic == nil
  File.open("../reference/dic.txt", 'r').each { |line|
    line = line.rstrip.split("=")
    $dic[line[0]]=line[1]
  }
end

def save_dic()
  f = File.open("../reference/dic.txt", 'w')
  $dic.each{|k,v|
    f.write(k+ "=" +v + "\n")
  }
  f.fsync
  f.close
end
def process ()
  data =[]
  File.open( "reference.txt", 'r').each { |line|
    data << line.rstrip
  }
  init_dic()
  data = dbpedia_post(data)
  
end

def dbpedia_post(data)
  newdata = []
  t = []
  count=0
  finished = []
  $dictime= false
  data.each{|line|
    c = line.split("=")
    sleep(0.2) if $dic[c[1]] == nil
    t <<  Thread.new{
      count+=1
      a = count
      puts count
      finished << a
      if line.index("yago") != nil
      newdata <<    line
      next
      end

      y = line.split("=")
      link = dbpedia_deref(y[1], 1)
      if link != nil && link.index("/resource/") == nil
      $dic[y[1]]=link 
      newdata <<  y[0] +"=" + link
      else
        newdata <<  y[0] +"=" + y[1]
   end

      finished.delete(a)
      puts "END " + a.to_s
    }
    if $dictime==true
      
      t.map{|x|x.join}
      save_dic()
    t=[]
    $dictime=false
    end

  }
  t.map{|x|x.join}
  save_dic()
  return newdata
end

def dbpedia_deref(link, count)

  return link if count > 5
  if $dic!= nil && $dic[link] !=  nil

  return $dic[link]
  end
  uri = URI(link)
  res = Net::HTTP.get_response(uri)
  puts  "Resopnse: " + res.code
  puts res['location']
  if res.code == '303' || res.code == '301'

    return dbpedia_deref(res['location'], count + 1)
  elsif res.code == '503'
    $dictime=true
    return nil
  end
  return link
end


require 'net/http'

process()
# puts dbpedia_deref("http://rdf.freebase.com/ns/user.jamie.nytdataid.N39971021549573074462")
