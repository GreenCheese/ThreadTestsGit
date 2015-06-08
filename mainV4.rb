#encoding: utf-8
#encode: utf-8
require 'win32ole'
require 'date'

$:.unshift((File.dirname(__FILE__)))
require 'ptl'
require 'point'
require 'segment'
require 'route'

LOADFROMFILE = false
NARIADFROMFILE = true
@@CREATE_JPEG_IMAGES = false

str = Dir.pwd
str = str + "/PTL_LINES_DATA/*.*"

if (LOADFROMFILE)
	@@navFileReader = nil
	@@routeNameArr = []

	Dir[str].each{|file|
		card = IO.read(file)
		fRoute=false

		card.split("\n").each{|row|
			
		if (row.strip == "ROUTE_BEGIN")
			fRoute = true
			next
		end
		if (row.strip == "ROUTE_END")
			fRoute = false
			next
		end
	
		if (fRoute)
	
			name = row.split("\t")[0]
			dbconn = row.split("\t")[1]
			dbcode = row.split("\t")[2]
			segmts = row.split("\t")[3]

			if (LOADFROMFILE)
				@@routeNameArr << [name,dbcode]
			end
		end
		}
	}


def initializeFileReader(date, routeNameArr)

		#загружаем все маршруты
#		vehar = []
		hash = {}

			timestamp = TrnDate.GetDate()
			routeNameArr.each{|nameCode|
				routeName = nameCode[0]
#				p routeName

				dbcode = nameCode[1]
#				p dbcode


				path = "D://CbIP//CbIP//prj//VerifyNavigation//verifyNav//CorrectResult//#{timestamp}//#{dbcode}"
				Dir[path+"//*.txt"].each{|file|

				path = file.encode("utf-8")

				file = path[path.rindex("/")+1..path.rindex(".")-1]
				
				#puts file
				#puts "#{file.encode("utf-8")}\n"
				#count = 0
				if (routeName==file)
				

					#puts file
					#puts path

					card = IO.read (path)
					card.split("\n").each{|vehitem|
						if (vehitem[0]=="#")
							vehitem = vehitem[1..vehitem.size-1]
							vehitem = vehitem.strip
							if (vehitem!="0")

								found = false

								hash.keys.each{|key|
									if (key==dbcode)
										found = true
									end
								}

								if (!found)
									hash[dbcode] = []
								end

								hash[dbcode] << vehitem.to_i




								#count = count + 1
								#vehar << vehitem
							end
						end

					}
					#puts "routename = #{routeName}(#{dbcode}) - #{count} vh"
				end

			}
			}
		if (@@navFileReader!=nil)
			@@navFileReader.deleteData
		end
		@@navFileReader = nil
		@@navFileReader = FileNavigation.new
		t1 = Time.now
		@@navFileReader.loadAllByDate(date,hash)
		t2 = Time.now

		p "LoadAllByDate\t\t#{t2-t1}\n"
		sleep 5

	end
end

def startSegmentCalculation (srcFile)
	
	card = IO.read(srcFile)
	
	fSegment=false
	fRoute=false
	fHeader = false
	
	segarr = []
	routearr = []
	segment_number=1
	lineCode = 0
	lineName=""
	date = TrnDate.GetDate()
	
	card.split("\n").each{|row|
		if (row.strip == "SEGMENT_BEGIN")
			fSegment = true
			next
		end
		if (row.strip == "SEGMENT_END")
			fSegment = false
			next
		end
	
		if (row.strip == "ROUTE_BEGIN")
			fRoute = true
			next
		end
		if (row.strip == "ROUTE_END")
			fRoute = false
			next
		end
	
		if (row.strip == "LINE_BEGIN")
			fHeader = true
			next
		end
		if (row.strip == "LINE_END")
			fHeader = false
			next
		end
	
		if (fHeader)
			lineCode = row.split("\t")[0].to_s
			lineName = row.split("\t")[1].to_s
		end
	
		if (fSegment)
			#p "fSegment"
			sName = row.split("\t")[0]
			sbx = row.split("\t")[1].strip.to_f
			sby = row.split("\t")[2].strip.to_f
			sex = row.split("\t")[3].strip.to_f
			sey = row.split("\t")[4].strip.to_f
	
			pb = Point.new(sbx, sby)
			pe = Point.new(sex, sey)
	
			sfi = Segment.new(segment_number, "#{sName}-f", pb,pe)
	#		sbi = Segment.new(segment_number, "#{sName}-b", pe,pb)
	
			segarr << sfi
			segment_number = segment_number + 1
		end
	
		if (fRoute)
	
			name = row.split("\t")[0]
			dbconn = row.split("\t")[1]
			dbcode = row.split("\t")[2]
			segmts = row.split("\t")[3]

			route = Route.new(dbconn, dbcode, name)
			
			segmts.split(",").each{|segm_name|
				#Бежим по массиву сегментов
				segarr.each{|seg_item|
					#и ижем сегменты-объекты, для которые задан route
					segName = seg_item.getSegmentName
	
					if ("#{segm_name}-f"==segName)
						route.addSegment(seg_item)
					end
				}
			}
	
			routearr << route 
			
		end
	}
	
	# segarr = OK
	#segarr.each{|seg|
	#	pnts =  seg.getSegmentPoints
	#	puts pnts[0].getPoint
	#	puts pnts[1].getPoint
	#	puts	seg.getSegmentName
	#	puts "****"
	#}
	
	
	
	
	ptl = PTL.new(lineName, lineCode, date)
	
	segarr.each{|seg|
		ptl.addSegment(seg)
	}

	routeSize = routearr.size
	routeCountOper = 0

#	if (LOADFROMFILE)
#		routearr[0].initializeFileReader(date,@@routeNameArr)
#	end

	routearr.each{|route|
		if (NARIADFROMFILE)
			route.setNariadFromFile(true)
		end

		if (LOADFROMFILE)
			route.setNariadFromFile(true)
			route.setNavigateFromFile(true)
		end
		routeCountOper = routeCountOper + 1
		puts "route: #{routeCountOper}/#{routeSize}"
		route.setPoints(ptl)
		ptl.calculate (route)
	}
	
	
	ptl.fillMidSpeedTable
	puts "MIDSPEED"
	ptl.printMidSpeed(srcFile)
	
							#---ptl.printMidSpeedBySeg
	
	ptl.printMidSpeedByTime
	ptl.createJPG
	ptl.finalize
	puts "finished"
end


def getNextDate(str)
	dateCurrDate = Date.parse str
	dateNextDate = dateCurrDate+1	
	return dateNextDate.strftime("%d.%m.%Y")	
end


startDay = "29.04.2013"
operateDay = startDay

while (operateDay!="21.05.2013") #"01.11.2012"

	 
	TrnDate.SetDateStr(operateDay)

	dateStr = TrnDate.GetDate()

	if (LOADFROMFILE)
		initializeFileReader(dateStr, @@routeNameArr)
	end

	Dir[str].each{|file|
		startSegmentCalculation(file)
	}

	puts Time.now
	
	f = File.new("D://CbIP//CbIP//prj//VerifyNavigation//PTL_Analyse//PTL_ANAL_S1//ResOK//#{dateStr}.ok", "wb+")
	f.close

	operateDay = getNextDate(operateDay)
end



#threads = []
#
#Dir[str].each{|file|
#	threads << Thread.new(file) do |fn|
#		startSegmentCalculation(fn)
#	end
#}
#
#
#threads.each do |thr|
#    begin
#        thr.join
#    rescue RuntimeError => e
#        puts "Failed: #{e.message}"
#    end
#end 
#
#
#
