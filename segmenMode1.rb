
str = Dir.pwd
str = str + "/PTL_LINES_DATA/*.*"



threads = []
=begin
Dir[str].each{|file|
	threads << Thread.new {puts file}
}



Dir[str].each{|file|
	threads << Thread.new(file) do |fn|
		startSegmentCalculation(fn)
end
}


threads.each do |thr|
    begin
        thr.join
    rescue RuntimeError => e
        puts "Failed: #{e.message}"
    end
end 

=end



4.times do |number|
    threads << Thread.new(number) do |i|
        raise "Boom!" if i == 2
        print "#{i}\n"
    end
end