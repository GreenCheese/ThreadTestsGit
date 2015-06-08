

thread = Thread.new do
	system("1.bat")
end

thread2 = Thread.new do
	system("2.bat")
end

thread3 = Thread.new do
	system("3.bat")
end

thread.join
thread2.join
thread3.join

exit
for i in 1..10
	p Time.now
	sleep 1
end