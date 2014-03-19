require 'mechanize'
require 'open-uri'
require 'digest'
require 'watir-webdriver'
#require 'headless'

class String
	def drop
		self.gsub(/^\s+|\s+$/,'').gsub("\n"," ")
	end
end

class Gentleman
	def initialize
		#@headless = Headless.new
		#@headless.start
		@agent = Watir::Browser.new :firefox
		Dir.mkdir("tmp/") unless File.exist?("tmp/")
		Dir.mkdir("gen/") unless File.exist?("gen/")
	end

	def md5(text)
		return Digest::MD5.hexdigest(text.encode('utf-8')).upcase
	end

	def down_pic(url)
		return nil unless /\w+$/.match(url)
		filename = "tmp/" + md5(url) + '.' + /\w+$/.match(url)[0].to_s
		return filename if File.exist?(filename)

		pic = open(url) { |f| f.read }
		File.open(filename, "wb") { |f| f.write(pic) }
		return filename
	end

	def login
		page = @agent.goto("http://lknovel.lightnovel.cn/main/login.html")
		page.forms.each { |f| puts f["id"] }
		login_form = page.forms.first
		#puts login_form["id"]
		login_form["user_name"], login_form["pass_word"] = @user, @pass
		#puts login_form.text_field?(:name => "user_name") ? "yes" : "no"
		#puts login_form.texts
		#login_form.field_with(:name => "user_name").value = @user
		#login_form.field_with(:name => "pass_word").value = @pass
		@agent.submit(login_form, login_form.buttons.first)
	end

	def chap_scan(url)
		cp = {}
		@agent.goto(url)
		@agent.wait
		page = @agent.html()
		doc = Nokogiri::HTML(page)

		cp[:title] = doc.xpath('//h3[@class="ft-20"]').text.drop
		cp[:content] = []
		doc.xpath('//div[@id="J_view"]/div').each do |div|
			pa = {}
			if !div.child
			elsif div.child.class.to_s == "Nokogiri::XML::Text"
				pa[:type] = "text"
				pa[:content] = div.text
			elsif div.child.child
				pa[:type] = "illustration"
				#puts div["id"]
				pa[:content] = down_pic('http://lknovel.lightnovel.cn' \
				                        + div.child.child["href"])
			end
			cp[:content].push pa
		end

		cp
	end

	def vol_scan(url)
		sv = {}
		@agent.goto(url)
		@agent.wait
		page = @agent.html()
		doc = Nokogiri::HTML(page)

		sv[:title] = doc.xpath('//h1[@class="ft-24"]/strong').text.drop
		cover_url = doc.xpath('//div[@class="lk-book-cover"]/a/img')[0]["src"]
		sv[:cover] = down_pic('http://lknovel.lightnovel.cn'+cover_url)

		puts "Scanning Vol. #{sv[:title]}"

		sv[:chapters] = []
		doc.xpath('//li[@class="span3"]/a').each do |link|
			#puts link.child.class
			sv[:chapters].push chap_scan(link["href"])
		end

		sv
	end

	def scan
		@agent.goto(@url)
		@agent.wait
		page = @agent.html()
		doc = Nokogiri::HTML(page)

		@title = doc.xpath('//h1[@class="ft-24"]/strong').text.drop
		@author = doc.xpath('//td[@width="140"]/a')[0].text.drop
		#@author = doc.xpath('//td').select{|td| td.text=='作者：'}[0].text.drop
		#puts @title
		@vols = []
		doc.xpath('//h2[@class="ft-24"]/strong/a').each do |link|
			@vols.push vol_scan(link['href'])
		end
	end

	def check
		puts @title
		puts @author
		@vols.each do |v|
			puts "| "+v[:title]
			puts "| "+v[:cover]
			v[:chapters].each do |c|
				puts "| | "+c[:title]
			end
		end
	end

	def generate
		@vols.each_with_index do |vol, cv|
			File.open("gen/#{cv}.markdown", "w") do |file|
				file.puts '% ' + vol[:title]
				file.puts '% ' + @author
				vol[:chapters].each do |chap|
					file.puts '# ' + chap[:title]
					chap[:content].each do |cont|
						if cont[:type] == "text"
							file.puts cont[:content] + "\n\n"
						elsif cont[:content]
							file.puts '![](../' + cont[:content] + ")\n\n"
						end
					end
				end
			end
		end
	end

	def gentleman(num)
		@url = "http://lknovel.lightnovel.cn/main/vollist/#{num}.html"

		#puts login.body
		#login

		scan
		#check
		generate
	end

	def finish
		@agent.close
		#@headless.destroy
	end
end

g = Gentleman.new
g.gentleman(ARGV[0])
g.finish
