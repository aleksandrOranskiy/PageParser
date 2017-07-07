require 'open-uri'
require 'nokogiri'
require 'csv'

ENV['SSL_CERT_FILE'] = File.expand_path(File.dirname(__FILE__)) + "/cacert.pem"

url = ARGV[0]
path = ARGV[1]
doc = Nokogiri::HTML(open(url))

showings = []
#reading and writing goods pages from main page
doc.css('.product_img_link').each do |showing|
  showings.push(showing['href'])
end

#reading and counting quantity of pages with goods
all_count_of_goods = /(\d+)\sde\s(\d+)/.match(doc.css('.product-count').text)[2].to_i
curr_count_of_goods = /(\d+)\sde\s(\d+)/.match(doc.css('.product-count').text)[1].to_i
expression = all_count_of_goods%curr_count_of_goods
count = all_count_of_goods/curr_count_of_goods
count_of_pages = (expression != 0) ? count+1 : count

#writing all goods pages to an array
for i in 2..count_of_pages
  next_url = url + "?p=#{i}";
  next_doc = Nokogiri::HTML(open(next_url));
  next_doc.css('.product_img_link').each do |showing|
    showings.push(showing['href'])
  end
end

images = []

#giving info about goods from the every page
#and writing to the CSV file
CSV.open(path,"wb") do |csv|
  for j in 0..showings.size-1
    goods_doc = Nokogiri::HTML(open(showings[j]))
    goods_name = goods_doc.css('h1').text.strip.split("\n")[3]
    curr_image = goods_doc.css('#thumbs_list_frame a')
    if curr_image.size > 0
      curr_image.each do |showing|
        images.unshift(showing['href'])
      end
    else
      goods_doc.css('#bigpic').each do |showing|
        images.unshift(showing['src'])
      end
    end
    image = images.pop
    goods_doc.css('.attribute_labels_lists').each do |showing|
      name = "".concat(goods_name).concat(" ").concat(showing.css('.attribute_name').text);
      price = showing.css('.attribute_price').text.strip;
      if images.size > 0
        image = images.pop;
      end
      csv << [name, price, image];
    end
  end
end




