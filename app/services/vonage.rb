require 'net/http'
require 'base64'
require 'json'
require 'ostruct'
require 'openssl'
require 'jwt'

class VonageDataSource
  def balance
    uri = URI("https://rest.nexmo.com/account/get-balance?api_key=#{ENV['VONAGE_API_KEY']}&api_secret=#{ENV['VONAGE_API_SECRET']}")
    request = Net::HTTP::Get.new(uri)
    request['Content-type'] = 'application/json'
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return response.is_a?(Net::HTTPSuccess) ? response.body : nil
  end

  def apps
    uri = URI('https://api.nexmo.com/v2/applications')
    request = Net::HTTP::Get.new(uri)
    auth = "Basic " + Base64.strict_encode64("#{ENV['VONAGE_API_KEY']}:#{ENV['VONAGE_API_SECRET']}")
    request['Authorization'] = auth
    request['Content-type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return response.is_a?(Net::HTTPSuccess) ? response.body : nil
  end

end

class Vonage
  def initialize
    @data_source = VonageDataSource.new()
  end
  def data_source
    @data_source
  end

  def balance
    response = @data_source.balance
    return 0 if response == nil
    balance = JSON.parse(response, object_class: OpenStruct)
    return balance.value.to_f || 0
  end


  def apps
    response = @data_source.apps
    return [] if response == nil
    begin
      json_object = JSON.parse(response, object_class: OpenStruct)
    rescue JSON::ParserError
      return []
    end
    return [] if json_object._embedded == nil || json_object._embedded.class.name != 'OpenStruct'
    return json_object._embedded.applications || []
  end
  

  def self.app_create(api_key, api_secret, nexmo_app)
    uri = URI('https://api.nexmo.com/v2/applications/')
    request = Net::HTTP::Post.new(uri)
    auth = "Basic " + Base64.strict_encode64("#{api_key}:#{api_secret}")
    request['Authorization'] = auth
    request['Content-type'] = 'application/json'
    request.body = {
      name: nexmo_app[:name], 
      keys: {
        public_key: nexmo_app[:public_key]
      }, 
      capabilities: {
        voice: {
          webhooks: {
            answer_url: {
              address: nexmo_app[:voice_answer_url],
              http_method: nexmo_app[:voice_answer_method]
            },
            event_url: {
              address: nexmo_app[:voice_event_url],
              http_method: nexmo_app[:voice_event_method]
            }
          }
        },
        rtc: {
          webhooks: {
            event_url: {
              address: nexmo_app[:rtc_event_url],
              http_method: nexmo_app[:rtc_event_method]
            }
          }
        }
      }
    }.to_json
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    unless response.is_a?(Net::HTTPSuccess)
      puts "ERROR"
      puts response.body
      return false
    end

    jsonApp = JSON.parse(response.body, object_class: OpenStruct)
    return jsonApp
  end


  def self.numbers(api_key, api_secret)
    uri = URI("https://rest.nexmo.com/account/numbers?api_key=#{api_key}&api_secret=#{api_secret}")
    request = Net::HTTP::Get.new(uri)
    request['Content-type'] = 'application/json'
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return [] unless response.is_a?(Net::HTTPSuccess)
    json_object = JSON.parse(response.body, object_class: OpenStruct)
    return json_object.numbers
  end


  def self.number_search(api_key, api_secret, country)
    uri = URI("https://rest.nexmo.com/number/search?api_key=#{api_key}&api_secret=#{api_secret}&country=#{country}&features=VOICE&size=100")
    request = Net::HTTP::Get.new(uri)
    request['Content-type'] = 'application/json'
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return nil unless response.is_a?(Net::HTTPSuccess)
    json_object = JSON.parse(response.body, object_class: OpenStruct)
    return json_object.numbers
  end


  def self.number_buy(api_key, api_secret, country, msisdn)
    uri = URI("https://rest.nexmo.com/number/buy?api_key=#{api_key}&api_secret=#{api_secret}")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data({
      country: country,
      msisdn: msisdn
    })
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return response.is_a?(Net::HTTPSuccess)
  end


  def self.number_link(api_key, api_secret, country, msisdn, app_id)
    uri = URI("https://rest.nexmo.com/number/update?api_key=#{api_key}&api_secret=#{api_secret}")
    request = Net::HTTP::Post.new(uri)
    properties = {
      country: country,
      msisdn: msisdn
    }
    unless app_id == nil 
      properties[:voiceCallbackType] = 'app'
      properties[:voiceCallbackValue] = app_id
    end
    request.set_form_data(properties)
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return response.is_a?(Net::HTTPSuccess)
  end


  def admin_jwt
    rsa_private = OpenSSL::PKey::RSA.new(ENV['APP_PRIVATE_KEY'])
    payload = {
      "application_id": ENV['APP_ID'],
      "iat": Time.now.to_i,
      "jti": SecureRandom.uuid,
      "exp": (Time.now.to_i + 86400),
    }
    token = JWT.encode payload, rsa_private, 'RS256'
    return token
  end


  def self.users(app_id, private_key, url = 'https://api.nexmo.com/v0.3/users')
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    auth = "Bearer " + admin_jwt(app_id, private_key)
    request['Authorization'] = auth
    request['Content-type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return [] unless response.is_a?(Net::HTTPSuccess)
    json_users = JSON.parse(response.body, object_class: OpenStruct)
    return json_users
  end


  def self.create_user(app_id, private_key, name, display_name)
    uri = URI('https://api.nexmo.com/v0.3/users')
    request = Net::HTTP::Post.new(uri)
    auth = "Bearer " + admin_jwt(app_id, private_key)
    request['Authorization'] = auth
    request['Content-type'] = 'application/json'
    request.body = {name: name, display_name: display_name}.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return unless response.is_a?(Net::HTTPSuccess)
    json_user = JSON.parse(response.body, object_class: OpenStruct)
    return json_user
  end


  def self.delete_user(app_id, private_key, user_id)
    uri = URI('https://api.nexmo.com/v0.3/users/' + user_id)
    request = Net::HTTP::Delete.new(uri)
    auth = "Bearer " + admin_jwt(app_id, private_key)
    request['Authorization'] = auth
    request['Content-type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(request)
    }
    return response.is_a?(Net::HTTPSuccess)
  end



end