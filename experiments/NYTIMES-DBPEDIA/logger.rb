

def create_log()
   
  t1=Time.now
  $log_subjects =  File.open("./output/#{t1}_subjects.txt", 'w')
  $logger =  File.open("./output/#{t1}_log.txt", 'w')
  $output =  File.open("./output/#{t1}_mappings.txt", 'w')
  $results =  File.open("./output/#{t1}_results.txt", 'w')
end



def close_log()
  $logger.fsync if $logger!=nil
  $logger.close if $logger!=nil

  $log_subjects.fsync if $log_subjects!=nil
  $log_subjects.close if $log_subjects!=nil

  $output.fsync if $output!=nil
  $output.close if $output!=nil

end
