

def create_log()
   
  t1=Time.now
  $log_subjects =  File.open($current_dir +"/../output/#{t1}_subjects.txt", 'w')
  $logger =  File.open($current_dir +"/../output/#{t1}_log.txt", 'w')
  $output =  File.open($current_dir+"/../output/#{t1}_mappings.txt", 'w')
  $results =  File.open($current_dir +"/../output/#{t1}_results.txt", 'w')
  $log_candidates =  File.open($current_dir +"/../output/#{t1}_candidates.txt", 'w')
end

  def puts(str)
         return
    # create_log() if $logger == nil
    if str.instance_of? Array
      str.each{|x|
        $logger.write(x.to_s)
        $logger.write("\n")
      }
    else
      $logger.write(str.to_s)
      $logger.write("\n")
    end
  # $logger.fsync
  end


def close_log()
  $logger.fsync if $logger!=nil
  # $logger.close if $logger!=nil

  $log_subjects.fsync if $log_subjects!=nil
  $log_subjects.close if $log_subjects!=nil

  $log_candidates.fsync if $log_candidates!=nil
  $log_candidates.close if $log_candidates!=nil

  $output.fsync if $output!=nil
  $output.close if $output!=nil

end
