#!/usr/bin/env ruby

require 'base64'
require 'json'
require 'net/http'

def load_envs
  File.open(File.join(File.dirname(__FILE__), '.env')).each_line do |line|
    key, value = line.split("=").map(&:strip)
    ENV[key] = value
  end
end

class CheckOrders
  def initialize(printful_api_key, slack_webhook)
    load_orders
    check_printful(printful_api_key)
    @slack_webhook = slack_webhook
  end

  def ping_slack
    post @slack_webhook, slack_message
  end

  def save_orders
    @orders += new_orders.map{ |order| order['id'] }
    File.open(orders_file, 'w') { |fl| fl.write(@orders.to_json) }
  end

  def new_orders?
    new_orders.any?
  end

  def new_orders
    @printful_orders.reject{ |order| @orders.include? order['id'] }
  end

  private

  def check_printful(printful_api_key)
    key =  Base64.encode64 printful_api_key
    response = parse_json get("https://api.theprintful.com/orders", key)
    @printful_orders =  response['result']
  end

  def slack_message
    revenue = new_orders.map do |order|
      order['retail_costs']['total'].to_f - order['costs']['total'].to_f
    end.inject(0.0) { |order, total| order + total }.round(2)

    line_items = new_orders.map do |order|
      name = order['recipient']['name']
      from = "#{order['recipient']['city']}, #{order['recipient']['state_name']}"
      items = order['items'].map{ |item| item['name'] }.join(', ')
      "\t-\t*#{name}* from #{from} bought #{items}"
    end

    {
      text: "*#{new_orders.count} new orders* from the store for a _total of " \
            "$#{revenue}_.\n\n#{line_items.join("\n")}"
    }.to_json
  end


  def load_orders
    @orders = parse_json File.read(orders_file) if File.exists?(orders_file)
  end

  def orders_file
    File.join(File.dirname(__FILE__), 'orders.json')
  end

  def parse_json(raw_json)
    begin
      JSON.parse raw_json
    rescue JSON::ParserError
      return []
    end
  end

  def get(url, key=nil)
    uri = URI(url)
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Basic #{key}" if key
    http_send uri, req
  end

  def post(url, body)
    uri = URI(url)
    req = Net::HTTP::Post.new(uri)
    req.body = body
    p body
    # http_send uri, req
  end

  def http_send(uri, request)
    response = Net::HTTP.start(uri.hostname, uri.port,
                               use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    response.body
  end
end

load_envs
orders_check = CheckOrders.new ENV['PRINTFUL_API'], ENV['SLACK_WEBHOOK']
orders_check.ping_slack if orders_check.new_orders?
orders_check.save_orders


